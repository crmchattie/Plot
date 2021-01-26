//
//  SyncCalendarEventsOp.swift
//  Plot
//
//  Created by Hafiz Usama on 2020-11-24.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import EventKit

class SyncCalendarEventsOp: AsyncOperation {
    
    private let queue: OperationQueue
    private var operations: [AsyncOperation] = []
    var events: [EKEvent] = []
    var existingEvents: [EKEvent] = []
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
            if !existingEvents.contains(where: {$0.title == event.title && $0.startDate == event.startDate && $0.endDate == event.endDate}) && !existingActivities.contains(where: {$0.name == event.title && $0.startDate == event.startDate && $0.endDate == event.endDate}) {
                existingEvents.append(event)
                let op = CalendarActivityOp(event: event)
                queue.addOperation(op)
            }
        }
        
        queue.addBarrierBlock { [weak self] in
            self?.finish()
        }
    }
}
