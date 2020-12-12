//
//  MoodActions.swift
//  Plot
//
//  Created by Cory McHattie on 12/12/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import UIKit
import Firebase
import CodableFirebase

class MoodActions: NSObject {
    
    var mood: Mood!
    var ID: String?
    var active: Bool?
    var currentUser: String?
    
    let dispatchGroup = DispatchGroup()
        
    init(mood: Mood, active: Bool?, currentUser: String?) {
        super.init()
        self.mood = mood
        self.ID = mood.id
        self.active = active
        self.currentUser = currentUser
    
    }
    
    public func deleteMood() {
        guard currentReachabilityStatus != .notReachable else {
            return
        }
        
        guard let _ = active, let _ = mood, let ID = ID, let currentUser = currentUser else {
            return
        }
                          
        Database.database().reference().child(userMoodsEntity).child(currentUser).child(ID).removeAllObservers()
        Database.database().reference().child(userMoodsEntity).child(currentUser).child(ID).removeValue()
                
    }
    
    public func createNewMood() {
        guard currentReachabilityStatus != .notReachable else {
            return
        }
        
        guard let active = active, let ID = ID, let currentUser = currentUser else {
            return
        }
        
        if !active {
            let userReference = Database.database().reference().child(userMoodsEntity).child(currentUser).child(ID)
            let values:[String : Any] = ["isGroupMood": false]
            userReference.setValue(values)
            
            if mood.createdDate == nil {
                mood.createdDate = Date()
            }
        }
        
        mood.lastModifiedDate = Date()
        
        let groupMoodReference = Database.database().reference().child(moodsEntity).child(ID)

        do {
            let value = try FirebaseEncoder().encode(mood)
            groupMoodReference.setValue(value)
        } catch let error {
            print(error)
        }
                
        if !active {
            Analytics.logEvent("new_mood", parameters: [String: Any]())
        } else {
            Analytics.logEvent("update_mood", parameters: [String: Any]())
        }
    }
}
