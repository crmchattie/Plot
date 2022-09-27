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

enum ActivitySubcategory: String, CaseIterable {
    case bills = "Bills"
    case car = "Car"
    case chores = "Chores"
    case doctor = "Doctor"
    case entertainment = "Entertainment"
    case errand = "Errand"
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
    case shopping = "Shopping"
    case skill = "Skill"
    case sleep = "Sleep"
    case social = "Social"
    case travel = "Travel"
    case wedding = "Wedding"
    case work = "Work"
    case workout = "Workout"
    case uncategorized = "Uncategorized"
    /// Same as uncategorized but not included in the analytics
    case notApplicable = "Not Applicable"
        
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
