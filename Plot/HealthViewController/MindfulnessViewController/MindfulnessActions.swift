//
//  MindfulnessActions.swift
//  Plot
//
//  Created by Cory McHattie on 12/12/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import UIKit
import Firebase
import CodableFirebase

class MindfulnessActions: NSObject {
    
    var mindfulness: Mindfulness!
    var ID: String?
    var active: Bool?
    var selectedFalconUsers: [User]?
    
    let dispatchGroup = DispatchGroup()
        
    init(mindfulness: Mindfulness, active: Bool?, selectedFalconUsers: [User]) {
        super.init()
        self.mindfulness = mindfulness
        self.ID = mindfulness.id
        self.active = active
        self.selectedFalconUsers = selectedFalconUsers
    
    }
    
    func deleteMindfulness() {
        guard currentReachabilityStatus != .notReachable else {
            return
        }
        
        guard let _ = active, let _ = mindfulness, let ID = ID, let _ = selectedFalconUsers else {
            return
        }
                          
        let membersIDs = fetchMembersIDs()
        
        for memberID in membersIDs.0 {
        Database.database().reference().child(userMindfulnessEntity).child(memberID).child(ID).removeAllObservers()
        Database.database().reference().child(userMindfulnessEntity).child(memberID).child(ID).removeValue()
        }
                
    }
    
    func createNewMindfulness() {
        guard currentReachabilityStatus != .notReachable else {
            return
        }
        
        guard let active = active, let ID = ID, let _ = selectedFalconUsers else {
            return
        }
        
        if !active {
            if mindfulness.createdDate == nil {
                mindfulness.createdDate = Date()
            }
            if mindfulness.admin == nil {
                mindfulness.admin = Auth.auth().currentUser?.uid
            }
        }
        
        let membersIDs = fetchMembersIDs()
        mindfulness.participantsIDs = membersIDs.0
        mindfulness.lastModifiedDate = Date()
        
        let groupMindfulnessReference = Database.database().reference().child(mindfulnessEntity).child(ID)

        do {
            let value = try FirebaseEncoder().encode(mindfulness)
            groupMindfulnessReference.setValue(value)
        } catch let error {
            print(error)
        }
        
        incrementBadgeForReciever(ID: ID, participantsIDs: membersIDs.0)
        
        if !active {
            Analytics.logEvent("new_mindfulness", parameters: [String: Any]())
            dispatchGroup.enter()
            connectMembersToGroupMindfulness(memberIDs: membersIDs.0, ID: ID)
        } else {
            Analytics.logEvent("update_mindfulness", parameters: [String: Any]())
        }
    }
    
    func updateMindfulnessParticipants() {
        guard let _ = active, let mindfulness = mindfulness, let ID = ID else {
            return
        }
        let membersIDs = fetchMembersIDs()
        if Set(mindfulness.participantsIDs!) != Set(membersIDs.0) {
            let groupMindfulnessReference = Database.database().reference().child(mindfulnessEntity).child(ID)
            updateParticipants(membersIDs: membersIDs)
            groupMindfulnessReference.updateChildValues(["participantsIDs": membersIDs.0 as AnyObject])
            let date = Date().timeIntervalSinceReferenceDate
            groupMindfulnessReference.updateChildValues(["lastModifiedDate": date as AnyObject])
        }
        
    }
    
    func fetchMembersIDs() -> ([String], [String:AnyObject]) {
        var membersIDs = [String]()
        var membersIDsDictionary = [String:AnyObject]()
        
        guard let mindfulness = mindfulness, let selectedFalconUsers = selectedFalconUsers else {
            return (membersIDs, membersIDsDictionary)
        }
        
        guard let currentUserID = Auth.auth().currentUser?.uid else { return (membersIDs, membersIDsDictionary) }
        
        // Only append current user when admin/creator of the mindfulness
        if mindfulness.admin == currentUserID {
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
    
    func connectMembersToGroupMindfulness(memberIDs: [String], ID: String) {
        let connectingMembersGroup = DispatchGroup()
        for _ in memberIDs {
            connectingMembersGroup.enter()
        }
        connectingMembersGroup.notify(queue: DispatchQueue.main, execute: {
            self.dispatchGroup.leave()
        })
        for memberID in memberIDs {
            let userReference = Database.database().reference().child(userMindfulnessEntity).child(memberID).child(ID)
            let values:[String : Any] = ["isGroupMindfulness": true]
            userReference.updateChildValues(values, withCompletionBlock: { (error, reference) in
                connectingMembersGroup.leave()
            })
        }
    }

    func createGroupMindfulnessNode(reference: DatabaseReference, childValues: [String: Any]) {
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
        guard let mindfulness = mindfulness, let ID = ID else {
            return
        }
        let participantsSet = Set(mindfulness.participantsIDs!)
        let membersSet = Set(membersIDs.0)
        let difference = participantsSet.symmetricDifference(membersSet)
        for member in difference {
            if participantsSet.contains(member) {
                Database.database().reference().child(userMindfulnessEntity).child(member).child(ID).removeValue()
            }
            
            dispatchGroup.enter()
            
            connectMembersToGroupMindfulness(memberIDs: membersIDs.0, ID: ID)
        }
    }
    
    func incrementBadgeForReciever(ID: String?, participantsIDs: [String]) {
        guard let currentUserID = Auth.auth().currentUser?.uid, let ID = ID else { return }
        for participantID in participantsIDs where participantID != currentUserID {
            runMindfulnessBadgeUpdate(firstChild: participantID, secondChild: ID)
            runUserBadgeUpdate(firstChild: participantID)
        }
    }

    func runMindfulnessBadgeUpdate(firstChild: String, secondChild: String) {
        var ref = Database.database().reference().child(userMindfulnessEntity).child(firstChild).child(secondChild)
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
