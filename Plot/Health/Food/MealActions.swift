//
//  MealActions.swift
//  Plot
//
//  Created by Cory McHattie on 11/11/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import UIKit
import Firebase
import CodableFirebase

class MealActions: NSObject {
    
    var meal: Meal!
    var ID: String?
    var active: Bool?
    var selectedFalconUsers: [User]?
    
    let dispatchGroup = DispatchGroup()
        
    init(meal: Meal, active: Bool?, selectedFalconUsers: [User]) {
        super.init()
        self.meal = meal
        self.ID = meal.id
        self.active = active
        self.selectedFalconUsers = selectedFalconUsers
    
    }
    
    func deleteMeal() {
        guard currentReachabilityStatus != .notReachable else {
            return
        }
        
        guard let _ = active, let _ = meal, let ID = ID, let _ = selectedFalconUsers else {
            return
        }
                          
        let membersIDs = fetchMembersIDs()
        
        for memberID in membersIDs.0 {
        Database.database().reference().child(userMealsEntity).child(memberID).child(ID).removeAllObservers()
        Database.database().reference().child(userMealsEntity).child(memberID).child(ID).removeValue()
        }
                
    }
    
    func createNewMeal() {
        guard currentReachabilityStatus != .notReachable else {
            return
        }
        
        guard let active = active, let ID = ID, let selectedFalconUsers = selectedFalconUsers else {
            return
        }
        
        if !active {
            if meal.createdDate == nil {
                meal.createdDate = Date()
            }
            if meal.admin == nil {
                meal.admin = Auth.auth().currentUser?.uid
            }
        }
        
        let membersIDs = fetchMembersIDs()
        meal.participantsIDs = membersIDs.0
        meal.lastModifiedDate = Date()
        
        let groupMealReference = Database.database().reference().child(mealsEntity).child(ID)

        do {
            let value = try FirebaseEncoder().encode(meal)
            groupMealReference.setValue(value)
        } catch let error {
            print(error)
        }
        
        incrementBadgeForReciever(ID: ID, participantsIDs: membersIDs.0)
        
        if !active {
            Analytics.logEvent("new_meal", parameters: [String: Any]())
            dispatchGroup.enter()
            connectMembersToGroupMeal(memberIDs: membersIDs.0, ID: ID)
            
            // Store nutritions in healthkit
            if let samples = HealthKitSampleBuilder.createHKNutritions(from: meal), samples.count > 0 {
                HealthKitService.storeSamples(samples: samples) { (_, _) in
                    
                }
            }
            
            // Create activity
            if let activity = ActivityBuilder.createActivity(from: meal) {
                let activityActions = ActivityActions(activity: activity, active: active, selectedFalconUsers: selectedFalconUsers)
                activityActions.createNewActivity()
            }
        } else {
            Analytics.logEvent("update_meal", parameters: [String: Any]())
        }
    }
    
    func updateMealParticipants() {
        guard let _ = active, let meal = meal, let ID = ID else {
            return
        }
        let membersIDs = fetchMembersIDs()
        if Set(meal.participantsIDs!) != Set(membersIDs.0) {
            let groupMealReference = Database.database().reference().child(mealsEntity).child(ID)
            updateParticipants(membersIDs: membersIDs)
            groupMealReference.updateChildValues(["participantsIDs": membersIDs.0 as AnyObject])
            let date = Date().timeIntervalSinceReferenceDate
            groupMealReference.updateChildValues(["lastModifiedDate": date as AnyObject])
        }
        
    }
    
    func fetchMembersIDs() -> ([String], [String:AnyObject]) {
        var membersIDs = [String]()
        var membersIDsDictionary = [String:AnyObject]()
        
        guard let meal = meal, let selectedFalconUsers = selectedFalconUsers else {
            return (membersIDs, membersIDsDictionary)
        }
        
        guard let currentUserID = Auth.auth().currentUser?.uid else { return (membersIDs, membersIDsDictionary) }
        
        // Only append current user when admin/creator of the meal
        if meal.admin == currentUserID {
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
    
    func connectMembersToGroupMeal(memberIDs: [String], ID: String) {
        let connectingMembersGroup = DispatchGroup()
        for _ in memberIDs {
            connectingMembersGroup.enter()
        }
        connectingMembersGroup.notify(queue: DispatchQueue.main, execute: {
            self.dispatchGroup.leave()
        })
        for memberID in memberIDs {
            let userReference = Database.database().reference().child(userMealsEntity).child(memberID).child(ID)
            let values:[String : Any] = ["isGroupMeal": true]
            userReference.updateChildValues(values, withCompletionBlock: { (error, reference) in
                connectingMembersGroup.leave()
            })
        }
    }

    func createGroupMealNode(reference: DatabaseReference, childValues: [String: Any]) {
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
        guard let meal = meal, let ID = ID else {
            return
        }
        let participantsSet = Set(meal.participantsIDs!)
        let membersSet = Set(membersIDs.0)
        let difference = participantsSet.symmetricDifference(membersSet)
        for member in difference {
            if participantsSet.contains(member) {
                Database.database().reference().child(userMealsEntity).child(member).child(ID).removeValue()
            }
            
            dispatchGroup.enter()
            
            connectMembersToGroupMeal(memberIDs: membersIDs.0, ID: ID)
        }
    }
    
    func incrementBadgeForReciever(ID: String?, participantsIDs: [String]) {
        guard let currentUserID = Auth.auth().currentUser?.uid, let ID = ID else { return }
        for participantID in participantsIDs where participantID != currentUserID {
            runMealBadgeUpdate(firstChild: participantID, secondChild: ID)
            runUserBadgeUpdate(firstChild: participantID)
        }
    }

    func runMealBadgeUpdate(firstChild: String, secondChild: String) {
        var ref = Database.database().reference().child(userMealsEntity).child(firstChild).child(secondChild)
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
