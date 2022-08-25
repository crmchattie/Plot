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

class EKPlotTaskOp: AsyncOperation {
    private let eventKitService: EventKitService
    private var tasks: [Activity]
    
    init(eventKitService: EventKitService, tasks: [Activity]) {
        self.eventKitService = eventKitService
        self.tasks = tasks
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
        for task in tasks {
            if let activityID = task.activityID, !(task.calendarExport ?? false) {
                dispatchGroup.enter()
                if let reminder = eventKitService.storeReminder(for: task) {
                    let reminderTaskActivityValue: [String : Any] = ["activityID": activityID as AnyObject]
                    reference.child(reminder.calendarItemIdentifier).updateChildValues(reminderTaskActivityValue) { (_, _) in
                        let userReference = Database.database().reference().child(userActivitiesEntity).child(currentUserId).child(activityID).child(messageMetaDataFirebaseFolder)
                        let values:[String : Any] = ["calendarExport": true, "externalActivityID": reminder.calendarItemIdentifier as Any]
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
