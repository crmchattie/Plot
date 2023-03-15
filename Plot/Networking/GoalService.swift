//
//  GoalService.swift
//  Plot
//
//  Created by Cory McHattie on 2/4/23.
//  Copyright © 2023 Immature Creations. All rights reserved.
//

import Foundation
import Firebase
import EventKit
import RRuleSwift

extension NetworkController {    
    func checkGoalsForCompletion(_ completion: @escaping () -> Void) {
        //create loop of existing goals
        //check if goal is complete
        //check if goal has end date
        //if so, check frequency
        //if so, grab start date (= endDate - frequency day interval)
        //grab goal details and check against relevant metric(s)
        //if goal metric is met, update goal to completion; if not, do nothing and move to next goal
        //add check to see if endDate is in the past - maybe add buffer like a month? If so, skip and move to next goal?
        
        let past = Date().weekBefore
        let current = Date().localTime
        let group = DispatchGroup()
        
        for task in activityService.goals {
            group.enter()
            guard !(task.completeUpdatedByUser ?? false), let goal = task.goal, let metric = goal.metric, let unit = goal.unit, let target = goal.targetNumber else {
                group.leave()
                continue
            }
            
            var range = DateRange(startDate: Date().localTime.startOfDay, endDate: Date().localTime.endOfDay.advanced(by: -1))
            
            //not all tasks will have a start date
            if let startDate = task.goalStartDate, let endDate = task.goalEndDate {
                range = DateRange(startDate: startDate, endDate: endDate)
            } else if let endDate = task.goalEndDate {
                range = DateRange(startDate: endDate.endOfDay.advanced(by: -1), endDate: endDate.endOfDay.advanced(by: -1))
            }
            
            guard range.endDate > past, range.startDate <= current else {
                group.leave()
                continue
            }
            
//            print("metricCheck check")
//            print(task.name)
//            print(task.activityID)
//            print(metric)
//            print(task.startDate)
//            print(range.startDate)
//            print(task.endDate)
//            print(range.endDate)
//            print(past)
//            print(current)
                                        
            checkGoal(metric: metric, submetric: goal.submetric, option: goal.option, unit: unit, range: range) { stat in
                var finalStat = Statistic(date: range.startDate, value: 0)
                if let stat = stat {
                    finalStat = stat
                }
                
//                print("metricCheck done")
//                print(task.name)
//                print(task.activityID)
//                print(metric)
//                print(task.startDate)
//                print(range.startDate)
//                print(task.endDate)
//                print(range.endDate)
//                print(finalStat.date)
//                print(finalStat.value)

                if let metricsRelationshipType = goal.metricsRelationshipType, let metricSecond = goal.metricSecond, let unitSecond = goal.unitSecond, let targetSecond = goal.targetNumberSecond {
                    self.checkGoal(metric: metricSecond, submetric: goal.submetricSecond, option: goal.optionSecond, unit: unitSecond, range: range) { statSecond in
                        var finalStatSecond = Statistic(date: range.startDate, value: 0)
                        if let statSecond = statSecond {
                            finalStatSecond = statSecond
                        }
                        
//                        print("metricCheckSecond done")
//                        print(task.name)
//                        print(task.activityID)
//                        print(metric)
//                        print(task.startDate)
//                        print(range.startDate)
//                        print(task.endDate)
//                        print(range.endDate)
//                        print(finalStatSecond.date)
//                        print(finalStatSecond.value)
                        
                        switch metricsRelationshipType {
                        case .or:
                            switch goal.metricRelationship ?? MetricsRelationshipType.equalMore {
                            case .equalMore:
                                switch goal.metricRelationshipSecond ?? MetricsRelationshipType.equalMore {
                                    case .equalMore:
                                        if (finalStat.value >= target && (goal.currentNumber != finalStat.value || !(task.isCompleted ?? false))) || (finalStatSecond.value >= targetSecond && (goal.currentNumberSecond != finalStatSecond.value || !(task.isCompleted ?? false))) {
                                            if !(task.isCompleted ?? false) {
                                                task.completedDate = NSNumber(value: Int((range.endDate).timeIntervalSince1970))
                                            }
                                            let updateTask = ActivityActions(activity: task, active: true, selectedFalconUsers: [])
                                            updateTask.updateCompletion(isComplete: true, completeUpdatedByUser: false, goalCurrentNumber: finalStat.value as NSNumber, goalCurrentNumberSecond: finalStatSecond.value as NSNumber)
                                        } else if (finalStat.value < target && (goal.currentNumber != finalStat.value || task.isCompleted ?? false)) && (finalStatSecond.value < targetSecond && (goal.currentNumberSecond != finalStatSecond.value || task.isCompleted ?? false)) {
                                            let updateTask = ActivityActions(activity: task, active: true, selectedFalconUsers: [])
                                            updateTask.updateCompletion(isComplete: false, completeUpdatedByUser: false, goalCurrentNumber: finalStat.value as NSNumber, goalCurrentNumberSecond: finalStatSecond.value as NSNumber)
                                        } else if goal.currentNumber != finalStat.value || goal.currentNumberSecond != finalStatSecond.value {
                                            let updateTask = ActivityActions(activity: task, active: true, selectedFalconUsers: [])
                                            updateTask.updateCompletion(isComplete: task.isCompleted ?? false, completeUpdatedByUser: false, goalCurrentNumber: finalStat.value as NSNumber, goalCurrentNumberSecond: finalStatSecond.value as NSNumber)
                                        }
                                    
                                    case .equalLess:
                                        if (finalStat.value >= target && (goal.currentNumber != finalStat.value || !(task.isCompleted ?? false))) || (finalStatSecond.value <= targetSecond && (goal.currentNumberSecond != finalStatSecond.value || !(task.isCompleted ?? false))) {
                                            if !(task.isCompleted ?? false) {
                                                task.completedDate = NSNumber(value: Int((range.endDate).timeIntervalSince1970))
                                            }
                                            let updateTask = ActivityActions(activity: task, active: true, selectedFalconUsers: [])
                                            updateTask.updateCompletion(isComplete: true, completeUpdatedByUser: false, goalCurrentNumber: finalStat.value as NSNumber, goalCurrentNumberSecond: finalStatSecond.value as NSNumber)
                                        } else if (finalStat.value < target && (goal.currentNumber != finalStat.value || task.isCompleted ?? false)) && (finalStatSecond.value > targetSecond && (goal.currentNumberSecond != finalStatSecond.value || task.isCompleted ?? false)) {
                                            let updateTask = ActivityActions(activity: task, active: true, selectedFalconUsers: [])
                                            updateTask.updateCompletion(isComplete: false, completeUpdatedByUser: false, goalCurrentNumber: finalStat.value as NSNumber, goalCurrentNumberSecond: finalStatSecond.value as NSNumber)
                                        } else if goal.currentNumber != finalStat.value || goal.currentNumberSecond != finalStatSecond.value {
                                            let updateTask = ActivityActions(activity: task, active: true, selectedFalconUsers: [])
                                            updateTask.updateCompletion(isComplete: task.isCompleted ?? false, completeUpdatedByUser: false, goalCurrentNumber: finalStat.value as NSNumber, goalCurrentNumberSecond: finalStatSecond.value as NSNumber)
                                        }
                                    case .and, .or, .equal:
                                        break
                                }

                            case .equalLess:
                                switch goal.metricRelationshipSecond ?? MetricsRelationshipType.equalMore {
                                    case .equalMore:
                                        if (finalStat.value <= target && (goal.currentNumber != finalStat.value || !(task.isCompleted ?? false))) || (finalStatSecond.value >= targetSecond && (goal.currentNumberSecond != finalStatSecond.value || !(task.isCompleted ?? false))) {
                                            if !(task.isCompleted ?? false) {
                                                task.completedDate = NSNumber(value: Int((range.endDate).timeIntervalSince1970))
                                            }
                                            let updateTask = ActivityActions(activity: task, active: true, selectedFalconUsers: [])
                                            updateTask.updateCompletion(isComplete: true, completeUpdatedByUser: false, goalCurrentNumber: finalStat.value as NSNumber, goalCurrentNumberSecond: finalStatSecond.value as NSNumber)
                                        } else if (finalStat.value > target && (goal.currentNumber != finalStat.value || task.isCompleted ?? false)) && (finalStatSecond.value < targetSecond && (goal.currentNumberSecond != finalStatSecond.value || task.isCompleted ?? false)) {
                                            let updateTask = ActivityActions(activity: task, active: true, selectedFalconUsers: [])
                                            updateTask.updateCompletion(isComplete: false, completeUpdatedByUser: false, goalCurrentNumber: finalStat.value as NSNumber, goalCurrentNumberSecond: finalStatSecond.value as NSNumber)
                                        } else if goal.currentNumber != finalStat.value || goal.currentNumberSecond != finalStatSecond.value {
                                            let updateTask = ActivityActions(activity: task, active: true, selectedFalconUsers: [])
                                            updateTask.updateCompletion(isComplete: task.isCompleted ?? false, completeUpdatedByUser: false, goalCurrentNumber: finalStat.value as NSNumber, goalCurrentNumberSecond: finalStatSecond.value as NSNumber)
                                        }

                                    
                                    case .equalLess:
                                        if (finalStat.value <= target && (goal.currentNumber != finalStat.value || !(task.isCompleted ?? false))) || (finalStatSecond.value <= targetSecond && (goal.currentNumberSecond != finalStatSecond.value || !(task.isCompleted ?? false))) {
                                            if !(task.isCompleted ?? false) {
                                                task.completedDate = NSNumber(value: Int((range.endDate).timeIntervalSince1970))
                                            }
                                            let updateTask = ActivityActions(activity: task, active: true, selectedFalconUsers: [])
                                            updateTask.updateCompletion(isComplete: true, completeUpdatedByUser: false, goalCurrentNumber: finalStat.value as NSNumber, goalCurrentNumberSecond: finalStatSecond.value as NSNumber)
                                        } else if (finalStat.value > target && (goal.currentNumber != finalStat.value || task.isCompleted ?? false)) && (finalStatSecond.value > targetSecond && (goal.currentNumberSecond != finalStatSecond.value || task.isCompleted ?? false)) {
                                            let updateTask = ActivityActions(activity: task, active: true, selectedFalconUsers: [])
                                            updateTask.updateCompletion(isComplete: false, completeUpdatedByUser: false, goalCurrentNumber: finalStat.value as NSNumber, goalCurrentNumberSecond: finalStatSecond.value as NSNumber)
                                        } else if goal.currentNumber != finalStat.value || goal.currentNumberSecond != finalStatSecond.value {
                                            let updateTask = ActivityActions(activity: task, active: true, selectedFalconUsers: [])
                                            updateTask.updateCompletion(isComplete: task.isCompleted ?? false, completeUpdatedByUser: false, goalCurrentNumber: finalStat.value as NSNumber, goalCurrentNumberSecond: finalStatSecond.value as NSNumber)
                                        }
                                    case .and, .or, .equal:
                                        break
                                }
                            case .and, .or, .equal:
                                break
                            }
                        case .and:
                            switch goal.metricRelationship ?? MetricsRelationshipType.equalMore {
                            case .equalMore:
                                switch goal.metricRelationshipSecond ?? MetricsRelationshipType.equalMore {
                                    case .equalMore:
                                        if (finalStat.value >= target && (goal.currentNumber != finalStat.value || !(task.isCompleted ?? false))) && (finalStatSecond.value >= targetSecond && (goal.currentNumberSecond != finalStatSecond.value || !(task.isCompleted ?? false))) {
                                            if !(task.isCompleted ?? false) {
                                                task.completedDate = NSNumber(value: Int((range.endDate).timeIntervalSince1970))
                                            }
                                            let updateTask = ActivityActions(activity: task, active: true, selectedFalconUsers: [])
                                            updateTask.updateCompletion(isComplete: true, completeUpdatedByUser: false, goalCurrentNumber: finalStat.value as NSNumber, goalCurrentNumberSecond: finalStatSecond.value as NSNumber)
                                        } else if (finalStat.value < target && (goal.currentNumber != finalStat.value || task.isCompleted ?? false)) || (finalStatSecond.value < targetSecond && (goal.currentNumberSecond != finalStatSecond.value || task.isCompleted ?? false)) {
                                            let updateTask = ActivityActions(activity: task, active: true, selectedFalconUsers: [])
                                            updateTask.updateCompletion(isComplete: false, completeUpdatedByUser: false, goalCurrentNumber: finalStat.value as NSNumber, goalCurrentNumberSecond: finalStatSecond.value as NSNumber)
                                        } else if goal.currentNumber != finalStat.value || goal.currentNumberSecond != finalStatSecond.value {
                                            let updateTask = ActivityActions(activity: task, active: true, selectedFalconUsers: [])
                                            updateTask.updateCompletion(isComplete: task.isCompleted ?? false, completeUpdatedByUser: false, goalCurrentNumber: finalStat.value as NSNumber, goalCurrentNumberSecond: finalStatSecond.value as NSNumber)
                                        }
                                    
                                    case .equalLess:
                                        if (finalStat.value >= target && (goal.currentNumber != finalStat.value || !(task.isCompleted ?? false))) && (finalStatSecond.value <= targetSecond && (goal.currentNumberSecond != finalStatSecond.value || !(task.isCompleted ?? false))) {
                                            if !(task.isCompleted ?? false) {
                                                task.completedDate = NSNumber(value: Int((range.endDate).timeIntervalSince1970))
                                            }
                                            let updateTask = ActivityActions(activity: task, active: true, selectedFalconUsers: [])
                                            updateTask.updateCompletion(isComplete: true, completeUpdatedByUser: false, goalCurrentNumber: finalStat.value as NSNumber, goalCurrentNumberSecond: finalStatSecond.value as NSNumber)
                                        } else if (finalStat.value < target && (goal.currentNumber != finalStat.value || task.isCompleted ?? false)) || (finalStatSecond.value > targetSecond && (goal.currentNumberSecond != finalStatSecond.value || task.isCompleted ?? false)) {
                                            let updateTask = ActivityActions(activity: task, active: true, selectedFalconUsers: [])
                                            updateTask.updateCompletion(isComplete: false, completeUpdatedByUser: false, goalCurrentNumber: finalStat.value as NSNumber, goalCurrentNumberSecond: finalStatSecond.value as NSNumber)
                                        } else if goal.currentNumber != finalStat.value || goal.currentNumberSecond != finalStatSecond.value {
                                            let updateTask = ActivityActions(activity: task, active: true, selectedFalconUsers: [])
                                            updateTask.updateCompletion(isComplete: task.isCompleted ?? false, completeUpdatedByUser: false, goalCurrentNumber: finalStat.value as NSNumber, goalCurrentNumberSecond: finalStatSecond.value as NSNumber)
                                        }
                                    case .and, .or, .equal:
                                        break
                                }

                            case .equalLess:
                                switch goal.metricRelationshipSecond ?? MetricsRelationshipType.equalMore {
                                    case .equalMore:
                                        if (finalStat.value <= target && (goal.currentNumber != finalStat.value || !(task.isCompleted ?? false))) && (finalStatSecond.value >= targetSecond && (goal.currentNumberSecond != finalStatSecond.value || !(task.isCompleted ?? false))) {
                                            if !(task.isCompleted ?? false) {
                                                task.completedDate = NSNumber(value: Int((range.endDate).timeIntervalSince1970))
                                            }
                                            let updateTask = ActivityActions(activity: task, active: true, selectedFalconUsers: [])
                                            updateTask.updateCompletion(isComplete: true, completeUpdatedByUser: false, goalCurrentNumber: finalStat.value as NSNumber, goalCurrentNumberSecond: finalStatSecond.value as NSNumber)
                                        } else if (finalStat.value > target && (goal.currentNumber != finalStat.value || task.isCompleted ?? false)) || (finalStatSecond.value < targetSecond && (goal.currentNumberSecond != finalStatSecond.value || task.isCompleted ?? false)) {
                                            let updateTask = ActivityActions(activity: task, active: true, selectedFalconUsers: [])
                                            updateTask.updateCompletion(isComplete: false, completeUpdatedByUser: false, goalCurrentNumber: finalStat.value as NSNumber, goalCurrentNumberSecond: finalStatSecond.value as NSNumber)
                                        } else if goal.currentNumber != finalStat.value || goal.currentNumberSecond != finalStatSecond.value {
                                            let updateTask = ActivityActions(activity: task, active: true, selectedFalconUsers: [])
                                            updateTask.updateCompletion(isComplete: task.isCompleted ?? false, completeUpdatedByUser: false, goalCurrentNumber: finalStat.value as NSNumber, goalCurrentNumberSecond: finalStatSecond.value as NSNumber)
                                        }

                                    
                                    case .equalLess:
                                        if (finalStat.value <= target && (goal.currentNumber != finalStat.value || !(task.isCompleted ?? false))) && (finalStatSecond.value <= targetSecond && (goal.currentNumberSecond != finalStatSecond.value || !(task.isCompleted ?? false))) {
                                            if !(task.isCompleted ?? false) {
                                                task.completedDate = NSNumber(value: Int((range.endDate).timeIntervalSince1970))
                                            }
                                            let updateTask = ActivityActions(activity: task, active: true, selectedFalconUsers: [])
                                            updateTask.updateCompletion(isComplete: true, completeUpdatedByUser: false, goalCurrentNumber: finalStat.value as NSNumber, goalCurrentNumberSecond: finalStatSecond.value as NSNumber)
                                        } else if (finalStat.value > target && (goal.currentNumber != finalStat.value || task.isCompleted ?? false)) || (finalStatSecond.value > targetSecond && (goal.currentNumberSecond != finalStatSecond.value || task.isCompleted ?? false)) {
                                            let updateTask = ActivityActions(activity: task, active: true, selectedFalconUsers: [])
                                            updateTask.updateCompletion(isComplete: false, completeUpdatedByUser: false, goalCurrentNumber: finalStat.value as NSNumber, goalCurrentNumberSecond: finalStatSecond.value as NSNumber)
                                        } else if goal.currentNumber != finalStat.value || goal.currentNumberSecond != finalStatSecond.value {
                                            let updateTask = ActivityActions(activity: task, active: true, selectedFalconUsers: [])
                                            updateTask.updateCompletion(isComplete: task.isCompleted ?? false, completeUpdatedByUser: false, goalCurrentNumber: finalStat.value as NSNumber, goalCurrentNumberSecond: finalStatSecond.value as NSNumber)
                                        }
                                    case .and, .or, .equal:
                                        break
                                }
                            case .and, .or, .equal:
                                break
                            }

                        //not in use yet
                        case .equal, .equalMore, .equalLess:
                            break
                        }
                    }
                    group.leave()
                } else {
                    switch goal.metricRelationship ?? MetricsRelationshipType.equalMore {
                    case .equalMore:
                        if finalStat.value >= target && (goal.currentNumber != finalStat.value || !(task.isCompleted ?? false)) {
                            if !(task.isCompleted ?? false) {
                                task.completedDate = NSNumber(value: Int((range.endDate).timeIntervalSince1970))
                            }
                            let updateTask = ActivityActions(activity: task, active: true, selectedFalconUsers: [])
                            updateTask.updateCompletion(isComplete: true, completeUpdatedByUser: false, goalCurrentNumber: finalStat.value as NSNumber, goalCurrentNumberSecond: nil)
                        } else if finalStat.value < target && (goal.currentNumber != finalStat.value || task.isCompleted ?? false) {
                            let updateTask = ActivityActions(activity: task, active: true, selectedFalconUsers: [])
                            updateTask.updateCompletion(isComplete: false, completeUpdatedByUser: false, goalCurrentNumber: finalStat.value as NSNumber, goalCurrentNumberSecond: nil)
                        } else if goal.currentNumber != finalStat.value {
                            let updateTask = ActivityActions(activity: task, active: true, selectedFalconUsers: [])
                            updateTask.updateCompletion(isComplete: task.isCompleted ?? false, completeUpdatedByUser: false, goalCurrentNumber: finalStat.value as NSNumber, goalCurrentNumberSecond: nil)
                        }

                    case .equalLess:
                        if finalStat.value <= target && (goal.currentNumber != finalStat.value || !(task.isCompleted ?? false)) {
                            if !(task.isCompleted ?? false) {
                                task.completedDate = NSNumber(value: Int((range.endDate).timeIntervalSince1970))
                            }
                            let updateTask = ActivityActions(activity: task, active: true, selectedFalconUsers: [])
                            updateTask.updateCompletion(isComplete: true, completeUpdatedByUser: false, goalCurrentNumber: finalStat.value as NSNumber, goalCurrentNumberSecond: nil)
                        } else if finalStat.value > target && (goal.currentNumber != finalStat.value || task.isCompleted ?? false) {
                            let updateTask = ActivityActions(activity: task, active: true, selectedFalconUsers: [])
                            updateTask.updateCompletion(isComplete: false, completeUpdatedByUser: false, goalCurrentNumber: finalStat.value as NSNumber, goalCurrentNumberSecond: nil)
                        } else if goal.currentNumber != finalStat.value {
                            let updateTask = ActivityActions(activity: task, active: true, selectedFalconUsers: [])
                            updateTask.updateCompletion(isComplete: task.isCompleted ?? false, completeUpdatedByUser: false, goalCurrentNumber: finalStat.value as NSNumber, goalCurrentNumberSecond: nil)
                        }

                    case .and, .or, .equal:
                        break
                    }
                    group.leave()
                }
            }
        }
        
        group.notify(queue: .main) {
            completion()
        }
    }
    
  
    func checkGoal(metric: GoalMetric, submetric: GoalSubMetric?, option: [String]?, unit: GoalUnit, range: DateRange, completion: @escaping (Statistic?) -> Void) {
        switch metric {
        case .events:
            activityDetailService.getActivityCategoriesSamples(activities: activityService.events, isEvent: true, level: submetric?.activityLevel ?? .none, options: option, range: range) { stat, activities in
                guard let stat = stat, let activities = activities else {
                    completion(nil)
                    return
                }
                
                var finalStat = stat
                switch unit {
                case .count:
                    finalStat.value = Double(activities.count)
                    completion(finalStat)
                case .minutes:
                    finalStat.value = finalStat.value.totalMinutes
                    completion(finalStat)
                case .hours:
                    finalStat.value = finalStat.value.totalHours
                    completion(finalStat)
                case .days:
                    finalStat.value = finalStat.value.totalDays
                    completion(finalStat)
                case .calories, .amount, .percent, .multiple, .level:
                    completion(finalStat)
                }
                
            }
        case .tasks:
            activityDetailService.getActivityCategoriesSamples(activities: activityService.tasks, isEvent: false, level: submetric?.activityLevel ?? .none, options: option, range: range) { stat, activities in
                guard let stat = stat, let activities = activities else {
                    completion(nil)
                    return
                }
                
                var finalStat = stat
                switch unit {
                case .count:
                    finalStat.value = Double(activities.count)
                    completion(finalStat)
                case .hours, .minutes, .days, .calories, .amount, .percent, .multiple, .level:
                    completion(finalStat)
                }
            }
        case .financialTransactions:
            var transactionDetails = [TransactionDetails]()
            switch submetric {
            case nil, .some(.none):
                break
            case .some(.group):
                for opt in option ?? [] {
                    let transactionDetail = TransactionDetails(name: opt, amount: 0, level: submetric?.transcationCatLevel ?? .group, group: opt)
                    transactionDetails.append(transactionDetail)
                }
            case .some(.category):
                for opt in option ?? [] {
                    let transactionDetail = TransactionDetails(name: opt, amount: 0, level: submetric?.transcationCatLevel ?? .group, topLevelCategory: opt)
                    transactionDetails.append(transactionDetail)
                }
            case .some(.subcategory):
                for opt in option ?? [] {
                    let transactionDetail = TransactionDetails(name: opt, amount: 0, level: submetric?.transcationCatLevel ?? .group, category: opt)
                    transactionDetails.append(transactionDetail)
                }
            }
            
            financeDetailService.getSamples(for: range, accountDetails: nil, transactionDetails: transactionDetails, accounts: nil, transactions: financeService.transactions, filterAccounts: nil, ignore_plot_created: nil, ignore_transfer_between_accounts: true) { stat, _, transactions, err in
                guard let stat = stat, let transactions = transactions else {
                    completion(nil)
                    return
                    
                }
                
                var finalStat = stat
                switch unit {
                case .count:
                    finalStat.value = Double(transactions.count)
                    completion(finalStat)
                case .amount:
                    completion(finalStat)
                case .hours, .minutes, .days, .calories, .percent, .multiple, .level:
                    completion(nil)
                }
            }
        case .financialAccounts:
            if let option = option, option.count == 1, option.first == "Credit Card" {
                let transactionDetails = [TransactionDetails(name: "Credit Card Payment", amount: 0, level: TransactionCatLevel.category, category: "Credit Card Payment")]
                let accounts = financeService.accounts.filter({ $0.type == .creditCard})
                let filterAccounts = accounts.map({ $0.guid })
                financeDetailService.getSamples(for: range, accountDetails: nil, transactionDetails: transactionDetails, accounts: nil, transactions: financeService.transactions, filterAccounts: filterAccounts, ignore_plot_created: nil, ignore_transfer_between_accounts: false) { stat, _, transactions, err in
                    guard let stat = stat, let transactions = transactions else {
                        completion(nil)
                        return
                    }
                    var finalStat = stat
                    let transactionAccounts = Set(transactions.map({ $0.account_guid ?? "" }))
                    let difference = transactionAccounts.symmetricDifference(Set(filterAccounts))
                    let accts = self.financeService.accounts.filter({ difference.contains($0.guid) && $0.balance > 0 })
                    finalStat.value = accts.map({$0.balance}).reduce(0, +)
                    if finalStat.value <= 0, let transaction = transactions.first {
                        finalStat.date = ISO8601DateFormatter().date(from: transaction.transacted_at) ?? Date()
                    }
                    completion(finalStat)
                }
            } else {
                var accountDetails = [AccountDetails]()
                switch submetric {
                case nil, .some(.none):
                    break
                case .some(.group):
                    for opt in option ?? [] {
                        let accountDetail = AccountDetails(name: opt, balance: 0, level: submetric?.accountCatLevel ?? .bs_type, bs_type: BalanceSheetType(rawValue: opt))
                        accountDetails.append(accountDetail)
                    }
                    
                case .some(.category):
                    for opt in option ?? [] {
                        let accountDetail = AccountDetails(name: opt, balance: 0, level: submetric?.accountCatLevel ?? .bs_type, type: MXAccountType(rawValue: opt))
                        accountDetails.append(accountDetail)
                    }
                    
                case .some(.subcategory):
                    for opt in option ?? [] {
                        let accountDetail = AccountDetails(name: opt, balance: 0, level: submetric?.accountCatLevel ?? .bs_type, subtype: MXAccountSubType(rawValue: opt))
                        accountDetails.append(accountDetail)
                    }
                }
                
                financeDetailService.getSamples(for: range, accountDetails: accountDetails, transactionDetails: nil, accounts: financeService.accounts, transactions: nil, filterAccounts: nil, ignore_plot_created: nil, ignore_transfer_between_accounts: nil) { stat, accounts, _, err in
                    guard let stat = stat, let accounts = accounts else {
                        completion(nil)
                        return
                    }
                    
                    var finalStat = stat
                    switch unit {
                    case .count:
                        finalStat.value = Double(accounts.count)
                        completion(finalStat)
                    case .amount:
                        completion(finalStat)
                    case .hours, .minutes, .days, .calories, .percent, .multiple, .level:
                        completion(nil)
                    }
                }
            }
            
            
        case .workout:
            healthDetailService.getSamples(for: healthService.workouts, measure: unit.workoutMeasure ?? .duration, categories: option, range: range) {stat, workouts,_ in
                guard let stat = stat, let workouts = workouts else {
                    completion(nil)
                    return
                }
                
                var finalStat = stat
                switch unit {
                case .count:
                    finalStat.value = Double(workouts.count)
                    completion(finalStat)
                case .minutes:
                    completion(finalStat)
                case .calories:
                    completion(finalStat)
                case .hours, .days, .amount, .percent, .multiple, .level:
                    completion(nil)
                }
            }
            
        case .mindfulness:
            healthDetailService.getSamples(for: healthService.mindfulnesses, range: range) {stat, mindfulnesses,_ in
                guard let stat = stat, let mindfulnesses = mindfulnesses else {
                    completion(nil)
                    return
                }
                var finalStat = stat
                switch unit {
                case .count:
                    finalStat.value = Double(mindfulnesses.count)
                    completion(finalStat)
                case .minutes:
                    completion(finalStat)
                case .hours, .days, .calories, .amount, .percent, .multiple, .level:
                    completion(nil)
                }

            }
        case .mood:
            healthDetailService.getSamples(for: healthService.moods, types: option, range: range) {stat, moods,_ in
                guard let stat = stat, let moods = moods else {
                    completion(nil)
                    return
                }
                var finalStat = stat
                switch unit {
                case .count:
                    finalStat.value = Double(moods.count)
                    completion(finalStat)
                case .hours, .days, .calories, .amount, .percent, .multiple, .level, .minutes:
                    completion(nil)
                }
            }
        case .sleep:
            guard let generalMetrics = healthService.healthMetrics[.general], let healthMetric = generalMetrics.first(where: {$0.type == .sleep}) else {
                print(".sleep completion(nil)")
                completion(nil)
                return
            }
            healthDetailService.getSamples(for: healthMetric, range: range) { stat, samples, _ in
                completion(stat)
            }
        case .steps:
            guard let generalMetrics = healthService.healthMetrics[.general], let healthMetric = generalMetrics.first(where: {$0.type == .steps}) else {
                completion(nil)
                return
            }
            healthDetailService.getSamples(for: healthMetric, range: range) { stat, samples, _ in
                completion(stat)
            }
        case .flightsClimbed:
            guard let generalMetrics = healthService.healthMetrics[.general], let healthMetric = generalMetrics.first(where: {$0.type == .flightsClimbed}) else {
                completion(nil)
                return
            }
            healthDetailService.getSamples(for: healthMetric, range: range) { stat, samples, _ in
                completion(stat)
            }
        case .activeCalories:
            guard let workoutsMetrics = healthService.healthMetrics[.workouts], let healthMetric = workoutsMetrics.first(where: {$0.type == .activeEnergy}) else {
                completion(nil)
                return
            }
            healthDetailService.getSamples(for: healthMetric, range: range) { stat, samples, _ in
                completion(stat)
            }
        }
    }
    
