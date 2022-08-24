//
//  ActivitylistFetcher.swift
//  Plot
//
//  Created by Cory McHattie on 7/15/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import UIKit
import Firebase
import CodableFirebase

class ActivitylistFetcher: NSObject {
        
    fileprivate var userActivitylistsDatabaseRef: DatabaseReference!
    fileprivate var currentUserActivitylistsAddHandle = DatabaseHandle()
    fileprivate var currentUserActivitylistsChangeHandle = DatabaseHandle()
    fileprivate var currentUserActivitylistsRemoveHandle = DatabaseHandle()
    
    
    var activitylistsAdded: (([Activitylist])->())?
    var activitylistsRemoved: (([Activitylist])->())?
    var activitylistsChanged: (([Activitylist])->())?
    
    fileprivate var isGroupAlreadyFinished = false
    
    func fetchActivitylists(completion: @escaping ([Activitylist])->()) {
        guard let currentUserID = Auth.auth().currentUser?.uid else {
            completion([])
            return
        }
                
        let ref = Database.database().reference()
        userActivitylistsDatabaseRef = Database.database().reference().child(userActivitylistsEntity).child(currentUserID)
        userActivitylistsDatabaseRef.observeSingleEvent(of: .value, with: { snapshot in
            if snapshot.exists(), let activitylistIDs = snapshot.value as? [String: AnyObject] {
                var activitylists: [Activitylist] = []
                let group = DispatchGroup()
                for (activitylistID, userActivitylistInfo) in activitylistIDs {
                    if let userActivitylist = try? FirebaseDecoder().decode(Activitylist.self, from: userActivitylistInfo) {
                        group.enter()
                        ref.child(activitylistsEntity).child(activitylistID).observeSingleEvent(of: .value, with: { activitylistSnapshot in
                            if activitylistSnapshot.exists(), let activitylistSnapshotValue = activitylistSnapshot.value {
                                if let activitylist = try? FirebaseDecoder().decode(Activitylist.self, from: activitylistSnapshotValue) {
                                    activitylist.badge = userActivitylist.badge
                                    activitylist.muted = userActivitylist.muted
                                    activitylist.pinned = userActivitylist.pinned
                                    activitylists.append(activitylist)
                                }
                            }
                            group.leave()
                        })
                    } else {
                        group.enter()
                        ref.child(activitylistsEntity).child(activitylistID).observeSingleEvent(of: .value, with: { activitylistSnapshot in
                            if activitylistSnapshot.exists(), let activitylistSnapshotValue = activitylistSnapshot.value {
                                if let activitylist = try? FirebaseDecoder().decode(Activitylist.self, from: activitylistSnapshotValue) {
                                    activitylists.append(activitylist)
                                }
                            }
                            group.leave()
                        })
                    }
                }
                group.notify(queue: .main) {
                    completion(activitylists)
                }
            } else {
                completion([])
            }
        })
    }
    
    func observeActivitylistForCurrentUser(activitylistsAdded: @escaping ([Activitylist])->(), activitylistsRemoved: @escaping ([Activitylist])->(), activitylistsChanged: @escaping ([Activitylist])->()) {
        guard let _ = Auth.auth().currentUser?.uid else {
            return
        }
        self.activitylistsAdded = activitylistsAdded
        self.activitylistsRemoved = activitylistsRemoved
        self.activitylistsChanged = activitylistsChanged
        currentUserActivitylistsAddHandle = userActivitylistsDatabaseRef.observe(.childAdded, with: { snapshot in
            if let completion = self.activitylistsAdded {
                let activitylistID = snapshot.key
                let ref = Database.database().reference()
                var handle = UInt.max
                handle = ref.child(activitylistsEntity).child(activitylistID).observe(.childChanged) { _ in
                    ref.removeObserver(withHandle: handle)
                    self.getActivitylistsFromSnapshot(ID: snapshot.key, completion: completion)
                }
            }
        })
        
        currentUserActivitylistsChangeHandle = userActivitylistsDatabaseRef.observe(.childChanged, with: { snapshot in
            if let completion = self.activitylistsChanged {
                self.getActivitylistsFromSnapshot(ID: snapshot.key, completion: completion)
            }
        })
        
        currentUserActivitylistsRemoveHandle = userActivitylistsDatabaseRef.observe(.childRemoved, with: { snapshot in
            if let completion = self.activitylistsRemoved {
                self.getActivitylistsFromSnapshot(ID: snapshot.key, completion: completion)
            }
        })
        
    }
    
    func getActivitylistsFromSnapshot(ID: String, completion: @escaping ([Activitylist])->()) {
        guard let currentUserID = Auth.auth().currentUser?.uid else {
            return
        }
        let ref = Database.database().reference()
        var activitylists: [Activitylist] = []
        let group = DispatchGroup()
        group.enter()
        ref.child(userActivitylistsEntity).child(currentUserID).child(ID).observeSingleEvent(of: .value, with: { snapshot in
            if snapshot.exists(), let userActivitylistInfo = snapshot.value {
                if let userActivitylist = try? FirebaseDecoder().decode(Activitylist.self, from: userActivitylistInfo) {
                    ref.child(activitylistsEntity).child(ID).observeSingleEvent(of: .value, with: { activitylistSnapshot in
                        if activitylistSnapshot.exists(), let activitylistSnapshotValue = activitylistSnapshot.value {
                            if let activitylist = try? FirebaseDecoder().decode(Activitylist.self, from: activitylistSnapshotValue) {
                                activitylist.badge = userActivitylist.badge
                                activitylist.muted = userActivitylist.muted
                                activitylist.pinned = userActivitylist.pinned
                                activitylists.append(activitylist)
                            }
                        }
                        group.leave()
                    })
                }
            } else {
                ref.child(activitylistsEntity).child(ID).observeSingleEvent(of: .value, with: { activitylistSnapshot in
                    if activitylistSnapshot.exists(), let activitylistSnapshotValue = activitylistSnapshot.value {
                        if let activitylist = try? FirebaseDecoder().decode(Activitylist.self, from: activitylistSnapshotValue) {
                            activitylists.append(activitylist)
                        }
                    }
                    group.leave()
                })
            }
        })
        
        group.notify(queue: .main) {
            completion(activitylists)
        }
    }
}

