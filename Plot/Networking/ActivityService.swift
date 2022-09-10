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

extension NSNotification.Name {
    static let eventsUpdated = NSNotification.Name(Bundle.main.bundleIdentifier! + ".eventsUpdated")
    static let tasksUpdated = NSNotification.Name(Bundle.main.bundleIdentifier! + ".tasksUpdated")
    static let invitationsUpdated = NSNotification.Name(Bundle.main.bundleIdentifier! + ".invitationsUpdated")
    static let calendarsUpdated = NSNotification.Name(Bundle.main.bundleIdentifier! + ".calendarsUpdated")
    static let listsUpdated = NSNotification.Name(Bundle.main.bundleIdentifier! + ".listsUpdated")
    static let hasLoadedCalendarEventActivities = NSNotification.Name(Bundle.main.bundleIdentifier! + ".hasLoadedCalendarEventActivities")
    static let hasLoadedListTaskActivities = NSNotification.Name(Bundle.main.bundleIdentifier! + ".hasLoadedListTaskActivities")
}

class ActivityService {
    let activitiesFetcher = ActivitiesFetcher()
    let invitationsFetcher = InvitationsFetcher()
    let calendarFetcher = CalendarFetcher()
    let listFetcher = ListFetcher()
    
    var askedforCalendarAuthorization: Bool = false
    var askedforReminderAuthorization: Bool = false
    