    func setupInitialTimeGoals() {
        if let currentUserID = Auth.auth().currentUser?.uid, let lists = activityService.lists[ListSourceOptions.plot.name] {
            for g in prebuiltGoalsTime {
                var goal = g
                let activityID = Database.database().reference().child(userActivitiesEntity).child(currentUserID).childByAutoId().key ?? ""
                let category = goal.category
                let subcategory = goal.subcategory
                
                var list: ListType?
                if category == .finances, let newList = lists.first(where: { $0.financeList ?? false }) {
                    list = newList
                } else if category == .health, let newList = lists.first(where: { $0.healthList ?? false }) {
                    list = newList
                } else if let newList = lists.first(where: { $0.defaultList ?? false }) {
                    list = newList
                }
                
                if let list = list {
                    var date = Date().dayBefore
                    let task = Activity(activityID: activityID, admin: currentUserID, listID: list.id ?? "", listName: list.name ?? "", listColor: list.color ?? CIColor(color: ChartColors.palette()[5]).stringRepresentation, listSource: list.source ?? "", isCompleted: false, createdDate: NSNumber(value: Int((date).timeIntervalSince1970)))
                    task.name = goal.name
                    task.isGoal = true
                    
                    let group = DispatchGroup()
                    if goal.targetNumber == nil {
                        group.enter()
                        if goal.name == "Save Emergency Fund" {
                            let startOfThreeMonthsAgo = Date().startOfMonth.monthBefore.monthBefore.monthBefore
                            let endOfLastMonth = Date().endOfMonth.monthBefore
                            checkGoal(metric: GoalMetric.financialTransactions, submetric: GoalSubMetric.group, option: ["Expense"], unit: GoalUnit.amount, range: DateRange(startDate: startOfThreeMonthsAgo, endDate: endOfLastMonth)) { stat in
                                goal.targetNumber = round(stat?.value ?? 0)
                                group.leave()
                            }
                        } else if goal.name == "Monthly Savings" {
                            let startOfThreeMonthsAgo = Date().startOfMonth.monthBefore.monthBefore.monthBefore
                            let endOfLastMonth = Date().endOfMonth.monthBefore
                            checkGoal(metric: GoalMetric.financialTransactions, submetric: GoalSubMetric.group, option: ["Income"], unit: GoalUnit.amount, range: DateRange(startDate: startOfThreeMonthsAgo, endDate: endOfLastMonth)) { stat in
                                goal.targetNumber = round((stat?.value ?? 0 * 0.2) / 3)
                                group.leave()
                            }
                        } else if goal.name == "Daily Spending" {
                            let startOfThreeMonthsAgo = Date().startOfMonth.monthBefore.monthBefore.monthBefore
                            let endOfLastMonth = Date().endOfMonth.monthBefore
                            let daysBetween = Double(Calendar.current.numberOfDaysBetween(startOfThreeMonthsAgo, and: endOfLastMonth))
                            checkGoal(metric: GoalMetric.financialTransactions, submetric: GoalSubMetric.group, option: ["Income"], unit: GoalUnit.amount, range: DateRange(startDate: startOfThreeMonthsAgo, endDate: endOfLastMonth)) { stat in
                                goal.targetNumber = round((stat?.value ?? 0 * 0.8) / daysBetween)
                                group.leave()
                            }
                        }
                    }
                    
                    group.notify(queue: .global()) {
                        task.goal = goal
                        task.category = category.rawValue
                        task.subcategory = subcategory.rawValue
                        if let frequency = goal.frequency, let recurrenceFrequency = frequency.recurrenceFrequency {
                            var recurrenceRule = RecurrenceRule(frequency: recurrenceFrequency)
                            let calendar = Calendar.current

                            switch recurrenceRule.frequency {
                            case .yearly:
                                date = date.startOfYear.UTCTime
                                let month = calendar.component(.month, from: date)
                                recurrenceRule = RecurrenceRule.yearlyRecurrence(withMonth: month)
                                task.endDateTime = NSNumber(value: Int((date.endOfYear.advanced(by: -1).UTCTime).timeIntervalSince1970))
                            case .monthly:
                                // monthly needs UTCTime in order for recurrence to calc the correct dates
                                date = date.startOfMonth.UTCTime
                                let monthday = calendar.component(.day, from: date)
                                recurrenceRule = RecurrenceRule.monthlyRecurrence(withMonthday: monthday)
                                task.endDateTime = NSNumber(value: Int((date.endOfMonth.advanced(by: -1).UTCTime).timeIntervalSince1970))
                                recurrenceRule.bymonthday = [1]
                            case .weekly:
                                date = date.startOfWeek.UTCTime
                                let weekday = EKWeekday(rawValue: calendar.component(.weekday, from: date))!
                                recurrenceRule = RecurrenceRule.weeklyRecurrence(withWeekday: weekday)
                                task.endDateTime = NSNumber(value: Int((date.endOfWeek.advanced(by: -1).UTCTime).timeIntervalSince1970))
                            case .daily:
                                date = date.startOfDay.UTCTime
                                recurrenceRule = RecurrenceRule.dailyRecurrence()
                                task.endDateTime = NSNumber(value: Int((date.endOfDay.advanced(by: -1).UTCTime).timeIntervalSince1970))
                            case .hourly, .minutely, .secondly:
                                break
                            }
                            
                            task.hasStartTime = false
                            task.hasDeadlineTime = false
                            task.startDateTime = NSNumber(value: Int((date).timeIntervalSince1970))
                            
                            recurrenceRule.startDate = date
                            recurrenceRule.interval = goal.name != "Bi-Annual Dental Cleaning" ? 1 : 2
                            task.recurrences = [recurrenceRule.toRRuleString()]
                            
                            if goal.name == "Daily Mood" {
                                task.reminder = TaskAlert.SixPMOnDeadlineDate.description
                            } else if frequency == .monthly {
                                task.reminder = TaskAlert.NineAMOneWeekBeforeDeadlineDate.description
                            } else if frequency == .yearly {
                                task.reminder = TaskAlert.NineAMOneMonthBeforeDeadlineDate.description
                            } else if goal.name != "Daily Sleep" {
                                task.reminder = TaskAlert.NineAMOnDeadlineDate.description
                            }
                        }
                        
                        let activityAction = ActivityActions(activity: task, active: false, selectedFalconUsers: [])
                        activityAction.createNewActivity(updateDirectAssociation: false)

                    }
                }
            }
        }
    }
    
