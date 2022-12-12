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
                           "Finances": ["bill", "payment"]
]

enum ActivityCategory: String, Codable, CaseIterable {
    case family = "Family"
    case finances = "Finances"
    case health = "Health"
    case leisure = "Leisure"
    case meal = "Meal"
    case personal = "Personal"
    case school = "School"
    case social = "Social"
    case todo = "To-do"
    case work = "Work"
    case uncategorized = "Uncategorized"
    /// Same as uncategorized by not included in the analytics
    case notApplicable = "Not Applicable"
    
    static var allValues: [String] {
        var array = [String]()
        ActivityCategory.allCases.forEach { category in
            if category != .uncategorized && category != .notApplicable {
                array.append(category.rawValue)
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
        case .uncategorized: return UIImage(named: "event")!
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
        case .uncategorized: return "event"
        case .notApplicable: return "event"
        }
    }
    
    var color: UIColor {
        switch self {
        case .health: return ChartColors.palette()[1]
        case .meal: return ChartColors.palette()[2]
        case .work: return ChartColors.palette()[3]
        case .school: return ChartColors.palette()[4]
        case .social: return ChartColors.palette()[5]
        case .leisure: return ChartColors.palette()[6]
        case .family: return ChartColors.palette()[7]
        case .personal: return ChartColors.palette()[8]
        case .todo: return ChartColors.palette()[1]
        case .finances: return ChartColors.palette()[5]
        case .uncategorized: return ChartColors.palette()[0]
        case .notApplicable: return ChartColors.palette()[1]
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
    
    static func categorize(_ subcategory: ActivitySubcategory) -> ActivityCategory {
        switch subcategory {
        case .bills:
            return .finances
        case .car:
            return .todo
        case .chores:
            return .todo
        case .doctor:
            return .health
        case .entertainment:
            return .leisure
        case .errand:
            return .todo
        case .family:
            return .family
        case .finances:
            return .finances
        case .health:
            return .health
        case .home:
            return .todo
        case .hygiene:
            return .health
        case .investments:
            return .finances
        case .kids:
            return .family
        case .leisure:
            return .leisure
        case .meal:
            return .meal
        case .mindfulness:
            return .health
        case .moving:
            return .todo
        case .personal:
            return .personal
        case .pets:
            return .family
        case .savings:
            return .finances
        case .school:
            return .school
        case .shopping:
            return .leisure
        case .skill:
            return .personal
        case .sleep:
            return .health
        case .social:
            return .social
        case .spending:
            return .finances
        case .timeOff:
            return .leisure
        case .todo:
            return .todo
        case .travel:
            return .leisure
        case .wedding:
            return .social
        case .work:
            return .work
        case .workout:
            return .health
        case .uncategorized:
            return .uncategorized
        case .notApplicable:
            return .notApplicable
        }
    }
    
    static func categorize(_ transaction: Transaction) -> ActivityCategory {
        if transaction.category == "Amusement" || transaction.category == "Arts" || transaction.category == "Alcohol & Bars" || transaction.category == "Coffee Shops" {
            return .social
        } else if transaction.category == "Fast Food" || transaction.category == "Restaurants" || transaction.category == "Food & Dining" {
            return .meal
        } else if transaction.category == "Dentist" || transaction.category == "Doctor" {
            return .health
        } else if transaction.category == "Hair" || transaction.category == "Spa & Massage" || transaction.category == "Personal Care" {
            return .personal
        } else if transaction.category == "Pet Grooming" || transaction.category == "Veterinary" {
            return .family
        } else if transaction.category == "Groceries" {
            return .todo
        }
        
        return .uncategorized
    }
}
