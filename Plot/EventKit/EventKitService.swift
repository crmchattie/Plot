//
//  EventKitService.swift
//  Plot
//
//  Created by Hafiz Usama on 2020-11-23.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import EventKit

class EventKitService {
    let setupAssistant: EventKitSetupAssistant
    
    init(setupAssistant: EventKitSetupAssistant) {
        self.setupAssistant = setupAssistant
    }
    
    func authorizeEventKit(completion: @escaping (Bool, Error?) -> Swift.Void) {
        setupAssistant.authorizeEventKit(completion: completion)
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
            predicate = setupAssistant.eventStore.predicateForEvents(withStart: timeAgo, end: timeFromNow, calendars: nil)
        }

        // Fetch all events that match the predicate.
        var events: [EKEvent] = []
        if let aPredicate = predicate {
            events = setupAssistant.eventStore.events(matching: aPredicate)
        }
        
        return events
    }
}
