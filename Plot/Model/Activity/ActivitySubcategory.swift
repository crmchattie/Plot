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
                           "To-do": ["meeting", "assignment", "project", "standup", "work", "groceries", "to-dos", "tasks"],
                           "Social": ["party", "birthday"],
                           "Family": ["family"],
                           "Personal": ["appointment", "consultation", "therapy", "haircut", "dr", "doctor"],
                           "Meal": ["dinner", "lunch", "meal", "breakfast", "reservation"],
                           "Leisure": ["trip", "vacation"]
]

enum ActivitySubcategory: String, CaseIterable {
    case sleep = "Sleep"
    case meal = "Meal"
    case work = "Work"
    case social = "Social"
    case leisure = "Leisure"
    case workout = "Workout"
    case family = "Family"
    case personal = "Personal"
    case uncategorized = "Uncategorized"
    case todo = "To-do"
    /// Same as uncategorized by not included in the analytics
    case notApplicable = "Not Applicable"
    
    var icon: UIImage {
        switch self {
        case .sleep: return UIImage(named: "sleep")!
        case .meal: return UIImage(named: "food")!
        case .work: return UIImage(named: "work")!
        case .social: return UIImage(named: "nightlife")!
        case .leisure: return UIImage(named: "leisure")!
        case .workout: return UIImage(named: "workout")!
        case .family: return UIImage(named: "family")!
        case .personal: return UIImage(named: "personal")!
        case .todo: return UIImage(named: "todo")!
        case .uncategorized,
             .notApplicable:
            return UIImage(named: "activity")!
        }
    }
    
    // MARK: - Utility
    static func categorize(_ activity: Activity) -> ActivityCategory {
        let text = "\(activity.name?.lowercased() ?? "") \(activity.notes?.lowercased() ?? "")"
        let elements = text.split(separator: " ")
        
        for (category, keywords) in keywordsMap {
            if elements.contains(where: { keywords.contains(String($0)) }),
               let cat = ActivityCategory(rawValue: category) {
                return cat
            }
        }
        
        return .uncategorized
    }
}
