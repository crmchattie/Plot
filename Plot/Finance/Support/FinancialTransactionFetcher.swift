//
//  FinanceFetcher.swift
//  Plot
//
//  Created by Cory McHattie on 9/20/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import UIKit
import Firebase
import CodableFirebase

class FinancialTransactionFetcher: NSObject {
        
    fileprivate var userTransactionsDatabaseRef: DatabaseReference!
    fileprivate var currentUserTransactionsAddHandle = DatabaseHandle()
    fileprivate var currentUserTransactionsChangeHandle = DatabaseHandle()
    fileprivate var currentUserTransactionsRemoveHandle = DatabaseHandle()
    
    var transactionsInitialAdd: (([Transaction])->())?
    var transactionsAdded: (([Transaction])->())?
    var transactionsChanged: (([Transaction])->())?
    var transactionsRemoved: (([Transaction])->())?
    
    var userTransactions: [String: UserTransaction] = [:]
    var unloadedTransactions: [String: UserTransaction] = [:]
    
    var handles = [String: UInt]()
        
    func observeTransactionForCurrentUser(transactionsInitialAdd: @escaping ([Transaction])->(), transactionsAdded: @escaping ([Transaction])->(), transactionsRemoved: @escaping ([Transaction])->(), transactionsChanged: @escaping ([Transaction])->()) {
        guard let currentUserID = Auth.auth().currentUser?.uid else {
            return
        }
                
        let ref = Database.database().reference()
        userTransactionsDatabaseRef = ref.child(userFinancialTransactionsEntity).child(currentUserID)
        
        self.transactionsInitialAdd = transactionsInitialAdd
        self.transactionsAdded = transactionsAdded
        self.transactionsChanged = transactionsChanged
        self.transactionsRemoved = transactionsRemoved
                
        userTransactionsDatabaseRef.observeSingleEvent(of: .value, with: { snapshot in
            guard snapshot.exists() else {
                transactionsInitialAdd([])
                return
            }
            
            if let completion = self.transactionsInitialAdd {
                var transactions: [Transaction] = []
                let group = DispatchGroup()
                var counter = 0
                let transactionIDs = snapshot.value as? [String: AnyObject] ?? [:]
                for (ID, userTransactionInfo) in transactionIDs {
                    var handle = UInt.max
                    if let userTransaction = try? FirebaseDecoder().decode(UserTransaction.self, from: userTransactionInfo) {
                        self.userTransactions[ID] = userTransaction
                        
                        guard let transacted_at = userTransaction.transactionDate, transacted_at > Date().addMonths(-2) else {
                            self.unloadedTransactions[ID] = userTransaction
                            continue
                        }
                        
                        group.enter()
                        counter += 1
                        handle = ref.child(financialTransactionsEntity).child(ID).observe(.value) { snapshot in
                            ref.removeObserver(withHandle: handle)
                            if snapshot.exists(), let snapshotValue = snapshot.value {
                                if let transaction = try? FirebaseDecoder().decode(Transaction.self, from: snapshotValue), let userTransaction = self.userTransactions[ID] {
                                    var _transaction = transaction
                                    if let value = userTransaction.description {
                                        _transaction.description = value
                                    }
                                    if let value = userTransaction.group {
                                        _transaction.group = value
                                    }
                                    if let value = userTransaction.top_level_category {
                                        _transaction.top_level_category = value
                                    }
                                    if let value = userTransaction.category {
                                        _transaction.category = value
                                    }
                                    if let value = userTransaction.tags {
                                        _transaction.tags = value
                                    }
                                    if let value = userTransaction.should_link {
                                        _transaction.should_link = value
                                    }
                                    if let value = userTransaction.date_for_reports, value != "" {
                                        _transaction.date_for_reports = value
                                    }
                                    _transaction.badge = userTransaction.badge
                                    _transaction.muted = userTransaction.muted
                                    _transaction.pinned = userTransaction.pinned
                                    if counter > 0 {
                                        transactions.append(_transaction)
                                        group.leave()
                                        counter -= 1
                                    } else {
                                        transactions = [_transaction]
                                        completion(transactions)
                                        return
                                    }
                                }
                            } else {
                                if counter > 0 {
                                    group.leave()
                                    counter -= 1
                                }
                            }
                        }
                    }
                }
                group.notify(queue: .main) {
                    completion(transactions)
                }
            }
        })
        
        currentUserTransactionsAddHandle = userTransactionsDatabaseRef.observe(.childAdded, with: { snapshot in
            if self.userTransactions[snapshot.key] == nil {
                if let completion = self.transactionsAdded {
                    var handle = UInt.max
                    let ID = snapshot.key
                    self.getUserDataFromSnapshot(ID: ID) { transactionsList in
                        for userTransaction in transactionsList {
                            self.userTransactions[ID] = userTransaction
                            handle = ref.child(financialTransactionsEntity).child(ID).observe(.value) { snapshot in
                                ref.removeObserver(withHandle: handle)
                                if snapshot.exists(), let snapshotValue = snapshot.value {
                                    if let transaction = try? FirebaseDecoder().decode(Transaction.self, from: snapshotValue), let userTransaction = self.userTransactions[ID] {
                                        var _transaction = transaction
                                        if let value = userTransaction.description {
                                            _transaction.description = value
                                        }
                                        if let value = userTransaction.group {
                                            _transaction.group = value
                                        }
                                        if let value = userTransaction.top_level_category {
                                            _transaction.top_level_category = value
                                        }
                                        if let value = userTransaction.category {
                                            _transaction.category = value
                                        }
                                        if let value = userTransaction.tags {
                                            _transaction.tags = value
                                        }
                                        if let value = userTransaction.should_link {
                                            _transaction.should_link = value
                                        }
                                        if let value = userTransaction.date_for_reports, value != "" {
                                            _transaction.date_for_reports = value
                                        }
                                        _transaction.badge = userTransaction.badge
                                        _transaction.muted = userTransaction.muted
                                        _transaction.pinned = userTransaction.pinned
                                        completion([_transaction])
                                    }
                                }
                            }
                        }
                    }
                }
            }
        })
        
        currentUserTransactionsRemoveHandle = userTransactionsDatabaseRef.observe(.childRemoved, with: { snapshot in
            if let completion = self.transactionsRemoved {
                self.userTransactions[snapshot.key] = nil
                self.unloadedTransactions[snapshot.key] = nil
                FinancialTransactionFetcher.getDataFromSnapshot(ID: snapshot.key, completion: completion)
            }
        })
        
        currentUserTransactionsChangeHandle = userTransactionsDatabaseRef.observe(.childChanged, with: { snapshot in
            if let completion = self.transactionsChanged {
                FinancialTransactionFetcher.getDataFromSnapshot(ID: snapshot.key) { transactionsList in
                    for transaction in transactionsList {
                        self.userTransactions[transaction.guid] = UserTransaction(transaction: transaction)
                    }
                    completion(transactionsList)
                }
            }
        })
    }
    
