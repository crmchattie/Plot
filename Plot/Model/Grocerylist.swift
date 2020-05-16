//
//  GroceryList.swift
//  Plot
//
//  Created by Cory McHattie on 5/6/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import UIKit
import CodableFirebase

class Grocerylist: NSObject, Codable {
    
    var name: String?
    var recipes: [String: String]?
    var ingredients: [ExtendedIngredient]?
    var servings: [String: Int]?
    
    enum CodingKeys: String, CodingKey {
        case name
        case recipes
        case ingredients
        case servings
    }

    init(dictionary: [String: AnyObject]?) {
        super.init()
        
        name = dictionary?["name"] as? String
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
        
    }
    
    func toAnyObject() -> [String: AnyObject?] {
        var dictionary = [String: AnyObject?]()
        
        if let value = self.name as AnyObject? {
            dictionary["name"] = value
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
                                
        return dictionary
    }
}
