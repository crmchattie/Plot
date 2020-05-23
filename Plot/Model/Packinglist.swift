//
//  Packinglist.swift
//  Plot
//
//  Created by Cory McHattie on 5/1/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import UIKit

let packinglistsEntity = "packinglists"
let userPackinglistsEntity = "user-packinglists"

class Packinglist: NSObject, Codable {
    
    var name: String?
    var ID: String?
    var activities: [String: Bool]?
    var items: [String: [Int: Bool]]?
    var participantsIDs: [String]?
    var conversationID: String?
    var activity: Activity?
    var admin: String?
    var badge: Int?
    var pinned: Bool?
    var muted: Bool?

    init(dictionary: [String: AnyObject]?) {
        super.init()
        
        name = dictionary?["name"] as? String
        ID = dictionary?["ID"] as? String
        activities = dictionary?["activities"] as? [String: Bool]
        items = dictionary?["items"] as? [String: [Int: Bool]]
        admin = dictionary?["admin"] as? String
        badge = dictionary?["badge"] as? Int
        pinned = dictionary?["pinned"] as? Bool
        muted = dictionary?["muted"] as? Bool
        
        conversationID = dictionary?["conversationID"] as? String
        
        if let participantsIDsDict = dictionary?["participantsIDs"] as? [String: String] {
            participantsIDs = Array(participantsIDsDict.keys)
        }
        else if let participantsIDsArray = dictionary?["participantsIDs"] as? [String] {
            participantsIDs = participantsIDsArray
        } else {
            participantsIDs = []
        }
        
    }
    
    func copy(with zone: NSZone? = nil) -> Any {
        let copy = Packinglist(dictionary: self.toAnyObject())
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
        
        if let value = self.activities as AnyObject? {
            dictionary["activities"] = value
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
