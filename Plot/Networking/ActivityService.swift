//
//  ActivityService.swift
//  Plot
//
//  Created by Cory McHattie on 12/24/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import Foundation
import Firebase
import GoogleSignIn
import CodableFirebase

extension NSNotification.Name {
    static let eventsUpdated = NSNotification.Name(Bundle.main.bundleIdentifier! + ".eventsUpdated")
    static let eventsNoRepeatsUpdated = NSNotification.Name(Bundle.main.bundleIdentifier! + ".eventsNoRepeatsUpdated")
    static let tasksUpdated = NSNotification.Name(Bundle.main.bundleIdentifier! + ".tasksUpdated")
    static let tasksNoRepeatsUpdated = NSNotification.Name(Bundle.main.bundleIdentifier! + ".tasksNoRepeatsUpdated")
    static let goalsUpdated = NSNotification.Name(Bundle.main.bundleIdentifier! + ".goalsUpdated")
    static let goalsNoRepeatsUpdated = NSNotification.Name(Bundle.main.bundleIdentifier! + ".goalsNoRepeatsUpdated")
    static let invitationsUpdated = NSNotification.Name(Bundle.main.bundleIdentifier! + ".invitationsUpdated")
    static let calendarsUpdated = NSNotification.Name(Bundle.main.bundleIdentifier! + ".calendarsUpdated")
    static let listsUpdated = NSNotification.Name(Bundle.main.bundleIdentifier! + ".listsUpdated")
    static let calendarActivitiesUpdated = NSNotification.Name(Bundle.main.bundleIdentifier! + ".calendarActivitiesUpdated")
    static let hasLoadedCalendarEventActivities = NSNotification.Name(Bundle.main.bundleIdentifier! + ".hasLoadedCalendarEventActivities")
    static let hasLoadedListTaskActivities = NSNotification.Name(Bundle.main.bundleIdentifier! + ".hasLoadedListTaskActivities")
    static let timeDataIsSetup = NSNotification.Name(Bundle.main.bundleIdentifier! + ".timeDataIsSetup")

}

class ActivityService {
    let activitiesFetcher = ActivitiesFetcher()
    let invitationsFetcher = InvitationsFetcher()
    let calendarFetcher = CalendarFetcher()
    let listFetcher = ListFetcher()
    
    var askedforCalendarAuthorization: Bool = false
    var askedforReminderAuthorization: Bool = false
    
    var dataIsSetup = false {
        didSet {
            if dataIsSetup {
                NotificationCenter.default.post(name: .timeDataIsSetup, object: nil)
            }
        }
    }
    
    var activities = [Activity]() {
        didSet {
            print("activities didSet")
            if oldValue != activities {
                print("oldValue != activities")
                eventsNoRepeats = activities.filter { $0.isTask == nil }
                tasksNoRepeats = activities.filter { $0.isTask ?? false && !($0.isGoal ?? false) }
                goalsNoRepeats = activities.filter { $0.isGoal ?? false }
            }
        }
    }
    
    var activitiesWithRepeats = [Activity]() {
        didSet {
            if oldValue != activitiesWithRepeats {
                self.events = activitiesWithRepeats.filter { $0.isTask == nil }
                self.tasks = activitiesWithRepeats.filter { $0.isTask ?? false && !($0.isGoal ?? false) }
                self.goals = activitiesWithRepeats.filter { $0.isGoal ?? false }
                self.calendarActivities = activitiesWithRepeats.filter { $0.finalDateForDisplay != nil && !($0.isGoal ?? false) }
                self.scheduleReminder(activities: activitiesWithRepeats)
                self.deleteActivities(activities: activitiesWithRepeats)
            }
        }
    }
    
    var events = [Activity]() {
        didSet {
            if oldValue != events {
                let currentDate = Date().localTime
                events.sort { (event1, event2) -> Bool in
                    if currentDate.isBetween(event1.startDate ?? Date.distantPast, and: event1.endDate ?? Date.distantPast) && currentDate.isBetween(event2.startDate ?? Date.distantPast, and: event2.endDate ?? Date.distantPast) {
                        return event1.startDate ?? Date.distantPast < event2.startDate ?? Date.distantPast
                    } else if currentDate.isBetween(event1.startDate ?? Date.distantPast, and: event1.endDate ?? Date.distantPast) {
                        return currentDate < event2.startDate ?? Date.distantPast
                    } else if currentDate.isBetween(event2.startDate ?? Date.distantPast, and: event2.endDate ?? Date.distantPast) {
                        return event1.startDate ?? Date.distantPast < currentDate
                    }
                    return event1.startDate ?? Date.distantPast < event2.startDate ?? Date.distantPast
                }
                NotificationCenter.default.post(name: .eventsUpdated, object: nil)
            }
        }
    }
    //for Apple/Google Calendar functions
    var eventsNoRepeats = [Activity]() {
        didSet {
            if oldValue != eventsNoRepeats {
                let currentDate = Date().localTime
                eventsNoRepeats.sort { (event1, event2) -> Bool in
                    if currentDate.isBetween(event1.startDate ?? Date.distantPast, and: event1.endDate ?? Date.distantPast) && currentDate.isBetween(event2.startDate ?? Date.distantPast, and: event2.endDate ?? Date.distantPast) {
                        return event1.startDate ?? Date.distantPast < event2.startDate ?? Date.distantPast
                    } else if currentDate.isBetween(event1.startDate ?? Date.distantPast, and: event1.endDate ?? Date.distantPast) {
                        return currentDate < event2.startDate ?? Date.distantPast
                    } else if currentDate.isBetween(event2.startDate ?? Date.distantPast, and: event2.endDate ?? Date.distantPast) {
                        return event1.startDate ?? Date.distantPast < currentDate
                    }
                    return event1.startDate ?? Date.distantPast < event2.startDate ?? Date.distantPast
                }
                NotificationCenter.default.post(name: .eventsNoRepeatsUpdated, object: nil)
            }
        }
    }
    