    class func getDataFromSnapshot(ID: String, completion: @escaping ([Transaction])->()) {
        guard let currentUserID = Auth.auth().currentUser?.uid else {
            return
        }
        let ref = Database.database().reference()
        var transactions: [Transaction] = []
        let group = DispatchGroup()
        group.enter()
        ref.child(userFinancialTransactionsEntity).child(currentUserID).child(ID).observeSingleEvent(of: .value, with: { snapshot in
            if snapshot.exists(), let userTransactionInfo = snapshot.value {
                if let userTransaction = try? FirebaseDecoder().decode(UserTransaction.self, from: userTransactionInfo) {
                    ref.child(financialTransactionsEntity).child(ID).observeSingleEvent(of: .value, with: { transactionSnapshot in
                        if transactionSnapshot.exists(), let transactionSnapshotValue = transactionSnapshot.value {
                            if let transaction = try? FirebaseDecoder().decode(Transaction.self, from: transactionSnapshotValue) {
                                var _transaction = transaction
                                if let value = userTransaction.description {
                                    _transaction.description = value
                                }
                                if let value = userTransaction.group {
                                    _transaction.group = value
                                }
                                if let value = userTransaction.top_level_category {
                                    _transaction.top_level_category = value
                                }
                                if let value = userTransaction.category {
                                    _transaction.category = value
                                }
                                if let value = userTransaction.tags {
                                    _transaction.tags = value
                                }
                                if let value = userTransaction.should_link {
                                    _transaction.should_link = value
                                }
                                if let value = userTransaction.date_for_reports, value != "" {
                                    _transaction.date_for_reports = value
                                }
                                _transaction.badge = userTransaction.badge
                                _transaction.muted = userTransaction.muted
                                _transaction.pinned = userTransaction.pinned
                                transactions.append(_transaction)
                            }
                        }
                        group.leave()
                    })
                }
            } else {
                ref.child(financialTransactionsEntity).child(ID).observeSingleEvent(of: .value, with: { transactionSnapshot in
                    if transactionSnapshot.exists(), let transactionSnapshotValue = transactionSnapshot.value {
                        if let transaction = try? FirebaseDecoder().decode(Transaction.self, from: transactionSnapshotValue) {
                            transactions.append(transaction)
                        }
                    }
                    group.leave()
                })
            }
        })
        group.notify(queue: .main) {
            completion(transactions)
        }
    }
    
