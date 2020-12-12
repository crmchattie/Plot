//
//  WorkFetcher.swift
//  Plot
//
//  Created by Cory McHattie on 12/12/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import UIKit
import Firebase
import CodableFirebase

class WorkFetcher: NSObject {
        
    fileprivate var userWorkDatabaseRef: DatabaseReference!
    fileprivate var currentUserWorkAddHandle = DatabaseHandle()
    
    var workAdded: (([Scheduler])->())?
    
    fileprivate var isGroupAlreadyFinished = false
    
    func fetchWork(completion: @escaping ([Scheduler])->()) {
        guard let currentUserID = Auth.auth().currentUser?.uid else {
            completion([])
            return
        }
                
        let ref = Database.database().reference()
        userWorkDatabaseRef = Database.database().reference().child(userWorkEntity).child(currentUserID)
        userWorkDatabaseRef.observeSingleEvent(of: .value, with: { snapshot in
            if snapshot.exists(), let workIDs = snapshot.value as? [String: AnyObject] {
                var works: [Scheduler] = []
                let group = DispatchGroup()
                for (workID, _) in workIDs {
                    group.enter()
                    ref.child(workEntity).child(workID).observeSingleEvent(of: .value, with: { workSnapshot in
                        if workSnapshot.exists(), let workSnapshotValue = workSnapshot.value {
                            if let work = try? FirebaseDecoder().decode(Scheduler.self, from: workSnapshotValue) {
                                works.append(work)
                            }
                        }
                        group.leave()
                    })
                }
                group.notify(queue: .main) {
                    completion(works)
                }
            } else {
                completion([])
            }
        })
    }
    
    func observeWorkForCurrentUser(workAdded: @escaping ([Scheduler])->()) {
        guard let _ = Auth.auth().currentUser?.uid else {
            return
        }
        self.workAdded = workAdded
        currentUserWorkAddHandle = userWorkDatabaseRef.observe(.childAdded, with: { snapshot in
            if let completion = self.workAdded {
                let workID = snapshot.key
                let ref = Database.database().reference()
                var handle = UInt.max
                handle = ref.child(workEntity).child(workID).observe(.value) { _ in
                    ref.removeObserver(withHandle: handle)
                    self.getWorkFromSnapshot(snapshot: snapshot, completion: completion)
                }
            }
        })
    }
    
    func getWorkFromSnapshot(snapshot: DataSnapshot, completion: @escaping ([Scheduler])->()) {
        if snapshot.exists() {
            guard let _ = Auth.auth().currentUser?.uid else {
                return
            }
            
            let workID = snapshot.key
            let ref = Database.database().reference()
            var works: [Scheduler] = []
            let group = DispatchGroup()
            group.enter()
            
            ref.child(workEntity).child(workID).observeSingleEvent(of: .value, with: { workSnapshot in
                if workSnapshot.exists(), let workSnapshotValue = workSnapshot.value {
                    if let work = try? FirebaseDecoder().decode(Scheduler.self, from: workSnapshotValue) {
                        works.append(work)
                    }
                }
                group.leave()
            })
            
            group.notify(queue: .main) {
                completion(works)
            }
        } else {
            completion([])
        }
    }
}

