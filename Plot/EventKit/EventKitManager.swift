//
//  EventKitManager.swift
//  Plot
//
//  Created by Hafiz Usama on 2020-11-23.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import Foundation

class EventKitManager {
    private let eventKitService: EventKitService
    private var isRunning: Bool
    private var activities: [Activity]
    private var queue: OperationQueue
    
    init(eventKitService: EventKitService) {
        self.eventKitService = eventKitService
        self.isRunning = false
        self.activities = []
        self.queue = OperationQueue()
    }
    
    func syncEventKitActivities(_ completion: @escaping () -> Void) {
        guard !isRunning else {
            completion()
            return
        }
        
        activities = []
        isRunning = true
        
        eventKitService.authorizeEventKit { [weak self] (granted, _) in
            guard let weakSelf = self, granted else {
                self?.isRunning = false
                completion()
                return
            }
            
            let eventsOp = FetchCalendarEventsOp(eventKitService: weakSelf.eventKitService)
            let syncEventsOp = SyncCalendarEventsOp()
            let eventsOpAdapter = BlockOperation() { [unowned eventsOp, unowned syncEventsOp] in
                syncEventsOp.events = eventsOp.events
            }
            eventsOpAdapter.addDependency(eventsOp)
            syncEventsOp.addDependency(eventsOpAdapter)
            
            // Setup queue
            weakSelf.queue.addOperations([eventsOp, eventsOpAdapter, syncEventsOp], waitUntilFinished: false)
            
            // Once everything is fetched call the completion block
            weakSelf.queue.addBarrierBlock { [weak self] in
                guard let weakSelf = self else {
                    completion()
                    return
                }
                
                weakSelf.isRunning = false
                completion()
            }
        }
    }
}
