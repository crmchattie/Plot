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
    
    var built: Bool {
        return metric != nil && targetNumber != nil
    }
    
    var category: ActivityCategory {
        switch self.metric {
        case .events:
            switch self.submetric {
            case .group:
                return .uncategorized
            case .category:
                return ActivityCategory(rawValue: self.submetric?.rawValue ?? "Uncategorized") ?? .uncategorized
            case .subcategory:
                return ActivityCategory.categorize(ActivitySubcategory(rawValue: self.submetric?.rawValue ?? "Uncategorized") ?? .uncategorized)
            case .some(.none):
                return .uncategorized
            case nil:
                return .uncategorized
            }
        case .tasks:
            switch self.submetric {
            case .group:
                return .uncategorized
            case .category:
                return ActivityCategory(rawValue: self.submetric?.rawValue ?? "Uncategorized") ?? .uncategorized
            case .subcategory:
                return ActivityCategory.categorize(ActivitySubcategory(rawValue: self.submetric?.rawValue ?? "Uncategorized") ?? .uncategorized)
            case .some(.none):
                return .uncategorized
            case nil:
                return .uncategorized
            }
        case .savings, .spending, .balances:
            return .finances
        case .workout, .mindfulness, .sleep, .steps, .flightsClimbed, .activeCalories:
            return .health
        case .none:
            return .uncategorized
        }
    }
    
    var subcategory: ActivitySubcategory {
        switch self.metric {
        case .events:
            switch self.submetric {
            case .group:
                return .uncategorized
            case .category:
                return ActivitySubcategory(rawValue: self.submetric?.rawValue ?? "Uncategorized") ?? .uncategorized
            case .subcategory:
                return ActivitySubcategory.categorize(ActivityCategory(rawValue: self.submetric?.rawValue ?? "Uncategorized") ?? .uncategorized)
            case .some(.none):
                return .uncategorized
            case nil:
                return .uncategorized
            }
        case .tasks:
            switch self.submetric {
            case .group:
                return .uncategorized
            case .category:
                return ActivitySubcategory(rawValue: self.submetric?.rawValue ?? "Uncategorized") ?? .uncategorized
            case .subcategory:
                return ActivitySubcategory.categorize(ActivityCategory(rawValue: self.submetric?.rawValue ?? "Uncategorized") ?? .uncategorized)
            case .some(.none):
                return .uncategorized
            case nil:
                return .uncategorized
            }
        case .savings:
            return .savings
        case .spending:
            return .spending
        case .balances:
            return .finances
        case .mindfulness:
            return .mindfulness
        case .sleep:
            return .sleep
        case .workout, .steps, .flightsClimbed, .activeCalories:
            return .workout
        case .none:
            return .uncategorized
        }
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
        case .savings:
            switch self.submetric {
            case .group:
                return nil
            case .category:
                return nil
            case .subcategory:
                return financialTransactionsCategoriesStaticWOUncategorizedIncome.sorted()
            case .some(.none):
                return nil
            case nil:
                return nil
            }
        case .spending:
            switch self.submetric {
            case .group:
                return financialTransactionsGroupsWExpenseStatic.sorted()
            case .category:
                return financialTransactionsTopLevelCategoriesStaticWOUncategorizedExpense.sorted()
            case .subcategory:
                return financialTransactionsCategoriesStaticWOUncategorizedExpense.sorted()
            case .some(.none):
                return nil
            case nil:
                return nil
            }
        case .balances:
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
        case .savings:
            switch submetric {
            case .group:
                return nil
            case .category:
                return nil
            case .subcategory:
                return financialTransactionsCategoriesStaticWOUncategorizedIncome.sorted()
            case .none:
                return nil
            }
        case .spending:
            switch submetric {
            case .group:
                return financialTransactionsGroupsWExpenseStatic.sorted()
            case .category:
                return financialTransactionsTopLevelCategoriesStaticWOUncategorizedExpense.sorted()
            case .subcategory:
                return financialTransactionsCategoriesStaticWOUncategorizedExpense.sorted()
            case .none:
                return nil
            }
        case .balances:
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
//    case time = "Time"
//    case tasks = "Completed Tasks"
//    case spending = "Spending"
//    case savings = "Savings"
//    case cash = "Cash"
//    case investments = "Investments"
//    case assets = "Assets"
//    case creditCardDebt = "Credit Card Debt"
//    case mortgage = "Mortgage"
//    case autoLoans = "Auto Loans"
//    case studentLoans = "Student Loans"
//    case liabilities = "Liabilities"
//    case workout = "Workouts"
//    case mindfulness = "Mindfulness"
//    case sleep = "Sleep"
//    case steps = "Steps"
//    case flightsClimbed = "Flights Climbed"
//    case activeCalories = "Active Calories"
    
    case events = "Events"
    case tasks = "Completed Tasks"
    case savings = "Savings"
    case spending = "Spending"
    case balances = "Balances"
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
    
    var allValuesSubmetrics: [String] {
        var array = [String]()
        self.submetrics.forEach { submetric in
            array.append(submetric.rawValue)
        }
        return array
    }
    
    var allValuesUnits: [String] {
        var array = [String]()
        self.units.forEach { unit in
            array.append(unit.rawValue)
        }
        return array
    }
    
    var submetrics: [GoalSubMetric] {
        switch self {
        case .events:
            return [.none, .category, .subcategory]
        case .tasks:
            return [.none, .category, .subcategory]
        case .savings:
            return [.none, .subcategory]
        case .spending:
            return [.none, .group, .category, .subcategory]
        case .balances:
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
        case .savings:
            return [.amount, .percent]
        case .spending:
            return [.amount]
        case .balances:
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

enum FormatterType: String {
    case number = "Number"
    case date = "Date"
}
