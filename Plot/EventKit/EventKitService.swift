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
            predicate = eventStore.predicateForEvents(withStart: timeAgo, end: timeFromNow, calendars: nil)
        }

        // Fetch all events that match the predicate.
        var events: [EKEvent] = []
        if let aPredicate = predicate {
            events = eventStore.events(matching: aPredicate)
        }
        
        return events
    }
    
    func storeEvent(for activity: Activity) -> EKEvent? {
        let timezone = TimeZone.current
        let seconds = TimeInterval(timezone.secondsFromGMT(for: Date())) * -1
        
        guard let startDate = activity.startDate?.addingTimeInterval(seconds), let endDate = activity.endDate?.addingTimeInterval(seconds), let name = activity.name else {
            return nil
        }
        
        var text = activity.notes ?? ""
        if text.isEmpty {
            text = activity.activityDescription ?? ""
        }
        
        let event = EKEvent(eventStore: eventStore)
        event.title = name
        event.startDate = startDate
        event.endDate = endDate
        event.notes = text
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
