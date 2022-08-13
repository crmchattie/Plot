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
    static let activitiesUpdated = NSNotification.Name(Bundle.main.bundleIdentifier! + ".activitiesUpdated")
    static let invitationsUpdated = NSNotification.Name(Bundle.main.bundleIdentifier! + ".invitationsUpdated")
    static let calendarsUpdated = NSNotification.Name(Bundle.main.bundleIdentifier! + ".calendarsUpdated")
}

class ActivityService {
    let activitiesFetcher = ActivitiesFetcher()
    let invitationsFetcher = InvitationsFetcher()
    let calendarFetcher = CalendarFetcher()
    
    var askedforAuthorization: Bool = false
    
    var calendars = [String: [CalendarType]]() {
        didSet {
            if oldValue != calendars {
                NotificationCenter.default.post(name: .calendarsUpdated, object: nil)
            }
        }
    }
    
    var primaryCalendar = String()
    
    var activities = [Activity]() {
        didSet {
            if oldValue != activities {
                let currentDate = NSNumber(value: Int((Date().localTime).timeIntervalSince1970)).int64Value
                activities.sort { (activity1, activity2) -> Bool in
                    if currentDate.isBetween(activity1.startDateTime?.int64Value ?? 0, and: activity1.endDateTime?.int64Value ?? 0) && currentDate.isBetween(activity2.startDateTime?.int64Value ?? 0, and: activity2.endDateTime?.int64Value ?? 0) {
                        return activity1.startDateTime?.int64Value ?? 0 < activity2.startDateTime?.int64Value ?? 0
                    } else if currentDate.isBetween(activity1.startDateTime?.int64Value ?? 0, and: activity1.endDateTime?.int64Value ?? 0) {
                        return currentDate < activity2.startDateTime?.int64Value ?? 0
                    } else if currentDate.isBetween(activity2.startDateTime?.int64Value ?? 0, and: activity2.endDateTime?.int64Value ?? 0) {
                        return activity1.startDateTime?.int64Value ?? 0 < currentDate
                    }
                    return activity1.startDateTime?.int64Value ?? 0 < activity2.startDateTime?.int64Value ?? 0
                }
                NotificationCenter.default.post(name: .activitiesUpdated, object: nil)
            }
        }
    }
    //for Apple/Google Calendar functions
    var activitiesNoRepeats = [Activity]()
    var invitations: [String: Invitation] = [:] {
        didSet {
            if oldValue != invitations {
                NotificationCenter.default.post(name: .invitationsUpdated, object: nil)
            }
        }
    }
    var invitedActivities = [Activity]()
    
    var hasLoadedCalendarEventActivities = false
    
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
    