    func setupInitialHealthGoals() {
        if let currentUserID = Auth.auth().currentUser?.uid, let lists = activityService.lists[ListSourceOptions.plot.name] {
            for g in prebuiltGoalsHealth {
                var goal = g
                let activityID = Database.database().reference().child(userActivitiesEntity).child(currentUserID).childByAutoId().key ?? ""
                let category = goal.category
                let subcategory = goal.subcategory
                
                var list: ListType?
                if category == .finances, let newList = lists.first(where: { $0.financeList ?? false }) {
                    list = newList
                } else if category == .health, let newList = lists.first(where: { $0.healthList ?? false }) {
                    list = newList
                } else if let newList = lists.first(where: { $0.defaultList ?? false }) {
                    list = newList
                }
                
                if let list = list {
                    var date = Date().dayBefore
                    let task = Activity(activityID: activityID, admin: currentUserID, listID: list.id ?? "", listName: list.name ?? "", listColor: list.color ?? CIColor(color: ChartColors.palette()[5]).stringRepresentation, listSource: list.source ?? "", isCompleted: false, createdDate: NSNumber(value: Int((date).timeIntervalSince1970)))
                    task.name = goal.name
                    task.isGoal = true
                    
                    let group = DispatchGroup()
                    if goal.targetNumber == nil {
                        group.enter()
                        if goal.name == "Save Emergency Fund" {
                            let startOfThreeMonthsAgo = Date().startOfMonth.monthBefore.monthBefore.monthBefore
                            let endOfLastMonth = Date().endOfMonth.monthBefore
                            checkGoal(metric: GoalMetric.financialTransactions, submetric: GoalSubMetric.group, option: ["Expense"], unit: GoalUnit.amount, range: DateRange(startDate: startOfThreeMonthsAgo, endDate: endOfLastMonth)) { stat in
                                goal.targetNumber = round(stat?.value ?? 0)
                                group.leave()
                            }
                        } else if goal.name == "Monthly Savings" {
                            let startOfThreeMonthsAgo = Date().startOfMonth.monthBefore.monthBefore.monthBefore
                            let endOfLastMonth = Date().endOfMonth.monthBefore
                            checkGoal(metric: GoalMetric.financialTransactions, submetric: GoalSubMetric.group, option: ["Income"], unit: GoalUnit.amount, range: DateRange(startDate: startOfThreeMonthsAgo, endDate: endOfLastMonth)) { stat in
                                goal.targetNumber = round((stat?.value ?? 0 * 0.2) / 3)
                                group.leave()
                            }
                        } else if goal.name == "Daily Spending" {
                            let startOfThreeMonthsAgo = Date().startOfMonth.monthBefore.monthBefore.monthBefore
                            let endOfLastMonth = Date().endOfMonth.monthBefore
                            let daysBetween = Double(Calendar.current.numberOfDaysBetween(startOfThreeMonthsAgo, and: endOfLastMonth))
                            checkGoal(metric: GoalMetric.financialTransactions, submetric: GoalSubMetric.group, option: ["Income"], unit: GoalUnit.amount, range: DateRange(startDate: startOfThreeMonthsAgo, endDate: endOfLastMonth)) { stat in
                                goal.targetNumber = round((stat?.value ?? 0 * 0.8) / daysBetween)
                                group.leave()
                            }
                        }
                    }
                    
                    group.notify(queue: .global()) {
                        task.goal = goal
                        task.category = category.rawValue
                        task.subcategory = subcategory.rawValue
                        if let frequency = goal.frequency, let recurrenceFrequency = frequency.recurrenceFrequency {
                            var recurrenceRule = RecurrenceRule(frequency: recurrenceFrequency)
                            let calendar = Calendar.current

                            switch recurrenceRule.frequency {
                            case .yearly:
                                date = date.startOfYear.UTCTime
                                let month = calendar.component(.month, from: date)
                                recurrenceRule = RecurrenceRule.yearlyRecurrence(withMonth: month)
                                task.endDateTime = NSNumber(value: Int((date.endOfYear.advanced(by: -1).UTCTime).timeIntervalSince1970))
                            case .monthly:
                                // monthly needs UTCTime in order for recurrence to calc the correct dates
                                date = date.startOfMonth.UTCTime
                                let monthday = calendar.component(.day, from: date)
                                recurrenceRule = RecurrenceRule.monthlyRecurrence(withMonthday: monthday)
                                task.endDateTime = NSNumber(value: Int((date.endOfMonth.advanced(by: -1).UTCTime).timeIntervalSince1970))
                                recurrenceRule.bymonthday = [1]
                            case .weekly:
                                date = date.startOfWeek.UTCTime
                                let weekday = EKWeekday(rawValue: calendar.component(.weekday, from: date))!
                                recurrenceRule = RecurrenceRule.weeklyRecurrence(withWeekday: weekday)
                                task.endDateTime = NSNumber(value: Int((date.endOfWeek.advanced(by: -1).UTCTime).timeIntervalSince1970))
                            case .daily:
                                date = date.startOfDay.UTCTime
                                recurrenceRule = RecurrenceRule.dailyRecurrence()
                                task.endDateTime = NSNumber(value: Int((date.endOfDay.advanced(by: -1).UTCTime).timeIntervalSince1970))
                            case .hourly, .minutely, .secondly:
                                break
                            }
                            
                            task.hasStartTime = false
                            task.hasDeadlineTime = false
                            task.startDateTime = NSNumber(value: Int((date).timeIntervalSince1970))
                            
                            recurrenceRule.startDate = date
                            recurrenceRule.interval = goal.name != "Bi-Annual Dental Cleaning" ? 1 : 2
                            task.recurrences = [recurrenceRule.toRRuleString()]
                            
                            if goal.name == "Daily Mood" {
                                task.reminder = TaskAlert.SixPMOnDeadlineDate.description
                            } else if frequency == .monthly {
                                task.reminder = TaskAlert.NineAMOneWeekBeforeDeadlineDate.description
                            } else if frequency == .yearly {
                                task.reminder = TaskAlert.NineAMOneMonthBeforeDeadlineDate.description
                            } else if goal.name != "Daily Sleep" {
                                task.reminder = TaskAlert.NineAMOnDeadlineDate.description
                            }
                        }
                        
                        let activityAction = ActivityActions(activity: task, active: false, selectedFalconUsers: [])
                        activityAction.createNewActivity(updateDirectAssociation: false)

                    }
                }
            }
        }
    }
    
