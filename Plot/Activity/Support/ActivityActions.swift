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
        
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            return
        }
        
        let activityDataReference = Database.database().reference().child(activitiesEntity).child(activityID).child(messageMetaDataFirebaseFolder)
        activityDataReference.observeSingleEvent(of: .value, with: { (snapshot) in
            guard let dictionary = snapshot.value as? [String: AnyObject] else { return }
            if let membersIDs = dictionary["participantsIDs"] as? [String:AnyObject] {
                var varMemberIDs = membersIDs
                varMemberIDs[currentUserId] = nil
                activityDataReference.updateChildValues(["participantsIDs": varMemberIDs as AnyObject])
            }
        })
        
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["\(activityID)_Reminder"])
        
        if activity.isTask ?? false {
            let reference = Database.database().reference().child(userReminderTasksEntity).child(currentUserId).child(primaryReminderKey)
            reference.observeSingleEvent(of: .value, with: { (snapshot) in
                if snapshot.exists(), let value = snapshot.value as? String {
                    if value == ListSourceOptions.apple.name {
                        self.eventKitService.deleteReminder(for: activity)
                    } else if value == ListSourceOptions.google.name {
                        self.googleCalService.deleteTask(for: activity)
                    }
                }
            })
        } else {
            let reference = Database.database().reference().child(userCalendarEventsEntity).child(currentUserId).child(primaryCalendarKey)
            reference.observeSingleEvent(of: .value, with: { (snapshot) in
                if snapshot.exists(), let value = snapshot.value as? String {
                    if value == CalendarSourceOptions.apple.name {
                        self.eventKitService.deleteEvent(for: activity)
                    } else if value == CalendarSourceOptions.google.name {
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
        
        guard let active = active, let activity = activity, let activityID = activityID, let _ = selectedFalconUsers, let currentUserId = Auth.auth().currentUser?.uid else {
            return
        }
        
        if !active {
            activity.admin = currentUserId
        }
        
        let membersIDs = fetchMembersIDs()
        activity.participantsIDs = membersIDs.0
        
        storeReminder()
    
        var firebaseDictionary = activity.toAnyObject()
        
        incrementBadgeForReciever(activityID: activityID, participantsIDs: membersIDs.0)
        
        if active {
            Analytics.logEvent("update_activity", parameters: [
                "activity_name": activity.name ?? "name" as NSObject,
                "activity_type": activity.activityType ?? "basic" as NSObject
            ])
            firebaseDictionary["lastModifiedDate"] = NSNumber(value: Int((Date()).timeIntervalSince1970)) as AnyObject
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
            if !(activity.isTask ?? false) {
                InvitationsFetcher.updateInvitations(forActivity: activity, selectedParticipants: selectedFalconUsers) {
                    
                }
            }
        }
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
                    if value == ListSourceOptions.apple.name {
                        self.eventKitService.updateReminder(for: activity)
                    } else if value == ListSourceOptions.google.name {
                        self.googleCalService.updateTask(for: activity)
                    }
                }
            })
        } else {
            let reference = Database.database().reference().child(userCalendarEventsEntity).child(currentUserId).child(primaryCalendarKey)
            reference.observeSingleEvent(of: .value, with: { (snapshot) in
                if snapshot.exists(), let value = snapshot.value as? String {
                    if value == CalendarSourceOptions.apple.name {
                        self.eventKitService.updateEvent(for: activity)
                    } else if value == CalendarSourceOptions.google.name {
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
        
        if let containerID = activity.containerID {
            ContainerFunctions.updateParticipants(containerID: containerID, selectedFalconUsers: selectedFalconUsers)
            self.dispatchGroup.leave()
        } else {
            connectMembersToGroupActivity(memberIDs: membersIDs.0, activityID: activityID)
            self.dispatchGroup.notify(queue: DispatchQueue.main, execute: {
                if !(activity.isTask ?? false) {
                    InvitationsFetcher.updateInvitations(forActivity: activity, selectedParticipants: selectedFalconUsers) {

                    }
                }
            })
        }
        
        // Save to calendar
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            return
        }
        
        if activity.isTask ?? false {
            var reference = Database.database().reference().child(userReminderTasksEntity).child(currentUserId).child(primaryReminderKey)
            reference.observeSingleEvent(of: .value, with: { (snapshot) in
                if snapshot.exists(), let value = snapshot.value as? String {
                    if value == ListSourceOptions.apple.name, let reminder = self.eventKitService.storeReminder(for: activity) {
                        reference = Database.database().reference().child(userReminderTasksEntity).child(currentUserId).child(reminderTasksKey).child(reminder.calendarItemIdentifier)
                        let calendarEventActivityValue: [String : Any] = ["activityID": activityID as AnyObject]
                        reference.updateChildValues(calendarEventActivityValue)
                        let userReference = Database.database().reference().child(userActivitiesEntity).child(currentUserId).child(activityID).child(messageMetaDataFirebaseFolder)
                        let values:[String : Any] = ["calendarExport": true, "externalActivityID": reminder.calendarItemIdentifier as Any]
                        userReference.updateChildValues(values)
                    } else if value == ListSourceOptions.google.name, let task = self.googleCalService.storeTask(for: activity), let id = task.identifier {
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
                    if value == CalendarSourceOptions.apple.name, let event = self.eventKitService.storeEvent(for: activity) {
                        reference = Database.database().reference().child(userCalendarEventsEntity).child(currentUserId).child(calendarEventsKey).child(event.calendarItemIdentifier)
                        let calendarEventActivityValue: [String : Any] = ["activityID": activityID as AnyObject]
                        reference.updateChildValues(calendarEventActivityValue)
                        let userReference = Database.database().reference().child(userActivitiesEntity).child(currentUserId).child(activityID).child(messageMetaDataFirebaseFolder)
                        let values:[String : Any] = ["calendarExport": true, "externalActivityID": event.calendarItemIdentifier as Any]
                        userReference.updateChildValues(values)
                    } else if value == CalendarSourceOptions.google.name, let event = self.googleCalService.storeEvent(for: activity), let id = event.identifier {
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
    
    func updateCompletion(isComplete: Bool) {
        guard let activity = activity, let activityID = activityID, let _ = selectedFalconUsers else {
            return
        }
        let groupActivityReference = Database.database().reference().child(activitiesEntity).child(activityID).child(messageMetaDataFirebaseFolder)
        if isComplete {
            let original = Date()
            let updateDate = Date(timeIntervalSinceReferenceDate:
                                (original.timeIntervalSinceReferenceDate / 300.0).rounded(.toNearestOrEven) * 300.0)
            let completedDate = NSNumber(value: Int((updateDate).timeIntervalSince1970))
            let values:[String : Any] = ["isCompleted": isComplete, "completedDate": completedDate as Any]
            groupActivityReference.updateChildValues(values)
            activity.completedDate = completedDate
            
        } else {
            let values:[String : Any] = ["isCompleted": isComplete]
            groupActivityReference.updateChildValues(values)
            groupActivityReference.child("completedDate").removeValue()
            activity.completedDate = nil
        }
        activity.isCompleted = isComplete
        
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            return
        }
        
        let reference = Database.database().reference().child(userReminderTasksEntity).child(currentUserId).child(primaryReminderKey)
        reference.observeSingleEvent(of: .value, with: { (snapshot) in
            if snapshot.exists(), let value = snapshot.value as? String {
                if value == ListSourceOptions.apple.name {
                    self.eventKitService.updateReminder(for: activity)
                } else if value == ListSourceOptions.google.name {
                    self.googleCalService.updateTask(for: activity)
                }
            }
        })
        
    }
    
    func fetchMembersIDs() -> ([String], [String:AnyObject]) {
        var membersIDs = [String]()
        var membersIDsDictionary = [String:AnyObject]()
        
        guard let _ = activity, let selectedFalconUsers = selectedFalconUsers, let currentUserID = Auth.auth().currentUser?.uid else {
            return (membersIDs, membersIDsDictionary)
        }
                        
        membersIDsDictionary.updateValue(currentUserID as AnyObject, forKey: currentUserID)
        membersIDs.append(currentUserID)
        
        for selectedUser in selectedFalconUsers {
            guard let id = selectedUser.id else { continue }
            membersIDsDictionary.updateValue(id as AnyObject, forKey: id)
            membersIDs.append(id)
        }
        
        return (membersIDs, membersIDsDictionary)
    }
    
    func connectMembersToGroupActivity(memberIDs: [String], activityID: String) {
        guard let activity = activity, let currentUserID = Auth.auth().currentUser?.uid else {
            self.dispatchGroup.leave()
            return
        }
        let connectingMembersGroup = DispatchGroup()
        for _ in memberIDs {
            connectingMembersGroup.enter()
        }
        connectingMembersGroup.notify(queue: DispatchQueue.main, execute: {
            self.dispatchGroup.leave()
        })
        for memberID in memberIDs {
            if activity.isTask ?? false {
                let userReference = Database.database().reference().child(userActivitiesEntity).child(memberID).child(activityID).child(messageMetaDataFirebaseFolder)
                let values: [String : Any] = ["isGroupActivity": true,
                                              "badge": 0,
                                              "showExtras": activity.showExtras as Any]
                userReference.updateChildValues(values, withCompletionBlock: { (error, reference) in
                    connectingMembersGroup.leave()
                })
            } else {
                if memberID == currentUserID, let calendarID = activity.calendarID {
                    let userReference = Database.database().reference().child(userActivitiesEntity).child(memberID).child(activityID).child(messageMetaDataFirebaseFolder)
                    let values: [String : Any] = ["isGroupActivity": true,
                                                  "badge": 0,
                                                  "calendarID": calendarID as Any,
                                                  "calendarName": activity.calendarName as Any,
                                                  "calendarSource": activity.calendarSource as Any,
                                                  "calendarColor": activity.calendarColor as Any,
                                                  "showExtras": activity.showExtras as Any]
                    userReference.updateChildValues(values, withCompletionBlock: { (error, reference) in
                        let calendarReference = Database.database().reference().child(calendarEntity).child(calendarID.removeCharacters()).child(calendarEventsEntity)
                        calendarReference.child(activityID).setValue(true)
                        connectingMembersGroup.leave()
                    })
                } else {
                    CalendarFetcher.fetchCalendarsForUser(id: memberID) { calendars in
                        if let calendar = calendars.first(where: { $0.defaultCalendar ?? false }) {
                            let userReference = Database.database().reference().child(userActivitiesEntity).child(memberID).child(activityID).child(messageMetaDataFirebaseFolder)
                            let values: [String : Any] = ["isGroupActivity": true,
                                                          "badge": 0,
                                                          "calendarID": calendar.id as Any,
                                                          "calendarName": calendar.name as Any,
                                                          "calendarSource": calendar.source as Any,
                                                          "calendarColor": calendar.color as Any,
                                                          "showExtras": activity.showExtras as Any]
                            userReference.updateChildValues(values, withCompletionBlock: { (error, reference) in
                                let calendarReference = Database.database().reference().child(calendarEntity).child(calendar.id ?? "").child(calendarEventsEntity)
                                calendarReference.child(activityID).setValue(true)
                                connectingMembersGroup.leave()
                            })
                        }
                    }
                }
            }
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
        }
        
        dispatchGroup.enter()
        
        connectMembersToGroupActivity(memberIDs: membersIDs.0, activityID: activityID)
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
