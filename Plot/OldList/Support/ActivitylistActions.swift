//
//  ActivitylistActions.swift
//  Plot
//
//  Created by Cory McHattie on 7/15/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import UIKit
import Firebase
import CodableFirebase

class ActivitylistActions: NSObject {
    
    var activitylist: Activitylist!
    var ID: String?
    var active: Bool?
    var selectedFalconUsers: [User]?
    
    let dispatchGroup = DispatchGroup()
        
    init(activitylist: Activitylist, active: Bool?, selectedFalconUsers: [User]) {
        super.init()
        self.activitylist = activitylist
        self.ID = activitylist.ID
        self.active = active
        self.selectedFalconUsers = selectedFalconUsers
    
    }
    
    func deleteActivitylist() {
        guard currentReachabilityStatus != .notReachable else {
            return
        }
        
        guard let _ = active, let _ = activitylist, let ID = ID, let _ = selectedFalconUsers else {
            return
        }
                          
        let membersIDs = fetchMembersIDs()
        
        for memberID in membersIDs.0 {
        Database.database().reference().child(userActivitylistsEntity).child(memberID).child(ID).removeAllObservers()
        Database.database().reference().child(userActivitylistsEntity).child(memberID).child(ID).removeValue()
        }
                
    }
    
    func createNewActivitylist() {
        guard currentReachabilityStatus != .notReachable else {
            return
        }
        
        guard let active = active, let activitylist = activitylist, let ID = ID, let _ = selectedFalconUsers else {
            return
        }
        
        if !active {
            if activitylist.createdDate == nil {
                activitylist.createdDate = Date()
            }
            if activitylist.admin == nil {
                activitylist.admin = Auth.auth().currentUser?.uid
            }
        }
        
        let membersIDs = fetchMembersIDs()
        activitylist.participantsIDs = membersIDs.0
        activitylist.lastModifiedDate = Date()
        
        let groupActivitylistReference = Database.database().reference().child(activitylistsEntity).child(ID)

        do {
            let value = try FirebaseEncoder().encode(activitylist)
            groupActivitylistReference.setValue(value)
        } catch let error {
            print(error)
        }
        
        incrementBadgeForReciever(ID: ID, participantsIDs: membersIDs.0)
        
        if !active {
            Analytics.logEvent("new_activitylist", parameters: [
                "connected_to_activity": activitylist.activityID ?? "none" as NSObject
            ])
            dispatchGroup.enter()
            connectMembersToGroupActivitylist(memberIDs: membersIDs.0, ID: ID)
        } else {
            Analytics.logEvent("update_activitylist", parameters: [
                "connected_to_activity": activitylist.activityID ?? "none" as NSObject
            ])
        }
    }
    
    func updateActivitylistParticipants() {
        guard let _ = active, let activitylist = activitylist, let ID = ID else {
            return
        }
        let membersIDs = fetchMembersIDs()
        if Set(activitylist.participantsIDs!) != Set(membersIDs.0) {
            print("does not equal")
            print("Set(activitylist.participantsIDs!) \(Set(activitylist.participantsIDs!))")
            print("Set(activitylist.participantsIDs!) \(Set(membersIDs.0))")
            let groupActivitylistReference = Database.database().reference().child(activitylistsEntity).child(ID)
            updateParticipants(membersIDs: membersIDs)
            groupActivitylistReference.updateChildValues(["participantsIDs": membersIDs.0 as AnyObject])
            let date = Date().timeIntervalSinceReferenceDate
            groupActivitylistReference.updateChildValues(["lastModifiedDate": date as AnyObject])
        }
        
    }
    
    func fetchMembersIDs() -> ([String], [String:AnyObject]) {
        var membersIDs = [String]()
        var membersIDsDictionary = [String:AnyObject]()
        
        guard let _ = activitylist, let selectedFalconUsers = selectedFalconUsers else {
            return (membersIDs.sorted(), membersIDsDictionary)
        }
        
        guard let currentUserID = Auth.auth().currentUser?.uid else { return (membersIDs.sorted(), membersIDsDictionary) }
        
        membersIDsDictionary.updateValue(currentUserID as AnyObject, forKey: currentUserID)
        membersIDs.append(currentUserID)
        
        for selectedUser in selectedFalconUsers {
            guard let id = selectedUser.id else { continue }
            membersIDsDictionary.updateValue(id as AnyObject, forKey: id)
            membersIDs.append(id)
        }
        
        return (membersIDs.sorted(), membersIDsDictionary)
    }
    
    func connectMembersToGroupActivitylist(memberIDs: [String], ID: String) {
        let connectingMembersGroup = DispatchGroup()
        for _ in memberIDs {
            connectingMembersGroup.enter()
        }
        connectingMembersGroup.notify(queue: DispatchQueue.main, execute: {
            self.dispatchGroup.leave()
        })
        for memberID in memberIDs {
            let userReference = Database.database().reference().child(userActivitylistsEntity).child(memberID).child(ID)
            let values:[String : Any] = ["isGroupActivitylist": true]
            userReference.updateChildValues(values, withCompletionBlock: { (error, reference) in
                connectingMembersGroup.leave()
            })
        }
    }

    func createGroupActivitylistNode(reference: DatabaseReference, childValues: [String: Any]) {
        print("child values \(childValues)")
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
        guard let activitylist = activitylist, let ID = ID else {
            return
        }
        let participantsSet = Set(activitylist.participantsIDs!)
        let membersSet = Set(membersIDs.0)
        let difference = participantsSet.symmetricDifference(membersSet)
        for member in difference {
            if participantsSet.contains(member) {
                Database.database().reference().child(userActivitylistsEntity).child(member).child(ID).removeValue()
            }            
        }
        dispatchGroup.enter()
                    
        connectMembersToGroupActivitylist(memberIDs: membersIDs.0, ID: ID)

    }
    
    func connectMembersToGroupChat(memberIDs: [String], chatID: String) {
        let connectingMembersGroup = DispatchGroup()
        for _ in memberIDs {
            connectingMembersGroup.enter()
        }
        connectingMembersGroup.notify(queue: DispatchQueue.main, execute: {
            self.dispatchGroup.leave()
        })
        for memberID in memberIDs {
            let userReference = Database.database().reference().child("user-messages").child(memberID).child(chatID).child(messageMetaDataFirebaseFolder)
            let values:[String : Any] = ["isGroupChat": true]
            userReference.updateChildValues(values, withCompletionBlock: { (error, reference) in
                connectingMembersGroup.leave()
            })
        }
    }
    
    func incrementBadgeForReciever(ID: String?, participantsIDs: [String]) {
        guard let currentUserID = Auth.auth().currentUser?.uid, let ID = ID else { return }
        for participantID in participantsIDs where participantID != currentUserID {
            runActivitylistBadgeUpdate(firstChild: participantID, secondChild: ID)
            runUserBadgeUpdate(firstChild: participantID)
        }
    }

    func runActivitylistBadgeUpdate(firstChild: String, secondChild: String) {
        var ref = Database.database().reference().child(userActivitylistsEntity).child(firstChild).child(secondChild)
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