    var tasks = [Activity]() {
        didSet {
            if oldValue != tasks {
                tasks.sort { task1, task2 in
                    if !(task1.isCompleted ?? false) && !(task2.isCompleted ?? false) {
                        if task1.endDate ?? Date.distantFuture == task2.endDate ?? Date.distantFuture {
                            return task1.name ?? "" < task2.name ?? ""
                        }
                        return task1.endDate ?? Date.distantFuture < task2.endDate ?? Date.distantFuture
                    } else if task1.isCompleted ?? false && task2.isCompleted ?? false {
                        if task1.completedDate ?? 0 == task2.completedDate ?? 0 {
                            return task1.name ?? "" < task2.name ?? ""
                        }
                        return Int(truncating: task1.completedDate ?? 0) > Int(truncating: task2.completedDate ?? 0)
                    }
                    return !(task1.isCompleted ?? false)
                }
                NotificationCenter.default.post(name: .tasksUpdated, object: nil)
            }
        }
    }
    //for Apple/Google Task functions
    var tasksNoRepeats = [Activity]() {
        didSet {
            if oldValue != tasksNoRepeats {
                tasksNoRepeats.sort { task1, task2 in
                    if !(task1.isCompleted ?? false) && !(task2.isCompleted ?? false) {
                        if task1.endDate ?? Date.distantFuture == task2.endDate ?? Date.distantFuture {
                            return task1.name ?? "" < task2.name ?? ""
                        }
                        return task1.endDate ?? Date.distantFuture < task2.endDate ?? Date.distantFuture
                    } else if task1.isCompleted ?? false && task2.isCompleted ?? false {
                        if task1.completedDate ?? 0 == task2.completedDate ?? 0 {
                            return task1.name ?? "" < task2.name ?? ""
                        }
                        return Int(truncating: task1.completedDate ?? 0) > Int(truncating: task2.completedDate ?? 0)
                    }
                    return !(task1.isCompleted ?? false)
                }
                NotificationCenter.default.post(name: .tasksNoRepeatsUpdated, object: nil)
            }
        }
    }
    
    var goals = [Activity]() {
        didSet {
            if oldValue != goals {
                goals.sort { goal1, goal2 in
                    if goal1.endDate == goal2.endDate {
                        return goal1.name ?? "" < goal2.name ?? ""
                    }
                    return goal1.endDate ?? Date.distantFuture < goal2.endDate ?? Date.distantFuture
                }
                NotificationCenter.default.post(name: .goalsUpdated, object: nil)
            }
        }
    }
    //for Apple/Google Task functions
    var goalsNoRepeats = [Activity]() {
        didSet {
            if oldValue != goalsNoRepeats {
                goalsNoRepeats.sort { goal1, goal2 in
                    if goal1.endDate == goal2.endDate {
                        return goal1.name ?? "" < goal2.name ?? ""
                    }
                    return goal1.endDate ?? Date.distantFuture < goal2.endDate ?? Date.distantFuture
                }
                NotificationCenter.default.post(name: .goalsNoRepeatsUpdated, object: nil)
            }
        }
    }
    
    var calendarActivities = [Activity]() {
        didSet {
            let currentDate = Date().localTime
            calendarActivities.sort { (activity1, activity2) -> Bool in
                if let startDate1 = activity1.startDate, let endDate1 = activity1.endDate, let startDate2 = activity2.startDate, let endDate2 = activity2.endDate, !(activity1.isGoal ?? false), !(activity2.isGoal ?? false) {
                    if currentDate.isBetween(startDate1, and: endDate1) && currentDate.isBetween(startDate2, and: endDate2) {
                        return startDate1 < startDate2
                    } else if currentDate.isBetween(startDate1, and: endDate1) {
                        return currentDate < startDate2
                    } else if currentDate.isBetween(startDate2, and: endDate2) {
                        return startDate1 < currentDate
                    }
                } else if let startDate1 = activity1.startDate, let endDate1 = activity1.endDate, !(activity1.isGoal ?? false), let finalDate2 = activity2.finalDateForDisplay {
                    if currentDate.isBetween(startDate1, and: endDate1) {
                        return currentDate < finalDate2
                    }
                    return startDate1 < finalDate2
                } else if let finalDate1 = activity1.finalDateForDisplay, let startDate2 = activity2.startDate, let endDate2 = activity2.endDate, !(activity2.isGoal ?? false) {
                    if currentDate.isBetween(startDate2, and: endDate2) {
                        return finalDate1 < currentDate
                    }
                    return finalDate1 < startDate2
                }
                if activity1.finalDateForDisplay == activity2.finalDateForDisplay {
                    return activity1.name ?? "" < activity2.name ?? ""
                }
                return activity1.finalDateForDisplay ?? Date.distantPast < activity2.finalDateForDisplay ?? Date.distantPast
            }
            NotificationCenter.default.post(name: .calendarActivitiesUpdated, object: nil)
        }
    }
    
    var invitations: [String: Invitation] = [:] {
        didSet {
            if oldValue != invitations {
                NotificationCenter.default.post(name: .invitationsUpdated, object: nil)
            }
        }
    }
    var invitedActivities = [Activity]()
    
