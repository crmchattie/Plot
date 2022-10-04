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
    
    var activitiesInitialAdd: (([Activity])->())?
    var activitiesAdded: (([Activity])->())?
    var activitiesRemoved: (([Activity])->())?
    var activitiesChanged: (([Activity])->())?
    var userActivities: [String: Activity] = [:]
            
    func observeActivityForCurrentUser(activitiesInitialAdd: @escaping ([Activity])->(), activitiesAdded: @escaping ([Activity])->(), activitiesRemoved: @escaping ([Activity])->(), activitiesChanged: @escaping ([Activity])->()) {
        guard let currentUserID = Auth.auth().currentUser?.uid else {
            return
        }
        
        let ref = Database.database().reference()
        userActivitiesDatabaseRef = ref.child(userActivitiesEntity).child(currentUserID)
        
        self.activitiesInitialAdd = activitiesInitialAdd
        self.activitiesAdded = activitiesAdded
        self.activitiesRemoved = activitiesRemoved
        self.activitiesChanged = activitiesChanged
                                
        userActivitiesDatabaseRef.observeSingleEvent(of: .value, with: { snapshot in
            guard snapshot.exists() else {
                activitiesInitialAdd([])
                return
            }
            
            if let completion = self.activitiesInitialAdd {
                var activities: [Activity] = []
                let group = DispatchGroup()
                var counter = 0
                let activityIDs = snapshot.value as? [String: AnyObject] ?? [:]
                for (ID, userActivityInfo) in activityIDs {
                    var handle = UInt.max
                    if let dictionary = userActivityInfo as? [String: AnyObject] {
                        let userActivity = Activity(dictionary: dictionary[messageMetaDataFirebaseFolder] as? [String : AnyObject])
                        self.userActivities[ID] = userActivity
                        group.enter()
                        counter += 1
                        handle = ref.child(activitiesEntity).child(ID).child(messageMetaDataFirebaseFolder).observe(.value) { snapshot in
                            ref.removeObserver(withHandle: handle)
                            if snapshot.exists(), let snapshotValue = snapshot.value as? [String: AnyObject], let userActivity = self.userActivities[ID] {
                                let activity = Activity(dictionary: snapshotValue)
                                activity.showExtras = userActivity.showExtras
                                activity.calendarID = userActivity.calendarID
                                activity.calendarName = userActivity.calendarName
                                activity.calendarColor = userActivity.calendarColor
                                activity.calendarSource = userActivity.calendarSource
                                activity.calendarExport = userActivity.calendarExport
                                activity.externalActivityID = userActivity.externalActivityID
                                activity.userIsCompleted = userActivity.userIsCompleted
                                activity.userCompletedDate = userActivity.userCompletedDate
                                activity.reminder = userActivity.reminder
                                activity.badge = userActivity.badge
                                activity.badgeDate = userActivity.badgeDate
                                activity.muted = userActivity.muted
                                activity.pinned = userActivity.pinned
                                if counter > 0 {
                                    activities.append(activity)
                                    group.leave()
                                    counter -= 1
                                } else {
                                    activities = [activity]
                                    completion(activities)
                                }
                            } else {
                                if counter > 0 {
                                    group.leave()
                                    counter -= 1
                                }
                            }
                        }
                    }
                }
                group.notify(queue: .main) {
                    completion(activities)
                }
            }
        })
        
        currentUserActivitiesAddHandle = userActivitiesDatabaseRef.observe(.childAdded, with: { snapshot in
            if self.userActivities[snapshot.key] == nil {
                if let completion = self.activitiesAdded {
                    var handle = UInt.max
                    let ID = snapshot.key
                    self.getUserDataFromSnapshot(ID: ID) { activityList in
                        for userActivity in activityList {
                            self.userActivities[ID] = userActivity
                            handle = ref.child(activitiesEntity).child(ID).child(messageMetaDataFirebaseFolder).observe(.value) { snapshot in
                                ref.removeObserver(withHandle: handle)
                                if snapshot.exists(), let snapshotValue = snapshot.value as? [String: AnyObject], let userActivity = self.userActivities[ID] {
                                    let activity = Activity(dictionary: snapshotValue)
                                    activity.showExtras = userActivity.showExtras
                                    activity.calendarID = userActivity.calendarID
                                    activity.calendarName = userActivity.calendarName
                                    activity.calendarColor = userActivity.calendarColor
                                    activity.calendarSource = userActivity.calendarSource
                                    activity.calendarExport = userActivity.calendarExport
                                    activity.externalActivityID = userActivity.externalActivityID
                                    activity.userIsCompleted = userActivity.userIsCompleted
                                    activity.userCompletedDate = userActivity.userCompletedDate
                                    activity.reminder = userActivity.reminder
                                    activity.badge = userActivity.badge
                                    activity.badgeDate = userActivity.badgeDate
                                    activity.muted = userActivity.muted
                                    activity.pinned = userActivity.pinned
                                    completion([activity])
                                }
                            }
                        }
                    }
                }
            }
        })
        
        currentUserActivitiesRemoveHandle = userActivitiesDatabaseRef.observe(.childRemoved, with: { snapshot in
            if let completion = self.activitiesRemoved {
                self.userActivities[snapshot.key] = nil
                ActivitiesFetcher.getDataFromSnapshot(ID: snapshot.key, completion: completion)
            }
        })
        
        currentUserActivitiesChangeHandle = userActivitiesDatabaseRef.observe(.childChanged, with: { snapshot in
            if let completion = self.activitiesChanged {
                ActivitiesFetcher.getDataFromSnapshot(ID: snapshot.key) { activityList in
                    for activity in activityList {
                        self.userActivities[activity.activityID ?? ""] = activity
                    }
                    completion(activityList)
                }
            }
        })
    }
    
    class func getDataFromSnapshot(ID: String, completion: @escaping ([Activity])->()) {
        guard let currentUserID = Auth.auth().currentUser?.uid else {
            return
        }
        
        let ref = Database.database().reference()
        var activities: [Activity] = []
        let group = DispatchGroup()
        group.enter()
        ref.child(userActivitiesEntity).child(currentUserID).child(ID).observeSingleEvent(of: .value, with: { snapshot in
            if snapshot.exists(), let dictionary = snapshot.value as? [String: AnyObject] {
                let userActivity = Activity(dictionary: dictionary[messageMetaDataFirebaseFolder] as? [String : AnyObject])
                ref.child(activitiesEntity).child(ID).child(messageMetaDataFirebaseFolder).observeSingleEvent(of: .value, with: { activitySnapshot in
                    if activitySnapshot.exists(), let activitySnapshotValue = activitySnapshot.value as? [String: AnyObject] {
                        let activity = Activity(dictionary: activitySnapshotValue)
                        activity.showExtras = userActivity.showExtras
                        activity.calendarID = userActivity.calendarID
                        activity.calendarName = userActivity.calendarName
                        activity.calendarColor = userActivity.calendarColor
                        activity.calendarSource = userActivity.calendarSource
                        activity.calendarExport = userActivity.calendarExport
                        activity.externalActivityID = userActivity.externalActivityID
                        activity.userIsCompleted = userActivity.userIsCompleted
                        activity.userCompletedDate = userActivity.userCompletedDate
                        activity.reminder = userActivity.reminder
                        activity.badge = userActivity.badge
                        activity.badgeDate = userActivity.badgeDate
                        activity.muted = userActivity.muted
                        activity.pinned = userActivity.pinned
                        activities.append(activity)
                    }
                    group.leave()
                })
            } else {
                ref.child(activitiesEntity).child(ID).child(messageMetaDataFirebaseFolder).observeSingleEvent(of: .value, with: { activitySnapshot in
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
    }
    
    class func grabInstanceActivities(IDs: [String], completion: @escaping ([Date: Activity])->()) {
        let ref = Database.database().reference()
        var activities: [Date: Activity] = [:]
        let group = DispatchGroup()
        var counter = 0
        for ID in IDs {
            var handle = UInt.max
            group.enter()
            counter += 1
            handle = ref.child(activitiesEntity).child(ID).child(messageMetaDataFirebaseFolder).observe(.value, with: { activitySnapshot in
                ref.removeObserver(withHandle: handle)
                if activitySnapshot.exists(), let activitySnapshotValue = activitySnapshot.value as? [String: AnyObject] {
                    let activity = Activity(dictionary: activitySnapshotValue)
                    if counter > 0 {
                        if let instanceOriginalStartDate = activity.instanceOriginalStartDate {
                            activities[instanceOriginalStartDate] = activity
                        }
                        group.leave()
                        counter -= 1
                    } else {
                        if let instanceOriginalStartDate = activity.instanceOriginalStartDate {
                            activities = [:]
                            activities[instanceOriginalStartDate] = activity
                            completion(activities)
                        }
                    }
                } else {
                    if counter > 0 {
                        group.leave()
                        counter -= 1
                    }
                }
            })
        }
        
        group.notify(queue: .main) {
            completion(activities)
        }
    }
    
    func getUserDataFromSnapshot(ID: String, completion: @escaping ([Activity])->()) {
        guard let currentUserID = Auth.auth().currentUser?.uid else {
            return
        }
        let ref = Database.database().reference()
        var activities: [Activity] = []
        let group = DispatchGroup()
        group.enter()
        ref.child(userActivitiesEntity).child(currentUserID).child(ID).observeSingleEvent(of: .value, with: { snapshot in
            if snapshot.exists(), let dictionary = snapshot.value as? [String: AnyObject] {
                let userActivity = Activity(dictionary: dictionary[messageMetaDataFirebaseFolder] as? [String : AnyObject])
                activities.append(userActivity)
                group.leave()
            }
        })
        group.notify(queue: .main) {
            completion(activities)
        }
    }
    
    func grabActivitiesViaCalendar(calendars: [CalendarType], completion: @escaping ([Activity])->()) {
        guard let currentUserID = Auth.auth().currentUser?.uid else {
            return
        }
        
        var activities: [Activity] = []
        let group = DispatchGroup()
        let filteredCalendars = calendars.filter({ $0.admin != currentUserID })
        for calendar in filteredCalendars {
            if let eventIDs = calendar.eventIDs?.keys {
                for ID in eventIDs {
                    if self.userActivities[ID] == nil, let admin = calendar.admin {
                        group.enter()
                        self.getDataFromSnapshotViaCalendar(ID: ID, userID: admin, calendar: calendar) { activityList in
                            for activity in activityList {
                                self.userActivities[activity.activityID ?? ""] = activity
                            }
                            activities.append(contentsOf: activityList)
                            group.leave()
                        }
                    }
                }
            }
        }
        group.notify(queue: .global()) {
            completion(activities)
        }
    }
    
    func getDataFromSnapshotViaCalendar(ID: String, userID: String, calendar: CalendarType, completion: @escaping ([Activity])->()) {
        let ref = Database.database().reference()
        var activities: [Activity] = []
        let group = DispatchGroup()
        group.enter()
        ref.child(userActivitiesEntity).child(userID).child(ID).observeSingleEvent(of: .value, with: { snapshot in
            if snapshot.exists(), let dictionary = snapshot.value as? [String: AnyObject] {
                let userActivity = Activity(dictionary: dictionary[messageMetaDataFirebaseFolder] as? [String : AnyObject])
                ref.child(activitiesEntity).child(ID).child(messageMetaDataFirebaseFolder).observeSingleEvent(of: .value, with: { activitySnapshot in
                    if activitySnapshot.exists(), let activitySnapshotValue = activitySnapshot.value as? [String: AnyObject] {
                        let activity = Activity(dictionary: activitySnapshotValue)
                        activity.showExtras = userActivity.showExtras
                        activity.calendarID = calendar.id
                        activity.calendarName = calendar.name
                        activity.calendarColor = calendar.color
                        activity.calendarSource = calendar.source
                        activity.userIsCompleted = userActivity.userIsCompleted
                        activity.userCompletedDate = userActivity.userCompletedDate
                        activity.calendarExport = true
                        activity.externalActivityID = nil
                        activity.reminder = nil
                        activity.badge = nil
                        activity.muted = nil
                        activity.pinned = nil
                        activities.append(activity)
                    }
                    group.leave()
                })
            } else {
                ref.child(activitiesEntity).child(ID).child(messageMetaDataFirebaseFolder).observeSingleEvent(of: .value, with: { activitySnapshot in
                    if activitySnapshot.exists(), let activitySnapshotValue = activitySnapshot.value as? [String: AnyObject] {
                        let activity = Activity(dictionary: activitySnapshotValue)
                        activities.append(activity)
                    }
                    group.leave()
                })
            }
        })
        group.notify(queue: .global()) {
            completion(activities)
        }
    }
    
    func grabActivitiesViaList(lists: [ListType], completion: @escaping ([Activity])->()) {
        guard let currentUserID = Auth.auth().currentUser?.uid else {
            return
        }
        
        var activities: [Activity] = []
        let group = DispatchGroup()
        let filteredLists = lists.filter({ $0.admin != currentUserID })
        for list in filteredLists {
            if let taskIDs = list.taskIDs?.keys {
                for ID in taskIDs {
                    if self.userActivities[ID] == nil, let admin = list.admin {
                        group.enter()
                        self.getDataFromSnapshotViaList(ID: ID, userID: admin, list: list) { activityList in
                            for activity in activityList {
                                self.userActivities[activity.activityID ?? ""] = activity
                            }
                            activities.append(contentsOf: activityList)
                            group.leave()
                        }
                    }
                }
            }
        }
        
        group.notify(queue: .global()) {
            completion(activities)
        }
    }
    
    func getDataFromSnapshotViaList(ID: String, userID: String, list: ListType, completion: @escaping ([Activity])->()) {
        let ref = Database.database().reference()
        var activities: [Activity] = []
        let group = DispatchGroup()
        group.enter()
        ref.child(userActivitiesEntity).child(userID).child(ID).observeSingleEvent(of: .value, with: { snapshot in
            if snapshot.exists(), let dictionary = snapshot.value as? [String: AnyObject] {
                let userActivity = Activity(dictionary: dictionary[messageMetaDataFirebaseFolder] as? [String : AnyObject])
                ref.child(activitiesEntity).child(ID).child(messageMetaDataFirebaseFolder).observeSingleEvent(of: .value, with: { activitySnapshot in
                    if activitySnapshot.exists(), let activitySnapshotValue = activitySnapshot.value as? [String: AnyObject] {
                        let activity = Activity(dictionary: activitySnapshotValue)
                        activity.showExtras = userActivity.showExtras
                        activity.calendarID = userActivity.calendarID
                        activity.calendarName = userActivity.calendarName
                        activity.calendarColor = userActivity.calendarColor
                        activity.calendarSource = userActivity.calendarSource
                        activity.userIsCompleted = userActivity.userIsCompleted
                        activity.userCompletedDate = userActivity.userCompletedDate
                        activity.calendarExport = true
                        activity.externalActivityID = nil
                        activity.reminder = nil
                        activity.badge = nil
                        activity.muted = nil
                        activity.pinned = nil
                        activities.append(activity)
                    }
                    group.leave()
                })
            } else {
                ref.child(activitiesEntity).child(ID).child(messageMetaDataFirebaseFolder).observeSingleEvent(of: .value, with: { activitySnapshot in
                    if activitySnapshot.exists(), let activitySnapshotValue = activitySnapshot.value as? [String: AnyObject] {
                        let activity = Activity(dictionary: activitySnapshotValue)
                        activities.append(activity)
                    }
                    group.leave()
                })
            }
        })
        group.notify(queue: .global()) {
            completion(activities)
        }
    }
}
