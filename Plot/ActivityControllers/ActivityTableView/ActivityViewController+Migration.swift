//
//  ActivityViewController+Migration.swift
//  Plot
//
//  Created by Hafiz Usama on 2019-12-12.
//  Copyright © 2019 Immature Creations. All rights reserved.
//

import Foundation
import Firebase

let kAppVersionKey = "AppVersionKey"
var appLoaded = false
extension ActivityViewController {
    
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
                    let activityReference = Database.database().reference().child("activities").child(activity.activityID!).child(messageMetaDataFirebaseFolder)
                    let values:[String : Any] = ["admin": currentUserID]
                    dispatchGroup.enter()
                    activityReference.updateChildValues(values, withCompletionBlock: { (error, reference) in
                        dispatchGroup.leave()
                    })
                }
                
                dispatchGroup.enter()
                getParticipants(forActivity: activity) { allParticipants in
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
                    self.invitations = [:]
                    self.invitedActivities = []
                    self.activitiesParticipants = [:]
                    self.activitiesFetcher.fetchActivities()
                } else {
                    self.createParticiapantsInvitations(forActivities: remainingActivities)
                }
            }
        }
        
    }
    
    func checkForDataMigration(forActivities activities: [Activity]) {
        let defaults = UserDefaults.standard
        guard let currentAppVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String else {
            return
        }
        
        let previousVersion = defaults.string(forKey: kAppVersionKey)
        let minVersion = "1.0.1"
        let maxVersion = "1.0.5"
        let firstCondition = (previousVersion == nil && currentAppVersion.compare(minVersion, options: .numeric) == .orderedDescending && currentAppVersion.compare(maxVersion, options: .numeric) == .orderedAscending)
        let secondCondition = (previousVersion != nil && currentAppVersion.compare(previousVersion!, options: .numeric) == .orderedDescending && currentAppVersion.compare(maxVersion, options: .numeric) == .orderedAscending)
        if firstCondition || secondCondition {
            // first launch
            print("data migration")
            createParticiapantsInvitations(forActivities: activities)
            
            defaults.setValue(currentAppVersion, forKey: kAppVersionKey)
        }
        else if currentAppVersion == previousVersion {
            // samve version
        }
        else {
            // other version
            
            defaults.setValue(currentAppVersion, forKey: kAppVersionKey)
        }
    }
}
