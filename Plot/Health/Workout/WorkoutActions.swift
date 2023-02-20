//
//  WorkoutActions.swift
//  Plot
//
//  Created by Cory McHattie on 11/11/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import UIKit
import Firebase
import CodableFirebase
import HealthKit

class WorkoutActions: NSObject {
    
    var workout: Workout!
    var ID: String?
    var active: Bool?
    var selectedFalconUsers: [User]?
    
    let dispatchGroup = DispatchGroup()
        
    init(workout: Workout, active: Bool?, selectedFalconUsers: [User]) {
        super.init()
        self.workout = workout
        self.ID = workout.id
        self.active = active
        self.selectedFalconUsers = selectedFalconUsers
    
    }
    
    public func deleteWorkout(updateDirectAssociation: Bool) {
        guard currentReachabilityStatus != .notReachable else {
            return
        }
        
        guard let _ = active, let _ = workout, let ID = ID, let selectedFalconUsers = selectedFalconUsers else {
            return
        }
                          
        let membersIDs = fetchMembersIDs()
        
        for memberID in membersIDs.0 {
            Database.database().reference().child(userWorkoutsEntity).child(memberID).child(ID).removeAllObservers()
            Database.database().reference().child(userWorkoutsEntity).child(memberID).child(ID).removeValue()
        }
        
        guard let currentUserID = Auth.auth().currentUser?.uid else {
            return
        }
        
        let reference = Database.database().reference().child(workoutsEntity).child(ID)
        reference.observeSingleEvent(of: .value, with: { (snapshot) in
            guard let dictionary = snapshot.value as? [String: AnyObject] else { return }
            if let membersIDs = dictionary["participantsIDs"] as? [String:AnyObject] {
                var varMemberIDs = membersIDs
                varMemberIDs[currentUserID] = nil
                reference.updateChildValues(["participantsIDs": varMemberIDs as AnyObject])
            }
        })
        
        if let _ = workout.containerID {
            ContainerFunctions.deleteStuffInside(type: .workout, ID: ID)
        }
        
        if updateDirectAssociation, workout.directAssociation ?? false, let ID = workout.directAssociationObjectID {
            ActivitiesFetcher.getDataFromSnapshot(ID: ID, parentID: nil) { activities in
                if let activity = activities.first {
                    let activityAction = ActivityActions(activity: activity, active: true, selectedFalconUsers: selectedFalconUsers)
                    activityAction.deleteActivity(updateExternal: true, updateDirectAssociation: false)
                }
            }
        }
        
        if let hkSampleID = workout.hkSampleID, let uuid = UUID(uuidString: hkSampleID) {
            Database.database().reference().child(userHealthEntity).child(currentUserID).child(healthkitWorkoutsKey).child(hkSampleID).child(identifierKey).removeValue()
            HealthKitService.deleteSample(sampleType: .workoutType(), uuid: uuid) { _,_ in }
        }
    }
    
    public func createNewWorkout(updateDirectAssociation: Bool) {
        guard currentReachabilityStatus != .notReachable else {
            return
        }
        
        guard let active = active, let ID = ID, let _ = selectedFalconUsers else {
            return
        }
        
        
        if !active {
            if workout.createdDate == nil {
                workout.createdDate = Date()
            }
            if workout.admin == nil {
                workout.admin = Auth.auth().currentUser?.uid
            }
        }
        
        let membersIDs = fetchMembersIDs()
        workout.participantsIDs = membersIDs.0
        workout.lastModifiedDate = Date()
                        
        let groupWorkoutReference = Database.database().reference().child(workoutsEntity).child(ID)
        
        do {
            let value = try FirebaseEncoder().encode(workout)
            groupWorkoutReference.setValue(value)
        } catch let error {
            print(error)
        }
        
        if workout.hkSampleID == nil {
            createHealthKit()
        } else if active, workout.user_created ?? false {
            editHealthKit()
        }
        
        if workout.containerID == nil {
            createActivity()
        } else if active, updateDirectAssociation {
            editActivity()
        }
        
        incrementBadgeForReciever(ID: ID, participantsIDs: membersIDs.0)
        
        if !active {
            Analytics.logEvent("new_workout", parameters: [String: Any]())
            dispatchGroup.enter()
//            if let containerID = workout.containerID {
//                ContainerFunctions.updateParticipants(containerID: containerID, selectedFalconUsers: selectedFalconUsers)
//                dispatchGroup.leave()
//            } else {
//                connectMembersToGroupWorkout(memberIDs: membersIDs.0, ID: ID)
//            }
            connectMembersToGroupWorkout(memberIDs: membersIDs.0, ID: ID)
        } else {
            Analytics.logEvent("update_workout", parameters: [String: Any]())
        }
    }
    
