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
    var option: [String]?
    var unit: GoalUnit?
    var targetNumber: Double?
    var currentNumber: Double?
    var activityID: String?
    
    init(name: String?, metric: GoalMetric?, submetric: GoalSubMetric?, option: [String]?, unit: GoalUnit?, targetNumber: Double?, currentNumber: Double?) {
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
        self.activityID = goal.activityID
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
                return ActivityCategory(rawValue: self.option?.first ?? "Uncategorized") ?? .uncategorized
            case .subcategory:
                return ActivityCategory.categorize(ActivitySubcategory(rawValue: self.option?.first ?? "Uncategorized") ?? .uncategorized)
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
                return ActivityCategory(rawValue: self.option?.first ?? "Uncategorized") ?? .uncategorized
            case .subcategory:
                return ActivityCategory.categorize(ActivitySubcategory(rawValue: self.option?.first ?? "Uncategorized") ?? .uncategorized)
            case .some(.none):
                return .uncategorized
            case nil:
                return .uncategorized
            }
        case .financialTransactions, .financialAccounts:
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
                return ActivitySubcategory.categorize(ActivityCategory(rawValue: self.option?.first ?? "Uncategorized") ?? .uncategorized)
            case .subcategory:
                return ActivitySubcategory(rawValue: self.option?.first ?? "Uncategorized") ?? .uncategorized
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
                return ActivitySubcategory.categorize(ActivityCategory(rawValue: self.option?.first ?? "Uncategorized") ?? .uncategorized)
            case .subcategory:
                return ActivitySubcategory(rawValue: self.option?.first ?? "Uncategorized") ?? .uncategorized
            case .some(.none):
                return .uncategorized
            case nil:
                return .uncategorized
            }
        case .financialTransactions:
            return .finances
        case .financialAccounts:
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
        var description = "Goal is complete when"
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
            
            description += " " + unit.rawValue.lowercased() + " of "

            if let string = numberFormatter.string(from: targetNumber), metric == .tasks || metric == .events {
                description += metric.rawValue.lowercased() + " in the "
                if option.count > 0 {
                    for index in 0...option.count - 1 {
                        if index == option.count - 1 {
                            description += option[index].lowercased()
                        } else {
                            if option.count == 2 || index == option.count - 2 {
                                description += option[index].lowercased() + " and "
                            } else {
                                description += option[index].lowercased() + ", "
                            }
                        }
                    }
                    if option.count > 1 {
                        description += " " + submetric.pluralName.lowercased() + " hits " + string
                    } else {
                        description += " " + submetric.singlularName.lowercased() + " hits " + string
                    }
                } else if submetric != .none {
                    return nil
                }
                return description
            } else if let string = numberFormatter.string(from: targetNumber) {
                if option.count > 0 {
                    for index in 0...option.count - 1 {
                        if index == option.count - 1 {
                            description += option[index].lowercased()
                        } else {
                            if option.count == 2 || index == option.count - 2 {
                                description += option[index].lowercased() + " and "
                            } else {
                                description += option[index].lowercased() + ", "
                            }
                        }
                    }
                } else if submetric != .none {
                    return nil
                }
                description += " hits " + string
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
                description += " " + metric.rawValue.lowercased() + " hits " + string
                return description
            } else if let string = numberFormatter.string(from: targetNumber) {
                description += " " + unit.rawValue.lowercased() + " of"
                description += " " + metric.rawValue.lowercased() + " hits " + string
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
        case .financialTransactions:
            switch self.submetric {
            case .group:
                return financialTransactionsGroupsWExpense
            case .category:
                return financialTransactionsTopLevelCategoriesStaticWOUncategorized.sorted()
            case .subcategory:
                return financialTransactionsCategoriesStaticWOUncategorized.sorted()
            case .some(.none):
                return nil
            case nil:
                return nil
            }
        case .financialAccounts:
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
        case .financialTransactions:
            switch submetric {
            case .group:
                return financialTransactionsGroupsWExpense
            case .category:
                return financialTransactionsTopLevelCategoriesStaticWOUncategorized.sorted()
            case .subcategory:
                return financialTransactionsCategoriesStaticWOUncategorized.sorted()
            case .none:
                return nil
            }
        case .financialAccounts:
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

let prebuiltGoals = [mindfulnessGoal, sleepGoal, workoutsGoal, savingsGoal, dentistGoal, timeOffGoal, generalCheckUpGoal, eyeCheckUpGoal, skinCheckUpGoal, socialGoal]

let mindfulnessGoal = Goal(name: "Mindfulness", metric: GoalMetric.mindfulness, submetric: nil, option: nil, unit: GoalUnit.minutes, targetNumber: 30, currentNumber: nil)
let sleepGoal = Goal(name: "Sleep", metric: GoalMetric.sleep, submetric: nil, option: nil, unit: GoalUnit.hours, targetNumber: 7, currentNumber: nil)
let workoutsGoal = Goal(name: "Workout", metric: GoalMetric.workout, submetric: nil, option: nil, unit: GoalUnit.minutes, targetNumber: 30, currentNumber: nil)
let savingsGoal = Goal(name: "Savings", metric: GoalMetric.financialTransactions, submetric: GoalSubMetric.group, option: ["Income"], unit: GoalUnit.percent, targetNumber: 0.2, currentNumber: nil)
let debtGoal = Goal(name: "Pay Down Debt Other Than Credit Card", metric: GoalMetric.financialAccounts, submetric: GoalSubMetric.category, option: ["Mortgage", "Loan", "Line of Credit"], unit: GoalUnit.percent, targetNumber: 0.2, currentNumber: nil)
let creditCardGoal = Goal(name: "Pay Off Credit Card", metric: GoalMetric.financialAccounts, submetric: GoalSubMetric.category, option: ["Credit Card"], unit: GoalUnit.percent, targetNumber: 0.2, currentNumber: nil)
let emergencyFundGoal = Goal(name: "Emergency Fund", metric: GoalMetric.financialAccounts, submetric: GoalSubMetric.category, option: ["Cash", "Checking", "Savings"], unit: GoalUnit.percent, targetNumber: 0.2, currentNumber: nil)
let dentistGoal = Goal(name: "Dentist", metric: GoalMetric.events, submetric: GoalSubMetric.subcategory, option: ["Dentist"], unit: GoalUnit.count, targetNumber: 2, currentNumber: nil)
let timeOffGoal = Goal(name: "Time Off", metric: GoalMetric.events, submetric: GoalSubMetric.subcategory, option: ["Time Off"], unit: GoalUnit.count, targetNumber: 10, currentNumber: nil)
let generalCheckUpGoal = Goal(name: "General Check-up", metric: GoalMetric.events, submetric: GoalSubMetric.subcategory, option: ["Doctor"], unit: GoalUnit.count, targetNumber: 1, currentNumber: nil)
let eyeCheckUpGoal = Goal(name: "Eye Check-up", metric: GoalMetric.events, submetric: GoalSubMetric.subcategory, option: ["Eye Doctor"], unit: GoalUnit.count, targetNumber: 1, currentNumber: nil)
let skinCheckUpGoal = Goal(name: "Skin Check-up", metric: GoalMetric.events, submetric: GoalSubMetric.subcategory, option: ["Skin Doctor"], unit: GoalUnit.count, targetNumber: 1, currentNumber: nil)
let socialGoal = Goal(name: "Reach out to Somone", metric: GoalMetric.events, submetric: GoalSubMetric.category, option: ["Social"], unit: GoalUnit.count, targetNumber: 1, currentNumber: nil)

enum GoalMetric: String, Codable, CaseIterable {
//    case time = "Time"
//    case tasks = "Completed Tasks"
//    case spending = "Spending"
//    case income = "Savings"
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
    case financialTransactions = "Financial Transactions"
    case financialAccounts = "Financial Accounts"
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
        case .financialTransactions:
            return [.none, .group, .category, .subcategory]
        case .financialAccounts:
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
        case .financialTransactions:
            return [.amount, .percent]
        case .financialAccounts:
            return [.amount]
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
    
    var singlularName: String {
        return self.rawValue
    }
    
    var pluralName: String {
        switch self {
        case .none:
            return self.rawValue
        case .group:
            return "Groups"
        case .category:
            return "Categories"
        case .subcategory:
            return "Subcategories"
        }
    }
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
