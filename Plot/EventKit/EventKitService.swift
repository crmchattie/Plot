//
//  EventKitService.swift
//  Plot
//
//  Created by Hafiz Usama on 2020-11-23.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import EventKit
import RRuleSwift

class EventKitService {
    
    var eventStore: EKEventStore {
        return EventKitSetupAssistant.eventStore
    }
    
    var plotAppleCalendar: String? {
        if let value = UserDefaults.standard.string(forKey: "PlotAppleCalendar") {
            return value
        } else if let value = UserDefaults.standard.string(forKey: "PlotCalendar") {
            UserDefaults.standard.set(value, forKey: "PlotAppleCalendar")
            return value
        }
        return nil
    }
    
    var plotAppleList: String? {
        if let value = UserDefaults.standard.string(forKey: "PlotAppleList") {
            return value
        } else if let value = UserDefaults.standard.string(forKey: "PlotList") {
            UserDefaults.standard.set(value, forKey: "PlotAppleList")
            return value
        }
        return nil
    }
    
    func authorizeEventKitEvents(completion: @escaping (Bool, Error?) -> Swift.Void) {
        EventKitSetupAssistant.authorizeEventKitEvents(completion: completion)
    }
    
    func authorizeEventKitReminders(completion: @escaping (Bool, Error?) -> Swift.Void) {
        EventKitSetupAssistant.authorizeEventKitReminders(completion: completion)
    }
    
    func checkEventAuthorizationStatus(completion: @escaping (String) -> Swift.Void) {
        let status = EKEventStore.authorizationStatus(for: .event)
        switch (status) {
        case EKAuthorizationStatus.notDetermined:
            // This happens on first-run
            completion("notDetermined")
        case EKAuthorizationStatus.authorized:
            // Things are in line with being able to show the calendars in the table view
            completion("authorized")
        case EKAuthorizationStatus.restricted, EKAuthorizationStatus.denied:
            // We need to help them give us permission
            completion("restricted")
        default:
            completion("default")
        }
    }
    
    func checkReminderAuthorizationStatus(completion: @escaping (String) -> Swift.Void) {
        let status = EKEventStore.authorizationStatus(for: .reminder)
        switch (status) {
        case EKAuthorizationStatus.notDetermined:
            // This happens on first-run
            completion("notDetermined")
        case EKAuthorizationStatus.authorized:
            // Things are in line with being able to show the calendars in the table view
            completion("authorized")
        case EKAuthorizationStatus.restricted, EKAuthorizationStatus.denied:
            // We need to help them give us permission
            completion("restricted")
        default:
            completion("default")
        }
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
            let calendars = eventStore.calendars(for: .event).filter { $0.calendarIdentifier != self.plotAppleCalendar }
            predicate = eventStore.predicateForEvents(withStart: timeAgo, end: timeFromNow, calendars: calendars)
        }
        
        // Fetch all events that match the predicate.
        var events: [EKEvent] = []
        if let aPredicate = predicate {
            let unfilteredEvents = eventStore.events(matching: aPredicate)
            //remove redunction events due to recurrences
            for event in unfilteredEvents {
                if !events.contains(where: {$0.calendarItemIdentifier == event.calendarItemIdentifier} ) {
                    events.append(event)
                }
            }
        }
        
