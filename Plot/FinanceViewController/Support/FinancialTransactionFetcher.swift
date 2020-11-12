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
    
    
    var transactionsAdded: (([Transaction])->())?
    var transactionsRemoved: (([Transaction])->())?
    var transactionsChanged: (([Transaction])->())?
    
    fileprivate var isGroupAlreadyFinished = false
    
    func fetchTransactions(completion: @escaping ([Transaction])->()) {
        guard let currentUserID = Auth.auth().currentUser?.uid else {
            completion([])
            return
        }
                
        let ref = Database.database().reference()
        userTransactionsDatabaseRef = ref.child(userFinancialTransactionsEntity).child(currentUserID)
        userTransactionsDatabaseRef.observeSingleEvent(of: .value, with: { snapshot in
            if snapshot.exists(), let transactionIDs = snapshot.value as? [String: AnyObject] {
                var transactions: [Transaction] = []
                let group = DispatchGroup()
                for (transactionID, userTransactionInfo) in transactionIDs {
                    if let userTransaction = try? FirebaseDecoder().decode(UserTransaction.self, from: userTransactionInfo) {
                        group.enter()
                        ref.child(financialTransactionsEntity).child(transactionID).observeSingleEvent(of: .value, with: { transactionSnapshot in
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
                    } else {
                        group.enter()
                        ref.child(financialTransactionsEntity).child(transactionID).observeSingleEvent(of: .value, with: { transactionSnapshot in
                            if transactionSnapshot.exists(), let transactionSnapshotValue = transactionSnapshot.value {
                                if let transaction = try? FirebaseDecoder().decode(Transaction.self, from: transactionSnapshotValue) {
                                    transactions.append(transaction)
                                }
                            }
                            group.leave()
                        })
                    }
                }
                group.notify(queue: .main) {
                    completion(transactions)
                }
            } else {
                completion([])
            }
        })
    }
    
    func observeTransactionForCurrentUser(transactionsAdded: @escaping ([Transaction])->()) {
        guard let _ = Auth.auth().currentUser?.uid else {
            return
        }
        self.transactionsAdded = transactionsAdded
        currentUserTransactionsAddHandle = userTransactionsDatabaseRef.observe(.childAdded, with: { snapshot in
            if let completion = self.transactionsAdded {
                let transactionID = snapshot.key
                let ref = Database.database().reference()
                var handle = UInt.max
                handle = ref.child(financialTransactionsEntity).child(transactionID).observe(.value) { _ in
                    ref.removeObserver(withHandle: handle)
                    self.getTransactionsFromSnapshot(snapshot: snapshot, completion: completion)
                }
            }
        })
    }
    
    func getTransactionsFromSnapshot(snapshot: DataSnapshot, completion: @escaping ([Transaction])->()) {
        if snapshot.exists() {
            guard let currentUserID = Auth.auth().currentUser?.uid else {
                return
            }
            let transactionID = snapshot.key
            let ref = Database.database().reference()
            var transactions: [Transaction] = []
            let group = DispatchGroup()
            group.enter()
            ref.child(userFinancialTransactionsEntity).child(currentUserID).child(transactionID).observeSingleEvent(of: .value, with: { snapshot in
                if snapshot.exists(), let userTransactionInfo = snapshot.value {
                    if let userTransaction = try? FirebaseDecoder().decode(UserTransaction.self, from: userTransactionInfo) {
                        ref.child(financialTransactionsEntity).child(transactionID).observeSingleEvent(of: .value, with: { transactionSnapshot in
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
                    ref.child(financialTransactionsEntity).child(transactionID).observeSingleEvent(of: .value, with: { transactionSnapshot in
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
        } else {
            completion([])
        }
    }
}
