//
//  EventKitManager.swift
//  Plot
//
//  Created by Hafiz Usama on 2020-11-23.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import Foundation
import EventKit
import CoreImage
import UIKit

class EventKitManager {
    private let eventKitService: EventKitService
    private var isRunningEvents: Bool
    private var isRunningTasks: Bool
    private var events: [Activity]
    private var tasks: [Activity]
    private var queue: OperationQueue
    
    var isAuthorizedEvents: Bool
    var isAuthorizedReminders: Bool
    var eventAuthorizationStatus: String
    var reminderAuthorizationStatus: String
    
    var plotAppleCalendar: String? {
        if let value = UserDefaults.standard.string(forKey: "PlotAppleCalendar") {
            return value
        } else if let value = UserDefaults.standard.string(forKey: "PlotCalendar") {
            UserDefaults.standard.set(value, forKey: "PlotAppleCalendar")
            return value
        }
        return nil
    }
    
    var plotAppleList: String? {
        if let value = UserDefaults.standard.string(forKey: "PlotAppleList") {
            return value
        } else if let value = UserDefaults.standard.string(forKey: "PlotList") {
            UserDefaults.standard.set(value, forKey: "PlotAppleList")
            return value
        }
        return nil
    }
    
    init(eventKitService: EventKitService) {
        self.eventKitService = eventKitService
        self.isRunningEvents = false
        self.isRunningTasks = false
        self.isAuthorizedEvents = false
        self.isAuthorizedReminders = false
        self.eventAuthorizationStatus = "notDetermined"
        self.reminderAuthorizationStatus = "notDetermined"
        self.events = []
        self.tasks = []
        self.queue = OperationQueue()
    }
    
    func authorizeEventKitEvents(_ completion: @escaping (Bool) -> Void) {
        eventKitService.authorizeEventKitEvents { [weak self] (granted, _) in
            self?.isAuthorizedEvents = granted
            completion(true)
        }
    }
    
    func authorizeEventKitReminders(_ completion: @escaping (Bool) -> Void) {
        eventKitService.authorizeEventKitReminders { [weak self] (granted, _) in
            self?.isAuthorizedReminders = granted
            completion(true)
        }
    }
    
    func checkEventAuthorizationStatus(_ completion: @escaping () -> Void) {
        eventKitService.checkEventAuthorizationStatus { [weak self] status in
            self?.eventAuthorizationStatus = status
            completion()
        }
    }
    
    func checkReminderAuthorizationStatus(_ completion: @escaping () -> Void) {
        eventKitService.checkReminderAuthorizationStatus { [weak self] status in
            self?.reminderAuthorizationStatus = status
            completion()
        }
    }
    
    func syncEventKitActivities(existingActivities: [Activity], completion: @escaping () -> Void) {
        guard !isRunningEvents, isAuthorizedEvents else {
            completion()
            return
        }
                        
        events = []
        isRunningEvents = true
        
        let eventsOp = EKFetchCalendarEventsOp(eventKitService: eventKitService)
        let syncEventsOp = EKSyncCalendarEventsOp(existingActivities: existingActivities)
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
            weakSelf.isRunningEvents = false
            completion()
        }
    }
    
    func syncActivitiesToEventKit(activities: [Activity], completion: @escaping () -> Void)  {
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
                
        let activitiesOp = EKPlotEventOp(eventKitService: eventKitService, activities: filterActivities)
        // Setup queue
        queue.addOperations([activitiesOp], waitUntilFinished: false)
        
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
    
    func grabCalendars() -> [CalendarType]? {
        guard isAuthorizedEvents else {
            return nil
        }
        
        let calendars = eventKitService.eventStore.calendars(for: .event).filter { $0.calendarIdentifier != self.plotAppleCalendar }
        return convertCalendarsToPlot(calendars: calendars)
    }
    
    func convertCalendarsToPlot(calendars: [EKCalendar]) -> [CalendarType] {
        var calendarTypes = [CalendarType]()
        for calendar in calendars {
            let calendarType = CalendarType(id: calendar.calendarIdentifier, name: calendar.title, color: CIColor(cgColor: calendar.cgColor).stringRepresentation, source: CalendarSourceOptions.apple.name, admin: nil, defaultCalendar: false)
            calendarTypes.append(calendarType)
        }
        return calendarTypes
    }
    
    func syncEventKitReminders(existingActivities: [Activity], completion: @escaping () -> Void) {
        guard !isRunningTasks, isAuthorizedReminders else {
            completion()
            return
        }
                        
        tasks = []
        isRunningTasks = true
        
        let remindersOp = EKFetchReminderTasksOp(eventKitService: eventKitService)
        let syncRemindersOp = EKSyncReminderTasksOp(existingActivities: existingActivities)
        let remindersOpAdapter = BlockOperation() { [unowned remindersOp, unowned syncRemindersOp] in
            syncRemindersOp.reminders = remindersOp.reminders
        }
        remindersOpAdapter.addDependency(remindersOp)
        syncRemindersOp.addDependency(remindersOpAdapter)
        
        // Setup queue
        queue.addOperations([remindersOp, remindersOpAdapter, syncRemindersOp], waitUntilFinished: false)
        
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
    
    func syncTasksToEventKit(activities: [Activity], completion: @escaping () -> Void)  {
        guard !isRunningTasks, isAuthorizedReminders else {
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
                        
        let activitiesOp = EKPlotTaskOp(eventKitService: eventKitService, activities: filterActivities)
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
    
    func grabLists() -> [ListType]? {
        guard isAuthorizedReminders else {
            return nil
        }
            
        let calendars = eventKitService.eventStore.calendars(for: .reminder).filter { $0.calendarIdentifier != self.plotAppleList }
        return convertListsToPlot(lists: calendars)
    }
    
    func convertListsToPlot(lists: [EKCalendar]) -> [ListType] {
        var listTypes = [ListType]()
        for list in lists {
            let listType = ListType(id: list.calendarIdentifier, name: list.title, color: CIColor(cgColor: list.cgColor).stringRepresentation, source: ListSourceOptions.apple.name, admin: nil, defaultList: false)
            listTypes.append(listType)
        }
        return listTypes
    }
}
