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
    var activitiesWithRepeatsInitialAdd: (([Activity])->())?
    var activitiesWithRepeatsAdded: (([Activity])->())?
    var activitiesWithRepeatsChanged: (([Activity])->())?
    //activityID:Activity
    var userActivities: [String: Activity] = [:]
    //instanceID:Activity
    var instanceActivities: [String: Activity] = [:]
            
    func observeActivityForCurrentUser(activitiesInitialAdd: @escaping ([Activity])->(), activitiesWithRepeatsInitialAdd: @escaping ([Activity])->(), activitiesAdded: @escaping ([Activity])->(), activitiesWithRepeatsAdded: @escaping ([Activity])->(), activitiesRemoved: @escaping ([Activity])->(), activitiesChanged: @escaping ([Activity])->(), activitiesWithRepeatsChanged: @escaping ([Activity])->()) {
        guard let currentUserID = Auth.auth().currentUser?.uid else {
            return
        }
        
        let ref = Database.database().reference()
        userActivitiesDatabaseRef = ref.child(userActivitiesEntity).child(currentUserID)
        
        self.activitiesInitialAdd = activitiesInitialAdd
        self.activitiesAdded = activitiesAdded
        self.activitiesRemoved = activitiesRemoved
        self.activitiesChanged = activitiesChanged
        self.activitiesWithRepeatsInitialAdd = activitiesWithRepeatsInitialAdd
        self.activitiesWithRepeatsAdded = activitiesWithRepeatsAdded
        self.activitiesWithRepeatsChanged = activitiesWithRepeatsChanged
                                
        userActivitiesDatabaseRef.observeSingleEvent(of: .value, with: { snapshot in
            guard snapshot.exists() else {
                activitiesInitialAdd([])
                activitiesWithRepeatsInitialAdd([])
                return
            }
            
            if let completion = self.activitiesInitialAdd, let completionRepeats = self.activitiesWithRepeatsInitialAdd {
                var activities: [Activity] = []
                var activitiesWithRepeats: [Activity] = []
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
                                if let rules = activity.recurrences, !rules.isEmpty {
                                    if counter == 0 {
                                        activities = [activity]
                                        completion(activities)
                                    }
                                    self.addRepeatingActivities(activity: activity) { newActivitiesWithRepeats in
                                        if counter > 0 {
                                            activities.append(activity)
                                            activitiesWithRepeats.append(contentsOf: newActivitiesWithRepeats)
                                            group.leave()
                                            counter -= 1
                                        } else {
                                            activitiesWithRepeats = newActivitiesWithRepeats
                                            completionRepeats(activitiesWithRepeats)
                                            return
                                        }
                                    }
                                } else {
                                    if counter > 0 {
                                        activities.append(activity)
                                        activitiesWithRepeats.append(activity)
                                        group.leave()
                                        counter -= 1
                                    } else {
                                        activities = [activity]
                                        completion(activities)
                                        activitiesWithRepeats = [activity]
                                        completionRepeats(activitiesWithRepeats)
                                        return
                                    }
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
                    completionRepeats(activitiesWithRepeats)
                }
            }
        })
        
        currentUserActivitiesAddHandle = userActivitiesDatabaseRef.observe(.childAdded, with: { snapshot in
            if self.userActivities[snapshot.key] == nil {
                print("childAdded")
                print(snapshot)
                if let completion = self.activitiesAdded, let completionRepeats = self.activitiesWithRepeatsAdded {
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
                                    if let rules = activity.recurrences, !rules.isEmpty {
                                        completion([activity])
                                        self.addRepeatingActivities(activity: activity) { newActivitiesWithRepeats in
                                            completionRepeats(newActivitiesWithRepeats)
                                        }
                                    } else {
                                        completion([activity])
                                        completionRepeats([activity])
                                    }
                                }
                            }
                        }
                    }
                }
            }
        })
        currentUserActivitiesRemoveHandle = userActivitiesDatabaseRef.observe(.childRemoved, with: { snapshot in
            print(snapshot)
            if let completion = self.activitiesRemoved {
                self.userActivities[snapshot.key] = nil
                ActivitiesFetcher.getDataFromSnapshot(ID: snapshot.key, completion: completion)
            }
        })
        
        currentUserActivitiesChangeHandle = userActivitiesDatabaseRef.observe(.childChanged, with: { snapshot in
            print(snapshot)
            if let completion = self.activitiesChanged, let completionRepeats = self.activitiesWithRepeatsAdded {
                ActivitiesFetcher.getDataFromSnapshot(ID: snapshot.key) { activityList in
                    for activity in activityList {
                        self.userActivities[activity.activityID ?? ""] = activity
                        if let rules = activity.recurrences, !rules.isEmpty {
                            completion([activity])
                            self.addRepeatingActivities(activity: activity) { newActivitiesWithRepeats in
                                completionRepeats(newActivitiesWithRepeats)
                            }
                        } else {
                            completion([activity])
                            completionRepeats([activity])
                        }
                    }
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
    
    func addRepeatingActivities(activity: Activity, completion: @escaping ([Activity])->()) {
        let yearFromNowDate = Calendar.current.date(byAdding: .year, value: 1, to: Date())
        var newActivities = [Activity]()
        let group = DispatchGroup()
        var counter = 0
        if let rules = activity.recurrences, !rules.isEmpty {
            group.enter()
            counter += 1
            if activity.isTask ?? false {
                if let instanceIDs = activity.instanceIDs {
                    ActivitiesFetcher.grabInstanceActivities(IDs: instanceIDs) { activities in
                        guard counter > 0 else {
                            for (_, instanceActivity) in activities {
                                if let instanceID = instanceActivity.instanceID, let activity = self.instanceActivities[instanceID] {
                                    activity.updateActivityWActivitySameInstance(updatingActivity: instanceActivity)
                                    self.instanceActivities[instanceID] = activity
                                    completion([activity])
                                }
                            }
                            return
                        }
                        let dayBeforeNowDate = Calendar.current.date(byAdding: .day, value: -1, to: activity.endDate ?? Date())
                        let dates = iCalUtility()
                            .recurringDates(forRules: rules, ruleStartDate: activity.finalDate ?? Date(), startDate: dayBeforeNowDate ?? Date(), endDate: yearFromNowDate ?? Date())
                        for date in dates {
                            if let instanceActivity = activities[date], let instanceID = instanceActivity.instanceID {
                                let newActivity = activity.updateActivityWActivityNewInstance(updatingActivity: instanceActivity)
                                newActivity.recurrenceStartDateTime = activity.finalDateTime
                                if newActivity.endDateTime == activity.endDateTime {
                                    newActivity.endDateTime = NSNumber(value: Int(date.timeIntervalSince1970))
                                }
                                self.instanceActivities[instanceID] = newActivity
                                newActivities.append(newActivity)
                            } else {
                                let newActivity = activity.copy() as! Activity
                                newActivity.recurrenceStartDateTime = activity.finalDateTime
                                newActivity.endDateTime = NSNumber(value: Int(date.timeIntervalSince1970))
                                newActivities.append(newActivity)
                            }
                        }
                        group.leave()
                        counter -= 1
                    }
                } else {
                    let dayBeforeNowDate = Calendar.current.date(byAdding: .day, value: -1, to: activity.endDate ?? Date())
                    let dates = iCalUtility()
                        .recurringDates(forRules: rules, ruleStartDate: activity.finalDate ?? Date(), startDate: dayBeforeNowDate ?? Date(), endDate: yearFromNowDate ?? Date())
                    for date in dates {
                        let newActivity = activity.copy() as! Activity
                        newActivity.recurrenceStartDateTime = activity.finalDateTime
                        newActivity.endDateTime = NSNumber(value: Int(date.timeIntervalSince1970))
                        newActivities.append(newActivity)
                    }
                    group.leave()
                    counter -= 1
                }
            } else {
                if let instanceIDs = activity.instanceIDs {
                    ActivitiesFetcher.grabInstanceActivities(IDs: instanceIDs) { activities in
                        guard counter > 0 else {
                            for (_, instanceActivity) in activities {
                                if let instanceID = instanceActivity.instanceID, let activity = self.instanceActivities[instanceID] {
                                    activity.updateActivityWActivitySameInstance(updatingActivity: instanceActivity)
                                    self.instanceActivities[instanceID] = activity
                                    completion([activity])
                                }
                            }
                            return
                        }
                        if let endDate = activity.endDate, let startDate = activity.startDate {
                            let dayBeforeNowDate = Calendar.current.date(byAdding: .day, value: -1, to: activity.endDate ?? Date())
                            let dates = iCalUtility()
                                .recurringDates(forRules: rules, ruleStartDate: activity.finalDate ?? Date(), startDate: dayBeforeNowDate ?? Date(), endDate: yearFromNowDate ?? Date())
                            let duration = endDate.timeIntervalSince(startDate)
                            for date in dates {
                                if let instanceActivity = activities[date], let instanceID = instanceActivity.instanceID {
                                    let newActivity = activity.updateActivityWActivityNewInstance(updatingActivity: instanceActivity)
                                    newActivity.recurrenceStartDateTime = activity.finalDateTime
                                    if newActivity.startDateTime == activity.startDateTime {
                                        newActivity.startDateTime = NSNumber(value: Int(date.timeIntervalSince1970))
                                    }
                                    if newActivity.endDateTime == activity.endDateTime {
                                        newActivity.endDateTime = NSNumber(value: Int(date.timeIntervalSince1970 + duration))
                                    }
                                    self.instanceActivities[instanceID] = newActivity
                                    newActivities.append(newActivity)
                                } else {
                                    let newActivity = activity.copy() as! Activity
                                    newActivity.recurrenceStartDateTime = activity.finalDateTime
                                    newActivity.startDateTime = NSNumber(value: Int(date.timeIntervalSince1970))
                                    newActivity.endDateTime = NSNumber(value: Int(date.timeIntervalSince1970 + duration))
                                    newActivities.append(newActivity)
                                }
                            }
                        }
                        group.leave()
                        counter -= 1
                    }
                } else {
                    if let endDate = activity.endDate, let startDate = activity.startDate {
                        let dayBeforeNowDate = Calendar.current.date(byAdding: .day, value: -1, to: activity.startDate ?? Date())
                        let dates = iCalUtility()
                            .recurringDates(forRules: rules, ruleStartDate: activity.finalDate ?? Date(), startDate: dayBeforeNowDate ?? Date(), endDate: yearFromNowDate ?? Date())
                        let duration = endDate.timeIntervalSince(startDate)
                        for date in dates {
                            let newActivity = activity.copy() as! Activity
                            newActivity.recurrenceStartDateTime = activity.finalDateTime
                            newActivity.startDateTime = NSNumber(value: Int(date.timeIntervalSince1970))
                            newActivity.endDateTime = NSNumber(value: Int(date.timeIntervalSince1970 + duration))
                            newActivities.append(newActivity)
                        }
                    }
                    group.leave()
                    counter -= 1
                }
            }
        }
        group.notify(queue: .main) {
            completion(newActivities)
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
            if let events = calendar.eventIDs {
                let eventIDs = events.keys
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
            if let tasks = list.taskIDs {
                let taskIDs = tasks.keys
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