    var calendars = [String: [CalendarType]]() {
        didSet {
            if oldValue != calendars {
                for (_, calendarList) in calendars {
                    for calendar in calendarList {
                        if let id = calendar.id {
                            calendarIDs[id] = calendar
                        }
                    }
                }
                NotificationCenter.default.post(name: .calendarsUpdated, object: nil)
            }
        }
    }
    var lists = [String: [ListType]]() {
        didSet {
            if oldValue != lists {
                for (_, listList) in lists {
                    for list in listList {
                        if let id = list.id {
                            listIDs[id] = list
                        }
                    }
                }
                NotificationCenter.default.post(name: .listsUpdated, object: nil)
            }
        }
    }
    var hasLoadedCalendarEventActivities = false {
        didSet {
            NotificationCenter.default.post(name: .hasLoadedCalendarEventActivities, object: nil)
        }
    }
    var hasLoadedListTaskActivities = false {
        didSet {
            NotificationCenter.default.post(name: .hasLoadedListTaskActivities, object: nil)
        }
    }

    var calendarIDs = [String: CalendarType]()
    var listIDs = [String: ListType]()
    
    var primaryCalendar = String()
    var primaryList = String()
    
    var eventKitManager: EventKitManager = {
        let eventKitService = EventKitService()
        let eventKitManager = EventKitManager(eventKitService: eventKitService)
        return eventKitManager
    }()
    
    var googleCalManager: GoogleCalManager = {
        let googleCalService = GoogleCalService()
        let googleCalManager = GoogleCalManager(googleCalService: googleCalService)
        return googleCalManager
    }()
    
    var isRunning: Bool = true
    fileprivate let plotAppGroup = "group.immaturecreations.plot"
    fileprivate var sharedContainer : UserDefaults?
    
    func grabActivities(_ completion: @escaping () -> Void) {
        self.observeActivitiesForCurrentUser({
            self.observeCalendarsForCurrentUser()
            self.observeListsForCurrentUser()
            if self.isRunning {
                self.grabOtherActivities()
                self.isRunning = false
                completion()
            }
        })
    }
    
    func grabOtherActivities() {
        self.observeInvitationForCurrentUser()
        self.grabPrimaryCalendar({ (calendar) in
            if calendar == CalendarSourceOptions.apple.name {
                self.grabEKEvents {
                    self.hasLoadedCalendarEventActivities = true
                }
            } else if calendar == CalendarSourceOptions.google.name {
                self.grabGEvents {
                    self.hasLoadedCalendarEventActivities = true
                }
            } else {
                self.hasLoadedCalendarEventActivities = true
            }
            self.grabCalendars()
        })
        self.grabPrimaryList({ (list) in
            if list == ListSourceOptions.apple.name {
                self.grabEKReminders {
                    self.hasLoadedListTaskActivities = true
                }
            } else if list == ListSourceOptions.google.name {
                self.grabGTasks {
                    self.hasLoadedListTaskActivities = true
                }
            } else {
                self.hasLoadedListTaskActivities = true
            }
            self.grabLists()
        })
        self.saveDataToSharedContainer(activities: self.activities)
    }
    
    func setupFirebase(_ completion: @escaping () -> Void) {
        self.observeActivitiesForCurrentUser({
            self.observeCalendarsForCurrentUser()
            self.observeListsForCurrentUser()
            self.observeInvitationForCurrentUser()
            self.hasLoadedCalendarEventActivities = true
            self.hasLoadedListTaskActivities = true
            completion()
        })
    }
    
    func regrabActivities(_ completion: @escaping () -> Void) {
        let dispatchGroup = DispatchGroup()
        
        dispatchGroup.enter()
        regrabLists {
            dispatchGroup.leave()
        }
        
        dispatchGroup.enter()
        regrabEvents {
            dispatchGroup.leave()
        }
        
        dispatchGroup.notify(queue: .main) {
            completion()
        }
    }
    
    func regrabEvents(_ completion: @escaping () -> Void) {
        hasLoadedCalendarEventActivities = false
        if primaryCalendar == CalendarSourceOptions.apple.name {
            self.grabEKEvents {
                self.grabCalendars()
                self.hasLoadedCalendarEventActivities = true
                completion()
            }
        } else if primaryCalendar == CalendarSourceOptions.google.name {
            self.grabGEvents {
                self.grabCalendars()
                self.hasLoadedCalendarEventActivities = true
                completion()
            }
        } else {
            self.grabCalendars()
            self.hasLoadedCalendarEventActivities = true
            completion()
        }
    }
    
    func regrabLists(_ completion: @escaping () -> Void) {
        hasLoadedListTaskActivities = false
        if primaryList == ListSourceOptions.apple.name {
            self.grabEKReminders {
                self.grabLists()
                self.hasLoadedListTaskActivities = true
                completion()
            }
        } else if primaryList == ListSourceOptions.google.name {
            self.grabGTasks {
                self.grabLists()
                self.hasLoadedListTaskActivities = true
                completion()
            }
        } else {
            self.grabLists()
            self.hasLoadedListTaskActivities = true
            completion()
        }
    }
    
