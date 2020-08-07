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
//    var ID: String?
    var purchaseType: String?
    var purchaseDescription: String?
    var cost: Double?
    var participantsIDs: [String]?
    var purchaser: [String]?
    //custom number purchase is split by
    var purchaseRowCount: Int?
//    var purchaseDate: Double?
    
    enum CodingKeys: String, CodingKey {
        case name
//        case ID
        case purchaseType
        case purchaseDescription
        case cost
        case participantsIDs
        case purchaser
        case purchaseRowCount
//        case purchaseDate
    }

    init(dictionary: [String: AnyObject]?) {
        super.init()
        name = dictionary?["name"] as? String
//        ID = dictionary?["ID"] as? String
        purchaseType = dictionary?["purchaseType"] as? String
        purchaseDescription = dictionary?["purchaseDescription"] as? String
        cost = dictionary?["cost"] as? Double
        participantsIDs = dictionary?["participantsIDs"] as? [String]
        purchaser = dictionary?["purchaser"] as? [String]
        purchaseRowCount = dictionary?["purchaseRowCount"] as? Int
//        purchaseDate = dictionary?["purchaseDate"] as? NSNumber
        
    }
    
    
    func toAnyObject() -> [String: AnyObject] {
        var dictionary = [String: AnyObject]()
        
        if let value = self.name as AnyObject? {
            dictionary["name"] = value
        }
        
//        if let value = self.ID as AnyObject? {
//            dictionary["ID"] = value
//        }
                
        if let value = self.purchaseType as AnyObject? {
            dictionary["purchaseType"] = value
        }
        
        if let value = self.purchaseDescription as AnyObject? {
            dictionary["purchaseDescription"] = value
        }
        
        if let value = self.cost as AnyObject? {
            dictionary["cost"] = value
        }
        
        if let value = self.participantsIDs as AnyObject? {
            dictionary["participantsIDs"] = value
        }
        
        if let value = self.purchaser as AnyObject? {
            dictionary["purchaser"] = value
        }
                
        if let value = self.purchaseRowCount as AnyObject? {
            dictionary["purchaseRowCount"] = value
        }
        
//        if let value = self.purchaseDate as AnyObject? {
//            dictionary["purchaseDate"] = value
//        }
        
        return dictionary
    }
}

//func ==(lhs: Purchase, rhs: Purchase) -> Bool {
//    return lhs.ID == rhs.ID
//}