    func getUserDataFromSnapshot(ID: String, completion: @escaping ([UserTransaction])->()) {
        guard let currentUserID = Auth.auth().currentUser?.uid else {
            return
        }
        let ref = Database.database().reference()
        var transactions: [UserTransaction] = []
        let group = DispatchGroup()
        group.enter()
        ref.child(userFinancialTransactionsEntity).child(currentUserID).child(ID).observeSingleEvent(of: .value, with: { snapshot in
            if snapshot.exists(), let userTransactionInfo = snapshot.value {
                if let userTransaction = try? FirebaseDecoder().decode(UserTransaction.self, from: userTransactionInfo) {
                    transactions.append(userTransaction)
                    group.leave()
                }
            }
        })
        group.notify(queue: .main) {
            completion(transactions)
        }
    }
    
    func getDataFromSnapshotWObserver(ID: String, completion: @escaping ([Transaction])->()) {
        let ref = Database.database().reference()
        var handle = UInt.max
        handle = ref.child(financialTransactionsEntity).child(ID).observe(.value) { snapshot in
            self.handles[ID] = handle
            if snapshot.exists(), let snapshotValue = snapshot.value {
                if let transaction = try? FirebaseDecoder().decode(Transaction.self, from: snapshotValue), let userTransaction = self.userTransactions[ID] {
                    var _transaction = transaction
                    if let value = userTransaction.description {
                        _transaction.description = value
                    }
                    if let value = userTransaction.group {
                        _transaction.group = value
                    }
                    if let value = userTransaction.top_level_category {
                        _transaction.top_level_category = value
                    }
                    if let value = userTransaction.category {
                        _transaction.category = value
                    }
                    if let value = userTransaction.tags {
                        _transaction.tags = value
                    }
                    if let value = userTransaction.should_link {
                        _transaction.should_link = value
                    }
                    if let value = userTransaction.date_for_reports, value != "" {
                        _transaction.date_for_reports = value
                    }
                    _transaction.badge = userTransaction.badge
                    _transaction.muted = userTransaction.muted
                    _transaction.pinned = userTransaction.pinned
                    completion([_transaction])
                } else {
                    completion([])
                }
            } else {
                completion([])
            }
        }
    }
    
    func removeObservers() {
        let ref = Database.database().reference()
        for (ID, handle) in handles {
            ref.child(financialTransactionsEntity).child(ID).removeObserver(withHandle: handle)
        }
    }
    