    func observeActivitiesForCurrentUser(_ completion: @escaping () -> Void) {
        activitiesFetcher.observeActivityForCurrentUser(activitiesInitialAdd: { [weak self] activitiesInitialAdd in
            if !activitiesInitialAdd.isEmpty {
                if self?.activities.isEmpty ?? true {
                    self?.activities = activitiesInitialAdd
                } else {
                    for activity in activitiesInitialAdd {
                        if let index = self?.activities.firstIndex(where: {$0.activityID == activity.activityID}) {
                            self?.activities[index] = activity
                        } else {
                            self?.activities.append(activity)
                        }
                    }
                }
            }
        }, activitiesWithRepeatsInitialAdd: { [weak self] activitiesWithRepeatsInitialAdd in
            if !activitiesWithRepeatsInitialAdd.isEmpty {
                if self?.activitiesWithRepeats.isEmpty ?? true {
                    self?.activitiesWithRepeats = activitiesWithRepeatsInitialAdd
                    completion()
                } else {
                    if activitiesWithRepeatsInitialAdd.count == 1, let activity = activitiesWithRepeatsInitialAdd.first, let instanceID = activity.instanceID {
                        self?.activitiesWithRepeats.removeAll(where: { $0.instanceID == instanceID })
                        self?.activitiesWithRepeats.append(activity)
                    } else {
                        let activityIDs = Array(Set(activitiesWithRepeatsInitialAdd.compactMap({ $0.activityID })))
                        for activityID in activityIDs {
                            self?.activitiesWithRepeats.removeAll(where: { $0.activityID == activityID })
                        }
                        self?.activitiesWithRepeats.append(contentsOf: activitiesWithRepeatsInitialAdd)
                    }
                }
            } else {
                completion()
            }
        }, activitiesAdded: { [weak self] activitiesAdded in
            for activity in activitiesAdded {
                //remove activities from repeatActivities in case recurrences is updated
                if let index = self?.activities.firstIndex(where: {$0.activityID == activity.activityID}) {
                    self?.activities[index] = activity
                } else {
                    self?.activities.append(activity)
                }
            }
        }, activitiesWithRepeatsAdded: { [weak self] activitiesWithRepeatsAdded in
            if activitiesWithRepeatsAdded.count == 1, let activity = activitiesWithRepeatsAdded.first, let instanceID = activity.instanceID {
                self?.activitiesWithRepeats.removeAll(where: { $0.instanceID == instanceID })
                self?.activitiesWithRepeats.append(activity)
            } else {
                let activityIDs = Array(Set(activitiesWithRepeatsAdded.compactMap({ $0.activityID })))
                for activityID in activityIDs {
                    self?.activitiesWithRepeats.removeAll(where: { $0.activityID == activityID })
                }
                self?.activitiesWithRepeats.append(contentsOf: activitiesWithRepeatsAdded)
            }
        }, activitiesRemoved: { [weak self] activitiesRemoved in
            self?.activities.removeAll(where: { $0.activityID == activitiesRemoved.first?.activityID })
            self?.activitiesWithRepeats.removeAll(where: { $0.activityID == activitiesRemoved.first?.activityID })
            self?.deleteReminder(activities: activitiesRemoved)
        }, activitiesChanged: { [weak self] activitiesChanged in
            for activity in activitiesChanged {
                if let index = self?.activities.firstIndex(where: {$0.activityID == activity.activityID}) {
                    self?.activities[index] = activity
                } else {
                    self?.activities.append(activity)
                }
            }
        }, activitiesWithRepeatsChanged: { [weak self] activitiesWithRepeatsChanged in
            if activitiesWithRepeatsChanged.count == 1, let activity = activitiesWithRepeatsChanged.first, let instanceID = activity.instanceID {
                self?.activitiesWithRepeats.removeAll(where: { $0.instanceID == instanceID })
                self?.activitiesWithRepeats.append(activity)
            } else {
                let activityIDs = Array(Set(activitiesWithRepeatsChanged.compactMap({ $0.activityID })))
                for activityID in activityIDs {
                    self?.activitiesWithRepeats.removeAll(where: { $0.activityID == activityID })
                }
                self?.activitiesWithRepeats.append(contentsOf: activitiesWithRepeatsChanged)
            }
        })
    }
    
    func grabEKEvents(_ completion: @escaping () -> Void) {
        guard Auth.auth().currentUser != nil else {
            return completion()
        }
        self.eventKitManager.checkEventAuthorizationStatus {
            if self.eventKitManager.eventAuthorizationStatus != "restricted" {
                self.eventKitManager.authorizeEventKitEvents({ askedforAuthorization in
                    self.askedforCalendarAuthorization = askedforAuthorization
                    self.eventKitManager.syncEventKitActivities(existingActivities: self.eventsNoRepeats, completion: {
                        self.eventKitManager.syncActivitiesToEventKit(activities: self.eventsNoRepeats, completion: {
                            completion()
                        })
                    })
                })
            }
        }
    }
    
    func grabEKReminders(_ completion: @escaping () -> Void) {
        guard Auth.auth().currentUser != nil else {
            return completion()
        }
        self.eventKitManager.checkReminderAuthorizationStatus {
            if self.eventKitManager.reminderAuthorizationStatus != "restricted" {
                self.eventKitManager.authorizeEventKitReminders({ askedforAuthorization in
                    self.dataIsSetup = true
                    self.askedforReminderAuthorization = askedforAuthorization
                    self.eventKitManager.syncEventKitReminders(existingActivities: self.tasksNoRepeats, completion: {
                        self.eventKitManager.syncTasksToEventKit(activities: self.tasksNoRepeats, completion: {
                            completion()
                        })
                    })
                })
            }
        }
    }
    
    func grabGEvents(_ completion: @escaping () -> Void) {
        guard Auth.auth().currentUser != nil else {
            return completion()
        }
        self.googleCalManager.authorizeGEvents { askedforCalendarAuthorization in
            self.askedforCalendarAuthorization = askedforCalendarAuthorization
            self.googleCalManager.syncGoogleCalActivities(existingActivities: self.eventsNoRepeats, completion: {
                self.googleCalManager.syncActivitiesToGoogleCal(activities: self.eventsNoRepeats, completion: {
                    completion()
                })
            })
        }
    }
    
