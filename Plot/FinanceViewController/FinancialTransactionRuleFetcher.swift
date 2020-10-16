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
    fileprivate var currentTransactionRulesAddHandle = DatabaseHandle()
    fileprivate var currentTransactionRulesChangeHandle = DatabaseHandle()
    fileprivate var currentTransactionRulesRemoveHandle = DatabaseHandle()
    
    
    var transactionRulesAdded: (([TransactionRule])->())?
    var transactionRulesRemoved: (([TransactionRule])->())?
    var transactionRulesChanged: (([TransactionRule])->())?
    
    fileprivate var isGroupAlreadyFinished = false
    
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
                for (_, userTransactionRuleInfo) in transactionRuleIDs {
                    group.enter()
                    if let userTransactionRule = try? FirebaseDecoder().decode(TransactionRule.self, from: userTransactionRuleInfo) {
                        transactionRules.append(userTransactionRule)
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
        guard let _ = Auth.auth().currentUser?.uid else {
            return
        }
        self.transactionRulesAdded = transactionRulesAdded
        self.transactionRulesRemoved = transactionRulesRemoved
        self.transactionRulesChanged = transactionRulesChanged
        currentTransactionRulesAddHandle = userTransactionRulesDatabaseRef.observe(.childAdded, with: { snapshot in
            if let completion = self.transactionRulesAdded {
                let transactionRuleID = snapshot.key
                let ref = Database.database().reference()
                var handle = UInt.max
                handle = ref.child(userFinancialTransactionRulesEntity).child(transactionRuleID).observe(.value) { _ in
                    ref.removeObserver(withHandle: handle)
                    self.getTransactionRulesFromSnapshot(snapshot: snapshot, completion: completion)
                }
            }
        })
        
        currentTransactionRulesChangeHandle = userTransactionRulesDatabaseRef.observe(.childChanged, with: { snapshot in
            if let completion = self.transactionRulesChanged {
                self.getTransactionRulesFromSnapshot(snapshot: snapshot, completion: completion)
            }
        })
        
    }
    
    func getTransactionRulesFromSnapshot(snapshot: DataSnapshot, completion: @escaping ([TransactionRule])->()) {
        if snapshot.exists() {
            guard let currentUserID = Auth.auth().currentUser?.uid else {
                return
            }
            let transactionRuleID = snapshot.key
            let ref = Database.database().reference()
            var transactionRules: [TransactionRule] = []
            let group = DispatchGroup()
            group.enter()
            ref.child(userFinancialTransactionRulesEntity).child(currentUserID).child(transactionRuleID).observeSingleEvent(of: .value, with: { snapshot in
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
        } else {
            completion([])
        }
    }
}
