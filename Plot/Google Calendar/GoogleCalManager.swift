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
    private var isRunningEvents: Bool
    private var isRunningTasks: Bool
    private var events: [Activity]
    private var tasks: [Activity]
    private var queue: OperationQueue
    
    var isAuthorizedEvents: Bool
    var isAuthorizedTasks: Bool
        
    init(googleCalService: GoogleCalService) {
        self.googleCalService = googleCalService
        self.isRunningEvents = false
        self.isRunningTasks = false
        self.isAuthorizedEvents = false
        self.isAuthorizedTasks = false
        self.events = []
        self.tasks = []
        self.queue = OperationQueue()
    }
    
    func authorizeGEvents(_ completion: @escaping (Bool) -> Void) {
        googleCalService.authorizeGEvents { [weak self] bool in
            self?.isAuthorizedEvents = bool
            completion(true)
        }
    }
    
    func authorizeGReminders(_ completion: @escaping (Bool) -> Void) {
        googleCalService.authorizeGReminders { [weak self] bool  in
            self?.isAuthorizedTasks = bool
            completion(true)
        }
    }
    
    func syncGoogleCalActivities(existingActivities: [Activity], completion: @escaping () -> Void) {
        guard !isRunningEvents, isAuthorizedEvents else {
            completion()
            return
        }
        
        events = []
        isRunningEvents = true
        
        let eventsOp = GFetchCalendarEventsOp(googleCalService: googleCalService)
        let syncEventsOp = GSyncCalendarEventsOp(existingActivities: existingActivities)
        let eventsOpAdapter = BlockOperation() { [unowned eventsOp, unowned syncEventsOp] in
            syncEventsOp.calendarEventsDict = eventsOp.calendarEventsDict
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
            
            weakSelf.isRunningEvents = false
            completion()
        }
    }
    
    func syncActivitiesToGoogleCal(activities: [Activity], completion: @escaping () -> Void)  {
        guard !isRunningEvents, isAuthorizedEvents else {
            completion()
            return
        }
                
        isRunningEvents = true
        
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
        let filterActivities = activities.filter { $0.endDate ?? Date() > timeAgo && $0.endDate ?? Date() < timeFromNow && $0.isTask == nil && $0.calendarSource == CalendarSourceOptions.plot.name }
                
        let eventsOp = GPlotEventOp(googleCalService: googleCalService, activities: filterActivities)
        // Setup queue
        queue.addOperations([eventsOp], waitUntilFinished: false)
        
        // Once everything is fetched call the completion block
        queue.addBarrierBlock { [weak self] in
            guard let weakSelf = self else {
                completion()
                return
            }
            
            weakSelf.isRunningEvents = false
            completion()
        }
    }
    
    func grabCalendars(completion: @escaping ([CalendarType]?) -> Swift.Void) {
        guard isAuthorizedEvents else {
            completion(nil)
            return
        }
        googleCalService.grabCalendars { (calendars) in
            completion(calendars)
        }
    }
    
    func syncGoogleCalTasks(existingActivities: [Activity], completion: @escaping () -> Void) {
        guard !isRunningTasks, isAuthorizedTasks else {
            completion()
            return
        }

        tasks = []
        isRunningTasks = true

        let tasksOp = GFetchListTasksOp(googleCalService: googleCalService)
        let syncTasksOp = GSyncListTasksOp(existingActivities: existingActivities)
        let tasksOpAdapter = BlockOperation() { [unowned tasksOp, unowned syncTasksOp] in
            syncTasksOp.listTasksDict = tasksOp.listTasksDict
        }
        tasksOpAdapter.addDependency(tasksOp)
        syncTasksOp.addDependency(tasksOpAdapter)

        // Setup queue
        queue.addOperations([tasksOp, tasksOpAdapter, syncTasksOp], waitUntilFinished: false)

        // Once everything is fetched call the completion block
        queue.addBarrierBlock { [weak self] in
            guard let weakSelf = self else {
                completion()
                return
            }

            weakSelf.isRunningTasks = false
            completion()
        }
    }

    func syncTasksToGoogleTasks(activities: [Activity], completion: @escaping () -> Void)  {
        guard !isRunningTasks, isAuthorizedTasks else {
            completion()
            return
        }

        isRunningTasks = true
        
        let calendar = Calendar.current
        // Create the start date components
        var timeAgoComponents = DateComponents()
        timeAgoComponents.month = -3
        let timeAgo = calendar.date(byAdding: timeAgoComponents, to: Date()) ?? Date()
        
        //filter old activities out
        let filterActivities = activities.filter { Date(timeIntervalSince1970: $0.lastModifiedDate?.doubleValue ?? 0) > timeAgo && $0.isTask ?? false && $0.listSource == ListSourceOptions.plot.name }

        let activitiesOp = GPlotTaskOp(googleCalService: googleCalService, activities: filterActivities)
        // Setup queue
        queue.addOperations([activitiesOp], waitUntilFinished: false)

        // Once everything is fetched call the completion block
        queue.addBarrierBlock { [weak self] in
            guard let weakSelf = self else {
                completion()
                return
            }

            weakSelf.isRunningTasks = false
            completion()
        }
    }

    func grabLists(completion: @escaping ([ListType]?) -> Swift.Void) {
        guard isAuthorizedTasks else {
            completion(nil)
            return
        }
        googleCalService.grabLists { (lists) in
            completion(lists)
        }
    }
}
