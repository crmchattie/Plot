//
//  FinancialHoldingActions.swift
//  Plot
//
//  Created by Cory McHattie on 2/15/21.
//  Copyright © 2021 Immature Creations. All rights reserved.
//

import UIKit
import Firebase
import CodableFirebase

class HoldingActions: NSObject {
    
    var holding: MXHolding!
    var ID: String?
    var active: Bool?
    var selectedFalconUsers: [User]?
    
    let isodateFormatter = ISO8601DateFormatter()
    
    let dispatchGroup = DispatchGroup()
        
    init(holding: MXHolding, active: Bool?, selectedFalconUsers: [User]) {
        super.init()
        self.holding = holding
        self.ID = holding.guid
        self.active = active
        self.selectedFalconUsers = selectedFalconUsers
    
    }
    
    func deleteHolding() {
        guard currentReachabilityStatus != .notReachable else {
            return
        }
        
        guard let _ = active, let _ = holding, let ID = ID, let _ = selectedFalconUsers else {
            return
        }
                          
        let membersIDs = fetchMembersIDs()
        
        for memberID in membersIDs.0 {
            Database.database().reference().child(userFinancialHoldingsEntity).child(memberID).child(ID).removeAllObservers()
            Database.database().reference().child(userFinancialHoldingsEntity).child(memberID).child(ID).removeValue()
        }
                
    }
    
    func createNewHolding() {
        guard currentReachabilityStatus != .notReachable else {
            return
        }
        
        guard let active = active, let _ = holding, let ID = ID, let _ = selectedFalconUsers else {
            return
        }
        
        if holding.admin == nil {
            holding.admin = Auth.auth().currentUser?.uid
        }
        
        let membersIDs = fetchMembersIDs()
        holding.participantsIDs = membersIDs.0
        holding.updated_at = isodateFormatter.string(from: Date())
        
        let groupHoldingReference = Database.database().reference().child(financialHoldingsEntity).child(ID)
        do {
            let value = try FirebaseEncoder().encode(holding)
            groupHoldingReference.setValue(value)
        } catch let error {
            print(error)
        }
        
        incrementBadgeForReciever(ID: ID, participantsIDs: membersIDs.0)
        
        if !active {
            dispatchGroup.enter()
            connectMembersToGroupHolding(memberIDs: membersIDs.0, ID: ID)
        }
    }
    
    func updateHoldingParticipants() {
        guard let _ = active, let holding = holding, let ID = ID else {
            return
        }
        let membersIDs = fetchMembersIDs()
        if let participantsIDs = holding.participantsIDs, Set(participantsIDs) != Set(membersIDs.0) {
            let groupHoldingReference = Database.database().reference().child(financialHoldingsEntity).child(ID)
            updateParticipants(membersIDs: membersIDs)
            groupHoldingReference.updateChildValues(["participantsIDs": membersIDs.0 as AnyObject])
            let date = isodateFormatter.string(from: Date())
            groupHoldingReference.updateChildValues(["updated_at": date as AnyObject])
        } else if holding.participantsIDs == nil {
            let groupHoldingReference = Database.database().reference().child(financialHoldingsEntity).child(ID)
            groupHoldingReference.updateChildValues(["participantsIDs": membersIDs.0 as AnyObject])
            let date = isodateFormatter.string(from: Date())
            groupHoldingReference.updateChildValues(["updated_at": date as AnyObject])
            for memberID in membersIDs.0.filter({$0 != holding.admin}) {
                let userReference = Database.database().reference().child(userFinancialHoldingsEntity).child(memberID).child(ID)
                let values:[String : Any] = ["description": holding.description]
                userReference.setValue(values)
            }
        }
    }
    
    func fetchMembersIDs() -> ([String], [String:AnyObject]) {
        var membersIDs = [String]()
        var membersIDsDictionary = [String:AnyObject]()
        
        guard let holding = holding, let selectedFalconUsers = selectedFalconUsers else {
            return (membersIDs, membersIDsDictionary)
        }
        
        guard let currentUserID = Auth.auth().currentUser?.uid else { return (membersIDs, membersIDsDictionary) }
        
        // Only append current user when admin/creator of the holding
        if holding.admin == currentUserID {
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
    
    func connectMembersToGroupHolding(memberIDs: [String], ID: String) {
        let connectingMembersGroup = DispatchGroup()
        for _ in memberIDs {
            connectingMembersGroup.enter()
        }
        connectingMembersGroup.notify(queue: DispatchQueue.main, execute: {
            self.dispatchGroup.leave()
        })
        for memberID in memberIDs {
            let userReference = Database.database().reference().child(userFinancialHoldingsEntity).child(memberID).child(ID)
            let values:[String : Any] = ["description": holding.description]
            userReference.updateChildValues(values, withCompletionBlock: { (error, reference) in
                connectingMembersGroup.leave()
            })
        }
    }

    func createGroupHoldingNode(reference: DatabaseReference, childValues: [String: Any]) {
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
        guard let holding = holding, let ID = ID else {
            return
        }
        let participantsSet = Set(holding.participantsIDs!)
        let membersSet = Set(membersIDs.0)
        let difference = participantsSet.symmetricDifference(membersSet)
        for member in difference {
            if participantsSet.contains(member) {
                Database.database().reference().child(userFinancialHoldingsEntity).child(member).child(ID).removeValue()
            }
            
            dispatchGroup.enter()
            
            connectMembersToGroupHolding(memberIDs: membersIDs.0, ID: ID)
        }
    }
    
    func incrementBadgeForReciever(ID: String?, participantsIDs: [String]) {
        guard let currentUserID = Auth.auth().currentUser?.uid, let ID = ID else { return }
        for participantID in participantsIDs where participantID != currentUserID {
            runHoldingBadgeUpdate(firstChild: participantID, secondChild: ID)
            runUserBadgeUpdate(firstChild: participantID)
        }
    }

    func runHoldingBadgeUpdate(firstChild: String, secondChild: String) {
        var ref = Database.database().reference().child(userFinancialHoldingsEntity).child(firstChild).child(secondChild)
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
