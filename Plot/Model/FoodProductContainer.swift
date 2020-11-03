//
//  FoodProductContainer.swift
//  Plot
//
//  Created by Cory McHattie on 10/28/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import Foundation

struct FoodProductContainer: Codable, Equatable, Hashable {
    var groceryProduct: GroceryProduct?
    var menuProduct: MenuProduct?
    var recipeProduct: Recipe?
    var complexIngredient: ExtendedIngredient?
    var basicIngredient: BasicIngredient?
    
    var ID: Int {
        return groceryProduct?.id ?? menuProduct?.id ?? recipeProduct?.id ?? complexIngredient?.id ?? basicIngredient?.id ?? 0
    }
    
    var title: String {
        return groceryProduct?.title ?? menuProduct?.title ?? recipeProduct?.title ?? complexIngredient?.name ?? basicIngredient?.title ?? ""
    }
    
    var subtitle: String {
        if groceryProduct != nil {
            return "Grocery Item"
        } else if menuProduct != nil {
            if menuProduct!.restaurantChain != "" {
                return menuProduct!.restaurantChain ?? "Restaurant Item"
            }
            return "Restaurant Item"
        } else if recipeProduct != nil {
            return "Recipe"
        } else if complexIngredient != nil || basicIngredient != nil {
            return "Ingredient"
        } else {
            return "none"
        }
    }
    
    var image: String {
        return groceryProduct?.image ?? menuProduct?.image ?? recipeProduct?.image ?? ""
    }
    
}
