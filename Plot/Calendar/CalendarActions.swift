//
//  CalendarActions.swift
//  Plot
//
//  Created by Cory McHattie on 7/28/22.
//  Copyright © 2022 Immature Creations. All rights reserved.
//

import UIKit
import Firebase
import CodableFirebase

class CalendarActions: NSObject {
    
    var calendar: CalendarType!
    var ID: String?
    var active: Bool?
    var selectedFalconUsers: [User]?
    
    let dispatchGroup = DispatchGroup()
        
    init(calendar: CalendarType, active: Bool?, selectedFalconUsers: [User]) {
        super.init()
        self.calendar = calendar
        self.ID = calendar.id
        self.active = active
        self.selectedFalconUsers = selectedFalconUsers
    
    }
    
    func deleteCalendar() {
        guard currentReachabilityStatus != .notReachable else {
            return
        }
        
        guard let _ = active, let _ = calendar, let ID = ID, let _ = selectedFalconUsers else {
            return
        }
                          
        let membersIDs = fetchMembersIDs()
        
        for memberID in membersIDs.0 {
            Database.database().reference().child(userCalendarEntity).child(memberID).child(ID).removeAllObservers()
            Database.database().reference().child(userCalendarEntity).child(memberID).child(ID).removeValue()
        }
        
        guard let currentUserID = Auth.auth().currentUser?.uid else {
            return
        }
        
        let reference = Database.database().reference().child(calendarEntity).child(ID.removeCharacters())
        reference.observeSingleEvent(of: .value, with: { (snapshot) in
            guard let dictionary = snapshot.value as? [String: AnyObject] else { return }
            if let membersIDs = dictionary["participantsIDs"] as? [String:AnyObject] {
                var varMemberIDs = membersIDs
                varMemberIDs[currentUserID] = nil
                reference.updateChildValues(["participantsIDs": varMemberIDs as AnyObject])
            }
        })
                
    }
    
    func createNewCalendar() {
        guard currentReachabilityStatus != .notReachable else {
            return
        }
        
        guard let active = active, let ID = ID, let _ = selectedFalconUsers else {
            return
        }
                
        if !active {
            if calendar.createdDate == nil {
                calendar.createdDate = Date()
            }
            if calendar.admin == nil {
                calendar.admin = Auth.auth().currentUser?.uid
            }
        }
        
        let membersIDs = fetchMembersIDs()
        calendar.participantsIDs = membersIDs.0
        calendar.lastModifiedDate = Date()
        
        let groupCalendarReference = Database.database().reference().child(calendarEntity).child(ID.removeCharacters())

        do {
            let value = try FirebaseEncoder().encode(calendar)
            groupCalendarReference.setValue(value)
        } catch let error {
            print(error)
        }
        
        incrementBadgeForReciever(ID: ID, participantsIDs: membersIDs.0)
        
        if !active {
            Analytics.logEvent("new_calendar", parameters: [String: Any]())
            dispatchGroup.enter()
            connectMembersToGroupCalendar(memberIDs: membersIDs.0, ID: ID)
        } else {
            Analytics.logEvent("update_calendar", parameters: [String: Any]())
        }
    }
    
    func updateCalendarParticipants() {
        guard let _ = active, let calendar = calendar, let ID = ID else {
            return
        }
        let membersIDs = fetchMembersIDs()
        if Set(calendar.participantsIDs!) != Set(membersIDs.0) {
            let groupCalendarReference = Database.database().reference().child(calendarEntity).child(ID.removeCharacters())
            updateParticipants(membersIDs: membersIDs)
            groupCalendarReference.updateChildValues(["participantsIDs": membersIDs.0 as AnyObject])
            let date = Date().timeIntervalSinceReferenceDate
            groupCalendarReference.updateChildValues(["lastModifiedDate": date as AnyObject])
        }
        
    }
    
    func fetchMembersIDs() -> ([String], [String:AnyObject]) {
        var membersIDs = [String]()
        var membersIDsDictionary = [String:AnyObject]()
        
        guard let _ = calendar, let selectedFalconUsers = selectedFalconUsers else {
            return (membersIDs.sorted(), membersIDsDictionary)
        }
                
        for selectedUser in selectedFalconUsers {
            guard let id = selectedUser.id else { continue }
            membersIDsDictionary.updateValue(id as AnyObject, forKey: id)
            membersIDs.append(id)
        }
        
        return (membersIDs.sorted(), membersIDsDictionary)
    }
    
    func connectMembersToGroupCalendar(memberIDs: [String], ID: String) {
        let connectingMembersGroup = DispatchGroup()
        for _ in memberIDs {
            connectingMembersGroup.enter()
        }
        connectingMembersGroup.notify(queue: DispatchQueue.main, execute: {
            self.dispatchGroup.leave()
        })
        for memberID in memberIDs {
            let userReference = Database.database().reference().child(userCalendarEntity).child(memberID).child(ID)
            let values:[String : Any] = ["isGroupCalendar": true, "color": calendar.color as Any]
            userReference.updateChildValues(values, withCompletionBlock: { (error, reference) in
                connectingMembersGroup.leave()
            })
        }
    }

    func createGroupCalendarNode(reference: DatabaseReference, childValues: [String: Any]) {
        let nodeCreationGroup = DispatchGroup()
        nodeCreationGroup.enter()
        nodeCreationGroup.notify(queue: DispatchQueue.main, execute: {
            self.dispatchGroup.leave()
        })
        reference.updateChildValues(childValues) { (error, reference) in
            nodeCreationGroup.leave()
        }
    }
    
    func updateParticipants(membersIDs: ([String], [String:AnyObject])) {
        guard let calendar = calendar, let ID = ID else {
            return
        }
        let participantsSet = Set(calendar.participantsIDs!)
        let membersSet = Set(membersIDs.0)
        let difference = participantsSet.symmetricDifference(membersSet)
        for member in difference {
            if participantsSet.contains(member) {
                Database.database().reference().child(userCalendarEntity).child(member).child(ID).removeValue()
            }
            
        }
        
        dispatchGroup.enter()
        
        connectMembersToGroupCalendar(memberIDs: membersIDs.0, ID: ID)

    }
    
    func incrementBadgeForReciever(ID: String?, participantsIDs: [String]) {
        guard let currentUserID = Auth.auth().currentUser?.uid, let ID = ID else { return }
        for participantID in participantsIDs where participantID != currentUserID {
            runCalendarBadgeUpdate(firstChild: participantID, secondChild: ID)
            runUserBadgeUpdate(firstChild: participantID)
        }
    }

    func runCalendarBadgeUpdate(firstChild: String, secondChild: String) {
        var ref = Database.database().reference().child(userCalendarEntity).child(firstChild).child(secondChild)
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            
            guard snapshot.hasChild("badge") else {
                ref.updateChildValues(["badge": 1])
                return
            }
            ref = ref.child("badge")
            ref.runTransactionBlock({ (mutableData) -> TransactionResult in
                var value = mutableData.value as? Int
                if value == nil { value = 0 }
                mutableData.value = value! + 1
                return TransactionResult.success(withValue: mutableData)
            })
        })
    }
}
