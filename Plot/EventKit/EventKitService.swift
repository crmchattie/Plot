//
//  EventKitService.swift
//  Plot
//
//  Created by Hafiz Usama on 2020-11-23.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import EventKit

class EventKitService {
    
    var eventStore: EKEventStore {
        return EventKitSetupAssistant.eventStore
    }
    
    func authorizeEventKit(completion: @escaping (Bool, Error?) -> Swift.Void) {
        EventKitSetupAssistant.authorizeEventKit(completion: completion)
    }
    
    func fetchEventsForCertainTime() -> [EKEvent] {
        // Get the appropriate calendar.
        let calendar = Calendar.current

        // Create the start date components
        var timeDayAgoComponents = DateComponents()
        timeDayAgoComponents.month = -1
        let timeAgo = calendar.date(byAdding: timeDayAgoComponents, to: Date())

        // Create the end date components.
        var timeFromNowComponents = DateComponents()
        timeFromNowComponents.month = 6
        let timeFromNow = calendar.date(byAdding: timeFromNowComponents, to: Date())

        // Create the predicate from the event store's instance method.
        var predicate: NSPredicate? = nil
        if let timeAgo = timeAgo, let timeFromNow = timeFromNow {
            let calendars = eventStore.calendars(for: .event).filter { $0.type == .local || $0.type == .calDAV || $0.type == .exchange || $0.type == .subscription || $0.type == .birthday }
            predicate = eventStore.predicateForEvents(withStart: timeAgo, end: timeFromNow, calendars: calendars)
        }

        // Fetch all events that match the predicate.
        var events: [EKEvent] = []
        if let aPredicate = predicate {
            events = eventStore.events(matching: aPredicate)
        }
        
        return events
    }
    
    func storeEvent(for activity: Activity) -> EKEvent? {
        guard let startDate = activity.startDate, let endDate = activity.endDate, let name = activity.name else {
            return nil
        }
        
        let event = EKEvent(eventStore: eventStore)
        event.title = name
        event.startDate = startDate
        event.endDate = endDate
        event.timeZone = TimeZone(identifier: activity.startTimeZone ?? "UTC")
        event.notes = activity.activityDescription ?? ""
        event.calendar = eventStore.defaultCalendarForNewEvents
        do {
            try eventStore.save(event, span: .thisEvent)
        }
        catch let error as NSError {
            print("Failed to save iOS calendar event with error : \(error)")
        }
        
        return event
    }
    
}
