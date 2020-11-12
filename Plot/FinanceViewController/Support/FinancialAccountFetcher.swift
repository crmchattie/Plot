//
//  FinancialAccountFetcher.swift
//  Plot
//
//  Created by Cory McHattie on 9/21/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import UIKit
import Firebase
import CodableFirebase

class FinancialAccountFetcher: NSObject {
        
    fileprivate var userAccountsDatabaseRef: DatabaseReference!
    fileprivate var currentUserAccountsAddHandle = DatabaseHandle()
    fileprivate var currentUserAccountsChangeHandle = DatabaseHandle()
    fileprivate var currentUserAccountsRemoveHandle = DatabaseHandle()
    
    var accountsAdded: (([MXAccount])->())?
    var accountsRemoved: (([MXAccount])->())?
    var accountsChanged: (([MXAccount])->())?
    
    fileprivate var isGroupAlreadyFinished = false
    
    func fetchAccounts(completion: @escaping ([MXAccount])->()) {
        guard let currentUserID = Auth.auth().currentUser?.uid else {
            completion([])
            return
        }
                
        let ref = Database.database().reference()
        userAccountsDatabaseRef = ref.child(userFinancialAccountsEntity).child(currentUserID)
        userAccountsDatabaseRef.observeSingleEvent(of: .value, with: { snapshot in
            if snapshot.exists(), let accountIDs = snapshot.value as? [String: AnyObject] {
                var accounts: [MXAccount] = []
                let group = DispatchGroup()
                for (accountID, userAccountInfo) in accountIDs {
                    group.enter()
                    if let userAccount = try? FirebaseDecoder().decode(UserAccount.self, from: userAccountInfo) {
                        ref.child(financialAccountsEntity).child(accountID).observeSingleEvent(of: .value, with: { accountSnapshot in
                            if accountSnapshot.exists(), let accountSnapshotValue = accountSnapshot.value {
                                if let account = try? FirebaseDecoder().decode(MXAccount.self, from: accountSnapshotValue) {
                                    var _account = account
                                    if let value = userAccount.name {
                                        _account.name = value
                                    }
                                    if let value = userAccount.should_link {
                                        _account.should_link = value
                                    }
                                    if let value = userAccount.tags {
                                        _account.tags = value
                                    }
                                    _account.badge = userAccount.badge
                                    _account.muted = userAccount.muted
                                    _account.pinned = userAccount.pinned
                                    accounts.append(_account)
                                }
                            }
                            group.leave()
                        })
                    } else {
                        ref.child(financialAccountsEntity).child(accountID).observeSingleEvent(of: .value, with: { accountSnapshot in
                            if accountSnapshot.exists(), let accountSnapshotValue = accountSnapshot.value {
                                if let account = try? FirebaseDecoder().decode(MXAccount.self, from: accountSnapshotValue) {
                                    accounts.append(account)
                                }
                            }
                            group.leave()
                        })
                    }
                }
                group.notify(queue: .main) {
                    completion(accounts)
                }
            } else {
                completion([])
            }
        })
    }
    
    func observeAccountForCurrentUser(accountsAdded: @escaping ([MXAccount])->()) {
        guard let _ = Auth.auth().currentUser?.uid else {
            return
        }
        self.accountsAdded = accountsAdded
        currentUserAccountsAddHandle = userAccountsDatabaseRef.observe(.childAdded, with: { snapshot in
            if let completion = self.accountsAdded {
                let accountID = snapshot.key
                let ref = Database.database().reference()
                var handle = UInt.max
                handle = ref.child(financialAccountsEntity).child(accountID).observe(.value) { _ in
                    ref.removeObserver(withHandle: handle)
                    self.getAccountsFromSnapshot(snapshot: snapshot, completion: completion)
                }
            }
        })        
    }
    
    func getAccountsFromSnapshot(snapshot: DataSnapshot, completion: @escaping ([MXAccount])->()) {
        if snapshot.exists() {
            guard let currentUserID = Auth.auth().currentUser?.uid else {
                return
            }
            let accountID = snapshot.key
            let ref = Database.database().reference()
            var accounts: [MXAccount] = []
            let group = DispatchGroup()
            group.enter()
            ref.child(userFinancialAccountsEntity).child(currentUserID).child(accountID).observeSingleEvent(of: .value, with: { snapshot in
                if snapshot.exists(), let userAccountInfo = snapshot.value {
                    if let userAccount = try? FirebaseDecoder().decode(UserAccount.self, from: userAccountInfo) {
                        ref.child(financialAccountsEntity).child(accountID).observeSingleEvent(of: .value, with: { accountSnapshot in
                            if accountSnapshot.exists(), let accountSnapshotValue = accountSnapshot.value {
                                if let account = try? FirebaseDecoder().decode(MXAccount.self, from: accountSnapshotValue) {
                                    var _account = account
                                    if let value = userAccount.name {
                                        _account.name = value
                                    }
                                    if let value = userAccount.should_link {
                                        _account.should_link = value
                                    }
                                    if let value = userAccount.tags {
                                        _account.tags = value
                                    }
                                    _account.badge = userAccount.badge
                                    _account.muted = userAccount.muted
                                    _account.pinned = userAccount.pinned
                                    accounts.append(_account)
                                }
                            }
                            group.leave()
                        })
                    } else {
                        ref.child(financialAccountsEntity).child(accountID).observeSingleEvent(of: .value, with: { accountSnapshot in
                            if accountSnapshot.exists(), let accountSnapshotValue = accountSnapshot.value {
                                if let account = try? FirebaseDecoder().decode(MXAccount.self, from: accountSnapshotValue) {
                                    accounts.append(account)
                                }
                            }
                            group.leave()
                        })
                    }
                }
            })
            group.notify(queue: .main) {
                completion(accounts)
            }
        } else {
            completion([])
        }
    }
}
