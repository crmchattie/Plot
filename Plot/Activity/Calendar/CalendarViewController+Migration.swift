//
//  ActivityViewController+Migration.swift
//  Plot
//
//  Created by Hafiz Usama on 2019-12-12.
//  Copyright © 2019 Immature Creations. All rights reserved.
//

import Foundation
import Firebase
import CodableFirebase

let kAppVersionKey = "AppVersionKey"
var appLoaded = false

extension CalendarViewController {
    
    func createParticiapantsInvitations(forActivities activities: [Activity]) {
        guard let currentUserID = Auth.auth().currentUser?.uid else {
            return
        }
                
        if !appLoaded {
            appLoaded = true
            let dispatchGroup = DispatchGroup()
            var remainingActivities = activities
            if let activity = remainingActivities.first {
                remainingActivities.remove(at: 0)
                if activity.admin == nil {
                    // make user current admin of activity
                    activity.admin = currentUserID
                    let activityReference = Database.database().reference().child(activitiesEntity).child(activity.activityID!).child(messageMetaDataFirebaseFolder)
                    let values:[String : Any] = ["admin": currentUserID]
                    dispatchGroup.enter()
                    activityReference.updateChildValues(values, withCompletionBlock: { (error, reference) in
                        dispatchGroup.leave()
                    })
                }
                
                dispatchGroup.enter()
                ParticipantsFetcher.getParticipants(forActivity: activity) { allParticipants in
                    var participants = allParticipants.filter({$0.id != currentUserID})
                    participants = participants.filter({$0.id != activity.admin})
                    if participants.count > 0 {
                        InvitationsFetcher.updateInvitations(forActivity: activity, selectedParticipants: participants, defaultStatus: .accepted) {
                            dispatchGroup.leave()
                        }
                    } else {
                        dispatchGroup.leave()
                    }
                }
            }
            
            dispatchGroup.notify(queue: .main) {
                if remainingActivities.count == 0 {
                    self.participants = [:]
                } else {
                    self.createParticiapantsInvitations(forActivities: remainingActivities)
                }
            }
        }
        
    }
    
    func updateCategory(for activities: [Activity]) {
        categoryUpdateDispatchGroup = DispatchGroup()
        
        for activity in activities {
            if let activityID = activity.activityID, (activity.category == nil || activity.category == "" || activity.category == "Uncategorized") {
                var category = ""
                if let type = activity.activityType, !type.isEmpty {
                    if let activityType = CustomType(rawValue: type) {
                        switch activityType {
                        case .workout:
                            category = "Workout"
                        case .work:
                            category = "Work"
                        case .meal:
                            category = "Meal"
                        default:
                            category = ""
                        }
                    }
                }
                
                if category.isEmpty {
                    category = ActivityCategory.categorize(activity).rawValue
                }
            
                activity.category = category
                let activityReference = Database.database().reference().child(activitiesEntity).child(activityID).child(messageMetaDataFirebaseFolder)
                categoryUpdateDispatchGroup?.enter()
                activityReference.updateChildValues(["category": category]) { [weak self] (error, ref) in
                    self?.categoryUpdateDispatchGroup?.leave()
                }
            }
        }
        
        categoryUpdateDispatchGroup?.notify(queue: .main) { [weak self] in
            self?.handleReloadTable()
        }
    }
    
    func checkForDataMigration(forActivities activities: [Activity]) {
        let defaults = UserDefaults.standard
        guard let currentAppVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String else {
            return
        }
        
        let previousVersion = defaults.string(forKey: kAppVersionKey)
        let minVersion = "1.0.1"
        let maxVersion = "1.0.14"
        let versionBeforeActivityCategory = "1.0.16"
        //current app version is greater than min version and lesser than max version
        let firstCondition = (previousVersion == nil && currentAppVersion.compare(minVersion, options: .numeric) == .orderedDescending && currentAppVersion.compare(maxVersion, options: .numeric) == .orderedAscending)
        
        let comparePrevVerActCat = previousVersion!.compare(versionBeforeActivityCategory, options: .numeric)
        let activityCategoryCondition = (previousVersion == nil && currentAppVersion.compare(versionBeforeActivityCategory, options: .numeric) == .orderedDescending) || (previousVersion != nil && currentAppVersion.compare(previousVersion!, options: .numeric) == .orderedDescending && (comparePrevVerActCat == .orderedAscending || comparePrevVerActCat == .orderedSame))
        
        //current app version is greater than previous version and lesser than max version
        let secondCondition = (previousVersion != nil && currentAppVersion.compare(previousVersion!, options: .numeric) == .orderedDescending && currentAppVersion.compare(maxVersion, options: .numeric) == .orderedAscending)
        if firstCondition || secondCondition {
            // first launch
        }
        else if activityCategoryCondition {
            updateCategory(for: activities)
        }
        
        // Always set this
        defaults.setValue(currentAppVersion, forKey: kAppVersionKey)
    }
}
