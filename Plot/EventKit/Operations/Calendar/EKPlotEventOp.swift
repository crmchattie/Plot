//
//  SyncPlotActivitiesOp.swift
//  Plot
//
//  Created by Cory McHattie on 1/25/21.
//  Copyright © 2021 Immature Creations. All rights reserved.
//

import EventKit
import Firebase
import CodableFirebase

class EKPlotEventOp: AsyncOperation {
    private let eventKitService: EventKitService
    private var activities: [Activity]
    
    init(eventKitService: EventKitService, activities: [Activity]) {
        self.eventKitService = eventKitService
        self.activities = activities
    }
    
    override func main() {
        startRequest()
    }
    
    private func startRequest() {
        guard let currentUserID = Auth.auth().currentUser?.uid else {
            self.finish()
            return
        }
        let reference = Database.database().reference().child(userCalendarEventsEntity).child(currentUserID).child(calendarEventsKey)
        let dispatchGroup = DispatchGroup()
        for activity in activities {
            if let activityID = activity.activityID {
                dispatchGroup.enter()
                if let _ = activity.externalActivityID {
                    eventKitService.updateEvent(for: activity, span: .futureEvents)
                    dispatchGroup.leave()
                } else if let event = eventKitService.storeEvent(for: activity) {
                    let calendarEventActivityValue: [String : Any] = ["activityID": activityID as AnyObject]
                    reference.child(event.calendarItemExternalIdentifierClean.removeCharacters()).updateChildValues(calendarEventActivityValue) { (_, _) in
                        let userReference = Database.database().reference().child(userActivitiesEntity).child(currentUserID).child(activityID).child(messageMetaDataFirebaseFolder)
                        let values:[String : Any] = ["externalActivityID": event.calendarItemExternalIdentifierClean.removeCharacters() as Any]
                        userReference.updateChildValues(values)
                        dispatchGroup.leave()
                    }
                } else {
                    dispatchGroup.leave()
                }
            }
        }
        dispatchGroup.notify(queue: .main) {
            self.finish()
        }
    }    
}
