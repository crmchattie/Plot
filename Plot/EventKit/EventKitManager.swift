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
    
    var isAuthorized: Bool
    
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
    
    func syncEventKitActivities(existingActivities: [Activity], completion: @escaping () -> Void) {
        guard !isRunning, isAuthorized else {
            completion()
            return
        }
        
        activities = []
        isRunning = true
        
        let eventsOp = FetchCalendarEventsOp(eventKitService: eventKitService)
        let syncEventsOp = SyncCalendarEventsOp(existingActivities: existingActivities)
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
    
    func syncActivitiesToEventKit(activities: [Activity], completion: @escaping () -> Void)  {
        guard !isRunning, isAuthorized else {
            completion()
            return
        }
        
        isRunning = true
        
        let calendar = Calendar.current

        // Create the start date components
        var timeAgoComponents = DateComponents()
        timeAgoComponents.day = -7
        let timeAgo = calendar.date(byAdding: timeAgoComponents, to: Date()) ?? Date()

        // Create the end date components.
        var timeFromNowComponents = DateComponents()
        timeFromNowComponents.month = 3
        let timeFromNow = calendar.date(byAdding: timeFromNowComponents, to: Date()) ?? Date()

        //filter old activities out
        let filterActivities = activities.filter { $0.startDate ?? Date() > timeAgo && $0.startDate ?? Date() < timeFromNow }
                
        let activitiesOp = PlotActivityOp(eventKitService: eventKitService, activities: filterActivities)
        // Setup queue
        queue.addOperations([activitiesOp], waitUntilFinished: false)
        
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
    
    func grabCalendars() -> [String]? {
        guard isAuthorized else {
            return nil
        }
        return eventKitService.eventStore.calendars(for: .event).map({ $0.title })
    }
}
