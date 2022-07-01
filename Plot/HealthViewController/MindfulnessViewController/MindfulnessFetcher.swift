//
//  MindfulnessFetcher.swift
//  Plot
//
//  Created by Cory McHattie on 12/12/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import UIKit
import Firebase
import CodableFirebase

class MindfulnessFetcher: NSObject {
        
    fileprivate var userMindfulnessDatabaseRef: DatabaseReference!
    fileprivate var currentUserMindfulnessAddHandle = DatabaseHandle()
    fileprivate var currentUserMindfulnessChangeHandle = DatabaseHandle()
    fileprivate var currentUserMindfulnessRemoveHandle = DatabaseHandle()
    
    
    var mindfulnessAdded: (([Mindfulness])->())?
    var mindfulnessRemoved: (([Mindfulness])->())?
    var mindfulnessChanged: (([Mindfulness])->())?
    
    fileprivate var isGroupAlreadyFinished = false
    
    func fetchMindfulness(completion: @escaping ([Mindfulness])->()) {
        guard let currentUserID = Auth.auth().currentUser?.uid else {
            completion([])
            return
        }
                
        let ref = Database.database().reference()
        userMindfulnessDatabaseRef = Database.database().reference().child(userMindfulnessEntity).child(currentUserID)
        userMindfulnessDatabaseRef.observeSingleEvent(of: .value, with: { snapshot in
            if snapshot.exists(), let mindfulnessIDs = snapshot.value as? [String: AnyObject] {
                var mindfulnessList: [Mindfulness] = []
                let group = DispatchGroup()
                for (mindfulnessID, userMindfulnessInfo) in mindfulnessIDs {
                    if let userMindfulness = try? FirebaseDecoder().decode(Mindfulness.self, from: userMindfulnessInfo) {
                        group.enter()
                        ref.child(mindfulnessEntity).child(mindfulnessID).observeSingleEvent(of: .value, with: { mindfulnessSnapshot in
                            if mindfulnessSnapshot.exists(), let mindfulnessSnapshotValue = mindfulnessSnapshot.value {
                                if let mindfulness = try? FirebaseDecoder().decode(Mindfulness.self, from: mindfulnessSnapshotValue) {
                                    var _mindfulness = mindfulness
                                    _mindfulness.badge = userMindfulness.badge
                                    _mindfulness.muted = userMindfulness.muted
                                    _mindfulness.pinned = userMindfulness.pinned
                                    mindfulnessList.append(_mindfulness)
                                }
                            }
                            group.leave()
                        })
                    } else {
                        group.enter()
                        ref.child(mindfulnessEntity).child(mindfulnessID).observeSingleEvent(of: .value, with: { mindfulnessSnapshot in
                            if mindfulnessSnapshot.exists(), let mindfulnessSnapshotValue = mindfulnessSnapshot.value {
                                if let mindfulness = try? FirebaseDecoder().decode(Mindfulness.self, from: mindfulnessSnapshotValue) {
                                    mindfulnessList.append(mindfulness)
                                }
                            }
                            group.leave()
                        })
                    }
                }
                group.notify(queue: .main) {
                    completion(mindfulnessList)
                }
            } else {
                completion([])
            }
        })
    }
    
    func observeMindfulnessForCurrentUser(mindfulnessAdded: @escaping ([Mindfulness])->(), mindfulnessRemoved: @escaping ([Mindfulness])->(), mindfulnessChanged: @escaping ([Mindfulness])->()) {
        guard let _ = Auth.auth().currentUser?.uid else {
            return
        }
        self.mindfulnessAdded = mindfulnessAdded
        self.mindfulnessRemoved = mindfulnessRemoved
        self.mindfulnessChanged = mindfulnessChanged
        currentUserMindfulnessAddHandle = userMindfulnessDatabaseRef.observe(.childAdded, with: { snapshot in
            if let completion = self.mindfulnessAdded {
                let mindfulnessID = snapshot.key
                let ref = Database.database().reference()
                var handle = UInt.max
                handle = ref.child(mindfulnessEntity).child(mindfulnessID).observe(.childChanged) { _ in
                    ref.removeObserver(withHandle: handle)
                    self.getMindfulnessFromSnapshot(snapshot: snapshot, completion: completion)
                }
            }
        })
        
        currentUserMindfulnessChangeHandle = userMindfulnessDatabaseRef.observe(.childChanged, with: { snapshot in
            if let completion = self.mindfulnessChanged {
                self.getMindfulnessFromSnapshot(snapshot: snapshot, completion: completion)
            }
        })
        
        currentUserMindfulnessRemoveHandle = userMindfulnessDatabaseRef.observe(.childRemoved, with: { snapshot in
            if let completion = self.mindfulnessRemoved {
                self.getMindfulnessFromSnapshot(snapshot: snapshot, completion: completion)
            }
        })
        
    }
    
    func getMindfulnessFromSnapshot(snapshot: DataSnapshot, completion: @escaping ([Mindfulness])->()) {
        if snapshot.exists() {
            guard let currentUserID = Auth.auth().currentUser?.uid else {
                return
            }
            let mindfulnessID = snapshot.key
            let ref = Database.database().reference()
            var mindfulnessList: [Mindfulness] = []
            let group = DispatchGroup()
            group.enter()
            ref.child(userMindfulnessEntity).child(currentUserID).child(mindfulnessID).observeSingleEvent(of: .value, with: { snapshot in
                if snapshot.exists(), let userMindfulnessInfo = snapshot.value {
                    if let userMindfulness = try? FirebaseDecoder().decode(Mindfulness.self, from: userMindfulnessInfo) {
                        ref.child(mindfulnessEntity).child(mindfulnessID).observeSingleEvent(of: .value, with: { mindfulnessSnapshot in
                            if mindfulnessSnapshot.exists(), let mindfulnessSnapshotValue = mindfulnessSnapshot.value {
                                if let mindfulness = try? FirebaseDecoder().decode(Mindfulness.self, from: mindfulnessSnapshotValue) {
                                    var _mindfulness = mindfulness
                                    _mindfulness.badge = userMindfulness.badge
                                    _mindfulness.muted = userMindfulness.muted
                                    _mindfulness.pinned = userMindfulness.pinned
                                    mindfulnessList.append(_mindfulness)
                                }
                            }
                            group.leave()
                        })
                    }
                } else {
                    ref.child(mindfulnessEntity).child(mindfulnessID).observeSingleEvent(of: .value, with: { mindfulnessSnapshot in
                        if mindfulnessSnapshot.exists(), let mindfulnessSnapshotValue = mindfulnessSnapshot.value {
                            if let mindfulness = try? FirebaseDecoder().decode(Mindfulness.self, from: mindfulnessSnapshotValue) {
                                mindfulnessList.append(mindfulness)
                            }
                        }
                        group.leave()
                    })
                }
            })
            
            group.notify(queue: .main) {
                completion(mindfulnessList)
            }
        } else {
            completion([])
        }
    }
}
