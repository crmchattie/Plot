//
//  RecipeSearchResult.swift
//  Plot
//
//  Created by Hafiz Usama on 2019-12-01.
//  Copyright © 2019 Immature Creations. All rights reserved.
//

import Foundation

struct RecipeSearchResult: Codable, Equatable, Hashable {
    var recipes: [Recipe]
    let baseURI: String?
    let offset, number, totalResults, processingTimeMS: Int?
    let expires: Int?

    enum CodingKeys: String, CodingKey {
        case recipes = "results"
        case baseURI = "baseUri"
        case offset, number, totalResults
        case processingTimeMS = "processingTimeMs"
        case expires
    }
}

struct Recipe: Codable, Equatable, Hashable {
    let uuid = UUID().uuidString
    let id: Int
    var title: String
    var readyInMinutes, servings: Int?
    let image: String
    let imageType: String?
    let imageUrls: [String]?
    let vegetarian, vegan, glutenFree, dairyFree: Bool?
    let veryHealthy, cheap, veryPopular, sustainable: Bool?
    let weightWatcherSmartPoints: Int?
    let gaps: String?
    let lowFodmap: Bool?
    let sourceUrl: String?
    let spoonacularSourceUrl: String?
    let aggregateLikes, spoonacularScore, healthScore: Int?
    let creditsText, license, sourceName: String?
    let pricePerServing: Double?
    var extendedIngredients: [ExtendedIngredient]?
    let nutrition: Nutrition?
    let summary: String?
    let cuisines, dishTypes: [String]?
    let diets, occasions: [String]?
    let winePairing: WinePairing?
    let instructions: String?
    let analyzedInstructions: [AnalyzedInstruction]?
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(uuid)
    }
}

func ==(lhs: Recipe, rhs: Recipe) -> Bool {
    return lhs.uuid == rhs.uuid
}

// MARK: - AnalyzedInstruction
struct AnalyzedInstruction: Codable, Equatable, Hashable {
    let name: String?
    let steps: [Step]?
}

// MARK: - Step
struct Step: Codable, Equatable, Hashable {
    let number: Int?
    let step: String?
    let ingredients, equipment: [Ent]?
    let length: Length?
}

// MARK: - Ent
struct Ent: Codable, Equatable, Hashable {
    let id: Int?
    let name, image: String?
}

// MARK: - Length
struct Length: Codable, Equatable, Hashable {
    let number: Int?
    let unit: String?
}

// MARK: - ExtendedIngredient
struct ExtendedIngredient: Codable, Equatable, Hashable {
    let id: Int?
    let aisle, image: String?
    let consitency: String?
    let name, original, originalString, originalName: String?
    var amount: Double?
    var unit: String?
    let meta, metaInformation: [String]?
    var measures: Measures?
    var recipe: [String: Double]?
    var bool: Bool?
    var unitLong: String?
    var unitShort: String?
    var possibleUnits: [String]?
    var shoppingListUnits: [String]?
    let nutrition: Nutrition?
    let estimatedCost: EstimatedCost?
    let consistency: String?
    let categoryPath: [String]?
    
    func toAnyObject() -> [String: AnyObject?] {
        var dictionary = [String: AnyObject?]()
        
        if let value = self.id as AnyObject? {
            dictionary["id"] = value
        }
        
        if let value = self.aisle as AnyObject? {
            dictionary["aisle"] = value
        }
        
        if let value = self.image as AnyObject? {
            dictionary["image"] = value
        }
        
        if let value = self.name as AnyObject? {
            dictionary["name"] = value
        }
        
        if let value = self.original as AnyObject? {
            dictionary["original"] = value
        }
        
        if let value = self.originalString as AnyObject? {
            dictionary["originalString"] = value
        }
        
        if let value = self.originalName as AnyObject? {
            dictionary["originalName"] = value
        }
        
        if let value = self.amount as AnyObject? {
            dictionary["amount"] = value
        }
        
        if let value = self.unit as AnyObject? {
            dictionary["unit"] = value
        }
        
        if let value = self.meta as AnyObject? {
            dictionary["meta"] = value
        }
        
        if let value = self.metaInformation as AnyObject? {
            dictionary["metaInformation"] = value
        }
        
        if let value = self.measures {
            let firebase = value.toAnyObject()
            dictionary["measures"] = firebase as AnyObject
        }
        
        if let value = self.recipe as AnyObject? {
            dictionary["recipe"] = value
        }
        
        if let value = self.bool as AnyObject? {
            dictionary["bool"] = value
        }
        
        if let value = self.unitLong as AnyObject? {
            dictionary["unitLong"] = value
        }
        
        if let value = self.unitShort as AnyObject? {
            dictionary["unitShort"] = value
        }
        
        if let value = self.possibleUnits as AnyObject? {
            dictionary["possibleUnits"] = value
        }
        
        if let value = self.shoppingListUnits as AnyObject? {
            dictionary["shoppingListUnits"] = value
        }
        
        if let value = self.nutrition as AnyObject? {
            dictionary["nutrition"] = value
        }
        
        if let value = self.estimatedCost {
            let firebase = value.toAnyObject()
            dictionary["estimatedCost"] = firebase as AnyObject
        }
        
        if let value = self.consistency as AnyObject? {
            dictionary["consistency"] = value
        }
        
        if let value = self.categoryPath as AnyObject? {
            dictionary["categoryPath"] = value
        }
                        
        return dictionary
    }
}