    func grabGTasks(_ completion: @escaping () -> Void) {
        guard Auth.auth().currentUser != nil else {
            return completion()
        }
        self.googleCalManager.authorizeGReminders { askedforReminderAuthorization in
            self.askedforReminderAuthorization = askedforReminderAuthorization
            self.googleCalManager.syncGoogleCalTasks(existingActivities: self.tasksNoRepeats, completion: {
                self.googleCalManager.syncTasksToGoogleTasks(activities: self.tasksNoRepeats, completion: {
                    completion()
                })
            })
        }
    }
    
    func grabCalendars() {
        if let _ = Auth.auth().currentUser {
            self.eventKitManager.checkEventAuthorizationStatus {
                if self.eventKitManager.eventAuthorizationStatus == "authorized" {
                    self.eventKitManager.authorizeEventKitEvents { _ in
                        if let calendars = self.eventKitManager.grabCalendars() {
                            self.calendars[CalendarSourceOptions.apple.name] = calendars
                        }
                    }
                }
            }
            
            self.googleCalManager.authorizeGEvents { _ in
                self.googleCalManager.grabCalendars() { calendars in
                    if let calendars = calendars {
                        self.calendars[CalendarSourceOptions.google.name] = calendars
                    }
                }
            }
        }
    }
    
    func observeCalendarsForCurrentUser() {
        self.calendarFetcher.observeCalendarForCurrentUser(calendarInitialAdd: { [weak self] calendarInitialAdd in
            if self?.calendars[CalendarSourceOptions.plot.name] != nil {
                var plotCalendars = self?.calendars[CalendarSourceOptions.plot.name]
                for calendar in calendarInitialAdd {
                    if let index = plotCalendars!.firstIndex(where: { $0.id == calendar.id}) {
                        plotCalendars![index] = calendar
                    } else {
                        plotCalendars!.append(calendar)
                    }
                }
                self?.calendars[CalendarSourceOptions.plot.name] = plotCalendars
            } else {
                self?.calendars[CalendarSourceOptions.plot.name] = calendarInitialAdd
                self?.grabCalendarEvents()
            }
        }, calendarAdded: { [weak self] calendarAdded in
            if self?.calendars[CalendarSourceOptions.plot.name] != nil {
                var plotCalendars = self?.calendars[CalendarSourceOptions.plot.name]
                for calendar in calendarAdded {
                    if let index = plotCalendars!.firstIndex(where: { $0.id == calendar.id}) {
                        plotCalendars![index] = calendar
                    } else {
                        plotCalendars!.append(calendar)
                    }
                }
                self?.calendars[CalendarSourceOptions.plot.name] = plotCalendars
            } else {
                self?.calendars[CalendarSourceOptions.plot.name] = calendarAdded
            }
        }, calendarRemoved: { [weak self] calendarRemoved in
            if self?.calendars[CalendarSourceOptions.plot.name] != nil {
                var plotCalendars = self?.calendars[CalendarSourceOptions.plot.name]
                for calendar in calendarRemoved {
                    plotCalendars = plotCalendars?.filter({$0.id != calendar.id})
                }
                self?.calendars[CalendarSourceOptions.plot.name] = plotCalendars
            }
        }, calendarChanged: { [weak self] calendarChanged in
            if self?.calendars[CalendarSourceOptions.plot.name] != nil {
                var plotCalendars = self?.calendars[CalendarSourceOptions.plot.name]
                for calendar in calendarChanged {
                    if let index = plotCalendars!.firstIndex(where: { $0.id == calendar.id }) {
                        plotCalendars![index] = calendar
                    } else {
                        plotCalendars!.append(calendar)
                    }
                }
                self?.calendars[CalendarSourceOptions.plot.name] = plotCalendars
            }
        })
    }
    
    func grabPrimaryCalendar(_ completion: @escaping (String) -> Void) {
        if let currentUserID = Auth.auth().currentUser?.uid {
            let reference = Database.database().reference().child(userCalendarEventsEntity).child(currentUserID).child(primaryCalendarKey)
            reference.observeSingleEvent(of: .value, with: { (snapshot) in
                if snapshot.exists(), let value = snapshot.value as? String {
                    self.primaryCalendar = value
                    completion(value)
                } else {
                    completion("none")
                }
            })
        }
    }
    
    func updatePrimaryCalendar(value: String) {
        if let currentUserID = Auth.auth().currentUser?.uid {
            let reference = Database.database().reference().child(userCalendarEventsEntity).child(currentUserID).child(primaryCalendarKey)
            reference.observeSingleEvent(of: .value, with: { (snapshot) in
                if !snapshot.exists() {
                    self.updatePrimaryCalendarFB(value: value)
                } else {
                    self.runCalendarFunctions(value: value)
                }
            })
        }
    }
    
    func runCalendarFunctions(value: String) {
        if !askedforCalendarAuthorization {
            regrabEvents {}
        } else {
            if value == primaryCalendar && value == CalendarSourceOptions.apple.name {
                grabEKEvents {
                    self.grabCalendars()
                }
            } else if value == primaryCalendar && value == CalendarSourceOptions.google.name {
                grabGEvents {
                    self.grabCalendars()
                }
            } else if value != primaryCalendar && value == CalendarSourceOptions.apple.name {
                grabEKEvents {
                    self.grabCalendars()
                }
            } else if value != primaryCalendar && value == CalendarSourceOptions.google.name {
                grabGEvents {
                    self.grabCalendars()
                }
            }
        }
    }
    
    func updatePrimaryCalendarFB(value: String) {
        if let currentUserID = Auth.auth().currentUser?.uid {
            self.primaryCalendar = value
            self.runCalendarFunctions(value: value)
            let reference = Database.database().reference().child(userCalendarEventsEntity).child(currentUserID).child(primaryCalendarKey)
            reference.setValue(value)
        }
    }
    