    func setupInitialFinanceGoals() {
        if let currentUserID = Auth.auth().currentUser?.uid, let lists = activityService.lists[ListSourceOptions.plot.name] {
            for g in prebuiltGoalsFinances {
                var goal = g
                let activityID = Database.database().reference().child(userActivitiesEntity).child(currentUserID).childByAutoId().key ?? ""
                let category = goal.category
                let subcategory = goal.subcategory
                
                var list: ListType?
                if category == .finances, let newList = lists.first(where: { $0.financeList ?? false }) {
                    list = newList
                } else if category == .health, let newList = lists.first(where: { $0.healthList ?? false }) {
                    list = newList
                } else if let newList = lists.first(where: { $0.defaultList ?? false }) {
                    list = newList
                }
                
                if let list = list {
                    var date = Date().dayBefore
                    let task = Activity(activityID: activityID, admin: currentUserID, listID: list.id ?? "", listName: list.name ?? "", listColor: list.color ?? CIColor(color: ChartColors.palette()[5]).stringRepresentation, listSource: list.source ?? "", isCompleted: false, createdDate: NSNumber(value: Int((date).timeIntervalSince1970)))
                    task.name = goal.name
                    task.isGoal = true
                    
                    let group = DispatchGroup()
                    if goal.targetNumber == nil {
                        group.enter()
                        if goal.name == "Save Emergency Fund" {
                            let startOfThreeMonthsAgo = Date().startOfMonth.monthBefore.monthBefore.monthBefore
                            let endOfLastMonth = Date().endOfMonth.monthBefore
                            checkGoal(metric: GoalMetric.financialTransactions, submetric: GoalSubMetric.group, option: ["Expense"], unit: GoalUnit.amount, range: DateRange(startDate: startOfThreeMonthsAgo, endDate: endOfLastMonth)) { stat in
                                goal.targetNumber = round(stat?.value ?? 0)
                                group.leave()
                            }
                        } else if goal.name == "Monthly Savings" {
                            let startOfThreeMonthsAgo = Date().startOfMonth.monthBefore.monthBefore.monthBefore
                            let endOfLastMonth = Date().endOfMonth.monthBefore
                            checkGoal(metric: GoalMetric.financialTransactions, submetric: GoalSubMetric.group, option: ["Income"], unit: GoalUnit.amount, range: DateRange(startDate: startOfThreeMonthsAgo, endDate: endOfLastMonth)) { stat in
                                goal.targetNumber = round((stat?.value ?? 0 * 0.2) / 3)
                                group.leave()
                            }
                        } else if goal.name == "Daily Spending" {
                            let startOfThreeMonthsAgo = Date().startOfMonth.monthBefore.monthBefore.monthBefore
                            let endOfLastMonth = Date().endOfMonth.monthBefore
                            let daysBetween = Double(Calendar.current.numberOfDaysBetween(startOfThreeMonthsAgo, and: endOfLastMonth))
                            checkGoal(metric: GoalMetric.financialTransactions, submetric: GoalSubMetric.group, option: ["Income"], unit: GoalUnit.amount, range: DateRange(startDate: startOfThreeMonthsAgo, endDate: endOfLastMonth)) { stat in
                                goal.targetNumber = round((stat?.value ?? 0 * 0.8) / daysBetween)
                                group.leave()
                            }
                        }
                    }
                    
                    group.notify(queue: .global()) {
                        task.goal = goal
                        task.category = category.rawValue
                        task.subcategory = subcategory.rawValue
                        if let frequency = goal.frequency, let recurrenceFrequency = frequency.recurrenceFrequency {
                            var recurrenceRule = RecurrenceRule(frequency: recurrenceFrequency)
                            let calendar = Calendar.current

                            switch recurrenceRule.frequency {
                            case .yearly:
                                date = date.startOfYear.UTCTime
                                let month = calendar.component(.month, from: date)
                                recurrenceRule = RecurrenceRule.yearlyRecurrence(withMonth: month)
                                task.endDateTime = NSNumber(value: Int((date.endOfYear.advanced(by: -1).UTCTime).timeIntervalSince1970))
                            case .monthly:
                                // monthly needs UTCTime in order for recurrence to calc the correct dates
                                date = date.startOfMonth.UTCTime
                                let monthday = calendar.component(.day, from: date)
                                recurrenceRule = RecurrenceRule.monthlyRecurrence(withMonthday: monthday)
                                task.endDateTime = NSNumber(value: Int((date.endOfMonth.advanced(by: -1).UTCTime).timeIntervalSince1970))
                                recurrenceRule.bymonthday = [1]
                            case .weekly:
                                date = date.startOfWeek.UTCTime
                                let weekday = EKWeekday(rawValue: calendar.component(.weekday, from: date))!
                                recurrenceRule = RecurrenceRule.weeklyRecurrence(withWeekday: weekday)
                                task.endDateTime = NSNumber(value: Int((date.endOfWeek.advanced(by: -1).UTCTime).timeIntervalSince1970))
                            case .daily:
                                date = date.startOfDay.UTCTime
                                recurrenceRule = RecurrenceRule.dailyRecurrence()
                                task.endDateTime = NSNumber(value: Int((date.endOfDay.advanced(by: -1).UTCTime).timeIntervalSince1970))
                            case .hourly, .minutely, .secondly:
                                break
                            }
                            
                            task.hasStartTime = false
                            task.hasDeadlineTime = false
                            task.startDateTime = NSNumber(value: Int((date).timeIntervalSince1970))
                            
                            recurrenceRule.startDate = date
                            recurrenceRule.interval = goal.name != "Bi-Annual Dental Cleaning" ? 1 : 2
                            task.recurrences = [recurrenceRule.toRRuleString()]
                            
                            if goal.name == "Daily Mood" {
                                task.reminder = TaskAlert.SixPMOnDeadlineDate.description
                            } else if frequency == .monthly {
                                task.reminder = TaskAlert.NineAMOneWeekBeforeDeadlineDate.description
                            } else if frequency == .yearly {
                                task.reminder = TaskAlert.NineAMOneMonthBeforeDeadlineDate.description
                            } else if goal.name != "Daily Sleep" {
                                task.reminder = TaskAlert.NineAMOnDeadlineDate.description
                            }
                        }
                        
                        let activityAction = ActivityActions(activity: task, active: false, selectedFalconUsers: [])
                        activityAction.createNewActivity(updateDirectAssociation: false)

                    }
                }
            }
        }
    }
    
