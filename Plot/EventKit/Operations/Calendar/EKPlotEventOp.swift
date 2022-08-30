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
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            self.finish()
            return
        }
        // @FIX-ME remove in four months from 2/6/21 since we can check for calendar export property on activities
        let reference = Database.database().reference().child(userCalendarEventsEntity).child(currentUserId).child(calendarEventsKey)
        let dispatchGroup = DispatchGroup()
        for activity in activities {
            if let activityID = activity.activityID {
                dispatchGroup.enter()
                if let event = eventKitService.storeEvent(for: activity) {
                    let calendarEventActivityValue: [String : Any] = ["activityID": activityID as AnyObject]
                    reference.child(event.calendarItemIdentifier).updateChildValues(calendarEventActivityValue) { (_, _) in
                        let userReference = Database.database().reference().child(userActivitiesEntity).child(currentUserId).child(activityID).child(messageMetaDataFirebaseFolder)
                        let values:[String : Any] = ["calendarExport": true, "externalActivityID": event.calendarItemIdentifier as Any]
                        userReference.updateChildValues(values)
                        dispatchGroup.leave()
                    }
                } else {
                    dispatchGroup.leave()
                }
            }
        }
        dispatchGroup.notify(queue: .global()) {
            self.finish()
        }
    }    
}
