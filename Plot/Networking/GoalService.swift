//
//  GoalService.swift
//  Plot
//
//  Created by Cory McHattie on 2/4/23.
//  Copyright © 2023 Immature Creations. All rights reserved.
//

import Foundation
import Firebase
import RRuleSwift

extension NetworkController {    
    func checkGoalsForCompletion() {
        print("checkGoalsForCompletion")
        //create loop of existing goals
        //check if goal is complete
        //check if goal has end date
        //if so, check frequency
        //if so, grab start date (= endDate - frequency day interval)
        //grab goal details and check against relevant metric(s)
        //if goal metric is met, update goal to completion; if not, do nothing and move to next goal
        //add check to see if endDate is in the past - maybe add buffer like a month? If so, skip and move to next goal?
        
        let monthPast = Date().monthBefore
        let tomorrow = Date().dayAfter
        for task in activityService.goals {
//            print("--------------------------")
            if let goal = task.goal, let metric = goal.metric, let unit = goal.unit, !(task.isCompleted ?? false) {
                var updatedDescription = goal.description ?? ""
                if let secondaryDescription = goal.descriptionSecondary {
                    updatedDescription += secondaryDescription
                }
//
//                print(updatedDescription)
//                print(monthPast)
//                print(now)
//                print(task.endDate)
//                print(task.startDateGivenEndDateFrequency)
//                print(goal.frequency)
                
                var startDate = Date()
                var endDate = Date()
                
                if let endDateTemp = task.endDate {
                    endDate = endDateTemp
                    if let startDateTemp = task.startDate {
                        startDate = startDateTemp
                    } else if let _ = goal.frequency, let startDateTemp = task.startDateGivenEndDateFrequency {
                        startDate = startDateTemp
                    }
                }
                
                let range = DateRange(startDate: startDate, endDate: endDate)
                if range.endDate > monthPast, range.startDate <= tomorrow {
                    checkGoal(metric: metric, submetric: goal.submetric, option: goal.option, unit: unit, range: range) { double in
                        print("done checking first metric")
                        print(goal.name)
                        print(metric.rawValue)
                        print(double)
                    }
                    if let _ = goal.metricsRelationshipType, let metricSecond = goal.metricSecond, let unitSecond = goal.unitSecond {
                        checkGoal(metric: metricSecond, submetric: goal.submetricSecond, option: goal.optionSecond, unit: unitSecond, range: range) { double in
                            print("done checking second metric")
                            print(goal.name)
                            print(metricSecond.rawValue)
                            print(double)
                        }
                    }
                }
            }
        }
    }
    
