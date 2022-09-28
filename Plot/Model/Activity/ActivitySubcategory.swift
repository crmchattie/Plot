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
                           "Social": ["party", "birthday"],
                           "Family": ["family"],
                           "Personal": ["appointment", "consultation", "therapy", "haircut", "dr", "doctor"],
                           "Meal": ["dinner", "lunch", "meal", "breakfast", "reservation"],
                           "Leisure": ["trip", "vacation"]
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
    case todo = "To-do"
    case travel = "Travel"
    case wedding = "Wedding"
    case work = "Work"
    case workout = "Workout"
    case uncategorized = "Uncategorized"
    /// Same as uncategorized but not included in the analytics
    case notApplicable = "Not Applicable"
    
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
        case .travel: return UIImage(named: "plane")!
        case .wedding: return UIImage(named: "wedding")!
        case .workout: return UIImage(named: "workout")!
        case .notApplicable: return UIImage(named: "event")!
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
}
