//
//  HealthContainer.swift
//  Plot
//
//  Created by Cory McHattie on 7/5/22.
//  Copyright © 2022 Immature Creations. All rights reserved.
//

import Foundation

struct HealthContainer: Codable, Equatable {
    
    var meal: Meal?
    var workout: Workout?
    var mindfulness: Mindfulness?

    var ID: String {
        return meal?.id ?? workout?.id ?? mindfulness?.id  ?? ""
    }
    
    var name: String {
        return meal?.name ?? workout?.name ?? mindfulness?.name  ?? ""
    }
    
    var lastModifiedDate: Date {
        return meal?.lastModifiedDate ?? workout?.lastModifiedDate ?? mindfulness?.lastModifiedDate ?? Date.distantPast
    }
    
    var createdDate: Date {
        return meal?.createdDate ?? workout?.createdDate ?? mindfulness?.createdDate ?? Date.distantPast
    }
    
    var badge: Int {
        return meal?.badge ?? workout?.badge ?? mindfulness?.badge ?? 0
    }
    
    var muted: Bool {
        return meal?.muted ?? workout?.muted ?? mindfulness?.muted ?? false
    }
    
    var pinned: Bool {
        return meal?.pinned ?? workout?.pinned ?? mindfulness?.pinned ?? false
    }
    
    var type: String {
        if meal != nil {
            return "meal"
        } else if workout != nil {
            return "workout"
        } else if mindfulness != nil {
            return "mindfulness"
        }else {
            return "none"
        }
    }

}

func ==(lhs: HealthContainer, rhs: HealthContainer) -> Bool {
    return lhs.meal == rhs.meal && lhs.workout == rhs.workout && lhs.mindfulness == rhs.mindfulness
}
