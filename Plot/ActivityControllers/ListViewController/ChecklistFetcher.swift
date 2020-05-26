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
        
    fileprivate var userChecklistsDatabaseRef: DatabaseReference!
    fileprivate var checklistsDatabaseRef: DatabaseReference!
    fileprivate var currentUserChecklistsAddHandle = DatabaseHandle()
    fileprivate var currentUserChecklistsRemoveHandle = DatabaseHandle()
    fileprivate var checklistsChangedHandle = DatabaseHandle()
    
    var checklistsAdded: (([Checklist])->())?
    var checklistsRemoved: (([Checklist])->())?
    var checklistsChanged: (([Checklist])->())?
    
    fileprivate var isGroupAlreadyFinished = false
    
    func fetchChecklists(completion: @escaping ([Checklist])->()) {
        guard let currentUserID = Auth.auth().currentUser?.uid else {
            completion([])
            return
        }
                
        let ref = Database.database().reference()
        userChecklistsDatabaseRef = Database.database().reference().child(userChecklistsEntity).child(currentUserID)
        userChecklistsDatabaseRef.observeSingleEvent(of: .value, with: { snapshot in
            if snapshot.exists(), let checklistIDs = snapshot.value as? [String: AnyObject] {
                var checklists: [Checklist] = []
                let group = DispatchGroup()
                for (checklistID, userChecklistInfo) in checklistIDs {
                    if let userChecklist = try? FirebaseDecoder().decode(Checklist.self, from: userChecklistInfo) {
                        group.enter()
                        ref.child(checklistsEntity).child(checklistID).observeSingleEvent(of: .value, with: { checklistSnapshot in
                            if checklistSnapshot.exists(), let checklistSnapshotValue = checklistSnapshot.value {
                                if let checklist = try? FirebaseDecoder().decode(Checklist.self, from: checklistSnapshotValue) {
                                    checklist.badge = userChecklist.badge
                                    checklist.muted = userChecklist.muted
                                    checklist.pinned = userChecklist.pinned
                                    checklists.append(checklist)
                                }
                            }
                            group.leave()
                        })
                    } else {
                        group.enter()
                        ref.child(checklistsEntity).child(checklistID).observeSingleEvent(of: .value, with: { checklistSnapshot in
                            if checklistSnapshot.exists(), let checklistSnapshotValue = checklistSnapshot.value {
                                if let checklist = try? FirebaseDecoder().decode(Checklist.self, from: checklistSnapshotValue) {
                                    checklists.append(checklist)
                                }
                            }
                            group.leave()
                        })
                    }
                }
                group.notify(queue: .main) {
                    completion(checklists)
                }
            } else {
                completion([])
            }
        })
    }
    
    func observeChecklistForCurrentUser(checklistsAdded: @escaping ([Checklist])->(), checklistsRemoved: @escaping ([Checklist])->()) {
        print("observeChecklistForCurrentUser")
        self.checklistsAdded = checklistsAdded
        self.checklistsRemoved = checklistsRemoved
        currentUserChecklistsAddHandle = userChecklistsDatabaseRef.observe(.childAdded, with: { snapshot in
            print("observeChecklistForAdded")
            if let completion = self.checklistsAdded {
                let checklistID = snapshot.key
                let ref = Database.database().reference()
                var handle = UInt.max
                handle = ref.child(checklistsEntity).child(checklistID).observe(.value) { _ in
                    ref.removeObserver(withHandle: handle)
                    self.getChecklistsFromSnapshot(snapshot: snapshot, completion: completion)
                }
            }
        })
        
        currentUserChecklistsRemoveHandle = userChecklistsDatabaseRef.observe(.childRemoved, with: { snapshot in
            print("observeChecklistForRemoved")
            if let completion = self.checklistsRemoved {
                self.getChecklistsFromSnapshot(snapshot: snapshot, completion: completion)
            }
        })
        
//        checklistsChangedHandle = checklistsDatabaseRef.observe(.value, with: { snapshot in
//            print("checklistsChangedHandle")
//            if let completion = self.checklistsAdded {
//                let checklistID = snapshot.key
//                let ref = Database.database().reference()
//                var handle = UInt.max
//                handle = ref.child(checklistsEntity).child(checklistID).observe(.childAdded) { _ in
//                    ref.removeObserver(withHandle: handle)
//                    self.getChecklistsFromSnapshot(snapshot: snapshot, completion: completion)
//                }
//            }
//        })
    }
    
    func getChecklistsFromSnapshot(snapshot: DataSnapshot, completion: @escaping ([Checklist])->()) {
        if snapshot.exists() {
            let checklistID = snapshot.key
            let ref = Database.database().reference()
            var checklists: [Checklist] = []
            let group = DispatchGroup()
            group.enter()
            ref.child(checklistsEntity).child(checklistID).observeSingleEvent(of: .value, with: { checklistSnapshot in
                if checklistSnapshot.exists(), let checklistSnapshotValue = checklistSnapshot.value {
                    if let checklist = try? FirebaseDecoder().decode(Checklist.self, from: checklistSnapshotValue) {
                        checklists.append(checklist)
                    }
                }
                group.leave()
            })
            group.notify(queue: .main) {
                completion(checklists)
            }
        } else {
            completion([])
        }
    }
}
