//
//  SleepFetcher.swift
//  Plot
//
//  Created by Cory McHattie on 12/12/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import UIKit
import Firebase
import CodableFirebase

class SleepFetcher: NSObject {
        
    fileprivate var userSleepDatabaseRef: DatabaseReference!
    fileprivate var currentUserSleepAddHandle = DatabaseHandle()
    
    var sleepInitalAdd: (([Scheduler])->())?
    var sleepAdded: (([Scheduler])->())?
    
    var sleepIDs: [String] = []
        
    func fetchSleep(completion: @escaping ([Scheduler])->()) {
        guard let currentUserID = Auth.auth().currentUser?.uid else {
            completion([])
            return
        }
                
        let ref = Database.database().reference()
        userSleepDatabaseRef = ref.child(userSleepEntity).child(currentUserID)
        userSleepDatabaseRef.observeSingleEvent(of: .value, with: { snapshot in
            if snapshot.exists(), let sleepIDs = snapshot.value as? [String: AnyObject] {
                var sleeps: [Scheduler] = []
                let group = DispatchGroup()
                for (sleepID, _) in sleepIDs {
                    group.enter()
                    ref.child(sleepEntity).child(sleepID).observeSingleEvent(of: .value, with: { sleepSnapshot in
                        if sleepSnapshot.exists(), let sleepSnapshotValue = sleepSnapshot.value {
                            if let sleep = try? FirebaseDecoder().decode(Scheduler.self, from: sleepSnapshotValue) {
                                sleeps.append(sleep)
                            }
                        }
                        group.leave()
                    })
                }
                group.notify(queue: .main) {
                    completion(sleeps)
                }
            } else {
                completion([])
            }
        })
    }
    
    func observeSleepForCurrentUser(sleepAdded: @escaping ([Scheduler])->()) {
        guard let _ = Auth.auth().currentUser?.uid else {
            return
        }
        self.sleepAdded = sleepAdded
        currentUserSleepAddHandle = userSleepDatabaseRef.observe(.childAdded, with: { snapshot in
            if let completion = self.sleepAdded {
                let sleepID = snapshot.key
                let ref = Database.database().reference()
                var handle = UInt.max
                handle = ref.child(sleepEntity).child(sleepID).observe(.childChanged) { _ in
                    ref.removeObserver(withHandle: handle)
                    self.getSleepFromSnapshot(ID: snapshot.key, completion: completion)
                }
            }
        })
    }
    
    func getSleepFromSnapshot(ID: String, completion: @escaping ([Scheduler])->()) {
        guard let _ = Auth.auth().currentUser?.uid else {
            return
        }
        
        let ref = Database.database().reference()
        var sleeps: [Scheduler] = []
        let group = DispatchGroup()
        group.enter()
        
        ref.child(sleepEntity).child(ID).observeSingleEvent(of: .value, with: { sleepSnapshot in
            if sleepSnapshot.exists(), let sleepSnapshotValue = sleepSnapshot.value {
                if let sleep = try? FirebaseDecoder().decode(Scheduler.self, from: sleepSnapshotValue) {
                    sleeps.append(sleep)
                }
            }
            group.leave()
        })
        
        group.notify(queue: .main) {
            completion(sleeps)
        }
    }
}
