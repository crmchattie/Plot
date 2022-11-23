//
//  Goal.swift
//  Plot
//
//  Created by Cory McHattie on 11/22/22.
//  Copyright © 2022 Immature Creations. All rights reserved.
//

struct Goal: Codable, Equatable, Hashable {
    var name: String?
    var metric: GoalMetric?
    var unit: GoalUnit?
    var number: Double?
    
    init(name: String?, metric: GoalMetric, unit: GoalUnit, number: Double?) {
        self.name = name
        self.metric = metric
        self.unit = unit
        self.number = number
    }
}

enum GoalMetric: Codable, CaseIterable {
    case time
    case income
    case expenses
    case event
    case financialAccount
    case workout
    case mindfulness
    case sleep
    case steps
    
    var options: [GoalUnit] {
        switch self {
        case .time:
            return [.minutes, .hours, .days]
        case .income:
            return [.dollars]
        case .expenses:
            return [.dollars]
        case .event:
            return [.event]
        case .financialAccount:
            return [.financialAccount]
        case .workout:
            return [.minutes]
        case .mindfulness:
            return [.minutes]
        case .sleep:
            return [.hours]
        case .steps:
            return [.steps]
        }
    }
}

enum GoalUnit: Codable, CaseIterable {
    case minutes
    case hours
    case days
    case dollars
    case event
    case financialAccount
    case steps
}
