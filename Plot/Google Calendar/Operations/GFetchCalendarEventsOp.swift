//
//  GFetchCalendarEventsOp.swift
//  Plot
//
//  Created by Cory McHattie on 2/3/21.
//  Copyright © 2021 Immature Creations. All rights reserved.
//

import Foundation

class GFetchCalendarEventsOp: AsyncOperation {
    private let googleCalService: GoogleCalService
    var calendarEventsDict: [GTLRCalendar_CalendarListEntry: [GTLRCalendar_Event]] = [:]
    
    init(googleCalService: GoogleCalService) {
        self.googleCalService = googleCalService
    }
    
    override func main() {
        startFetchRequest()
    }
    
    private func startFetchRequest() {
        googleCalService.fetchEventsForCertainTime { calendarEventsDict in
            self.calendarEventsDict = calendarEventsDict
            self.finish()
        }
    }
}
