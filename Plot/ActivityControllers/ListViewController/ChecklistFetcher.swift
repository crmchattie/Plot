//
//  ListsFetcher.swift
//  Plot
//
//  Created by Cory McHattie on 5/20/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import UIKit
import Firebase
import CodableFirebase

class ChecklistFetcher: NSObject {
        
    fileprivate var userInvitationsDatabaseRef: DatabaseReference!
    fileprivate var currentUserInvitationsAddHandle = DatabaseHandle()
    fileprivate var currentUserInvitationsRemoveHandle = DatabaseHandle()
    
    var invitationsAdded: (([Invitation])->())?
    var invitationsRemoved: (([Invitation])->())?
    
    func fetchInvitations(completion: @escaping ([String: Invitation], [Activity])->()) {
        guard let currentUserID = Auth.auth().currentUser?.uid else {
            completion([:], [])
            return
        }
        
        let ref = Database.database().reference()
        userInvitationsDatabaseRef = Database.database().reference().child(userInvitationsEntity).child(currentUserID)

        userInvitationsDatabaseRef.observeSingleEvent(of: .value, with: { snapshot in
            if snapshot.exists(), let invitationIDs = snapshot.value as? [String: Int] {
                var invitations: [String: Invitation] = [:]
                var activiitiesForInvitations: [Activity] = []
                let group = DispatchGroup()
                for (invitationID, _) in invitationIDs {
                    group.enter()
                    ref.child(invitationsEntity).child(invitationID).observeSingleEvent(of: .value, with: { invitationSnapshot in
                        if invitationSnapshot.exists(), let invitationSnapshotValue = invitationSnapshot.value {
                            if let invitation = try? FirebaseDecoder().decode(Invitation.self, from: invitationSnapshotValue) {
                                invitations[invitation.activityID] = invitation
                                
                                group.enter()
                                ref.child("activities").child(invitation.activityID).observeSingleEvent(of: .value, with: { activitySnapshot in
                                    if activitySnapshot.exists(), let activitySnapshotValue = activitySnapshot.value as? [String: AnyObject], let meta = activitySnapshotValue["metaData"] as? [String: AnyObject] {
                                        let activity = Activity(dictionary: meta)
                                        activiitiesForInvitations.append(activity)
                                    }
                                    
                                    group.leave()
                                })
                            }
                        }
                        group.leave()
                    })
                }
                
                group.notify(queue: .main) {
                    completion(invitations, activiitiesForInvitations)
                }
            } else {
                completion([:], [])
            }
        })
    }
    
    func observeInvitationForCurrentUser(invitationsAdded: @escaping ([Invitation])->(), invitationsRemoved: @escaping ([Invitation])->()) {
        self.invitationsAdded = invitationsAdded
        self.invitationsRemoved = invitationsRemoved
        currentUserInvitationsAddHandle = userInvitationsDatabaseRef.observe(.childAdded, with: { snapshot in
            if let completion = self.invitationsAdded {
                let invitationID = snapshot.key
                let ref = Database.database().reference()
                var handle = UInt.max
                handle = ref.child(invitationsEntity).child(invitationID).observe(.childAdded) { _ in
                    ref.removeObserver(withHandle: handle)
                    self.getInvitationsFromSnapshot(snapshot: snapshot, completion: completion)
                }
            }
        })
        
        currentUserInvitationsRemoveHandle = userInvitationsDatabaseRef.observe(.childRemoved, with: { snapshot in
            if let completion = self.invitationsRemoved {
                self.getInvitationsFromSnapshot(snapshot: snapshot, completion: completion)
            }
        })
    }
    
    func getInvitationsFromSnapshot(snapshot: DataSnapshot, completion: @escaping ([Invitation])->()) {
        if snapshot.exists() {
            let invitationID = snapshot.key
            let ref = Database.database().reference()
            var invitations: [Invitation] = []
            let group = DispatchGroup()
            group.enter()
            ref.child(invitationsEntity).child(invitationID).observeSingleEvent(of: .value, with: { invitationSnapshot in
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
        } else {
            completion([])
        }
    }
    
    class func update(invitation: Invitation, completion: @escaping (Bool)->()) {
        let ref = Database.database().reference()
        ref.child(invitationsEntity).child(invitation.invitationID).observeSingleEvent(of: .value, with: { invitationSnapshot in
            // first check if invitation exists
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
}
