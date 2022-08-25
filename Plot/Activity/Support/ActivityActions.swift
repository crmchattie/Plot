//
//  CreateActivity.swift
//  Plot
//
//  Created by Cory McHattie on 4/11/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import UIKit
import Firebase
import EventKit

class ActivityActions: NSObject {
    
    var activity: Activity?
    var activityID: String?
    var active: Bool?
    var selectedFalconUsers: [User]?
    
    let dispatchGroup = DispatchGroup()
    let eventKitService = EventKitService()
    let googleCalService = GoogleCalService()
        
    init(activity: Activity, active: Bool?, selectedFalconUsers: [User]) {
        super.init()
        self.activity = activity
        self.activityID = activity.activityID
        self.active = active
        self.selectedFalconUsers = selectedFalconUsers
    }
    
    func deleteActivity() {
        guard currentReachabilityStatus != .notReachable else {
            return
        }
        
        guard let _ = active, let activity = activity, let activityID = activityID, let _ = selectedFalconUsers else {
            return
        }
                                  
        let membersIDs = fetchMembersIDs()
        
        for memberID in membersIDs.0 {
            Database.database().reference().child(userActivitiesEntity).child(memberID).child(activityID).child(messageMetaDataFirebaseFolder).removeAllObservers()
            Database.database().reference().child(userActivitiesEntity).child(memberID).child(activityID).removeValue()
        }
        
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["\(activityID)_Reminder"])
        
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            return
        }
        
        if activity.isTask ?? false {
            let reference = Database.database().reference().child(userReminderTasksEntity).child(currentUserId).child(primaryReminderKey)
            reference.observeSingleEvent(of: .value, with: { (snapshot) in
                if snapshot.exists(), let value = snapshot.value as? String {
                    if value == ListOptions.apple.name {
                        self.eventKitService.deleteReminder(for: activity)
                    } else if value == ListOptions.google.name {
                        self.googleCalService.deleteTask(for: activity)
                    }
                }
            })
        } else {
            let reference = Database.database().reference().child(userCalendarEventsEntity).child(currentUserId).child(primaryCalendarKey)
            reference.observeSingleEvent(of: .value, with: { (snapshot) in
                if snapshot.exists(), let value = snapshot.value as? String {
                    if value == CalendarOptions.apple.name {
                        self.eventKitService.deleteEvent(for: activity)
                    } else if value == CalendarOptions.google.name {
                        self.googleCalService.deleteEvent(for: activity)
                    }
                }
            })
        }
    }
    
    func createNewActivity() {
        guard currentReachabilityStatus != .notReachable else {
            return
        }
        
        guard let active = active, let activity = activity, let activityID = activityID, let _ = selectedFalconUsers else {
            return
        }
        
        if !active {
            activity.admin = Auth.auth().currentUser?.uid
        }
        
        let membersIDs = fetchMembersIDs()
        activity.participantsIDs = membersIDs.0
        
        storeReminder()
    
        let firebaseDictionary = activity.toAnyObject()
        
        incrementBadgeForReciever(activityID: activityID, participantsIDs: membersIDs.0)
        
        if active {
            Analytics.logEvent("update_activity", parameters: [
                "activity_name": activity.name ?? "name" as NSObject,
                "activity_type": activity.activityType ?? "basic" as NSObject
            ])
            updateActivity(firebaseDictionary: firebaseDictionary)
        } else {
            Analytics.logEvent("new_activity", parameters: [
                "activity_name": activity.name ?? "name" as NSObject,
                "activity_type": activity.activityType ?? "basic" as NSObject
            ])
            newActivity(firebaseDictionary: firebaseDictionary, membersIDs: membersIDs)
        }
    }
    
    func createSubActivity() {
        guard let activity = activity, let _ = activityID, let _ = selectedFalconUsers else {
            return
        }
        scheduleReminder()
    
        let firebaseDictionary = activity.toAnyObject()
        updateActivity(firebaseDictionary: firebaseDictionary)
    }
    
    func updateActivityParticipants() {
        guard let _ = active, let activity = activity, let activityID = activityID, let selectedFalconUsers = selectedFalconUsers else {
            return
        }
        let membersIDs = fetchMembersIDs()
        if Set(activity.participantsIDs!) != Set(membersIDs.0) {
            let groupActivityReference = Database.database().reference().child(activitiesEntity).child(activityID).child(messageMetaDataFirebaseFolder)
            updateParticipants(membersIDs: membersIDs)
            groupActivityReference.updateChildValues(["participantsIDs": membersIDs.0 as AnyObject])
        }
        
        dispatchGroup.notify(queue: DispatchQueue.main, execute: {
            InvitationsFetcher.updateInvitations(forActivity:activity, selectedParticipants: selectedFalconUsers) {
            }
        })
    }
    
    func updateActivity(firebaseDictionary: [String: AnyObject]) {
        guard let activity = activity, let activityID = activityID else {
            return
        }
        
        let groupActivityReference = Database.database().reference().child(activitiesEntity).child(activityID).child(messageMetaDataFirebaseFolder)
        groupActivityReference.updateChildValues(firebaseDictionary)
        
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            return
        }
        
        
        if activity.isTask ?? false {
            let reference = Database.database().reference().child(userReminderTasksEntity).child(currentUserId).child(primaryReminderKey)
            reference.observeSingleEvent(of: .value, with: { (snapshot) in
                if snapshot.exists(), let value = snapshot.value as? String {
                    if value == ListOptions.apple.name {
                        self.eventKitService.updateReminder(for: activity)
                    } else if value == ListOptions.google.name {
                        self.googleCalService.updateTask(for: activity)
                    }
                }
            })
        } else {
            let reference = Database.database().reference().child(userCalendarEventsEntity).child(currentUserId).child(primaryCalendarKey)
            reference.observeSingleEvent(of: .value, with: { (snapshot) in
                if snapshot.exists(), let value = snapshot.value as? String {
                    if value == CalendarOptions.apple.name {
                        self.eventKitService.updateEvent(for: activity)
                    } else if value == CalendarOptions.google.name {
                        self.googleCalService.updateEvent(for: activity)
                    }
                }
            })
        }
    }
    
    func newActivity(firebaseDictionary: [String: AnyObject], membersIDs: ([String], [String:AnyObject])) {
        guard let activity = activity, let activityID = activityID, let selectedFalconUsers = selectedFalconUsers else {
            return
        }
                                
        let groupActivityReference = Database.database().reference().child(activitiesEntity).child(activityID).child(messageMetaDataFirebaseFolder)
                
        self.dispatchGroup.enter()
        self.dispatchGroup.enter()
        createGroupActivityNode(reference: groupActivityReference, childValues: firebaseDictionary)
        connectMembersToGroupActivity(memberIDs: membersIDs.0, activityID: activityID)
        self.dispatchGroup.notify(queue: DispatchQueue.main, execute: {
            InvitationsFetcher.updateInvitations(forActivity: activity, selectedParticipants: selectedFalconUsers) {
            }
        })
        
        // Save to calendar
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            return
        }
        
        if activity.isTask ?? false {
            var reference = Database.database().reference().child(userReminderTasksEntity).child(currentUserId).child(primaryReminderKey)
            reference.observeSingleEvent(of: .value, with: { (snapshot) in
                if snapshot.exists(), let value = snapshot.value as? String {
                    if value == ListOptions.apple.name, let reminder = self.eventKitService.storeReminder(for: activity) {
                        reference = Database.database().reference().child(userReminderTasksEntity).child(currentUserId).child(reminderTasksKey).child(reminder.calendarItemIdentifier)
                        let calendarEventActivityValue: [String : Any] = ["activityID": activityID as AnyObject]
                        reference.updateChildValues(calendarEventActivityValue)
                        let userReference = Database.database().reference().child(userActivitiesEntity).child(currentUserId).child(activityID).child(messageMetaDataFirebaseFolder)
                        let values:[String : Any] = ["calendarExport": true, "externalActivityID": reminder.calendarItemIdentifier as Any]
                        userReference.updateChildValues(values)
                    } else if value == ListOptions.google.name, let task = self.googleCalService.storeTask(for: activity), let id = task.identifier {
                        reference = Database.database().reference().child(userCalendarEventsEntity).child(currentUserId).child(calendarEventsKey).child(id)
                        let calendarEventActivityValue: [String : Any] = ["activityID": activityID as AnyObject]
                        reference.updateChildValues(calendarEventActivityValue)
                        let userReference = Database.database().reference().child(userActivitiesEntity).child(currentUserId).child(activityID).child(messageMetaDataFirebaseFolder)
                        let values:[String : Any] = ["calendarExport": true, "externalActivityID": task.identifier as Any]
                        userReference.updateChildValues(values)
                    }
                }
            })
        } else {
            var reference = Database.database().reference().child(userCalendarEventsEntity).child(currentUserId).child(primaryCalendarKey)
            reference.observeSingleEvent(of: .value, with: { (snapshot) in
                if snapshot.exists(), let value = snapshot.value as? String {
                    if value == CalendarOptions.apple.name, let event = self.eventKitService.storeEvent(for: activity) {
                        reference = Database.database().reference().child(userCalendarEventsEntity).child(currentUserId).child(calendarEventsKey).child(event.calendarItemIdentifier)
                        let calendarEventActivityValue: [String : Any] = ["activityID": activityID as AnyObject]
                        reference.updateChildValues(calendarEventActivityValue)
                        let userReference = Database.database().reference().child(userActivitiesEntity).child(currentUserId).child(activityID).child(messageMetaDataFirebaseFolder)
                        let values:[String : Any] = ["calendarExport": true, "externalActivityID": event.calendarItemIdentifier as Any]
                        userReference.updateChildValues(values)
                    } else if value == CalendarOptions.google.name, let event = self.googleCalService.storeEvent(for: activity), let id = event.identifier {
                        reference = Database.database().reference().child(userCalendarEventsEntity).child(currentUserId).child(calendarEventsKey).child(id)
                        let calendarEventActivityValue: [String : Any] = ["activityID": activityID as AnyObject]
                        reference.updateChildValues(calendarEventActivityValue)
                        let userReference = Database.database().reference().child(userActivitiesEntity).child(currentUserId).child(activityID).child(messageMetaDataFirebaseFolder)
                        let values:[String : Any] = ["calendarExport": true, "externalActivityID": event.identifier as Any]
                        userReference.updateChildValues(values)
                    }
                }
            })
        }
    }
    
    func updateRecurrences(recurrences: [String]) {
        guard let _ = activity, let activityID = activityID, let _ = selectedFalconUsers else {
            return
        }
        let groupActivityReference = Database.database().reference().child(activitiesEntity).child(activityID).child(messageMetaDataFirebaseFolder).child("recurrences")
        groupActivityReference.setValue(recurrences)
    }
    
    func deleteRecurrences() {
        guard let _ = activity, let activityID = activityID, let _ = selectedFalconUsers else {
            return
        }
        let groupActivityReference = Database.database().reference().child(activitiesEntity).child(activityID).child(messageMetaDataFirebaseFolder).child("recurrences")
        groupActivityReference.removeValue()
    }
    
    func fetchMembersIDs() -> ([String], [String:AnyObject]) {
        var membersIDs = [String]()
        var membersIDsDictionary = [String:AnyObject]()
        
        guard let activity = activity, let selectedFalconUsers = selectedFalconUsers else {
            return (membersIDs, membersIDsDictionary)
        }
        
        guard let currentUserID = Auth.auth().currentUser?.uid else { return (membersIDs, membersIDsDictionary) }
                
        // Only append current user when admin/creator of the activity
        if activity.admin == currentUserID {
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
    
    func connectMembersToGroupActivity(memberIDs: [String], activityID: String) {
        let connectingMembersGroup = DispatchGroup()
        for _ in memberIDs {
            connectingMembersGroup.enter()
        }
        connectingMembersGroup.notify(queue: DispatchQueue.main, execute: {
            self.dispatchGroup.leave()
        })
        for memberID in memberIDs {
            let userReference = Database.database().reference().child(userActivitiesEntity).child(memberID).child(activityID).child(messageMetaDataFirebaseFolder)
            let values:[String : Any] = ["isGroupActivity": true]
            userReference.updateChildValues(values, withCompletionBlock: { (error, reference) in
                connectingMembersGroup.leave()
            })
        }
    }

    func createGroupActivityNode(reference: DatabaseReference, childValues: [String: Any]) {
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
        guard let activity = activity, let activityID = activityID else {
            return
        }
        let participantsSet = Set(activity.participantsIDs!)
        let membersSet = Set(membersIDs.0)
        let difference = participantsSet.symmetricDifference(membersSet)
        for member in difference {
            if participantsSet.contains(member) {
                Database.database().reference().child(userActivitiesEntity).child(member).child(activityID).removeValue()
            }
            
            dispatchGroup.enter()
            
            connectMembersToGroupActivity(memberIDs: membersIDs.0, activityID: activityID)
        }
    }
    
    func storeReminder() {
        guard let activity = activity, let activityID = activityID else {
            return
        }
        
        if let currentUserID = Auth.auth().currentUser?.uid {
            let userReference = Database.database().reference().child(userActivitiesEntity).child(currentUserID).child(activityID).child(messageMetaDataFirebaseFolder)
            let values:[String : AnyObject] = ["reminder": activity.reminder as AnyObject]
            userReference.updateChildValues(values)
            scheduleReminder()
        }
    }
    
    func scheduleReminder() {
        guard let activity = activity, let activityReminder = activity.reminder, let activityID = activityID, let startDate = activity.startDate, let endDate = activity.endDate, let allDay = activity.allDay, let startTimeZone = activity.startTimeZone, let endTimeZone = activity.endTimeZone else {
            return
        }
        let center = UNUserNotificationCenter.current()
        guard activity.reminder != nil else { return }
        guard activity.reminder! != "None" else {
            center.removePendingNotificationRequests(withIdentifiers: ["\(activityID)_Reminder"])
            return
        }
        let content = UNMutableNotificationContent()
        content.title = "\(String(describing: activity.name!)) Reminder"
        content.sound = UNNotificationSound.default
        var formattedDate: (String, String) = ("", "")
        formattedDate = timestampOfEvent(startDate: startDate, endDate: endDate, allDay: allDay, startTimeZone: startTimeZone, endTimeZone: endTimeZone)
        content.subtitle = formattedDate.0
        if let reminder = EventAlert(rawValue: activityReminder) {
            let reminderDate = startDate.addingTimeInterval(reminder.timeInterval)
            var calendar = Calendar.current
            calendar.timeZone = TimeZone(identifier: startTimeZone)!
            let triggerDate = calendar.dateComponents([.year,.month,.day,.hour,.minute,.second,], from: reminderDate)
            let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate,
                                                        repeats: false)
            let identifier = "\(activityID)_Reminder"
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
            center.add(request, withCompletionHandler: { (error) in
                if let error = error {
                    print(error)
                }
            })
        }
    }
    
    func incrementBadgeForReciever(activityID: String?, participantsIDs: [String]) {
        guard let currentUserID = Auth.auth().currentUser?.uid, let activityID = activityID else { return }
        for participantID in participantsIDs where participantID != currentUserID {
            runActivityBadgeUpdate(firstChild: participantID, secondChild: activityID)
            runUserBadgeUpdate(firstChild: participantID)
        }
    }

    func runActivityBadgeUpdate(firstChild: String, secondChild: String) {
        var ref = Database.database().reference().child(userActivitiesEntity).child(firstChild).child(secondChild)
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            
            guard snapshot.hasChild(messageMetaDataFirebaseFolder) else {
                ref = ref.child(messageMetaDataFirebaseFolder)
                ref.updateChildValues(["badge": 1])
                return
            }
            ref = ref.child(messageMetaDataFirebaseFolder).child("badge")
            ref.runTransactionBlock({ (mutableData) -> TransactionResult in
                var value = mutableData.value as? Int
                if value == nil { value = 0 }
                mutableData.value = value! + 1
                return TransactionResult.success(withValue: mutableData)
            })
        })
    }
}
