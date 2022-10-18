//
//  EventKitSetupAssistant.swift
//  Plot
//
//  Created by Hafiz Usama on 2020-11-23.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import Foundation
import EventKit

class EventKitSetupAssistant {
    
    static let eventStore = EKEventStore()
    
    class func authorizeEventKitEvents(completion: @escaping (Bool, Error?) -> Swift.Void) {
        EventKitSetupAssistant.eventStore.requestAccess(to: .event) { granted, error in
            EventKitSetupAssistant.eventStore.reset()
            completion(granted, error)
        }
    }
    class func authorizeEventKitReminders(completion: @escaping (Bool, Error?) -> Swift.Void) {
        EventKitSetupAssistant.eventStore.requestAccess(to: .reminder) { granted, error in
            EventKitSetupAssistant.eventStore.reset()
            completion(granted, error)
        }
    }
}
