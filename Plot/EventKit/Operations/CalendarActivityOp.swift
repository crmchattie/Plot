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

let ekEventIDKey = "ekEventID"

class CalendarActivityOp: AsyncOperation {
    private var event: EKEvent
    
    init(event: EKEvent) {
        self.event = event
    }
    
    override func main() {
        startRequest()
        //deleteActivity()
    }
    
    private func startRequest() {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            self.finish()
            return
        }
        
        let reference = Database.database().reference().child(userCalendarEventsEntity).child(currentUserId).child(calendarEventsKey).child(event.calendarItemIdentifier)
        reference.observeSingleEvent(of: .value, with: { [weak self] (snapshot) in
            if snapshot.exists(), let value = snapshot.value as? [String : String], let activityID = value["activityID"] {
                let activityDataReference = Database.database().reference().child(activitiesEntity).child(activityID)
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
                
                        let values: [String : Any] = ["isGroupActivity": false, "badge": 0]
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
        activity.category = ActivityCategorySelector.selectCategory(for: activity)
        return activity
    }
    
    private func update(activity: Activity) {
        activity.activityType = CustomType.iOSCalendarEvent.categoryText
        activity.name = event.title
        activity.notes = event.notes
        activity.locationName = event.location
        activity.allDay = event.isAllDay
        let timezone = event.timeZone
        let seconds = TimeInterval(timezone?.secondsFromGMT(for: Date()) ?? 0)
        let startDateTime = event.startDate.addingTimeInterval(seconds)
        let endDateTime = event.endDate.addingTimeInterval(seconds)
        if event.isAllDay, let endDateTime = Calendar.current.date(byAdding: .day, value: -1, to: endDateTime.startOfDay) {
            activity.startDateTime = NSNumber(value: startDateTime.startOfDay.timeIntervalSince1970)
            activity.endDateTime = NSNumber(value: endDateTime.timeIntervalSince1970)
        } else {
            activity.startDateTime = NSNumber(value: startDateTime.timeIntervalSince1970)
            activity.endDateTime = NSNumber(value: endDateTime.timeIntervalSince1970)
        }
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
