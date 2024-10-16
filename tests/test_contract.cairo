use starknet::ContractAddress;
use snforge_std::{declare, ContractClassTrait, DeclareResultTrait, start_cheat_caller_address, stop_cheat_caller_address};

use bookstore::bookstore::{ Book, Category };
use bookstore::bookstore::{ IBookstoreDispatcher, IBookstoreDispatcherTrait };
use core::num::traits::Zero;

pub mod Accounts {
    use starknet::ContractAddress;
    use core::traits::TryInto;

    pub fn account1() -> ContractAddress {
        'account1'.try_into().unwrap()
    }

    pub fn account2() -> ContractAddress {
        'account2'.try_into().unwrap()
    }
}

fn deploy_contract(name: ByteArray) -> ContractAddress {
    let contract = declare(name).unwrap().contract_class();
    let (contract_address, _) = contract.deploy(@ArrayTrait::new()).unwrap();
    contract_address
}

#[test]
fn test_constructor() {
    let contract_address = deploy_contract("BookstoreContract");
    let dispatcher = IBookstoreDispatcher { contract_address };

    assert_eq!(dispatcher.get_book_count(), 0, "Constructor not initialized properly"); 
}

#[test]
fn test_add_book() {
    let contract_address = deploy_contract("BookstoreContract");
    let dispatcher = IBookstoreDispatcher { contract_address };

    let book_1 = dispatcher.add_book(title: 'Book 1', author: 'Michael James' , category: Category::NONFICTION , year_of_publication: 1999);
    let book_2 = dispatcher.add_book(title: 'Book 2', author: 'King Zamunda' , category: Category::SCI_FI , year_of_publication: 2022);

    assert(dispatcher.get_book_by_id(1) == book_1, 'Book not added successfully.');
    assert(dispatcher.get_book_by_id(2) == book_2, 'Book not added successfully.');
}

#[test]
fn test_remove_book() {
    let contract_address = deploy_contract("BookstoreContract");
    let dispatcher = IBookstoreDispatcher { contract_address };

    dispatcher.add_book(title: 'Book 1', author: 'Michael James' , category: Category::NONFICTION , year_of_publication: 1999);
    dispatcher.add_book(title: 'Book 2', author: 'King Zamunda' , category: Category::SCI_FI , year_of_publication: 2022);
    
    let removed_book_1 = dispatcher.remove_book(1);
    let removed_book_2 = dispatcher.remove_book(2);

    assert_eq!(removed_book_1, Book {
        id: 0, 
        owner: Zero::zero(),
        title: 0, 
        author: 0, 
        category: Category::NULL, 
        year_of_publication: 0
    }, "Book 1 has not been removed"); 
    
    assert_eq!(removed_book_2, Book {
        id: 0, 
        owner: Zero::zero(),
        title: 0, 
        author: 0, 
        category: Category::NULL, 
        year_of_publication: 0
    }, "Book 2 has not been removed"); 


}

#[test]
#[should_panic(expected: ('Book does not exist', ))]
fn test_remove_invalid_book() {
    let contract_address = deploy_contract("BookstoreContract");
    let dispatcher = IBookstoreDispatcher { contract_address };

    dispatcher.remove_book(1);
}


#[test]
#[should_panic(expected: ('Invalid ID', ))]
fn test_try_get_invalid_book() {
    let contract_address = deploy_contract("BookstoreContract");
    let dispatcher = IBookstoreDispatcher { contract_address };
    
    dispatcher.get_book_by_id(0);
}

#[test]
#[should_panic(expected: ('Book does not exist', ))]
fn test_try_get_removed_book() {
    let contract_address = deploy_contract("BookstoreContract");
    let dispatcher = IBookstoreDispatcher { contract_address };

    dispatcher.add_book(title: 'Book 1', author: 'Michael James' , category: Category::NONFICTION , year_of_publication: 1999);
    dispatcher.add_book(title: 'Book 2', author: 'King Zamunda' , category: Category::SCI_FI , year_of_publication: 2022);
    
    dispatcher.remove_book(1);
    dispatcher.remove_book(2);

    dispatcher.get_book_by_id(1);
}

#[test]
fn test_buy_book() {
    let contract_address = deploy_contract("BookstoreContract");
    let dispatcher = IBookstoreDispatcher { contract_address };

    dispatcher.add_book(title: 'Book 1', author: 'Michael James' , category: Category::NONFICTION , year_of_publication: 1999);
    dispatcher.add_book(title: 'Book 2', author: 'King Zamunda' , category: Category::SCI_FI , year_of_publication: 2022);
    
    start_cheat_caller_address(contract_address, Accounts::account1());
    dispatcher.buy_book(1);
    let book_1 = dispatcher.get_book_by_id(1);
    assert_eq!(book_1.owner, Accounts::account1(), "fake_address_1 does not own book_1");
    stop_cheat_caller_address(contract_address);
    
    
    start_cheat_caller_address(contract_address, Accounts::account2());
    dispatcher.buy_book(2);
    let book_2 = dispatcher.get_book_by_id(2);
    assert_eq!(book_2.owner, Accounts::account2(), "fake_address_2 does not own book_2");
    stop_cheat_caller_address(contract_address);
}

#[test]
#[should_panic(expected: ('Invalid ID', ))]
fn test_buy_book_invalid_id() {
    let contract_address = deploy_contract("BookstoreContract");
    let dispatcher = IBookstoreDispatcher { contract_address };

    dispatcher.buy_book(0);
}

#[test]
#[should_panic(expected: ('Book does not exist', ))]
fn test_buy_book_that_does_not_exist() {
    let contract_address = deploy_contract("BookstoreContract");
    let dispatcher = IBookstoreDispatcher { contract_address };

    dispatcher.buy_book(1);
}