    var activities = [Activity]() {
        didSet {
            if oldValue != activities {
                events = activities.filter { $0.isTask == nil }
                tasks = activities.filter { $0.isTask ?? false }
                calendarActivities = activities.filter { $0.finalDate != nil }
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
    var eventsNoRepeats = [Activity]()
    
    var tasks = [Activity]() {
        didSet {
            if oldValue != tasks {
                tasks.sort { task1, task2 in
                    if !(task1.isCompleted ?? false) && !(task2.isCompleted ?? false) {
                        if task1.endDate ?? Date.distantPast == task2.endDate ?? Date.distantPast {
                            return task1.name ?? "" < task2.name ?? ""
                        }
                        return task1.endDate ?? Date.distantPast < task2.endDate ?? Date.distantPast
                    } else if task1.isCompleted ?? false && task2.isCompleted ?? false {
                        if task1.completedDate ?? 0 == task2.completedDate ?? 0 {
                            return task1.name ?? "" < task2.name ?? ""
                        }
                        return Int(truncating: task1.completedDate ?? 0) < Int(truncating: task2.completedDate ?? 0)
                    }
                    return !(task1.isCompleted ?? false)
                }
                NotificationCenter.default.post(name: .tasksUpdated, object: nil)
            }
        }
    }
    //for Apple/Google Task functions
    var tasksNoRepeats = [Activity]()
    
    var calendarActivities = [Activity]() {
        didSet {
            let currentDate = Date().localTime
            calendarActivities.sort { (activity1, activity2) -> Bool in
                if currentDate.isBetween(activity1.startDate ?? Date.distantPast, and: activity1.endDate ?? Date.distantPast) && currentDate.isBetween(activity2.startDate ?? Date.distantPast, and: activity2.endDate ?? Date.distantPast) {
                    return activity1.startDate ?? Date.distantPast < activity2.startDate ?? Date.distantPast
                } else if currentDate.isBetween(activity1.startDate ?? Date.distantPast, and: activity1.endDate ?? Date.distantPast) {
                    return currentDate < activity2.startDate ?? Date.distantPast
                } else if currentDate.isBetween(activity2.startDate ?? Date.distantPast, and: activity2.endDate ?? Date.distantPast) {
                    return activity1.startDate ?? Date.distantPast < currentDate
                }
                if activity1.finalDate == activity2.finalDate {
                    return activity1.name ?? "" < activity2.name ?? ""
                }
                return activity1.finalDate ?? Date.distantPast < activity2.finalDate ?? Date.distantPast
            }
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
        DispatchQueue.main.async { [weak self] in
            self?.observeActivitiesForCurrentUser({
                if self?.isRunning ?? true {
                    completion()
                    self?.grabOtherActivities()
                    self?.isRunning = false
                }
            })
        }
    }
    
    func grabOtherActivities() {
        DispatchQueue.global(qos: .userInteractive).async { [weak self] in
            self?.fetchInvitations()
            self?.observeInvitationForCurrentUser()
            self?.addRepeatingActivities(activities: self?.activities ?? [], completion: { newActivities in
                self?.activities = newActivities
                self?.grabPlotLists()
                self?.grabPlotCalendars()
                self?.grabPrimaryList({ (list) in
                    if list == ListSourceOptions.apple.name {
                        self?.grabEKReminders {
                            self?.hasLoadedListTaskActivities = true
                        }
                    } else if list == ListSourceOptions.google.name {
                        self?.grabGTasks {
                            self?.hasLoadedListTaskActivities = true
                        }
                    } else {
                        self?.hasLoadedListTaskActivities = true
                    }
                    self?.grabLists()
                })
                self?.grabPrimaryCalendar({ (calendar) in
                    if calendar == CalendarSourceOptions.apple.name {
                        self?.grabEKEvents {
                            self?.hasLoadedCalendarEventActivities = true
                        }
                    } else if calendar == CalendarSourceOptions.google.name {
                        self?.grabGEvents {
                            self?.hasLoadedCalendarEventActivities = true
                        }
                    } else {
                        self?.hasLoadedCalendarEventActivities = true
                    }
                    self?.grabCalendars()
                })
            })
            self?.saveDataToSharedContainer(activities: self?.activities ?? [])
        }
    }
    
    func observeActivitiesForCurrentUser(_ completion: @escaping () -> Void) {
        activitiesFetcher.observeActivityForCurrentUser(activitiesInitialAdd: { [weak self] activitiesInitialAdd in
            if self?.activities.isEmpty ?? true {
                self?.activities = activitiesInitialAdd
                self?.eventsNoRepeats = activitiesInitialAdd.filter { $0.isTask == nil }
                self?.tasksNoRepeats = activitiesInitialAdd.filter { $0.isTask != nil }
                completion()
            } else if !activitiesInitialAdd.isEmpty {
                for activity in activitiesInitialAdd {
                    if activity.recurrences != nil {
                        if self!.activities.contains(where: {$0.activityID == activity.activityID}) {
                            self?.activities = (self?.activities.filter({$0.activityID != activity.activityID})) ?? []
                            self?.addRepeatingActivities(activities: [activity], completion: { activities in
                                self?.activities.append(contentsOf: activities)
                            })
                        } else {
                            self?.addRepeatingActivities(activities: [activity], completion: { activities in
                                self?.activities.append(contentsOf: activities)
                            })
                        }
                    } else {
                        //if recurrence was just made nil, repeating activities could show up so remove and then add back
                        self?.activities = (self?.activities.filter({$0.activityID != activity.activityID})) ?? []
                        self?.activities.append(activity)
                    }
                }
            } else {
                completion()
            }
        }, activitiesAdded: { [weak self] activitiesAdded in
            for activity in activitiesAdded {
                if activity.recurrences != nil {
                    if self!.activities.contains(where: {$0.activityID == activity.activityID}) {
                        self?.activities = (self?.activities.filter({$0.activityID != activity.activityID})) ?? []
                        self?.addRepeatingActivities(activities: [activity], completion: { activities in
                            self?.activities.append(contentsOf: activities)
                        })
                    } else {
                        self?.addRepeatingActivities(activities: [activity], completion: { activities in
                            self?.activities.append(contentsOf: activities)
                        })
                    }
                } else {
                    //if recurrence was just made nil, repeating activities could show up so remove and then add back
                    self?.activities = (self?.activities.filter({$0.activityID != activity.activityID})) ?? []
                    self?.activities.append(activity)
                }
            }
        }, activitiesRemoved: { [weak self] activitiesRemoved in
            for activity in activitiesRemoved {
                //just filter out activities that match activityID; will capture both recurring and non-recurring
                self?.activities = (self?.activities.filter({$0.activityID != activity.activityID})) ?? []
            }
        }, activitiesChanged: { [weak self] activitiesChanged in
            for activity in activitiesChanged {
                if activity.recurrences != nil {
                    if self!.activities.contains(where: {$0.activityID == activity.activityID}) {
                        self?.activities = (self?.activities.filter({$0.activityID != activity.activityID})) ?? []
                        self?.addRepeatingActivities(activities: [activity], completion: { activities in
                            self?.activities.append(contentsOf: activities)
                        })
                    } else {
                        self?.addRepeatingActivities(activities: [activity], completion: { activities in
                            self?.activities.append(contentsOf: activities)
                        })
                    }
                } else {
                    //if recurrence was just made nil, repeating activities could show up so remove and then add back
                    self?.activities = (self?.activities.filter({$0.activityID != activity.activityID})) ?? []
                    self?.activities.append(activity)
                }
            }
        })
    }
    
    func grabEKEvents(_ completion: @escaping () -> Void) {
        guard Auth.auth().currentUser != nil else {
            return completion()
        }
        self.eventKitManager.checkEventAuthorizationStatus {}
        self.eventKitManager.authorizeEventKitEvents({ askedforAuthorization in
            self.askedforCalendarAuthorization = askedforAuthorization
            self.eventKitManager.syncEventKitActivities(existingActivities: self.eventsNoRepeats, completion: {
                self.eventKitManager.syncActivitiesToEventKit(activities: self.eventsNoRepeats, completion: {
                    completion()
                })
            })
        })
    }
    
    func grabEKReminders(_ completion: @escaping () -> Void) {
        guard Auth.auth().currentUser != nil else {
            return completion()
        }
        self.eventKitManager.checkEventAuthorizationStatus {}
        self.eventKitManager.authorizeEventKitReminders({ askedforAuthorization in
            self.askedforReminderAuthorization = askedforAuthorization
            self.eventKitManager.syncEventKitReminders(existingActivities: self.tasksNoRepeats, completion: {
                self.eventKitManager.syncTasksToEventKit(activities: self.tasksNoRepeats, completion: {
                    completion()
                })
            })
        })
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
        self.googleCalManager.authorizeGReminders { askedforCalendarAuthorization in
            self.askedforReminderAuthorization = askedforCalendarAuthorization
            self.googleCalManager.syncGoogleCalTasks(existingActivities: self.tasksNoRepeats, completion: {
                self.googleCalManager.syncTasksToGoogleTasks(activities: self.tasksNoRepeats, completion: {
                    completion()
                })
            })
        }
    }
    
    func grabCalendars() {
        if let _ = Auth.auth().currentUser {
            self.eventKitManager.authorizeEventKitEvents { _ in
                if let calendars = self.eventKitManager.grabCalendars() {
                    self.calendars[CalendarSourceOptions.apple.name] = calendars
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
    
    func grabPlotCalendars() {
        self.calendarFetcher.observeCalendarForCurrentUser(calendarInitialAdd: { [weak self] calendarInitialAdd in
            if self?.calendars[CalendarSourceOptions.plot.name] != nil {
                var plotCalendars = self?.calendars[CalendarSourceOptions.plot.name]
                for calendar in calendarInitialAdd {
                    if let index = plotCalendars?.firstIndex(where: { $0.id == calendar.id}) {
                        plotCalendars?[index] = calendar
                    }
                }
                self?.calendars[CalendarSourceOptions.plot.name] = plotCalendars
            } else {
                self?.calendars[CalendarSourceOptions.plot.name] = calendarInitialAdd
            }
        }, calendarAdded: { [weak self] calendarAdded in
            if self?.calendars[CalendarSourceOptions.plot.name] != nil {
                var plotCalendars = self?.calendars[CalendarSourceOptions.plot.name]
                for calendar in calendarAdded {
                    if let index = plotCalendars?.firstIndex(where: { $0.id == calendar.id}) {
                        plotCalendars?[index] = calendar
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
                    if let index = plotCalendars?.firstIndex(where: { $0.id == calendar.id}) {
                        plotCalendars?[index] = calendar
                    }
                }
                self?.calendars[CalendarSourceOptions.plot.name] = plotCalendars
            }
        })
    }
    
    func grabPrimaryCalendar(_ completion: @escaping (String) -> Void) {
        if let currentUserId = Auth.auth().currentUser?.uid {
            let reference = Database.database().reference().child(userCalendarEventsEntity).child(currentUserId).child(primaryCalendarKey)
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
        if let currentUserId = Auth.auth().currentUser?.uid {
            let reference = Database.database().reference().child(userCalendarEventsEntity).child(currentUserId).child(primaryCalendarKey)
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
            grabActivities {}
        } else {
            if value == primaryCalendar && value == CalendarSourceOptions.apple.name {
                grabEKEvents {}
            } else if value == primaryCalendar && value == CalendarSourceOptions.google.name {
                grabGEvents {}
            }
            grabCalendars()
        }
    }
    
    func updatePrimaryCalendarFB(value: String) {
        if let currentUserId = Auth.auth().currentUser?.uid {
            self.primaryCalendar = value
            self.runCalendarFunctions(value: value)
            let reference = Database.database().reference().child(userCalendarEventsEntity).child(currentUserId).child(primaryCalendarKey)
            reference.setValue(value)
        }
    }
    
    func grabLists() {
        if let _ = Auth.auth().currentUser {
            self.eventKitManager.authorizeEventKitReminders { _ in
                if let lists = self.eventKitManager.grabLists() {
                    self.lists[ListSourceOptions.apple.name] = lists
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
    
    func grabPlotLists() {
        self.listFetcher.observeListForCurrentUser(listInitialAdd: { [weak self] listInitialAdd in
            if self?.lists[ListSourceOptions.plot.name] != nil {
                var plotLists = self?.lists[ListSourceOptions.plot.name]
                for list in listInitialAdd {
                    if let index = plotLists?.firstIndex(where: { $0.id == list.id}) {
                        plotLists?[index] = list
                    }
                }
                self?.lists[ListSourceOptions.plot.name] = plotLists
            } else {
                self?.lists[ListSourceOptions.plot.name] = listInitialAdd
            }
        }, listAdded: { [weak self] listAdded in
            if self?.lists[ListSourceOptions.plot.name] != nil {
                var plotLists = self?.lists[ListSourceOptions.plot.name]
                for list in listAdded {
                    if let index = plotLists?.firstIndex(where: { $0.id == list.id}) {
                        plotLists?[index] = list
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
                    plotLists = plotLists?.filter({$0.id != list.id})
                }
                self?.lists[ListSourceOptions.plot.name] = plotLists
            }
        }, listChanged: { [weak self] listChanged in
            if self?.lists[ListSourceOptions.plot.name] != nil {
                var plotLists = self?.lists[ListSourceOptions.plot.name]
                for list in listChanged {
                    if let index = plotLists?.firstIndex(where: { $0.id == list.id}) {
                        plotLists?[index] = list
                    }
                }
                self?.lists[ListSourceOptions.plot.name] = plotLists
            }
        })
    }
    
    func grabPrimaryList(_ completion: @escaping (String) -> Void) {
        if let currentUserId = Auth.auth().currentUser?.uid {
            let reference = Database.database().reference().child(userReminderTasksEntity).child(currentUserId).child(primaryReminderKey)
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
        if let currentUserId = Auth.auth().currentUser?.uid {
            let reference = Database.database().reference().child(userReminderTasksEntity).child(currentUserId).child(primaryReminderKey)
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
            grabActivities {}
        } else {
            if value == primaryList && value == ListSourceOptions.apple.name {
                grabEKReminders {}
            } else if value == primaryList && value == ListSourceOptions.google.name {
                grabGTasks {}
            }
            grabLists()
        }
    }
    
    func updatePrimaryListFB(value: String) {
        if let currentUserId = Auth.auth().currentUser?.uid {
            self.primaryList = value
            self.runListFunctions(value: value)
            let reference = Database.database().reference().child(userReminderTasksEntity).child(currentUserId).child(primaryReminderKey)
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
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            
            return
        }
        
        for activity in self.activities {
            if activity.activityType == "calendarEvent" || activity.activityType == CustomType.iOSCalendarEvent.categoryText || activity.activityType == CustomType.googleCalendarEvent.categoryText, let activityID = activity.activityID {
                let activityReference = Database.database().reference().child(activitiesEntity).child(activityID)
                let userActivityReference = Database.database().reference().child(userActivitiesEntity).child(currentUserId).child(activityID)
                activityReference.removeValue()
                userActivityReference.removeValue()
            }
        }
        let reference = Database.database().reference().child(userCalendarEventsEntity).child(currentUserId).child(calendarEventsKey)
        reference.removeValue()
    }
    
    func observeInvitationForCurrentUser() {
        self.invitationsFetcher.observeInvitationForCurrentUser(invitationsAdded: { [weak self] invitationsAdded in
            for invitation in invitationsAdded {
                self?.invitations[invitation.activityID] = invitation
            }
        }) { [weak self] (invitationsRemoved) in
            for invitation in invitationsRemoved {
                self?.invitations.removeValue(forKey: invitation.activityID)
            }
        }
    }
    
    func addRepeatingActivities(activities: [Activity], completion: @escaping ([Activity])->()) {
        let yearFromNowDate = Calendar.current.date(byAdding: .year, value: 1, to: Date())
        var newActivities = [Activity]()
        for activity in activities {
            // Handles recurring events.
            if let rules = activity.recurrences, !rules.isEmpty {
                let dayBeforeNowDate = Calendar.current.date(byAdding: .day, value: -1, to: activity.startDate ?? Date())
                let dates = iCalUtility()
                    .recurringDates(forRules: rules, ruleStartDate: activity.startDate ?? Date(), startDate: dayBeforeNowDate ?? Date(), endDate: yearFromNowDate ?? Date())
                let duration = activity.endDate!.timeIntervalSince(activity.startDate!)
                for date in dates {
                    let newActivity = activity.copy() as! Activity
                    newActivity.startDateTime = NSNumber(value: date.timeIntervalSince1970)
                    newActivity.endDateTime = NSNumber(value: date.timeIntervalSince1970 + duration)
                    newActivities.append(newActivity)
                }
            } else {
                newActivities.append(activity)
            }
        }
        completion(newActivities)
    }
}
