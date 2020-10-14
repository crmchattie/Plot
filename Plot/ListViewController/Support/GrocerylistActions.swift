//
//  GrocerylistActions.swift
//  Plot
//
//  Created by Cory McHattie on 5/23/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import UIKit
import Firebase
import CodableFirebase

class GrocerylistActions: NSObject {
    
    var grocerylist: Grocerylist!
    var ID: String?
    var active: Bool?
    var selectedFalconUsers: [User]?
    
    let dispatchGroup = DispatchGroup()
        
    init(grocerylist: Grocerylist, active: Bool?, selectedFalconUsers: [User]) {
        super.init()
        self.grocerylist = grocerylist
        self.ID = grocerylist.ID
        self.active = active
        self.selectedFalconUsers = selectedFalconUsers
    
    }
    
    public func deleteGrocerylist() {
        guard currentReachabilityStatus != .notReachable else {
            return
        }
        
        guard let _ = active, let _ = grocerylist, let ID = ID, let _ = selectedFalconUsers else {
            return
        }
                          
        let membersIDs = fetchMembersIDs()
        
        for memberID in membersIDs.0 {
        Database.database().reference().child(userGrocerylistsEntity).child(memberID).child(ID).removeAllObservers()
        Database.database().reference().child(userGrocerylistsEntity).child(memberID).child(ID).removeValue()
        }
                
    }
    
    public func createNewGrocerylist() {
        guard currentReachabilityStatus != .notReachable else {
            return
        }
        
        guard let active = active, let grocerylist = grocerylist, let ID = ID, let _ = selectedFalconUsers else {
            return
        }
        
        if !active {
            if grocerylist.createdDate == nil {
                grocerylist.createdDate = Date()
            }
            grocerylist.admin = Auth.auth().currentUser?.uid
        }
        
        let membersIDs = fetchMembersIDs()
        grocerylist.participantsIDs = membersIDs.0
        grocerylist.lastModifiedDate = Date()
        
        let groupGrocerylistReference = Database.database().reference().child(grocerylistsEntity).child(ID)

        do {
            let value = try FirebaseEncoder().encode(grocerylist)
            groupGrocerylistReference.setValue(value)
        } catch let error {
            print(error)
        }
        
        incrementBadgeForReciever(ID: ID, participantsIDs: membersIDs.0)
        
        if !active {
            Analytics.logEvent("new_grocerylist", parameters: [
                "connected_to_activity": grocerylist.activityID ?? "none" as NSObject
            ])
            dispatchGroup.enter()
            connectMembersToGroupGrocerylist(memberIDs: membersIDs.0, ID: ID)
        } else {
            Analytics.logEvent("update_grocerylist", parameters: [
                "connected_to_activity": grocerylist.activityID ?? "none" as NSObject
            ])
        }
    }
    
    public func updateGrocerylistParticipants() {
        guard let _ = active, let grocerylist = grocerylist, let ID = ID else {
            return
        }
        let membersIDs = fetchMembersIDs()
        if Set(grocerylist.participantsIDs!) != Set(membersIDs.0) {
            let groupGrocerylistReference = Database.database().reference().child(grocerylistsEntity).child(ID)
            updateParticipants(membersIDs: membersIDs)
            groupGrocerylistReference.updateChildValues(["participantsIDs": membersIDs.0 as AnyObject])
            let date = Date().timeIntervalSinceReferenceDate
            groupGrocerylistReference.updateChildValues(["lastModifiedDate": date as AnyObject])
        }
        
    }
    
    func fetchMembersIDs() -> ([String], [String:AnyObject]) {
        var membersIDs = [String]()
        var membersIDsDictionary = [String:AnyObject]()
        
        guard let grocerylist = grocerylist, let selectedFalconUsers = selectedFalconUsers else {
            return (membersIDs, membersIDsDictionary)
        }
        
        guard let currentUserID = Auth.auth().currentUser?.uid else { return (membersIDs, membersIDsDictionary) }
        
        // Only append current user when admin/creator of the grocerylist
        if grocerylist.admin == currentUserID {
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
    
    func connectMembersToGroupGrocerylist(memberIDs: [String], ID: String) {
        let connectingMembersGroup = DispatchGroup()
        for _ in memberIDs {
            connectingMembersGroup.enter()
        }
        connectingMembersGroup.notify(queue: DispatchQueue.main, execute: {
            self.dispatchGroup.leave()
        })
        for memberID in memberIDs {
            let userReference = Database.database().reference().child(userGrocerylistsEntity).child(memberID).child(ID)
            let values:[String : Any] = ["isGroupGrocerylist": true]
            userReference.updateChildValues(values, withCompletionBlock: { (error, reference) in
                connectingMembersGroup.leave()
            })
        }
    }

    func createGroupGrocerylistNode(reference: DatabaseReference, childValues: [String: Any]) {
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
        guard let grocerylist = grocerylist, let ID = ID else {
            return
        }
        let participantsSet = Set(grocerylist.participantsIDs!)
        let membersSet = Set(membersIDs.0)
        let difference = participantsSet.symmetricDifference(membersSet)
        for member in difference {
            if participantsSet.contains(member) {
                Database.database().reference().child(userGrocerylistsEntity).child(member).child(ID).removeValue()
            }
            if let chatID = grocerylist.conversationID { Database.database().reference().child("groupChats").child(chatID).child(messageMetaDataFirebaseFolder).child("chatParticipantsIDs").updateChildValues(membersIDs.1)
            }
            
            dispatchGroup.enter()
            
            if let chatID = grocerylist.conversationID {
                dispatchGroup.enter()
                connectMembersToGroupChat(memberIDs: membersIDs.0, chatID: chatID)
            }
            
            connectMembersToGroupGrocerylist(memberIDs: membersIDs.0, ID: ID)
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
            runGrocerylistBadgeUpdate(firstChild: participantID, secondChild: ID)
            runUserBadgeUpdate(firstChild: participantID)
        }
    }

    func runGrocerylistBadgeUpdate(firstChild: String, secondChild: String) {
        print("runGrocerylistBadgeUpdate")
        var ref = Database.database().reference().child(userGrocerylistsEntity).child(firstChild).child(secondChild)
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            print("snapshot \(snapshot)")
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
