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
import HealthKit

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
    
    func deleteMindfulness(updateDirectAssociation: Bool) {
        guard currentReachabilityStatus != .notReachable else {
            return
        }
        
        guard let _ = active, let _ = mindfulness, let ID = ID, let selectedFalconUsers = selectedFalconUsers else {
            return
        }
                          
        let membersIDs = fetchMembersIDs()
        
        for memberID in membersIDs.0 {
            Database.database().reference().child(userMindfulnessEntity).child(memberID).child(ID).removeAllObservers()
            Database.database().reference().child(userMindfulnessEntity).child(memberID).child(ID).removeValue()
        }
        
        guard let currentUserID = Auth.auth().currentUser?.uid else {
            return
        }
        
        let reference = Database.database().reference().child(mindfulnessEntity).child(ID)
        reference.observeSingleEvent(of: .value, with: { (snapshot) in
            guard let dictionary = snapshot.value as? [String: AnyObject] else { return }
            if let membersIDs = dictionary["participantsIDs"] as? [String:AnyObject] {
                var varMemberIDs = membersIDs
                varMemberIDs[currentUserID] = nil
                reference.updateChildValues(["participantsIDs": varMemberIDs as AnyObject])
            }
        })
        
        if let _ = mindfulness.containerID {
            ContainerFunctions.deleteStuffInside(type: .mindfulness, ID: ID)
        }
        
        if updateDirectAssociation, mindfulness.directAssociation ?? false, let ID = mindfulness.directAssociationObjectID {
            ActivitiesFetcher.getDataFromSnapshot(ID: ID, parentID: nil) { activities in
                if let activity = activities.first {
                    let activityAction = ActivityActions(activity: activity, active: true, selectedFalconUsers: selectedFalconUsers)
                    activityAction.deleteActivity(updateExternal: true, updateDirectAssociation: false)
                }
            }
        }
        
        if let hkSampleID = mindfulness.hkSampleID, let uuid = UUID(uuidString: hkSampleID), let mindfulSessionType = HKObjectType.categoryType(forIdentifier: .mindfulSession) {
            Database.database().reference().child(userHealthEntity).child(currentUserID).child(healthkitMindfulnessKey).child(hkSampleID).child(identifierKey).removeValue()
            HealthKitService.deleteSample(sampleType: mindfulSessionType, uuid: uuid) { _,_ in }
        }
                
    }
    
    func createNewMindfulness(updateDirectAssociation: Bool) {
        guard currentReachabilityStatus != .notReachable else {
            return
        }
        
        guard let active = active, let ID = ID, let selectedFalconUsers = selectedFalconUsers else {
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
        
        if mindfulness.hkSampleID == nil {
            createHealthKit()
        } else if active, mindfulness.user_created ?? false {
            editHealthKit()
        }
        
        if mindfulness.containerID == nil {
            createActivity()
        } else if active, updateDirectAssociation {
            editActivity()
        }
        
        incrementBadgeForReciever(ID: ID, participantsIDs: membersIDs.0)
        
        if !active {
            Analytics.logEvent("new_mindfulness", parameters: [String: Any]())
            dispatchGroup.enter()
            if let containerID = mindfulness.containerID {
                ContainerFunctions.updateParticipants(containerID: containerID, selectedFalconUsers: selectedFalconUsers)
                dispatchGroup.leave()
            } else {
                connectMembersToGroupMindfulness(memberIDs: membersIDs.0, ID: ID)
            }
        } else {
            
            Analytics.logEvent("update_mindfulness", parameters: [String: Any]())
        }
    }
    
    func createHealthKit() {
        if let _ = HealthKitSampleBuilder.createHKMindfulness(from: mindfulness) {}
    }
    
    func editHealthKit() {
        if let _ = HealthKitSampleBuilder.editHKMindfulness(from: mindfulness) {}
    }
    
    func createActivity() {
        if let activity = EventBuilder.createActivity(from: self.mindfulness), let activityID = activity.activityID {
            Database.database().reference().child(mindfulnessEntity).child(mindfulness.id).child(directAssociationObjectIDEntity).setValue(activityID)
            let activityActions = ActivityActions(activity: activity, active: false, selectedFalconUsers: selectedFalconUsers ?? [])
            activityActions.createNewActivity(updateDirectAssociation: false)
            //will update activity.containerID and mindfulness.containerID
            let containerID = Database.database().reference().child(containerEntity).childByAutoId().key ?? ""
            let container = Container(id: containerID, activityIDs: [activityID], taskIDs: nil, workoutIDs: nil, mindfulnessIDs: [mindfulness.id], mealIDs: nil, transactionIDs: nil, participantsIDs: mindfulness.participantsIDs)
            ContainerFunctions.updateContainerAndStuffInside(container: container)
        }
    }
    
    func editActivity() {
        if let activity = EventBuilder.createActivity(from: self.mindfulness), let ID = mindfulness.directAssociationObjectID {
            activity.activityID = ID
            let activityActions = ActivityActions(activity: activity, active: true, selectedFalconUsers: selectedFalconUsers ?? [])
            activityActions.createNewActivity(updateDirectAssociation: false)
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
        
        guard let _ = mindfulness, let selectedFalconUsers = selectedFalconUsers else {
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
        }
        
        dispatchGroup.enter()
        
        connectMembersToGroupMindfulness(memberIDs: membersIDs.0, ID: ID)
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
