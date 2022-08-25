//
//  GoogleCalService.swift
//  Plot
//
//  Created by Cory McHattie on 2/1/21.
//  Copyright © 2021 Immature Creations. All rights reserved.
//

import Foundation
import GoogleSignIn

class GoogleCalService {
    var calendarService: GTLRCalendarService? {
        return GoogleCalSetupAssistant.calendarService
    }
    
    var user : GIDGoogleUser?
    
    func setupGoogle(completion: @escaping (Bool) -> Swift.Void) {
        GoogleCalSetupAssistant.setupGoogle { bool in
            if let user = GIDSignIn.sharedInstance()?.currentUser {
                self.user = user
            }
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
        timeFromNowComponents.month = 6
        let timeFromNow = GTLRDateTime(date: calendar.date(byAdding: timeFromNowComponents, to: Date()) ?? Date())
        
        dispatchGroup.enter()
        let query = GTLRCalendarQuery_CalendarListList.query()
        service.executeQuery(query) { (ticket, result, error) in
            if error == nil, let calendars = (result as? GTLRCalendar_CalendarList)?.items {
                let filteredCalendars = calendars.filter{ $0.summary != "Plot" }
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
    
    func storeEvent(for activity: Activity) -> GTLRCalendar_Event? {
        guard let service = self.calendarService, let startDate = activity.startDate, let endDate = activity.endDate, let start = dateToGLTRDate(date: startDate, allDay: activity.allDay ?? false, timeZone: TimeZone(identifier: activity.startTimeZone ?? "UTC")), let end = dateToGLTRDate(date: endDate, allDay: activity.allDay ?? false, timeZone: TimeZone(identifier: activity.endTimeZone ?? "UTC")), let name = activity.name else {
            return nil
        }
        
        let event = GTLRCalendar_Event()
        event.summary = name
        event.start = start
        event.end = end
        event.recurrence = activity.recurrences
        
        if let value = UserDefaults.standard.string(forKey: "PlotCalendar") {
            let query = GTLRCalendarQuery_EventsInsert.query(withObject: event, calendarId: value)
            service.executeQuery(query, completionHandler: { (ticket, result, error) in
                if error != nil {
                    print("Failed to save google calendar event with error : \(String(describing: error))")
                }
            })
        } else {
            createPlotCalendar { (identifier) in
                if let value = identifier {
                    let query = GTLRCalendarQuery_EventsInsert.query(withObject: event, calendarId: value)
                    service.executeQuery(query, completionHandler: { (ticket, result, error) in
                        if error != nil {
                            print("Failed to save google calendar event with error : \(String(describing: error))")
                        }
                    })
                }
            }
        }
        
        return event
    }
    
    func updateEvent(for activity: Activity) {
        guard let service = self.calendarService, let eventID = activity.externalActivityID, let calendarID = activity.calendarID, let startDate = activity.startDate, let endDate = activity.endDate, let start = dateToGLTRDate(date: startDate, allDay: activity.allDay ?? false, timeZone: TimeZone(identifier: activity.startTimeZone ?? "UTC")), let end = dateToGLTRDate(date: endDate, allDay: activity.allDay ?? false, timeZone: TimeZone(identifier: activity.endTimeZone ?? "UTC")), let name = activity.name else {
            return
        }
        
        let eventQuery = GTLRCalendarQuery_EventsGet.query(withCalendarId: calendarID, eventId: eventID)
        
        service.executeQuery(eventQuery, completionHandler: { (ticket, result, error) in
            guard error == nil, let event = result as? GTLRCalendar_Event else {
                print("failed to grab events \(String(describing: error))")
                return
            }
            
            event.summary = name
            event.start = start
            event.end = end
            event.recurrence = activity.recurrences
            
            let query = GTLRCalendarQuery_EventsInsert.query(withObject: event, calendarId: calendarID)
            service.executeQuery(query, completionHandler: { (ticket, result, error) in
                if error != nil {
                    print("Failed to save google calendar event with error : \(String(describing: error))")
                }
            })
        })
    }
    
    func deleteEvent(for activity: Activity) {
        guard let service = self.calendarService, let eventID = activity.externalActivityID, let calendarID = activity.calendarID else {
            return
        }
        
        let eventQuery = GTLRCalendarQuery_EventsDelete.query(withCalendarId: calendarID, eventId: eventID)
        
        service.executeQuery(eventQuery, completionHandler: { (_, _, error) in
            guard error == nil else {
                print("failed to grab events \(String(describing: error))")
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
            UserDefaults.standard.set(calendar.identifier, forKey: "PlotCalendar")
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
                completion(nil)
                return
            }
            let calendars = items.filter { $0.summary != "Plot" }
            completion(self.convertCalendarsToPlot(calendars: calendars))
        }
    }
    
    func convertCalendarsToPlot(calendars: [GTLRCalendar_CalendarListEntry]) -> [CalendarType] {
        var calendarTypes = [CalendarType]()
        for calendar in calendars {
            let calendarType = CalendarType(id: calendar.identifier ?? UUID().uuidString, name: calendar.summary ?? "Google", color:  CIColor(color: UIColor(calendar.backgroundColor ?? "#007AFF")).stringRepresentation, source: CalendarOptions.google.name)
            calendarTypes.append(calendarType)
        }
        return calendarTypes
    }
}
