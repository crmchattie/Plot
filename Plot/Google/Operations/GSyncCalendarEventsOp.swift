//
//  GSyncCalendarEventsOp.swift
//  Plot
//
//  Created by Cory McHattie on 2/3/21.
//  Copyright © 2021 Immature Creations. All rights reserved.
//

import Foundation

class GSyncCalendarEventsOp: AsyncOperation {
    
    private let queue: OperationQueue
    private var operations: [AsyncOperation] = []
    var events: [GTLRCalendar_Event] = []
    var existingEvents: [GTLRCalendar_Event] = []
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
            if !existingEvents.contains(where: {$0.summary == event.summary && $0.start == event.start && $0.end == event.end}) && !existingActivities.contains(where: {$0.name == event.summary && $0.startDate == event.startDate && $0.endDate == event.endDate}) {
                existingEvents.append(event)
                let op = GCalendarActivityOp(event: event)
                queue.addOperation(op)
            }
        }
        
        queue.addBarrierBlock { [weak self] in
            self?.finish()
        }
    }
}