    func grabTransactionsViaAccounts(accounts: [MXAccount], completion: @escaping ([Transaction])->()) {
        guard let currentUserID = Auth.auth().currentUser?.uid else {
            return
        }
        
        var transactions: [Transaction] = []
        let group = DispatchGroup()
        let filteredAccounts = accounts.filter({ $0.admin != currentUserID })
        for account in filteredAccounts {
            group.enter()
            let reference = Database.database().reference()
            reference.child(financialTransactionsEntity).queryOrdered(byChild: "account_guid").queryEqual(toValue: account.guid).observeSingleEvent(of: .value, with: { (snapshot) in
                if snapshot.exists(), let snapshotValue = snapshot.value as? [String: AnyObject] {
                    for (ID, transactionValue) in snapshotValue {
                        if self.userTransactions[ID] == nil, let transaction = try? FirebaseDecoder().decode(Transaction.self, from: transactionValue), let admin = transaction.admin {
                            group.enter()
                            self.getUserDataFromSnapshotViaUser(ID: transaction.guid, userID: admin) { transactionList in
                                if let userTransaction = transactionList.first {
                                    var _transaction = transaction
                                    if let value = userTransaction.description {
                                        _transaction.description = value
                                    }
                                    if let value = userTransaction.group {
                                        _transaction.group = value
                                    }
                                    if let value = userTransaction.top_level_category {
                                        _transaction.top_level_category = value
                                    }
                                    if let value = userTransaction.category {
                                        _transaction.category = value
                                    }
                                    if let value = userTransaction.tags {
                                        _transaction.tags = value
                                    }
                                    if let value = userTransaction.should_link {
                                        _transaction.should_link = value
                                    }
                                    if let value = userTransaction.date_for_reports, value != "" {
                                        _transaction.date_for_reports = value
                                    }
                                    transactions.append(_transaction)
                                }
                                group.leave()
                            }
                        }
                    }
                }
                group.leave()
            })
        }
        
        group.notify(queue: .main) {
            completion(transactions)
        }
    }
    
    func getUserDataFromSnapshotViaUser(ID: String, userID: String, completion: @escaping ([UserTransaction])->()) {
        let ref = Database.database().reference()
        var transactions: [UserTransaction] = []
        let group = DispatchGroup()
        group.enter()
        ref.child(userFinancialTransactionsEntity).child(userID).child(ID).observeSingleEvent(of: .value, with: { snapshot in
            if snapshot.exists(), let userTransactionInfo = snapshot.value {
                if let userTransaction = try? FirebaseDecoder().decode(UserTransaction.self, from: userTransactionInfo) {
                    transactions.append(userTransaction)
                    group.leave()
                }
            }
        })
        group.notify(queue: .main) {
            completion(transactions)
        }
    }
    
    func loadUnloadedTransaction(startDate: Date?, endDate: Date?, completion: @escaping ([Transaction])->()) {
        let group = DispatchGroup()
        var counter = 0
        var transactions: [Transaction] = []
        if let startDate = startDate, let endDate = endDate {
            let IDs = unloadedTransactions.filter {
                $0.value.transactionDate ?? Date.distantPast > startDate &&
                $0.value.transactionDate ?? Date.distantFuture < endDate
            }
            for (ID, _) in IDs {
                group.enter()
                counter += 1
                self.getDataFromSnapshotWObserver(ID: ID) { transactionList in
                    if counter > 0 {
                        transactions.append(contentsOf: transactionList)
                        group.leave()
                        counter -= 1
                    } else {
                        completion(transactionList)
                    }
                }
            }
            group.notify(queue: .main) {
                transactions.sort { (transaction1, transaction2) -> Bool in
                    if transaction1.should_link ?? true == transaction2.should_link ?? true {
                        if let date1 = transaction1.transactionDate, let date2 = transaction2.transactionDate {
                            return date1 > date2
                        }
                        return transaction1.description < transaction2.description
                    }
                    return transaction1.should_link ?? true && !(transaction2.should_link ?? true)
                }
                completion(transactions)
            }
        } else {
            for (ID, _) in unloadedTransactions {
                group.enter()
                counter += 1
                self.getDataFromSnapshotWObserver(ID: ID) { transactionList in
                    if counter > 0 {
                        transactions.append(contentsOf: transactionList)
                        group.leave()
                        counter -= 1
                    } else {
                        completion(transactionList)
                    }
                }
            }
            group.notify(queue: .main) {
                transactions.sort { (transaction1, transaction2) -> Bool in
                    if transaction1.should_link ?? true == transaction2.should_link ?? true {
                        if let date1 = transaction1.transactionDate, let date2 = transaction2.transactionDate {
                            return date1 > date2
                        }
                        return transaction1.description < transaction2.description
                    }
                    return transaction1.should_link ?? true && !(transaction2.should_link ?? true)
                }
                completion(transactions)
            }
        }
    }
}
