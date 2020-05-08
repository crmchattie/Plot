//
//  Packinglist.swift
//  Plot
//
//  Created by Cory McHattie on 5/1/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import UIKit

class Packinglist: NSObject, Codable {
    
    var name: String?
    var activities: [String: Bool]?
    var items: [String: [Int: Bool]]?
    
    enum CodingKeys: String, CodingKey {
        case name
        case activities
        case items
    }

    init(dictionary: [String: AnyObject]?) {
        super.init()
        
        name = dictionary?["name"] as? String
        activities = dictionary?["activities"] as? [String: Bool]
        items = dictionary?["items"] as? [String: [Int: Bool]]
        
    }
    
    func toAnyObject() -> [String: AnyObject?] {
        var dictionary = [String: AnyObject?]()
        
        if let value = self.name as AnyObject? {
            dictionary["name"] = value
        }
        
        if let value = self.activities as AnyObject? {
            dictionary["activities"] = value
        }
                
        if let value = self.items as AnyObject? {
            dictionary["items"] = value
        }
        
        return dictionary
    }
}