    func createHealthKit() {
        if let _ = HealthKitSampleBuilder.createHKWorkout(from: workout) {}
    }
    
    func editHealthKit() {
        print("editHealthKit")
        if let _ = HealthKitSampleBuilder.editHKWorkout(from: workout) {}
    }
    
    func createActivity() {
        if let activity = EventBuilder.createActivity(from: workout), let activityID = activity.activityID {
            Database.database().reference().child(workoutsEntity).child(workout.id).child(directAssociationObjectIDEntity).setValue(activityID)
            let activityActions = ActivityActions(activity: activity, active: false, selectedFalconUsers: selectedFalconUsers ?? [])
            activityActions.createNewActivity(updateDirectAssociation: false)
            //will update activity.containerID and workout.containerID
            let containerID = Database.database().reference().child(containerEntity).childByAutoId().key ?? ""
            let container = Container(id: containerID, activityIDs: [activityID], taskIDs: nil, workoutIDs: [workout.id], mindfulnessIDs: nil, mealIDs: nil, transactionIDs: nil, participantsIDs: workout.participantsIDs)
            ContainerFunctions.updateContainerAndStuffInside(container: container)
        }
    }
    
    func editActivity() {
        if let activity = EventBuilder.createActivity(from: self.workout), let ID = workout.directAssociationObjectID {
            activity.activityID = ID
            let activityActions = ActivityActions(activity: activity, active: true, selectedFalconUsers: selectedFalconUsers ?? [])
            activityActions.createNewActivity(updateDirectAssociation: false)
        }
    }
    
    public func updateWorkoutParticipants() {
        guard let _ = active, let workout = workout, let ID = ID else {
            return
        }
        let membersIDs = fetchMembersIDs()
        if Set(workout.participantsIDs!) != Set(membersIDs.0) {
            let groupWorkoutReference = Database.database().reference().child(workoutsEntity).child(ID)
            updateParticipants(membersIDs: membersIDs)
            groupWorkoutReference.updateChildValues(["participantsIDs": membersIDs.0 as AnyObject])
            let date = Date().timeIntervalSinceReferenceDate
            groupWorkoutReference.updateChildValues(["lastModifiedDate": date as AnyObject])
        }
        
    }
    
    func fetchMembersIDs() -> ([String], [String:AnyObject]) {
        var membersIDs = [String]()
        var membersIDsDictionary = [String:AnyObject]()
        
        guard let _ = workout, let selectedFalconUsers = selectedFalconUsers else {
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
    
    func connectMembersToGroupWorkout(memberIDs: [String], ID: String) {
        let connectingMembersGroup = DispatchGroup()
        for _ in memberIDs {
            connectingMembersGroup.enter()
        }
        connectingMembersGroup.notify(queue: DispatchQueue.main, execute: {
            self.dispatchGroup.leave()
        })
        for memberID in memberIDs {
            let userReference = Database.database().reference().child(userWorkoutsEntity).child(memberID).child(ID)
            let values:[String : Any] = ["isGroupWorkout": true]
            userReference.updateChildValues(values, withCompletionBlock: { (error, reference) in
                connectingMembersGroup.leave()
            })
        }
    }

    func createGroupWorkoutNode(reference: DatabaseReference, childValues: [String: Any]) {
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
        guard let workout = workout, let ID = ID else {
            return
        }
        let participantsSet = Set(workout.participantsIDs!)
        let membersSet = Set(membersIDs.0)
        let difference = participantsSet.symmetricDifference(membersSet)
        for member in difference {
            if participantsSet.contains(member) {
                Database.database().reference().child(userWorkoutsEntity).child(member).child(ID).removeValue()
            }
        }
        dispatchGroup.enter()
        
        connectMembersToGroupWorkout(memberIDs: membersIDs.0, ID: ID)

    }
    
    func incrementBadgeForReciever(ID: String?, participantsIDs: [String]) {
        guard let currentUserID = Auth.auth().currentUser?.uid, let ID = ID else { return }
        for participantID in participantsIDs where participantID != currentUserID {
            runWorkoutBadgeUpdate(firstChild: participantID, secondChild: ID)
            runUserBadgeUpdate(firstChild: participantID)
        }
    }

    func runWorkoutBadgeUpdate(firstChild: String, secondChild: String) {
        var ref = Database.database().reference().child(userWorkoutsEntity).child(firstChild).child(secondChild)
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
