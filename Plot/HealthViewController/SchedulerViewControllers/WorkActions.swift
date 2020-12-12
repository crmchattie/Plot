//
//  WorkActions.swift
//  Plot
//
//  Created by Cory McHattie on 12/12/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import UIKit
import Firebase
import CodableFirebase

class WorkActions: NSObject {
    
    var work: Scheduler!
    var ID: String?
    var active: Bool?
    var currentUser: String?
    
    let dispatchGroup = DispatchGroup()
        
    init(work: Scheduler, active: Bool?, currentUser: String?) {
        super.init()
        self.work = work
        self.ID = work.id
        self.active = active
        self.currentUser = currentUser
    
    }
    
    public func deleteWork() {
        guard currentReachabilityStatus != .notReachable else {
            return
        }
        
        guard let _ = active, let _ = work, let ID = ID, let currentUser = currentUser else {
            return
        }
                          
        Database.database().reference().child(userWorkEntity).child(currentUser).child(ID).removeAllObservers()
        Database.database().reference().child(userWorkEntity).child(currentUser).child(ID).removeValue()
                
    }
    
    public func createNewWork() {
        guard currentReachabilityStatus != .notReachable else {
            return
        }
        
        guard let active = active, let ID = ID, let currentUser = currentUser else {
            return
        }
        
        if !active {
            let userReference = Database.database().reference().child(userWorkEntity).child(currentUser).child(ID)
            let values:[String : Any] = ["isGroupWork": false]
            userReference.setValue(values)
            
            if work.createdDate == nil {
                work.createdDate = Date()
            }
        }
        
        work.lastModifiedDate = Date()
        
        let groupWorkReference = Database.database().reference().child(workEntity).child(ID)

        do {
            let value = try FirebaseEncoder().encode(work)
            groupWorkReference.setValue(value)
        } catch let error {
            print(error)
        }
                
        if !active {
            Analytics.logEvent("new_work", parameters: [String: Any]())
        } else {
            Analytics.logEvent("update_work", parameters: [String: Any]())
        }
    }
}
