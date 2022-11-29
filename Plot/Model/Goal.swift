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
    var targetNumber: Double?
    var currentNumber: Double?
    
    init(name: String?, metric: GoalMetric?, submetric: GoalSubMetric?, option: String?, unit: GoalUnit?, targetNumber: Double?, currentNumber: Double?) {
        self.name = name
        self.metric = metric
        self.submetric = submetric
        self.option = option
        self.unit = unit
        self.targetNumber = targetNumber
        self.currentNumber = currentNumber
    }
    
    init(goal: Goal) {
        self.name = goal.name
        self.metric = goal.metric
        self.submetric = goal.submetric
        self.option = goal.option
        self.unit = goal.unit
        self.targetNumber = goal.targetNumber
        self.currentNumber = goal.currentNumber
    }
    
    var build: Bool {
        return metric != nil && targetNumber != nil
    }
    
    var description: String? {
        let numberFormatter = NumberFormatter()
        numberFormatter.currencyCode = "USD"
        numberFormatter.maximumFractionDigits = 0
        var description = "Goal is Complete when"
        if let unit = unit, let metric = metric, let submetric = submetric, let option = option, let targetNumber = targetNumber as? NSNumber {
            switch unit {
            case .calories:
                numberFormatter.numberStyle = .decimal
            case .count:
                numberFormatter.numberStyle = .decimal
            case .amount:
                numberFormatter.numberStyle = .currency
            case .percent:
                numberFormatter.numberStyle = .percent
            case .multiple:
                numberFormatter.numberStyle = .decimal
            case .minutes:
                numberFormatter.numberStyle = .decimal
            case .hours:
                numberFormatter.numberStyle = .decimal
                numberFormatter.maximumFractionDigits = 1
            case .days:
                numberFormatter.numberStyle = .decimal
                numberFormatter.maximumFractionDigits = 1
            case .level:
                numberFormatter.numberStyle = .decimal
            }
            
            description += " " + unit.rawValue + " of"

            if let string = numberFormatter.string(from: targetNumber), metric == .tasks || metric == .events {
                description += " " + metric.rawValue + " in the " + option + " " + submetric.rawValue + " hits " + string
                return description
            } else if let string = numberFormatter.string(from: targetNumber) {
                description += " " + option + " hits " + string
                return description
            }
        } else if let unit = unit, let metric = metric, let targetNumber = targetNumber as? NSNumber {
            switch unit {
            case .calories:
                numberFormatter.numberStyle = .decimal
            case .count:
                numberFormatter.numberStyle = .decimal
            case .amount:
                numberFormatter.numberStyle = .currency
            case .percent:
                numberFormatter.numberStyle = .percent
            case .multiple:
                numberFormatter.numberStyle = .decimal
            case .minutes:
                numberFormatter.numberStyle = .decimal
            case .hours:
                numberFormatter.numberStyle = .decimal
                numberFormatter.maximumFractionDigits = 1
            case .days:
                numberFormatter.numberStyle = .decimal
                numberFormatter.maximumFractionDigits = 1
            case .level:
                numberFormatter.numberStyle = .decimal
            }
            
            if let string = numberFormatter.string(from: targetNumber), metric == .activeCalories || metric == .steps || metric == .flightsClimbed {
                description += " " + metric.rawValue + " hits " + string
                return description
            } else if let string = numberFormatter.string(from: targetNumber) {
                description += " " + unit.rawValue + " of"
                description += " " + metric.rawValue + " hits " + string
                return description
            }
        }
        
        return nil
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
            case .some(.none):
                return nil
            case nil:
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
            case .some(.none):
                return nil
            case nil:
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
            case .some(.none):
                return nil
            case nil:
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
            case .some(.none):
                return nil
            case nil:
                return nil
            }
        case .workout, .mindfulness, .sleep, .steps, .flightsClimbed, .activeCalories:
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
            case .none:
                return nil
            }
        case .tasks:
            switch submetric {
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
            switch submetric {
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
            switch submetric {
            case .group:
                return BalanceSheetType.allValues
            case .category:
                return MXAccountType.allValues
            case .subcategory:
                return MXAccountSubType.allValues
            case .none:
                return nil
            }
        case .workout, .mindfulness, .sleep, .steps, .flightsClimbed, .activeCalories:
            return nil
        case .none:
            return nil
        }
    }
}

enum GoalMetric: String, Codable, CaseIterable {
    case events = "Events"
    case tasks = "Completed Tasks"
    case transactions = "Transactions"
    case accounts = "Accounts"
    case workout = "Workouts"
    case mindfulness = "Mindfulness"
    case sleep = "Sleep"
    case steps = "Steps"
    case flightsClimbed = "Flights Climbed"
    case activeCalories = "Active Calories"
//    case weight = "Weight"
    
    static var allValues: [String] {
        var array = [String]()
        GoalMetric.allCases.forEach { metric in
            array.append(metric.rawValue)
        }
        return array.sorted()
    }
    
    var submetrics: [GoalSubMetric] {
        switch self {
        case .events:
            return [.none, .category, .subcategory]
        case .tasks:
            return [.none, .category, .subcategory]
        case .transactions:
            return [.none, .group, .category, .subcategory]
        case .accounts:
            return [.none, .group, .category, .subcategory]
        case .workout, .mindfulness, .sleep, .steps, .flightsClimbed, .activeCalories:
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
            return [.amount, .percent]
        case .accounts:
            return [.amount, .percent]
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
        }
    }
}

enum GoalSubMetric: String, Codable, CaseIterable {
    case none = "None"
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
    case level = "Level"
}
