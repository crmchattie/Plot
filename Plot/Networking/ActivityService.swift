//
//  ActivityService.swift
//  Plot
//
//  Created by Cory McHattie on 12/24/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import Foundation
import Firebase

extension NSNotification.Name {
    static let activitiesUpdated = NSNotification.Name(Bundle.main.bundleIdentifier! + ".activitiesUpdated")
}

class ActivityService {
    let activitiesFetcher = ActivitiesFetcher()
    let invitationsFetcher = InvitationsFetcher()
    
    var askedforAuthorization: Bool = false

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
    var invitations: [String: Invitation] = [:] {
        didSet {
            if oldValue != invitations {
                NotificationCenter.default.post(name: .activitiesUpdated, object: nil)
            }
        }
    }
    var invitedActivities = [Activity]()
    
    var hasLoadedCalendarEventActivities = false
        
    var eventKitManager: EventKitManager = {
        let eventKitSetupAssistant = EventKitSetupAssistant()
        let eventKitService = EventKitService()
        let eventKitManager = EventKitManager(eventKitService: eventKitService)
        return eventKitManager
    }()
    
    func grabActivities(_ completion: @escaping () -> Void) {
        DispatchQueue.main.async { [weak self] in
            self?.activitiesFetcher.fetchActivities { (activities) in
                self?.activities = activities
                self?.fetchInvitations()
                if let _ = Auth.auth().currentUser {
                    self?.eventKitManager.authorizeEventKit({ (askedforAuthorization) in
                        self?.askedforAuthorization = askedforAuthorization
                        self?.eventKitManager.syncEventKitActivities {
                            self?.eventKitManager.syncActivitiesToEventKit(activities: activities, completion: {
                                self?.observeActivitiesForCurrentUser()
                                self?.observeInvitationForCurrentUser()
                            })
                        }
                    })
                }
                completion()
            }
        }
    }
    
    func observeActivitiesForCurrentUser() {
        activitiesFetcher.observeActivityForCurrentUser(activitiesAdded: { [weak self] activitiesAdded in
                for activity in activitiesAdded {
                    if let index = self!.activities.firstIndex(where: {$0.activityID == activity.activityID}) {
                        self!.activities[index] = activity
                    } else {
                        self!.activities.append(activity)
                    }
                }
            }, activitiesRemoved: { [weak self] activitiesRemoved in
                for activity in activitiesRemoved {
                    if let index = self!.activities.firstIndex(where: {$0.activityID == activity.activityID}) {
                        self!.activities.remove(at: index)
                    }
                }
            }, activitiesChanged: { [weak self] activitiesChanged in
                for activity in activitiesChanged {
                    if let index = self!.activities.firstIndex(where: {$0.activityID == activity.activityID}) {
                        self!.activities[index] = activity
                    }
                }
            }
        )
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
            if activity.activityType == "calendarEvent" || activity.activityType == CustomType.iOSCalendarEvent.categoryText, let activityID = activity.activityID {
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
}
