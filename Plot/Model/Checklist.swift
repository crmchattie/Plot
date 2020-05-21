//
//  Checklist.swift
//  Plot
//
//  Created by Cory McHattie on 5/1/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import UIKit

class Checklist: NSObject, Codable {
    
    var name: String?
    var ID: String?
    var items: [String: Bool]?
    var participantsIDs: [String]?
    var activity: Activity?
    var admin: String?
    var badge: Int?
    var pinned: Bool?
    var muted: Bool?
    
    enum CodingKeys: String, CodingKey {
        case name
        case ID
        case items
        case participantsIDs
        case activity
        case admin
        case badge
        case pinned
        case muted
    }

    init(dictionary: [String: AnyObject]?) {
        super.init()
        name = dictionary?["name"] as? String
        ID = dictionary?["ID"] as? String
        admin = dictionary?["admin"] as? String
        badge = dictionary?["badge"] as? Int
        pinned = dictionary?["pinned"] as? Bool
        muted = dictionary?["muted"] as? Bool
        
        if let participantsIDsDict = dictionary?["participantsIDs"] as? [String: String] {
            participantsIDs = Array(participantsIDsDict.keys)
        }
        else if let participantsIDsArray = dictionary?["participantsIDs"] as? [String] {
            participantsIDs = participantsIDsArray
        } else {
            participantsIDs = []
        }
    }
    
    func toAnyObject() -> [String: AnyObject?] {
        var dictionary = [String: AnyObject?]()
        
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
        
        return dictionary
    }
}
