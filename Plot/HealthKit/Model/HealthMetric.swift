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
    var unitName: String
    var rank: Int
    var average: Double?
    var hkSample: HKSample?
    var unit: HKUnit?
    var quantityTypeIdentifier: HKQuantityTypeIdentifier?
    init(type: HealthMetricType, total: Double, date: Date, unitName: String, rank: Int) {
        self.type = type
        self.total = total
        self.date = date
        self.unitName = unitName
        self.rank = rank
    }
    
    static func == (lhs: Self, rhs: Self) -> Bool {
        var type = false
        switch (lhs.type, rhs.type) {
        case let (.nutrition(v0), .nutrition(v1)):
            type = v0 == v1
        default:
            type = false
        }
        
        return type && lhs.total == rhs.total && lhs.date == rhs.date && lhs.unit == rhs.unit && lhs.average == rhs.average
    }
}

enum HealthMetricType {
    case steps
    case nutrition(String)
    case workout
    case heartRate
    case weight
    case sleep
    case mindfulness
    case activeEnergy
    
    var name: String {
        get {
            switch self {
            case .steps:
                return "Steps"
            case .nutrition(let value):
                return value
            case .workout:
                return "Exercise"
            case .heartRate:
                return "Heart Rate"
            case .weight:
                return "Weight"
            case .sleep:
                return "Sleep"
            case .mindfulness:
                return "Mindfulness"
            case .activeEnergy:
                return "Active Energy"
            }
        }
    }
    
    var rank: Int {
        get {
            switch self {
            case .steps:
                return 3
            case .nutrition:
                return 7
            case .workout:
                return 6
            case .heartRate:
                return 2
            case .weight:
                return 1
            case .mindfulness:
                return 4
            case .sleep:
                return 5
            case .activeEnergy:
                return 8
            }
        }
    }
}

enum HealthMetricCategory: String {
    case general
    case workouts
    case nutrition
    
    var rank: Int {
        get {
            switch self {
            case .general:
                return 1
            case .workouts:
                return 2
            case .nutrition:
                return 3
            }
        }
    }
}
