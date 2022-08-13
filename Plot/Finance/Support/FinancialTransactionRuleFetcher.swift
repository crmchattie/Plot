//
//  FinancialTransactionRuleFetcher.swift
//  Plot
//
//  Created by Cory McHattie on 10/15/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import UIKit
import Firebase
import CodableFirebase

class FinancialTransactionRuleFetcher: NSObject {
        
    fileprivate var userTransactionRulesDatabaseRef: DatabaseReference!
    fileprivate var currentUserTransactionRulesAddHandle = DatabaseHandle()
    fileprivate var currentUserTransactionRulesChangeHandle = DatabaseHandle()
    fileprivate var currentUserTransactionRulesRemoveHandle = DatabaseHandle()
    
    var transactionRulesAdded: (([TransactionRule])->())?
    var transactionRulesRemoved: (([TransactionRule])->())?
    var transactionRulesChanged: (([TransactionRule])->())?
    
    var IDs: [String] = []
        
    func fetchTransactionRules(completion: @escaping ([TransactionRule])->()) {
        guard let currentUserID = Auth.auth().currentUser?.uid else {
            completion([])
            return
        }
                
        let ref = Database.database().reference()
        userTransactionRulesDatabaseRef = ref.child(userFinancialTransactionRulesEntity).child(currentUserID)
        userTransactionRulesDatabaseRef.observeSingleEvent(of: .value, with: { snapshot in
            if snapshot.exists(), let transactionRuleIDs = snapshot.value as? [String: AnyObject] {
                var transactionRules: [TransactionRule] = []
                let group = DispatchGroup()
                for (ID, userTransactionRuleInfo) in transactionRuleIDs {
                    group.enter()
                    if let userTransactionRule = try? FirebaseDecoder().decode(TransactionRule.self, from: userTransactionRuleInfo) {
                        transactionRules.append(userTransactionRule)
                        self.IDs.append(ID)
                        group.leave()
                    }
                }
                
                group.notify(queue: .main) {
                    completion(transactionRules)
                }
            } else {
                completion([])
            }
        })
    }
    
    func observeTransactionRuleForCurrentUser(transactionRulesAdded: @escaping ([TransactionRule])->(), transactionRulesRemoved: @escaping ([TransactionRule])->(), transactionRulesChanged: @escaping ([TransactionRule])->()) {
        guard let currentUserID = Auth.auth().currentUser?.uid else {
            return
        }
                
        let ref = Database.database().reference()
        userTransactionRulesDatabaseRef = ref.child(userFinancialTransactionRulesEntity).child(currentUserID)
        
        self.transactionRulesAdded = transactionRulesAdded
        self.transactionRulesRemoved = transactionRulesRemoved
        self.transactionRulesChanged = transactionRulesChanged
        
        currentUserTransactionRulesAddHandle = userTransactionRulesDatabaseRef.observe(.childAdded, with: { snapshot in
            if !self.IDs.contains(snapshot.key) {
                if let completion = self.transactionRulesAdded {
                    self.getDataFromSnapshot(ID: snapshot.key, completion: completion)
                }
            }
        })
        
        currentUserTransactionRulesChangeHandle = userTransactionRulesDatabaseRef.observe(.childChanged, with: { snapshot in
            if let completion = self.transactionRulesChanged {
                self.getDataFromSnapshot(ID: snapshot.key, completion: completion)
            }
        })
        
        currentUserTransactionRulesRemoveHandle = userTransactionRulesDatabaseRef.observe(.childRemoved, with: { snapshot in
            if let completion = self.transactionRulesRemoved {
                self.getDataFromSnapshot(ID: snapshot.key, completion: completion)
            }
        })
        
    }
    
    func getDataFromSnapshot(ID: String, completion: @escaping ([TransactionRule])->()) {
        guard let currentUserID = Auth.auth().currentUser?.uid else {
            return
        }
        let ref = Database.database().reference()
        var transactionRules: [TransactionRule] = []
        let group = DispatchGroup()
        group.enter()
        ref.child(userFinancialTransactionRulesEntity).child(currentUserID).child(ID).observeSingleEvent(of: .value, with: { snapshot in
            if snapshot.exists(), let userTransactionRuleInfo = snapshot.value {
                if let userTransactionRule = try? FirebaseDecoder().decode(TransactionRule.self, from: userTransactionRuleInfo) {
                    transactionRules.append(userTransactionRule)
                    group.leave()
                }
            }
        })
        
        group.notify(queue: .main) {
            completion(transactionRules)
        }
    }
}
