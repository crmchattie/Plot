//
//  HealthMetric.swift
//  Plot
//
//  Created by Hafiz Usama on 2020-09-13.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import Foundation
import HealthKit

struct HealthMetric: Equatable {
    let type: HealthMetricType
    let total: Double
    let date: Date
    var unit: String
    var rank: Int
    var average: Double?
    var hkWorkout: HKWorkout?
    init(type: HealthMetricType, total: Double, date: Date, unit: String, rank: Int) {
        self.type = type
        self.total = total
        self.date = date
        self.unit = unit
        self.rank = rank
    }
    
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.type == rhs.type && lhs.total == rhs.total && lhs.date == rhs.date && lhs.unit == rhs.unit && lhs.average == rhs.average
    }
}

enum HealthMetricType {
    case steps
    case nutrition
    case workout
    case heartRate
    case weight
    
    var name: String {
        get {
            switch self {
            case .steps:
                return "Steps"
            case .nutrition:
                return "Nutrition"
            case .workout:
                return "Exercise"
            case .heartRate:
                return "Heart Rate"
            case .weight:
                return "Weight"
            }
        }
    }
    
    var rank: Int {
        get {
            switch self {
            case .steps:
                return 3
            case .nutrition:
                return 4
            case .workout:
                return 5
            case .heartRate:
                return 2
            case .weight:
                return 1
            }
        }
    }
}