//
//  ActivityList.swift
//  Plot
//
//  Created by Cory McHattie on 7/15/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import UIKit

let activitylistsEntity = "activitylists"
let userActivitylistsEntity = "user-activitylists"

class Activitylist: NSObject, NSCopying, Codable {
    
    var name: String?
    var ID: String?
    var items: [String: Bool]?
    var IDTypeDictionary: [String: [String: String]]?
    var participantsIDs: [String]?
    var activityID: String?
    var conversationID: String?
    var admin: String?
    var badge: Int?
    var pinned: Bool?
    var muted: Bool?
    var lastModifiedDate: Date?
    var createdDate: Date?

    init(dictionary: [String: AnyObject]?) {
        super.init()
        name = dictionary?["name"] as? String
        items = dictionary?["items"] as? [String: Bool]
        IDTypeDictionary = dictionary?["IDTypeDictionary"] as? [String: [String: String]]
        ID = dictionary?["ID"] as? String
        admin = dictionary?["admin"] as? String
        badge = dictionary?["badge"] as? Int
        pinned = dictionary?["pinned"] as? Bool
        muted = dictionary?["muted"] as? Bool
        conversationID = dictionary?["conversationID"] as? String
        activityID = dictionary?["activityID"] as? String
        lastModifiedDate = dictionary?["lastModifiedDate"] as? Date
        createdDate = dictionary?["lastModifiedDate"] as? Date
        
        if let participantsIDsDict = dictionary?["participantsIDs"] as? [String: String] {
            participantsIDs = Array(participantsIDsDict.keys)
        } else if let participantsIDsArray = dictionary?["participantsIDs"] as? [String] {
            participantsIDs = participantsIDsArray
        } else {
            participantsIDs = []
        }
    }
    
    func copy(with zone: NSZone? = nil) -> Any {
        let copy = Activitylist(dictionary: self.toAnyObject())
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
        
        if let value = self.IDTypeDictionary as AnyObject? {
            dictionary["IDTypeDictionary"] = value
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
        
        if let value = self.activityID as AnyObject? {
            dictionary["activityID"] = value
        }
        
        if let value = self.lastModifiedDate {
            let date = value.timeIntervalSinceReferenceDate as AnyObject?
            dictionary["lastModifiedDate"] = date
        }
        
        if let value = self.createdDate {
            let date = value.timeIntervalSinceReferenceDate as AnyObject?
            dictionary["createdDate"] = date
        }
        
        return dictionary
    }
}

func ==(lhs: Activitylist, rhs: Activitylist) -> Bool {
    return lhs.ID == rhs.ID
}
