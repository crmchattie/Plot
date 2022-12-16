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
    var metricSecond: GoalMetric?
    var submetricSecond: GoalSubMetric?
    var optionSecond: [String]?
    var unitSecond: GoalUnit?
    var targetNumberSecond: Double?
    var currentNumberSecond: Double?
    var activityID: String?
    var frequency: PlotRecurrenceFrequency?
    var secondMetricType: SecondMetricType?
    
    init(name: String?, metric: GoalMetric?, submetric: GoalSubMetric?, option: [String]?, unit: GoalUnit?, targetNumber: Double?, currentNumber: Double?, frequency: PlotRecurrenceFrequency?, metricSecond: GoalMetric?, submetricSecond: GoalSubMetric?, optionSecond: [String]?, unitSecond: GoalUnit?, targetNumberSecond: Double?, currentNumberSecond: Double?, secondMetricType: SecondMetricType?) {
        self.name = name
        self.metric = metric
        self.submetric = submetric
        self.option = option
        self.unit = unit
        self.targetNumber = targetNumber
        self.currentNumber = currentNumber
        self.frequency = frequency
        self.metricSecond = metricSecond
        self.submetricSecond = submetricSecond
        self.optionSecond = optionSecond
        self.unitSecond = unitSecond
        self.targetNumberSecond = targetNumberSecond
        self.currentNumberSecond = currentNumberSecond
        self.secondMetricType = secondMetricType
    }
    
    init(goal: Goal) {
        self.activityID = goal.activityID
        self.name = goal.name
        self.metric = goal.metric
        self.submetric = goal.submetric
        self.option = goal.option
        self.unit = goal.unit
        self.targetNumber = goal.targetNumber
        self.currentNumber = goal.currentNumber
        self.frequency = goal.frequency
        self.metricSecond = goal.metricSecond
        self.submetricSecond = goal.submetricSecond
        self.optionSecond = goal.optionSecond
        self.unitSecond = goal.unitSecond
        self.targetNumberSecond = goal.targetNumberSecond
        self.currentNumberSecond = goal.currentNumberSecond
        self.secondMetricType = goal.secondMetricType
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
    
    func optionsSecond() -> [String]? {
        switch self.metricSecond {
        case .events:
            switch self.submetricSecond {
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
            switch self.submetricSecond {
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
            switch self.submetricSecond {
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
            switch self.submetricSecond {
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
    
    var description: String? {
        let numberFormatter = NumberFormatter()
        numberFormatter.currencyCode = "USD"
        numberFormatter.maximumFractionDigits = 0
        var description = "Goal is complete when"
        if let secondMetricType = secondMetricType, secondMetricType == .equal || secondMetricType == .more || secondMetricType == .less {
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
                
                if unit == .multiple {
                    description += " "
                    if let string = numberFormatter.string(from: targetNumber) {
                        if option.count > 0 {
                            description += string + "x the " + GoalUnit.amount.rawValue.lowercased() + " of "
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
                        return description

                    }
                } else {
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
                                description += " " + submetric.pluralName.lowercased() + " hits " + string
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
                } else if let string = numberFormatter.string(from: targetNumber) {
                    if unit == .multiple {
                        description += " " + string + "x the " + GoalUnit.amount.rawValue.lowercased() + " of " + metric.rawValue.lowercased()
                    } else {
                        description += " " + unit.rawValue.lowercased() + " of " + metric.rawValue.lowercased() + " hits " + string
                    }
                }
                return description
            }
        } else {
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
                
                if unit == .multiple {
                    description += " " + GoalUnit.amount.rawValue.lowercased() + " of "
                } else {
                    description += " " + unit.rawValue.lowercased() + " of "
                }

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
                            if unit == .multiple {
                                description += " " + submetric.pluralName.lowercased() + " hits " + string + "x"
                            } else {
                                description += " " + submetric.pluralName.lowercased() + " hits " + string
                            }
                        } else {
                            if unit == .multiple {
                                description += " " + submetric.pluralName.lowercased() + " hits " + string + "x"
                            } else {
                                description += " " + submetric.pluralName.lowercased() + " hits " + string
                            }
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
                    if unit == .multiple {
                        description += " hits " + string + "x"
                    } else {
                        description += " hits " + string
                    }
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
                } else if let string = numberFormatter.string(from: targetNumber) {
                    if unit == .multiple {
                        description += " " + GoalUnit.amount.rawValue.lowercased() + " of"
                        description += " " + metric.rawValue.lowercased() + " hits " + string + "x"
                    } else {
                        description += " " + unit.rawValue.lowercased() + " of"
                        description += " " + metric.rawValue.lowercased() + " hits " + string
                    }
                }
                return description
            }
        }
        
        return nil
    }
}

let prebuiltGoals = [mindfulnessGoal, sleepGoal, workoutsGoal, savingsGoal, dentistGoal, timeOffGoal, generalCheckUpGoal, eyeCheckUpGoal, skinCheckUpGoal, socialGoal]

let mindfulnessGoal = Goal(name: "Mindfulness", metric: GoalMetric.mindfulness, submetric: nil, option: nil, unit: GoalUnit.minutes, targetNumber: 30, currentNumber: nil, frequency: PlotRecurrenceFrequency.daily, metricSecond: nil, submetricSecond: nil, optionSecond: nil, unitSecond: nil, targetNumberSecond: nil, currentNumberSecond: nil, secondMetricType: nil)
let sleepGoal = Goal(name: "Sleep", metric: GoalMetric.sleep, submetric: nil, option: nil, unit: GoalUnit.hours, targetNumber: 7, currentNumber: nil, frequency: PlotRecurrenceFrequency.daily, metricSecond: nil, submetricSecond: nil, optionSecond: nil, unitSecond: nil, targetNumberSecond: nil, currentNumberSecond: nil, secondMetricType: nil)
let workoutsGoal = Goal(name: "Workout", metric: GoalMetric.workout, submetric: nil, option: nil, unit: GoalUnit.minutes, targetNumber: 30, currentNumber: nil, frequency: PlotRecurrenceFrequency.daily, metricSecond: nil, submetricSecond: nil, optionSecond: nil, unitSecond: nil, targetNumberSecond: nil, currentNumberSecond: nil, secondMetricType: nil)
let savingsGoal = Goal(name: "Savings", metric: GoalMetric.financialTransactions, submetric: GoalSubMetric.group, option: ["Income"], unit: GoalUnit.percent, targetNumber: 0.2, currentNumber: nil, frequency: PlotRecurrenceFrequency.monthly, metricSecond: nil, submetricSecond: nil, optionSecond: nil, unitSecond: nil, targetNumberSecond: nil, currentNumberSecond: nil, secondMetricType: nil)
let creditCardGoal = Goal(name: "Pay Off Credit Card", metric: GoalMetric.financialAccounts, submetric: GoalSubMetric.category, option: ["Credit Card"], unit: GoalUnit.amount, targetNumber: 0, currentNumber: nil, frequency: PlotRecurrenceFrequency.monthly, metricSecond: nil, submetricSecond: nil, optionSecond: nil, unitSecond: nil, targetNumberSecond: nil, currentNumberSecond: nil, secondMetricType: nil)
let emergencyFundGoal = Goal(name: "Emergency Fund", metric: GoalMetric.financialAccounts, submetric: GoalSubMetric.category, option: ["Cash", "Checking", "Savings"], unit: GoalUnit.amount, targetNumber: 0.2, currentNumber: nil, frequency: nil, metricSecond: nil, submetricSecond: nil, optionSecond: nil, unitSecond: nil, targetNumberSecond: nil, currentNumberSecond: nil, secondMetricType: nil)
let timeOffGoal = Goal(name: "Time Off", metric: GoalMetric.events, submetric: GoalSubMetric.subcategory, option: ["Time Off"], unit: GoalUnit.count, targetNumber: 10, currentNumber: nil, frequency: PlotRecurrenceFrequency.yearly, metricSecond: nil, submetricSecond: nil, optionSecond: nil, unitSecond: nil, targetNumberSecond: nil, currentNumberSecond: nil, secondMetricType: nil)
let generalCheckUpGoal = Goal(name: "Annual Physical", metric: GoalMetric.events, submetric: GoalSubMetric.subcategory, option: ["Doctor - General"], unit: GoalUnit.count, targetNumber: 1, currentNumber: nil, frequency: PlotRecurrenceFrequency.yearly, metricSecond: nil, submetricSecond: nil, optionSecond: nil, unitSecond: nil, targetNumberSecond: nil, currentNumberSecond: nil, secondMetricType: nil)
let dentistGoal = Goal(name: "Dental Cleaning", metric: GoalMetric.events, submetric: GoalSubMetric.subcategory, option: ["Doctor - Dentist"], unit: GoalUnit.count, targetNumber: 2, currentNumber: nil, frequency: PlotRecurrenceFrequency.yearly, metricSecond: nil, submetricSecond: nil, optionSecond: nil, unitSecond: nil, targetNumberSecond: nil, currentNumberSecond: nil, secondMetricType: nil)
let eyeCheckUpGoal = Goal(name: "Vision Exam", metric: GoalMetric.events, submetric: GoalSubMetric.subcategory, option: ["Doctor - Eye"], unit: GoalUnit.count, targetNumber: 1, currentNumber: nil, frequency: PlotRecurrenceFrequency.yearly, metricSecond: nil, submetricSecond: nil, optionSecond: nil, unitSecond: nil, targetNumberSecond: nil, currentNumberSecond: nil, secondMetricType: nil)
let skinCheckUpGoal = Goal(name: "Skin Screening", metric: GoalMetric.events, submetric: GoalSubMetric.subcategory, option: ["Doctor - Dermatologist"], unit: GoalUnit.count, targetNumber: 1, currentNumber: nil, frequency: PlotRecurrenceFrequency.yearly, metricSecond: nil, submetricSecond: nil, optionSecond: nil, unitSecond: nil, targetNumberSecond: nil, currentNumberSecond: nil, secondMetricType: nil)
let socialGoal = Goal(name: "Reach out to Somone", metric: GoalMetric.events, submetric: GoalSubMetric.category, option: ["Social"], unit: GoalUnit.count, targetNumber: 1, currentNumber: nil, frequency: PlotRecurrenceFrequency.weekly, metricSecond: nil, submetricSecond: nil, optionSecond: nil, unitSecond: nil, targetNumberSecond: nil, currentNumberSecond: nil, secondMetricType: nil)

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
            return [.amount, .percent, .multiple]
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

enum SecondMetricType: String, Codable, CaseIterable {
    case none = "None"
    case or = "Or"
    case and = "And"
    case equal = "Equal"
    case more = "More"
    case less = "Less"
    
    static var allValues: [String] {
        var array = [String]()
        SecondMetricType.allCases.forEach { value in
            array.append(value.rawValue)
        }
        return array
    }
}
