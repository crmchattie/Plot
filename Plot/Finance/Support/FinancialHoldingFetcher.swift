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
    
    
    var holdingsInitialAdd: (([MXHolding])->())?
    var holdingsAdded: (([MXHolding])->())?
    var holdingsRemoved: (([MXHolding])->())?
    var holdingsChanged: (([MXHolding])->())?
    
    func observeHoldingForCurrentUser(holdingsInitialAdd: @escaping ([MXHolding])->(), holdingsAdded: @escaping ([MXHolding])->(), holdingsChanged: @escaping ([MXHolding])->()) {
        guard let currentUserID = Auth.auth().currentUser?.uid else {
            return
        }
                
        let ref = Database.database().reference()
        userHoldingsDatabaseRef = ref.child(userFinancialHoldingsEntity).child(currentUserID)
        
        self.holdingsInitialAdd = holdingsInitialAdd
        self.holdingsAdded = holdingsAdded
        self.holdingsChanged = holdingsChanged
        
        var userHoldings: [String: UserHolding] = [:]
        
        userHoldingsDatabaseRef.observeSingleEvent(of: .value, with: { snapshot in
            guard snapshot.exists() else {
                holdingsInitialAdd([])
                return
            }
            
            if let completion = self.holdingsInitialAdd {
                var holdings: [MXHolding] = []
                let group = DispatchGroup()
                var counter = 0
                let holdingIDs = snapshot.value as? [String: AnyObject] ?? [:]
                for (ID, userHoldingInfo) in holdingIDs {
                    var handle = UInt.max
                    if let userHolding = try? FirebaseDecoder().decode(UserHolding.self, from: userHoldingInfo) {
                        userHoldings[ID] = userHolding
                        group.enter()
                        counter += 1
                        handle = ref.child(financialHoldingsEntity).child(ID).observe(.value) { snapshot in
                            ref.removeObserver(withHandle: handle)
                            if snapshot.exists(), let snapshotValue = snapshot.value {
                                if let holding = try? FirebaseDecoder().decode(MXHolding.self, from: snapshotValue), let userHolding = userHoldings[ID] {
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
                                    if counter > 0 {
                                        holdings.append(_holding)
                                        group.leave()
                                        counter -= 1
                                    } else {
                                        holdings = [_holding]
                                        completion(holdings)
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
                    completion(holdings)
                }
            }
        })
        
        currentUserHoldingsAddHandle = userHoldingsDatabaseRef.observe(.childAdded, with: { snapshot in
            if userHoldings[snapshot.key] == nil {
                if let completion = self.holdingsAdded {
                    var handle = UInt.max
                    let ID = snapshot.key
                    self.getUserDataFromSnapshot(ID: ID) { holdingsList in
                        for userHolding in holdingsList {
                            userHoldings[ID] = userHolding
                            handle = ref.child(activitiesEntity).child(ID).child(messageMetaDataFirebaseFolder).observe(.value) { snapshot in
                                ref.removeObserver(withHandle: handle)
                                if snapshot.exists(), let snapshotValue = snapshot.value {
                                    if let holding = try? FirebaseDecoder().decode(MXHolding.self, from: snapshotValue), let userHolding = userHoldings[ID] {
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
                                        completion([_holding])
                                    }
                                }
                            }
                        }
                    }
                }
            }
        })
        
        currentUserHoldingsChangeHandle = userHoldingsDatabaseRef.observe(.childChanged, with: { snapshot in
            if let completion = self.holdingsChanged {
                self.getDataFromSnapshot(ID: snapshot.key) { holdingsList in
                    for holding in holdingsList {
                        if let userHolding = try? FirebaseDecoder().decode(UserHolding.self, from: holding) {
                            userHoldings[holding.guid] = userHolding
                        }
                    }
                    completion(holdingsList)
                }
            }
        })
    }
    
    func getDataFromSnapshot(ID: String, completion: @escaping ([MXHolding])->()) {
        guard let currentUserID = Auth.auth().currentUser?.uid else {
            return
        }
        let ref = Database.database().reference()
        var holdings: [MXHolding] = []
        let group = DispatchGroup()
        group.enter()
        ref.child(userFinancialHoldingsEntity).child(currentUserID).child(ID).observeSingleEvent(of: .value, with: { snapshot in
            if snapshot.exists(), let userHoldingInfo = snapshot.value {
                if let userHolding = try? FirebaseDecoder().decode(UserHolding.self, from: userHoldingInfo) {
                    ref.child(financialHoldingsEntity).child(ID).observeSingleEvent(of: .value, with: { holdingSnapshot in
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
                ref.child(financialHoldingsEntity).child(ID).observeSingleEvent(of: .value, with: { holdingSnapshot in
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
    }
    
    func getUserDataFromSnapshot(ID: String, completion: @escaping ([UserHolding])->()) {
        guard let currentUserID = Auth.auth().currentUser?.uid else {
            return
        }
        let ref = Database.database().reference()
        var holdings: [UserHolding] = []
        let group = DispatchGroup()
        group.enter()
        ref.child(userFinancialHoldingsEntity).child(currentUserID).child(ID).observeSingleEvent(of: .value, with: { snapshot in
            if snapshot.exists(), let userHoldingInfo = snapshot.value {
                if let userHolding = try? FirebaseDecoder().decode(UserHolding.self, from: userHoldingInfo) {
                    holdings.append(userHolding)
                    group.leave()
                }
            }
        })
        group.notify(queue: .main) {
            completion(holdings)
        }
    }
}

