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
        return GoogleSetupAssistant.calendarService
    }
    
    var user : GIDGoogleUser?
    
    func setupGoogle(completion: @escaping (Bool) -> Swift.Void) {
        GoogleSetupAssistant.setupGoogle { bool in
            if let user = GIDSignIn.sharedInstance()?.currentUser {
                self.user = user
            }
            completion(bool)
        }
    }
    
    func fetchEventsForCertainTime() -> [GTLRCalendar_Event] {
        var events: [GTLRCalendar_Event] = []
        guard let service = self.calendarService else {
            return events
        }
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

        let query = GTLRCalendarQuery_CalendarListList.query()
        service.executeQuery(query) { (ticket, result, error) in
            if error == nil, let items = (result as? GTLRCalendar_CalendarList)?.items {
                for item in items {
                    if let id = item.identifier {
                        let eventsListQuery = GTLRCalendarQuery_EventsList.query(withCalendarId: id)
                        eventsListQuery.timeMin = timeAgo
                        eventsListQuery.timeMax = timeFromNow

                        service.executeQuery(eventsListQuery, completionHandler: { (ticket, result, error) in
                            guard error == nil, let items = (result as? GTLRCalendar_Events)?.items else {
                                return
                            }

                            if items.count > 0 {
                                print(items)
                                events.append(contentsOf: items)
                                // Do stuff with your events
                            } else {
                                // No events
                            }
                        })
                    }
                }
            }
        }
        
        return events
    }
    
    func storeEvent(for activity: Activity) -> GTLRCalendar_Event? {
        guard let service = self.calendarService, let startDate = activity.startDate, let endDate = activity.endDate, let start = dateToGLTRDate(date: startDate, timeZone: TimeZone(identifier: activity.startTimeZone ?? "UTC")), let end = dateToGLTRDate(date: endDate, timeZone: TimeZone(identifier: activity.endTimeZone ?? "UTC")), let name = activity.name else {
            return nil
        }
        
        let event = GTLRCalendar_Event()
        event.summary = name
        event.start = start
        event.end = end
        
        let query = GTLRCalendarQuery_EventsInsert.query(withObject: event, calendarId: "primary")
        service.executeQuery(query, completionHandler: { (ticket, result, error) in
            if error != nil {
                print("Failed to save google calendar event with error : \(String(describing: error))")
            }
        })
        
        return event
    }
    
    func grabCalendars(completion: @escaping ([String: [String]]?) -> Swift.Void) {
        guard let service = self.calendarService, let user = user else {
            completion(nil)
            return
        }
        
        var calendars = [String: [String]]()
        let query = GTLRCalendarQuery_CalendarListList.query()
        service.executeQuery(query) { (ticket, result, error) in
            guard error == nil, let items = (result as? GTLRCalendar_CalendarList)?.items else {
                completion(nil)
                return
            }
            calendars[user.profile.email] = items.map { $0.summary ?? "" }
            completion(calendars)
        }
    }
}