    func setupInitialGoals() {
        print("setupInitialGoals")
        if activityService.goals.isEmpty, let currentUserID = Auth.auth().currentUser?.uid, let lists = activityService.lists[ListSourceOptions.plot.name] {
            for g in prebuiltGoals {
                var goal = g
                let activityID = Database.database().reference().child(userActivitiesEntity).child(currentUserID).childByAutoId().key ?? ""
                let category = goal.category
                let subcategory = goal.subcategory
                
                var list: ListType?
                if category == .finances, let currentList = lists.first(where: { $0.financeList ?? false }) {
                    list = currentList
                } else if category == .health, let currentList = lists.first(where: { $0.healthList ?? false }) {
                    list = currentList
                } else if let currentList = lists.first(where: { $0.defaultList ?? false }) {
                    list = currentList
                }
                
                if let list = list {
                    var date = Date().dayBefore
                    let task = Activity(activityID: activityID, admin: currentUserID, listID: list.id ?? "", listName: list.name ?? "", listColor: list.color ?? CIColor(color: ChartColors.palette()[5]).stringRepresentation, listSource: list.source ?? "", isCompleted: false, createdDate: NSNumber(value: Int((date).timeIntervalSince1970)))
                    task.name = goal.name
                    task.isGoal = true
                    
                    let group = DispatchGroup()
                    if goal.targetNumber == nil {
                        group.enter()
                        if goal.name == "Save Emergency Fund" {
                            let startOfThreeMonthsAgo = Date().startOfMonth.monthBefore.monthBefore.monthBefore
                            let endOfLastMonth = Date().endOfMonth.monthBefore
                            checkGoal(metric: GoalMetric.financialTransactions, submetric: GoalSubMetric.group, option: ["Expense"], unit: GoalUnit.amount, range: DateRange(startDate: startOfThreeMonthsAgo, endDate: endOfLastMonth)) { stat in
                                goal.targetNumber = round(stat?.value ?? 0)
                                group.leave()
                            }
                        } else if goal.name == "Monthly Savings" {
                            let startOfThreeMonthsAgo = Date().startOfMonth.monthBefore.monthBefore.monthBefore
                            let endOfLastMonth = Date().endOfMonth.monthBefore
                            checkGoal(metric: GoalMetric.financialTransactions, submetric: GoalSubMetric.group, option: ["Income"], unit: GoalUnit.amount, range: DateRange(startDate: startOfThreeMonthsAgo, endDate: endOfLastMonth)) { stat in
                                goal.targetNumber = round((stat?.value ?? 0 * 0.2) / 3)
                                group.leave()
                            }
                        } else if goal.name == "Daily Spending" {
                            let startOfThreeMonthsAgo = Date().startOfMonth.monthBefore.monthBefore.monthBefore
                            let endOfLastMonth = Date().endOfMonth.monthBefore
                            let daysBetween = Double(Calendar.current.numberOfDaysBetween(startOfThreeMonthsAgo, and: endOfLastMonth))
                            checkGoal(metric: GoalMetric.financialTransactions, submetric: GoalSubMetric.group, option: ["Income"], unit: GoalUnit.amount, range: DateRange(startDate: startOfThreeMonthsAgo, endDate: endOfLastMonth)) { stat in
                                goal.targetNumber = round((stat?.value ?? 0 * 0.8) / daysBetween)
                                group.leave()
                            }
                        }
                    }
                    
                    group.notify(queue: .global()) {
                        task.goal = goal
                        task.category = category.rawValue
                        task.subcategory = subcategory.rawValue
                        if let frequency = goal.frequency, let recurrenceFrequency = frequency.recurrenceFrequency {
                            var recurrenceRule = RecurrenceRule(frequency: recurrenceFrequency)
                            let calendar = Calendar.current

                            switch recurrenceRule.frequency {
                            case .yearly:
                                date = date.startOfYear.UTCTime
                                let month = calendar.component(.month, from: date)
                                recurrenceRule = RecurrenceRule.yearlyRecurrence(withMonth: month)
                                task.endDateTime = NSNumber(value: Int((date.endOfYear.advanced(by: -1).UTCTime).timeIntervalSince1970))
                            case .monthly:
                                // monthly needs UTCTime in order for recurrence to calc the correct dates
                                date = date.startOfMonth.UTCTime
                                let monthday = calendar.component(.day, from: date)
                                recurrenceRule = RecurrenceRule.monthlyRecurrence(withMonthday: monthday)
                                task.endDateTime = NSNumber(value: Int((date.endOfMonth.advanced(by: -1).UTCTime).timeIntervalSince1970))
                                recurrenceRule.bymonthday = [1]
                            case .weekly:
                                date = date.startOfWeek.UTCTime
                                let weekday = EKWeekday(rawValue: calendar.component(.weekday, from: date))!
                                recurrenceRule = RecurrenceRule.weeklyRecurrence(withWeekday: weekday)
                                task.endDateTime = NSNumber(value: Int((date.endOfWeek.advanced(by: -1).UTCTime).timeIntervalSince1970))
                            case .daily:
                                date = date.startOfDay.UTCTime
                                recurrenceRule = RecurrenceRule.dailyRecurrence()
                                task.endDateTime = NSNumber(value: Int((date.endOfDay.advanced(by: -1).UTCTime).timeIntervalSince1970))
                            case .hourly, .minutely, .secondly:
                                break
                            }
                            
                            task.hasStartTime = false
                            task.hasDeadlineTime = false
                            task.startDateTime = NSNumber(value: Int((date).timeIntervalSince1970))
                            
                            recurrenceRule.startDate = date
                            recurrenceRule.interval = goal.name != "Bi-Annual Dental Cleaning" ? 1 : 2
                            task.recurrences = [recurrenceRule.toRRuleString()]
                            
                            if goal.name == "Daily Mood" {
                                task.reminder = TaskAlert.SixPMOnDeadlineDate.description
                            } else if frequency == .monthly {
                                task.reminder = TaskAlert.NineAMOneWeekBeforeDeadlineDate.description
                            } else if frequency == .yearly {
                                task.reminder = TaskAlert.NineAMOneMonthBeforeDeadlineDate.description
                            } else if goal.name != "Daily Sleep" {
                                task.reminder = TaskAlert.NineAMOnDeadlineDate.description
                            }
                                         
//                            print("setup initial goal")
//                            print(task.name)
//                            print(task.startDate)
//                            print(task.endDate)
//                            print(task.startDateTime)
//                            print(task.endDateTime)
//                            print(recurrenceRule.toRRuleString())
//                            print(task.reminder)
                        }
                        
                        let activityAction = ActivityActions(activity: task, active: false, selectedFalconUsers: [])
                        activityAction.createNewActivity(updateDirectAssociation: false)

                    }
                }
            }
        }
    }
    
