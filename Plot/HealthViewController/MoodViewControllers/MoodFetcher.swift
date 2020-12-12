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
        
    fileprivate var userMoodsDatabaseRef: DatabaseReference!
    fileprivate var currentUserMoodsAddHandle = DatabaseHandle()
    
    var moodsAdded: (([Mood])->())?
    
    fileprivate var isGroupAlreadyFinished = false
    
    func fetchMoods(completion: @escaping ([Mood])->()) {
        guard let currentUserID = Auth.auth().currentUser?.uid else {
            completion([])
            return
        }
                
        let ref = Database.database().reference()
        userMoodsDatabaseRef = Database.database().reference().child(userMoodsEntity).child(currentUserID)
        userMoodsDatabaseRef.observeSingleEvent(of: .value, with: { snapshot in
            if snapshot.exists(), let moodIDs = snapshot.value as? [String: AnyObject] {
                var moods: [Mood] = []
                let group = DispatchGroup()
                for (moodID, _) in moodIDs {
                    group.enter()
                    ref.child(moodsEntity).child(moodID).observeSingleEvent(of: .value, with: { moodSnapshot in
                        if moodSnapshot.exists(), let moodSnapshotValue = moodSnapshot.value {
                            if let mood = try? FirebaseDecoder().decode(Mood.self, from: moodSnapshotValue) {
                                moods.append(mood)
                            }
                        }
                        group.leave()
                    })
                }
                group.notify(queue: .main) {
                    completion(moods)
                }
            } else {
                completion([])
            }
        })
    }
    
    func observeMoodForCurrentUser(moodsAdded: @escaping ([Mood])->()) {
        guard let _ = Auth.auth().currentUser?.uid else {
            return
        }
        self.moodsAdded = moodsAdded
        currentUserMoodsAddHandle = userMoodsDatabaseRef.observe(.childAdded, with: { snapshot in
            if let completion = self.moodsAdded {
                let moodID = snapshot.key
                let ref = Database.database().reference()
                var handle = UInt.max
                handle = ref.child(moodsEntity).child(moodID).observe(.value) { _ in
                    ref.removeObserver(withHandle: handle)
                    self.getMoodsFromSnapshot(snapshot: snapshot, completion: completion)
                }
            }
        })
    }
    
    func getMoodsFromSnapshot(snapshot: DataSnapshot, completion: @escaping ([Mood])->()) {
        if snapshot.exists() {
            guard let _ = Auth.auth().currentUser?.uid else {
                return
            }
            
            let moodID = snapshot.key
            let ref = Database.database().reference()
            var moods: [Mood] = []
            let group = DispatchGroup()
            group.enter()
            
            ref.child(moodsEntity).child(moodID).observeSingleEvent(of: .value, with: { moodSnapshot in
                if moodSnapshot.exists(), let moodSnapshotValue = moodSnapshot.value {
                    if let mood = try? FirebaseDecoder().decode(Mood.self, from: moodSnapshotValue) {
                        moods.append(mood)
                    }
                }
                group.leave()
            })
            
            group.notify(queue: .main) {
                completion(moods)
            }
        } else {
            completion([])
        }
    }
}
