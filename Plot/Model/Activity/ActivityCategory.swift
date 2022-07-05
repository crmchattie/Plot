//
//  ActivityCategory.swift
//  Plot
//
//  Created by Botond Magyarosi on 17.03.2021.
//  Copyright © 2021 Immature Creations. All rights reserved.
//

import Foundation
import UIKit

private let keywordsMap = ["Exercise": ["fitness", "workout", "run", "training", "cycling", "hiit", "exercise"],
                           "Work": ["meeting", "assignment", "project", "standup", "work"],
                           "Social": ["party", "birthday"],
                           "Family": ["family"],
                           "Personal": ["appointment", "consultation", "therapy", "haircut"],
                           "Meal": ["dinner", "lunch", "meal", "breakfast"],
                           "Leisure": ["trip", "vacation"]
]

enum ActivityCategory: String, CaseIterable {
    case sleep = "Sleep"
    case meal = "Meal"
    case work = "Work"
    case social = "Social"
    case leisure = "Leisure"
    case excercise = "Exercise"
    case family = "Family"
    case personal = "Personal"
    case uncategorized = "Uncategorized"
    /// Same as uncategorized by not included in the analytics
    case notApplicable = "Not Applicable"
    
    var icon: UIImage {
        switch self {
        case .sleep: return UIImage(named: "sleep")!
        case .meal: return UIImage(named: "food")!
        case .work: return UIImage(named: "work")!
        case .social: return UIImage(named: "nightlife")!
        case .leisure: return UIImage(named: "leisure")!
        case .excercise: return UIImage(named: "workout")!
        case .family: return UIImage(named: "family")!
        case .personal: return UIImage(named: "personal")!
        case .uncategorized,
             .notApplicable:
            return UIImage(named: "activity")!
        }
    }
    
    var color: UIColor {
        switch self {
        case .sleep: return ChartColors.palette()[0]
        case .meal: return ChartColors.palette()[1]
        case .work: return ChartColors.palette()[2]
        case .social: return ChartColors.palette()[4]
        case .leisure: return ChartColors.palette()[6]
        case .excercise: return ChartColors.palette()[7]
        case .family: return ChartColors.palette()[8]
        case .personal: return ChartColors.palette()[9]
        case .uncategorized,
             .notApplicable:
            return UIColor.systemBlue
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
