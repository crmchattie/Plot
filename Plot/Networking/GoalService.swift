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
        let tomorrow = Date().dayAfter
        let group = DispatchGroup()
        
        for task in activityService.goals {
            group.enter()
            guard !(task.completeUpdatedByUser ?? false), let goal = task.goal, let metric = goal.metric, let unit = goal.unit, let target = goal.targetNumber else {
                group.leave()
                continue
            }
                        
            let range = DateRange(startDate: task.goalStartDate, endDate: task.goalEndDate)
            guard range.endDate > past, range.startDate <= tomorrow else {
                group.leave()
                continue
            }
            
//            print("metricCheck")
//            print(metric)
//            print(task.goalStartDate)
//            print(task.goalEndDate)
                                        
            checkGoal(metric: metric, submetric: goal.submetric, option: goal.option, unit: unit, range: range) { stat in
                var finalStat = Statistic(date: range.startDate, value: 0)
                if let stat = stat {
                    finalStat = stat
                }

                if let metricsRelationshipType = goal.metricsRelationshipType, let metricSecond = goal.metricSecond, let unitSecond = goal.unitSecond, let targetSecond = goal.targetNumberSecond {
                    self.checkGoal(metric: metricSecond, submetric: goal.submetricSecond, option: goal.optionSecond, unit: unitSecond, range: range) { statSecond in
                        var finalStatSecond = Statistic(date: range.startDate, value: 0)
                        if let statSecond = statSecond {
                            finalStatSecond = statSecond
                        }
                        
                        switch metricsRelationshipType {
                        case .or:
                            if (finalStat.value >= target && (goal.currentNumber != finalStat.value || !(task.isCompleted ?? false))) || (finalStatSecond.value >= targetSecond && (goal.currentNumberSecond != finalStatSecond.value || !(task.isCompleted ?? false))) {
                                task.completedDate = NSNumber(value: Int((range.endDate).timeIntervalSince1970))
                                let updateTask = ActivityActions(activity: task, active: true, selectedFalconUsers: [])
                                updateTask.updateCompletion(isComplete: true, completeUpdatedByUser: false, goalCurrentNumber: finalStat.value as NSNumber, goalCurrentNumberSecond: finalStatSecond.value as NSNumber)
                            } else if (finalStat.value < target && (goal.currentNumber != finalStat.value || task.isCompleted ?? false)) && (finalStatSecond.value < targetSecond && (goal.currentNumberSecond != finalStatSecond.value || task.isCompleted ?? false)) {
                                let updateTask = ActivityActions(activity: task, active: true, selectedFalconUsers: [])
                                updateTask.updateCompletion(isComplete: false, completeUpdatedByUser: false, goalCurrentNumber: finalStat.value as NSNumber, goalCurrentNumberSecond: finalStatSecond.value as NSNumber)
                            } else if goal.currentNumber != finalStat.value || goal.currentNumberSecond != finalStatSecond.value {
                                let updateTask = ActivityActions(activity: task, active: true, selectedFalconUsers: [])
                                updateTask.updateCompletion(isComplete: task.isCompleted ?? false, completeUpdatedByUser: false, goalCurrentNumber: finalStat.value as NSNumber, goalCurrentNumberSecond: finalStatSecond.value as NSNumber)
                            }

                        case .and:
                            if (finalStat.value >= target && (goal.currentNumber != finalStat.value || !(task.isCompleted ?? false))) && (finalStatSecond.value >= targetSecond && (goal.currentNumberSecond != finalStatSecond.value || !(task.isCompleted ?? false))) {
                                task.completedDate = NSNumber(value: Int((range.endDate).timeIntervalSince1970))
                                let updateTask = ActivityActions(activity: task, active: true, selectedFalconUsers: [])
                                updateTask.updateCompletion(isComplete: true, completeUpdatedByUser: false, goalCurrentNumber: finalStat.value as NSNumber, goalCurrentNumberSecond: finalStatSecond.value as NSNumber)
                            } else if (finalStat.value < target && (goal.currentNumber != finalStat.value || task.isCompleted ?? false)) || (finalStatSecond.value < targetSecond && (goal.currentNumberSecond != finalStatSecond.value || task.isCompleted ?? false)) {
                                let updateTask = ActivityActions(activity: task, active: true, selectedFalconUsers: [])
                                updateTask.updateCompletion(isComplete: false, completeUpdatedByUser: false, goalCurrentNumber: finalStat.value as NSNumber, goalCurrentNumberSecond: finalStatSecond.value as NSNumber)
                            } else if goal.currentNumber != finalStat.value || goal.currentNumberSecond != finalStatSecond.value {
                                let updateTask = ActivityActions(activity: task, active: true, selectedFalconUsers: [])
                                updateTask.updateCompletion(isComplete: task.isCompleted ?? false, completeUpdatedByUser: false, goalCurrentNumber: finalStat.value as NSNumber, goalCurrentNumberSecond: finalStatSecond.value as NSNumber)
                            }

                        //not in use yet
                        case .equal, .more, .less:
                            break
                        }
                        group.leave()
                    }
                } else {
                    if finalStat.value >= target && (goal.currentNumber != finalStat.value || !(task.isCompleted ?? false)) {
                        task.completedDate = NSNumber(value: Int((range.endDate).timeIntervalSince1970))
                        let updateTask = ActivityActions(activity: task, active: true, selectedFalconUsers: [])
                        updateTask.updateCompletion(isComplete: true, completeUpdatedByUser: false, goalCurrentNumber: finalStat.value as NSNumber, goalCurrentNumberSecond: nil)
                    } else if finalStat.value < target && (goal.currentNumber != finalStat.value || task.isCompleted ?? false) {
                        let updateTask = ActivityActions(activity: task, active: true, selectedFalconUsers: [])
                        updateTask.updateCompletion(isComplete: false, completeUpdatedByUser: false, goalCurrentNumber: finalStat.value as NSNumber, goalCurrentNumberSecond: nil)
                    } else if goal.currentNumber != finalStat.value {
                        let updateTask = ActivityActions(activity: task, active: true, selectedFalconUsers: [])
                        updateTask.updateCompletion(isComplete: task.isCompleted ?? false, completeUpdatedByUser: false, goalCurrentNumber: finalStat.value as NSNumber, goalCurrentNumberSecond: nil)
                    }
                    group.leave()
                }
            }
        }
        
        group.notify(queue: .main) {
            completion()
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

    
    func checkGoal(metric: GoalMetric, submetric: GoalSubMetric?, option: [String]?, unit: GoalUnit, range: DateRange, completion: @escaping (Statistic?) -> Void) {
        switch metric {
        case .events:
            activityDetailService.getActivityCategoriesSamples(activities: activityService.events, level: submetric?.activityLevel ?? .none, options: nil, range: range) { stat, activities in
                if let stat = stat, let activities = activities {
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
            }
        case .tasks:
            activityDetailService.getActivityCategoriesSamples(activities: activityService.tasks, level: submetric?.activityLevel ?? .none, options: nil, range: range) { stat, activities in
                if let stat = stat, let activities = activities {
                    var finalStat = stat
                    switch unit {
                    case .count:
                        finalStat.value = Double(activities.count)
                        completion(finalStat)
                    case .hours, .minutes, .days, .calories, .amount, .percent, .multiple, .level:
                        completion(finalStat)
                    }
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
                if let stat = stat, let transactions = transactions {
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
            }
        case .financialAccounts:
            if let option = option, option.count == 1, option.first == "Credit Card" {
                let transactionDetails = [TransactionDetails(name: "Credit Card Payment", amount: 0, level: TransactionCatLevel.category, category: "Credit Card Payment")]
                let accounts = financeService.accounts.filter({ $0.type == .creditCard})
                let filterAccounts = accounts.map({ $0.guid })
                financeDetailService.getSamples(for: range, accountDetails: nil, transactionDetails: transactionDetails, accounts: nil, transactions: financeService.transactions, filterAccounts: filterAccounts, ignore_plot_created: nil, ignore_transfer_between_accounts: false) { stat, _, transactions, err in
                    if let stat = stat, let transactions = transactions {
                        var finalStat = stat
                        let transactionAccounts = Set(transactions.map({ $0.account_guid ?? "" }))
                        let difference = transactionAccounts.symmetricDifference(Set(filterAccounts))
                        let accts = self.financeService.accounts.filter({ difference.contains($0.guid) && $0.balance > 0 })
                        finalStat.value = accts.map({$0.balance}).reduce(0, +) * -1
                        completion(finalStat)
                    } else {
                        completion(nil)
                    }
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
                    if let stat = stat, let accounts = accounts {
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
            }
            
            
        case .workout:
            healthDetailService.getSamples(for: healthService.workouts, measure: unit.workoutMeasure ?? .duration, categories: option, range: range) {stat, workouts,_ in
                completion(stat)
            }
            
        case .mindfulness:
            healthDetailService.getSamples(for: healthService.mindfulnesses, range: range) {stat, mindfulnesses,_ in
                if let stat = stat, let mindfulnesses = mindfulnesses {
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
            }
            
        case .sleep:
            if let generalMetrics = healthService.healthMetrics[.general], let healthMetric = generalMetrics.first(where: {$0.type == .sleep}) {
                healthDetailService.getSamples(for: healthMetric, range: range) { stat, samples, _ in
                    completion(stat)
                }
            }
        case .steps:
            if let generalMetrics = healthService.healthMetrics[.general], let healthMetric = generalMetrics.first(where: {$0.type == .steps}) {
                healthDetailService.getSamples(for: healthMetric, range: range) { stat, samples, _ in
                    completion(stat)
                }
            }
        case .flightsClimbed:
            if let generalMetrics = healthService.healthMetrics[.general], let healthMetric = generalMetrics.first(where: {$0.type == .flightsClimbed}) {
                healthDetailService.getSamples(for: healthMetric, range: range) { stat, samples, _ in
                    completion(stat)
                }
            }
        case .activeCalories:
            if let workoutsMetrics = healthService.healthMetrics[.workouts], let healthMetric = workoutsMetrics.first(where: {$0.type == .activeEnergy}) {
                healthDetailService.getSamples(for: healthMetric, range: range) { stat, samples, _ in
                    completion(stat)
                }
            }
        }
    }
    
    func setupInitialGoals() {
        print("setupInitialGoals")
        if let currentUserID = Auth.auth().currentUser?.uid, let lists = activityService.lists[ListSourceOptions.plot.name] {
            for g in prebuiltGoals {
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
                    var date = Date().weekBefore
                    let task = Activity(activityID: activityID, admin: currentUserID, listID: list.id ?? "", listName: list.name ?? "", listColor: list.color ?? CIColor(color: ChartColors.palette()[5]).stringRepresentation, listSource: list.source ?? "", isCompleted: false, createdDate: NSNumber(value: Int((date).timeIntervalSince1970)))
                    task.name = goal.name
                    task.isGoal = true
                    
                    let group = DispatchGroup()
                    if goal.targetNumber == nil {
                        group.enter()
                        if goal.name == "Save Emergency Fund" {
                            checkGoal(metric: GoalMetric.financialTransactions, submetric: GoalSubMetric.group, option: ["Expense"], unit: GoalUnit.amount, range: DateRange(startDate: Date().startOfMonth.monthBefore.monthBefore.monthBefore, endDate: Date().endOfMonth.monthBefore)) { stat in
                                goal.targetNumber = round(stat?.value ?? 0)
                                group.leave()
                            }
                        } else if goal.name == "Monthly Savings" {
                            checkGoal(metric: GoalMetric.financialTransactions, submetric: GoalSubMetric.group, option: ["Income"], unit: GoalUnit.amount, range: DateRange(startDate: Date().startOfMonth.monthBefore.monthBefore.monthBefore, endDate: Date().endOfMonth.monthBefore)) { stat in
                                goal.targetNumber = round(stat?.value ?? 0 / 3 * 0.2)
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
                                date = date.startOfYear
                                let month = calendar.component(.month, from: date)
                                recurrenceRule = RecurrenceRule.yearlyRecurrence(withMonth: month)
                                task.endDateTime = NSNumber(value: Int((date.endOfYear).timeIntervalSince1970))
                            case .monthly:
                                date = date.startOfMonth.UTCTime
                                let monthday = calendar.component(.day, from: date)
                                recurrenceRule = RecurrenceRule.monthlyRecurrence(withMonthday: monthday)
                                task.endDateTime = NSNumber(value: Int((date.endOfMonth.UTCTime).timeIntervalSince1970))
                                recurrenceRule.bymonthday = [1]
                            case .weekly:
                                date = date.startOfWeek
                                let weekday = EKWeekday(rawValue: calendar.component(.weekday, from: date))!
                                recurrenceRule = RecurrenceRule.weeklyRecurrence(withWeekday: weekday)
                                task.endDateTime = NSNumber(value: Int((date.endOfWeek).timeIntervalSince1970))
                            case .daily:
                                date = date.startOfDay
                                recurrenceRule = RecurrenceRule.dailyRecurrence()
                                task.endDateTime = NSNumber(value: Int((date.endOfDay).timeIntervalSince1970))
                            case .hourly, .minutely, .secondly:
                                break
                            }
                            
                            task.hasStartTime = false
                            task.hasDeadlineTime = false
                            task.startDateTime = NSNumber(value: Int((date).timeIntervalSince1970))
                            
                            recurrenceRule.startDate = date
                            recurrenceRule.interval = goal.name != "Dentist" ? 1 : 2
                            task.recurrences = [recurrenceRule.toRRuleString()]
                            
//                            print(task.name)
//                            print(task.startDate)
//                            print(task.startDateTime)
//                            print(task.endDate)
//                            print(task.endDateTime)
//
//                            print(date)
//                            print(recurrenceRule.toRRuleString())
//                            print(recurrenceRule.occurrences(between: date.dayBefore, and: Date().nextYear))
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
