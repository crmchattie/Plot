//
//  FinancialAccountActions.swift
//  Plot
//
//  Created by Cory McHattie on 10/13/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import UIKit
import Firebase
import CodableFirebase

class AccountActions: NSObject {
    
    var account: MXAccount!
    var ID: String?
    var active: Bool?
    var selectedFalconUsers: [User]?
    
    let isodateFormatter = ISO8601DateFormatter()
    
    let dispatchGroup = DispatchGroup()
        
    init(account: MXAccount, active: Bool?, selectedFalconUsers: [User]) {
        super.init()
        self.account = account
        self.ID = account.guid
        self.active = active
        self.selectedFalconUsers = selectedFalconUsers
    
    }
    
    func deleteAccount() {
        guard currentReachabilityStatus != .notReachable else {
            return
        }
        
        guard let _ = active, let _ = account, let ID = ID, let _ = selectedFalconUsers else {
            return
        }
                          
        let membersIDs = fetchMembersIDs()
        
        for memberID in membersIDs.0 {
        Database.database().reference().child(userFinancialAccountsEntity).child(memberID).child(ID).removeAllObservers()
        Database.database().reference().child(userFinancialAccountsEntity).child(memberID).child(ID).removeValue()
        }
                
    }
    
    func createNewAccount() {
        guard currentReachabilityStatus != .notReachable else {
            return
        }
        
        guard let active = active, let _ = account, let ID = ID, let _ = selectedFalconUsers else {
            return
        }
        
        if account.admin == nil {
            account.admin = Auth.auth().currentUser?.uid
        }
        
        let membersIDs = fetchMembersIDs()
        account.participantsIDs = membersIDs.0
        account.updated_at = isodateFormatter.string(from: Date())
        
        let groupAccountReference = Database.database().reference().child(financialAccountsEntity).child(ID)

        do {
            let value = try FirebaseEncoder().encode(account)
            groupAccountReference.setValue(value)
        } catch let error {
            print(error)
        }
        
        incrementBadgeForReciever(ID: ID, participantsIDs: membersIDs.0)
        
        if !active {
            dispatchGroup.enter()
            connectMembersToGroupAccount(memberIDs: membersIDs.0, ID: ID)
        }
    }
    
    func updateAccountParticipants() {
        guard let _ = active, let account = account, let ID = ID else {
            return
        }
        let membersIDs = fetchMembersIDs()
        if let participantsIDs = account.participantsIDs, Set(participantsIDs) != Set(membersIDs.0) {
            let groupAccountReference = Database.database().reference().child(financialAccountsEntity).child(ID)
            updateParticipants(membersIDs: membersIDs)
            groupAccountReference.updateChildValues(["participantsIDs": membersIDs.0 as AnyObject])
            let date = isodateFormatter.string(from: Date())
            groupAccountReference.updateChildValues(["updated_at": date as AnyObject])
        } else if account.participantsIDs == nil {
            let groupAccountReference = Database.database().reference().child(financialAccountsEntity).child(ID)
            groupAccountReference.updateChildValues(["participantsIDs": membersIDs.0 as AnyObject])
            let date = isodateFormatter.string(from: Date())
            groupAccountReference.updateChildValues(["updated_at": date as AnyObject])
            for memberID in membersIDs.0.filter({$0 != account.admin}) {
                let userReference = Database.database().reference().child(userFinancialAccountsEntity).child(memberID).child(ID)
                let values:[String : Any] = ["name": "\(account.name)"]
                userReference.setValue(values)
            }
        }
        
    }
    
    func fetchMembersIDs() -> ([String], [String:AnyObject]) {
        var membersIDs = [String]()
        var membersIDsDictionary = [String:AnyObject]()
        
        guard let account = account, let selectedFalconUsers = selectedFalconUsers else {
            return (membersIDs, membersIDsDictionary)
        }
        
        guard let currentUserID = Auth.auth().currentUser?.uid else { return (membersIDs, membersIDsDictionary) }
        
        // Only append current user when admin/creator of the account
        if account.admin == currentUserID {
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
    
    func connectMembersToGroupAccount(memberIDs: [String], ID: String) {
        let connectingMembersGroup = DispatchGroup()
        for _ in memberIDs {
            connectingMembersGroup.enter()
        }
        connectingMembersGroup.notify(queue: DispatchQueue.main, execute: {
            self.dispatchGroup.leave()
        })
        for memberID in memberIDs {
            let userReference = Database.database().reference().child(userFinancialAccountsEntity).child(memberID).child(ID)
            let values:[String : Any] = ["name": "\(account.name)", "should_link": false]
            userReference.updateChildValues(values, withCompletionBlock: { (error, reference) in
                connectingMembersGroup.leave()
            })
        }
    }

    func createGroupAccountNode(reference: DatabaseReference, childValues: [String: Any]) {
        let nodeCreationGroup = DispatchGroup()
        nodeCreationGroup.enter()
        nodeCreationGroup.notify(queue: DispatchQueue.main, execute: {
            self.dispatchGroup.leave()
        })
        reference.updateChildValues(childValues) { (error, reference) in
            nodeCreationGroup.leave()
        }
    }
    
    func updateParticipants(membersIDs: ([String], [String:AnyObject])) {
        guard let account = account, let ID = ID else {
            return
        }
        let participantsSet = Set(account.participantsIDs!)
        let membersSet = Set(membersIDs.0)
        let difference = participantsSet.symmetricDifference(membersSet)
        for member in difference {
            if participantsSet.contains(member) {
                Database.database().reference().child(userFinancialAccountsEntity).child(member).child(ID).removeValue()
            }
            
            dispatchGroup.enter()
            
            connectMembersToGroupAccount(memberIDs: membersIDs.0, ID: ID)
        }
    }
    
    func incrementBadgeForReciever(ID: String?, participantsIDs: [String]) {
        guard let currentUserID = Auth.auth().currentUser?.uid, let ID = ID else { return }
        for participantID in participantsIDs where participantID != currentUserID {
            runAccountBadgeUpdate(firstChild: participantID, secondChild: ID)
            runUserBadgeUpdate(firstChild: participantID)
        }
    }

    func runAccountBadgeUpdate(firstChild: String, secondChild: String) {
        var ref = Database.database().reference().child(userFinancialAccountsEntity).child(firstChild).child(secondChild)
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