    func grabActivities(_ completion: @escaping () -> Void) {
        DispatchQueue.main.async { [weak self] in
            self?.observeActivitiesForCurrentUser({
                self?.grabOtherActivities()
                if self?.isRunning ?? true {
                    completion()
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
                self?.grabPrimaryCalendar({ (calendar) in
                    self?.grabPlotCalendars()
                    if calendar == CalendarOptions.apple.name {
                        self?.grabEventKit {}
                    } else if calendar == CalendarOptions.google.name {
                        self?.grabGoogle {}
                    }
                    self?.grabCalendars()
                })
            })
        }
    }
    
    func observeActivitiesForCurrentUser(_ completion: @escaping () -> Void) {
        activitiesFetcher.observeActivityForCurrentUser(activitiesInitialAdd: { [weak self] activitiesInitialAdd in
            if self?.activities.isEmpty ?? true {
                self?.activities = activitiesInitialAdd
                self?.activitiesNoRepeats = activitiesInitialAdd
                completion()
            } else {
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
            }
        }, activitiesAdded: { [weak self] activitiesAdded in
            print("activitiesAdded")
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
            print("activitiesRemoved")
            for activity in activitiesRemoved {
                //just filter out activities that match activityID; will capture both recurring and non-recurring
                self?.activities = (self?.activities.filter({$0.activityID != activity.activityID})) ?? []
            }
        }, activitiesChanged: { [weak self] activitiesChanged in
            print("activitiesChanged")
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
    
    func grabEventKit(_ completion: @escaping () -> Void) {
        guard Auth.auth().currentUser != nil else {
            return completion()
        }
        self.eventKitManager.checkEventAuthorizationStatus {}
        self.eventKitManager.authorizeEventKit({ askedforAuthorization in
            self.askedforAuthorization = askedforAuthorization
            self.eventKitManager.syncEventKitActivities(existingActivities: self.activitiesNoRepeats, completion: {
                self.eventKitManager.syncActivitiesToEventKit(activities: self.activitiesNoRepeats, completion: {
                    completion()
                })
            })
        })
    }
    
    func grabGoogle(_ completion: @escaping () -> Void) {
        guard Auth.auth().currentUser != nil else {
            return completion()
        }
        self.googleCalManager.setupGoogle { askedforAuthorization in
            self.askedforAuthorization = askedforAuthorization
            self.googleCalManager.syncGoogleCalActivities(existingActivities: self.activitiesNoRepeats, completion: {
                self.googleCalManager.syncActivitiesToGoogleCal(activities: self.activitiesNoRepeats, completion: {
                    completion()
                })
            })
        }
    }
    
    func grabCalendars() {
        if let _ = Auth.auth().currentUser {
            self.eventKitManager.authorizeEventKit({ _ in
                if let calendars = self.eventKitManager.grabCalendars() {
                    self.calendars[CalendarOptions.apple.name] = calendars
                }
            })
            self.googleCalManager.setupGoogle { _ in
                self.googleCalManager.grabCalendars() { calendars in
                    if let calendars = calendars {
                        self.calendars[CalendarOptions.google.name] = calendars
                    }
                }
            }
        }
    }
    
    func grabPlotCalendars() {
        self.calendarFetcher.observeCalendarForCurrentUser(calendarInitialAdd: { [weak self] calendarInitialAdd in
            if self?.calendars[CalendarOptions.plot.name] != nil {
                var plotCalendars = self?.calendars[CalendarOptions.plot.name]
                for calendar in calendarInitialAdd {
                    if let index = plotCalendars?.firstIndex(where: { $0.id == calendar.id}) {
                        plotCalendars?[index] = calendar
                    }
                }
                self?.calendars[CalendarOptions.plot.name] = plotCalendars
            } else {
                self?.calendars[CalendarOptions.plot.name] = calendarInitialAdd
            }
        }, calendarAdded: { [weak self] calendarAdded in
            if self?.calendars[CalendarOptions.plot.name] != nil {
                var plotCalendars = self?.calendars[CalendarOptions.plot.name]
                for calendar in calendarAdded {
                    if let index = plotCalendars?.firstIndex(where: { $0.id == calendar.id}) {
                        plotCalendars?[index] = calendar
                    }
                }
                self?.calendars[CalendarOptions.plot.name] = plotCalendars
            } else {
                self?.calendars[CalendarOptions.plot.name] = calendarAdded
            }
        }, calendarRemoved: { [weak self] calendarRemoved in
            if self?.calendars[CalendarOptions.plot.name] != nil {
                var plotCalendars = self?.calendars[CalendarOptions.plot.name]
                for calendar in calendarRemoved {
                    plotCalendars = plotCalendars?.filter({$0.id != calendar.id})
                }
                self?.calendars[CalendarOptions.plot.name] = plotCalendars
            }
        }, calendarChanged: { [weak self] calendarChanged in
            if self?.calendars[CalendarOptions.plot.name] != nil {
                var plotCalendars = self?.calendars[CalendarOptions.plot.name]
                for calendar in calendarChanged {
                    if let index = plotCalendars?.firstIndex(where: { $0.id == calendar.id}) {
                        plotCalendars?[index] = calendar
                    }
                }
                self?.calendars[CalendarOptions.plot.name] = plotCalendars
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
        if !askedforAuthorization {
            grabActivities {}
        } else {
            if value == primaryCalendar && value == CalendarOptions.apple.name {
                grabEventKit {}
            } else if value == primaryCalendar && value == CalendarOptions.google.name {
                grabGoogle {}
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
