//
//  Goal.swift
//  Plot
//
//  Created by Cory McHattie on 11/22/22.
//  Copyright © 2022 Immature Creations. All rights reserved.
//

import HealthKit

struct Goal: Codable, Equatable, Hashable {
    var name: String?
    var metric: GoalMetric?
    var submetric: GoalSubMetric?
    var option: [String]?
    var unit: GoalUnit?
    var period: GoalPeriod?
    var targetNumber: Double?
    var currentNumber: Double?
    var metricSecond: GoalMetric?
    var submetricSecond: GoalSubMetric?
    var optionSecond: [String]?
    var unitSecond: GoalUnit?
    var periodSecond: GoalPeriod?
    var targetNumberSecond: Double?
    var currentNumberSecond: Double?
    var activityID: String?
    var frequency: PlotRecurrenceFrequency?
    var metricsRelationshipType: MetricsRelationshipType?
    
    init(name: String?, metric: GoalMetric?, submetric: GoalSubMetric?, option: [String]?, unit: GoalUnit?, period: GoalPeriod?, targetNumber: Double?, currentNumber: Double?, frequency: PlotRecurrenceFrequency?, metricSecond: GoalMetric?, submetricSecond: GoalSubMetric?, optionSecond: [String]?, unitSecond: GoalUnit?, periodSecond: GoalPeriod?, targetNumberSecond: Double?, currentNumberSecond: Double?, metricsRelationshipType: MetricsRelationshipType?) {
        self.name = name
        self.metric = metric
        self.submetric = submetric
        self.option = option
        self.unit = unit
        self.period = period
        self.targetNumber = targetNumber
        self.currentNumber = currentNumber
        self.frequency = frequency
        self.metricSecond = metricSecond
        self.submetricSecond = submetricSecond
        self.optionSecond = optionSecond
        self.unitSecond = unitSecond
        self.periodSecond = periodSecond
        self.targetNumberSecond = targetNumberSecond
        self.currentNumberSecond = currentNumberSecond
        self.metricsRelationshipType = metricsRelationshipType
    }
    
