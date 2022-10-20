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
    
    var accountsInitialAdd: (([MXAccount])->())?
    var accountsAdded: (([MXAccount])->())?
    var accountsChanged: (([MXAccount])->())?
    
    func observeAccountForCurrentUser(accountsInitialAdd: @escaping ([MXAccount])->(), accountsAdded: @escaping ([MXAccount])->(), accountsChanged: @escaping ([MXAccount])->()) {
        guard let currentUserID = Auth.auth().currentUser?.uid else {
            return
        }
                
        let ref = Database.database().reference()
        userAccountsDatabaseRef = ref.child(userFinancialAccountsEntity).child(currentUserID)
        
        self.accountsInitialAdd = accountsInitialAdd
        self.accountsAdded = accountsAdded
        self.accountsChanged = accountsChanged
        
        var userAccounts: [String: UserAccount] = [:]
        
        userAccountsDatabaseRef.observeSingleEvent(of: .value, with: { snapshot in
            guard snapshot.exists() else {
                accountsInitialAdd([])
                return
            }
            
            if let completion = self.accountsInitialAdd {
                var accounts: [MXAccount] = []
                let group = DispatchGroup()
                var counter = 0
                let accountIDs = snapshot.value as? [String: AnyObject] ?? [:]
                for (ID, userAccountInfo) in accountIDs {
                    var handle = UInt.max
                    if let userAccount = try? FirebaseDecoder().decode(UserAccount.self, from: userAccountInfo) {
                        userAccounts[ID] = userAccount
                        group.enter()
                        counter += 1
                        handle = ref.child(financialAccountsEntity).child(ID).observe(.value) { snapshot in
                            ref.removeObserver(withHandle: handle)
                            if snapshot.exists(), let snapshotValue = snapshot.value {
                                if let account = try? FirebaseDecoder().decode(MXAccount.self, from: snapshotValue), let userAccount = userAccounts[ID] {
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
                                    if counter > 0 {
                                        accounts.append(_account)
                                        group.leave()
                                        counter -= 1
                                    } else {
                                        accounts = [_account]
                                        completion(accounts)
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
                    completion(accounts)
                }
            }
        })
        
        currentUserAccountsAddHandle = userAccountsDatabaseRef.observe(.childAdded, with: { snapshot in
            if userAccounts[snapshot.key] == nil {
                if let completion = self.accountsAdded {
                    var handle = UInt.max
                    let ID = snapshot.key
                    self.getUserDataFromSnapshot(ID: ID) { accountsList in
                        for userAccount in accountsList {
                            userAccounts[ID] = userAccount
                            handle = ref.child(financialAccountsEntity).child(ID).observe(.value) { snapshot in
                                ref.removeObserver(withHandle: handle)
                                if snapshot.exists(), let snapshotValue = snapshot.value {
                                    if let account = try? FirebaseDecoder().decode(MXAccount.self, from: snapshotValue), let userAccount = userAccounts[ID] {
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
                                        completion([_account])
                                    }
                                }
                            }
                        }
                    }
                }
            }
        })
        
        currentUserAccountsChangeHandle = userAccountsDatabaseRef.observe(.childChanged, with: { snapshot in
            if let completion = self.accountsChanged {
                FinancialAccountFetcher.getDataFromSnapshot(ID: snapshot.key) { accountsList in
                    for account in accountsList {
                        userAccounts[account.guid] = UserAccount(account: account)
                    }
                    completion(accountsList)
                }
            }
        })
    }
    
    class func getDataFromSnapshot(ID: String, completion: @escaping ([MXAccount])->()) {
        guard let currentUserID = Auth.auth().currentUser?.uid else {
            return
        }
        let ref = Database.database().reference()
        var accounts: [MXAccount] = []
        let group = DispatchGroup()
        group.enter()
        ref.child(userFinancialAccountsEntity).child(currentUserID).child(ID).observeSingleEvent(of: .value, with: { snapshot in
            if snapshot.exists(), let userAccountInfo = snapshot.value {
                if let userAccount = try? FirebaseDecoder().decode(UserAccount.self, from: userAccountInfo) {
                    ref.child(financialAccountsEntity).child(ID).observeSingleEvent(of: .value, with: { accountSnapshot in
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
                    ref.child(financialAccountsEntity).child(ID).observeSingleEvent(of: .value, with: { accountSnapshot in
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
    }
    
    func getUserDataFromSnapshot(ID: String, completion: @escaping ([UserAccount])->()) {
        guard let currentUserID = Auth.auth().currentUser?.uid else {
            return
        }
        let ref = Database.database().reference()
        var accounts: [UserAccount] = []
        let group = DispatchGroup()
        group.enter()
        ref.child(userFinancialAccountsEntity).child(currentUserID).child(ID).observeSingleEvent(of: .value, with: { snapshot in
            if snapshot.exists(), let userAccountInfo = snapshot.value {
                if let userAccount = try? FirebaseDecoder().decode(UserAccount.self, from: userAccountInfo) {
                    accounts.append(userAccount)
                    group.leave()
                }
            }
        })
        group.notify(queue: .main) {
            completion(accounts)
        }
    }
}
