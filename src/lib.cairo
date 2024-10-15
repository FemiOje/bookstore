use starknet::ContractAddress;

#[starknet::interface]
trait IBookstore<TContractState> {
    fn add_book( ref self: TContractState, title: felt252, author: felt252, category: Category, year_of_publication: u16 );
    fn remove_book(ref self: TContractState, book_id: u32);
    fn get_book_by_id(self: @TContractState, book_id: u32) -> Book;
    fn buy_book(ref self: TContractState, book_id: u32)-> (ContractAddress, ContractAddress);
}

#[derive(Drop, Copy, Serde, PartialEq, starknet::Store)]
enum Category {
    #[default]
    NULL,
    SCI_FI,
    ADVENTURE,
    NONFICTION,
    HORROR
}

#[derive(Drop, Copy, Serde, PartialEq, starknet::Store)]
struct Book {
    id: u32,
    owner: ContractAddress,
    title: felt252,
    author: felt252,
    category: Category,
    year_of_publication: u16
}


#[starknet::contract]
pub mod bookstore {
    use core::starknet::storage::{StoragePointerReadAccess, StoragePointerWriteAccess, StoragePathEntry, StorageMapReadAccess, StorageMapWriteAccess, Map};
    use core::starknet::{ContractAddress, get_caller_address};
    use core::num::traits::Zero;
    use super::{Book, Category, IBookstore};

    #[storage]
    struct Storage {
        all_books: Map<u32, Book>, // <id, Book>
        book_count: u32
    }

    #[constructor]
    fn constructor(ref self: ContractState) {
        self.book_count.write(0);
    }

    #[abi(embed_v0)]
    impl BookstoreImpl of IBookstore<ContractState> {
        fn add_book(
            ref self: ContractState,
            title: felt252,
            author: felt252,
            category: Category,
            year_of_publication: u16
        ) {
            self.book_count.write(self.book_count.read() + 1);

            let new_book = Book {
                id: self.book_count.read(), 
                owner: get_caller_address(), 
                title, 
                author, 
                category, 
                year_of_publication
            };
            self.all_books.write(new_book.id, new_book);
        }

        fn remove_book(ref self: ContractState, book_id: u32) {
            let zero_book = Book {
                id: 0, 
                owner: Zero::zero(), // confirm that this is correct
                title: 0, 
                author: 0, 
                category: Category::NULL, 
                year_of_publication: 0
            };
            assert(self.all_books.read(book_id) != zero_book, 'Book does not exist');
            self.all_books.entry(book_id).write(zero_book);
        }

        fn get_book_by_id(self: @ContractState, book_id: u32) -> Book {
            // assert(book_id != 0, 'Cannot get empty book');
            self.all_books.read(book_id)
        }

        fn buy_book(ref self: ContractState, book_id: u32) -> (ContractAddress, ContractAddress){
            let old_book = self.all_books.read(book_id);
            let new_book = Book { owner: get_caller_address(), ..old_book };
            self.all_books.write(book_id, new_book);

            (old_book.owner, new_book.owner)
        }
    }
}
