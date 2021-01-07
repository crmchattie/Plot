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
    private var isAuthorized: Bool
    private var activities: [Activity]
    private var queue: OperationQueue
    
    init(eventKitService: EventKitService) {
        self.eventKitService = eventKitService
        self.isRunning = false
        self.isAuthorized = false
        self.activities = []
        self.queue = OperationQueue()
    }
    
    func authorizeEventKit(_ completion: @escaping (Bool) -> Void) {
        eventKitService.authorizeEventKit { [weak self] (granted, _) in
            self?.isAuthorized = granted
            completion(true)
        }
    }
    
    func syncEventKitActivities(_ completion: @escaping () -> Void) {
        guard !isRunning, isAuthorized else {
            completion()
            return
        }
        
        activities = []
        isRunning = true
        
        let eventsOp = FetchCalendarEventsOp(eventKitService: eventKitService)
        let syncEventsOp = SyncCalendarEventsOp()
        let eventsOpAdapter = BlockOperation() { [unowned eventsOp, unowned syncEventsOp] in
            syncEventsOp.events = eventsOp.events
        }
        eventsOpAdapter.addDependency(eventsOp)
        syncEventsOp.addDependency(eventsOpAdapter)
        
        // Setup queue
        queue.addOperations([eventsOp, eventsOpAdapter, syncEventsOp], waitUntilFinished: false)
        
        // Once everything is fetched call the completion block
        queue.addBarrierBlock { [weak self] in
            guard let weakSelf = self else {
                completion()
                return
            }
            
            weakSelf.isRunning = false
            completion()
        }
    }
}
