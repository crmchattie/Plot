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
    private var event: GTLRCalendar_Event
    
    init(event: GTLRCalendar_Event) {
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
        activity.activityType = CustomType.iOSCalendarEvent.categoryText
        return activity
    }
    
    private func update(activity: Activity) {
        activity.name = event.summary
        activity.activityDescription = event.description
        activity.locationName = event.location
        if let start = event.start?.date, let end = event.end?.date {
            activity.allDay = true
            activity.startDateTime = NSNumber(value: start.date.timeIntervalSince1970)
            activity.startTimeZone = event.start?.timeZone
            activity.endDateTime = NSNumber(value: end.date.timeIntervalSince1970)
            activity.endTimeZone = event.end?.timeZone
        } else if let start = event.start?.dateTime, let end = event.end?.dateTime {
            activity.allDay = false
            activity.startDateTime = NSNumber(value: start.date.timeIntervalSince1970)
            activity.startTimeZone = event.start?.timeZone
            activity.endDateTime = NSNumber(value: end.date.timeIntervalSince1970)
            activity.endTimeZone = event.end?.timeZone
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
