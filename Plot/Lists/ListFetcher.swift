//
//  ListFetcher.swift
//  Plot
//
//  Created by Cory McHattie on 8/20/22.
//  Copyright © 2022 Immature Creations. All rights reserved.
//

import UIKit
import Firebase
import CodableFirebase

class ListFetcher: NSObject {
        
    fileprivate var userListDatabaseRef: DatabaseReference!
    fileprivate var currentUserListAddHandle = DatabaseHandle()
    fileprivate var currentUserListChangeHandle = DatabaseHandle()
    fileprivate var currentUserListRemoveHandle = DatabaseHandle()
    
    var listInitialAdd: (([ListType])->())?
    var listAdded: (([ListType])->())?
    var listRemoved: (([ListType])->())?
    var listChanged: (([ListType])->())?
    
    func fetchList(completion: @escaping ([ListType])->()) {
        guard let currentUserID = Auth.auth().currentUser?.uid else {
            return
        }
                
        let ref = Database.database().reference()
        userListDatabaseRef = ref.child(userListEntity).child(currentUserID)
        
        var lists: [ListType] = []
        
        userListDatabaseRef.observeSingleEvent(of: .value, with: { snapshot in
            if snapshot.exists() {
                let group = DispatchGroup()
                group.enter()
                let listIDs = snapshot.value as? [String: AnyObject] ?? [:]
                for (ID, userListInfo) in listIDs {
                    if let userList = try? FirebaseDecoder().decode(ListType.self, from: userListInfo) {
                        ref.child(listEntity).child(ID).observeSingleEvent(of: .value, with: { snapshot in
                            if snapshot.exists(), let snapshotValue = snapshot.value {
                                if let list = try? FirebaseDecoder().decode(ListType.self, from: snapshotValue) {
                                    var _list = list
                                    _list.color = userList.color
                                    _list.badge = userList.badge
                                    _list.muted = userList.muted
                                    _list.pinned = userList.pinned
                                    lists.append(_list)
                                    group.leave()
                                }
                            } else {
                                group.leave()
                            }
                        })
                    }
                }
                group.notify(queue: .main) {
                    completion(lists)
                }
            } else {
                completion([])
            }
        })
    }
    
