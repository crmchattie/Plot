//
//  GoogleManager.swift
//  Plot
//
//  Created by Cory McHattie on 2/1/21.
//  Copyright © 2021 Immature Creations. All rights reserved.
//

import Foundation

class GoogleCalManager {
    private let googleCalService: GoogleCalService
    private var isRunning: Bool
    private var activities: [Activity]
    private var queue: OperationQueue
    
    var isAuthorized: Bool
        
    init(googleCalService: GoogleCalService) {
        self.googleCalService = googleCalService
        self.isRunning = false
        self.isAuthorized = false
        self.activities = []
        self.queue = OperationQueue()
    }
    
    func setupGoogle(_ completion: @escaping (Bool) -> Void) {
        googleCalService.setupGoogle { [weak self] bool in
            self?.isAuthorized = bool
            completion(true)
        }
    }
    
    func syncGoogleCalActivities(existingActivities: [Activity], completion: @escaping () -> Void) {
        guard !isRunning, isAuthorized else {
            completion()
            return
        }
        
        activities = []
        isRunning = true
        
        let eventsOp = GFetchCalendarEventsOp(googleCalService: googleCalService)
        let syncEventsOp = GSyncCalendarEventsOp(existingActivities: existingActivities)
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
    
    func syncActivitiesToGoogleCal(activities: [Activity], completion: @escaping () -> Void)  {
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
                
        let activitiesOp = GPlotActivityOp(googleCalService: googleCalService, activities: filterActivities)
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
    
    func grabCalendars(completion: @escaping ([String: [String]]?) -> Swift.Void) {
        guard isAuthorized else {
            completion(nil)
            return
        }
        googleCalService.grabCalendars { (calendars) in
            completion(calendars)
        }
    }
}
