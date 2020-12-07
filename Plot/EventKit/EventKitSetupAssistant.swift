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
    
    let eventStore: EKEventStore
    
    init() {
        eventStore = EKEventStore()
    }
    
    func authorizeEventKit(completion: @escaping (Bool, Error?) -> Swift.Void) {
        eventStore.requestAccess(to: .event) { granted, error in
            completion(granted, error)
        }
    }
}
