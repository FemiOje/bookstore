use starknet::ContractAddress;

#[starknet::interface]
trait IBookstore<TContractState> {
    fn add_book(
        ref self: TContractState,
        title: ByteArray,
        author: felt252,
        category: Category,
        year_of_publication: u16
    );
    fn remove_book(ref self: TContractState, book_id: u256);
    fn get_book_by_id(self: @TContractState, book_id: u256) -> Book;
    fn buy_book(ref self: TContractState, book_id: u256);
}

#[derive(Drop, Copy, Serde, starknet::Store)]
enum Category {
    SCI_FI,
    ADVENTURE,
    NONFICTION,
    HORROR
}

#[derive(Drop, Serde)]
struct Book {
    id: u256,
    owner: ContractAddress,
    title: ByteArray,
    author: felt252,
    category: Category,
    year_of_publication: u16
}

#[starknet::contract]
pub mod bookstore {
    use core::starknet::storage::{StoragePointerReadAccess, StoragePointerWriteAccess, Map};
    use core::starknet::{get_caller_address};
    use super::{Book, Category, IBookstore};

    #[storage]
    struct Storage {
        all_books: Map<u256, Book>, // <id, Book>
        book_counter: u256, 
        id_generator: u256
    }


    #[abi(embed_v0)]
    impl BookstoreImpl of IBookstore<ContractState> {
        fn add_book(
            ref self: ContractState,
            title: ByteArray,
            author: felt252,
            category: Category,
            year_of_publication: u16
        ) {
            //increment book counter
            let latest_book_counter_value = self.book_counter.read();
            self.book_counter.write(latest_book_counter_value + 1);

            //increment id generator
            let latest_id_value = self.id_generator.read();
            self.id_generator.write(latest_id_value + 1);

            //assign new id to book
            let mut book_id = self.id_generator.read();

            let caller_address = get_caller_address();
            let new_book = Book {
                id: book_id, owner: caller_address, title, author, category, year_of_publication
            };
            self.all_books.write(book_id, new_book);
        }

        fn remove_book(ref self: ContractState, book_id: u256) {
            self.all_books.write(book_id, 0); // might throw error if Book default value is not 0

            //decrement book counter
            let latest_book_counter_value = self.book_counter.read();
            self.book_counter.write(latest_book_counter_value - 1);
        }

        fn get_book_by_id(self: @ContractState, book_id: u256) -> Book {
            let result = self.all_books.read(book_id);
            result
        }

        fn buy_book(ref self: ContractState, book_id: u256) {
            let mut caller = get_caller_address();
            let old_book = self.all_books.read(book_id);
            let new_book = Book { owner: caller, ..old_book };
            self.all_books.write(book_id, new_book);
        }
    }
}
