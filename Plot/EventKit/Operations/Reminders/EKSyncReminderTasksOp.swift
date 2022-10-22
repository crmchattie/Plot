//
//  SyncCalendarEventsOp.swift
//  Plot
//
//  Created by Hafiz Usama on 2020-11-24.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import EventKit

class EKSyncReminderTasksOp: AsyncOperation {
    
    private let queue: OperationQueue
    private var operations: [AsyncOperation] = []
    var reminders: [EKReminder] = []
    var existingActivities: [Activity] = []
    
    init(existingActivities: [Activity]) {
        self.queue = OperationQueue()
        self.existingActivities = existingActivities
    }
    
    override func main() {
        startRequest()
    }
    
    private func startRequest() {
        for reminder in reminders {
            let op = EKReminderTaskOp(reminder: reminder)
            queue.addOperation(op)
        }
        
        for activity in existingActivities {
            if !reminders.contains(where: { $0.calendarItemIdentifier == activity.externalActivityID }) {
                let op = EKDeletePlotActivityOp(activity: activity)
                queue.addOperation(op)
            }
        }
        
        queue.addBarrierBlock { [weak self] in
            self?.finish()
        }
    }
}