        return events
    }
    
    func storeEvent(for activity: Activity) -> EKEvent? {
        guard let startDate = activity.startDate, let endDate = activity.endDate, let name = activity.name, let allDay = activity.allDay else {
            return nil
        }
        
        let event = EKEvent(eventStore: eventStore)
        event.title = name
        event.startDate = startDate
        event.endDate = endDate
        event.isAllDay = allDay
        event.timeZone = TimeZone(identifier: activity.startTimeZone ?? "UTC")
        event.notes = activity.activityDescription ?? ""
        
        if let recurrences = activity.recurrences, let recurrenceRule = RecurrenceRule(rruleString: recurrences[0]), let frequency = EKRecurrenceFrequency(rawValue: recurrenceRule.frequency.number) {
            var daysOfTheWeek = [EKRecurrenceDayOfWeek]()
            for dayy in recurrenceRule.byweekday {
                daysOfTheWeek.append(EKRecurrenceDayOfWeek.init(dayy))
            }
            
            var daysOfTheMonth = [NSNumber]()
            for dayy in recurrenceRule.bymonthday {
                daysOfTheMonth.append(NSNumber(value: dayy))
            }
            
            var monthsOfTheYear = [NSNumber]()
            for month in recurrenceRule.bymonth {
                monthsOfTheYear.append(NSNumber(value: month))
            }
            
            var weeksOfTheYear = [NSNumber]()
            for week in recurrenceRule.byweekno {
                weeksOfTheYear.append(NSNumber(value: week))
            }
            
            var daysOfTheYear = [NSNumber]()
            for dayy in recurrenceRule.byyearday {
                daysOfTheYear.append(NSNumber(value: dayy))
            }
            
            var setPositions = [NSNumber]()
            for setPos in recurrenceRule.bysetpos {
                setPositions.append(NSNumber(value: setPos))
            }
                        
            event.recurrenceRules = [EKRecurrenceRule(recurrenceWith: frequency, interval: recurrenceRule.interval, daysOfTheWeek: daysOfTheWeek, daysOfTheMonth: daysOfTheMonth, monthsOfTheYear: monthsOfTheYear, weeksOfTheYear: weeksOfTheYear, daysOfTheYear: daysOfTheYear, setPositions: setPositions, end: recurrenceRule.recurrenceEnd)]
        }
        
        if let value = UserDefaults.standard.string(forKey: "PlotAppleCalendar"), let calendar = eventStore.calendar(withIdentifier: value) {
            event.calendar = calendar
            do {
                try eventStore.save(event, span: .thisEvent)
            }
            catch let error as NSError {
                print("Failed to save iOS calendar event with error : \(error)")
            }
        } else if let calendar = createPlotCalendar() {
            event.calendar = calendar
            do {
                try eventStore.save(event, span: .thisEvent)
            }
            catch let error as NSError {
                print("Failed to save iOS calendar event with error : \(error)")
            }
        }
        
        return event
    }
    
    func updateEvent(for activity: Activity) {
        guard let eventID = activity.externalActivityID, let startDate = activity.startDate, let endDate = activity.endDate, let name = activity.name, let allDay = activity.allDay else {
            return
        }
        
        let existingEvent = eventStore.calendarItem(withIdentifier:eventID)
        if let event = existingEvent as? EKEvent {
            event.title = name
            event.startDate = startDate
            event.endDate = endDate
            event.isAllDay = allDay
            event.timeZone = TimeZone(identifier: activity.startTimeZone ?? "UTC")
            event.notes = activity.activityDescription ?? ""
            if let recurrences = activity.recurrences, let recurrenceRule = RecurrenceRule(rruleString: recurrences[0]), let frequency = EKRecurrenceFrequency(rawValue: recurrenceRule.frequency.number) {
                var daysOfTheWeek = [EKRecurrenceDayOfWeek]()
                for dayy in recurrenceRule.byweekday {
                    daysOfTheWeek.append(EKRecurrenceDayOfWeek.init(dayy))
                }
                
                var daysOfTheMonth = [NSNumber]()
                for dayy in recurrenceRule.bymonthday {
                    daysOfTheMonth.append(NSNumber(value: dayy))
                }
                
                var monthsOfTheYear = [NSNumber]()
                for month in recurrenceRule.bymonth {
                    monthsOfTheYear.append(NSNumber(value: month))
                }
                
                var weeksOfTheYear = [NSNumber]()
                for week in recurrenceRule.byweekno {
                    weeksOfTheYear.append(NSNumber(value: week))
                }
                
                var daysOfTheYear = [NSNumber]()
                for dayy in recurrenceRule.byyearday {
                    daysOfTheYear.append(NSNumber(value: dayy))
                }
                
                var setPositions = [NSNumber]()
                for setPos in recurrenceRule.bysetpos {
                    setPositions.append(NSNumber(value: setPos))
                }
                            
                event.recurrenceRules = [EKRecurrenceRule(recurrenceWith: frequency, interval: recurrenceRule.interval, daysOfTheWeek: daysOfTheWeek, daysOfTheMonth: daysOfTheMonth, monthsOfTheYear: monthsOfTheYear, weeksOfTheYear: weeksOfTheYear, daysOfTheYear: daysOfTheYear, setPositions: setPositions, end: recurrenceRule.recurrenceEnd)]
            }
            
            do {
                try eventStore.save(event, span: .futureEvents)
            }
            catch let error as NSError {
                print("Failed to save iOS calendar event with error : \(error)")
            }
        }
    }
    
    func deleteEvent(for activity: Activity) {
        guard let eventID = activity.externalActivityID else {
            return
        }
        
        if let event = eventStore.calendarItem(withIdentifier: eventID) as? EKEvent {
            do {
                try eventStore.remove(event, span: .futureEvents, commit: true)
            }
            catch let error as NSError {
                print("Failed to save iOS calendar event with error : \(error)")
            }
        }
    }
    
    func createPlotCalendar() -> EKCalendar? {
        let calendar = EKCalendar(for: .event, eventStore: eventStore)
        calendar.title = "Plot"
        calendar.cgColor = UIColor.systemBlue.cgColor

        guard let source = bestPossibleEKEventSource() else {
            return nil
        }
        calendar.source = source
        do {
            try eventStore.saveCalendar(calendar, commit: true)
            UserDefaults.standard.set(calendar.calendarIdentifier, forKey: "PlotAppleCalendar")
        } catch let error as NSError {
            print("Failed to save iOS calendar with error : \(error)")
        }
        return calendar
    }
    
    func bestPossibleEKEventSource() -> EKSource? {
        let `default` = eventStore.defaultCalendarForNewEvents?.source
        let iCloud = eventStore.sources.first(where: { $0.title == "iCloud" }) // this is fragile, user can rename the source
        let local = eventStore.sources.first(where: { $0.sourceType == .local })

        return `default` ?? iCloud ?? local
    }
    
    func fetchReminders(completion: @escaping ([EKReminder]) -> Swift.Void) {
        let calendars = eventStore.calendars(for: .reminder).filter { $0.calendarIdentifier != self.plotAppleList }
        let predicate: NSPredicate? = eventStore.predicateForReminders(in: calendars)
        if let aPredicate = predicate {
            eventStore.fetchReminders(matching: aPredicate, completion: {(_ reminders: [Any]?) -> Void in
                var filteredReminders = [EKReminder]()
                //remove redunction reminders due to recurrences
                for reminder in reminders as? [EKReminder] ?? [] {
                    if !filteredReminders.contains(where: {$0.calendarItemIdentifier == reminder.calendarItemIdentifier} ) {
                        filteredReminders.append(reminder)
                    }
                }
                completion(filteredReminders)
            })
        }
    }
    
    func storeReminder(for activity: Activity) -> EKReminder? {
        guard let name = activity.name else {
            return nil
        }
        
        let reminder = EKReminder(eventStore: eventStore)
        reminder.title = name
        if let startDate = activity.startDate {
            let calendar = Calendar.current
            if activity.hasStartTime ?? false {
                let dateComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: startDate)
                reminder.startDateComponents = dateComponents
            } else {
                let dateComponents = calendar.dateComponents([.year, .month, .day], from: startDate)
                reminder.startDateComponents = dateComponents
            }
        }
        if let endDate = activity.endDate {
            let calendar = Calendar.current
            if activity.hasDeadlineTime ?? false {
                let dateComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: endDate)
                reminder.dueDateComponents = dateComponents
            } else {
                let dateComponents = calendar.dateComponents([.year, .month, .day], from: endDate)
                reminder.dueDateComponents = dateComponents
            }
        }
        reminder.isCompleted = activity.isCompleted ?? false
        if let completedDate = activity.completedDate {
            reminder.completionDate = Date(timeIntervalSince1970: completedDate.doubleValue)
        }
        reminder.notes = activity.activityDescription ?? ""

        if let recurrences = activity.recurrences, let recurrenceRule = RecurrenceRule(rruleString: recurrences[0]), let frequency = EKRecurrenceFrequency(rawValue: recurrenceRule.frequency.number) {
            var daysOfTheWeek = [EKRecurrenceDayOfWeek]()
            for dayy in recurrenceRule.byweekday {
                daysOfTheWeek.append(EKRecurrenceDayOfWeek.init(dayy))
            }

            var daysOfTheMonth = [NSNumber]()
            for dayy in recurrenceRule.bymonthday {
                daysOfTheMonth.append(NSNumber(value: dayy))
            }

            var monthsOfTheYear = [NSNumber]()
            for month in recurrenceRule.bymonth {
                monthsOfTheYear.append(NSNumber(value: month))
            }

            var weeksOfTheYear = [NSNumber]()
            for week in recurrenceRule.byweekno {
                weeksOfTheYear.append(NSNumber(value: week))
            }

            var daysOfTheYear = [NSNumber]()
            for dayy in recurrenceRule.byyearday {
                daysOfTheYear.append(NSNumber(value: dayy))
            }

            var setPositions = [NSNumber]()
            for setPos in recurrenceRule.bysetpos {
                setPositions.append(NSNumber(value: setPos))
            }

            reminder.recurrenceRules = [EKRecurrenceRule(recurrenceWith: frequency, interval: recurrenceRule.interval, daysOfTheWeek: daysOfTheWeek, daysOfTheMonth: daysOfTheMonth, monthsOfTheYear: monthsOfTheYear, weeksOfTheYear: weeksOfTheYear, daysOfTheYear: daysOfTheYear, setPositions: setPositions, end: recurrenceRule.recurrenceEnd)]

        }
        
        if let value = UserDefaults.standard.string(forKey: "PlotAppleList"), let calendar = eventStore.calendar(withIdentifier: value) {
            reminder.calendar = calendar
            do {
                try eventStore.save(reminder, commit: true)
            }
            catch let error as NSError {
                print("Failed to save iOS calendar event with error : \(error)")
            }
        } else if let calendar = createPlotList() {
            reminder.calendar = calendar
            do {
                try eventStore.save(reminder, commit: true)
            }
            catch let error as NSError {
                print("Failed to save iOS calendar event with error : \(error)")
            }
        }
        
        return reminder
    }

    func updateReminder(for activity: Activity) {
        guard let reminderID = activity.externalActivityID, let name = activity.name else {
            return
        }

        let existingReminder = eventStore.calendarItem(withIdentifier: reminderID)
        if let reminder = existingReminder as? EKReminder {
            reminder.title = name
            if let startDate = activity.startDate {
                let calendar = Calendar.current
                if activity.hasStartTime ?? false {
                    let dateComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: startDate)
                    reminder.startDateComponents = dateComponents
                } else {
                    let dateComponents = calendar.dateComponents([.year, .month, .day], from: startDate)
                    reminder.startDateComponents = dateComponents
                }
            }
            if let endDate = activity.endDate {
                let calendar = Calendar.current
                if activity.hasDeadlineTime ?? false {
                    let dateComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: endDate)
                    reminder.dueDateComponents = dateComponents
                } else {
                    let dateComponents = calendar.dateComponents([.year, .month, .day], from: endDate)
                    reminder.dueDateComponents = dateComponents
                }
            }
            reminder.isCompleted = activity.isCompleted ?? false
            if let completedDate = activity.completedDate {
                reminder.completionDate = Date(timeIntervalSince1970: completedDate.doubleValue)
            }
            reminder.notes = activity.activityDescription ?? ""

            if let recurrences = activity.recurrences, let recurrenceRule = RecurrenceRule(rruleString: recurrences[0]), let frequency = EKRecurrenceFrequency(rawValue: recurrenceRule.frequency.number) {
                var daysOfTheWeek = [EKRecurrenceDayOfWeek]()
                for dayy in recurrenceRule.byweekday {
                    daysOfTheWeek.append(EKRecurrenceDayOfWeek.init(dayy))
                }

                var daysOfTheMonth = [NSNumber]()
                for dayy in recurrenceRule.bymonthday {
                    daysOfTheMonth.append(NSNumber(value: dayy))
                }

                var monthsOfTheYear = [NSNumber]()
                for month in recurrenceRule.bymonth {
                    monthsOfTheYear.append(NSNumber(value: month))
                }

                var weeksOfTheYear = [NSNumber]()
                for week in recurrenceRule.byweekno {
                    weeksOfTheYear.append(NSNumber(value: week))
                }

                var daysOfTheYear = [NSNumber]()
                for dayy in recurrenceRule.byyearday {
                    daysOfTheYear.append(NSNumber(value: dayy))
                }

                var setPositions = [NSNumber]()
                for setPos in recurrenceRule.bysetpos {
                    setPositions.append(NSNumber(value: setPos))
                }

                reminder.recurrenceRules = [EKRecurrenceRule(recurrenceWith: frequency, interval: recurrenceRule.interval, daysOfTheWeek: daysOfTheWeek, daysOfTheMonth: daysOfTheMonth, monthsOfTheYear: monthsOfTheYear, weeksOfTheYear: weeksOfTheYear, daysOfTheYear: daysOfTheYear, setPositions: setPositions, end: recurrenceRule.recurrenceEnd)]
            }

            do {
                try eventStore.save(reminder, commit: true)
            }
            catch let error as NSError {
                print("Failed to save iOS calendar event with error : \(error)")
            }
        }
    }

    func deleteReminder(for activity: Activity) {
        guard let reminderID = activity.externalActivityID else {
            return
        }

        if let reminder = eventStore.calendarItem(withIdentifier: reminderID) as? EKReminder {
            do {
                try eventStore.remove(reminder, commit: true)
            }
            catch let error as NSError {
                print("Failed to save iOS calendar event with error : \(error)")
            }
        }
    }

    func createPlotList() -> EKCalendar? {
        let calendar = EKCalendar(for: .reminder, eventStore: eventStore)
        calendar.title = "Plot"
        calendar.cgColor = UIColor.systemBlue.cgColor

        guard let source = bestPossibleEKReminderSource() else {
            return nil
        }
        calendar.source = source
        do {
            try eventStore.saveCalendar(calendar, commit: true)
            UserDefaults.standard.set(calendar.calendarIdentifier, forKey: "PlotAppleList")
        } catch let error as NSError {
            print("Failed to save iOS calendar with error : \(error)")
        }
        return calendar
    }

    func bestPossibleEKReminderSource() -> EKSource? {
        let `default` = eventStore.defaultCalendarForNewReminders()?.source
        let iCloud = eventStore.sources.first(where: { $0.title == "iCloud" }) // this is fragile, user can rename the source
        let local = eventStore.sources.first(where: { $0.sourceType == .local })

        return `default` ?? iCloud ?? local
    }
}
