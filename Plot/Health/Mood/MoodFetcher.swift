//
//  MoodFetcher.swift
//  Plot
//
//  Created by Cory McHattie on 12/12/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import UIKit
import Firebase
import CodableFirebase

class MoodFetcher: NSObject {
        
    fileprivate var userMoodDatabaseRef: DatabaseReference!
    fileprivate var currentUserMoodAddHandle = DatabaseHandle()
    fileprivate var currentUserMoodChangeHandle = DatabaseHandle()
    fileprivate var currentUserMoodRemoveHandle = DatabaseHandle()
    
    var moodInitialAdd: (([Mood])->())?
    var moodAdded: (([Mood])->())?
    var moodRemoved: (([Mood])->())?
    var moodChanged: (([Mood])->())?
    
    func observeMoodForCurrentUser(moodInitialAdd: @escaping ([Mood])->(), moodAdded: @escaping ([Mood])->(), moodRemoved: @escaping ([Mood])->(), moodChanged: @escaping ([Mood])->()) {
        guard let currentUserID = Auth.auth().currentUser?.uid else {
            return
        }
                
        let ref = Database.database().reference()
        userMoodDatabaseRef = ref.child(userMoodEntity).child(currentUserID)
        
        self.moodInitialAdd = moodInitialAdd
        self.moodAdded = moodAdded
        self.moodRemoved = moodRemoved
        self.moodChanged = moodChanged
        
        var userMoods: [String: UserMood] = [:]
        
        let endDateTimeFilter = Date().monthAfter // Replace with your desired filter value
        let startDateTimeFilter = Date().monthBefore // Replace with your desired filter value
        
        userMoodDatabaseRef.queryOrdered(byChild: "moodDate").observeSingleEvent(of: .value, with: { snapshot in
            guard snapshot.exists() else {
                moodInitialAdd([])
                return
            }
            
            if let completion = self.moodInitialAdd {
                var moods: [Mood] = []
                let group = DispatchGroup()
                var counter = 0
                for child in snapshot.children.allObjects.reversed() {
                    let snapshot = child as! DataSnapshot
                    guard let userMoodInfo = snapshot.value as? [String : AnyObject] else { return }
                    var handle = UInt.max
                    if var userMood = try? FirebaseDecoder().decode(UserMood.self, from: userMoodInfo) {
                        
//                        if (userMood.moodDate != nil && startDateTimeFilter <= userMood.moodDate! && userMood.moodDate! <= endDateTimeFilter) {
//                            userMood.current = true
//                            group.enter()
//                            counter += 1
//                        }
                        
                        userMood.current = true
                        group.enter()
                        counter += 1
                        
                        userMoods[snapshot.key] = userMood
                        
                        handle = ref.child(moodEntity).child(snapshot.key).observe(.value) { snapshot in
                            ref.removeObserver(withHandle: handle)
                            if snapshot.exists(), let snapshotValue = snapshot.value {
                                if let mood = try? FirebaseDecoder().decode(Mood.self, from: snapshotValue), let userMood = userMoods[snapshot.key] {
                                    var _mood = mood
                                    _mood.badge = userMood.badge
                                    _mood.muted = userMood.muted
                                    _mood.pinned = userMood.pinned
                                    if counter > 0, userMood.current ?? false {
                                        moods.append(_mood)
                                        group.leave()
                                        counter -= 1
                                    } else if counter > 0 {
                                        moods.append(_mood)
                                    } else {
                                        moods = [_mood]
                                        completion(moods)
                                        return
                                    }
                                }
                            } else {
                                if counter > 0, userMood.current ?? false {
                                    group.leave()
                                    counter -= 1
                                }
                            }
                        }
                    }
                }
                group.notify(queue: .main) {
                    completion(moods)
                }
            }
        })
        
        currentUserMoodAddHandle = userMoodDatabaseRef.observe(.childAdded, with: { snapshot in
            if userMoods[snapshot.key] == nil {
                if let completion = self.moodAdded {
                    var handle = UInt.max
                    let ID = snapshot.key
                    self.getUserDataFromSnapshot(ID: ID) { moodList in
                        for userMood in moodList {
                            userMoods[ID] = userMood
                            handle = ref.child(moodEntity).child(ID).observe(.value) { snapshot in
                                ref.removeObserver(withHandle: handle)
                                if snapshot.exists(), let snapshotValue = snapshot.value {
                                    if let mood = try? FirebaseDecoder().decode(Mood.self, from: snapshotValue), let userMood = userMoods[ID] {
                                        var _mood = mood
                                        _mood.badge = userMood.badge
                                        _mood.muted = userMood.muted
                                        _mood.pinned = userMood.pinned
                                        completion([_mood])
                                    }
                                }
                            }
                        }
                    }
                }
            }
        })
        
        currentUserMoodChangeHandle = userMoodDatabaseRef.observe(.childChanged, with: { snapshot in
            if let completion = self.moodChanged {
                MoodFetcher.getDataFromSnapshot(ID: snapshot.key) { moodList in
                    for mood in moodList {
                        userMoods[mood.id] = UserMood(mood: mood)
                    }
                    completion(moodList)
                }
            }
        })
        
        currentUserMoodRemoveHandle = userMoodDatabaseRef.observe(.childRemoved, with: { snapshot in
            if let completion = self.moodRemoved {
                userMoods[snapshot.key] = nil
                MoodFetcher.getDataFromSnapshot(ID: snapshot.key, completion: completion)
            }
        })
        
    }
    