    init(goal: Goal) {
        self.activityID = goal.activityID
        self.name = goal.name
        self.metric = goal.metric
        self.submetric = goal.submetric
        self.option = goal.option
        self.unit = goal.unit
        self.period = goal.period
        self.targetNumber = goal.targetNumber
        self.currentNumber = goal.currentNumber
        self.frequency = goal.frequency
        self.metricSecond = goal.metricSecond
        self.submetricSecond = goal.submetricSecond
        self.optionSecond = goal.optionSecond
        self.unitSecond = goal.unitSecond
        self.periodSecond = goal.periodSecond
        self.targetNumberSecond = goal.targetNumberSecond
        self.currentNumberSecond = goal.currentNumberSecond
        self.metricsRelationshipType = goal.metricsRelationshipType
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
        case .workout, .mindfulness, .sleep, .steps, .flightsClimbed, .activeCalories, .mood:
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
        case .mood:
            return .health
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
        case .workout:
            switch self.submetric {
            case .group:
                return nil
            case .category:
                var array = [String]()
                if #available(iOS 16.0, *) {
                    HKWorkoutActivityType.allCases.forEach {
                        array.append($0.name)
                    }
                } else if #available(iOS 14.0, *) {
                    HKWorkoutActivityType.oldAllCases.forEach {
                        array.append($0.name)
                    }
                } else {
                    HKWorkoutActivityType.oldOldAllCases.forEach {
                        array.append($0.name)
                    }
                }
                return array
            case .subcategory:
                return nil
            case .some(.none):
                return nil
            case nil:
                return nil
            }
        case .mood:
            switch self.submetric {
            case .group:
                return nil
            case .category:
                return MoodType.allValues
            case .subcategory:
                return nil
            case .some(.none):
                return nil
            case nil:
                return nil
            }
        case .mindfulness, .sleep, .steps, .flightsClimbed, .activeCalories:
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
        case .workout:
            switch self.submetric {
            case .group:
                return nil
            case .category:
                var array = [String]()
                if #available(iOS 16.0, *) {
                    HKWorkoutActivityType.allCases.forEach {
                        array.append($0.name)
                    }
                } else if #available(iOS 14.0, *) {
                    HKWorkoutActivityType.oldAllCases.forEach {
                        array.append($0.name)
                    }
                } else {
                    HKWorkoutActivityType.oldOldAllCases.forEach {
                        array.append($0.name)
                    }
                }
                return array
            case .subcategory:
                return nil
            case .some(.none):
                return nil
            case nil:
                return nil
            }
        case .mood:
            switch self.submetric {
            case .group:
                return nil
            case .category:
                return MoodType.allValues
            case .subcategory:
                return nil
            case .some(.none):
                return nil
            case nil:
                return nil
            }
        case .mindfulness, .sleep, .steps, .flightsClimbed, .activeCalories:
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
        case .workout:
            switch submetric {
            case .group:
                return nil
            case .category:
                var array = [String]()
                if #available(iOS 16.0, *) {
                    HKWorkoutActivityType.allCases.forEach {
                        array.append($0.name)
                    }
                } else if #available(iOS 14.0, *) {
                    HKWorkoutActivityType.oldAllCases.forEach {
                        array.append($0.name)
                    }
                } else {
                    HKWorkoutActivityType.oldOldAllCases.forEach {
                        array.append($0.name)
                    }
                }
                return array
            case .subcategory:
                return nil
            case .none:
                return nil
            }
        case .mood:
            switch submetric {
            case .group:
                return nil
            case .category:
                return MoodType.allValues
            case .subcategory:
                return nil
            case .none:
                return nil
            }
        case .mindfulness, .sleep, .steps, .flightsClimbed, .activeCalories:
            return nil
        case .none:
            return nil
        }
    }
    
    var metricsRelationshipTypes: [String] {
        if let metric = metric, let submetricSecond = metricSecond, (metric == .financialAccounts || metric == .financialTransactions), (submetricSecond == .financialAccounts || submetricSecond == .financialTransactions) {
            return MetricsRelationshipType.allValues
        }
        return MetricsRelationshipType.certainValues
    }
    
    var description: String? {
        let numberFormatter = NumberFormatter()
        numberFormatter.currencyCode = "USD"
        numberFormatter.maximumFractionDigits = 0
        var description = "Goal is complete when"
        if let metricsRelationshipType = metricsRelationshipType, (metricsRelationshipType == .equal || metricsRelationshipType == .more || metricsRelationshipType == .less) {
            if let targetNumber = targetNumber as? NSNumber {
                if let unit = unit, let metric = metric, let submetric = submetric, let option = option {
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
                    
                    if let string = numberFormatter.string(from: targetNumber) {
                        if unit == .multiple {
                            description += " " + string + "x"
                        } else {
                            description += " " + string
                        }
                    }
                    
                    if unit == .multiple {
                        description += " " + GoalUnit.amount.rawValue.lowercased() + " of "
                    } else {
                        description += " " + unit.rawValue.lowercased() + " of "
                    }

                    if metric == .tasks || metric == .events {
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
                                description += " " + submetric.pluralName.lowercased()
                            } else {
                                description += " " + submetric.singlularName.lowercased()
                            }
                        } else if submetric != .none {
                            return nil
                        }
                        return description
                    } else {
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
                        return description
                    }
                } else if let unit = unit, let metric = metric {
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
                    
                    if let string = numberFormatter.string(from: targetNumber) {
                        if unit == .multiple {
                            description += " " + string + "x"
                        } else {
                            description += " " + string
                        }
                    }
                    
                    if metric == .activeCalories || metric == .steps || metric == .flightsClimbed {
                        description += " " + metric.rawValue.lowercased()
                    } else {
                        if unit == .multiple {
                            description += " " + GoalUnit.amount.rawValue.lowercased() + " of"
                            description += " " + metric.rawValue.lowercased()
                        } else {
                            description += " " + unit.rawValue.lowercased() + " of"
                            description += " " + metric.rawValue.lowercased()
                        }
                    }
                    return description
                }
            } else {
                if let unit = unit, let metric = metric, let submetric = submetric, let option = option {
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

                    if metric == .tasks || metric == .events {
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
                                description += " " + submetric.pluralName.lowercased()
                            } else {
                                description += " " + submetric.singlularName.lowercased()
                            }
                        } else if submetric != .none {
                            return nil
                        }
                        return description
                    } else {
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
                                description += " " + submetric.singlularName.lowercased() + " hits " + string + "x"
                            } else {
                                description += " " + submetric.singlularName.lowercased() + " hits " + string
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
    
    var descriptionSecondary: String? {
        let numberFormatter = NumberFormatter()
        numberFormatter.currencyCode = "USD"
        numberFormatter.maximumFractionDigits = 0
        var description = " "
        guard let type = metricsRelationshipType else { return nil }
        description += type.descriptionText
        if let metricsRelationshipType = metricsRelationshipType, (metricsRelationshipType == .equal || metricsRelationshipType == .more || metricsRelationshipType == .less) {
            if let targetNumber = targetNumberSecond as? NSNumber {
                if let unit = unitSecond, let metric = metricSecond, let submetric = submetricSecond, let option = optionSecond {
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
                    
                    if let string = numberFormatter.string(from: targetNumber) {
                        if unit == .multiple {
                            description += " " + string + "x"
                        } else {
                            description += " " + string
                        }
                    }
                    
                    if unit == .multiple {
                        description += " " + GoalUnit.amount.rawValue.lowercased() + " of "
                    } else {
                        description += " " + unit.rawValue.lowercased() + " of "
                    }

                    if metric == .tasks || metric == .events {
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
                                description += " " + submetric.pluralName.lowercased()
                            } else {
                                description += " " + submetric.singlularName.lowercased()
                            }
                        } else if submetric != .none {
                            return nil
                        }
                        return description
                    } else {
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
                        return description
                    }
                } else if let unit = unitSecond, let metric = metricSecond, let targetNumber = targetNumberSecond as? NSNumber {
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
                    
                    if let string = numberFormatter.string(from: targetNumber) {
                        if unit == .multiple {
                            description += " " + string + "x"
                        } else {
                            description += " " + string
                        }
                    }
                    
                    if metric == .activeCalories || metric == .steps || metric == .flightsClimbed {
                        description += " " + metric.rawValue.lowercased()
                    } else {
                        if unit == .multiple {
                            description += " " + GoalUnit.amount.rawValue.lowercased() + " of"
                            description += " " + metric.rawValue.lowercased()
                        } else {
                            description += " " + unit.rawValue.lowercased() + " of"
                            description += " " + metric.rawValue.lowercased()
                        }
                    }
                    return description
                }
            } else {
                if let unit = unitSecond, let metric = metricSecond, let submetric = submetricSecond, let option = optionSecond {
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

                    if metric == .tasks || metric == .events {
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
                                description += " " + submetric.pluralName.lowercased()
                            } else {
                                description += " " + submetric.singlularName.lowercased()
                            }
                        } else if submetric != .none {
                            return nil
                        }
                        return description
                    } else {
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
                        return description
                    }
                } else if let unit = unitSecond, let metric = metricSecond, let targetNumber = targetNumberSecond as? NSNumber {
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
        } else {
            if let unit = unitSecond, let metric = metricSecond, let submetric = submetricSecond, let option = optionSecond, let targetNumber = targetNumberSecond as? NSNumber {
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
                                description += " " + submetric.singlularName.lowercased() + " hits " + string + "x"
                            } else {
                                description += " " + submetric.singlularName.lowercased() + " hits " + string
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
            } else if let unit = unitSecond, let metric = metricSecond, let targetNumber = targetNumberSecond as? NSNumber {
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

let prebuiltGoals = [mindfulnessGoal, sleepGoal, workoutsGoal, moodGoal, spendingGoal, savingsGoal, spendingGoal, emergencyFundGoal, creditCardGoal, debtGoal, dentistGoal, timeOffGoal, generalCheckUpGoal, eyeCheckUpGoal, skinCheckUpGoal, socialGoal]

let mindfulnessGoal = Goal(name: "Daily Mindfulness", metric: GoalMetric.mindfulness, submetric: nil, option: nil, unit: GoalUnit.minutes, period: GoalPeriod.day, targetNumber: 15, currentNumber: nil, frequency: PlotRecurrenceFrequency.daily, metricSecond: GoalMetric.events, submetricSecond: GoalSubMetric.category, optionSecond: ["Personal"], unitSecond: GoalUnit.minutes, periodSecond: nil, targetNumberSecond: 15, currentNumberSecond: nil, metricsRelationshipType: MetricsRelationshipType.or)
let sleepGoal = Goal(name: "Daily Sleep", metric: GoalMetric.sleep, submetric: nil, option: nil, unit: GoalUnit.hours, period: GoalPeriod.day, targetNumber: 7, currentNumber: nil, frequency: PlotRecurrenceFrequency.daily, metricSecond: nil, submetricSecond: nil, optionSecond: nil, unitSecond: nil, periodSecond: nil, targetNumberSecond: nil, currentNumberSecond: nil, metricsRelationshipType: nil)
let workoutsGoal = Goal(name: "Daily Workout", metric: GoalMetric.workout, submetric: nil, option: nil, unit: GoalUnit.minutes, period: GoalPeriod.day, targetNumber: 15, currentNumber: nil, frequency: PlotRecurrenceFrequency.daily, metricSecond: GoalMetric.steps, submetricSecond: nil, optionSecond: nil, unitSecond: GoalUnit.count, periodSecond: nil, targetNumberSecond: 5000, currentNumberSecond: nil, metricsRelationshipType: MetricsRelationshipType.or)
let moodGoal = Goal(name: "Daily Mood", metric: GoalMetric.mood, submetric: nil, option: nil, unit: GoalUnit.count, period: GoalPeriod.day, targetNumber: 1, currentNumber: nil, frequency: PlotRecurrenceFrequency.daily, metricSecond: nil, submetricSecond: nil, optionSecond: nil, unitSecond: nil, periodSecond: nil, targetNumberSecond: nil, currentNumberSecond: nil, metricsRelationshipType: nil)
let savingsGoal = Goal(name: "Monthly Savings", metric: GoalMetric.financialTransactions, submetric: GoalSubMetric.group, option: ["Net Savings"], unit: GoalUnit.amount, period: GoalPeriod.month, targetNumber: nil, currentNumber: nil, frequency: PlotRecurrenceFrequency.monthly, metricSecond: nil, submetricSecond: nil, optionSecond: nil, unitSecond: nil, periodSecond: nil, targetNumberSecond: nil, currentNumberSecond: nil, metricsRelationshipType: nil)
let spendingGoal = Goal(name: "Daily Spending", metric: GoalMetric.financialTransactions, submetric: GoalSubMetric.group, option: ["Expense"], unit: GoalUnit.amount, period: GoalPeriod.day, targetNumber: nil, currentNumber: nil, frequency: PlotRecurrenceFrequency.daily, metricSecond: nil, submetricSecond: nil, optionSecond: nil, unitSecond: nil, periodSecond: nil, targetNumberSecond: nil, currentNumberSecond: nil, metricsRelationshipType: nil)
let creditCardGoal = Goal(name: "Pay Off Credit Card(s)", metric: GoalMetric.financialAccounts, submetric: GoalSubMetric.category, option: ["Credit Card"], unit: GoalUnit.amount, period: GoalPeriod.month, targetNumber: 0, currentNumber: nil, frequency: PlotRecurrenceFrequency.monthly, metricSecond: nil, submetricSecond: nil, optionSecond: nil, unitSecond: nil, periodSecond: nil, targetNumberSecond: nil, currentNumberSecond: nil, metricsRelationshipType: nil)
let emergencyFundGoal = Goal(name: "Save Emergency Fund", metric: GoalMetric.financialAccounts, submetric: GoalSubMetric.category, option: ["Cash", "Checking", "Savings"], unit: GoalUnit.amount, period: nil,  targetNumber: nil, currentNumber: nil, frequency: nil, metricSecond: nil, submetricSecond: nil, optionSecond: nil, unitSecond: nil, periodSecond: nil, targetNumberSecond: nil, currentNumberSecond: nil, metricsRelationshipType: nil)
//let emergencyFundGoal = Goal(name: "Save Emergency Fund", metric: GoalMetric.financialAccounts, submetric: GoalSubMetric.category, option: ["Cash", "Checking", "Savings"], unit: GoalUnit.amount, period: nil,  targetNumber: nil, currentNumber: nil, frequency: nil, metricSecond: GoalMetric.financialTransactions, submetricSecond: GoalSubMetric.group, optionSecond: ["Expense"], unitSecond: GoalUnit.multiple, periodSecond: nil, targetNumberSecond: 3, currentNumberSecond: nil, metricsRelationshipType: MetricsRelationshipType.more)
let debtGoal = Goal(name: "Pay Off Debt", metric: GoalMetric.financialAccounts, submetric: GoalSubMetric.category, option: ["Mortgage", "Loan", "Line of Credit"], unit: GoalUnit.amount, period: nil, targetNumber: 0, currentNumber: nil, frequency: nil, metricSecond: nil, submetricSecond: nil, optionSecond: nil, unitSecond: nil, periodSecond: nil, targetNumberSecond: nil, currentNumberSecond: nil, metricsRelationshipType: nil)
let timeOffGoal = Goal(name: "Annual Time Off", metric: GoalMetric.events, submetric: GoalSubMetric.subcategory, option: ["Time Off"], unit: GoalUnit.count, period: GoalPeriod.year, targetNumber: 5, currentNumber: nil, frequency: PlotRecurrenceFrequency.yearly, metricSecond: nil, submetricSecond: nil, optionSecond: nil, unitSecond: nil, periodSecond: nil, targetNumberSecond: nil, currentNumberSecond: nil, metricsRelationshipType: nil)
let generalCheckUpGoal = Goal(name: "Annual Physical", metric: GoalMetric.events, submetric: GoalSubMetric.subcategory, option: ["Doctor - General"], unit: GoalUnit.count, period: GoalPeriod.year, targetNumber: 1, currentNumber: nil, frequency: PlotRecurrenceFrequency.yearly, metricSecond: nil, submetricSecond: nil, optionSecond: nil, unitSecond: nil, periodSecond: nil, targetNumberSecond: nil, currentNumberSecond: nil, metricsRelationshipType: nil)
let dentistGoal = Goal(name: "Bi-Annual Dental Cleaning", metric: GoalMetric.events, submetric: GoalSubMetric.subcategory, option: ["Doctor - Dentist"], unit: GoalUnit.count, period: GoalPeriod.year, targetNumber: 2, currentNumber: nil, frequency: PlotRecurrenceFrequency.yearly, metricSecond: nil, submetricSecond: nil, optionSecond: nil, unitSecond: nil, periodSecond: nil, targetNumberSecond: nil, currentNumberSecond: nil, metricsRelationshipType: nil)
let eyeCheckUpGoal = Goal(name: "Annual Vision Exam", metric: GoalMetric.events, submetric: GoalSubMetric.subcategory, option: ["Doctor - Eye"], unit: GoalUnit.count, period: GoalPeriod.year, targetNumber: 1, currentNumber: nil, frequency: PlotRecurrenceFrequency.yearly, metricSecond: nil, submetricSecond: nil, optionSecond: nil, unitSecond: nil, periodSecond: nil, targetNumberSecond: nil, currentNumberSecond: nil, metricsRelationshipType: nil)
let skinCheckUpGoal = Goal(name: "Annual Skin Screening", metric: GoalMetric.events, submetric: GoalSubMetric.subcategory, option: ["Doctor - Dermatologist"], unit: GoalUnit.count, period: GoalPeriod.year, targetNumber: 1, currentNumber: nil, frequency: PlotRecurrenceFrequency.yearly, metricSecond: nil, submetricSecond: nil, optionSecond: nil, unitSecond: nil, periodSecond: nil, targetNumberSecond: nil, currentNumberSecond: nil, metricsRelationshipType: nil)
let socialGoal = Goal(name: "Weekly Social", metric: GoalMetric.events, submetric: GoalSubMetric.category, option: ["Social"], unit: GoalUnit.count, period: GoalPeriod.week, targetNumber: 1, currentNumber: nil, frequency: PlotRecurrenceFrequency.weekly, metricSecond: nil, submetricSecond: nil, optionSecond: nil, unitSecond: nil, periodSecond: nil, targetNumberSecond: nil, currentNumberSecond: nil, metricsRelationshipType: nil)

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
    case mood = "Mood"
//    case weight = "Weight"
    
    static var allValues: [String] {
        var array = [String]()
        GoalMetric.allCases.forEach { metric in
            array.append(metric.rawValue)
        }
        return array.sorted()
    }
    
    static var allValuesWNone: [String] {
        var array = [String]()
        GoalMetric.allCases.forEach { metric in
            array.append(metric.rawValue)
        }
        array = array.sorted()
        array.insert("None", at: 0)
        return array
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
            return [.group, .category, .subcategory]
        case .financialAccounts:
            return [.group, .category, .subcategory]
        case .workout:
            return [.none, .category]
        case .mood:
            return [.none, .category]
        case .mindfulness, .sleep, .steps, .flightsClimbed, .activeCalories:
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
//            return [.amount, .percent, .multiple]
            return [.count, .amount]
        case .financialAccounts:
            return [.count, .amount]
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
        case .mood:
            return [.count]
        }
    }
    
    var type: MetricType {
        switch self {
        case .events:
            return .periodOfTime
        case .tasks:
            return .periodOfTime
        case .financialTransactions:
            return .periodOfTime
        case .financialAccounts:
            return .pointInTime
        case .workout:
            return .periodOfTime
        case .mindfulness:
            return .periodOfTime
        case .sleep:
            return .periodOfTime
        case .steps:
            return .periodOfTime
        case .flightsClimbed:
            return .periodOfTime
        case .activeCalories:
            return .periodOfTime
        case .mood:
            return .periodOfTime
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
    
    var activityLevel: ActivityLevel? {
        switch self {
        case .none:
            return ActivityLevel.none
        case .group:
            return nil
        case .category:
            return ActivityLevel.category
        case .subcategory:
            return ActivityLevel.subcategory
        }
    }
    
    var transcationCatLevel: TransactionCatLevel? {
        switch self {
        case .none:
            return nil
        case .group:
            return .group
        case .category:
            return .top
        case .subcategory:
            return .category
        }
    }
    
    var accountCatLevel: AccountCatLevel? {
        switch self {
        case .none:
            return nil
        case .group:
            return .bs_type
        case .category:
            return .type
        case .subcategory:
            return .subtype
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
    
    
    var workoutMeasure: WorkoutMeasure? {
        switch self {
        case .calories:
            return .calories
        case .count, .amount, .percent, .multiple, .hours, .days, .level:
            return nil
        case .minutes:
            return .duration
        }
    }
    
}

enum GoalPeriod: String, Codable, CaseIterable {
    case none = "None"
    case day = "Day"
    case week = "Week"
    case month = "Month"
    case year = "Year"
    
    static var allValues: [String] {
        var array = [String]()
        GoalPeriod.allCases.forEach { value in
            array.append(value.rawValue)
        }
        return array
    }
}

enum FormatterType: String {
    case number = "Number"
    case date = "Date"
}

enum MetricType {
    case pointInTime
    case periodOfTime
}

enum MetricsRelationshipType: String, Codable, CaseIterable {
    case or = "Or"
    case and = "And"
    case equal = "Equal"
    case more = "More"
    case less = "Less"
    
    static var allValues: [String] {
        var array = [String]()
        MetricsRelationshipType.allCases.forEach { value in
            if value == .or || value == .and {
                array.append(value.rawValue)
            }
        }
        return array
    }
    
    static var certainValues: [String] {
        return [MetricsRelationshipType.or.rawValue, MetricsRelationshipType.and.rawValue]
    }
    
    var descriptionText: String {
        switch self {
        case .or:
            return "or"
        case .and:
            return "and"
        case .equal:
            return "is equal to"
        case .more:
            return "is more than"
        case .less:
            return "is less than"
        }
    }
}

let MetricRelationshipFooterAll = "If OR is selected, goal will be marked as complete if the first OR the second metric is hit \nIf AND is selected, goal will be marked as complete when the first AND the second metric are hit \nIf EQUAL is selected, goal is complete when the first metric EQUALS the second metric \nIf MORE is selected, goal is complete when the first metric is MORE than the second metric \nIf LESS is selected, goal is complete when the first metric is LESS than the second metric"

let MetricRelationshipFooterCertain = "If OR is selected, goal will be marked as complete if the first OR the second metric is hit \nIf AND is selected, goal will be marked as complete when the first AND the second metric are hit"
