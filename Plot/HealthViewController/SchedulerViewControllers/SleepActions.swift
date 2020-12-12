//
//  SchedulerActions.swift
//  Plot
//
//  Created by Cory McHattie on 12/12/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import UIKit
import Firebase
import CodableFirebase

class SleepActions: NSObject {
    
    var sleep: Scheduler!
    var ID: String?
    var active: Bool?
    var currentUser: String?
    
    let dispatchGroup = DispatchGroup()
        
    init(sleep: Scheduler, active: Bool?, currentUser: String?) {
        super.init()
        self.sleep = sleep
        self.ID = sleep.id
        self.active = active
        self.currentUser = currentUser
    
    }
    
    public func deleteSleep() {
        guard currentReachabilityStatus != .notReachable else {
            return
        }
        
        guard let _ = active, let _ = sleep, let ID = ID, let currentUser = currentUser else {
            return
        }
                          
        Database.database().reference().child(userSleepEntity).child(currentUser).child(ID).removeAllObservers()
        Database.database().reference().child(userSleepEntity).child(currentUser).child(ID).removeValue()
                
    }
    
    public func createNewSleep() {
        guard currentReachabilityStatus != .notReachable else {
            return
        }
        
        guard let active = active, let ID = ID, let currentUser = currentUser else {
            return
        }
        
        if !active {
            let userReference = Database.database().reference().child(userSleepEntity).child(currentUser).child(ID)
            let values:[String : Any] = ["isGroupSleep": false]
            userReference.setValue(values)
            
            if sleep.createdDate == nil {
                sleep.createdDate = Date()
            }
        }
        
        sleep.lastModifiedDate = Date()
        
        let groupSleepReference = Database.database().reference().child(sleepEntity).child(ID)

        do {
            let value = try FirebaseEncoder().encode(sleep)
            groupSleepReference.setValue(value)
        } catch let error {
            print(error)
        }
                
        if !active {
            Analytics.logEvent("new_sleep", parameters: [String: Any]())
        } else {
            Analytics.logEvent("update_sleep", parameters: [String: Any]())
        }
    }
}
