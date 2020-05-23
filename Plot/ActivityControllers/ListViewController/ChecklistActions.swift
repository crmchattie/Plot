//
//  ListActions.swift
//  Plot
//
//  Created by Cory McHattie on 5/22/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import UIKit
import Firebase
import CodableFirebase

class ChecklistActions: NSObject {
    
    var checklist: Checklist!
    var ID: String?
    var active: Bool?
    var selectedFalconUsers: [User]?
    
    let dispatchGroup = DispatchGroup()
        
    init(checklist: Checklist, active: Bool?, selectedFalconUsers: [User]) {
        super.init()
        self.checklist = checklist
        self.ID = checklist.ID
        self.active = active
        self.selectedFalconUsers = selectedFalconUsers
    
    }
    
    public func deleteChecklist() {
        guard currentReachabilityStatus != .notReachable else {
            return
        }
        
        guard let _ = active, let _ = checklist, let ID = ID, let _ = selectedFalconUsers else {
            return
        }
                          
        let membersIDs = fetchMembersIDs()
        
        for memberID in membersIDs.0 {
        Database.database().reference().child(userChecklistsEntity).child(memberID).child(ID).child(messageMetaDataFirebaseFolder).removeAllObservers()
        Database.database().reference().child(userChecklistsEntity).child(memberID).child(ID).removeValue()
        }
                
    }
    
    public func createNewChecklist() {
        guard currentReachabilityStatus != .notReachable else {
            return
        }
        
        guard let active = active, let checklist = checklist, let ID = ID, let _ = selectedFalconUsers else {
            return
        }
        
        if !active {
            checklist.admin = Auth.auth().currentUser?.uid
        }
        
        let membersIDs = fetchMembersIDs()
        checklist.participantsIDs = membersIDs.0
            
        var firebaseDictionary = checklist.toAnyObject()
        
        incrementBadgeForReciever(ID: ID, participantsIDs: membersIDs.0)
        
        if active {
            updateChecklist(firebaseDictionary: firebaseDictionary, membersIDs: membersIDs)
        } else {
            firebaseDictionary["participantsIDs"] = membersIDs.1 as AnyObject
            newChecklist(firebaseDictionary: firebaseDictionary, membersIDs: membersIDs)
        }
    }
    
    public func updateChecklistParticipants() {
        guard let _ = active, let checklist = checklist, let ID = ID else {
            return
        }
        let membersIDs = fetchMembersIDs()
        if Set(checklist.participantsIDs!) != Set(membersIDs.0) {
            let groupChecklistReference = Database.database().reference().child(checklistsEntity).child(ID).child(messageMetaDataFirebaseFolder)
            updateParticipants(membersIDs: membersIDs)
            groupChecklistReference.updateChildValues(["participantsIDs": membersIDs.1 as AnyObject])
        }
        
    }
    
    func updateChecklist(firebaseDictionary: [String: AnyObject], membersIDs: ([String], [String:AnyObject])) {
        guard let _ = checklist, let ID = ID else {
            return
        }
        
        let groupChecklistReference = Database.database().reference().child(checklistsEntity).child(ID).child(messageMetaDataFirebaseFolder)
        groupChecklistReference.updateChildValues(firebaseDictionary)
        
        
    }
    
    func newChecklist(firebaseDictionary: [String: AnyObject], membersIDs: ([String], [String:AnyObject])) {
        guard let _ = checklist, let ID = ID else {
            return
        }
                                
        let groupChecklistReference = Database.database().reference().child(checklistsEntity).child(ID).child(messageMetaDataFirebaseFolder)
                
        self.dispatchGroup.enter()
        self.dispatchGroup.enter()
        createGroupChecklistNode(reference: groupChecklistReference, childValues: firebaseDictionary)
        connectMembersToGroupChecklist(memberIDs: membersIDs.0, ID: ID)

    }
    
    func fetchMembersIDs() -> ([String], [String:AnyObject]) {
        var membersIDs = [String]()
        var membersIDsDictionary = [String:AnyObject]()
        
        guard let checklist = checklist, let selectedFalconUsers = selectedFalconUsers else {
            return (membersIDs, membersIDsDictionary)
        }
        
        guard let currentUserID = Auth.auth().currentUser?.uid else { return (membersIDs, membersIDsDictionary) }
        
        // Only append current user when admin/creator of the checklist
        if checklist.admin == currentUserID {
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
    
    func connectMembersToGroupChecklist(memberIDs: [String], ID: String) {
        let connectingMembersGroup = DispatchGroup()
        for _ in memberIDs {
            connectingMembersGroup.enter()
        }
        connectingMembersGroup.notify(queue: DispatchQueue.main, execute: {
            self.dispatchGroup.leave()
        })
        for memberID in memberIDs {
            let userReference = Database.database().reference().child(userChecklistsEntity).child(memberID).child(ID).child(messageMetaDataFirebaseFolder)
            let values:[String : Any] = ["isGroupChecklist": true]
            userReference.updateChildValues(values, withCompletionBlock: { (error, reference) in
                connectingMembersGroup.leave()
            })
        }
    }

    func createGroupChecklistNode(reference: DatabaseReference, childValues: [String: Any]) {
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
        guard let checklist = checklist, let ID = ID else {
            return
        }
        let participantsSet = Set(checklist.participantsIDs!)
        let membersSet = Set(membersIDs.0)
        let difference = participantsSet.symmetricDifference(membersSet)
        for member in difference {
            if participantsSet.contains(member) {
                Database.database().reference().child(userChecklistsEntity).child(member).child(ID).removeValue()
            }
            if let chatID = checklist.conversationID { Database.database().reference().child("groupChats").child(chatID).child(messageMetaDataFirebaseFolder).child("chatParticipantsIDs").updateChildValues(membersIDs.1)
            }
            
            dispatchGroup.enter()
            
            if let chatID = checklist.conversationID {
                dispatchGroup.enter()
                connectMembersToGroupChat(memberIDs: membersIDs.0, chatID: chatID)
            }
            
            connectMembersToGroupChecklist(memberIDs: membersIDs.0, ID: ID)
        }
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
            runChecklistBadgeUpdate(firstChild: participantID, secondChild: ID)
            runUserBadgeUpdate(firstChild: participantID)
        }
    }

    func runChecklistBadgeUpdate(firstChild: String, secondChild: String) {
        var ref = Database.database().reference().child(userChecklistsEntity).child(firstChild).child(secondChild)
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            
            guard snapshot.hasChild(messageMetaDataFirebaseFolder) else {
                ref = ref.child(messageMetaDataFirebaseFolder)
                ref.updateChildValues(["badge": 1])
                return
            }
            ref = ref.child(messageMetaDataFirebaseFolder).child("badge")
            ref.runTransactionBlock({ (mutableData) -> TransactionResult in
                var value = mutableData.value as? Int
                if value == nil { value = 0 }
                mutableData.value = value! + 1
                return TransactionResult.success(withValue: mutableData)
            })
        })
    }
}
