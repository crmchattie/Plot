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
    
    func deleteActivity(updateExternal: Bool, updateDirectAssociation: Bool) {
        guard currentReachabilityStatus != .notReachable else {
            return
        }
        
        guard let _ = active, let activity = activity, let activityID = activityID, let selectedFalconUsers = selectedFalconUsers, let currentUserID = Auth.auth().currentUser?.uid else {
            return
        }
                                  
        let membersIDs = fetchMembersIDs()
        
        for memberID in membersIDs.0 {
            Database.database().reference().child(userActivitiesEntity).child(memberID).child(activityID).child(messageMetaDataFirebaseFolder).removeAllObservers()
            Database.database().reference().child(userActivitiesEntity).child(memberID).child(activityID).removeValue()
        }
        
        let activityDataReference = Database.database().reference().child(activitiesEntity).child(activityID).child(messageMetaDataFirebaseFolder)
        activityDataReference.observeSingleEvent(of: .value, with: { (snapshot) in
            guard let dictionary = snapshot.value as? [String: AnyObject] else { return }
            if let membersIDs = dictionary["participantsIDs"] as? [String:AnyObject] {
                var varMemberIDs = membersIDs
                varMemberIDs[currentUserID] = nil
                activityDataReference.updateChildValues(["participantsIDs": varMemberIDs as AnyObject])
            }
        })
        
        if let _ = activity.containerID {
            ContainerFunctions.deleteStuffInside(type: .activity, ID: activityID)
        }
        
        if updateDirectAssociation, activity.directAssociation ?? false, let ID = activity.directAssociationObjectID {
            if activity.directAssociationType == .workout {
                WorkoutFetcher.getDataFromSnapshot(ID: ID) { workouts in
                    if let workout = workouts.first, workout.user_created ?? false {
                        let workoutAction = WorkoutActions(workout: workout, active: true, selectedFalconUsers: selectedFalconUsers)
                        workoutAction.deleteWorkout(updateDirectAssociation: false)
                    }
                }
            } else if activity.directAssociationType == .mindfulness {
                MindfulnessFetcher.getDataFromSnapshot(ID: ID) { mindfulnesses in
                    if let mindfulness = mindfulnesses.first, mindfulness.user_created ?? false {
                        let mindfulnessAction = MindfulnessActions(mindfulness: mindfulness, active: true, selectedFalconUsers: selectedFalconUsers)
                        mindfulnessAction.deleteMindfulness(updateDirectAssociation: false)
                    }
                }
            }
        }
        
        if updateExternal {
            if activity.isTask ?? false {
                let reference = Database.database().reference().child(userReminderTasksEntity).child(currentUserID).child(primaryReminderKey)
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
                let reference = Database.database().reference().child(userCalendarEventsEntity).child(currentUserID).child(primaryCalendarKey)
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
    }
    
    func createNewActivity(updateDirectAssociation: Bool) {
        guard currentReachabilityStatus != .notReachable else {
            return
        }
        
        guard let active = active, let activity = activity, let activityID = activityID, let _ = selectedFalconUsers, let currentUserID = Auth.auth().currentUser?.uid else {
            return
        }
        
        if !active {
            activity.admin = currentUserID
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
            if updateDirectAssociation, activity.directAssociation ?? false {
                editObject()
            }
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
                InvitationsFetcher.updateInvitations(forActivity: activity, selectedParticipants: selectedFalconUsers) {}
            }
        }
    }
    
    func updateActivity(firebaseDictionary: [String: AnyObject]) {
        guard let activity = activity, let activityID = activityID else {
            return
        }
        
        let groupActivityReference = Database.database().reference().child(activitiesEntity).child(activityID).child(messageMetaDataFirebaseFolder)
        groupActivityReference.updateChildValues(firebaseDictionary)
        
        guard let currentUserID = Auth.auth().currentUser?.uid else {
            return
        }
        
        
        if activity.isTask ?? false {
            let reference = Database.database().reference().child(userReminderTasksEntity).child(currentUserID).child(primaryReminderKey)
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
            let reference = Database.database().reference().child(userCalendarEventsEntity).child(currentUserID).child(primaryCalendarKey)
            reference.observeSingleEvent(of: .value, with: { (snapshot) in
                if snapshot.exists(), let value = snapshot.value as? String {
                    if value == CalendarSourceOptions.apple.name {
                        self.eventKitService.updateEvent(for: activity, span: .futureEvents)
                    } else if value == CalendarSourceOptions.google.name {
                        self.googleCalService.updateEvent(for: activity, span: .futureEvents)
                    }
                }
            })
        }
    }
    
    func editObject() {
        guard let _ = active, let activity = activity, let _ = activityID, let selectedFalconUsers = selectedFalconUsers else {
            return
        }
        
        if let ID = activity.directAssociationObjectID {
            if activity.directAssociationType == .workout {
                WorkoutFetcher.getDataFromSnapshot(ID: ID) { workouts in
                    if let workout = workouts.first, workout.user_created ?? false {
                        var newWorkout = workout
                        newWorkout.startDateTime = activity.startDate
                        newWorkout.endDateTime = activity.endDate
                        let length = Calendar.current.dateComponents([.second], from: newWorkout.startDateTime ?? Date(), to: newWorkout.endDateTime ?? Date()).second ?? 0
                        newWorkout.length = Double(length)
                        let workoutAction = WorkoutActions(workout: newWorkout, active: true, selectedFalconUsers: selectedFalconUsers)
                        workoutAction.createNewWorkout(updateDirectAssociation: false)
                    }
                }
            } else if activity.directAssociationType == .mindfulness {
                MindfulnessFetcher.getDataFromSnapshot(ID: ID) { mindfulnesses in
                    if let mindfulness = mindfulnesses.first, mindfulness.user_created ?? false {
                        var newMindfulness = mindfulness
                        newMindfulness.startDateTime = activity.startDate
                        newMindfulness.endDateTime = activity.endDate
                        let length = Calendar.current.dateComponents([.second], from: newMindfulness.startDateTime ?? Date(), to: newMindfulness.endDateTime ?? Date()).second ?? 0
                        newMindfulness.length = Double(length)
                        let mindfulnessAction = MindfulnessActions(mindfulness: newMindfulness, active: true, selectedFalconUsers: selectedFalconUsers)
                        mindfulnessAction.createNewMindfulness(updateDirectAssociation: false)
                    }
                }
            }
        }
    }
    
    func newActivity(firebaseDictionary: [String: AnyObject], membersIDs: ([String], [String:AnyObject])) {
        guard let currentUserID = Auth.auth().currentUser?.uid, let activity = activity, let activityID = activityID, let selectedFalconUsers = selectedFalconUsers else {
            return
        }
                                
        let groupActivityReference = Database.database().reference().child(activitiesEntity).child(activityID).child(messageMetaDataFirebaseFolder)
                
        self.dispatchGroup.enter()
        self.dispatchGroup.enter()
        
        createGroupActivityNode(reference: groupActivityReference, childValues: firebaseDictionary)
//        if let containerID = activity.containerID {
//            ContainerFunctions.updateParticipants(containerID: containerID, selectedFalconUsers: selectedFalconUsers)
//            self.dispatchGroup.leave()
//        } else {
//            connectMembersToGroupActivity(memberIDs: membersIDs.0, activityID: activityID)
//            self.dispatchGroup.notify(queue: DispatchQueue.main, execute: {
//                if !(activity.isTask ?? false) {
//                    InvitationsFetcher.updateInvitations(forActivity: activity, selectedParticipants: selectedFalconUsers) {}
//                }
//            })
//        }
        
        connectMembersToGroupActivity(memberIDs: membersIDs.0, activityID: activityID)
        self.dispatchGroup.notify(queue: DispatchQueue.main, execute: {
            if !(activity.isTask ?? false) {
                InvitationsFetcher.updateInvitations(forActivity: activity, selectedParticipants: selectedFalconUsers) {}
            }
        })
                
        if activity.isTask ?? false {
            if let source = activity.listSource, source == ListSourceOptions.plot.name, let listID = activity.listID {
                let listReference = Database.database().reference().child(listEntity).child(listID).child(listTasksEntity)
                listReference.child(activityID).setValue(true)
            }
            var reference = Database.database().reference().child(userReminderTasksEntity).child(currentUserID).child(primaryReminderKey)
            reference.observeSingleEvent(of: .value, with: { (snapshot) in
                if snapshot.exists(), let value = snapshot.value as? String {
                    if value == ListSourceOptions.apple.name, let reminder = self.eventKitService.storeReminder(for: activity) {
                        reference = Database.database().reference().child(userReminderTasksEntity).child(currentUserID).child(reminderTasksKey).child(reminder.calendarItemIdentifier)
                        let calendarEventActivityValue: [String : Any] = ["activityID": activityID as AnyObject]
                        reference.updateChildValues(calendarEventActivityValue)
                        let userReference = Database.database().reference().child(userActivitiesEntity).child(currentUserID).child(activityID).child(messageMetaDataFirebaseFolder)
                        let values:[String : Any] = ["calendarExport": true, "externalActivityID": reminder.calendarItemIdentifier as Any]
                        userReference.updateChildValues(values)
                    } else if value == ListSourceOptions.google.name {
                        self.googleCalService.storeTask(for: activity) { task in
                            if let task = task, let id = task.identifier {
                                reference = Database.database().reference().child(userCalendarEventsEntity).child(currentUserID).child(reminderTasksKey).child(id)
                                let calendarEventActivityValue: [String : Any] = ["activityID": activityID as AnyObject]
                                reference.updateChildValues(calendarEventActivityValue)
                                let userReference = Database.database().reference().child(userActivitiesEntity).child(currentUserID).child(activityID).child(messageMetaDataFirebaseFolder)
                                let values:[String : Any] = ["calendarExport": true, "externalActivityID": task.identifier as Any]
                                userReference.updateChildValues(values)
                            }
                        }
                    }
                }
            })
        } else {
            var reference = Database.database().reference().child(userCalendarEventsEntity).child(currentUserID).child(primaryCalendarKey)
            reference.observeSingleEvent(of: .value, with: { (snapshot) in
                if snapshot.exists(), let value = snapshot.value as? String {
                    if value == CalendarSourceOptions.apple.name, let event = self.eventKitService.storeEvent(for: activity) {
                        reference = Database.database().reference().child(userCalendarEventsEntity).child(currentUserID).child(calendarEventsKey).child(event.calendarItemExternalIdentifierClean.removeCharacters())
                        let calendarEventActivityValue: [String : Any] = ["activityID": activityID as AnyObject]
                        reference.updateChildValues(calendarEventActivityValue)
                        let userReference = Database.database().reference().child(userActivitiesEntity).child(currentUserID).child(activityID).child(messageMetaDataFirebaseFolder)
                        let values:[String : Any] = ["calendarExport": true, "externalActivityID": event.calendarItemExternalIdentifierClean.removeCharacters() as Any]
                        userReference.updateChildValues(values)
                    } else if value == CalendarSourceOptions.google.name {
                        self.googleCalService.storeEvent(for: activity) { event in
                            if let event = event, let id = event.identifierClean {
                                reference = Database.database().reference().child(userCalendarEventsEntity).child(currentUserID).child(calendarEventsKey).child(id)
                                let calendarEventActivityValue: [String : Any] = ["activityID": activityID as AnyObject]
                                reference.updateChildValues(calendarEventActivityValue)
                                let userReference = Database.database().reference().child(userActivitiesEntity).child(currentUserID).child(activityID).child(messageMetaDataFirebaseFolder)
                                let values:[String : Any] = ["calendarExport": true, "externalActivityID": id as Any]
                                userReference.updateChildValues(values)
                            }
                        }
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
        let groupActivityReference = Database.database().reference().child(activitiesEntity).child(activityID).child(messageMetaDataFirebaseFolder)
        groupActivityReference.child("recurrences").removeValue()
        groupActivityReference.child("instanceIDs").removeValue()
        
        let membersIDs = fetchMembersIDs()
        
        for memberID in membersIDs.0 {
            Database.database().reference().child(userActivitiesEntity).child(memberID).child(activityID).child(messageMetaDataFirebaseFolder).child("badgeDate").removeValue()
        }
    }
    
    func updateCompletion(isComplete: Bool, completeUpdatedByUser: Bool?, goalCurrentNumber: NSNumber?, goalCurrentNumberSecond: NSNumber?) {
        guard let activity = activity, let activityID = activityID, let _ = selectedFalconUsers else {
            return
        }
        if activity.recurrences != nil || activity.instanceID != nil {
            var values:[String : Any] = [:]
            activity.isCompleted = isComplete
            if isComplete {
                var finalCompletedDate = NSNumber()
                if let completedDate = activity.completedDate {
                    finalCompletedDate = completedDate
                } else {
                    let original = Date()
                    let updateDate = Date(timeIntervalSinceReferenceDate:
                                        (original.timeIntervalSinceReferenceDate / 300.0).rounded(.toNearestOrEven) * 300.0)
                    finalCompletedDate = NSNumber(value: Int((updateDate).timeIntervalSince1970))
                }
                values = ["isCompleted": isComplete, "completedDate": finalCompletedDate as Any, "completeUpdatedByUser": completeUpdatedByUser as Any, "goalCurrentNumber": goalCurrentNumber as Any, "goalCurrentNumberSecond": goalCurrentNumberSecond as Any]
                updateInstance(instanceValues: values, updateExternal: true)
            } else {
                values = ["isCompleted": isComplete, "completedDate": NSNull() as Any, "completeUpdatedByUser": completeUpdatedByUser as Any, "goalCurrentNumber": goalCurrentNumber as Any, "goalCurrentNumberSecond": goalCurrentNumberSecond as Any]
                updateInstance(instanceValues: values, updateExternal: true)
            }
        } else if let currentUserID = Auth.auth().currentUser?.uid {
            let groupActivityReference = Database.database().reference().child(activitiesEntity).child(activityID).child(messageMetaDataFirebaseFolder)
            activity.isCompleted = isComplete
            if isComplete {
                var finalCompletedDate = NSNumber()
                if let completedDate = activity.completedDate {
                    finalCompletedDate = completedDate
                } else {
                    let original = Date()
                    let updateDate = Date(timeIntervalSinceReferenceDate:
                                        (original.timeIntervalSinceReferenceDate / 300.0).rounded(.toNearestOrEven) * 300.0)
                    finalCompletedDate = NSNumber(value: Int((updateDate).timeIntervalSince1970))
                }
                let values:[String : Any] = ["isCompleted": isComplete, "completedDate": finalCompletedDate as Any, "completeUpdatedByUser": completeUpdatedByUser as Any, "goalCurrentNumber": goalCurrentNumber as Any, "goalCurrentNumberSecond": goalCurrentNumberSecond as Any]
                groupActivityReference.updateChildValues(values)
            } else {
                let values:[String : Any] = ["isCompleted": isComplete, "completedDate": NSNull() as Any, "completeUpdatedByUser": completeUpdatedByUser as Any, "goalCurrentNumber": goalCurrentNumber as Any, "goalCurrentNumberSecond": goalCurrentNumberSecond as Any]
                groupActivityReference.updateChildValues(values)
            }
            incrementBadgeForReciever(activityID: activityID, participantsIDs: activity.participantsIDs ?? [])
            
            let reference = Database.database().reference().child(userReminderTasksEntity).child(currentUserID).child(primaryReminderKey)
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
    }
    
    func updateInstance(instanceValues: [String : Any], updateExternal: Bool) {
        guard let activity = activity, let activityID = activityID, let _ = selectedFalconUsers, let currentUserID = Auth.auth().currentUser?.uid else {
            return
        }
        
        var instanceID = Database.database().reference().child(userActivitiesEntity).child(currentUserID).childByAutoId().key ?? ""
        var instanceIDs = activity.instanceIDs ?? []
        if let instance = activity.instanceID {
            instanceID = instance
        } else {
            instanceIDs.append(instanceID)
        }
                
        var updateInstanceValues = instanceValues
        updateInstanceValues["instanceID"] = instanceID
        
        if activity.instanceOriginalStartDateTime == nil {
            updateInstanceValues["instanceOriginalStartDateTime"] = activity.finalDateTime
        }
        
        if activity.isTask ?? false {
            updateInstanceValues["isTask"] = true
        } else {
            updateInstanceValues["isEvent"] = true
        }
        if activity.isSubtask ?? false || activity.isSchedule ?? false {
            updateInstanceValues["parentID"] = activity.parentID
        }
        updateInstanceValues["recurringEventID"] = activityID
                        
        let groupInstanceActivityReference = Database.database().reference().child(activitiesEntity).child(instanceID).child(messageMetaDataFirebaseFolder)
        groupInstanceActivityReference.updateChildValues(updateInstanceValues) { _,_ in
            let groupRecurringActivityReference = Database.database().reference().child(activitiesEntity).child(activityID).child(messageMetaDataFirebaseFolder)
            let recurringValues: [String : Any] = ["instanceIDs": instanceIDs as Any]
            groupRecurringActivityReference.updateChildValues(recurringValues)
            self.incrementBadgeForReciever(activityID: activityID, participantsIDs: activity.participantsIDs ?? [])
            
            if updateExternal {
                if activity.isTask ?? false {
                    let reference = Database.database().reference().child(userReminderTasksEntity).child(currentUserID).child(primaryReminderKey)
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
                    let reference = Database.database().reference().child(userCalendarEventsEntity).child(currentUserID).child(primaryCalendarKey)
                    reference.observeSingleEvent(of: .value, with: { (snapshot) in
                        if snapshot.exists(), let value = snapshot.value as? String {
                            if value == CalendarSourceOptions.apple.name {
                                self.eventKitService.updateEvent(for: activity, span: .thisEvent)
                            } else if value == CalendarSourceOptions.google.name {
                                self.googleCalService.updateEvent(for: activity, span: .thisEvent)
                            }
                        }
                    })
                }
            }
        }
    }
    
    func fetchMembersIDs() -> ([String], [String:AnyObject]) {
        var membersIDs = [String]()
        var membersIDsDictionary = [String:AnyObject]()
        
        guard let _ = activity, let selectedFalconUsers = selectedFalconUsers, let currentUserID = Auth.auth().currentUser?.uid else {
            return (membersIDs.sorted(), membersIDsDictionary)
        }
                
        membersIDsDictionary.updateValue(currentUserID as AnyObject, forKey: currentUserID)
        membersIDs.append(currentUserID)
        
        for selectedUser in selectedFalconUsers {
            guard let id = selectedUser.id else { continue }
            membersIDsDictionary.updateValue(id as AnyObject, forKey: id)
            membersIDs.append(id)
        }
        
        return (membersIDs.sorted(), membersIDsDictionary)
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
                if memberID == currentUserID, let calendarID = activity.calendarID, !calendarID.isEmpty {
                    let userReference = Database.database().reference().child(userActivitiesEntity).child(memberID).child(activityID).child(messageMetaDataFirebaseFolder)
                    let values: [String : Any] = ["isGroupActivity": true,
                                                  "badge": 0,
                                                  "calendarID": calendarID as Any,
                                                  "calendarName": activity.calendarName as Any,
                                                  "calendarSource": activity.calendarSource as Any,
                                                  "calendarColor": activity.calendarColor as Any,
                                                  "showExtras": activity.showExtras as Any]
                    userReference.updateChildValues(values, withCompletionBlock: { (error, reference) in
                        if let source = activity.calendarSource, source == CalendarSourceOptions.plot.name {
                            let calendarReference = Database.database().reference().child(calendarEntity).child(calendarID).child(calendarEventsEntity)
                            calendarReference.child(activityID).setValue(true)
                        }
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
                                if let source = calendar.source, source == CalendarSourceOptions.plot.name {
                                    let calendarReference = Database.database().reference().child(calendarEntity).child(calendar.id ?? "").child(calendarEventsEntity)
                                    calendarReference.child(activityID).setValue(true)
                                }
                                connectingMembersGroup.leave()
                            })
                        } else {
                            connectingMembersGroup.leave()
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
        guard let activity = activity else {
            return
        }
        var ref = Database.database().reference().child(userActivitiesEntity).child(firstChild).child(secondChild)
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            if activity.recurrences != nil {
                ref = ref.child(messageMetaDataFirebaseFolder).child("badgeDate")
                ref.runTransactionBlock({ (mutableData) -> TransactionResult in
                    var value = mutableData.value as? [String: Int]
                    if value == nil, let finalDateTime = activity.finalDateTime {
                        value = [String(describing: Int(truncating: finalDateTime)): 1]
                    } else if let finalDateTime = activity.finalDateTime {
                        let stringFinalDateTime = String(describing: Int(truncating: finalDateTime))
                        if let badge = value![stringFinalDateTime] {
                            value![stringFinalDateTime] = badge + 1
                        } else {
                            value![stringFinalDateTime] = 1
                        }
                    }
                    mutableData.value = value
                    return TransactionResult.success(withValue: mutableData)
                })
            } else {
                ref = ref.child(messageMetaDataFirebaseFolder).child("badge")
                ref.runTransactionBlock({ (mutableData) -> TransactionResult in
                    let value = mutableData.value as? Int
                    mutableData.value = (value ?? 0) + 1
                    return TransactionResult.success(withValue: mutableData)
                })
            }
        })
    }
}
