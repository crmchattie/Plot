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
    
    class func authorizeEventKit(completion: @escaping (Bool, Error?) -> Swift.Void) {
        EventKitSetupAssistant.eventStore.requestAccess(to: .event) { granted, error in
            completion(granted, error)
        }
    }
}
