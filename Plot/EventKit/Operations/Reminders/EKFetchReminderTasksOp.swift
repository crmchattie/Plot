//
//  FetchCalendarEventsOp.swift
//  Plot
//
//  Created by Hafiz Usama on 2020-11-24.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import EventKit

class EKFetchReminderTasksOp: AsyncOperation {
    private let eventKitService: EventKitService
    var reminders: [EKReminder] = []
    
    init(eventKitService: EventKitService) {
        self.eventKitService = eventKitService
    }
    
    override func main() {
        startFetchRequest()
    }
    
    private func startFetchRequest() {
        eventKitService.fetchReminders { reminders in
            self.reminders = reminders
            self.finish()
        }
    }
}
