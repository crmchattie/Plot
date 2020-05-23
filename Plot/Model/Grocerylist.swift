//
//  GroceryList.swift
//  Plot
//
//  Created by Cory McHattie on 5/6/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import UIKit
import CodableFirebase

let grocerylistsEntity = "grocerylists"
let userGrocerylistsEntity = "user-grocerylists"

class Grocerylist: NSObject, Codable {
    
    var name: String?
    var ID: String?
    var recipes: [String: String]?
    var ingredients: [ExtendedIngredient]?
    var servings: [String: Int]?
    var participantsIDs: [String]?
    var activity: Activity?
    var admin: String?
    var badge: Int?
    var pinned: Bool?
    var muted: Bool?
    
    enum CodingKeys: String, CodingKey {
        case name
        case ID
        case recipes
        case ingredients
        case servings
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
        recipes = dictionary?["recipes"] as? [String: String]
        if let ingredientsFirebaseList = dictionary?["ingredients"] as? [AnyObject] {
            var ingredientsList = [ExtendedIngredient]()
            for ingredients in ingredientsFirebaseList {
                if let ingre = try? FirebaseDecoder().decode(ExtendedIngredient.self, from: ingredients) {
                    ingredientsList.append(ingre)
                }
            }
            ingredients = ingredientsList
        }
        servings = dictionary?["servings"] as? [String: Int]
        
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
        
        if let value = self.recipes as AnyObject? {
            dictionary["recipes"] = value
        }
        
        if let value = self.ingredients {
            var firebaseIngredientsList = [[String: AnyObject?]]()
            for ingredient in value {
                let firebaseIngredient = ingredient.toAnyObject()
                firebaseIngredientsList.append(firebaseIngredient)
            }
            dictionary["ingredients"] = firebaseIngredientsList as AnyObject
        }
        
        if let value = self.servings as AnyObject? {
            dictionary["servings"] = value
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
