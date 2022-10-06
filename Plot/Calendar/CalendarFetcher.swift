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
    
    var calendarInitialAdd: (([CalendarType])->())?
    var calendarAdded: (([CalendarType])->())?
    var calendarRemoved: (([CalendarType])->())?
    var calendarChanged: (([CalendarType])->())?
    
    func fetchCalendar(completion: @escaping ([CalendarType])->()) {
        guard let currentUserID = Auth.auth().currentUser?.uid else {
            return
        }
                
        let ref = Database.database().reference()
        userCalendarDatabaseRef = ref.child(userCalendarEntity).child(currentUserID)
        
        var calendars: [CalendarType] = []
                
        userCalendarDatabaseRef.observeSingleEvent(of: .value, with: { snapshot in
            if snapshot.exists() {
                let group = DispatchGroup()
                group.enter()
                let calendarIDs = snapshot.value as? [String: AnyObject] ?? [:]
                for (ID, userCalendarInfo) in calendarIDs {
                    if let userCalendar = try? FirebaseDecoder().decode(CalendarType.self, from: userCalendarInfo) {
                        ref.child(calendarEntity).child(ID).observeSingleEvent(of: .value, with: { snapshot in
                            if snapshot.exists(), let snapshotValue = snapshot.value {
                                if let calendar = try? FirebaseDecoder().decode(CalendarType.self, from: snapshotValue) {
                                    var _calendar = calendar
                                    _calendar.color = userCalendar.color
                                    _calendar.badge = userCalendar.badge
                                    _calendar.muted = userCalendar.muted
                                    _calendar.pinned = userCalendar.pinned
                                    calendars.append(_calendar)
                                    group.leave()
                                }
                            } else {
                                group.leave()
                            }
                        })
                    }
                }
                group.notify(queue: .main) {
                    completion(calendars)
                }
            } else {
                completion([])
            }
        })
    }
    
    func observeCalendarForCurrentUser(calendarInitialAdd: @escaping ([CalendarType])->(), calendarAdded: @escaping ([CalendarType])->(), calendarRemoved: @escaping ([CalendarType])->(), calendarChanged: @escaping ([CalendarType])->()) {
        guard let currentUserID = Auth.auth().currentUser?.uid else {
            return
        }
                
        let ref = Database.database().reference()
        userCalendarDatabaseRef = ref.child(userCalendarEntity).child(currentUserID)
        
        self.calendarInitialAdd = calendarInitialAdd
        self.calendarAdded = calendarAdded
        self.calendarRemoved = calendarRemoved
        self.calendarChanged = calendarChanged
        
        var userCalendars: [String: CalendarType] = [:]
        
        userCalendarDatabaseRef.observeSingleEvent(of: .value, with: { snapshot in
            guard snapshot.exists() else {
                self.uploadInitialPlotCalendars()
                calendarInitialAdd(prebuiltCalendars)
                return
            }
            
            if let completion = self.calendarInitialAdd {
                var calendars: [CalendarType] = []
                let group = DispatchGroup()
                var counter = 0
                let calendarIDs = snapshot.value as? [String: AnyObject] ?? [:]
                for (ID, userCalendarInfo) in calendarIDs {
                    var handle = UInt.max
                    if let userCalendar = try? FirebaseDecoder().decode(CalendarType.self, from: userCalendarInfo) {
                        userCalendars[ID] = userCalendar
                        group.enter()
                        counter += 1
                        handle = ref.child(calendarEntity).child(ID).observe(.value) { snapshot in
                            ref.removeObserver(withHandle: handle)
                            if snapshot.exists(), let snapshotValue = snapshot.value {
                                if let calendar = try? FirebaseDecoder().decode(CalendarType.self, from: snapshotValue), let userCalendar = userCalendars[ID] {
                                    var _calendar = calendar
                                    _calendar.color = userCalendar.color
                                    _calendar.badge = userCalendar.badge
                                    _calendar.muted = userCalendar.muted
                                    _calendar.pinned = userCalendar.pinned
                                    if counter > 0 {
                                        calendars.append(_calendar)
                                        group.leave()
                                        counter -= 1
                                    } else {
                                        calendars = [_calendar]
                                        completion(calendars)
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
                    completion(calendars)
                }
            }
        })
        
        currentUserCalendarAddHandle = userCalendarDatabaseRef.observe(.childAdded, with: { snapshot in
            if userCalendars[snapshot.key] == nil {
                if let completion = self.calendarAdded {
                    var handle = UInt.max
                    let ID = snapshot.key
                    self.getUserDataFromSnapshot(ID: ID) { calendarsList in
                        for userCalendar in calendarsList {
                            userCalendars[ID] = userCalendar
                            handle = ref.child(activitiesEntity).child(ID).child(messageMetaDataFirebaseFolder).observe(.value) { snapshot in
                                ref.removeObserver(withHandle: handle)
                                if snapshot.exists(), let snapshotValue = snapshot.value {
                                    if let calendar = try? FirebaseDecoder().decode(CalendarType.self, from: snapshotValue), let userCalendar = userCalendars[ID] {
                                        var _calendar = calendar
                                        _calendar.color = userCalendar.color
                                        _calendar.badge = userCalendar.badge
                                        _calendar.muted = userCalendar.muted
                                        _calendar.pinned = userCalendar.pinned
                                        completion([_calendar])
                                    }
                                }
                            }
                        }
                    }
                }
            }
        })
        
        currentUserCalendarChangeHandle = userCalendarDatabaseRef.observe(.childChanged, with: { snapshot in
            if let completion = self.calendarChanged {
                CalendarFetcher.getDataFromSnapshot(ID: snapshot.key) { calendarsList in
                    for calendar in calendarsList {
                        userCalendars[calendar.id ?? ""] = calendar
                    }
                    completion(calendarsList)
                }
            }
        })
        
        currentUserCalendarRemoveHandle = userCalendarDatabaseRef.observe(.childRemoved, with: { snapshot in
            if let completion = self.calendarRemoved {
                userCalendars[snapshot.key] = nil
                CalendarFetcher.getDataFromSnapshot(ID: snapshot.key, completion: completion)
            }
        })
        
    }
    
    class func getDataFromSnapshot(ID: String, completion: @escaping ([CalendarType])->()) {
        guard let currentUserID = Auth.auth().currentUser?.uid else {
            return
        }
        let ref = Database.database().reference()
        var calendarList: [CalendarType] = []
        let group = DispatchGroup()
        group.enter()
        ref.child(userCalendarEntity).child(currentUserID).child(ID).observeSingleEvent(of: .value, with: { snapshot in
            if snapshot.exists(), let userCalendarInfo = snapshot.value {
                if let userCalendar = try? FirebaseDecoder().decode(CalendarType.self, from: userCalendarInfo) {
                    ref.child(calendarEntity).child(ID).observeSingleEvent(of: .value, with: { calendarSnapshot in
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
                ref.child(calendarEntity).child(ID).observeSingleEvent(of: .value, with: { calendarSnapshot in
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
    }
    
    func getUserDataFromSnapshot(ID: String, completion: @escaping ([CalendarType])->()) {
        guard let currentUserID = Auth.auth().currentUser?.uid else {
            return
        }
        let ref = Database.database().reference()
        var calendars: [CalendarType] = []
        let group = DispatchGroup()
        group.enter()
        ref.child(userCalendarEntity).child(currentUserID).child(ID).observeSingleEvent(of: .value, with: { snapshot in
            if snapshot.exists(), let userCalendarInfo = snapshot.value {
                if let userCalendar = try? FirebaseDecoder().decode(CalendarType.self, from: userCalendarInfo) {
                    calendars.append(userCalendar)
                    group.leave()
                }
            }
        })
        group.notify(queue: .main) {
            completion(calendars)
        }
    }
    
    func uploadInitialPlotCalendars() {
        guard let _ = Auth.auth().currentUser?.uid else {
            return
        }
        for calendar in prebuiltCalendars {
            let createCalendar = CalendarActions(calendar: calendar, active: false, selectedFalconUsers: [])
            createCalendar.createNewCalendar()
        }
    }
    
    class func fetchCalendarsForUser(id: String, completion: @escaping ([CalendarType])->()) {
        let ref = Database.database().reference()
        let userCalendarDatabaseRef = ref.child(userCalendarEntity).child(id)
        
        var calendars: [CalendarType] = []
                
        userCalendarDatabaseRef.observeSingleEvent(of: .value, with: { snapshot in
            if snapshot.exists() {
                let group = DispatchGroup()
                let calendarIDs = snapshot.value as? [String: AnyObject] ?? [:]
                for (ID, userCalendarInfo) in calendarIDs {
                    if let userCalendar = try? FirebaseDecoder().decode(CalendarType.self, from: userCalendarInfo) {
                        group.enter()
                        ref.child(calendarEntity).child(ID).observeSingleEvent(of: .value, with: { snapshot in
                            if snapshot.exists(), let snapshotValue = snapshot.value {
                                if let calendar = try? FirebaseDecoder().decode(CalendarType.self, from: snapshotValue) {
                                    var _calendar = calendar
                                    _calendar.color = userCalendar.color
                                    _calendar.badge = userCalendar.badge
                                    _calendar.muted = userCalendar.muted
                                    _calendar.pinned = userCalendar.pinned
                                    calendars.append(_calendar)
                                }
                            }
                            group.leave()
                        })
                    }
                }
                group.notify(queue: .main) {
                    completion(calendars)
                }
            } else {
                completion([])
            }
        })
    }
}
