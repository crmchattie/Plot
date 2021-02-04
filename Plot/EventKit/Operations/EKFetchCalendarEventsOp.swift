//
//  FetchCalendarEventsOp.swift
//  Plot
//
//  Created by Hafiz Usama on 2020-11-24.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import EventKit

class EKFetchCalendarEventsOp: AsyncOperation {
    private let eventKitService: EventKitService
    var events: [EKEvent] = []
    
    init(eventKitService: EventKitService) {
        self.eventKitService = eventKitService
    }
    
    override func main() {
        startFetchRequest()
    }
    
    private func startFetchRequest() {
        events = eventKitService.fetchEventsForCertainTime()
        self.finish()
    }
}
