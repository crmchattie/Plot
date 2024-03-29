//
//  InvitationsFetcher.swift
//  Plot
//
//  Created by Hafiz Usama on 2019-10-26.
//  Copyright © 2019 Immature Creations. All rights reserved.
//

import Foundation
import Firebase
import CodableFirebase

class InvitationsFetcher: NSObject {
    
    fileprivate var userInvitationsDatabaseRef: DatabaseReference!
    fileprivate var currentUserInvitationsAddHandle = DatabaseHandle()
    fileprivate var currentUserInvitationsRemoveHandle = DatabaseHandle()
    
    var invitationsInitialAdd: (([String: Invitation], [Activity])->())?
    var invitationsAdded: (([Invitation])->())?
    var invitationsRemoved: (([Invitation])->())?
    var userInvitations: [String: Invitation] = [:]
    
    func fetchInvitations(completion: @escaping ([String: Invitation], [Activity])->()) {
        guard let currentUserID = Auth.auth().currentUser?.uid else {
            completion([:], [])
            return
        }

        let ref = Database.database().reference()
        userInvitationsDatabaseRef = ref.child(userInvitationsEntity).child(currentUserID)
        
        userInvitationsDatabaseRef.observeSingleEvent(of: .value, with: { snapshot in
            if snapshot.exists(), let invitationIDs = snapshot.value as? [String: Int] {
                var invitations: [String: Invitation] = [:]
                var activitiesForInvitations: [Activity] = []
                let group = DispatchGroup()
                for (invitationID, _) in invitationIDs {
                    group.enter()
                    ref.child(invitationsEntity).child(invitationID).observeSingleEvent(of: .value, with: { invitationSnapshot in
                        if invitationSnapshot.exists(), let invitationSnapshotValue = invitationSnapshot.value {
                            if let invitation = try? FirebaseDecoder().decode(Invitation.self, from: invitationSnapshotValue) {
                                invitations[invitation.activityID] = invitation
                                group.enter()
                                ref.child(activitiesEntity).child(invitation.activityID).observeSingleEvent(of: .value, with: { activitySnapshot in
                                    if activitySnapshot.exists(), let activitySnapshotValue = activitySnapshot.value as? [String: AnyObject], let meta = activitySnapshotValue["metaData"] as? [String: AnyObject] {
                                        let activity = Activity(dictionary: meta)
                                        activitiesForInvitations.append(activity)
                                    }
                                    
                                    group.leave()
                                })
                            }
                        }
                        group.leave()
                    })
                }
                
                group.notify(queue: .main) {
                    completion(invitations, activitiesForInvitations)
                }
            } else {
                completion([:], [])
            }
        })
    }
    
