//
//  ActivityService.swift
//  Plot
//
//  Created by Cory McHattie on 12/24/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import Foundation
import Firebase

class ActivityService {
    let activitiesFetcher = ActivitiesFetcher()
    let invitationsFetcher = InvitationsFetcher()

    var activities = [Activity]()
    var invitations: [String: Invitation] = [:]
    var invitedActivities = [Activity]()
    
    var hasLoadedCalendarEventActivities = false
        
    var eventKitManager: EventKitManager = {
        let eventKitSetupAssistant = EventKitSetupAssistant()
        let eventKitService = EventKitService(setupAssistant: eventKitSetupAssistant)
        let eventKitManager = EventKitManager(eventKitService: eventKitService)
        return eventKitManager
    }()
    
    func grabActivities(_ completion: @escaping () -> Void) {
        DispatchQueue.main.async { [unowned self] in
            activitiesFetcher.fetchActivities { (activities) in
                print("activities grabbed \(activities.count)")
                self.activities = activities.sorted { (activity1, activity2) -> Bool in
                    return activity1.startDateTime?.int64Value ?? 0 < activity2.startDateTime?.int64Value ?? 0
                }
                self.fetchInvitations()
                if let _ = Auth.auth().currentUser {
                    self.eventKitManager.syncEventKitActivities {
                        self.observeActivitiesForCurrentUser()
                        self.observeInvitationForCurrentUser()
                    }
                }
                completion()
            }
        }
        
//        if !self.hasLoadedCalendarEventActivities {
//            self.hasLoadedCalendarEventActivities = true
            // Comment out the block below to stop the sync
//
//                // Uncomment this line to clean the calendar events. The app might freeze for a bit and/or require a restart
//                DispatchQueue.global().async {
//                    weakSelf.cleanCalendarEventActivities()
//                }
//        }
    }
    
    func observeActivitiesForCurrentUser() {
        activitiesFetcher.observeActivityForCurrentUser(activitiesAdded: { [weak self] activitiesAdded in
                for activity in activitiesAdded {
                    if let index = self!.activities.firstIndex(where: {$0 == activity}) {
                        self!.activities[index] = activity
                    } else {
                        self!.activities.append(activity)
                    }
                }
            }, activitiesRemoved: { [weak self] activitiesRemoved in
                for activity in activitiesRemoved {
                    if let index = self!.activities.firstIndex(where: {$0 == activity}) {
                        self!.activities.remove(at: index)
                    }
                }
            }, activitiesChanged: { [weak self] activitiesChanged in
                for activity in activitiesChanged {
                    if let index = self!.activities.firstIndex(where: {$0 == activity}) {
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
            print("invitations grabbed \(invitations.count)")
            
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
