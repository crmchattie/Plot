//
//  HealthMetric.swift
//  Plot
//
//  Created by Hafiz Usama on 2020-09-13.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import Foundation

struct HealthMetric: Equatable {
    let type: HealthMetricType
    let total: Int
    let date: Date
    var unit: String
    var average: Int?
    init(type: HealthMetricType, total: Int, date: Date, unit: String) {
        self.type = type
        self.total = total
        self.date = date
        self.unit = unit
    }
    
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.type == rhs.type && lhs.total == rhs.total && lhs.date == rhs.date && lhs.unit == rhs.unit && lhs.average == rhs.average
    }
}

enum HealthMetricType: String {
    case steps
    case nutrition
    case exercise
    case heartRate
    case weight
}
