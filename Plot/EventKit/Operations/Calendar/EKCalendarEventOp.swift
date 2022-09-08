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

class EKCalendarEventOp: AsyncOperation {
    private var event: EKEvent
    
    init(event: EKEvent) {
        self.event = event
    }
    
    override func main() {
        startRequest()
    }
    
    private func startRequest() {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            self.finish()
            return
        }
        let reference = Database.database().reference().child(userCalendarEventsEntity).child(currentUserId).child(calendarEventsKey).child(event.calendarItemIdentifier)
        reference.observeSingleEvent(of: .value, with: { [weak self] (snapshot) in
            if snapshot.exists(), let value = snapshot.value as? [String : String], let activityID = value["activityID"] {
                let activityDataReference = Database.database().reference().child(activitiesEntity).child(activityID).child(messageMetaDataFirebaseFolder)
                activityDataReference.observeSingleEvent(of: .value, with: { [weak self] (snapshot) in
                    guard snapshot.exists(), let activitySnapshotValue = snapshot.value, let activity = try? FirebaseDecoder().decode(Activity.self, from: activitySnapshotValue) else {
                        self?.finish()
                        return
                    }
                    self?.update(activity: activity) { activity in
                        let activityReference = Database.database().reference().child(activitiesEntity).child(activityID).child(messageMetaDataFirebaseFolder)
                        activityReference.updateChildValues(activity.toAnyObject(), withCompletionBlock: { [weak self] (error, reference) in
                            let userActivityReference = Database.database().reference().child(userActivitiesEntity).child(currentUserId).child(activityID).child(messageMetaDataFirebaseFolder)
                            var values: [String : Any] = ["calendarExport": true,
                                                          "calendarID": self?.event.calendar.calendarIdentifier as Any,
                                                          "calendarName": self?.event.calendar.title as Any,
                                                          "calendarSource": CalendarSourceOptions.apple.name as Any,
                                                          "externalActivityID": self?.event.calendarItemIdentifier as Any]
                            if let CGColor = self?.event.calendar.cgColor {
                                values["calendarColor"] = CIColor(cgColor: CGColor).stringRepresentation as Any
                            }
                            userActivityReference.updateChildValues(values, withCompletionBlock: { [weak self] (error, reference) in
                                self?.finish()
                            })
                        })
                    }
                })
            }
            else if !snapshot.exists() {
                guard let activityID = Database.database().reference().child(userActivitiesEntity).child(currentUserId).childByAutoId().key, let weakSelf = self else {
                    self?.finish()
                    return
                }
                let calendarEventActivityValue: [String : Any] = ["activityID": activityID as AnyObject]
                reference.updateChildValues(calendarEventActivityValue) { (_, _) in
                    weakSelf.createActivity(for: activityID) { activity in
                        let activityReference = Database.database().reference().child(activitiesEntity).child(activityID).child(messageMetaDataFirebaseFolder)
                        activityReference.updateChildValues(activity.toAnyObject(), withCompletionBlock: { [weak self] (error, reference) in
                            let userActivityReference = Database.database().reference().child(userActivitiesEntity).child(currentUserId).child(activityID).child(messageMetaDataFirebaseFolder)
                            var values: [String : Any] = ["isGroupActivity": false,
                                                          "badge": 0,
                                                          "calendarExport": true,
                                                          "calendarID": self?.event.calendar.calendarIdentifier as Any,
                                                          "calendarName": self?.event.calendar.title as Any,
                                                          "calendarSource": CalendarSourceOptions.apple.name as Any,
                                                          "externalActivityID": self?.event.calendarItemIdentifier as Any,
                                                          "showExtras": activity.showExtras as Any]
                            if let CGColor = self?.event.calendar.cgColor {
                                values["calendarColor"] = CIColor(cgColor: CGColor).stringRepresentation as Any
                            }
                            userActivityReference.updateChildValues(values, withCompletionBlock: { [weak self] (error, reference) in
                                self?.finish()
                            })
                        })
                    }
                }
            }
            else {
                self?.finish()
            }
        })
    }
    
    private func createActivity(for activityID: String, completion: @escaping (Activity) -> Void) {
        let activity = Activity(dictionary: ["activityID": activityID as AnyObject])
        update(activity: activity) { activity in
            activity.activityType = CustomType.iOSCalendarEvent.categoryText
            activity.category = ActivityCategory.categorize(activity).rawValue
            completion(activity)
        }
    }
    
    private func update(activity: Activity, completion: @escaping (Activity) -> Void) {
        activity.isEvent = true
        activity.name = event.title
        activity.activityDescription = event.notes
        if let structuredLocation = event.structuredLocation, let geoLocation = structuredLocation.geoLocation, let location = event.location {
            let coordinates = geoLocation.coordinate
            let latitude = coordinates.latitude
            let longitude = coordinates.longitude
            activity.locationName = location.removeCharacters()
            activity.locationAddress = [location.removeCharacters(): [latitude, longitude]]
        } else {
            activity.locationName = nil
            activity.locationAddress = nil
        }
        activity.allDay = event.isAllDay
        activity.startTimeZone = event.timeZone?.identifier
        activity.endTimeZone = event.timeZone?.identifier
        activity.recurrences = event.recurrenceRules?.map { $0.iCalRuleString() }
        activity.startDateTime = NSNumber(value: event.startDate.timeIntervalSince1970)
        activity.endDateTime = NSNumber(value: event.endDate.timeIntervalSince1970)
        activity.admin = Auth.auth().currentUser?.uid
        completion(activity)
        
    }
    
    private func deleteActivity() {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            self.finish()
            return
        }
        
        let reference = Database.database().reference().child(userCalendarEventsEntity).child(currentUserId).child(calendarEventsKey).child(event.calendarItemIdentifier)
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