    func grabLists() {
        if let _ = Auth.auth().currentUser {
            self.eventKitManager.checkReminderAuthorizationStatus {
                if self.eventKitManager.reminderAuthorizationStatus == "authorized" {
                    self.eventKitManager.authorizeEventKitReminders { _ in
                        if let lists = self.eventKitManager.grabLists() {
                            self.lists[ListSourceOptions.apple.name] = lists
                        }
                    }
                }
            }
            self.googleCalManager.authorizeGReminders { _ in
                self.googleCalManager.grabLists() { lists in
                    if let lists = lists {
                        self.lists[ListSourceOptions.google.name] = lists
                    }
                }
            }
        }
    }
    
    func observeListsForCurrentUser() {
        self.listFetcher.observeListForCurrentUser(listInitialAdd: { [weak self] listInitialAdd in
            if self?.lists[ListSourceOptions.plot.name] != nil {
                var plotLists = self?.lists[ListSourceOptions.plot.name]
                for list in listInitialAdd {
                    if let index = plotLists?.firstIndex(where: { $0.id == list.id}) {
                        plotLists![index] = list
                    } else {
                        plotLists!.append(list)
                    }
                }
                self?.lists[ListSourceOptions.plot.name] = plotLists
            } else {
                self?.lists[ListSourceOptions.plot.name] = listInitialAdd
                self?.grabListTasks()
            }
        }, listAdded: { [weak self] listAdded in
            if self?.lists[ListSourceOptions.plot.name] != nil {
                var plotLists = self?.lists[ListSourceOptions.plot.name]
                for list in listAdded {
                    if let index = plotLists!.firstIndex(where: { $0.id == list.id}) {
                        plotLists![index] = list
                    } else {
                        plotLists!.append(list)
                    }
                }
                self?.lists[ListSourceOptions.plot.name] = plotLists
            } else {
                self?.lists[ListSourceOptions.plot.name] = listAdded
            }
        }, listRemoved: { [weak self] listRemoved in
            if self?.lists[ListSourceOptions.plot.name] != nil {
                var plotLists = self?.lists[ListSourceOptions.plot.name]
                for list in listRemoved {
                    plotLists = plotLists!.filter({$0.id != list.id})
                }
                self?.lists[ListSourceOptions.plot.name] = plotLists
            }
        }, listChanged: { [weak self] listChanged in
            if self?.lists[ListSourceOptions.plot.name] != nil {
                var plotLists = self?.lists[ListSourceOptions.plot.name]
                for list in listChanged {
                    if let index = plotLists!.firstIndex(where: { $0.id == list.id}) {
                        plotLists![index] = list
                    } else {
                        plotLists!.append(list)
                    }
                }
                self?.lists[ListSourceOptions.plot.name] = plotLists
            }
        })
    }
    
    func grabPrimaryList(_ completion: @escaping (String) -> Void) {
        if let currentUserID = Auth.auth().currentUser?.uid {
            let reference = Database.database().reference().child(userReminderTasksEntity).child(currentUserID).child(primaryReminderKey)
            reference.observeSingleEvent(of: .value, with: { (snapshot) in
                if snapshot.exists(), let value = snapshot.value as? String {
                    self.primaryList = value
                    completion(value)
                } else {
                    completion("none")
                }
            })
        }
    }
    
    func updatePrimaryList(value: String) {
        if let currentUserID = Auth.auth().currentUser?.uid {
            let reference = Database.database().reference().child(userReminderTasksEntity).child(currentUserID).child(primaryReminderKey)
            reference.observeSingleEvent(of: .value, with: { (snapshot) in
                if !snapshot.exists() {
                    self.updatePrimaryListFB(value: value)
                } else {
                    self.runListFunctions(value: value)
                }
            })
        }
    }
    
    func runListFunctions(value: String) {
        if !askedforReminderAuthorization {
            regrabLists {}
        } else {
            if value == primaryList && value == ListSourceOptions.apple.name {
                grabEKReminders {
                    self.grabLists()
                }
            } else if value == primaryList && value == ListSourceOptions.google.name {
                grabGTasks {
                    self.grabLists()
                }
            } else if value != primaryList && value == ListSourceOptions.apple.name {
                grabEKReminders {
                    self.grabLists()
                }
            } else if value != primaryList && value == ListSourceOptions.google.name {
                grabGTasks {
                    self.grabLists()
                }
            }
        }
    }
    
    func updatePrimaryListFB(value: String) {
        if let currentUserID = Auth.auth().currentUser?.uid {
            self.primaryList = value
            self.runListFunctions(value: value)
            let reference = Database.database().reference().child(userReminderTasksEntity).child(currentUserID).child(primaryReminderKey)
            reference.setValue(value)
        }
    }
    
    func saveDataToSharedContainer(activities: [Activity]) {
        sharedContainer = UserDefaults(suiteName: plotAppGroup)
        if let sharedContainer = sharedContainer {
            var activitiesArray = [Any]()
            for activity in activities {
                let activityNSDictionary = activity.toAnyObject()
                activitiesArray.append(NSKeyedArchiver.archivedData(withRootObject: activityNSDictionary))
            }
            sharedContainer.set(activitiesArray, forKey: "ActivitiesArray")
            sharedContainer.synchronize()
        }
    }
    
    func grabCalendarEvents() {
        if let plotCalendars = self.calendars[CalendarSourceOptions.plot.name] {
            activitiesFetcher.grabActivitiesViaCalendar(calendars: plotCalendars) { [weak self] activities in
                self?.activities.append(contentsOf: activities)
            }
        }
    }
    
