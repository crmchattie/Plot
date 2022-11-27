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

enum GoalMetric: String, Codable, CaseIterable {
    case time = "Time"
    case income = "Income"
    case expenses = "Expenses"
    case events = "Events"
    case accounts = "Accounts"
    case workout = "Workout"
    case mindfulness = "Mindfulness"
    case sleep = "Sleep"
    case steps = "Steps"
    
    static var allValues: [String] {
        var array = [String]()
        GoalMetric.allCases.forEach { metric in
            array.append(metric.rawValue)
        }
        return array
    }
    
    var options: [GoalUnit] {
        switch self {
        case .time:
            return [.minutes, .hours, .days]
        case .income:
            return [.dollars]
        case .expenses:
            return [.dollars]
        case .events:
            return [.events]
        case .accounts:
            return [.accounts]
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

enum GoalUnit: String, Codable, CaseIterable {
    case minutes = "Minutes"
    case hours = "Hours"
    case days = "Days"
    case dollars = "Dollars"
    case events = "Events"
    case accounts = "Accounts"
    case steps = "Steps"
}
