//
//  RecipeSearchResult.swift
//  Plot
//
//  Created by Hafiz Usama on 2019-12-01.
//  Copyright © 2019 Immature Creations. All rights reserved.
//

import Foundation

struct RecipeSearchResult: Codable {
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

struct Recipe: Codable {
    let id: Int
    let title: String
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

//    enum CodingKeys: String, CodingKey {
//        case vegetarian, vegan, glutenFree, dairyFree, veryHealthy, cheap, veryPopular, sustainable, weightWatcherSmartPoints, gaps, lowFodmap
//        case sourceURL = "sourceUrl"
//        case spoonacularSourceURL = "spoonacularSourceUrl"
//        case aggregateLikes, spoonacularScore, healthScore, creditsText, license, sourceName, pricePerServing, extendedIngredients, id, title, readyInMinutes, servings, image, imageType, nutrition, summary, cuisines, dishTypes, diets, occasions, winePairing, instructions, analyzedInstructions
//    }
}

// MARK: - AnalyzedInstruction
struct AnalyzedInstruction: Codable {
    let name: String?
    let steps: [Step]?
}

// MARK: - Step
struct Step: Codable {
    let number: Int?
    let step: String?
    let ingredients, equipment: [Ent]?
    let length: Length?
}

// MARK: - Ent
struct Ent: Codable {
    let id: Int?
    let name, image: String?
}

// MARK: - Length
struct Length: Codable {
    let number: Int?
    let unit: String?
}

// MARK: - ExtendedIngredient
struct ExtendedIngredient: Codable, Equatable {
    let id: Int?
    let aisle, image: String?
    let consitency: String?
    let name, original, originalString, originalName: String?
    var amount: Double?
    let unit: String?
    let meta, metaInformation: [String]?
    var measures: Measures?
    var recipe: [String: Double]?
    var bool: Bool?
    
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
                        
        return dictionary
    }
    
    static func == (lhs: ExtendedIngredient, rhs: ExtendedIngredient) -> Bool {
        if lhs.id == rhs.id {
            return true
        } else {
            return false
        }
    }
}

// MARK: - Measures
struct Measures: Codable {
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

// MARK: - Metric
struct Metric: Codable {
    var amount: Double?
    let unitShort, unitLong: String?
    
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
struct Nutrition: Codable {
    let nutrients: [Nutrient]?
    let ingredients: [Ient]?
    let caloricBreakdown: CaloricBreakdown?
    let weightPerServing: WeightPerServing?
}

// MARK: - CaloricBreakdown
struct CaloricBreakdown: Codable {
    let percentProtein, percentFat, percentCarbs: Double?
}

// MARK: - Ient
struct Ient: Codable {
    let name: String?
    let amount: Double?
    let unit: String?
    let nutrients: [Ient]?
}

// MARK: - Nutrient
struct Nutrient: Codable {
    let title: String?
    let amount: Double?
    let unit: String?
    let percentOfDailyNeeds: Double?
}

// MARK: - WeightPerServing
struct WeightPerServing: Codable {
    let amount: Int?
    let unit: String?
}

// MARK: - WinePairing
struct WinePairing: Codable {
    let pairedWines: [JSONAny]?
    let pairingText: String?
    let productMatches: [JSONAny]?
}

// MARK: - Encode/decode helpers

class JSONNull: Codable, Hashable {

    public static func == (lhs: JSONNull, rhs: JSONNull) -> Bool {
        return true
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(0)
    }

    public init() {}

    public required init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if !container.decodeNil() {
            throw DecodingError.typeMismatch(JSONNull.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Wrong type for JSONNull"))
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encodeNil()
    }
}

class JSONCodingKey: CodingKey {
    let key: String

    required init?(intValue: Int) {
        return nil
    }

    required init?(stringValue: String) {
        key = stringValue
    }

    var intValue: Int? {
        return nil
    }

    var stringValue: String {
        return key
    }
}

class JSONAny: Codable {

    let value: Any

    static func decodingError(forCodingPath codingPath: [CodingKey]) -> DecodingError {
        let context = DecodingError.Context(codingPath: codingPath, debugDescription: "Cannot decode JSONAny")
        return DecodingError.typeMismatch(JSONAny.self, context)
    }

    static func encodingError(forValue value: Any, codingPath: [CodingKey]) -> EncodingError {
        let context = EncodingError.Context(codingPath: codingPath, debugDescription: "Cannot encode JSONAny")
        return EncodingError.invalidValue(value, context)
    }

    static func decode(from container: SingleValueDecodingContainer) throws -> Any {
        if let value = try? container.decode(Bool.self) {
            return value
        }
        if let value = try? container.decode(Int64.self) {
            return value
        }
        if let value = try? container.decode(Double.self) {
            return value
        }
        if let value = try? container.decode(String.self) {
            return value
        }
        if container.decodeNil() {
            return JSONNull()
        }
        throw decodingError(forCodingPath: container.codingPath)
    }

