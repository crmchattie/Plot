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
    var items: [String: Bool]?
    
    enum CodingKeys: String, CodingKey {
        case name
        case items
    }

    init(dictionary: [String: AnyObject]?) {
        super.init()
        name = dictionary?["name"] as? String
        items = dictionary?["items"] as? [String: Bool]
    }
    
    func toAnyObject() -> [String: AnyObject?] {
        var dictionary = [String: AnyObject?]()
        
        if let value = self.name as AnyObject? {
            dictionary["name"] = value
        }
                
        if let value = self.items as AnyObject? {
            dictionary["items"] = value
        }
        
        return dictionary
    }
}
