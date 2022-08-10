//
//  GCalendarActivityOp.swift
//  Plot
//
//  Created by Cory McHattie on 2/3/21.
//  Copyright © 2021 Immature Creations. All rights reserved.
//

import Foundation
import Firebase
import CodableFirebase

class GCalendarActivityOp: AsyncOperation {
    private var calendar: GTLRCalendar_CalendarListEntry
    private var event: GTLRCalendar_Event
    
    init(calendar: GTLRCalendar_CalendarListEntry,event: GTLRCalendar_Event) {
        self.calendar = calendar
        self.event = event
    }
    
    override func main() {
        startRequest()
    }
    
    private func startRequest() {
        guard let currentUserId = Auth.auth().currentUser?.uid, let id = event.identifier else {
            self.finish()
            return
        }
        let reference = Database.database().reference().child(userCalendarEventsEntity).child(currentUserId).child(calendarEventsKey).child(id)
        reference.observeSingleEvent(of: .value, with: { [weak self] (snapshot) in
            if snapshot.exists(), let value = snapshot.value as? [String : String], let activityID = value["activityID"] {
                let activityDataReference = Database.database().reference().child(activitiesEntity).child(activityID)
                activityDataReference.observeSingleEvent(of: .value, with: { [weak self] (snapshot) in
                    guard snapshot.exists(), let activitySnapshotValue = snapshot.value, let activity = try? FirebaseDecoder().decode(Activity.self, from: activitySnapshotValue) else {
                        self?.finish()
                        return
                    }
                    self?.update(activity: activity, completion: { activity in
                        let activityReference = Database.database().reference().child(activitiesEntity).child(activityID).child(messageMetaDataFirebaseFolder)
                        activityReference.updateChildValues(activity.toAnyObject(), withCompletionBlock: { [weak self] (error, reference) in
                            let userActivityReference = Database.database().reference().child(userActivitiesEntity).child(currentUserId).child(activityID).child(messageMetaDataFirebaseFolder)
                            var values: [String : Any] = ["calendarExport": true,
                                                          "calendarSource": CalendarOptions.google.name as Any,
                                                          "showExtras": activity.showExtras as Any]
                            if let value = self?.calendar.identifier {
                                values["calendarID"] = value as Any
                            }
                            if let value = self?.calendar.summary {
                                values["calendarName"] = value as Any
                            }
                            if let value = self?.calendar.backgroundColor {
                                values["calendarColor"] = CIColor(color: UIColor(value)).stringRepresentation as Any
                            }
                            userActivityReference.updateChildValues(values, withCompletionBlock: { [weak self] (error, reference) in
                                self?.finish()
                            })
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
                    weakSelf.createActivity(for: activityID) { activity in
                        let activityReference = Database.database().reference().child(activitiesEntity).child(activityID).child(messageMetaDataFirebaseFolder)
                        activityReference.updateChildValues(activity.toAnyObject(), withCompletionBlock: { [weak self] (error, reference) in
                            let userActivityReference = Database.database().reference().child(userActivitiesEntity).child(currentUserId).child(activityID).child(messageMetaDataFirebaseFolder)
                            var values: [String : Any] = ["isGroupActivity": false,
                                                          "badge": 0,
                                                          "calendarExport": true,
                                                          "calendarSource": CalendarOptions.google.name as Any,
                                                          "showExtras": activity.showExtras as Any]
                            if let value = self?.calendar.identifier {
                                values["calendarID"] = value as Any
                            }
                            if let value = self?.calendar.summary {
                                values["calendarName"] = value as Any
                            }
                            if let value = self?.calendar.backgroundColor {
                                values["calendarColor"] = CIColor(color: UIColor(value)).stringRepresentation as Any
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
            activity.category = ActivityCategory.categorize(activity).rawValue
            activity.activityType = CustomType.googleCalendarEvent.categoryText
            completion(activity)
        }
    }
    
    private func update(activity: Activity, completion: @escaping (Activity) -> Void) {        
        activity.name = event.summary
        activity.activityDescription = event.descriptionProperty
        activity.recurrences = event.recurrence
        activity.admin = Auth.auth().currentUser?.uid
        if let start = event.start?.date, let end = event.end?.date {
            activity.allDay = true
            activity.startDateTime = NSNumber(value: start.date.timeIntervalSince1970)
            activity.startTimeZone = event.start?.timeZone ?? TimeZone.current.identifier
            activity.endDateTime = NSNumber(value: end.date.addingTimeInterval(-86400).timeIntervalSince1970)
            activity.endTimeZone = event.end?.timeZone ?? TimeZone.current.identifier
        } else if let start = event.start?.dateTime, let end = event.end?.dateTime {
            activity.allDay = false
            activity.startDateTime = NSNumber(value: start.date.timeIntervalSince1970)
            activity.startTimeZone = event.start?.timeZone ?? TimeZone.current.identifier
            activity.endDateTime = NSNumber(value: end.date.timeIntervalSince1970)
            activity.endTimeZone = event.end?.timeZone ?? TimeZone.current.identifier
        }
        if let location = event.location {
            lookupLocation(for: location) { coordinates in
                if let coordinates = coordinates {
                    let latitude = coordinates.latitude
                    let longitude = coordinates.longitude
                    activity.locationName = location.removeCharacters()
                    activity.locationAddress = [location.removeCharacters(): [latitude, longitude]]
                    completion(activity)
                } else {
                    completion(activity)
                }
            }
        }
    }
    
    private func deleteActivity() {
        guard let currentUserId = Auth.auth().currentUser?.uid, let id = event.identifier else {
            self.finish()
            return
        }
        
        let reference = Database.database().reference().child(userCalendarEventsEntity).child(currentUserId).child(calendarEventsKey).child(id)
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
