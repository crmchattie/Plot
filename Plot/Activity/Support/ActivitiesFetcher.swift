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
import RRuleSwift

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
                    print(ID)
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
                                activity.userCompleted = userActivity.userCompleted
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
                                    activity.userCompleted = userActivity.userCompleted
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
            if let completion = self.activitiesRemoved {
                self.userActivities[snapshot.key] = nil
                ActivitiesFetcher.getDataFromSnapshot(ID: snapshot.key, parentID: nil, completion: completion)
            }
        })
        
        currentUserActivitiesChangeHandle = userActivitiesDatabaseRef.observe(.childChanged, with: { snapshot in
            if let completion = self.activitiesChanged, let completionRepeats = self.activitiesWithRepeatsAdded {
                ActivitiesFetcher.getDataFromSnapshot(ID: snapshot.key, parentID: nil) { activityList in
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
    
    class func getDataFromSnapshot(ID: String, parentID: String?, completion: @escaping ([Activity])->()) {
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
                        activity.userCompleted = userActivity.userCompleted
                        activity.userCompletedDate = userActivity.userCompletedDate
                        activity.reminder = userActivity.reminder
                        activity.badge = userActivity.badge
                        activity.badgeDate = userActivity.badgeDate
                        activity.muted = userActivity.muted
                        activity.pinned = userActivity.pinned
                        if let parentID = parentID, let instanceIDs = activity.instanceIDs {
                            ActivitiesFetcher.grabInstanceActivities(IDs: instanceIDs) { _ , instanceActivities in
                                if let instanceActivity = instanceActivities[parentID] {
                                    let newActivity = activity.updateActivityWActivityNewInstance(updatingActivity: instanceActivity)
                                    activities.append(newActivity)
                                } else {
                                    activities.append(activity)
                                }
                                group.leave()
                            }
                        } else {
                            activities.append(activity)
                            group.leave()
                        }
                    } else {
                        group.leave()
                    }
                })
            } else {
                ref.child(activitiesEntity).child(ID).child(messageMetaDataFirebaseFolder).observeSingleEvent(of: .value, with: { activitySnapshot in
                    if activitySnapshot.exists(), let activitySnapshotValue = activitySnapshot.value as? [String: AnyObject] {
                        let activity = Activity(dictionary: activitySnapshotValue)
                        if let parentID = parentID, let instanceIDs = activity.instanceIDs {
                            ActivitiesFetcher.grabInstanceActivities(IDs: instanceIDs) { _ , instanceActivities in
                                if let instanceActivity = instanceActivities[parentID] {
                                    let newActivity = activity.updateActivityWActivityNewInstance(updatingActivity: instanceActivity)
                                    activities.append(newActivity)
                                } else {
                                    activities.append(activity)
                                }
                                group.leave()
                            }
                        } else {
                            activities.append(activity)
                            group.leave()
                        }
                    } else {
                        group.leave()
                    }
                })
            }
        })
        group.notify(queue: .main) {
            completion(activities)
        }
    }
    
    func addRepeatingActivities(activity: Activity, completion: @escaping ([Activity])->()) {
        var newActivities = [Activity]()
        let group = DispatchGroup()
        var counter = 0
        if let rules = activity.recurrences, !rules.isEmpty {
            let futureDate = Calendar.current.date(byAdding: .month, value: 3, to: Date())
            group.enter()
            counter += 1
            if let goalPeriod = activity.goalPeriod, let period = GoalPeriod(rawValue: goalPeriod) {
                if let startDate = activity.startDate {
                    if let instanceIDs = activity.instanceIDs {
                        ActivitiesFetcher.grabInstanceActivities(IDs: instanceIDs) { activities, _ in
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
                            let dayBeforeNowDate = Calendar.current.date(byAdding: .day, value: -1, to: startDate)
                            let dates = iCalUtility().recurringDates(forRules: rules, ruleStartDate: startDate, startDate: dayBeforeNowDate ?? Date(), endDate: futureDate ?? Date())
                            for (index, date) in dates.enumerated() {
                                let updatedStartDate = NSNumber(value: Int(date.timeIntervalSince1970))
                                if let instanceActivity = activities[updatedStartDate], let instanceID = instanceActivity.instanceID {
                                    let newActivity = activity.updateActivityWActivityNewInstance(updatingActivity: instanceActivity)
                                    newActivity.recurrenceStartDateTime = activity.startDateTime
                                    newActivity.instanceIndex = index
                                    if period != .month {
                                        newActivity.startDateTime = NSNumber(value: Int(date.timeIntervalSince1970))
                                    } else {
                                        newActivity.startDateTime = NSNumber(value: Int(date.startOfDay.UTCTime.timeIntervalSince1970))
                                    }
                                    newActivity.endDateTime = NSNumber(value: Int(newActivity.endDateGivenStartDatePeriod?.timeIntervalSince1970 ?? 0))
                                    self.instanceActivities[instanceID] = newActivity
                                    newActivities.append(newActivity)
                                } else {
                                    let newActivity = activity.copy() as! Activity
                                    newActivity.recurrenceStartDateTime = activity.finalDateTime
                                    newActivity.instanceIndex = index
                                    if period != .month {
                                        newActivity.startDateTime = NSNumber(value: Int(date.timeIntervalSince1970))
                                    } else {
                                        newActivity.startDateTime = NSNumber(value: Int(date.startOfDay.UTCTime.timeIntervalSince1970))
                                    }
                                    newActivity.endDateTime = NSNumber(value: Int(newActivity.endDateGivenStartDatePeriod?.timeIntervalSince1970 ?? 0))
                                    newActivities.append(newActivity)
                                }
                            }
                            group.leave()
                            counter -= 1
                        }
                    } else {
                        let dayBeforeNowDate = Calendar.current.date(byAdding: .day, value: -1, to: startDate)
                        let dates = iCalUtility().recurringDates(forRules: rules, ruleStartDate: startDate, startDate: dayBeforeNowDate ?? Date(), endDate: futureDate ?? Date())
                        for (index, date) in dates.enumerated() {
                            let newActivity = activity.copy() as! Activity
                            newActivity.recurrenceStartDateTime = activity.startDateTime
                            newActivity.instanceIndex = index
                            if period != .month {
                                newActivity.startDateTime = NSNumber(value: Int(date.timeIntervalSince1970))
                            } else {
                                newActivity.startDateTime = NSNumber(value: Int(date.startOfDay.UTCTime.timeIntervalSince1970))
                            }
                            newActivity.endDateTime = NSNumber(value: Int(newActivity.endDateGivenStartDatePeriod?.timeIntervalSince1970 ?? 0))
                            newActivities.append(newActivity)
                        }
                        group.leave()
                        counter -= 1
                    }
                } else if let endDate = activity.endDate {
                    if let instanceIDs = activity.instanceIDs {
                        ActivitiesFetcher.grabInstanceActivities(IDs: instanceIDs) { activities, _ in
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
                            let dayBeforeNowDate = Calendar.current.date(byAdding: .day, value: -1, to: endDate)
                            let dates = iCalUtility().recurringDates(forRules: rules, ruleStartDate: endDate, startDate: dayBeforeNowDate ?? Date(), endDate: futureDate ?? Date())
                            for (index, date) in dates.enumerated() {
                                let updatedDate = NSNumber(value: Int(date.timeIntervalSince1970))
                                if let instanceActivity = activities[updatedDate], let instanceID = instanceActivity.instanceID {
                                    let newActivity = activity.updateActivityWActivityNewInstance(updatingActivity: instanceActivity)
                                    newActivity.recurrenceStartDateTime = activity.endDateTime
                                    newActivity.instanceIndex = index
                                    if period != .month {
                                        newActivity.endDateTime = NSNumber(value: Int(date.endOfDay.advanced(by: -1).timeIntervalSince1970))
                                    } else {
                                        newActivity.endDateTime = NSNumber(value: Int(date.endOfDay.advanced(by: -1).UTCTime.timeIntervalSince1970))
                                    }
                                    self.instanceActivities[instanceID] = newActivity
                                    newActivities.append(newActivity)
                                } else {
                                    let newActivity = activity.copy() as! Activity
                                    newActivity.recurrenceStartDateTime = activity.endDateTime
                                    newActivity.instanceIndex = index
                                    if period != .month {
                                        newActivity.endDateTime = NSNumber(value: Int(date.endOfDay.advanced(by: -1).timeIntervalSince1970))
                                    } else {
                                        newActivity.endDateTime = NSNumber(value: Int(date.endOfDay.advanced(by: -1).UTCTime.timeIntervalSince1970))
                                    }
                                    newActivities.append(newActivity)
                                }
                            }
                            group.leave()
                            counter -= 1
                        }
                    } else {
                        let dayBeforeNowDate = Calendar.current.date(byAdding: .day, value: -1, to: endDate)
                        let dates = iCalUtility().recurringDates(forRules: rules, ruleStartDate: endDate, startDate: dayBeforeNowDate ?? Date(), endDate: futureDate ?? Date())
                        for (index, date) in dates.enumerated() {
                            let newActivity = activity.copy() as! Activity
                            newActivity.recurrenceStartDateTime = activity.endDateTime
                            newActivity.instanceIndex = index
                            if period != .month {
                                newActivity.endDateTime = NSNumber(value: Int(date.endOfDay.advanced(by: -1).timeIntervalSince1970))
                            } else {
                                newActivity.endDateTime = NSNumber(value: Int(date.endOfDay.advanced(by: -1).UTCTime.timeIntervalSince1970))
                            }
                            newActivities.append(newActivity)
                        }
                        group.leave()
                        counter -= 1
                    }
                }
            } else if let endDate = activity.endDate, let startDate = activity.startDate {
                if let instanceIDs = activity.instanceIDs {
                    ActivitiesFetcher.grabInstanceActivities(IDs: instanceIDs) { activities, _ in
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
                        let dayBeforeNowDate = Calendar.current.date(byAdding: .day, value: -1, to: startDate)
                        let dates = iCalUtility().recurringDates(forRules: rules, ruleStartDate: startDate, startDate: dayBeforeNowDate ?? Date(), endDate: futureDate ?? Date())
                        let duration = endDate.timeIntervalSince(startDate)
                        for (index, date) in dates.enumerated() {
                            let updatedStartDate = NSNumber(value: Int(date.timeIntervalSince1970))
                            let updatedEndDate = NSNumber(value: Int(date.timeIntervalSince1970 + duration))
                            if let instanceActivity = activities[updatedStartDate], let instanceID = instanceActivity.instanceID {
                                let newActivity = activity.updateActivityWActivityNewInstance(updatingActivity: instanceActivity)
                                newActivity.recurrenceStartDateTime = activity.startDateTime
                                newActivity.instanceIndex = index
                                if newActivity.startDateTime == activity.startDateTime {
                                    newActivity.startDateTime = updatedStartDate
                                }
                                if newActivity.endDateTime == activity.endDateTime {
                                    newActivity.endDateTime = updatedEndDate
                                }
                                self.instanceActivities[instanceID] = newActivity
                                newActivities.append(newActivity)
                            } else {
                                let newActivity = activity.copy() as! Activity
                                newActivity.recurrenceStartDateTime = activity.startDateTime
                                newActivity.instanceIndex = index
                                newActivity.startDateTime = updatedStartDate
                                newActivity.endDateTime = updatedEndDate
                                newActivities.append(newActivity)
                            }
                        }
                        group.leave()
                        counter -= 1
                    }
                } else {
                    let dayBeforeNowDate = Calendar.current.date(byAdding: .day, value: -1, to: startDate)
                    let dates = iCalUtility().recurringDates(forRules: rules, ruleStartDate: startDate, startDate: dayBeforeNowDate ?? Date(), endDate: futureDate ?? Date())
                    let duration = endDate.timeIntervalSince(startDate)
                    for (index, date) in dates.enumerated() {
                        let newActivity = activity.copy() as! Activity
                        newActivity.recurrenceStartDateTime = activity.startDateTime
                        newActivity.instanceIndex = index
                        newActivity.startDateTime = NSNumber(value: Int(date.timeIntervalSince1970))
                        newActivity.endDateTime = NSNumber(value: Int(date.timeIntervalSince1970 + duration))
                        newActivities.append(newActivity)
                    }
                    group.leave()
                    counter -= 1
                }
            } else if let endDate = activity.endDate {
                if let instanceIDs = activity.instanceIDs {
                    ActivitiesFetcher.grabInstanceActivities(IDs: instanceIDs) { activities, _ in
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
                        let dayBeforeNowDate = Calendar.current.date(byAdding: .day, value: -1, to: endDate)
                        let dates = iCalUtility().recurringDates(forRules: rules, ruleStartDate: endDate, startDate: dayBeforeNowDate ?? Date(), endDate: futureDate ?? Date())
                        for (index, date) in dates.enumerated() {
                            let updatedDate = NSNumber(value: Int(date.timeIntervalSince1970))
                            if let instanceActivity = activities[updatedDate], let instanceID = instanceActivity.instanceID {
                                let newActivity = activity.updateActivityWActivityNewInstance(updatingActivity: instanceActivity)
                                newActivity.recurrenceStartDateTime = activity.endDateTime
                                newActivity.instanceIndex = index
                                if newActivity.endDateTime == activity.endDateTime {
                                    newActivity.endDateTime = updatedDate
                                }
                                self.instanceActivities[instanceID] = newActivity
                                newActivities.append(newActivity)
                            } else {
                                let newActivity = activity.copy() as! Activity
                                newActivity.recurrenceStartDateTime = activity.endDateTime
                                newActivity.instanceIndex = index
                                newActivity.endDateTime = updatedDate
                                newActivities.append(newActivity)
                            }
                        }
                        group.leave()
                        counter -= 1
                    }
                } else {
                    let dayBeforeNowDate = Calendar.current.date(byAdding: .day, value: -1, to: endDate)
                    let dates = iCalUtility().recurringDates(forRules: rules, ruleStartDate: endDate, startDate: dayBeforeNowDate ?? Date(), endDate: futureDate ?? Date())
                    for (index, date) in dates.enumerated() {
                        let newActivity = activity.copy() as! Activity
                        newActivity.recurrenceStartDateTime = activity.finalDateTime
                        newActivity.instanceIndex = index
                        newActivity.endDateTime = NSNumber(value: Int(date.timeIntervalSince1970))
                        newActivities.append(newActivity)
                    }
                    group.leave()
                    counter -= 1
                }
            } else {
                group.leave()
                counter -= 1
            }
        }
        group.notify(queue: .main) {
//            if activity.isGoal ?? false {
//                print("found goal")
//                print(activity.name)
//                print(activity.activityID)
//                print(activity.startDate)
//                print(activity.endDate)
//                print(activity.startDateTime)
//                print(activity.endDateTime)
//                for newActivity in newActivities {
//                    print("instance")
//                    print(newActivity.name)
//                    print(newActivity.startDate)
//                    print(newActivity.endDate)
//                }
//            }
            completion(newActivities)
        }
    }
    
    class func grabInstanceActivities(IDs: [String], completion: @escaping ([NSNumber: Activity], [String: Activity])->()) {
        let ref = Database.database().reference()
        var activitiesDate: [NSNumber: Activity] = [:]
        var activitiesParent: [String: Activity] = [:]
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
                        if let instanceOriginalStartDateTime = activity.instanceOriginalStartDateTime {
                            activitiesDate[Int(truncating: instanceOriginalStartDateTime) as NSNumber] = activity
                        }
                        if let parentID = activity.parentID {
                            activitiesParent[parentID] = activity
                        }
                        group.leave()
                        counter -= 1
                    } else {
                        if let instanceOriginalStartDateTime = activity.instanceOriginalStartDateTime {
                            activitiesDate = [:]
                            activitiesDate[Int(truncating: instanceOriginalStartDateTime) as NSNumber] = activity
                        }
                        if let parentID = activity.parentID {
                            activitiesParent = [:]
                            activitiesParent[parentID] = activity
                        }
                        completion(activitiesDate, activitiesParent)
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
            completion(activitiesDate, activitiesParent)
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
        group.notify(queue: .main) {
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
                        activity.userCompleted = userActivity.userCompleted
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
        group.notify(queue: .main) {
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
                                guard !(activity.isGoal ?? false) else {
                                    continue
                                }
                                
                                self.userActivities[activity.activityID ?? ""] = activity
                                activities.append(activity)
                            }
                            group.leave()
                        }
                    }
                }
            }
        }
        
        group.notify(queue: .main) {
            completion(activities)
        }
    }
    
    func getDataFromSnapshotViaList(ID: String, userID: String, list: ListType, completion: @escaping ([Activity])->()) {
        guard let currentUserID = Auth.auth().currentUser?.uid else {
            return
        }
        
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
                        activity.participantsIDs?.append(currentUserID)
                        activity.showExtras = userActivity.showExtras
                        activity.calendarID = userActivity.calendarID
                        activity.calendarName = userActivity.calendarName
                        activity.calendarColor = userActivity.calendarColor
                        activity.calendarSource = userActivity.calendarSource
                        activity.userCompleted = userActivity.userCompleted
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
                        activity.participantsIDs?.append(currentUserID)
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
}
