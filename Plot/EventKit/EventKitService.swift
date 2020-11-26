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
    
    func fetchEventsOneYearFromAPastMonth() -> [EKEvent] {
        // Get the appropriate calendar.
        let calendar = Calendar.current

        // Create the start date components
        var oneDayAgoComponents = DateComponents()
        oneDayAgoComponents.month = -1
        let oneDayAgo = calendar.date(byAdding: oneDayAgoComponents, to: Date())

        // Create the end date components.
        var oneYearFromNowComponents = DateComponents()
        oneYearFromNowComponents.month = 1
        let oneYearFromNow = calendar.date(byAdding: oneYearFromNowComponents, to: Date())

        // Create the predicate from the event store's instance method.
        var predicate: NSPredicate? = nil
        if let anAgo = oneDayAgo, let aNow = oneYearFromNow {
            predicate = setupAssistant.eventStore.predicateForEvents(withStart: anAgo, end: aNow, calendars: nil)
        }

        // Fetch all events that match the predicate.
        var events: [EKEvent] = []
        if let aPredicate = predicate {
            events = setupAssistant.eventStore.events(matching: aPredicate)
        }
        
        return events
    }
}
