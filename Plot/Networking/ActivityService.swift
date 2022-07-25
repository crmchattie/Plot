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

let icloudString = "iCloud"
let googleString = "Google"

extension NSNotification.Name {
    static let activitiesUpdated = NSNotification.Name(Bundle.main.bundleIdentifier! + ".activitiesUpdated")
    static let invitationsUpdated = NSNotification.Name(Bundle.main.bundleIdentifier! + ".invitationsUpdated")
    static let calendarsUpdated = NSNotification.Name(Bundle.main.bundleIdentifier! + ".calendarsUpdated")
}

class ActivityService {
    let activitiesFetcher = ActivitiesFetcher()
    let invitationsFetcher = InvitationsFetcher()
    
    var askedforAuthorization: Bool = false
    
    var calendars = [String: [String]]() {
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
                activities.sort { (activity1, activity2) -> Bool in
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
    
    func grabActivities(_ completion: @escaping () -> Void) {
        DispatchQueue.main.async { [weak self] in
            self?.activitiesFetcher.fetchActivities { [weak self] activities in
                self?.activities = activities
                self?.activitiesNoRepeats = activities
                self?.grabOtherActivities()
                completion()
            }
        }
    }
    
    func grabOtherActivities() {
        DispatchQueue.global(qos: .userInteractive).async { [weak self] in
            self?.fetchInvitations()
            self?.addRepeatingActivities(activities: self?.activities ?? [], completion: { newActivities in
                self?.activities = newActivities
                self?.grabPrimaryCalendar({ (calendar) in
                    if calendar == icloudString {
                        self?.grabEventKit {
                            self?.observeActivitiesForCurrentUser()
                            self?.observeInvitationForCurrentUser()
                        }
                    } else if calendar == googleString {
                        self?.grabGoogle {
                            self?.observeActivitiesForCurrentUser()
                            self?.observeInvitationForCurrentUser()
                        }
                    } else {
                        self?.observeActivitiesForCurrentUser()
                        self?.observeInvitationForCurrentUser()
                    }
                    self?.grabCalendars()
                })
            })
        }
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
                    self.calendars[icloudString] = calendars
                }
            })
            self.googleCalManager.setupGoogle { _ in
                self.googleCalManager.grabCalendars() { calendars in
                    if let calendars = calendars {
                        self.calendars[googleString] = calendars
                    }
                }
            }
        }
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
            if value == primaryCalendar && value == icloudString {
                grabEventKit {}
            } else if value == primaryCalendar && value == googleString {
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
    
    func observeActivitiesForCurrentUser() {
        activitiesFetcher.observeActivityForCurrentUser(activitiesAdded: { [weak self] activitiesAdded in
            print("activitiesAdded")
                for activity in activitiesAdded {
                    if activity.recurrences != nil {
                        if self!.activities.contains(where: {$0.activityID == activity.activityID}) {
                            self?.activities = (self?.activities.filter({$0.activityID != activity.activityID}))!
                            self?.addRepeatingActivities(activities: [activity], completion: { activities in
                                self?.activities.append(contentsOf: activities)
                            })
                        } else {
                            self?.addRepeatingActivities(activities: [activity], completion: { activities in
                                self?.activities.append(contentsOf: activities)
                            })
                        }
                    } else {
                        if let index = self?.activities.firstIndex(where: {$0.activityID == activity.activityID}) {
                            self?.activities[index] = activity
                        } else {
                            self?.activities.append(activity)
                        }
                    }
                }
            }, activitiesRemoved: { [weak self] activitiesRemoved in
                print("activitiesRemoved")
                for activity in activitiesRemoved {
                    if activity.recurrences != nil {
                        if self!.activities.contains(where: {$0.activityID == activity.activityID}) {
                            self?.activities = (self?.activities.filter({$0.activityID != activity.activityID}))!
                        }
                    } else if let index = self?.activities.firstIndex(where: {$0.activityID == activity.activityID}) {
                        self?.activities.remove(at: index)
                    }
                }
            }, activitiesChanged: { [weak self] activitiesChanged in
                print("activitiesChanged")
                for activity in activitiesChanged {
                    if activity.recurrences != nil {
                        if self!.activities.contains(where: {$0.activityID == activity.activityID}) {
                            self?.activities = (self?.activities.filter({$0.activityID != activity.activityID}))!
                            self?.addRepeatingActivities(activities: [activity], completion: { activities in
                                self?.activities.append(contentsOf: activities)
                            })
                        } else {
                            self?.addRepeatingActivities(activities: [activity], completion: { activities in
                                self?.activities.append(contentsOf: activities)
                            })
                        }
                    } else {
                        if let index = self?.activities.firstIndex(where: {$0.activityID == activity.activityID}) {
                            self?.activities[index] = activity
                        } else {
                            self?.activities.append(activity)
                        }
                    }
                }
            }
        )
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
                if activity.name == "Test three" {
                    print("rules \(rules)")
                    print("dayBeforeNowDate \(dayBeforeNowDate)")
                    print("dates \(dates)")
                }
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
