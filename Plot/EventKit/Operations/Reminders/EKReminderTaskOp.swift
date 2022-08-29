//
//  CalendarActivityOp.swift
//  Plot
//
//  Created by Hafiz Usama on 2020-11-24.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import EventKit
import Firebase
import CodableFirebase

class EKReminderTaskOp: AsyncOperation {
    private var reminder: EKReminder
    
    init(reminder: EKReminder) {
        self.reminder = reminder
    }
    
    override func main() {
        startRequest()
    }
    
    private func startRequest() {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            self.finish()
            return
        }
        let reference = Database.database().reference().child(userReminderTasksEntity).child(currentUserId).child(reminderTasksKey).child(reminder.calendarItemIdentifier)
        reference.observeSingleEvent(of: .value, with: { [weak self] (snapshot) in
            if snapshot.exists(), let value = snapshot.value as? [String : String], let activityID = value["activityID"] {
                let activityDataReference = Database.database().reference().child(activitiesEntity).child(activityID).child(messageMetaDataFirebaseFolder)
                activityDataReference.observeSingleEvent(of: .value, with: { [weak self] (snapshot) in
                    guard snapshot.exists(), let activitySnapshotValue = snapshot.value, let activity = try? FirebaseDecoder().decode(Activity.self, from: activitySnapshotValue) else {
                        self?.finish()
                        return
                    }
                    self?.update(activity: activity)
                    let activityReference = Database.database().reference().child(activitiesEntity).child(activityID).child(messageMetaDataFirebaseFolder)
                    activityReference.updateChildValues(activity.toAnyObject(), withCompletionBlock: { [weak self] (error, reference) in
                        let userActivityReference = Database.database().reference().child(userActivitiesEntity).child(currentUserId).child(activityID).child(messageMetaDataFirebaseFolder)
                        var values: [String : Any] = ["listExport": true,
                                                      "listID": self?.reminder.calendar.calendarIdentifier as Any,
                                                      "listName": self?.reminder.calendar.title as Any,
                                                      "listSource": CalendarSourceOptions.apple.name as Any,
                                                      "externalActivityID": self?.reminder.calendarItemIdentifier as Any]
                        if let CGColor = self?.reminder.calendar.cgColor {
                            values["listColor"] = CIColor(cgColor: CGColor).stringRepresentation as Any
                        }
                        userActivityReference.updateChildValues(values, withCompletionBlock: { [weak self] (error, reference) in
                            self?.finish()
                        })
                    })
                })
            }
            else if !snapshot.exists() {
                guard let activityID = Database.database().reference().child(userActivitiesEntity).child(currentUserId).childByAutoId().key, let weakSelf = self else {
                    self?.finish()
                    return
                }
                let calendarEventActivityValue: [String : Any] = ["activityID": activityID as AnyObject]
                reference.updateChildValues(calendarEventActivityValue) { (_, _) in
                    let activity = weakSelf.createActivity(for: activityID)
                    let activityReference = Database.database().reference().child(activitiesEntity).child(activityID).child(messageMetaDataFirebaseFolder)
                    activityReference.updateChildValues(activity.toAnyObject(), withCompletionBlock: { [weak self] (error, reference) in
                        let userActivityReference = Database.database().reference().child(userActivitiesEntity).child(currentUserId).child(activityID).child(messageMetaDataFirebaseFolder)
                        var values: [String : Any] = ["isGroupActivity": false,
                                                      "badge": 0,
                                                      "calendarExport": true,
                                                      "listID": self?.reminder.calendar.calendarIdentifier as Any,
                                                      "listName": self?.reminder.calendar.title as Any,
                                                      "listSource": CalendarSourceOptions.apple.name as Any,
                                                      "externalActivityID": self?.reminder.calendarItemIdentifier as Any,
                                                      "showExtras": activity.showExtras as Any]
                        if let CGColor = self?.reminder.calendar.cgColor {
                            values["listColor"] = CIColor(cgColor: CGColor).stringRepresentation as Any
                        }
                        userActivityReference.updateChildValues(values, withCompletionBlock: { [weak self] (error, reference) in
                            self?.finish()
                        })
                    })
                }
            }
            else {
                self?.finish()
            }
        })
    }
    
    private func createActivity(for activityID: String) -> Activity {
        let activity = Activity(dictionary: ["activityID": activityID as AnyObject])
        update(activity: activity)
        return activity
    }
    
    private func update(activity: Activity) {
        activity.isTask = true
        activity.name = reminder.title
        activity.activityDescription = reminder.notes
        activity.category = ActivityCategory.categorize(activity).rawValue
        activity.activityType = CustomType.iOSCalendarEvent.categoryText
        activity.startTimeZone = reminder.timeZone?.identifier
        activity.endTimeZone = reminder.timeZone?.identifier
        activity.recurrences = reminder.recurrenceRules?.map { $0.iCalRuleString() }
        if let startDate = reminder.startDateComponents?.date {
            activity.startDateTime = NSNumber(value: startDate.timeIntervalSince1970)
            if reminder.startDateComponents?.hour != nil {
                activity.hasStartTime = true
            } else {
                activity.hasStartTime = false
            }
        }
        if let endDate = reminder.dueDateComponents?.date {
            activity.endDateTime = NSNumber(value: endDate.timeIntervalSince1970)
            if reminder.dueDateComponents?.hour != nil {
                activity.hasDeadlineTime = true
            } else {
                activity.hasDeadlineTime = false
            }
        }
        activity.isCompleted = reminder.isCompleted
        if let completionDate = reminder.completionDate {
            activity.completedDate = NSNumber(value: completionDate.timeIntervalSince1970)
        }
        activity.admin = Auth.auth().currentUser?.uid
    }
    
    private func deleteActivity() {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            self.finish()
            return
        }
        
        let reference = Database.database().reference().child(userReminderTasksEntity).child(currentUserId).child(reminderTasksKey).child(reminder.calendarItemIdentifier)
        reference.observeSingleEvent(of: .value, with: { [weak self] (snapshot) in
            guard snapshot.exists(), let value = snapshot.value as? [String : String], let activityID = value["activityID"] else {
                self?.finish()
                return
            }
            
            let activityReference = Database.database().reference().child(activitiesEntity).child(activityID)
            let userActivityReference = Database.database().reference().child(userActivitiesEntity).child(currentUserId).child(activityID)
            activityReference.removeValue { (_, _) in
                userActivityReference.removeValue { (_, _) in
                    reference.removeValue { (_, _) in
                        self?.finish()
                    }
                }
            }
        })
    }
}