    func deleteGoals() {
        for task in activityService.goalsNoRepeats {
            let activityAction = ActivityActions(activity: task, active: true, selectedFalconUsers: [])
            activityAction.deleteActivity(updateExternal: true, updateDirectAssociation: false)
        }
    }
}

//                        print("finished checking")
//                        print(range.startDate)
//                        print(range.endDate)
//
//                        print("metricCheck First")
//                        print(metric)
//                        print(goal.submetric)
//                        print(goal.option)
//                        print(finalStat.date)
//                        print(finalStat.value)
//                        print(target)
//
//                        print("metricCheck Second")
//                        print(metricSecond)
//                        print(goal.submetricSecond)
//                        print(goal.optionSecond)
//                        print(finalStatSecond.date)
//                        print(finalStatSecond.value)
//                        print(targetSecond)

    
//                    print("finished checking")
//                    print(range.startDate)
//                    print(range.endDate)
//
//                    print("metricCheck First")
//                    print(metric)
//                    print(goal.submetric)
//                    print(goal.option)
//                    print(finalStat.date)
//                    print(finalStat.value)
//                    print(target)

    
// task.completedDate = finalStat.date > finalStatSecond.date ? NSNumber(value: Int((finalStat.date).timeIntervalSince1970)) : NSNumber(value: Int((finalStatSecond.date).timeIntervalSince1970))

  
