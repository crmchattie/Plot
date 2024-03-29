//
//  GoogleCalService.swift
//  Plot
//
//  Created by Cory McHattie on 2/1/21.
//  Copyright © 2021 Immature Creations. All rights reserved.
//

import Foundation
import GoogleSignIn
import EventKit

let kPlotGoogleCalendar = "PlotGoogleCalendar"
let kPlotGoogleList = "PlotGoogleList"

class GoogleCalService {
    var calendarService: GTLRCalendarService? {
        return GoogleCalSetupAssistant.calendarService
    }
    var taskService: GTLRTasksService? {
        return GoogleCalSetupAssistant.taskService
    }
    
    var plotGoogleCalendar: String? {
        if let value = UserDefaults.standard.string(forKey: kPlotGoogleCalendar) {
            return value
        } else if let value = UserDefaults.standard.string(forKey: kPlotCalendar) {
            UserDefaults.standard.set(value, forKey: kPlotGoogleCalendar)
            setFirebaseUserDefaults(child: kPlotGoogleCalendar, childValue: value)
            return value
        }
        return nil
    }
    
    var plotGoogleList: String? {
        if let value = UserDefaults.standard.string(forKey: kPlotGoogleList) {
            return value
        } else if let value = UserDefaults.standard.string(forKey: kPlotList) {
            UserDefaults.standard.set(value, forKey: kPlotGoogleList)
            setFirebaseUserDefaults(child: kPlotGoogleList, childValue: value)
            return value
        }
        return nil
    }
    
    func authorizeGEvents(completion: @escaping (Bool) -> Swift.Void) {
        GoogleCalSetupAssistant.authorizeGEvents { bool in
            completion(bool)
        }
    }
    
    func authorizeGReminders(completion: @escaping (Bool) -> Swift.Void) {
        GoogleCalSetupAssistant.authorizeGReminders { bool in
            completion(bool)
        }
    }
    
