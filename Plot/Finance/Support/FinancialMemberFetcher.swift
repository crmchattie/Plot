//
//  FinancialMemberFetcher.swift
//  Plot
//
//  Created by Cory McHattie on 1/13/21.
//  Copyright © 2021 Immature Creations. All rights reserved.
//

import UIKit
import Firebase
import CodableFirebase

class FinancialMemberFetcher: NSObject {
        
    fileprivate var userMembersDatabaseRef: DatabaseReference!
    fileprivate var currentUserMembersAddHandle = DatabaseHandle()
    fileprivate var currentUserMembersChangeHandle = DatabaseHandle()
    
    var membersInitialAdd: (([MXMember])->())?
    var membersAdded: (([MXMember])->())?
    var membersChanged: (([MXMember])->())?
        
    func observeMemberForCurrentUser(membersInitialAdd: @escaping ([MXMember])->(), membersAdded: @escaping ([MXMember])->(), membersChanged: @escaping ([MXMember])->()) {
        guard let currentUserID = Auth.auth().currentUser?.uid else {
            return
        }
        let ref = Database.database().reference()
        userMembersDatabaseRef = ref.child(userFinancialMembersEntity).child(currentUserID)
        
        self.membersInitialAdd = membersInitialAdd
        self.membersAdded = membersAdded
        self.membersChanged = membersChanged
        
        var IDs: [String] = []
        
        userMembersDatabaseRef.observeSingleEvent(of: .value, with: { snapshot in
            guard snapshot.exists() else {
                membersInitialAdd([])
                return
            }
            
            if let completion = self.membersInitialAdd {
                var members: [MXMember] = []
                var counter = 0
                let group = DispatchGroup()
                let memberIDs = snapshot.value as? [String: AnyObject] ?? [:]
                IDs = Array(memberIDs.keys)
                for (ID, _) in memberIDs {
                    var handle = UInt.max
                    group.enter()
                    counter += 1
                    handle = ref.child(financialMembersEntity).child(ID).observe(.value) { snapshot in
                        ref.removeObserver(withHandle: handle)
                        if snapshot.exists(), let snapshotValue = snapshot.value {
                            if let member = try? FirebaseDecoder().decode(MXMember.self, from: snapshotValue) {
                                if counter > 0 {
                                    members.append(member)
                                    group.leave()
                                    counter -= 1
                                } else {
                                    members = [member]
                                    completion(members)
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
                    completion(members)
                }
            }
        })
        
        currentUserMembersAddHandle = userMembersDatabaseRef.observe(.childAdded, with: { snapshot in
            if !IDs.contains(snapshot.key) {
                if let completion = self.membersAdded {
                    var handle = UInt.max
                    let ID = snapshot.key
                    handle = ref.child(financialMembersEntity).child(ID).observe(.value) { snapshot in
                        ref.removeObserver(withHandle: handle)
                        if snapshot.exists(), let snapshotValue = snapshot.value {
                            if let member = try? FirebaseDecoder().decode(MXMember.self, from: snapshotValue) {
                                completion([member])
                            }
                        }
                        
                    }
                }
            }
        })
        
        currentUserMembersChangeHandle = userMembersDatabaseRef.observe(.childChanged, with: { snapshot in
            if let completion = self.membersChanged {
                FinancialMemberFetcher.getDataFromSnapshot(ID: snapshot.key, completion: completion)
            }
        })

    }
    
    class func getDataFromSnapshot(ID: String, completion: @escaping ([MXMember])->()) {
        guard let currentUserID = Auth.auth().currentUser?.uid else {
            return
        }
        let ref = Database.database().reference()
        var members: [MXMember] = []
        let group = DispatchGroup()
        group.enter()
        ref.child(userFinancialMembersEntity).child(currentUserID).child(ID).observeSingleEvent(of: .value, with: { snapshot in
            if snapshot.exists(), let _ = snapshot.value {
                ref.child(financialMembersEntity).child(ID).observeSingleEvent(of: .value, with: { memberSnapshot in
                    if memberSnapshot.exists(), let memberSnapshotValue = memberSnapshot.value {
                        if let member = try? FirebaseDecoder().decode(MXMember.self, from: memberSnapshotValue) {
                            members.append(member)
                        }
                    }
                    group.leave()
                })
            }
        })
        group.notify(queue: .main) {
            completion(members)
        }
    }
}
