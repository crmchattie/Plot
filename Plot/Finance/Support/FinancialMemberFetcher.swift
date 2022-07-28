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
    fileprivate var currentUserMembersRemoveHandle = DatabaseHandle()
    
    var membersAdded: (([MXMember])->())?
    var membersRemoved: (([MXMember])->())?
    var membersChanged: (([MXMember])->())?
    
    fileprivate var isGroupAlreadyFinished = false
    
    func fetchMembers(completion: @escaping ([MXMember])->()) {
        guard let currentUserID = Auth.auth().currentUser?.uid else {
            completion([])
            return
        }
                
        let ref = Database.database().reference()
        userMembersDatabaseRef = ref.child(userFinancialMembersEntity).child(currentUserID)
        userMembersDatabaseRef.observeSingleEvent(of: .value, with: { snapshot in
            if snapshot.exists(), let memberIDs = snapshot.value as? [String: AnyObject] {
                var members: [MXMember] = []
                let group = DispatchGroup()
                for (memberID, _) in memberIDs {
                    group.enter()
                    ref.child(financialMembersEntity).child(memberID).observeSingleEvent(of: .value, with: { memberSnapshot in
                        if memberSnapshot.exists(), let memberSnapshotValue = memberSnapshot.value {
                            if let member = try? FirebaseDecoder().decode(MXMember.self, from: memberSnapshotValue) {
                                members.append(member)
                            }
                        }
                        group.leave()
                    })
                }
                group.notify(queue: .main) {
                    completion(members)
                }
            } else {
                completion([])
            }
        })
    }
    
    func observeMemberForCurrentUser(membersAdded: @escaping ([MXMember])->()) {
        guard let _ = Auth.auth().currentUser?.uid else {
            return
        }
        self.membersAdded = membersAdded
        currentUserMembersAddHandle = userMembersDatabaseRef.observe(.childAdded, with: { snapshot in
            if let completion = self.membersAdded {
                let memberID = snapshot.key
                let ref = Database.database().reference()
                var handle = UInt.max
                handle = ref.child(financialMembersEntity).child(memberID).observe(.childChanged) { _ in
                    ref.removeObserver(withHandle: handle)
                    self.getMembersFromSnapshot(snapshot: snapshot, completion: completion)
                }
            }
        })
    }
    
    func getMembersFromSnapshot(snapshot: DataSnapshot, completion: @escaping ([MXMember])->()) {
        if snapshot.exists() {
            guard let currentUserID = Auth.auth().currentUser?.uid else {
                return
            }
            let memberID = snapshot.key
            let ref = Database.database().reference()
            var members: [MXMember] = []
            let group = DispatchGroup()
            group.enter()
            ref.child(userFinancialMembersEntity).child(currentUserID).child(memberID).observeSingleEvent(of: .value, with: { snapshot in
                if snapshot.exists(), let _ = snapshot.value {
                    ref.child(financialMembersEntity).child(memberID).observeSingleEvent(of: .value, with: { memberSnapshot in
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
        } else {
            completion([])
        }
    }
}
