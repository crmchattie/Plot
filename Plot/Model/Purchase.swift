//
//  Purchase.swift
//  Pigeon-project
//
//  Created by Cory McHattie on 6/6/19.
//  Copyright © 2019 Immature Creations. All rights reserved.
//

import UIKit

class Purchase: NSObject, Codable {
    
    var name: String?
    var purchaseType: String?
    var purchaseDescription: String?
    var cost: Double?
    var participantsIDs: [String]?
    
    enum CodingKeys: String, CodingKey {
        case name
        case purchaseType
        case purchaseDescription
        case cost
        case participantsIDs
    }

    init(dictionary: [String: AnyObject]?){
        super.init()
        
        name = dictionary?["name"] as? String
        purchaseType = dictionary?["purchaseType"] as? String
        purchaseDescription = dictionary?["purchaseDescription"] as? String
        cost = dictionary?["cost"] as? Double
        participantsIDs = dictionary?["participantsIDs"] as? [String]
        
    }
    
    func toAnyObject() -> [String: AnyObject?] {
        var purchaseDict = [String: AnyObject?]()
        
        purchaseDict["name"] = self.name as AnyObject?
        
        if let value = self.purchaseType as AnyObject? {
            purchaseDict["purchaseType"] = value
        }
        
        if let value = self.purchaseDescription as AnyObject? {
            purchaseDict["purchaseDescription"] = value
        }
        
        purchaseDict["cost"] = self.cost as AnyObject?
        purchaseDict["participantsIDs"] = self.participantsIDs as AnyObject?
        
        return purchaseDict
    }
}
