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

class EKCalendarActivityOp: AsyncOperation {
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
                    self?.update(activity: activity)
                    let activityReference = Database.database().reference().child(activitiesEntity).child(activityID).child(messageMetaDataFirebaseFolder)
                    activityReference.updateChildValues(activity.toAnyObject(), withCompletionBlock: { [weak self] (error, reference) in
                        self?.finish()
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
                        let values: [String : Any] = ["isGroupActivity": false, "badge": 0, "calendarExport": true]
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
        activity.name = event.title
        activity.activityDescription = event.notes
        if let structuredLocation = event.structuredLocation, let geoLocation = structuredLocation.geoLocation, let location = event.location {
            let coordinates = geoLocation.coordinate
            let latitude = coordinates.latitude
            let longitude = coordinates.longitude
            activity.locationName = location.removeCharacters()
            activity.locationAddress = [location.removeCharacters(): [latitude, longitude]]
        }
        activity.category = ActivityCategory.categorize(activity).rawValue
        activity.activityType = CustomType.iOSCalendarEvent.categoryText
        activity.allDay = event.isAllDay
        activity.startTimeZone = event.timeZone?.identifier
        activity.endTimeZone = event.timeZone?.identifier
        activity.recurrences = event.recurrenceRules?.map { $0.iCalRuleString() }
        activity.startDateTime = NSNumber(value: event.startDate.timeIntervalSince1970)
        activity.endDateTime = NSNumber(value: event.endDate.timeIntervalSince1970)
        activity.calendarID = event.calendar.calendarIdentifier
        activity.calendarName = event.calendar.title
        activity.calendarColor = CIColor(cgColor: event.calendar.cgColor).stringRepresentation
        activity.calendarSource = CalendarOptions.apple.name
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
