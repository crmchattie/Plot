//
//  GrocerylistFetcher.swift
//  Plot
//
//  Created by Cory McHattie on 5/22/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import UIKit
import Firebase
import CodableFirebase

class GrocerylistFetcher: NSObject {
        
    fileprivate var userGrocerylistsDatabaseRef: DatabaseReference!
    fileprivate var currentUserGrocerylistsAddHandle = DatabaseHandle()
    fileprivate var currentUserGrocerylistsRemoveHandle = DatabaseHandle()
    
    var grocerylistsAdded: (([Grocerylist])->())?
    var grocerylistsRemoved: (([Grocerylist])->())?
    
    func fetchGrocerylists(completion: @escaping ([Grocerylist])->()) {
        guard let currentUserID = Auth.auth().currentUser?.uid else {
            completion([])
            return
        }
        
        let ref = Database.database().reference()
        userGrocerylistsDatabaseRef = Database.database().reference().child(userGrocerylistsEntity).child(currentUserID)
        userGrocerylistsDatabaseRef.observeSingleEvent(of: .value, with: { snapshot in
            if snapshot.exists(), let grocerylistIDs = snapshot.value as? [String: AnyObject] {
                var grocerylists: [Grocerylist] = []
                let group = DispatchGroup()
                for (grocerylistID, userGrocerylistInfo) in grocerylistIDs {
                    if let userGrocerylist = try? FirebaseDecoder().decode(Grocerylist.self, from: userGrocerylistInfo) {
                        group.enter()
                        ref.child(grocerylistsEntity).child(grocerylistID).observeSingleEvent(of: .value, with: { grocerylistSnapshot in
                            if grocerylistSnapshot.exists(), let grocerylistSnapshotValue = grocerylistSnapshot.value {
                                if let grocerylist = try? FirebaseDecoder().decode(Grocerylist.self, from: grocerylistSnapshotValue) {
                                    grocerylist.badge = userGrocerylist.badge
                                    grocerylist.muted = userGrocerylist.muted
                                    grocerylist.pinned = userGrocerylist.pinned
                                    grocerylists.append(grocerylist)
                                }
                            }
                            group.leave()
                        })
                    } else {
                        group.enter()
                        ref.child(grocerylistsEntity).child(grocerylistID).observeSingleEvent(of: .value, with: { grocerylistSnapshot in
                            if grocerylistSnapshot.exists(), let grocerylistSnapshotValue = grocerylistSnapshot.value {
                                if let grocerylist = try? FirebaseDecoder().decode(Grocerylist.self, from: grocerylistSnapshotValue) {
                                    grocerylists.append(grocerylist)
                                }
                            }
                            group.leave()
                        })
                    }
                }
                group.notify(queue: .main) {
                    completion(grocerylists)
                }
            } else {
                completion([])
            }
        })
    }
    
    func observeGrocerylistForCurrentUser(grocerylistsAdded: @escaping ([Grocerylist])->(), grocerylistsRemoved: @escaping ([Grocerylist])->()) {
        self.grocerylistsAdded = grocerylistsAdded
        self.grocerylistsRemoved = grocerylistsRemoved
        currentUserGrocerylistsAddHandle = userGrocerylistsDatabaseRef.observe(.childAdded, with: { snapshot in
            if let completion = self.grocerylistsAdded {
                let grocerylistID = snapshot.key
                let ref = Database.database().reference()
                var handle = UInt.max
                handle = ref.child(grocerylistsEntity).child(grocerylistID).observe(.childAdded) { _ in
                    ref.removeObserver(withHandle: handle)
                    self.getGrocerylistsFromSnapshot(snapshot: snapshot, completion: completion)
                }
            }
        })
        
        currentUserGrocerylistsRemoveHandle = userGrocerylistsDatabaseRef.observe(.childRemoved, with: { snapshot in
            if let completion = self.grocerylistsRemoved {
                self.getGrocerylistsFromSnapshot(snapshot: snapshot, completion: completion)
            }
        })
    }
    
    func getGrocerylistsFromSnapshot(snapshot: DataSnapshot, completion: @escaping ([Grocerylist])->()) {
        if snapshot.exists() {
            let grocerylistID = snapshot.key
            let ref = Database.database().reference()
            var grocerylists: [Grocerylist] = []
            let group = DispatchGroup()
            group.enter()
            ref.child(grocerylistsEntity).child(grocerylistID).observeSingleEvent(of: .value, with: { grocerylistSnapshot in
                if grocerylistSnapshot.exists(), let grocerylistSnapshotValue = grocerylistSnapshot.value {
                    if let grocerylist = try? FirebaseDecoder().decode(Grocerylist.self, from: grocerylistSnapshotValue) {
                        grocerylists.append(grocerylist)
                    }
                }
                group.leave()
            })
            
            group.notify(queue: .main) {
                completion(grocerylists)
            }
        } else {
            completion([])
        }
    }
    
    class func update(grocerylist: Grocerylist, completion: @escaping (Bool)->()) {
        let ref = Database.database().reference()
        ref.child(grocerylistsEntity).child(grocerylist.ID!).observeSingleEvent(of: .value, with: { grocerylistSnapshot in
            if grocerylistSnapshot.exists(), let _ = grocerylistSnapshot.value {
                do {
                    let value = try FirebaseEncoder().encode(grocerylist)
                    ref.child(grocerylistsEntity).child(grocerylist.ID!).setValue(value)
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
    
    class func remove(grocerylist: Grocerylist) {
        guard let currentUserID = Auth.auth().currentUser?.uid else {
            return
        }
        
        let ref = Database.database().reference()
        ref.child(grocerylistsEntity).child(grocerylist.ID!).removeValue()
        ref.child(userGrocerylistsEntity).child(currentUserID).child(grocerylist.ID!).removeValue()
    }
}
