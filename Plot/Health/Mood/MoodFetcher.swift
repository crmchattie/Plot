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
        
        var moods: [String: Mood] = [:]
                
        userMoodDatabaseRef.observeSingleEvent(of: .value, with: { snapshot in
            guard snapshot.exists() else {
                moodInitialAdd([])
                return
            }
            if let completion = self.moodInitialAdd {
                var moodList: [Mood] = []
                let group = DispatchGroup()
                var counter = 0
                let moodIDs = snapshot.value as? [String: AnyObject] ?? [:]
                for (ID, userMoodInfo) in moodIDs {
                    group.enter()
                    counter += 1
                    if let mood = try? FirebaseDecoder().decode(Mood.self, from: userMoodInfo) {
                        moods[ID] = mood
                        if counter > 0 {
                            moodList.append(mood)
                            group.leave()
                            counter -= 1
                        } else {
                            moodList = [mood]
                            completion(moodList)
                            return
                        }
                    } else {
                        if counter > 0 {
                            group.leave()
                            counter -= 1
                        }
                    }
                }
                group.notify(queue: .main) {
                    completion(moodList)
                }
            }
        })
        
        currentUserMoodAddHandle = userMoodDatabaseRef.observe(.childAdded, with: { snapshot in
            if moods[snapshot.key] == nil {
                if let completion = self.moodAdded {
                    let ID = snapshot.key
                    self.getUserDataFromSnapshot(ID: ID) { moodList in
                        for mood in moodList {
                            moods[ID] = mood
                            completion([mood])
                        }
                    }
                }
            }
        })
        
        currentUserMoodChangeHandle = userMoodDatabaseRef.observe(.childChanged, with: { snapshot in
            if let completion = self.moodChanged {
                MoodFetcher.getDataFromSnapshot(ID: snapshot.key) { moodList in
                    for mood in moodList {
                        moods[mood.id] = mood
                    }
                    completion(moodList)
                }
            }
        })
        
        currentUserMoodRemoveHandle = userMoodDatabaseRef.observe(.childRemoved, with: { snapshot in
            if let completion = self.moodRemoved {
                moods[snapshot.key] = nil
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
    
    func getUserDataFromSnapshot(ID: String, completion: @escaping ([Mood])->()) {
        guard let currentUserID = Auth.auth().currentUser?.uid else {
            return
        }
        let ref = Database.database().reference()
        var mood: [Mood] = []
        let group = DispatchGroup()
        group.enter()
        ref.child(userMoodEntity).child(currentUserID).child(ID).observeSingleEvent(of: .value, with: { snapshot in
            if snapshot.exists(), let userMoodInfo = snapshot.value {
                if let userMood = try? FirebaseDecoder().decode(Mood.self, from: userMoodInfo) {
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