    static func decode(from container: inout UnkeyedDecodingContainer) throws -> Any {
        if let value = try? container.decode(Bool.self) {
            return value
        }
        if let value = try? container.decode(Int64.self) {
            return value
        }
        if let value = try? container.decode(Double.self) {
            return value
        }
        if let value = try? container.decode(String.self) {
            return value
        }
        if let value = try? container.decodeNil() {
            if value {
                return JSONNull()
            }
        }
        if var container = try? container.nestedUnkeyedContainer() {
            return try decodeArray(from: &container)
        }
        if var container = try? container.nestedContainer(keyedBy: JSONCodingKey.self) {
            return try decodeDictionary(from: &container)
        }
        throw decodingError(forCodingPath: container.codingPath)
    }

    static func decode(from container: inout KeyedDecodingContainer<JSONCodingKey>, forKey key: JSONCodingKey) throws -> Any {
        if let value = try? container.decode(Bool.self, forKey: key) {
            return value
        }
        if let value = try? container.decode(Int64.self, forKey: key) {
            return value
        }
        if let value = try? container.decode(Double.self, forKey: key) {
            return value
        }
        if let value = try? container.decode(String.self, forKey: key) {
            return value
        }
        if let value = try? container.decodeNil(forKey: key) {
            if value {
                return JSONNull()
            }
        }
        if var container = try? container.nestedUnkeyedContainer(forKey: key) {
            return try decodeArray(from: &container)
        }
        if var container = try? container.nestedContainer(keyedBy: JSONCodingKey.self, forKey: key) {
            return try decodeDictionary(from: &container)
        }
        throw decodingError(forCodingPath: container.codingPath)
    }

    static func decodeArray(from container: inout UnkeyedDecodingContainer) throws -> [Any] {
        var arr: [Any] = []
        while !container.isAtEnd {
            let value = try decode(from: &container)
            arr.append(value)
        }
        return arr
    }

    static func decodeDictionary(from container: inout KeyedDecodingContainer<JSONCodingKey>) throws -> [String: Any] {
        var dict = [String: Any]()
        for key in container.allKeys {
            let value = try decode(from: &container, forKey: key)
            dict[key.stringValue] = value
        }
        return dict
    }

    static func encode(to container: inout UnkeyedEncodingContainer, array: [Any]) throws {
        for value in array {
            if let value = value as? Bool {
                try container.encode(value)
            } else if let value = value as? Int64 {
                try container.encode(value)
            } else if let value = value as? Double {
                try container.encode(value)
            } else if let value = value as? String {
                try container.encode(value)
            } else if value is JSONNull {
                try container.encodeNil()
            } else if let value = value as? [Any] {
                var container = container.nestedUnkeyedContainer()
                try encode(to: &container, array: value)
            } else if let value = value as? [String: Any] {
                var container = container.nestedContainer(keyedBy: JSONCodingKey.self)
                try encode(to: &container, dictionary: value)
            } else {
                throw encodingError(forValue: value, codingPath: container.codingPath)
            }
        }
    }

    static func encode(to container: inout KeyedEncodingContainer<JSONCodingKey>, dictionary: [String: Any]) throws {
        for (key, value) in dictionary {
            let key = JSONCodingKey(stringValue: key)!
            if let value = value as? Bool {
                try container.encode(value, forKey: key)
            } else if let value = value as? Int64 {
                try container.encode(value, forKey: key)
            } else if let value = value as? Double {
                try container.encode(value, forKey: key)
            } else if let value = value as? String {
                try container.encode(value, forKey: key)
            } else if value is JSONNull {
                try container.encodeNil(forKey: key)
            } else if let value = value as? [Any] {
                var container = container.nestedUnkeyedContainer(forKey: key)
                try encode(to: &container, array: value)
            } else if let value = value as? [String: Any] {
                var container = container.nestedContainer(keyedBy: JSONCodingKey.self, forKey: key)
                try encode(to: &container, dictionary: value)
            } else {
                throw encodingError(forValue: value, codingPath: container.codingPath)
            }
        }
    }

    static func encode(to container: inout SingleValueEncodingContainer, value: Any) throws {
        if let value = value as? Bool {
            try container.encode(value)
        } else if let value = value as? Int64 {
            try container.encode(value)
        } else if let value = value as? Double {
            try container.encode(value)
        } else if let value = value as? String {
            try container.encode(value)
        } else if value is JSONNull {
            try container.encodeNil()
        } else {
            throw encodingError(forValue: value, codingPath: container.codingPath)
        }
    }

    public required init(from decoder: Decoder) throws {
        if var arrayContainer = try? decoder.unkeyedContainer() {
            self.value = try JSONAny.decodeArray(from: &arrayContainer)
        } else if var container = try? decoder.container(keyedBy: JSONCodingKey.self) {
            self.value = try JSONAny.decodeDictionary(from: &container)
        } else {
            let container = try decoder.singleValueContainer()
            self.value = try JSONAny.decode(from: container)
        }
    }

    public func encode(to encoder: Encoder) throws {
        if let arr = self.value as? [Any] {
            var container = encoder.unkeyedContainer()
            try JSONAny.encode(to: &container, array: arr)
        } else if let dict = self.value as? [String: Any] {
            var container = encoder.container(keyedBy: JSONCodingKey.self)
            try JSONAny.encode(to: &container, dictionary: dict)
        } else {
            var container = encoder.singleValueContainer()
            try JSONAny.encode(to: &container, value: self.value)
        }
    }
}

