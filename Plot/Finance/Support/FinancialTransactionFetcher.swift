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
    
    var userTransactions: [String: UserTransaction] = [:]
        
    func observeTransactionForCurrentUser(transactionsInitialAdd: @escaping ([Transaction])->(), transactionsAdded: @escaping ([Transaction])->(), transactionsChanged: @escaping ([Transaction])->()) {
        guard let currentUserID = Auth.auth().currentUser?.uid else {
            return
        }
                
        let ref = Database.database().reference()
        userTransactionsDatabaseRef = ref.child(userFinancialTransactionsEntity).child(currentUserID)
        
        self.transactionsInitialAdd = transactionsInitialAdd
        self.transactionsAdded = transactionsAdded
        self.transactionsChanged = transactionsChanged
                
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
            reference.child(financialTransactionsEntity).queryOrdered(byChild: "account_guid").queryEqual(toValue: account.guid).observeSingleEvent(of: .childAdded, with: { (snapshot) in
                if snapshot.exists(), let transaction = try? FirebaseDecoder().decode(Transaction.self, from: snapshot), self.userTransactions[transaction.guid] == nil, let admin = transaction.admin {
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
                    }
                }
            })
        }
        
        group.notify(queue: .global()) {
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
}
