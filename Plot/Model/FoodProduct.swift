//
//  FoodProductSearch.swift
//  Plot
//
//  Created by Cory McHattie on 11/1/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

// This file was generated from JSON Schema using quicktype, do not modify it directly.
// To parse the JSON, add this file to your project and do:
//
//   let foodSearch = try? newJSONDecoder().decode(FoodSearch.self, from: jsonData)

import Foundation

// MARK: - FoodSearch
struct FoodSearch: Codable {
    let text: String?
    let parsed: [FoodParsed]?
    let hints: [FoodHint]?
    let links: Links?

    enum CodingKeys: String, CodingKey {
        case text, parsed, hints
        case links = "_links"
    }
}

// MARK: - Hint
struct FoodHint: Codable {
    let food: Food?
    let measures: [Measure]?
}

// MARK: - Food
struct Food: Codable {
    let foodID: String?
    let uri: String?
    let label: String?
    let nutrients: Nutrients?
    let category: FoodCategory?
    let categoryLabel: CategoryLabel?
    let image: String?
    let servingsPerContainer: Double?

    enum CodingKeys: String, CodingKey {
        case foodID = "foodId"
        case uri, label, nutrients, category, categoryLabel, image, servingsPerContainer
    }
}

enum FoodCategory: String, Codable {
    case genericFoods = "Generic foods"
    case genericMeals = "Generic meals"
    case packagedFoods = "Packaged foods"
    case fastFoods = "Fast foods"
}

enum CategoryLabel: String, Codable {
    case food = "food"
    case meal = "meal"
}



// MARK: - Nutrients
struct Nutrients: Codable {
    let enercKcal, procnt, fat, chocdf, fibtg: Double?

    enum CodingKeys: String, CodingKey {
        case enercKcal = "ENERC_KCAL"
        case procnt = "PROCNT"
        case fat = "FAT"
        case chocdf = "CHOCDF"
        case fibtg = "FIBTG"
    }
}

// MARK: - Measure
struct Measure: Codable {
    let uri: String?
    let label: String?
    let weight: Double?
    let qualified: [Qualified]?
}

// MARK: - Qualified
struct Qualified: Codable {
    let qualifiers: [Qualifier]?
    let weight: Int?
}

// MARK: - Qualifier
struct Qualifier: Codable {
    let uri: String?
    let label: String?
}

enum Label: String, Codable {
    case chopped = "chopped"
    case extraLarge = "extra large"
    case large = "large"
    case medium = "medium"
    case small = "small"
}

// MARK: - Links
struct Links: Codable {
    let next: Next?
}

// MARK: - Next
struct Next: Codable {
    let title: String?
    let href: String?
}

// MARK: - Parsed
struct FoodParsed: Codable {
    let food: Food?
}

// MARK: - NutrientSearch
struct NutrientSearch: Codable {
    let uri: String?
    let calories, glycemicIndex, totalWeight: Int?
    let dietLabels: [String]?
    let healthLabels: [String]?
    let cautions: [String]?
    let totalNutrients, totalDaily: [String: Total]?
    let ingredients: [FoodIngredient]?
}

// MARK: - Ingredient
struct FoodIngredient: Codable {
    let parsed: [NutrientParsed]?
}

// MARK: - Parsed
struct NutrientParsed: Codable {
    let quantity: Int?
    let measure, food, foodID: String?
    let foodURI: String?
    let weight, retainedWeight: Int?
    let measureURI: String?
    let status: String?

    enum CodingKeys: String, CodingKey {
        case quantity, measure, food
        case foodID = "foodId"
        case foodURI, weight, retainedWeight, measureURI, status
    }
}

// MARK: - Total
struct Total: Codable {
    let label: String?
    let quantity: Double?
    let unit: Unit?
}

enum Unit: String, Codable {
    case empty = "%"
    case g = "g"
    case kcal = "kcal"
    case mg = "mg"
    case µg = "µg"
}

enum FoodHealthLabels: String, Codable {
    case alcohol_free = "alcohol-free"
    case celery_free = "celery-free"
    case crustacean_free = "crustacean-free"
    case dairy_free = "dairy-free"
    case egg_free = "egg-free"
    case fish_free = "fish-free"
    case fodmap_free = "fodmap-free"
    case gluten_free = "gluten-free"
    case kosher = "kosher"
    case lupine_free = "lupine-free"
    case mustard_free = "mustard-free"
    case no_oil_added = "No-oil-added"
    case low_sugar = "low-sugar"
    case paleo = "paleo"
    case peanut_free = "peanut-free"
    case pecatarian = "pecatarian"
    case pork_free = "pork-free"
    case red_meat_free = "red-meat-free"
    case sesame_free = "sesame-free"
    case shellfish_free = "shellfish-free"
    case soy_free = "soy-free"
    case tree_nut_free = "tree-nut-free"
    case vegan = "vegan"
    case vegetarian = "vegetarian"
    case wheat_free = "wheat-free"
}

enum DietFoodLabels: String, Codable {
    case balance = "balanced"
    case high_protein = "high-protein"
    case high_fiber = "high-fiber"
    case low_fat = "low-fat"
    case low_carb = "low-carb"
    case low_sodium = "low-sodium"
}


