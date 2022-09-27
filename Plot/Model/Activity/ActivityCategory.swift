//
//  ActivityCategory.swift
//  Plot
//
//  Created by Botond Magyarosi on 17.03.2021.
//  Copyright © 2021 Immature Creations. All rights reserved.
//

import Foundation
import UIKit

let userActivityCategoriesEntity = "user-activities-categories"

private let keywordsMap = ["Health": ["fitness", "workout", "run", "training", "cycling", "hiit", "exercise", "mindfulness", "meditation", "dr", "doctor", "therapy", "appointment"],
                           "To-do": ["groceries", "to-dos", "tasks", "errand", "chore"],
                           "Work": ["meeting", "assignment", "project", "standup", "work"],
                           "School": ["class", "homework", "test"],
                           "Social": ["party", "birthday", "wedding", "drinks", "date"],
                           "Family": ["family", "kids"],
                           "Personal": ["consultation", "haircut", "read", "journal"],
                           "Meal": ["dinner", "lunch", "meal", "breakfast", "reservation", "brunch"],
                           "Leisure": ["vacation", "shopping", "concert", "sporting event", "museum", "movies"],
                           "Finances": ["vacation", "shopping"]
]

enum ActivityCategory: String, Codable, CaseIterable {
    case health = "Health"
    case meal = "Meal"
    case work = "Work"
    case school = "School"
    case social = "Social"
    case leisure = "Leisure"
    case family = "Family"
    case personal = "Personal"
    case todo = "To-do"
    case finances = "Finances"
    case uncategorized = "Uncategorized"
    /// Same as uncategorized by not included in the analytics
    
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
        }
    }
    
    // MARK: - Utility
    static func categorize(_ activity: Activity) -> ActivityCategory {
        let text = "\(activity.name?.lowercased() ?? "") \(activity.notes?.lowercased() ?? "") \(activity.activityDescription?.lowercased() ?? "")"
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
