//
//  ActivitiesFetcher.swift
//  Pigeon-project
//
//  Created by Cory McHattie on 6/9/19.
//  Copyright © 2019 Immature Creations. All rights reserved.
//

import UIKit
import Firebase
import CodableFirebase

class ActivitiesFetcher: NSObject {
        
    fileprivate var userActivitiesDatabaseRef: DatabaseReference!
    fileprivate var currentUserActivitiesAddHandle = DatabaseHandle()
    fileprivate var currentUserActivitiesChangeHandle = DatabaseHandle()
    fileprivate var currentUserActivitiesRemoveHandle = DatabaseHandle()
    
    var activitiesAdded: (([Activity])->())?
    var activitiesRemoved: (([Activity])->())?
    var activitiesChanged: (([Activity])->())?
    
    fileprivate var isGroupAlreadyFinished = false
    
    func fetchActivities(completion: @escaping ([Activity])->()) {
        guard let currentUserID = Auth.auth().currentUser?.uid else {
            completion([])
            return
        }
                
        let ref = Database.database().reference()
        userActivitiesDatabaseRef = ref.child(userActivitiesEntity).child(currentUserID)
        userActivitiesDatabaseRef.observeSingleEvent(of: .value, with: { snapshot in
            guard snapshot.exists(), let activityIDs = snapshot.value as? [String: AnyObject] else {
                return completion([])
            }
            var activities: [Activity] = []
            let group = DispatchGroup()
            for (activityID, userActivityInfo) in activityIDs {
                if let dictionary = userActivityInfo as? [String: AnyObject] {
                    let userActivity = Activity(dictionary: dictionary[messageMetaDataFirebaseFolder] as? [String : AnyObject])
                    group.enter()
                    ref.child(activitiesEntity).child(activityID).child(messageMetaDataFirebaseFolder).observeSingleEvent(of: .value, with: { activitySnapshot in
                        if activitySnapshot.exists(), let activitySnapshotValue = activitySnapshot.value as? [String: AnyObject] {
                            let activity = Activity(dictionary: activitySnapshotValue)
                            activity.showExtras = userActivity.showExtras
                            activity.calendarID = userActivity.calendarID
                            activity.calendarName = userActivity.calendarName
                            activity.calendarColor = userActivity.calendarColor
                            activity.calendarSource = userActivity.calendarSource
                            activity.calendarExport = userActivity.calendarExport
                            activity.isComplete = userActivity.isComplete
                            activity.reminder = userActivity.reminder
                            activity.badge = userActivity.badge
                            activity.muted = userActivity.muted
                            activity.pinned = userActivity.pinned
                            activities.append(activity)
                        }
                        group.leave()
                    })
                } else {
                    group.enter()
                    ref.child(activitiesEntity).child(activityID).child(messageMetaDataFirebaseFolder).observeSingleEvent(of: .value, with: { activitySnapshot in
                        if activitySnapshot.exists(), let activitySnapshotValue = activitySnapshot.value as? [String: AnyObject] {
                            let activity = Activity(dictionary: activitySnapshotValue)
                            activities.append(activity)
                        }
                        group.leave()
                    })
                }
            }
            group.notify(queue: .main) {
                completion(activities)
            }
        })
    }
    
    func observeActivityForCurrentUser(activitiesAdded: @escaping ([Activity])->(), activitiesRemoved: @escaping ([Activity])->(), activitiesChanged: @escaping ([Activity])->()) {
        guard let _ = Auth.auth().currentUser?.uid else {
            return
        }
        self.activitiesAdded = activitiesAdded
        self.activitiesRemoved = activitiesRemoved
        self.activitiesChanged = activitiesChanged
        currentUserActivitiesAddHandle = userActivitiesDatabaseRef.observe(.childAdded, with: { snapshot in
            if let completion = self.activitiesAdded {
                let activityID = snapshot.key
                let ref = Database.database().reference()
                var handle = UInt.max
                handle = ref.child(activitiesEntity).child(activityID).child(messageMetaDataFirebaseFolder).observe(.childChanged) { _ in
                    ref.removeObserver(withHandle: handle)
                    self.getActivitiesFromSnapshot(snapshot: snapshot, completion: completion)
                }
            }
        })
        
        currentUserActivitiesRemoveHandle = userActivitiesDatabaseRef.observe(.childRemoved, with: { snapshot in
            if let completion = self.activitiesRemoved {
                self.getActivitiesFromSnapshot(snapshot: snapshot, completion: completion)
            }
        })
        
        currentUserActivitiesChangeHandle = userActivitiesDatabaseRef.observe(.childChanged, with: { snapshot in
            print(snapshot)
            if let completion = self.activitiesChanged {
                self.getActivitiesFromSnapshot(snapshot: snapshot, completion: completion)
            }
        })
    }
    
    func getActivitiesFromSnapshot(snapshot: DataSnapshot, completion: @escaping ([Activity])->()) {
        if snapshot.exists() {
            guard let currentUserID = Auth.auth().currentUser?.uid else {
                return
            }
            let activityID = snapshot.key
            let ref = Database.database().reference()
            var activities: [Activity] = []
            let group = DispatchGroup()
            group.enter()
            ref.child(userActivitiesEntity).child(currentUserID).child(activityID).observeSingleEvent(of: .value, with: { snapshot in
                if snapshot.exists(), let dictionary = snapshot.value as? [String: AnyObject] {
                    let userActivity = Activity(dictionary: dictionary[messageMetaDataFirebaseFolder] as? [String : AnyObject])
                    ref.child(activitiesEntity).child(activityID).child(messageMetaDataFirebaseFolder).observeSingleEvent(of: .value, with: { activitySnapshot in
                        if activitySnapshot.exists(), let activitySnapshotValue = activitySnapshot.value as? [String: AnyObject] {
                            let activity = Activity(dictionary: activitySnapshotValue)
                            activity.showExtras = userActivity.showExtras
                            activity.calendarID = userActivity.calendarID
                            activity.calendarName = userActivity.calendarName
                            activity.calendarColor = userActivity.calendarColor
                            activity.calendarExport = userActivity.calendarExport
                            activity.calendarSource = userActivity.calendarSource
                            activity.isComplete = userActivity.isComplete
                            activity.reminder = userActivity.reminder
                            activity.badge = userActivity.badge
                            activity.muted = userActivity.muted
                            activity.pinned = userActivity.pinned
                            activities.append(activity)
                        }
                        group.leave()
                    })
                } else {
                    ref.child(activitiesEntity).child(activityID).child(messageMetaDataFirebaseFolder).observeSingleEvent(of: .value, with: { activitySnapshot in
                        if activitySnapshot.exists(), let activitySnapshotValue = activitySnapshot.value as? [String: AnyObject] {
                            let activity = Activity(dictionary: activitySnapshotValue)
                            activities.append(activity)
                        }
                        group.leave()
                    })
                }
            })
            
            group.notify(queue: .main) {
                completion(activities)
            }
        } else {
            completion([])
        }
    }
}
