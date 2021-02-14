//
//  FinancialHoldingFetcher.swift
//  Plot
//
//  Created by Cory McHattie on 2/14/21.
//  Copyright © 2021 Immature Creations. All rights reserved.
//

import UIKit
import Firebase
import CodableFirebase

class FinancialHoldingFetcher: NSObject {
        
    fileprivate var userHoldingsDatabaseRef: DatabaseReference!
    fileprivate var currentUserHoldingsAddHandle = DatabaseHandle()
    fileprivate var currentUserHoldingsChangeHandle = DatabaseHandle()
    fileprivate var currentUserHoldingsRemoveHandle = DatabaseHandle()
    
    
    var holdingsAdded: (([MXHolding])->())?
    var holdingsRemoved: (([MXHolding])->())?
    var holdingsChanged: (([MXHolding])->())?
    
    fileprivate var isGroupAlreadyFinished = false
    
    func fetchHoldings(completion: @escaping ([MXHolding])->()) {
        guard let currentUserID = Auth.auth().currentUser?.uid else {
            completion([])
            return
        }
                
        let ref = Database.database().reference()
        userHoldingsDatabaseRef = ref.child(userFinancialHoldingsEntity).child(currentUserID)
        userHoldingsDatabaseRef.observeSingleEvent(of: .value, with: { snapshot in
            if snapshot.exists(), let holdingIDs = snapshot.value as? [String: AnyObject] {
                var holdings: [MXHolding] = []
                let group = DispatchGroup()
                for (holdingID, userHoldingInfo) in holdingIDs {
                    if let userHolding = try? FirebaseDecoder().decode(UserHolding.self, from: userHoldingInfo) {
                        group.enter()
                        ref.child(financialHoldingsEntity).child(holdingID).observeSingleEvent(of: .value, with: { holdingSnapshot in
                            if holdingSnapshot.exists(), let holdingSnapshotValue = holdingSnapshot.value {
                                if let holding = try? FirebaseDecoder().decode(MXHolding.self, from: holdingSnapshotValue) {
                                    var _holding = holding
                                    if let value = userHolding.tags {
                                        _holding.tags = value
                                    }
                                    if let value = userHolding.should_link {
                                        _holding.should_link = value
                                    }
                                    _holding.badge = userHolding.badge
                                    _holding.muted = userHolding.muted
                                    _holding.pinned = userHolding.pinned
                                    holdings.append(_holding)
                                }
                            } else {
                                print("failed to convert \(userHolding.description)")
                            }
                            group.leave()
                        })
                    } else {
                        print("else")
                        group.enter()
                        ref.child(financialHoldingsEntity).child(holdingID).observeSingleEvent(of: .value, with: { holdingSnapshot in
                            if holdingSnapshot.exists(), let holdingSnapshotValue = holdingSnapshot.value {
                                if let holding = try? FirebaseDecoder().decode(MXHolding.self, from: holdingSnapshotValue) {
                                    holdings.append(holding)
                                }
                            }
                            group.leave()
                        })
                    }
                }
                group.notify(queue: .main) {
                    completion(holdings)
                }
            } else {
                completion([])
            }
        })
    }
    
    func observeHoldingForCurrentUser(holdingsAdded: @escaping ([MXHolding])->(), holdingsChanged: @escaping ([MXHolding])->()) {
        guard let _ = Auth.auth().currentUser?.uid else {
            return
        }
        self.holdingsAdded = holdingsAdded
        self.holdingsChanged = holdingsChanged
        currentUserHoldingsAddHandle = userHoldingsDatabaseRef.observe(.childAdded, with: { snapshot in
            if let completion = self.holdingsAdded {
                let holdingID = snapshot.key
                let ref = Database.database().reference()
                var handle = UInt.max
                handle = ref.child(financialHoldingsEntity).child(holdingID).observe(.value) { _ in
                    ref.removeObserver(withHandle: handle)
                    self.getHoldingsFromSnapshot(snapshot: snapshot, completion: completion)
                }
            }
        })
        
        currentUserHoldingsChangeHandle = userHoldingsDatabaseRef.observe(.childChanged, with: { snapshot in
            if let completion = self.holdingsChanged {
                self.getHoldingsFromSnapshot(snapshot: snapshot, completion: completion)
            }
        })
    }
    
    func getHoldingsFromSnapshot(snapshot: DataSnapshot, completion: @escaping ([MXHolding])->()) {
        if snapshot.exists() {
            guard let currentUserID = Auth.auth().currentUser?.uid else {
                return
            }
            let holdingID = snapshot.key
            let ref = Database.database().reference()
            var holdings: [MXHolding] = []
            let group = DispatchGroup()
            group.enter()
            ref.child(userFinancialHoldingsEntity).child(currentUserID).child(holdingID).observeSingleEvent(of: .value, with: { snapshot in
                if snapshot.exists(), let userHoldingInfo = snapshot.value {
                    if let userHolding = try? FirebaseDecoder().decode(UserHolding.self, from: userHoldingInfo) {
                        ref.child(financialHoldingsEntity).child(holdingID).observeSingleEvent(of: .value, with: { holdingSnapshot in
                            if holdingSnapshot.exists(), let holdingSnapshotValue = holdingSnapshot.value {
                                if let holding = try? FirebaseDecoder().decode(MXHolding.self, from: holdingSnapshotValue) {
                                    var _holding = holding
                                    if let value = userHolding.tags {
                                        _holding.tags = value
                                    }
                                    if let value = userHolding.should_link {
                                        _holding.should_link = value
                                    }
                                    _holding.badge = userHolding.badge
                                    _holding.muted = userHolding.muted
                                    _holding.pinned = userHolding.pinned
                                    holdings.append(_holding)
                                }
                            }
                            group.leave()
                        })
                    }
                } else {
                    ref.child(financialHoldingsEntity).child(holdingID).observeSingleEvent(of: .value, with: { holdingSnapshot in
                        if holdingSnapshot.exists(), let holdingSnapshotValue = holdingSnapshot.value {
                            if let holding = try? FirebaseDecoder().decode(MXHolding.self, from: holdingSnapshotValue) {
                                holdings.append(holding)
                            }
                        }
                        group.leave()
                    })
                }
            })
            
            group.notify(queue: .main) {
                completion(holdings)
            }
        } else {
            completion([])
        }
    }
}

