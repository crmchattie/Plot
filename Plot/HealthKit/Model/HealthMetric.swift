//
//  HealthMetric.swift
//  Plot
//
//  Created by Hafiz Usama on 2020-09-13.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import Foundation

struct HealthMetric {
    let type: HealthMetricType
    let total: Int
    let date: Date
    var unit: String?
    var average: Int?
    init(type: HealthMetricType, total: Int, date: Date) {
        self.type = type
        self.total = total
        self.date = date
    }
}

enum HealthMetricType {
    case steps
    case nutrition
    case exercise
    case heartRate
    case weight
}