    func grabListTasks() {
        if let plotLists = self.lists[ListSourceOptions.plot.name] {
            activitiesFetcher.grabActivitiesViaList(lists: plotLists) { [weak self] activities in
                self?.activities.append(contentsOf: activities)
            }
        }
    }
    
    func scheduleReminder(activities: [Activity]) {
        //only 64 notifications; think about repeating ones that repeat
        let sortedActivities = activities.filter({ $0.reminder != nil && $0.endDate ?? Date() > Date().dayBefore }).sorted(by: { $0.finalDate ?? Date.distantFuture < $1.finalDate ?? Date.distantFuture})
        for activity in Array(sortedActivities.prefix(64)) {
            guard let activityReminder = activity.reminder, let activityID = activity.activityID, let endDate = activity.endDate, endDate > Date().dayBefore else {
                continue
            }
            let center = UNUserNotificationCenter.current()
            guard activityReminder != "None" else {
                center.removePendingNotificationRequests(withIdentifiers: ["\(activityID)_\(endDate)_Reminder"])
                continue
            }
            
            if activity.isTask ?? false, activity.isCompleted ?? false {
                center.removePendingNotificationRequests(withIdentifiers: ["\(activityID)_\(endDate)_Reminder"])
                continue
            }
                                                
            if let startDate = activity.startDate, let allDay = activity.allDay, let startTimeZone = activity.startTimeZone, let endTimeZone = activity.endTimeZone {
                let content = UNMutableNotificationContent()
                content.title = "\(String(describing: activity.name!)) Reminder"
                content.sound = UNNotificationSound.default
                if let reminder = EventAlert(rawValue: activityReminder) {
                    let reminderDate = startDate.addingTimeInterval(reminder.timeInterval)
                    var formattedDate: (String, String) = ("", "")
                    formattedDate = timestampOfEvent(startDate: startDate, endDate: endDate, allDay: allDay, startTimeZone: startTimeZone, endTimeZone: endTimeZone, now: reminderDate)
                    content.subtitle = formattedDate.0
                    content.categoryIdentifier = Identifiers.eventCategory
                    content.userInfo = [PlotNotification.CodingKeys.ID.rawValue: activity.instanceID ?? activityID, PlotNotification.CodingKeys.date.rawValue: activity.finalDateTime as Any]
                    var calendar = Calendar.current
                    calendar.timeZone = TimeZone(identifier: startTimeZone)!
                    let triggerDate = calendar.dateComponents([.year,.month,.day,.hour,.minute,.second], from: reminderDate)
                    let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate,
                                                                repeats: false)
                    let identifier = "\(activityID)_\(endDate)_Reminder"
                    let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
                    center.add(request, withCompletionHandler: { (error) in
                        if let error = error {
                            print("error")
                            print(error)
                        }
                    })
                }
            } else {
                let content = UNMutableNotificationContent()
                content.title = "\(String(describing: activity.name!)) Reminder"
                content.sound = UNNotificationSound.default
                if let reminder = TaskAlert(rawValue: activityReminder), let reminderDate = reminder.timeInterval(endDate) {
                    var formattedDate: (Int, String, String) = (1, "", "")
                    formattedDate = timestampOfTask(endDate: endDate, hasDeadlineTime: activity.hasDeadlineTime ?? false, startDate: activity.startDate, hasStartTime: activity.hasStartTime, now: reminderDate)
                    content.subtitle = formattedDate.2
                    content.categoryIdentifier = activity.isGoal ?? false ? Identifiers.goalCategory : Identifiers.taskCategory
                    content.userInfo = [PlotNotification.CodingKeys.ID.rawValue: activity.instanceID ?? activityID, PlotNotification.CodingKeys.date.rawValue: activity.finalDateTime as Any]
                    let calendar = Calendar.current
                    let triggerDate = calendar.dateComponents([.year,.month,.day,.hour,.minute,.second], from: reminderDate)
                    let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate,
                                                                repeats: false)
                    let identifier = "\(activityID)_\(endDate)_Reminder"
                    let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
                    center.add(request, withCompletionHandler: { (error) in
                        if let error = error {
                            print("error")
                            print(error)
                        }
                    })
                }
            }
        }
    }
    
    func scheduleSubReminder(sub_activities: [Activity], parent: Activity) {
        for sub_activity in sub_activities {
            guard let reminder = sub_activity.reminder, let sub_activity_ID = sub_activity.activityID, let endDate = sub_activity.getSubEndDate(parent: parent), endDate > Date() else {
                continue
            }
            let center = UNUserNotificationCenter.current()
            guard reminder != "None" else {
                center.removePendingNotificationRequests(withIdentifiers: ["\(sub_activity_ID)_\(endDate)_Reminder"])
                continue
            }
            
            if sub_activity.isTask ?? false, sub_activity.isCompleted ?? false {
                center.removePendingNotificationRequests(withIdentifiers: ["\(sub_activity_ID)_\(endDate)_Reminder"])
                continue
            }
            
            if let startDate = sub_activity.getSubStartDate(parent: parent), let allDay = sub_activity.allDay {
                let content = UNMutableNotificationContent()
                content.title = "\(String(describing: sub_activity.name!)) Reminder"
                content.sound = UNNotificationSound.default
                if let reminder = EventAlert(rawValue: reminder) {
                    let reminderDate = startDate.addingTimeInterval(reminder.timeInterval)
                    var formattedDate: (String, String) = ("", "")
                    formattedDate = timestampOfEvent(startDate: startDate, endDate: endDate, allDay: allDay, startTimeZone: sub_activity.startTimeZone, endTimeZone: sub_activity.endTimeZone, now: reminderDate)
                    content.subtitle = formattedDate.0
                    content.categoryIdentifier = Identifiers.eventCategory

                    var calendar = Calendar.current
                    if let timeZone = sub_activity.startTimeZone {
                        calendar.timeZone = TimeZone(identifier: timeZone)!
                    }
                    let triggerDate = calendar.dateComponents([.year,.month,.day,.hour,.minute,.second,], from: reminderDate)
                    let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate,
                                                                repeats: false)
                    let identifier = "\(sub_activity_ID)_\(endDate)_Reminder"
                    let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
                    center.add(request, withCompletionHandler: { (error) in
                        if let error = error {
                            print(error)
                        }
                    })
                }
            } else {
                let content = UNMutableNotificationContent()
                content.title = "\(String(describing: sub_activity.name!)) Reminder"
                content.sound = UNNotificationSound.default
                if let reminder = TaskAlert(rawValue: reminder), let reminderDate = reminder.timeInterval(endDate) {
                    var formattedDate: (Int, String, String) = (1, "", "")
                    formattedDate = timestampOfTask(endDate: endDate, hasDeadlineTime: sub_activity.hasDeadlineTime ?? false, startDate: sub_activity.startDate, hasStartTime: sub_activity.hasStartTime, now: reminderDate)
                    content.subtitle = formattedDate.2
                    content.categoryIdentifier = sub_activity.isGoal ?? false ? Identifiers.goalCategory : Identifiers.taskCategory
                    let calendar = Calendar.current
                    let triggerDate = calendar.dateComponents([.year,.month,.day,.hour,.minute,.second], from: reminderDate)
                    let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate,
                                                                repeats: false)
                    let identifier = "\(sub_activity_ID)_\(endDate)_Reminder"
                    let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
                    center.add(request, withCompletionHandler: { (error) in
                        if let error = error {
                            print(error)
                        }
                    })
                }
            }
        }
    }
    
    func deleteReminder(activities: [Activity]) {
        let today = Date()
        for activity in activities {
            guard let activityID = activity.activityID, let endDate = activity.endDate, endDate > today else {
                continue
            }
            let center = UNUserNotificationCenter.current()
            center.removePendingNotificationRequests(withIdentifiers: ["\(activityID)_Reminder"])
            center.removePendingNotificationRequests(withIdentifiers: ["\(activityID)_\(endDate)_Reminder"])
        }
    }
    
    func deleteSubReminder(sub_activities: [Activity], parent: Activity) {
        let today = Date()
        for sub_activity in sub_activities {
            guard let sub_activity_ID = sub_activity.activityID, let endDate = sub_activity.getSubEndDate(parent: parent), endDate > today else {
                continue
            }
            let center = UNUserNotificationCenter.current()
            center.removePendingNotificationRequests(withIdentifiers: ["\(sub_activity_ID)_Reminder"])
            center.removePendingNotificationRequests(withIdentifiers: ["\(sub_activity_ID)_\(endDate)_Reminder"])
        }
    }
    
    func deleteActivities(activities: [Activity]) {
        guard let currentUserID = Auth.auth().currentUser?.uid else {
            return
        }
        for activity in activities {
            if let participantsIDs = activity.participantsIDs, !participantsIDs.contains(currentUserID), currentUserID == activity.admin ?? "", activity.isTask ?? false, activity.listName == "Finances" {
                let activityAction = ActivityActions(activity: activity, active: true, selectedFalconUsers: [])
                activityAction.deleteActivity(updateExternal: true, updateDirectAssociation: false)
            }
        }
    }
}

