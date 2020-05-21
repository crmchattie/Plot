//
//  ListContainer.swift
//  Plot
//
//  Created by Cory McHattie on 5/20/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import UIKit
import CodableFirebase

//class ListContainer: NSObject, Codable {
//    
//    var grocerylist: Grocerylist?
//    var checklist: Checklist?
//    var packinglist: Packinglist?
//    
//    enum CodingKeys: String, CodingKey {
//        case grocerylist
//        case checklist
//        case packinglist
//    }
//
//    init(dictionary: [String: AnyObject]?) {
//        super.init()
//
//        if let checklistFirebaseList = dictionary?["checklist"] as? [AnyObject] {
//            var checklistList = [Checklist]()
//            for checklist in checklistFirebaseList {
//                let check = Checklist(dictionary: checklist as? [String : AnyObject])
//                if check.name == "nothing" { continue }
//                checklistList.append(check)
//            }
//            checklist = checklistList
//        } else if let items = dictionary?["checklist"] as? [String : [String : Bool]] {
//            let check = Checklist(dictionary: ["name": "Checklist" as AnyObject])
//            var checklistItems = [String: Bool]()
//            for item in items.values {
//                checklistItems[item.keys.first!] = item.values.first
//            }
//            check.items = checklistItems
//            checklist = [check]
//        }
//
//        if let packinglistFirebaseList = dictionary?["packinglist"] as? [AnyObject] {
//            var packinglistList = [Packinglist]()
//            for packinglist in packinglistFirebaseList {
//                let pack = Packinglist(dictionary: packinglist as? [String : AnyObject])
//                if pack.name == "nothing" { continue }
//                packinglistList.append(pack)
//            }
//            packinglist = packinglistList
//        }
//
//        if let packingList = dictionary?["packinglist"] as? [String : AnyObject] {
//            packinglist = Packinglist(dictionary: packingList)
//        }
//
//        if let groceryList = dictionary?["grocerylist"] as? [String : AnyObject] {
//            grocerylist = Grocerylist(dictionary: groceryList)
//        }
//
//    }
//
//    func toAnyObject() -> [String: AnyObject?] {
//        var dictionary = [String: AnyObject?]()
//
//        if let value = self.name as AnyObject? {
//            dictionary["name"] = value
//        }
//
//        if let value = self.recipes as AnyObject? {
//            dictionary["recipes"] = value
//        }
//
//        if let value = self.ingredients {
//            var firebaseIngredientsList = [[String: AnyObject?]]()
//            for ingredient in value {
//                let firebaseIngredient = ingredient.toAnyObject()
//                firebaseIngredientsList.append(firebaseIngredient)
//            }
//            dictionary["ingredients"] = firebaseIngredientsList as AnyObject
//        }
//
//        if let value = self.servings as AnyObject? {
//            dictionary["servings"] = value
//        }
//
//        return dictionary
//    }
//}
//
//func ==(lhs: ListContainer, rhs: ListContainer) -> Bool {
//    return lhs.grocerylist == rhs.grocerylist && lhs.checklist == rhs.checklist && lhs.packinglist == rhs.packinglist
//}

