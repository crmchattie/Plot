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
    var submetric: GoalSubMetric?
    var option: String?
    var unit: GoalUnit?
    var number: Double?
    
    init(name: String?, metric: GoalMetric?, submetric: GoalSubMetric?, option: String?, unit: GoalUnit?, number: Double?) {
        self.name = name
        self.metric = metric
        self.submetric = submetric
        self.option = option
        self.unit = unit
        self.number = number
    }
    
    func options() -> [String]? {
        switch self.metric {
        case .events:
            switch self.submetric {
            case .group:
                return nil
            case .category:
                return ActivityCategory.allValues
            case .subcategory:
                return ActivitySubcategory.allValues
            case .none:
                return nil
            }
        case .tasks:
            switch self.submetric {
            case .group:
                return nil
            case .category:
                return ActivityCategory.allValues
            case .subcategory:
                return ActivitySubcategory.allValues
            case .none:
                return nil
            }
        case .transactions:
            switch self.submetric {
            case .group:
                return financialTransactionsGroupsWExpenseStatic
            case .category:
                return financialTransactionsTopLevelCategoriesStaticWOUncategorized
            case .subcategory:
                return financialTransactionsCategoriesStaticWOUncategorized
            case .none:
                return nil
            }
        case .accounts:
            switch self.submetric {
            case .group:
                return BalanceSheetType.allValues
            case .category:
                return MXAccountType.allValues
            case .subcategory:
                return MXAccountSubType.allValues
            case .none:
                return nil
            }
        case .workout, .mindfulness, .sleep, .steps, .flightsClimbed, .activeCalories, .weight:
            return nil
        case .none:
            return nil
        }
    }
    
    func options(submetric: GoalSubMetric) -> [String]? {
        switch self.metric {
        case .events:
            switch submetric {
            case .group:
                return nil
            case .category:
                return ActivityCategory.allValues
            case .subcategory:
                return ActivitySubcategory.allValues
            }
        case .tasks:
            switch submetric {
            case .group:
                return nil
            case .category:
                return ActivityCategory.allValues
            case .subcategory:
                return ActivitySubcategory.allValues
            }
        case .transactions:
            switch submetric {
            case .group:
                return financialTransactionsGroupsWExpenseStatic
            case .category:
                return financialTransactionsTopLevelCategoriesStaticWOUncategorized
            case .subcategory:
                return financialTransactionsCategoriesStaticWOUncategorized
            }
        case .accounts:
            switch submetric {
            case .group:
                return BalanceSheetType.allValues
            case .category:
                return MXAccountType.allValues
            case .subcategory:
                return MXAccountSubType.allValues
            }
        case .workout, .mindfulness, .sleep, .steps, .flightsClimbed, .activeCalories, .weight:
            return nil
        case .none:
            return nil
        }
    }
}

enum GoalMetric: String, Codable, CaseIterable {
    case events = "Events"
    case tasks = "Tasks"
    case transactions = "Transactions"
    case accounts = "Accounts"
    case workout = "Workouts"
    case mindfulness = "Mindfulness"
    case sleep = "Sleep"
    case steps = "Steps"
    case flightsClimbed = "Flights Climbed"
    case activeCalories = "Active Calories"
    case weight = "Weight"
    
    static var allValues: [String] {
        var array = [String]()
        GoalMetric.allCases.forEach { metric in
            array.append(metric.rawValue)
        }
        return array
    }
        
    var submetrics: [GoalSubMetric] {
        switch self {
        case .events:
            return [.category, .subcategory]
        case .tasks:
            return [.category, .subcategory]
        case .transactions:
            return [.group, .category, .subcategory]
        case .accounts:
            return [.group, .category, .subcategory]
        case .workout, .mindfulness, .sleep, .steps, .flightsClimbed, .activeCalories, .weight:
            return []
        }
    }
    
    var units: [GoalUnit] {
        switch self {
        case .events:
            return [.count, .minutes, .hours, .days]
        case .tasks:
            return [.count]
        case .transactions:
            return [.amount, .percent, .multiple]
        case .accounts:
            return [.amount, .percent, .multiple]
        case .workout:
            return [.count, .calories, .minutes]
        case .mindfulness:
            return [.count, .minutes]
        case .sleep:
            return [.hours]
        case .steps:
            return [.count]
        case .flightsClimbed:
            return [.count]
        case .activeCalories:
            return [.calories]
        case .weight:
            return [.amount]
        }
    }
}

enum GoalSubMetric: String, Codable, CaseIterable {
    case group = "Group"
    case category = "Category"
    case subcategory = "Subcategory"
//    case account = "Account"
//    case workout = "Workout"
//    case mindfulness = "Mindfulness"
//    case sleep = "Sleep"
//    case steps = "Steps"
//    case flightsClimbed = "Flights Climbed"
//    case activeCalories = "Active Calories"
}

enum GoalUnit: String, Codable, CaseIterable {
    case calories = "Calories"
    case count = "Count"
    case amount = "Amount"
    case percent = "Percent"
    case multiple = "Multiple"
    case minutes = "Minutes"
    case hours = "Hours"
    case days = "Days"
}
