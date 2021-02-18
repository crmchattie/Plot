//
//  ActivityCategorySelector.swift
//  Plot
//
//  Created by Hafiz Usama on 2020-12-06.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import Foundation

class ActivityCategorySelector {
    static var keywordsMap = ["Exercise": ["fitness", "workout", "run", "training", "cycling", "hiit", "exercise"],
                       "Work": ["meeting", "assignment", "project", "standup", "work"],
                       "Social": ["party", "birthday"],
                       "Family": ["family"],
                       "Personal": ["appointment", "consultation", "therapy", "haircut"],
                       "Meal": ["dinner", "lunch", "meal", "breakfast"],
                       "Leisure": ["trip", "vacation"]
    ]
    
    class func selectCategory(for activity: Activity) -> String {
        let text = "\(activity.name?.lowercased() ?? "") \(activity.notes?.lowercased() ?? "")"
        let elements = text.split(separator: " ")
        
        for (category, keywords) in keywordsMap {
            if elements.contains(where: { substring -> Bool in
                return keywords.contains(String(substring))
            }) {
                return category
            }
        }
        
        return "Not Applicable"
    }
}
