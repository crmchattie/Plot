//
//  ActivitySubcategory.swift
//  Plot
//
//  Created by Cory McHattie on 7/29/22.
//  Copyright © 2022 Immature Creations. All rights reserved.
//

import Foundation
import UIKit

let userActivitySubcategoriesEntity = "user-activities-subcategories"

private let keywordsMap = ["Workout": ["fitness", "workout", "run", "training", "cycling", "hiit", "exercise"],
                           "Mindfulness": ["mindfulness", "meditation"],
                           "Wedding": ["wedding"],
                           "Social": ["party", "birthday"],
                           "Family": ["family"],
                           "Doctor": ["appointment", "therapy", "dr", "doctor"],
                           "Personal": ["consultation", "haircut", "read", "journal"],
                           "Meal": ["dinner", "lunch", "meal", "breakfast", "reservation"],
                           "Travel": ["trip", "vacation"],
                           "Bills": ["bill", "payment"],
                           "Kids": ["kids"]
]

enum ActivitySubcategory: String, Codable, CaseIterable {
    case bills = "Bills"
    case car = "Car"
    case chores = "Chores"
    case doctor = "Doctor"
    case entertainment = "Entertainment"
    case errand = "Errand"
    case family = "Family"
    case finances = "Finances"
    case health = "Health"
    case home = "Home"
    case hygiene = "Hygiene"
    case investments = "Investments"
    case kids = "Kids"
    case leisure = "Leisure"
    case meal = "Meal"
    case mindfulness = "Mindfulness"
    case moving = "Moving"
    case personal = "Personal"
    case pets = "Pets"
    case savings = "Savings"
    case school = "School"
    case shopping = "Shopping"
    case skill = "Skill"
    case sleep = "Sleep"
    case social = "Social"
    case spending = "Spending"
    case timeOff = "Time Off"
    case todo = "To-do"
    case travel = "Travel"
    case wedding = "Wedding"
    case work = "Work"
    case workout = "Workout"
    case uncategorized = "Uncategorized"
    /// Same as uncategorized but not included in the analytics
    case notApplicable = "Not Applicable"
    
    static var allValues: [String] {
        var array = [String]()
        ActivitySubcategory.allCases.forEach { subcategory in
            if subcategory != .uncategorized && subcategory != .notApplicable {
                array.append(subcategory.rawValue)
            }
        }
        return array
    }
    
    var icon: UIImage {
        switch self {
        case .health: return UIImage(named: "heart-filled")!
        case .meal: return UIImage(named: "food")!
        case .work: return UIImage(named: "work")!
        case .school: return UIImage(named: "school")!
        case .social: return UIImage(named: "nightlife")!
        case .leisure: return UIImage(named: "leisure")!
        case .family: return UIImage(named: "family")!
        case .personal: return UIImage(named: "personal")!
        case .todo: return UIImage(named: "todo")!
        case .finances: return UIImage(named: "money")!
        case .spending: return UIImage(named: "transaction")!
        case .investments: return UIImage(named: "money")!
        case .uncategorized: return UIImage(named: "event")!
        case .bills: return UIImage(named: "transaction")!
        case .car: return UIImage(named: "car")!
        case .chores: return UIImage(named: "todo")!
        case .doctor: return UIImage(named: "doctor")!
        case .entertainment: return UIImage(named: "nightlife")!
        case .errand: return UIImage(named: "todo")!
        case .home: return UIImage(named: "home")!
        case .hygiene: return UIImage(named: "hygiene")!
        case .kids: return UIImage(named: "kids")!
        case .mindfulness: return UIImage(named: "mindfulness")!
        case .moving: return UIImage(named: "moving")!
        case .pets: return UIImage(named: "pets")!
        case .savings: return UIImage(named: "transaction")!
        case .shopping: return UIImage(named: "shopping")!
        case .skill: return UIImage(named: "school")!
        case .sleep: return UIImage(named: "sleep")!
        case .timeOff: return UIImage(named: "leisure")!
        case .travel: return UIImage(named: "plane")!
        case .wedding: return UIImage(named: "wedding")!
        case .workout: return UIImage(named: "workout")!
        case .notApplicable: return UIImage(named: "event")!
        }
    }
    
    var iconString: String {
        switch self {
        case .health: return "heart-filled"
        case .meal: return "food"
        case .work: return "work"
        case .school: return "school"
        case .social: return "nightlife"
        case .leisure: return "leisure"
        case .family: return "family"
        case .personal: return "personal"
        case .todo: return "todo"
        case .finances: return "money"
        case .spending: return "transaction"
        case .investments: return "money"
        case .uncategorized: return "event"
        case .bills: return "transaction"
        case .car: return "car"
        case .chores: return "todo"
        case .doctor: return "doctor"
        case .entertainment: return "nightlife"
        case .errand: return "todo"
        case .home: return "home"
        case .hygiene: return "hygiene"
        case .kids: return "kids"
        case .mindfulness: return "mindfulness"
        case .moving: return "moving"
        case .pets: return "pets"
        case .savings: return "transaction"
        case .shopping: return "shopping"
        case .skill: return "school"
        case .sleep: return "sleep"
        case .timeOff: return "leisure"
        case .travel: return "plane"
        case .wedding: return "wedding"
        case .workout: return "workout"
        case .notApplicable: return "event"
        }
    }
        
    // MARK: - Utility
    static func categorize(_ activity: Activity) -> ActivitySubcategory {
        let text = "\(activity.name?.lowercased() ?? "") \(activity.notes?.lowercased() ?? "")"
        let elements = text.split(separator: " ")
        
        for (category, keywords) in keywordsMap {
            if elements.contains(where: { keywords.contains(String($0)) }),
               let cat = ActivitySubcategory(rawValue: category) {
                return cat
            }
        }
        
        return .uncategorized
    }
    
    static func categorize(_ category: ActivityCategory) -> ActivitySubcategory {
        switch category {
        case .family:
            return .family
        case .finances:
            return .finances
        case .health:
            return .health
        case .leisure:
            return .leisure
        case .meal:
            return .meal
        case .personal:
            return .personal
        case .school:
            return .school
        case .social:
            return .social
        case .todo:
            return .todo
        case .work:
            return .work
        case .uncategorized:
            return .uncategorized
        case .notApplicable:
            return .notApplicable
        }
    }
    
    static func categorize(_ transaction: Transaction) -> ActivitySubcategory {
        if transaction.category == "Amusement" || transaction.category == "Arts" || transaction.category == "Alcohol & Bars" || transaction.category == "Coffee Shops" {
            return .social
        } else if transaction.category == "Fast Food" || transaction.category == "Restaurants" || transaction.category == "Food & Dining" {
            return .meal
        } else if transaction.category == "Dentist" || transaction.category == "Doctor" {
            return .doctor
        } else if transaction.category == "Hair" || transaction.category == "Spa & Massage" || transaction.category == "Personal Care" {
            return .personal
        } else if transaction.category == "Pet Grooming" || transaction.category == "Veterinary" {
            return .pets
        } else if transaction.category == "Groceries" {
            return .errand
        }
        return .uncategorized
    }
}
