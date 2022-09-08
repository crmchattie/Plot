//
//  FinancialTransactionActions.swift
//  Plot
//
//  Created by Cory McHattie on 10/13/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import UIKit
import Firebase
import CodableFirebase

class TransactionActions: NSObject {
    
    var transaction: Transaction!
    var ID: String?
    var active: Bool?
    var selectedFalconUsers: [User]?
    
    let isodateFormatter = ISO8601DateFormatter()
    
    let dispatchGroup = DispatchGroup()
        
    init(transaction: Transaction, active: Bool?, selectedFalconUsers: [User]) {
        super.init()
        self.transaction = transaction
        self.ID = transaction.guid
        self.active = active
        self.selectedFalconUsers = selectedFalconUsers
    
    }
    
    func deleteTransaction() {
        guard currentReachabilityStatus != .notReachable else {
            return
        }
        
        guard let _ = active, let _ = transaction, let ID = ID, let _ = selectedFalconUsers else {
            return
        }
                          
        let membersIDs = fetchMembersIDs()
        
        for memberID in membersIDs.0 {
            Database.database().reference().child(userFinancialTransactionsEntity).child(memberID).child(ID).removeAllObservers()
            Database.database().reference().child(userFinancialTransactionsEntity).child(memberID).child(ID).removeValue()
        }
                
    }
    
    func createNewTransaction() {
        guard currentReachabilityStatus != .notReachable else {
            return
        }
        
        guard let active = active, let _ = transaction, let ID = ID, let _ = selectedFalconUsers else {
            return
        }
        
        if transaction.admin == nil {
            transaction.admin = Auth.auth().currentUser?.uid
        }
        
        let membersIDs = fetchMembersIDs()
        transaction.participantsIDs = membersIDs.0
        transaction.updated_at = isodateFormatter.string(from: Date())
        
        let groupTransactionReference = Database.database().reference().child(financialTransactionsEntity).child(ID)
        do {
            let value = try FirebaseEncoder().encode(transaction)
            groupTransactionReference.setValue(value)
        } catch let error {
            print(error)
        }
        
        incrementBadgeForReciever(ID: ID, participantsIDs: membersIDs.0)
        
        if !active {
            Analytics.logEvent("new_transaction", parameters: [
                "connected_to_activity": transaction.activityID ?? "none" as NSObject
            ])
            dispatchGroup.enter()
            connectMembersToGroupTransaction(memberIDs: membersIDs.0, ID: ID)
        } else {
            Analytics.logEvent("update_transaction", parameters: [
                "connected_to_activity": transaction.activityID ?? "none" as NSObject
            ])
        }
    }
    
    func updateTransactionParticipants() {
        guard let _ = active, let transaction = transaction, let ID = ID else {
            return
        }
        let membersIDs = fetchMembersIDs()
        if let participantsIDs = transaction.participantsIDs, Set(participantsIDs) != Set(membersIDs.0) {
            let groupTransactionReference = Database.database().reference().child(financialTransactionsEntity).child(ID)
            updateParticipants(membersIDs: membersIDs)
            groupTransactionReference.updateChildValues(["participantsIDs": membersIDs.0 as AnyObject])
            let date = isodateFormatter.string(from: Date())
            groupTransactionReference.updateChildValues(["updated_at": date as AnyObject])
        } else if transaction.participantsIDs == nil {
            let groupTransactionReference = Database.database().reference().child(financialTransactionsEntity).child(ID)
            groupTransactionReference.updateChildValues(["participantsIDs": membersIDs.0 as AnyObject])
            let date = isodateFormatter.string(from: Date())
            groupTransactionReference.updateChildValues(["updated_at": date as AnyObject])
            for memberID in membersIDs.0.filter({$0 != transaction.admin}) {
                let userReference = Database.database().reference().child(userFinancialTransactionsEntity).child(memberID).child(ID)
                let values:[String : Any] = ["description": transaction.description]
                userReference.setValue(values)
            }
        }
    }
    
    func fetchMembersIDs() -> ([String], [String:AnyObject]) {
        var membersIDs = [String]()
        var membersIDsDictionary = [String:AnyObject]()
        
        guard let transaction = transaction, let selectedFalconUsers = selectedFalconUsers else {
            return (membersIDs, membersIDsDictionary)
        }
        
        guard let currentUserID = Auth.auth().currentUser?.uid else { return (membersIDs, membersIDsDictionary) }
        
        // Only append current user when admin/creator of the transaction
        if transaction.admin == currentUserID {
            membersIDsDictionary.updateValue(currentUserID as AnyObject, forKey: currentUserID)
            membersIDs.append(currentUserID)
        }
        
        for selectedUser in selectedFalconUsers {
            guard let id = selectedUser.id else { continue }
            membersIDsDictionary.updateValue(id as AnyObject, forKey: id)
            membersIDs.append(id)
        }
        
        return (membersIDs, membersIDsDictionary)
    }
    
    func connectMembersToGroupTransaction(memberIDs: [String], ID: String) {
        let connectingMembersGroup = DispatchGroup()
        for _ in memberIDs {
            connectingMembersGroup.enter()
        }
        connectingMembersGroup.notify(queue: DispatchQueue.main, execute: {
            self.dispatchGroup.leave()
        })
        for memberID in memberIDs {
            let userReference = Database.database().reference().child(userFinancialTransactionsEntity).child(memberID).child(ID)
            let values:[String : Any] = ["description": transaction.description, "should_link": false]
            userReference.updateChildValues(values, withCompletionBlock: { (error, reference) in
                connectingMembersGroup.leave()
            })
        }
    }
    
    func updateParticipants(membersIDs: ([String], [String:AnyObject])) {
        guard let transaction = transaction, let ID = ID else {
            return
        }
        let participantsSet = Set(transaction.participantsIDs!)
        let membersSet = Set(membersIDs.0)
        let difference = participantsSet.symmetricDifference(membersSet)
        for member in difference {
            if participantsSet.contains(member) {
                Database.database().reference().child(userFinancialTransactionsEntity).child(member).child(ID).removeValue()
            }
            
            dispatchGroup.enter()
            
            connectMembersToGroupTransaction(memberIDs: membersIDs.0, ID: ID)
        }
    }
    
    func incrementBadgeForReciever(ID: String?, participantsIDs: [String]) {
        guard let currentUserID = Auth.auth().currentUser?.uid, let ID = ID else { return }
        for participantID in participantsIDs where participantID != currentUserID {
            runTransactionBadgeUpdate(firstChild: participantID, secondChild: ID)
            runUserBadgeUpdate(firstChild: participantID)
        }
    }

    func runTransactionBadgeUpdate(firstChild: String, secondChild: String) {
        var ref = Database.database().reference().child(userFinancialTransactionsEntity).child(firstChild).child(secondChild)
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            
            guard snapshot.hasChild("badge") else {
                ref.updateChildValues(["badge": 1])
                return
            }
            ref = ref.child("badge")
            ref.runTransactionBlock({ (mutableData) -> TransactionResult in
                var value = mutableData.value as? Int
                if value == nil { value = 0 }
                mutableData.value = value! + 1
                return TransactionResult.success(withValue: mutableData)
            })
        })
    }
}
