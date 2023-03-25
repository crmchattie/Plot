//
//  MoodActions.swift
//  Plot
//
//  Created by Cory McHattie on 12/12/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import UIKit
import Firebase
import CodableFirebase

class MoodActions: NSObject {
    
    var mood: Mood!
    var ID: String?
    var active: Bool?
    var selectedFalconUsers: [User]?
    
    let dispatchGroup = DispatchGroup()
        
    init(mood: Mood, active: Bool?, selectedFalconUsers: [User]?) {
        super.init()
        self.mood = mood
        self.ID = mood.id
        self.active = active
        self.selectedFalconUsers = selectedFalconUsers
    
    }
    
    func deleteMood() {
        guard currentReachabilityStatus != .notReachable else {
            return
        }
        
        guard let _ = active, let _ = mood, let ID = ID, let _ = selectedFalconUsers else {
            return
        }
                          
        let membersIDs = fetchMembersIDs()
        
        for memberID in membersIDs.0 {
            Database.database().reference().child(userMoodEntity).child(memberID).child(ID).removeAllObservers()
            Database.database().reference().child(userMoodEntity).child(memberID).child(ID).removeValue()
        }
        
        guard let currentUserID = Auth.auth().currentUser?.uid else {
            return
        }
        
        let reference = Database.database().reference().child(moodEntity).child(ID)
        reference.observeSingleEvent(of: .value, with: { (snapshot) in
            guard let dictionary = snapshot.value as? [String: AnyObject] else { return }
            if let membersIDs = dictionary["participantsIDs"] as? [String:AnyObject] {
                var varMemberIDs = membersIDs
                varMemberIDs[currentUserID] = nil
                reference.updateChildValues(["participantsIDs": varMemberIDs as AnyObject])
            }
        })
                
    }
    
    func createNewMood() {
        guard currentReachabilityStatus != .notReachable else {
            return
        }
        
        guard let active = active, let ID = ID, let _ = selectedFalconUsers else {
            return
        }
        
        if !active {
            if mood.createdDate == nil {
                mood.createdDate = Date()
            }
            if mood.admin == nil {
                mood.admin = Auth.auth().currentUser?.uid
            }
        }
        
        let membersIDs = fetchMembersIDs()
        mood.participantsIDs = membersIDs.0
        mood.lastModifiedDate = Date()
                        
        let groupMoodReference = Database.database().reference().child(moodEntity).child(ID)

        do {
            let value = try FirebaseEncoder().encode(mood)
            groupMoodReference.setValue(value)
        } catch let error {
            print(error)
        }
        
        incrementBadgeForReciever(ID: ID, participantsIDs: membersIDs.0)
        
        if !active {
            Analytics.logEvent("new_mood", parameters: [String: Any]())
            dispatchGroup.enter()
            connectMembersToGroupMood(memberIDs: membersIDs.0, ID: ID)
        } else {
            Analytics.logEvent("update_mood", parameters: [String: Any]())
        }
    }
    
    func updateMoodParticipants() {
        guard let _ = active, let mood = mood, let ID = ID else {
            return
        }
        let membersIDs = fetchMembersIDs()
        if Set(mood.participantsIDs!) != Set(membersIDs.0) {
            let groupMoodReference = Database.database().reference().child(moodEntity).child(ID)
            updateParticipants(membersIDs: membersIDs)
            groupMoodReference.updateChildValues(["participantsIDs": membersIDs.0 as AnyObject])
            let date = Date().timeIntervalSinceReferenceDate
            groupMoodReference.updateChildValues(["lastModifiedDate": date as AnyObject])
        }
        
    }
    
    func fetchMembersIDs() -> ([String], [String:AnyObject]) {
        var membersIDs = [String]()
        var membersIDsDictionary = [String:AnyObject]()
        
        guard let _ = mood, let selectedFalconUsers = selectedFalconUsers, !selectedFalconUsers.isEmpty else {
            if let id = mood.admin {
                membersIDsDictionary.updateValue(id as AnyObject, forKey: id)
                membersIDs.append(id)
            }
            return (membersIDs.sorted(), membersIDsDictionary)
        }
                
        for selectedUser in selectedFalconUsers {
            guard let id = selectedUser.id else { continue }
            membersIDsDictionary.updateValue(id as AnyObject, forKey: id)
            membersIDs.append(id)
        }
        
        return (membersIDs.sorted(), membersIDsDictionary)
    }
    
    func connectMembersToGroupMood(memberIDs: [String], ID: String) {
        guard let mood = mood else {
            self.dispatchGroup.leave()
            return
        }
        
        let connectingMembersGroup = DispatchGroup()
        for _ in memberIDs {
            connectingMembersGroup.enter()
        }
        connectingMembersGroup.notify(queue: DispatchQueue.main, execute: {
            self.dispatchGroup.leave()
        })
        for memberID in memberIDs {
            let userReference = Database.database().reference().child(userMoodEntity).child(memberID).child(ID)
            var values = [String : Any]()
            do {
                let value = try FirebaseEncoder().encode(mood.moodDate)
                values = ["moodDate": value]
            } catch let error {
                print(error)
                values = ["isGroupMood": true]
            }
            userReference.updateChildValues(values, withCompletionBlock: { (error, reference) in
                connectingMembersGroup.leave()
            })
        }
    }

    func createGroupMoodNode(reference: DatabaseReference, childValues: [String: Any]) {
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
        guard let mood = mood, let ID = ID else {
            return
        }
        let participantsSet = Set(mood.participantsIDs!)
        let membersSet = Set(membersIDs.0)
        let difference = participantsSet.symmetricDifference(membersSet)
        for member in difference {
            if participantsSet.contains(member) {
                Database.database().reference().child(userMoodEntity).child(member).child(ID).removeValue()
            }
        }
        
        dispatchGroup.enter()
        
        connectMembersToGroupMood(memberIDs: membersIDs.0, ID: ID)
    }
    
    func incrementBadgeForReciever(ID: String?, participantsIDs: [String]) {
        guard let currentUserID = Auth.auth().currentUser?.uid, let ID = ID else { return }
        for participantID in participantsIDs where participantID != currentUserID {
            runMoodBadgeUpdate(firstChild: participantID, secondChild: ID)
            runUserBadgeUpdate(firstChild: participantID)
        }
    }

    func runMoodBadgeUpdate(firstChild: String, secondChild: String) {
        var ref = Database.database().reference().child(userMoodEntity).child(firstChild).child(secondChild)
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