    func checkGoal(metric: GoalMetric, submetric: GoalSubMetric?, option: [String]?, unit: GoalUnit, range: DateRange, completion: @escaping (Double) -> Void) {
        print("checkGoal")
        print(metric.rawValue)
        print(submetric?.rawValue)
        print(option)
        print(range.startDate)
        print(range.endDate)
        
        switch metric {
        case .events:
            activityDetailService.getActivityCategoriesSamples(activities: activityService.events, level: submetric?.activityLevel ?? .none, options: nil, range: range) { stat, activities in
                print("events stats")
                print(stat)
                for activity in activities ?? [] {
                    print(activity.name ?? "")
                    print(activity.category ?? "")
                    print(activity.startDate ?? "")
                    print(activity.endDate ?? "")
                }
                completion(stat?.value ?? 0)
            }
        case .tasks:
            activityDetailService.getActivityCategoriesSamples(activities: activityService.events, level: submetric?.activityLevel ?? .none, options: nil, range: range) { stat, activities in
                print("tasks stats")
                print(stat)
                for activity in activities ?? [] {
                    print(activity.name ?? "")
                    print(activity.category ?? "")
                    print(activity.startDate ?? "")
                    print(activity.endDate ?? "")
                }
                completion(stat?.value ?? 0)
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
            
            financeDetailService.getSamples(for: range, accountDetails: nil, transactionDetails: transactionDetails, accounts: nil, transactions: financeService.transactions, filterAccounts: nil) { stat, _, transactions, err in
                print("financialTransactions stats")
                print(stat)
                for transaction in transactions ?? [] {
                    print(transaction.description)
                    print(transaction.group)
                    print(transaction.transacted_at)
                }
                completion(stat?.value ?? 0)
            }
        case .financialAccounts:
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
            
            financeDetailService.getSamples(for: range, accountDetails: accountDetails, transactionDetails: nil, accounts: financeService.accounts, transactions: nil, filterAccounts: nil) { stat, accounts, _, err in
                print("financialAccounts stats")
                print(stat)
                for account in accounts ?? [] {
                    print(account.name)
                    print(account.bs_type)
                    print(account.updated_at)
                }
                completion(stat?.value ?? 0)
            }
            
        case .workout:
            healthDetailService.getSamples(for: healthService.workouts, measure: unit.workoutMeasure ?? .duration, categories: option, range: range) {stat, workouts,_ in
                print("workout stats")
                print(stat)
                for workout in workouts ?? [] {
                    print(workout.name)
                    print(workout.type ?? "")
                    print(workout.startDateTime ?? "")
                    print(workout.endDateTime ?? "")
                }
                completion(stat?.value ?? 0)
            }
            
        case .mindfulness:
            healthDetailService.getSamples(for: healthService.mindfulnesses, range: range) {stat, mindfulnesses,_ in
                print("mindfulness stats")
                print(stat)
                for mindfulness in mindfulnesses ?? [] {
                    print(mindfulness.name)
                    print(mindfulness.startDateTime ?? "")
                    print(mindfulness.endDateTime ?? "")
                }
                completion(stat?.value ?? 0)
            }
            
        case .sleep:
            if let generalMetrics = healthService.healthMetrics[.general], let healthMetric = generalMetrics.first(where: {$0.type == .sleep}) {
                healthDetailService.getSamples(for: healthMetric, range: range) { stat, samples, _ in
                    print("sleep stats")
                    print(stat)
                    for sample in samples ?? [] {
                        print(sample.sampleType)
                        print(sample.startDate)
                        print(sample.endDate)
                    }
                    completion(stat?.value ?? 0)
                }
            }
        case .steps:
            if let generalMetrics = healthService.healthMetrics[.general], let healthMetric = generalMetrics.first(where: {$0.type == .steps}) {
                healthDetailService.getSamples(for: healthMetric, range: range) { stat, samples, _ in
                    print("steps stats")
                    print(stat)
                    for sample in samples ?? [] {
                        print(sample.sampleType)
                        print(sample.startDate)
                        print(sample.endDate)
                    }
                    completion(stat?.value ?? 0)
                }
            }
        case .flightsClimbed:
            if let generalMetrics = healthService.healthMetrics[.general], let healthMetric = generalMetrics.first(where: {$0.type == .flightsClimbed}) {
                healthDetailService.getSamples(for: healthMetric, range: range) { stat, samples, _ in
                    print("flightsClimbed stats")
                    print(stat)
                    for sample in samples ?? [] {
                        print(sample.sampleType)
                        print(sample.startDate)
                        print(sample.endDate)
                    }
                    completion(stat?.value ?? 0)
                }
            }
        case .activeCalories:
            if let workoutsMetrics = healthService.healthMetrics[.workouts], let healthMetric = workoutsMetrics.first(where: {$0.type == .activeEnergy}) {
                healthDetailService.getSamples(for: healthMetric, range: range) { stat, samples, _ in
                    print("activeCalories stats")
                    print(stat)
                    for sample in samples ?? [] {
                        print(sample.sampleType)
                        print(sample.startDate)
                        print(sample.endDate)
                    }
                    completion(stat?.value ?? 0)
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
                    var date = Date()
                    let task = Activity(activityID: activityID, admin: currentUserID, listID: list.id ?? "", listName: list.name ?? "", listColor: list.color ?? CIColor(color: ChartColors.palette()[5]).stringRepresentation, listSource: list.source ?? "", isCompleted: false, createdDate: NSNumber(value: Int((date).timeIntervalSince1970)))
                    task.name = goal.name
                    task.isGoal = true
                    
                    let group = DispatchGroup()
                    if goal.targetNumber == nil {
                        group.enter()
                        if goal.name == "Save Emergency Fund" {
                            checkGoal(metric: GoalMetric.financialTransactions, submetric: GoalSubMetric.group, option: ["Expense"], unit: GoalUnit.amount, range: DateRange(startDate: Date().startOfMonth.monthBefore.monthBefore.monthBefore, endDate: Date().endOfMonth.monthBefore)) { double in
                                goal.targetNumber = round(double)
                                group.leave()
                            }
                        } else if goal.name == "Monthly Savings" {
                            checkGoal(metric: GoalMetric.financialTransactions, submetric: GoalSubMetric.group, option: ["Income"], unit: GoalUnit.amount, range: DateRange(startDate: Date().startOfMonth.monthBefore.monthBefore.monthBefore, endDate: Date().endOfMonth.monthBefore)) { double in
                                goal.targetNumber = round(double / 3 * 0.2)
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
                            switch recurrenceRule.frequency {
                            case .yearly:
                                date = date.localTime.endOfYear
                            case .monthly:
                                date = date.localTime.endOfMonth
                            case .weekly:
                                date = date.localTime.endOfWeek
                            case .daily:
                                date = date.localTime.endOfDay
                            case .hourly, .minutely, .secondly:
                                break
                            }
                            task.endDateTime = NSNumber(value: Int((date).timeIntervalSince1970))
                            recurrenceRule.startDate = date
                            recurrenceRule.interval = goal.name != "Dentist" ? 1 : 2
                            task.recurrences = [recurrenceRule.toRRuleString()]
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
