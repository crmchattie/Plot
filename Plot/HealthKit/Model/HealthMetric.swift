//
//  HealthMetric.swift
//  Plot
//
//  Created by Hafiz Usama on 2020-09-13.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import Foundation
import HealthKit

struct HealthMetric: Equatable, Hashable {
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

enum HealthMetricType: Hashable {
    case steps
    case nutrition(String)
    case workout
    case heartRate
    case weight
    case sleep
    case mindfulness
    case activeEnergy
    case workoutMinutes
    case flightsClimbed
    
    var name: String {
        get {
            switch self {
            case .steps:
                return "Steps"
            case .nutrition(let value):
                return value
            case .workout:
                return "Workout"
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
            case .workoutMinutes:
                return "Workout Minutes"
            case .flightsClimbed:
                return "Flights Climbed"
            }
        }
    }
    
    var rank: Int {
        get {
            switch self {
            case .steps:
                return 2
            case .nutrition:
                return 7
            case .workout:
                return 5
            case .heartRate:
                return 9
            case .weight:
                return 1
            case .mindfulness:
                return 3
            case .sleep:
                return 4
            case .workoutMinutes:
                return 6
            case .activeEnergy:
                return 7
            case .flightsClimbed:
                return 8
            }
        }
    }
}

extension HealthMetric {
    func grabSegment() -> Int {
        let anchorDate = Date().localTime
        if NSCalendar.current.isDateInToday(self.date) {
            return 0
        } else if self.date.isBetween(anchorDate, and: anchorDate.weekBefore) {
            return 1
        } else if self.date.isBetween(anchorDate, and: anchorDate.monthBefore) {
            return 2
        } else {
            return 3
        }
    }
}

enum HealthMetricCategory: String {
    case general
    case workouts
    case nutrition
    case workoutsList
    case mindfulnessList
    
    
    var rank: Int {
        get {
            switch self {
            case .general:
                return 1
            case .workouts:
                return 2
            case .nutrition:
                return 3
            case .workoutsList:
                return 4
            case .mindfulnessList:
                return 5
            }
        }
    }
    
    var name: String {
        get {
            switch self {
            case .general:
                return "General Summary"
            case .workouts:
                return "Workout Summary"
            case .nutrition:
                return "Nutrition Summary"
            case .workoutsList:
                return "Recent Workouts"
            case .mindfulnessList:
                return "Recent Mindfulness Sessions"
            }
        }
    }
}