    func observeInvitationForCurrentUser(invitationsInitialAdd: @escaping ([String: Invitation], [Activity])->(), invitationsAdded: @escaping ([Invitation])->(), invitationsRemoved: @escaping ([Invitation])->()) {
        guard let currentUserID = Auth.auth().currentUser?.uid else {
            return
        }
        
        let ref = Database.database().reference()
        userInvitationsDatabaseRef = ref.child(userInvitationsEntity).child(currentUserID)
                
        self.invitationsInitialAdd = invitationsInitialAdd
        self.invitationsAdded = invitationsAdded
        self.invitationsRemoved = invitationsRemoved
        
        userInvitationsDatabaseRef.observeSingleEvent(of: .value, with: { snapshot in
            guard snapshot.exists(), let invitationIDs = snapshot.value as? [String: Int] else {
                invitationsInitialAdd([:], [])
                return
            }
            
            if let completion = self.invitationsInitialAdd {
                var invitations: [String: Invitation] = [:]
                var activitiesForInvitations: [Activity] = []
                let group = DispatchGroup()
                var counter = 0
                for (invitationID, _) in invitationIDs {
                    group.enter()
                    var handle = UInt.max
                    handle = ref.child(invitationsEntity).child(invitationID).observe(.value) { snapshot in
                        ref.removeObserver(withHandle: handle)
                        if snapshot.exists(), let invitationSnapshotValue = snapshot.value {
                            if let invitation = try? FirebaseDecoder().decode(Invitation.self, from: invitationSnapshotValue) {
                                invitations[invitation.activityID] = invitation
                                self.userInvitations[invitation.activityID] = invitation
                                group.enter()
                                ActivitiesFetcher.getDataFromSnapshot(ID: invitation.activityID, parentID: nil) { activities in
                                    if let activity = activities.first {
                                        if counter > 0 {
                                            activitiesForInvitations.append(activity)
                                            group.leave()
                                            counter -= 1
                                        } else {
                                            activitiesForInvitations = [activity]
                                            completion(invitations, activities)
                                            return
                                        }
                                    } else {
                                        if counter > 0 {
                                            group.leave()
                                            counter -= 1
                                        }
                                    }
                                }
                            }
                        }
                        if counter > 0 {
                            group.leave()
                            counter -= 1
                        }
                    }
                }
                group.notify(queue: .main) {
                    completion(invitations, activitiesForInvitations)
                }
            }
        })
        
        currentUserInvitationsAddHandle = userInvitationsDatabaseRef.observe(.childAdded, with: { snapshot in
            if self.userInvitations[snapshot.key] == nil {
                if let completion = self.invitationsAdded {
                    let invitationID = snapshot.key
                    let ref = Database.database().reference()
                    var handle = UInt.max
                    handle = ref.child(invitationsEntity).child(invitationID).observe(.value) { snapshot in
                        ref.removeObserver(withHandle: handle)
                        if snapshot.exists(), let invitationSnapshotValue = snapshot.value {
                            if let invitation = try? FirebaseDecoder().decode(Invitation.self, from: invitationSnapshotValue) {
                                self.userInvitations[invitation.activityID] = invitation
                                completion([invitation])
                            }
                        }
                    }
                }
            }
        })
        
        currentUserInvitationsRemoveHandle = userInvitationsDatabaseRef.observe(.childRemoved, with: { snapshot in
            if let completion = self.invitationsRemoved {
                self.userInvitations[snapshot.key] = nil
                self.getInvitationsFromSnapshot(ID: snapshot.key, completion: completion)
            }
        })
    }
    
    func getInvitationsFromSnapshot(ID: String, completion: @escaping ([Invitation])->()) {
        let ref = Database.database().reference()
        var invitations: [Invitation] = []
        let group = DispatchGroup()
        group.enter()
        ref.child(invitationsEntity).child(ID).observeSingleEvent(of: .value, with: { invitationSnapshot in
            if invitationSnapshot.exists(), let invitationSnapshotValue = invitationSnapshot.value {
                if let invitation = try? FirebaseDecoder().decode(Invitation.self, from: invitationSnapshotValue) {
                    invitations.append(invitation)
                }
            }
            group.leave()
        })
        
        group.notify(queue: .main) {
            completion(invitations)
        }
    }
    
    class func update(invitation: Invitation, completion: @escaping (Bool)->()) {
        let ref = Database.database().reference()
        ref.child(invitationsEntity).child(invitation.invitationID).observeSingleEvent(of: .value, with: { invitationSnapshot in
            if invitationSnapshot.exists(), let _ = invitationSnapshot.value {
                do {
                    let value = try FirebaseEncoder().encode(invitation)
                    ref.child(invitationsEntity).child(invitation.invitationID).setValue(value)
                    completion(true)
                } catch let error {
                    print(error)
                    completion(false)
                }
            } else {
                completion(false)
            }
        })
    }
    
    class func remove(invitation: Invitation) {
        guard let currentUserID = Auth.auth().currentUser?.uid else {
            return
        }
        
        let ref = Database.database().reference()
        ref.child(invitationsEntity).child(invitation.invitationID).removeValue()
        ref.child(userInvitationsEntity).child(currentUserID).child(invitation.invitationID).removeValue()
    }
    
