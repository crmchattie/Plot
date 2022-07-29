//
//  CalendarFetcher.swift
//  Plot
//
//  Created by Cory McHattie on 7/28/22.
//  Copyright © 2022 Immature Creations. All rights reserved.
//

import UIKit
import Firebase
import CodableFirebase

class CalendarFetcher: NSObject {
        
    fileprivate var userCalendarDatabaseRef: DatabaseReference!
    fileprivate var currentUserCalendarAddHandle = DatabaseHandle()
    fileprivate var currentUserCalendarChangeHandle = DatabaseHandle()
    fileprivate var currentUserCalendarRemoveHandle = DatabaseHandle()
    
    
    var calendarAdded: (([CalendarType])->())?
    var calendarRemoved: (([CalendarType])->())?
    var calendarChanged: (([CalendarType])->())?
    
    fileprivate var isGroupAlreadyFinished = false
    
    func fetchCalendar(completion: @escaping ([CalendarType])->()) {
        guard let currentUserID = Auth.auth().currentUser?.uid else {
            completion([])
            return
        }
        
        let ref = Database.database().reference()
        userCalendarDatabaseRef = Database.database().reference().child(userCalendarEntity).child(currentUserID)
        userCalendarDatabaseRef.observeSingleEvent(of: .value, with: { snapshot in
            if snapshot.exists(), let calendarIDs = snapshot.value as? [String: AnyObject] {
                var calendarList: [CalendarType] = []
                let group = DispatchGroup()
                for (calendarID, userCalendarInfo) in calendarIDs {
                    if let userCalendar = try? FirebaseDecoder().decode(CalendarType.self, from: userCalendarInfo) {
                        group.enter()
                        ref.child(calendarEntity).child(calendarID).observeSingleEvent(of: .value, with: { calendarSnapshot in
                            if calendarSnapshot.exists(), let calendarSnapshotValue = calendarSnapshot.value {
                                if let calendar = try? FirebaseDecoder().decode(CalendarType.self, from: calendarSnapshotValue) {
                                    var _calendar = calendar
                                    _calendar.color = userCalendar.color
                                    _calendar.badge = userCalendar.badge
                                    _calendar.muted = userCalendar.muted
                                    _calendar.pinned = userCalendar.pinned
                                    calendarList.append(_calendar)
                                }
                            }
                            group.leave()
                        })
                    } else {
                        group.enter()
                        ref.child(calendarEntity).child(calendarID).observeSingleEvent(of: .value, with: { calendarSnapshot in
                            if calendarSnapshot.exists(), let calendarSnapshotValue = calendarSnapshot.value {
                                if let calendar = try? FirebaseDecoder().decode(CalendarType.self, from: calendarSnapshotValue) {
                                    calendarList.append(calendar)
                                }
                            }
                            group.leave()
                        })
                    }
                }
                group.notify(queue: .main) {
                    completion(calendarList)
                }
            } else {
                for calendar in prebuiltCalendars {
                    let createCalendar = CalendarActions(calendar: calendar, active: false, selectedFalconUsers: [])
                    createCalendar.createNewCalendar()
                }
                completion(prebuiltCalendars)
            }
        })
    }
    
    func observeCalendarForCurrentUser(calendarAdded: @escaping ([CalendarType])->(), calendarRemoved: @escaping ([CalendarType])->(), calendarChanged: @escaping ([CalendarType])->()) {
        guard let _ = Auth.auth().currentUser?.uid else {
            return
        }
        self.calendarAdded = calendarAdded
        self.calendarRemoved = calendarRemoved
        self.calendarChanged = calendarChanged
        currentUserCalendarAddHandle = userCalendarDatabaseRef.observe(.childAdded, with: { snapshot in
            if let completion = self.calendarAdded {
                let calendarID = snapshot.key
                let ref = Database.database().reference()
                var handle = UInt.max
                handle = ref.child(calendarEntity).child(calendarID).observe(.childChanged) { _ in
                    ref.removeObserver(withHandle: handle)
                    self.getCalendarFromSnapshot(snapshot: snapshot, completion: completion)
                }
            }
        })
        
        currentUserCalendarChangeHandle = userCalendarDatabaseRef.observe(.childChanged, with: { snapshot in
            if let completion = self.calendarChanged {
                self.getCalendarFromSnapshot(snapshot: snapshot, completion: completion)
            }
        })
        
        currentUserCalendarRemoveHandle = userCalendarDatabaseRef.observe(.childRemoved, with: { snapshot in
            if let completion = self.calendarRemoved {
                self.getCalendarFromSnapshot(snapshot: snapshot, completion: completion)
            }
        })
        
    }
    
    func getCalendarFromSnapshot(snapshot: DataSnapshot, completion: @escaping ([CalendarType])->()) {
        if snapshot.exists() {
            guard let currentUserID = Auth.auth().currentUser?.uid else {
                return
            }
            let calendarID = snapshot.key
            let ref = Database.database().reference()
            var calendarList: [CalendarType] = []
            let group = DispatchGroup()
            group.enter()
            ref.child(userCalendarEntity).child(currentUserID).child(calendarID).observeSingleEvent(of: .value, with: { snapshot in
                if snapshot.exists(), let userCalendarInfo = snapshot.value {
                    if let userCalendar = try? FirebaseDecoder().decode(CalendarType.self, from: userCalendarInfo) {
                        ref.child(calendarEntity).child(calendarID).observeSingleEvent(of: .value, with: { calendarSnapshot in
                            if calendarSnapshot.exists(), let calendarSnapshotValue = calendarSnapshot.value {
                                if let calendar = try? FirebaseDecoder().decode(CalendarType.self, from: calendarSnapshotValue) {
                                    var _calendar = calendar
                                    _calendar.color = userCalendar.color
                                    _calendar.badge = userCalendar.badge
                                    _calendar.muted = userCalendar.muted
                                    _calendar.pinned = userCalendar.pinned
                                    calendarList.append(_calendar)
                                }
                            }
                            group.leave()
                        })
                    }
                } else {
                    ref.child(calendarEntity).child(calendarID).observeSingleEvent(of: .value, with: { calendarSnapshot in
                        if calendarSnapshot.exists(), let calendarSnapshotValue = calendarSnapshot.value {
                            if let calendar = try? FirebaseDecoder().decode(CalendarType.self, from: calendarSnapshotValue) {
                                calendarList.append(calendar)
                            }
                        }
                        group.leave()
                    })
                }
            })
            
            group.notify(queue: .main) {
                completion(calendarList)
            }
        } else {
            completion([])
        }
    }
}