    func fetchEventsForCertainTime(completion: @escaping ([GTLRCalendar_CalendarListEntry: [GTLRCalendar_Event]]) -> Swift.Void) {
        var events: [GTLRCalendar_CalendarListEntry: [GTLRCalendar_Event]] = [:]
        guard let service = self.calendarService else {
            completion(events)
            return
        }
        
        let dispatchGroup = DispatchGroup()
        // Get the appropriate calendar.
        let calendar = Calendar.current
        
        // Create the start date components
        var timeDayAgoComponents = DateComponents()
        timeDayAgoComponents.month = -1
        let timeAgo = GTLRDateTime(date: calendar.date(byAdding: timeDayAgoComponents, to: Date()) ?? Date())
        
        // Create the end date components.
        var timeFromNowComponents = DateComponents()
        timeFromNowComponents.month = 3
        let timeFromNow = GTLRDateTime(date: calendar.date(byAdding: timeFromNowComponents, to: Date()) ?? Date())
        
        dispatchGroup.enter()
        let query = GTLRCalendarQuery_CalendarListList.query()
        service.executeQuery(query) { (ticket, result, error) in
            if error == nil, let calendars = (result as? GTLRCalendar_CalendarList)?.items {
                let filteredCalendars = calendars.filter{ $0.identifier != self.plotGoogleCalendar }
                for calendar in filteredCalendars {
                    if let id = calendar.identifier {
                        dispatchGroup.enter()
                        let eventsListQuery = GTLRCalendarQuery_EventsList.query(withCalendarId: id)
                        eventsListQuery.timeMin = timeAgo
                        eventsListQuery.timeMax = timeFromNow
                        
                        service.executeQuery(eventsListQuery, completionHandler: { (ticket, result, error) in
                            guard error == nil, let items = (result as? GTLRCalendar_Events)?.items else {
                                print("failed to grab events \(String(describing: error))")
                                dispatchGroup.leave()
                                return
                            }
                            events[calendar] = items
                            dispatchGroup.leave()
                        })
                    }
                }
                dispatchGroup.leave()
            } else {
                print("failed to grab calendars \(String(describing: error))")
                dispatchGroup.leave()
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            completion(events)
        }
    }
    
    func storeEvent(for activity: Activity, completion: @escaping (GTLRCalendar_Event?) -> Swift.Void) {
        guard let service = self.calendarService, let startDate = activity.startDate, let endDate = activity.endDate, let start = dateToGLTRDate(date: startDate, allDay: activity.allDay ?? false, timeZone: TimeZone(identifier: activity.startTimeZone ?? "UTC")), let end = dateToGLTRDate(date: endDate, allDay: activity.allDay ?? false, timeZone: TimeZone(identifier: activity.endTimeZone ?? "UTC")), let name = activity.name else {
            completion(nil)
            return
        }
        
        let event = GTLRCalendar_Event()
        event.summary = name
        event.start = start
        event.end = end
        event.recurrence = activity.recurrences
                        
        if let value = plotGoogleCalendar {
            let query = GTLRCalendarQuery_EventsInsert.query(withObject: event, calendarId: value)
            service.executeQuery(query, completionHandler: { (ticket, result, error) in
                if let event = result as? GTLRCalendar_Event {
                    completion(event)
                    return
                }
                print("Failed to save google calendar event with error : \(String(describing: error))")
                completion(nil)
            })
        } else {
            createPlotCalendar { (identifier) in
                if let value = identifier {
                    let query = GTLRCalendarQuery_EventsInsert.query(withObject: event, calendarId: value)
                    service.executeQuery(query, completionHandler: { (ticket, result, error) in
                        if let event = result as? GTLRCalendar_Event {
                            completion(event)
                            return
                        }
                        print("Failed to save google calendar event with error : \(String(describing: error))")
                        completion(nil)
                    })
                }
            }
        }
    }
    
    func updateEvent(for activity: Activity, span: EKSpan) {
        guard let service = self.calendarService, let eventID = activity.externalActivityID, let startDate = activity.startDate, let endDate = activity.endDate, let start = dateToGLTRDate(date: startDate, allDay: activity.allDay ?? false, timeZone: TimeZone(identifier: activity.startTimeZone ?? "UTC")), let end = dateToGLTRDate(date: endDate, allDay: activity.allDay ?? false, timeZone: TimeZone(identifier: activity.endTimeZone ?? "UTC")), let name = activity.name else {
            return
        }
        
        var calendarID = String()
        if activity.calendarSource == CalendarSourceOptions.plot.name, let calendar = plotGoogleCalendar {
            calendarID = calendar
        } else if let calendar = activity.calendarID {
            calendarID = calendar
        }
        
        if span == .futureEvents {
            let eventQuery = GTLRCalendarQuery_EventsGet.query(withCalendarId: calendarID, eventId: eventID)
            
            service.executeQuery(eventQuery, completionHandler: { (ticket, result, error) in
                guard error == nil, let event = result as? GTLRCalendar_Event else {
                    print("failed to update/grab FUTURE event \(String(describing: error))")
                    return
                }
                
                event.summary = name
                event.start = start
                event.end = end
                event.recurrence = activity.recurrences
                            
                let query = GTLRCalendarQuery_EventsUpdate.query(withObject: event, calendarId: calendarID, eventId: eventID)
                service.executeQuery(query, completionHandler: { (ticket, result, error) in
                    if error != nil {
                        print("Failed to update google calendar event with error : \(String(describing: error))")
                    }
                })
            })
        } else if span == .thisEvent, let originalStartDate = activity.instanceOriginalStartDate, let originalStartTime = dateToGLTRDate(date: originalStartDate, allDay: activity.allDay ?? false, timeZone: TimeZone(identifier: activity.startTimeZone ?? "UTC")) {
            let instancesQuery = GTLRCalendarQuery_EventsInstances.query(withCalendarId: calendarID, eventId: eventID)
            service.executeQuery(instancesQuery, completionHandler: { (ticket, result, error) in
                guard error == nil, let events = result as? GTLRCalendar_Events, let instances = events.items else {
                    print("failed to update/grab THIS event \(String(describing: error))")
                    return
                }
                
                if let event = instances.first(where: {$0.originalStartTime == originalStartTime }) {
                    event.summary = name
                    event.start = start
                    event.end = end
                    event.recurrence = activity.recurrences
                                
                    let query = GTLRCalendarQuery_EventsUpdate.query(withObject: event, calendarId: calendarID, eventId: eventID)
                    service.executeQuery(query, completionHandler: { (ticket, result, error) in
                        if error != nil {
                            print("Failed to update google calendar event with error : \(String(describing: error))")
                        }
                    })
                }
            })
            
        }
    }
    
    func deleteEvent(for activity: Activity) {
        guard let service = self.calendarService, let eventID = activity.externalActivityID else {
            return
        }
        
        var calendarID = String()
        if activity.calendarSource == CalendarSourceOptions.plot.name, let calendar = plotGoogleCalendar {
            calendarID = calendar
        } else if let calendar = activity.calendarID {
            calendarID = calendar
        }
        
        let eventQuery = GTLRCalendarQuery_EventsDelete.query(withCalendarId: calendarID, eventId: eventID)
        
        service.executeQuery(eventQuery, completionHandler: { (_, _, error) in
            guard error == nil else {
                print("failed to delete events \(String(describing: error))")
                return
            }
        })
    }
    
    func deleteCalendar(for calendarID: String) {
        guard let service = self.calendarService else {
            return
        }
        
        let eventQuery = GTLRCalendarQuery_CalendarsDelete.query(withCalendarId: calendarID)
        
        service.executeQuery(eventQuery, completionHandler: { (_, _, error) in
            guard error == nil else {
                print("failed to delete calendar \(String(describing: error))")
                return
            }
        })
    }
    
    func createPlotCalendar(completion: @escaping (String?) -> Swift.Void) {
        guard let service = self.calendarService else {
            completion(nil)
            return
        }
        let calendar = GTLRCalendar_Calendar()
        calendar.summary = "Plot"
                
        let query = GTLRCalendarQuery_CalendarsInsert.query(withObject: calendar)
        service.executeQuery(query, completionHandler: { (ticket, result, error) in
            guard error == nil, let createdCalendar = result as? GTLRCalendar_Calendar else {
                print("Failed to save google calendar with error : \(String(describing: error))")
                completion(nil)
                return
            }
            UserDefaults.standard.set(createdCalendar.identifier, forKey: kPlotGoogleCalendar)
            if let id = createdCalendar.identifier {
                setFirebaseUserDefaults(child: kPlotGoogleCalendar, childValue: id)
            }
            completion(createdCalendar.identifier)
        })
    }
    
    func grabCalendars(completion: @escaping ([CalendarType]?) -> Swift.Void) {
        guard let service = self.calendarService else {
            completion(nil)
            return
        }
        
        let query = GTLRCalendarQuery_CalendarListList.query()
        service.executeQuery(query) { (ticket, result, error) in
            guard error == nil, let items = (result as? GTLRCalendar_CalendarList)?.items else {
                print("grabCalendars error \(String(describing: error))")
                completion(nil)
                return
            }
            let calendars = items.filter { $0.identifier != self.plotGoogleCalendar }
            completion(self.convertCalendarsToPlot(calendars: calendars))
        }
    }
    
    func convertCalendarsToPlot(calendars: [GTLRCalendar_CalendarListEntry]) -> [CalendarType] {
        var calendarTypes = [CalendarType]()
        for calendar in calendars {
            let calendarType = CalendarType(id: calendar.identifier ?? UUID().uuidString, name: calendar.summary ?? "Google", color:  CIColor(color: UIColor(calendar.backgroundColor ?? "#007AFF")).stringRepresentation, source: CalendarSourceOptions.google.name, admin: nil, defaultCalendar: false)
            calendarTypes.append(calendarType)
        }
        return calendarTypes
    }
    
    func fetchTasks(completion: @escaping ([GTLRTasks_TaskList: [GTLRTasks_Task]]) -> Swift.Void) {
        var tasks: [GTLRTasks_TaskList: [GTLRTasks_Task]] = [:]
        guard let service = self.taskService else {
            completion(tasks)
            return
        }
        let dispatchGroup = DispatchGroup()
        
        dispatchGroup.enter()
        let query = GTLRTasksQuery_TasklistsList.query()
        query.maxResults = 100
        service.executeQuery(query) { (ticket, result, error) in
            if error == nil, let lists = (result as? GTLRTasks_TaskLists)?.items {
                let filteredLists = lists.filter{ $0.identifier != self.plotGoogleList }
                for list in filteredLists {
                    if let id = list.identifier {
                        dispatchGroup.enter()
                        let tasksListQuery = GTLRTasksQuery_TasksList.query(withTasklist: id)
                        tasksListQuery.maxResults = 100
                        
                        service.executeQuery(tasksListQuery, completionHandler: { (ticket, result, error) in
                            guard error == nil, let items = (result as? GTLRTasks_Tasks)?.items else {
                                print("failed to grab reminders \(String(describing: error))")
                                dispatchGroup.leave()
                                return
                            }
                            var filteredTasks = [GTLRTasks_Task]()
                            for item in items {
                                if item.completed == nil {
                                    filteredTasks.append(item)
                                }
                            }
                            tasks[list] = filteredTasks
                            dispatchGroup.leave()
                        })
                    }
                }
                dispatchGroup.leave()
            } else {
                print("failed to grab lists \(String(describing: error))")
                dispatchGroup.leave()
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            completion(tasks)
        }
    }
    
    func storeTask(for activity: Activity, completion: @escaping (GTLRTasks_Task?) -> Swift.Void) {
        guard let service = self.taskService, let name = activity.name else {
            completion(nil)
            return
        }
        
        let task = GTLRTasks_Task()
        task.title = name
        
        let isodateFormatter = ISO8601DateFormatter()
        
        if let deadlineDateSwitch = activity.endDate {
            let date = isodateFormatter.string(from: deadlineDateSwitch)
            task.due = date
        }
        
        if activity.isCompleted ?? false, let completedDate = activity.completedDate {
            let date = isodateFormatter.string(from: Date(timeIntervalSince1970: completedDate.doubleValue))
            task.completed = date
        }
        
        if let value = plotGoogleList {
            let query = GTLRTasksQuery_TasksInsert.query(withObject: task, tasklist: value)
            service.executeQuery(query, completionHandler: { (ticket, result, error) in
                if let event = result as? GTLRTasks_Task {
                    completion(event)
                    return
                }
                print("Failed to save google calendar event with error : \(String(describing: error))")
                completion(nil)
            })
        } else {
            createPlotList { (identifier) in
                if let value = identifier {
                    let query = GTLRTasksQuery_TasksInsert.query(withObject: task, tasklist: value)
                    service.executeQuery(query, completionHandler: { (ticket, result, error) in
                        if let event = result as? GTLRTasks_Task {
                            completion(event)
                            return
                        }
                        print("Failed to save google calendar event with error : \(String(describing: error))")
                        completion(nil)
                    })
                }
            }
        }
    }
    
    func updateTask(for activity: Activity) {
        guard let service = self.taskService, let taskID = activity.externalActivityID, let name = activity.name else {
            return
        }
        
        var listID = String()
        if activity.listSource == ListSourceOptions.plot.name, let list = plotGoogleList {
            listID = list
        } else if let list = activity.listID {
            listID = list
        }
        
        let taskQuery = GTLRTasksQuery_TasksGet.query(withTasklist: listID, task: taskID)
        
        service.executeQuery(taskQuery, completionHandler: { (ticket, result, error) in
            guard error == nil, let task = result as? GTLRTasks_Task else {
                print("failed to grab events \(String(describing: error))")
                return
            }
            
            task.title = name
            
            let isodateFormatter = ISO8601DateFormatter()
            
            if let deadlineDateSwitch = activity.endDate {
                let date = isodateFormatter.string(from: deadlineDateSwitch)
                task.due = date
            }
            
            if activity.isCompleted ?? false, let completedDate = activity.completedDate {
                let date = isodateFormatter.string(from: Date(timeIntervalSince1970: completedDate.doubleValue))
                task.completed = date
            }
            
            let query = GTLRTasksQuery_TasksUpdate.query(withObject: task, tasklist: listID, task: taskID)
            service.executeQuery(query, completionHandler: { (ticket, result, error) in
                if error != nil {
                    print("Failed to update google task with error : \(String(describing: error))")
                }
            })
        })
    }
    
    func deleteTask(for activity: Activity) {
        guard let service = self.taskService, let taskID = activity.externalActivityID else {
            return
        }
        
        var listID = String()
        if activity.listSource == ListSourceOptions.plot.name, let list = plotGoogleList {
            listID = list
        } else if let list = activity.listID {
            listID = list
        }
        
        let taskQuery = GTLRTasksQuery_TasksDelete.query(withTasklist: listID, task: taskID)
        
        service.executeQuery(taskQuery, completionHandler: { (_, _, error) in
            guard error == nil else {
                print("failed to grab events \(String(describing: error))")
                return
            }
        })
    }
    
    func createPlotList(completion: @escaping (String?) -> Swift.Void) {
        guard let service = self.taskService else {
            completion(nil)
            return
        }
        let list = GTLRTasks_TaskList()
        list.title = "Plot"
        
        let query = GTLRTasksQuery_TasklistsInsert.query(withObject: list)
        service.executeQuery(query, completionHandler: { (ticket, result, error) in
            guard error == nil, let createdList = result as? GTLRTasks_TaskList else {
                print("Failed to save google calendar with error : \(String(describing: error))")
                completion(nil)
                return
            }
            UserDefaults.standard.set(createdList.identifier, forKey: kPlotGoogleList)
            if let id = createdList.identifier {
                setFirebaseUserDefaults(child: kPlotGoogleList, childValue: id)
            }
            completion(createdList.identifier)
        })
    }
    
    func grabLists(completion: @escaping ([ListType]?) -> Swift.Void) {
        guard let service = self.taskService else {
            completion(nil)
            return
        }
        
        let query = GTLRTasksQuery_TasklistsList.query()
        service.executeQuery(query) { (ticket, result, error) in
            guard error == nil, let items = (result as? GTLRTasks_TaskLists)?.items else {
                print("grabLists error \(String(describing: error))")
                completion(nil)
                return
            }
            let lists = items.filter { $0.identifier != self.plotGoogleList }
            completion(self.convertListsToPlot(lists: lists))
        }
    }
    
    func convertListsToPlot(lists: [GTLRTasks_TaskList]) -> [ListType] {
        var listTypes = [ListType]()
        for list in lists {
            let listType = ListType(id: list.identifier ?? UUID().uuidString, name: list.title ?? "Google", color:  CIColor(color: UIColor("#007AFF")).stringRepresentation, source: ListSourceOptions.google.name, admin: nil, defaultList: false, financeList: false, healthList: false, goalList: false)
            listTypes.append(listType)
        }
        return listTypes
    }
}
