//
//  Checklist.swift
//  Plot
//
//  Created by Cory McHattie on 5/1/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import UIKit

let checklistsEntity = "checklists"
let userChecklistsEntity = "user-checklists"

class Checklist: NSObject, Codable {
    
    var name: String?
    var ID: String?
    var items: [String: Bool]?
    var participantsIDs: [String]?
    var activity: Activity?
    var conversationID: String?
    var admin: String?
    var badge: Int?
    var pinned: Bool?
    var muted: Bool?

    init(dictionary: [String: AnyObject]?) {
        super.init()
        name = dictionary?["name"] as? String
        items = dictionary?["items"] as? [String: Bool]
        ID = dictionary?["ID"] as? String
        admin = dictionary?["admin"] as? String
        badge = dictionary?["badge"] as? Int
        pinned = dictionary?["pinned"] as? Bool
        muted = dictionary?["muted"] as? Bool
        conversationID = dictionary?["conversationID"] as? String
        
        if let participantsIDsDict = dictionary?["participantsIDs"] as? [String: String] {
            participantsIDs = Array(participantsIDsDict.keys)
        } else if let participantsIDsArray = dictionary?["participantsIDs"] as? [String] {
            participantsIDs = participantsIDsArray
        } else {
            participantsIDs = []
        }
    }
    
    func copy(with zone: NSZone? = nil) -> Any {
        let copy = Checklist(dictionary: self.toAnyObject())
        return copy
    }
    
    func toAnyObject() -> [String: AnyObject] {
        var dictionary = [String: AnyObject]()
        
        if let value = self.name as AnyObject? {
            dictionary["name"] = value
        }
        
        if let value = self.ID as AnyObject? {
            dictionary["ID"] = value
        }
                
        if let value = self.items as AnyObject? {
            dictionary["items"] = value
        }
        
        if let value = self.admin as AnyObject? {
            dictionary["admin"] = value
        }
        
        if let value = self.participantsIDs as AnyObject? {
            dictionary["participantsIDs"] = value
        }
        
        if let value = self.conversationID as AnyObject? {
            dictionary["conversationID"] = value
        }
        
        return dictionary
    }
}