    class func activityInvitation(forUser userID: String, activityID: String, completion: @escaping (Invitation?)->()) {
        let ref = Database.database().reference()
        ref.child(userInvitationsEntity).child(userID).observeSingleEvent(of: .value, with: { (snapshot) in
            if snapshot.exists(), let invitationIDs = snapshot.value as? [String: Int] {
                var returnInvitation: Invitation?
                let group = DispatchGroup()
                for (invitationID, _) in invitationIDs {
                    group.enter()
                    let invitationIDRef = ref.child(invitationsEntity).child(invitationID)
//                    invitationIDRef.keepSynced(true)
                    invitationIDRef.observeSingleEvent(of: .value, with: { invitationSnapshot in
                        if invitationSnapshot.exists(), let invitationSnapshotValue = invitationSnapshot.value {
                            if let invitation = try? FirebaseDecoder().decode(Invitation.self, from: invitationSnapshotValue) {
                                if invitation.activityID == activityID {
                                    returnInvitation = invitation
                                }
                            }
                        }
                        group.leave()
                    })
                }
                group.notify(queue: .main) {
                    completion(returnInvitation)
                }
            } else {
                completion(nil)
            }
        })
    }
    
    class func updateInvitations(forActivity activity: Activity, selectedParticipants: [User], completion: @escaping ()->()) {
        updateInvitations(forActivity: activity, selectedParticipants: selectedParticipants, defaultStatus: nil, completion: completion)
    }
    
    class func updateInvitations(forActivity activity: Activity, selectedParticipants: [User], defaultStatus: Status?, completion: @escaping ()->()) {
        guard let activityID = activity.activityID else {
            completion()
            return
        }
        
        var invitations: [Invitation] = []
        // only create invitations for participants that did not create activity aka are not admin
        for participant in selectedParticipants {
            if let participantID = participant.id, participant.id != activity.admin {
                let status = defaultStatus ?? .pending
                let invitation = Invitation(invitationID: UUID().uuidString, activityID: activityID, participantID: participantID, dateInvited: Date(), dateAccepted: nil, status: status)
                invitations.append(invitation)
            }
        }
        
        // grab every existing invitation to see if invitation was already created
        let ref = Database.database().reference()
        ref.child(invitationsEntity).observeSingleEvent(of: .value, with: { snapshot in
            do {
                if snapshot.exists(), let value = snapshot.value {
                    let firebaseInvitations = try FirebaseDecoder().decode([String: Invitation].self, from: value)
                    for (key, invitation) in firebaseInvitations {
                        // remove existing invitations from invitations array
                        if invitation.activityID == activityID {
                            if invitations.contains(invitation) {
                                if let index = invitations.firstIndex(of: invitation) {
                                    invitations.remove(at: index)
                                }
                            }
                            // remove invitations for unselected participants - do not follow this logic
                            else {
                                ref.child(invitationsEntity).child(key).removeValue()
                                ref.child(userInvitationsEntity).child(invitation.participantID).child(key).removeValue()
                            }
                        }
                    }
                }
                // do not follow this logic also
                ref.child(userInvitationsEntity).observeSingleEvent(of: .value, with: { userInvitationsSnapshotRef in
                    var userInvitationsSnapshot: [String: Any] = [:]
                    if userInvitationsSnapshotRef.exists(), let userInvitationsSnapshotValue = userInvitationsSnapshotRef.value as? [String: Any] {
                        userInvitationsSnapshot = userInvitationsSnapshotValue

                    }
                    
                    // Add invitations that do not exist
                    for invitation in invitations {
                        let invitationRef = ref.child(invitationsEntity).child(invitation.invitationID)
                        var participantInvitations: [String: Int] = [:]
                        if userInvitationsSnapshot[invitation.participantID] != nil, let participantInvitationsValue = userInvitationsSnapshot[invitation.participantID] as? [String: Int] {
                            participantInvitations = participantInvitationsValue
                        }
                        
                        if let data = try? FirebaseEncoder().encode(invitation) {
                            invitationRef.setValue(data)
                            participantInvitations[invitation.invitationID] = 0
                            ref.child(userInvitationsEntity).child(invitation.participantID).setValue(participantInvitations)
                        }
                    }
                    completion()
                })
            } catch let error {
                print(error)
                completion()
            }
        })
    }
}
