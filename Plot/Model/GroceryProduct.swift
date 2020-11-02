//
//  GroceryProduct.swift
//  Plot
//
//  Created by Cory McHattie on 10/26/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import Foundation

// MARK: - MenuProduct
struct GroceryProductSearch: Codable {
    let products: [GroceryProduct]?
    let totalProducts: Int?
    let type: String?
    let offset, number: Int?
}

// MARK: - GroceryProduct
struct GroceryProduct: Codable, Equatable, Hashable {
    let id: Int
    let title: String
    let breadcrumbs: [String]?
    let imageType: String?
    let badges, importantBadges: [String]?
    let ingredientCount: Int?
    let generatedText: String?
    let ingredientList: String?
    let ingredients: [Ingredient]?
    let likes: Int?
    let aisle: String?
    let nutrition: Nutrition?
    let price: Double?
    let servings: Servings?
    let serving_size: String?
    let number_of_servings: Double?
    let spoonacularScore: Int?
    let image: String?
    var recipe: [String: Double]?
    var bool: Bool?
    var amount: Int?
}

func ==(lhs: GroceryProduct, rhs: GroceryProduct) -> Bool {
    return lhs.id == rhs.id
}

// MARK: - Ingredient
struct Ingredient: Codable, Hashable {
    let ingredientDescription: String?
    let name: String?
    let safetyLevel: String?

    enum CodingKeys: String, CodingKey {
        case ingredientDescription = "description"
        case name
        case safetyLevel = "safety_level"
    }
}

// MARK: - Servings
struct Servings: Codable, Equatable, Hashable {
    let number: Double?
    let size: Double?
    let unit: String?
}