// For invitations update
extension ActivityService {
    func fetchInvitations() {
        invitationsFetcher.fetchInvitations { [weak self] (invitations, activitiesForInvitations) in
            guard let weakSelf = self else { return }
            weakSelf.invitations = invitations
            weakSelf.invitedActivities = activitiesForInvitations
        }
    }
    
    func cleanCalendarEventActivities() {
        guard let currentUserID = Auth.auth().currentUser?.uid else {
            
            return
        }
        
        for activity in self.activities {
            if activity.activityType == "calendarEvent" || activity.activityType == CustomType.iOSCalendarEvent.categoryText || activity.activityType == CustomType.googleCalendarEvent.categoryText, let activityID = activity.activityID {
                let activityReference = Database.database().reference().child(activitiesEntity).child(activityID)
                let userActivityReference = Database.database().reference().child(userActivitiesEntity).child(currentUserID).child(activityID)
                activityReference.removeValue()
                userActivityReference.removeValue()
            }
        }
        let reference = Database.database().reference().child(userCalendarEventsEntity).child(currentUserID).child(calendarEventsKey)
        reference.removeValue()
    }
    
    func observeInvitationForCurrentUser() {
        self.invitationsFetcher.observeInvitationForCurrentUser(invitationsInitialAdd: { [weak self] invitationsInitialAdd, activitiesForInvitations in
            if self!.invitations.isEmpty {
                self?.invitations = invitationsInitialAdd
                self?.invitedActivities = activitiesForInvitations
            } else {
                for (activityID, invitation) in invitationsInitialAdd {
                    self?.invitations[activityID] = invitation
                }
            }
        }, invitationsAdded: { [weak self] invitationsAdded in
            for invitation in invitationsAdded {
                self?.invitations[invitation.activityID] = invitation
            }
        }, invitationsRemoved: { [weak self] invitationsRemoved in
            for invitation in invitationsRemoved {
                self?.invitations.removeValue(forKey: invitation.activityID)
            }
        })
    }
}
