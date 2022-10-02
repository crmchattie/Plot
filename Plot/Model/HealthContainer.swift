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
    
    var hkSampleID: String {
        return workout?.hkSampleID ?? mindfulness?.hkSampleID  ?? ""
    }
    
    var name: String {
        return meal?.name ?? workout?.name ?? mindfulness?.name  ?? ""
    }
    
    var date: Date {
        return meal?.startDateTime ?? workout?.startDateTime ?? mindfulness?.startDateTime ?? Date.distantPast
    }
    
    var total: Double {
        return meal?.nutrition?.calories ?? workout?.totalEnergyBurned ?? mindfulness?.length ?? 0
    }
    
    var unitName: String {
        if meal != nil {
            return "calories"
        } else if workout != nil {
            return "calories"
        } else if mindfulness != nil {
            return "minutes"
        } else {
            return "none"
        }
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
    
    var type: ContainerType {
        if meal != nil {
            return .meal
        } else if workout != nil {
            return .workout
        } else {
            return .mindfulness
        }
    }

}

func ==(lhs: HealthContainer, rhs: HealthContainer) -> Bool {
    return lhs.meal == rhs.meal && lhs.workout == rhs.workout && lhs.mindfulness == rhs.mindfulness
}
