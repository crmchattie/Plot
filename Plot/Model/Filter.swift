//
//  Filter.swift
//  Plot
//
//  Created by Cory McHattie on 1/30/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import Foundation

enum filter: String {
    //recipes
    case cuisine, excludeCuisine, diet, intolerances, type
    //ticketmaster
//    case type
//    //workouts
//    case type, muscle(s), duration
    
    var typeOfSection: String {
        switch self {
            case .cuisine: return "multiple"
            case .excludeCuisine: return "multiple"
            case .diet: return "single"
            case .intolerances: return "multiple"
            case .type: return "single"
        }
    }
    
    var descriptionText: String {
        switch self {
            case .cuisine: return "Choose one or more cuisines"
            case .excludeCuisine: return "Exclude one or more cuisines"
            case .diet: return "Choose a diet"
            case .intolerances: return "Exclude one or more intolerances"
            case .type: return "Choose a type of recipe e.g. dinner or snack"
        }
    }
    
    var choices: [String] {
        switch self {
            case .cuisine: return ["African", "American", "British", "Cajun", "Caribbean", "Chinese", "European", "French", "German", "Greek", "Indian", "Irish", "Italian", "Japanese", "Jewish", "Korean", "Latin American", "Mediterranean", "Mexican", "Middle Eastern", "Nordic", "Southern", "Spanish", "Thai", "Vietnamese"]
            case .excludeCuisine: return ["African", "American", "British", "Cajun", "Caribbean", "Chinese", "European", "French", "German", "Greek", "Indian", "Irish", "Italian", "Japanese", "Jewish", "Korean", "Latin American", "Mediterranean", "Mexican", "Middle Eastern", "Nordic", "Southern", "Spanish", "Thai", "Vietnamese"]
            case .diet: return ["Gluten Free", "Ketogenic", "Vegetarian", "Lacto-Vegetarian", "Ovo-Vegetarian", "Vegan", "Pescetarian", "Paleo", "Whole"]
            case .intolerances: return ["Dairy", "Egg", "Gluten", "Grain", "Peanut", "Seafood", "Sesame", "Shellfish", "Soy", "Sulfite", "Tree Nut", "Wheat"]
            case .type: return ["Main Course", "Side Dish", "Dessert", "Appetizer", "Salad", "Bread", "Breakfast", "Soup", "Beverage", "Sauce", "Marinade", "Fingerfood", "Snack", "Drink"]
        }
    }
    
}
