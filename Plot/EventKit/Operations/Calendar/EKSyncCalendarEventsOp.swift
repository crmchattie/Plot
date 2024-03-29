//
//  SyncCalendarEventsOp.swift
//  Plot
//
//  Created by Hafiz Usama on 2020-11-24.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import EventKit

class EKSyncCalendarEventsOp: AsyncOperation {
    private let queue: OperationQueue
    private var operations: [AsyncOperation] = []
    var events: [EKEvent] = []
    var existingActivities: [Activity] = []
    
    init(existingActivities: [Activity]) {
        self.queue = OperationQueue()
        self.existingActivities = existingActivities
    }
    
    override func main() {
        startRequest()
    }
    
    private func startRequest() {
        for event in events {
            let op = EKCalendarEventOp(event: event)
            queue.addOperation(op)
        }
        
        for activity in existingActivities {
            if !events.contains(where: { $0.calendarItemExternalIdentifierClean.removeCharacters() == activity.externalActivityID }) {
                let op = EKDeletePlotActivityOp(activity: activity)
                queue.addOperation(op)
            }
        }
        
        queue.addBarrierBlock { [weak self] in
            self?.finish()
        }
    }
}
