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
    var purchaser: [String]?
    var purchaseRowCount: Int?
    
    enum CodingKeys: String, CodingKey {
        case name
        case purchaseType
        case purchaseDescription
        case cost
        case participantsIDs
        case purchaser
        case purchaseRowCount
    }

    init(dictionary: [String: AnyObject]?){
        super.init()
        
        name = dictionary?["name"] as? String
        purchaseType = dictionary?["purchaseType"] as? String
        purchaseDescription = dictionary?["purchaseDescription"] as? String
        cost = dictionary?["cost"] as? Double
        participantsIDs = dictionary?["participantsIDs"] as? [String]
        purchaser = dictionary?["purchaser"] as? [String]
        purchaseRowCount = dictionary?["purchaseRowCount"] as? Int
        
    }
    
    func toAnyObject() -> [String: AnyObject?] {
        var purchaseDict = [String: AnyObject?]()
        
        if let value = self.name as AnyObject? {
            purchaseDict["name"] = value
        }
                
        if let value = self.purchaseType as AnyObject? {
            purchaseDict["purchaseType"] = value
        }
        
        if let value = self.purchaseDescription as AnyObject? {
            purchaseDict["purchaseDescription"] = value
        }
        
        if let value = self.cost as AnyObject? {
            purchaseDict["cost"] = value
        }
        
        if let value = self.participantsIDs as AnyObject? {
            purchaseDict["participantsIDs"] = value
        }
        
        if let value = self.purchaser as AnyObject? {
            purchaseDict["purchaser"] = value
        }
                
        if let value = self.purchaseRowCount as AnyObject? {
            purchaseDict["purchaseRowCount"] = value
        }
        
        return purchaseDict
    }
}