func ==(lhs: ExtendedIngredient, rhs: ExtendedIngredient) -> Bool {
    return lhs.id == rhs.id
}

// MARK: - Measures
struct Measures: Codable, Equatable, Hashable {
    var us, metric: Metric?
    
    func toAnyObject() -> [String: AnyObject?] {
        var dictionary = [String: AnyObject?]()
        
        if let value = self.us {
            let firebase = value.toAnyObject()
            dictionary["us"] = firebase as AnyObject
        }
        
        if let value = self.metric {
            let firebase = value.toAnyObject()
            dictionary["metric"] = firebase as AnyObject
        }
        
        return dictionary
    }
}

// MARK: - EstimatedCost
struct EstimatedCost: Codable, Equatable, Hashable {
    let value: Double?
    let unit: String?
    
    func toAnyObject() -> [String: AnyObject?] {
        var dictionary = [String: AnyObject?]()
        
        if let value = self.value as AnyObject? {
            dictionary["value"] = value
        }
        
        if let value = self.unit as AnyObject? {
            dictionary["unit"] = value
        }
        
        return dictionary
    }
}

// MARK: - Metric
struct Metric: Codable, Equatable, Hashable {
    var amount: Double?
    var unitShort, unitLong: String?
    
    func toAnyObject() -> [String: AnyObject?] {
        var dictionary = [String: AnyObject?]()
        
        if let value = self.amount as AnyObject? {
            dictionary["amount"] = value
        }
        
        if let value = self.unitShort as AnyObject? {
            dictionary["unitShort"] = value
        }
                
        if let value = self.unitLong as AnyObject? {
            dictionary["unitLong"] = value
        }
        
        return dictionary
    }
}

// MARK: - Nutrition
struct Nutrition: Codable, Equatable, Hashable {
    var nutrients, properties: [Nutrient]?
    var ingredients: [Ient]?
    var caloricBreakdown: CaloricBreakdown?
    var weightPerServing: WeightPerServing?
    var calories: Double?
    var fat, protein, carbs: String?
}

// MARK: - CaloricBreakdown
struct CaloricBreakdown: Codable, Equatable, Hashable {
    let percentProtein, percentFat, percentCarbs: Double?
}

// MARK: - Ient
struct Ient: Codable, Equatable, Hashable {
    var name: String?
    var amount: Double?
    var unit: String?
    var nutrients: [Ient]?
}

// MARK: - Nutrient
struct Nutrient: Codable, Equatable, Hashable {
    var title: String?
    var amount: Double?
    var unit: String?
    var percentOfDailyNeeds: Double?
}

// MARK: - WeightPerServing
struct WeightPerServing: Codable, Equatable, Hashable {
    let amount: Int?
    let unit: String?
}

// MARK: - WinePairing
struct WinePairing: Codable, Equatable, Hashable {
    let pairedWines: [String]?
    let pairingText: String?
    let productMatches: [ProductMatch]?
}

// MARK: - ProductMatch
struct ProductMatch: Codable, Equatable, Hashable  {
    let id: Int?
    let title: String?
    let averageRating: Double?
    let productMatchDescription: String?
    let imageURL: String?
    let link: String?
    let price: String?
    let ratingCount: Int?
    let score: Double?

    enum CodingKeys: String, CodingKey {
        case id, title, averageRating
        case productMatchDescription = "description"
        case imageURL = "imageUrl"
        case link, price, ratingCount, score
    }
}

