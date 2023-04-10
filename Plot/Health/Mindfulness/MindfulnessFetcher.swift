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
    
    var mindfulnessInitialAdd: (([Mindfulness])->())?
    var mindfulnessAdded: (([Mindfulness])->())?
    var mindfulnessRemoved: (([Mindfulness])->())?
    var mindfulnessChanged: (([Mindfulness])->())?
    
    var unloadedMindfulnesses: [String: UserMindfulness] = [:]
    
    func observeMindfulnessForCurrentUser(mindfulnessInitialAdd: @escaping ([Mindfulness])->(), mindfulnessAdded: @escaping ([Mindfulness])->(), mindfulnessRemoved: @escaping ([Mindfulness])->(), mindfulnessChanged: @escaping ([Mindfulness])->()) {
        guard let currentUserID = Auth.auth().currentUser?.uid else {
            return
        }
                
        let ref = Database.database().reference()
        userMindfulnessDatabaseRef = ref.child(userMindfulnessEntity).child(currentUserID)
        
        self.mindfulnessInitialAdd = mindfulnessInitialAdd
        self.mindfulnessAdded = mindfulnessAdded
        self.mindfulnessRemoved = mindfulnessRemoved
        self.mindfulnessChanged = mindfulnessChanged
        
        var userMindfulnesses: [String: UserMindfulness] = [:]
        
        userMindfulnessDatabaseRef.observeSingleEvent(of: .value, with: { snapshot in
            guard snapshot.exists() else {
                mindfulnessInitialAdd([])
                return
            }
            
            if let completion = self.mindfulnessInitialAdd {
                var mindfulnesses: [Mindfulness] = []
                let group = DispatchGroup()
                var counter = 0
                let mindfulnessIDs = snapshot.value as? [String: AnyObject] ?? [:]
                for (ID, userMindfulnessInfo) in mindfulnessIDs {
                    var handle = UInt.max
                    if let userMindfulness = try? FirebaseDecoder().decode(UserMindfulness.self, from: userMindfulnessInfo) {
                        userMindfulnesses[ID] = userMindfulness
                        
                        guard let startDateTime = userMindfulness.startDateTime, startDateTime > Date().monthBefore.monthBefore else {
                            self.unloadedMindfulnesses[ID] = userMindfulness
                            continue
                        }
                        
                        group.enter()
                        counter += 1
                        handle = ref.child(mindfulnessEntity).child(ID).observe(.value) { snapshot in
                            ref.removeObserver(withHandle: handle)
                            if snapshot.exists(), let snapshotValue = snapshot.value {
                                if let mindfulness = try? FirebaseDecoder().decode(Mindfulness.self, from: snapshotValue), let userMindfulness = userMindfulnesses[ID] {
                                    var _mindfulness = mindfulness
                                    _mindfulness.hkSampleID = userMindfulness.hkSampleID
                                    _mindfulness.badge = userMindfulness.badge
                                    _mindfulness.muted = userMindfulness.muted
                                    _mindfulness.pinned = userMindfulness.pinned
                                    if counter > 0 {
                                        mindfulnesses.append(_mindfulness)
                                        group.leave()
                                        counter -= 1
                                    } else {
                                        mindfulnesses = [_mindfulness]
                                        completion(mindfulnesses)
                                        return
                                    }
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
                group.notify(queue: .main) {
                    completion(mindfulnesses)
                }
            }
        })
        
        currentUserMindfulnessAddHandle = userMindfulnessDatabaseRef.observe(.childAdded, with: { snapshot in
            if userMindfulnesses[snapshot.key] == nil {
                if let completion = self.mindfulnessAdded {
                    var handle = UInt.max
                    let ID = snapshot.key
                    self.getUserDataFromSnapshot(ID: ID) { mindfulnessList in
                        for userMindfulness in mindfulnessList {
                            userMindfulnesses[ID] = userMindfulness
                            handle = ref.child(mindfulnessEntity).child(ID).observe(.value) { snapshot in
                                ref.removeObserver(withHandle: handle)
                                if snapshot.exists(), let snapshotValue = snapshot.value {
                                    if let mindfulness = try? FirebaseDecoder().decode(Mindfulness.self, from: snapshotValue), let userMindfulness = userMindfulnesses[ID] {
                                        var _mindfulness = mindfulness
                                        _mindfulness.hkSampleID = userMindfulness.hkSampleID
                                        _mindfulness.badge = userMindfulness.badge
                                        _mindfulness.muted = userMindfulness.muted
                                        _mindfulness.pinned = userMindfulness.pinned
                                        completion([_mindfulness])
                                    }
                                }
                            }
                        }
                    }
                }
            }
        })
        
        currentUserMindfulnessChangeHandle = userMindfulnessDatabaseRef.observe(.childChanged, with: { snapshot in
            if let completion = self.mindfulnessChanged {
                MindfulnessFetcher.getDataFromSnapshot(ID: snapshot.key) { mindfulnessList in
                    for mindfulness in mindfulnessList {
                        userMindfulnesses[mindfulness.id] = UserMindfulness(mindfulness: mindfulness)
                    }
                    completion(mindfulnessList)
                }
            }
        })
        
        currentUserMindfulnessRemoveHandle = userMindfulnessDatabaseRef.observe(.childRemoved, with: { snapshot in
            if let completion = self.mindfulnessRemoved {
                userMindfulnesses[snapshot.key] = nil
                self.unloadedMindfulnesses[snapshot.key] = nil
                MindfulnessFetcher.getDataFromSnapshot(ID: snapshot.key, completion: completion)
            }
        })
        
    }
    
    class func getDataFromSnapshot(ID: String, completion: @escaping ([Mindfulness])->()) {
        guard let currentUserID = Auth.auth().currentUser?.uid else {
            return
        }
        let ref = Database.database().reference()
        var mindfulnessList: [Mindfulness] = []
        let group = DispatchGroup()
        group.enter()
        ref.child(userMindfulnessEntity).child(currentUserID).child(ID).observeSingleEvent(of: .value, with: { snapshot in
            if snapshot.exists(), let userMindfulnessInfo = snapshot.value {
                if let userMindfulness = try? FirebaseDecoder().decode(UserMindfulness.self, from: userMindfulnessInfo) {
                    ref.child(mindfulnessEntity).child(ID).observeSingleEvent(of: .value, with: { mindfulnessSnapshot in
                        if mindfulnessSnapshot.exists(), let mindfulnessSnapshotValue = mindfulnessSnapshot.value {
                            if let mindfulness = try? FirebaseDecoder().decode(Mindfulness.self, from: mindfulnessSnapshotValue) {
                                var _mindfulness = mindfulness
                                _mindfulness.hkSampleID = userMindfulness.hkSampleID
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
                ref.child(mindfulnessEntity).child(ID).observeSingleEvent(of: .value, with: { mindfulnessSnapshot in
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
    }
    
    func getUserDataFromSnapshot(ID: String, completion: @escaping ([UserMindfulness])->()) {
        guard let currentUserID = Auth.auth().currentUser?.uid else {
            return
        }
        let ref = Database.database().reference()
        var mindfulness: [UserMindfulness] = []
        let group = DispatchGroup()
        group.enter()
        ref.child(userMindfulnessEntity).child(currentUserID).child(ID).observeSingleEvent(of: .value, with: { snapshot in
            if snapshot.exists(), let userMindfulnessInfo = snapshot.value {
                if let userMindfulness = try? FirebaseDecoder().decode(UserMindfulness.self, from: userMindfulnessInfo) {
                    mindfulness.append(userMindfulness)
                    group.leave()
                }
            }
        })
        group.notify(queue: .main) {
            completion(mindfulness)
        }
    }
    
    func loadUnloadedMindfulness(date: Date?, completion: @escaping ([Mindfulness])->()) {
        let group = DispatchGroup()
        var mindfulnesses: [Mindfulness] = []
        if let date = date {
            let IDs = unloadedMindfulnesses.filter {
                $0.value.startDateTime ?? Date.distantPast > date
            }
            for (ID, _) in IDs {
                group.enter()
                MindfulnessFetcher.getDataFromSnapshot(ID: ID) { mindfulnessList in
                    mindfulnesses.append(contentsOf: mindfulnessList)
                    group.leave()
                }
            }
            mindfulnesses.sort(by: {
                $0.startDateTime ?? Date.distantPast > $1.startDateTime ?? Date.distantPast
            })
            group.notify(queue: .main) {
                completion(mindfulnesses)
            }
        } else {
            for (ID, _) in unloadedMindfulnesses {
                group.enter()
                MindfulnessFetcher.getDataFromSnapshot(ID: ID) { mindfulnessList in
                    mindfulnesses.append(contentsOf: mindfulnessList)
                    group.leave()
                }
            }
            mindfulnesses.sort(by: {
                $0.startDateTime ?? Date.distantPast > $1.startDateTime ?? Date.distantPast
            })
            group.notify(queue: .main) {
                completion(mindfulnesses)
            }
        }
    }
}