    func observeListForCurrentUser(listInitialAdd: @escaping ([ListType])->(), listAdded: @escaping ([ListType])->(), listRemoved: @escaping ([ListType])->(), listChanged: @escaping ([ListType])->()) {
        guard let currentUserID = Auth.auth().currentUser?.uid else {
            return
        }
                
        let ref = Database.database().reference()
        userListDatabaseRef = ref.child(userListEntity).child(currentUserID)
        
        self.listInitialAdd = listInitialAdd
        self.listAdded = listAdded
        self.listRemoved = listRemoved
        self.listChanged = listChanged
        
        var userLists: [String: ListType] = [:]
        
        userListDatabaseRef.observeSingleEvent(of: .value, with: { snapshot in
            print(snapshot.exists())
            guard snapshot.exists() else {
                self.uploadInitialPlotLists()
                listInitialAdd(prebuiltLists)
                return
            }
            
            if let completion = self.listInitialAdd {
                var lists: [ListType] = []
                let group = DispatchGroup()
                var counter = 0
                let listIDs = snapshot.value as? [String: AnyObject] ?? [:]
                for (ID, userListInfo) in listIDs {
                    var handle = UInt.max
                    if let userList = try? FirebaseDecoder().decode(ListType.self, from: userListInfo) {
                        userLists[ID] = userList
                        group.enter()
                        counter += 1
                        handle = ref.child(listEntity).child(ID).observe(.value) { snapshot in
                            ref.removeObserver(withHandle: handle)
                            if snapshot.exists(), let snapshotValue = snapshot.value {
                                if let list = try? FirebaseDecoder().decode(ListType.self, from: snapshotValue), let userList = userLists[ID] {
                                    var _list = list
                                    _list.color = userList.color
                                    _list.badge = userList.badge
                                    _list.muted = userList.muted
                                    _list.pinned = userList.pinned
                                    if counter > 0 {
                                        lists.append(_list)
                                        group.leave()
                                        counter -= 1
                                    } else {
                                        lists = [_list]
                                        completion(lists)
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
                    completion(lists)
                }
            }
        })
        
        currentUserListAddHandle = userListDatabaseRef.observe(.childAdded, with: { snapshot in
            if userLists[snapshot.key] == nil {
                if let completion = self.listAdded {
                    var handle = UInt.max
                    let ID = snapshot.key
                    self.getUserDataFromSnapshot(ID: ID) { listsList in
                        for userList in listsList {
                            userLists[ID] = userList
                            handle = ref.child(activitiesEntity).child(ID).child(messageMetaDataFirebaseFolder).observe(.value) { snapshot in
                                ref.removeObserver(withHandle: handle)
                                if snapshot.exists(), let snapshotValue = snapshot.value {
                                    if let list = try? FirebaseDecoder().decode(ListType.self, from: snapshotValue), let userList = userLists[ID] {
                                        var _list = list
                                        _list.color = userList.color
                                        _list.badge = userList.badge
                                        _list.muted = userList.muted
                                        _list.pinned = userList.pinned
                                        completion([_list])
                                    }
                                }
                            }
                        }
                    }
                }
            }
        })
        
        currentUserListChangeHandle = userListDatabaseRef.observe(.childChanged, with: { snapshot in
            if let completion = self.listChanged {
                ListFetcher.getDataFromSnapshot(ID: snapshot.key) { listsList in
                    for list in listsList {
                        userLists[list.id ?? ""] = list
                    }
                    completion(listsList)
                }
            }
        })
        
        currentUserListRemoveHandle = userListDatabaseRef.observe(.childRemoved, with: { snapshot in
            if let completion = self.listRemoved {
                userLists[snapshot.key] = nil
                ListFetcher.getDataFromSnapshot(ID: snapshot.key, completion: completion)
            }
        })
        
    }
    
    class func getDataFromSnapshot(ID: String, completion: @escaping ([ListType])->()) {
        guard let currentUserID = Auth.auth().currentUser?.uid else {
            return
        }
        let ref = Database.database().reference()
        var listList: [ListType] = []
        let group = DispatchGroup()
        group.enter()
        ref.child(userListEntity).child(currentUserID).child(ID).observeSingleEvent(of: .value, with: { snapshot in
            if snapshot.exists(), let userListInfo = snapshot.value {
                if let userList = try? FirebaseDecoder().decode(ListType.self, from: userListInfo) {
                    ref.child(listEntity).child(ID).observeSingleEvent(of: .value, with: { listSnapshot in
                        if listSnapshot.exists(), let listSnapshotValue = listSnapshot.value {
                            if let list = try? FirebaseDecoder().decode(ListType.self, from: listSnapshotValue) {
                                var _list = list
                                _list.color = userList.color
                                _list.badge = userList.badge
                                _list.muted = userList.muted
                                _list.pinned = userList.pinned
                                listList.append(_list)
                            }
                        }
                        group.leave()
                    })
                }
            } else {
                ref.child(listEntity).child(ID).observeSingleEvent(of: .value, with: { listSnapshot in
                    if listSnapshot.exists(), let listSnapshotValue = listSnapshot.value {
                        if let list = try? FirebaseDecoder().decode(ListType.self, from: listSnapshotValue) {
                            listList.append(list)
                        }
                    }
                    group.leave()
                })
            }
        })
        
        group.notify(queue: .main) {
            completion(listList)
        }
    }
    
    func getUserDataFromSnapshot(ID: String, completion: @escaping ([ListType])->()) {
        guard let currentUserID = Auth.auth().currentUser?.uid else {
            return
        }
        let ref = Database.database().reference()
        var lists: [ListType] = []
        let group = DispatchGroup()
        group.enter()
        ref.child(userListEntity).child(currentUserID).child(ID).observeSingleEvent(of: .value, with: { snapshot in
            if snapshot.exists(), let userListInfo = snapshot.value {
                if let userList = try? FirebaseDecoder().decode(ListType.self, from: userListInfo) {
                    lists.append(userList)
                    group.leave()
                }
            }
        })
        group.notify(queue: .main) {
            completion(lists)
        }
    }
    
    func uploadInitialPlotLists() {
        guard let _ = Auth.auth().currentUser?.uid else {
            return
        }
        for list in prebuiltLists {
            let createList = ListActions(list: list, active: false, selectedFalconUsers: [])
            createList.createNewList()
        }
    }
}
