//
//  Section.swift
//  Plot
//
//  Created by Cory McHattie on 7/3/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import Foundation

enum ActivitySection: Hashable, CaseIterable {
    case custom
    case food
    case nightlife
    case events
    case sightseeing
    case recreation
    case shopping
    case workouts
    case recipes
    case american
    case italian
    case vegetarian
    case mexican
    case breakfast
    case dessert
    case music
    case sports
    case artstheatre
    case family
    case film
    case miscellaneous
    case quick
    case hiit
    case cardio
    case yoga
    case medium
    case strength
    case search
    
    var name: String {
        switch self {
        case .custom: return "Build Your Own"
        case .food: return "Food"
        case .nightlife: return "Nightlife"
        case .events: return "Events"
        case .sightseeing: return "Sightseeing"
        case .recreation: return "Recreation"
        case .shopping: return "Shopping"
        case .workouts: return "Workouts"
        case .recipes: return "Recipes"
        case .american: return "American"
        case .italian: return "Italian"
        case .vegetarian: return "Vegetarian"
        case .mexican: return "Mexican"
        case .breakfast: return "Breakfast"
        case .dessert: return "Dessert"
        case .music: return "Music"
        case .sports: return "Sports"
        case .artstheatre: return "Arts & Theatre"
        case .family: return "Family"
        case .film: return "Film"
        case .miscellaneous: return "Miscellaneous"
        case .quick: return "Quick"
        case .hiit: return "HIIT"
        case .cardio: return "Cardio"
        case .yoga: return "Yoga"
        case .medium: return "Medium"
        case .strength: return "Strength"
        case .search: return "Search"
        }
    }
    
    var type: String {
        switch self {
        case .custom: return "ActivityType"
        case .food, .nightlife, .recreation, .shopping: return "FSVenue"
        case .events, .music, .sports, .artstheatre, .family, .film, .miscellaneous: return "Event"
        case .sightseeing: return "SygicPlace"
        case .workouts, .quick, .hiit, .cardio, .yoga, .medium, .strength: return "Workout"
        case .recipes, .american, .italian, .vegetarian, .mexican, .breakfast, .dessert: return "Recipe"
        case .search: return "Search"
            
        }
    }
    
    var subType: String {
        switch self {
        case .custom: return "ActivityType"
        case .food, .nightlife, .recreation, .shopping, .events, .music, .sports, .artstheatre, .family, .film, .miscellaneous, .sightseeing: return "Category"
        case .workouts, .hiit, .cardio, .yoga, .strength: return "Type"
        case .quick, .medium: return "Duration"
        case .recipes, .american, .italian, .mexican: return "Cuisine"
        case .breakfast, .dessert: return "Query"
        case .vegetarian: return "Diet"
        case .search: return "Search"
            
        }
    }
    
    var searchTerm: String {
        switch self {
        case .custom: return ""
        case .food: return "4d4b7105d754a06374d81259"
        case .nightlife: return "4d4b7105d754a06376d81259"
        case .events: return "Events"
        case .sightseeing: return "Sightseeing"
        case .recreation: return "4d4b7105d754a06377d81259"
        case .shopping: return "4d4b7105d754a06378d81259"
        case .recipes, .american: return "American"
        case .italian: return "Italian"
        case .vegetarian: return "Vegetarian"
        case .mexican: return "Mexican"
        case .breakfast: return "Breakfast"
        case .dessert: return "Dessert"
        case .music: return "Music"
        case .sports: return "Sports"
        case .artstheatre: return "Arts & Theatre"
        case .family: return "Family"
        case .film: return "Film"
        case .miscellaneous: return "Miscellaneous"
        case .quick: return "short"
        case .hiit: return "hiit"
        case .cardio: return "cardio"
        case .yoga: return "yoga"
        case .medium: return "medium"
        case .workouts, .strength: return "work_out"
        case .search: return "Search"
        }
    }
}
