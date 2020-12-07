//
//  SyncCalendarEventsOp.swift
//  Plot
//
//  Created by Hafiz Usama on 2020-11-24.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import EventKit
import EventKit

class SyncCalendarEventsOp: AsyncOperation {
    
    private let queue: OperationQueue
    private var operations: [AsyncOperation] = []
    var events: [EKEvent] = []
    
    override init() {
        self.queue = OperationQueue()
    }
    
    override func main() {
        startRequest()
    }
    
    private func startRequest() {
        for event in events {
            let op = CalendarActivityOp(event: event)
            queue.addOperation(op)
        }
        
        queue.addBarrierBlock { [weak self] in
            self?.finish()
        }
    }
}