    class func getDataFromSnapshot(ID: String, completion: @escaping ([Mood])->()) {
        guard let currentUserID = Auth.auth().currentUser?.uid else {
            return
        }
        let ref = Database.database().reference()
        var moodList: [Mood] = []
        let group = DispatchGroup()
        group.enter()
        ref.child(userMoodEntity).child(currentUserID).child(ID).observeSingleEvent(of: .value, with: { snapshot in
            if snapshot.exists(), let userMoodInfo = snapshot.value {
                if let userMood = try? FirebaseDecoder().decode(UserMood.self, from: userMoodInfo) {
                    ref.child(moodEntity).child(ID).observeSingleEvent(of: .value, with: { moodSnapshot in
                        if moodSnapshot.exists(), let moodSnapshotValue = moodSnapshot.value {
                            if let mood = try? FirebaseDecoder().decode(Mood.self, from: moodSnapshotValue) {
                                var _mood = mood
                                _mood.badge = userMood.badge
                                _mood.muted = userMood.muted
                                _mood.pinned = userMood.pinned
                                moodList.append(_mood)
                            }
                        }
                        group.leave()
                    })
                }
            } else {
                ref.child(moodEntity).child(ID).observeSingleEvent(of: .value, with: { moodSnapshot in
                    if moodSnapshot.exists(), let moodSnapshotValue = moodSnapshot.value {
                        if let mood = try? FirebaseDecoder().decode(Mood.self, from: moodSnapshotValue) {
                            moodList.append(mood)
                        }
                    }
                    group.leave()
                })
            }
        })
        
        group.notify(queue: .main) {
            completion(moodList)
        }
    }
    
    func getUserDataFromSnapshot(ID: String, completion: @escaping ([UserMood])->()) {
        guard let currentUserID = Auth.auth().currentUser?.uid else {
            return
        }
        let ref = Database.database().reference()
        var mood: [UserMood] = []
        let group = DispatchGroup()
        group.enter()
        ref.child(userMoodEntity).child(currentUserID).child(ID).observeSingleEvent(of: .value, with: { snapshot in
            if snapshot.exists(), let userMoodInfo = snapshot.value {
                if let userMood = try? FirebaseDecoder().decode(UserMood.self, from: userMoodInfo) {
                    mood.append(userMood)
                    group.leave()
                }
            }
        })
        group.notify(queue: .main) {
            completion(mood)
        }
    }
}
