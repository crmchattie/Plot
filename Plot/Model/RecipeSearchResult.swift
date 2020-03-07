//
//  RecipeSearchResult.swift
//  Plot
//
//  Created by Hafiz Usama on 2019-12-01.
//  Copyright © 2019 Immature Creations. All rights reserved.
//

import Foundation

struct RecipeSearchResult: Codable {
    let recipes: [Recipe]
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
    let readyInMinutes, servings: Int?
    let image: String
    let imageUrls: [String]?
}

//enum Cuisine: String {
//    case African, American, British, Cajun, Caribbean, Chinese, European, French, German, Greek, Indian, Irish, Italian, Japanese, Jewish, Korean, Latin_American, Mediterranean, Mexican, Middle_Eastern, Nordic, Southern, Spanish, Thai, Vietnamese
//    
//}
//
//enum Diet: String {
//    case Gluten_Free, Ketogenic, Vegetarian, Lacto_Vegetarian, Ovo_Vegetarian, Vegan, Pescetarian, Paleo, Whole
//}
//
//enum Intolerance: String {
//    case Dairy, Egg, Gluten, Grain, Peanut, Seafood, Sesame, Shellfish, Soy, Sulfite, Tree_Nut, Wheat
//}
//
//enum Type: String {
//    case main_course, side_dish, dessert, appetizer, salad, bread, breakfast, soup, beverage, sauce, marinade, fingerfood, snack, drink
//}
