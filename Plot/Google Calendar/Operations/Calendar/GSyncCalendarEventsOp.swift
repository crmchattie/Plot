//
//  GSyncCalendarEventsOp.swift
//  Plot
//
//  Created by Cory McHattie on 2/3/21.
//  Copyright © 2021 Immature Creations. All rights reserved.
//

import Foundation

class GSyncCalendarEventsOp: AsyncOperation {
    
    private let queue: OperationQueue
    private var operations: [AsyncOperation] = []
    var calendarEventsDict: [GTLRCalendar_CalendarListEntry: [GTLRCalendar_Event]] = [:]
    var existingActivities: [Activity] = []
    
    init(existingActivities: [Activity]) {
        self.queue = OperationQueue()
        self.existingActivities = existingActivities
    }
    
    override func main() {
        startRequest()
    }
    
    private func startRequest() {
        for (calendar, events) in calendarEventsDict {
            for event in events {
                let op = GCalendarEventOp(calendar: calendar, event: event)
                queue.addOperation(op)
            }
        }
        
        var events = [GTLRCalendar_Event]()
        for (_, eventList) in calendarEventsDict {
            events.append(contentsOf: eventList)
        }
        for activity in existingActivities {
            if !events.contains(where: { $0.identifierClean == activity.externalActivityID }) {
                let op = GDeletePlotActivityOp(activity: activity)
                queue.addOperation(op)
            }
        }
        
        queue.addBarrierBlock { [weak self] in
            self?.finish()
        }
    }
}
