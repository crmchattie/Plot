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
        let now = Date()
        for task in activityService.goals {
            print("--------------------------")
            if let goal = task.goal, let metric = goal.metric, !(task.isCompleted ?? false) {
                var updatedDescription = goal.description ?? ""
                if let secondaryDescription = goal.descriptionSecondary {
                    updatedDescription += secondaryDescription
                }
                print(goal.name)
                print(updatedDescription)
                print(monthPast)
                print(now)
                print(task.endDate)
                print(task.startDateGivenEndDateFrequency)
                print(goal.frequency)
                
                var startDate: Date?
                var endDate: Date?
                
                if let endDateTemp = task.endDate, endDateTemp > monthPast {
                    endDate = endDateTemp
                    if let startDateTemp = task.startDate {
                        startDate = startDateTemp
                    } else if let _ = goal.frequency, let startDateTemp = task.startDateGivenEndDateFrequency, startDateTemp < now {
                        startDate = startDateTemp
                    }
                }
                
                if let metricsRelationship = goal.metricsRelationshipType, metricsRelationship != .or {
                    
                }
            }
        }
    }
    
    func checkGoal(metric: GoalMetric, submetric: GoalSubMetric?, option: [String]?, unit: GoalUnit, targetNumber: Double, range: DateRange) {
        switch metric {
        case .events:
            print("events")

            switch submetric {
            case nil:
                print("nil")
                break
            case .some(.none):
                print("none")
                activityDetailService.getEventCategoriesSamples(activities: activityService.events, activityCategories: nil, activitySubcategories: nil, range: range) { statsDict, activities in
                    for (cat, stats) in statsDict ?? [:] {
                        print(cat, stats)
                    }
                    for activity in activities ?? [] {
                        print(activity.name ?? "")
                        print(activity.category ?? "")
                        print(activity.startDate ?? "")
                        print(activity.endDate ?? "")
                    }
                }
            case .some(.group):
                print("group")
                break
            case .some(.category):
                print("category")
                activityDetailService.getEventCategoriesSamples(activities: activityService.events, activityCategories: option, activitySubcategories: nil, range: range) { statsDict, activities in
                    for (cat, stats) in statsDict ?? [:] {
                        print(cat, stats)
                    }
                    for activity in activities ?? [] {
                        print(activity.name ?? "")
                        print(activity.category ?? "")
                        print(activity.startDate ?? "")
                        print(activity.endDate ?? "")
                    }
                }
            case .some(.subcategory):
                print("subcategory")
                activityDetailService.getEventCategoriesSamples(activities: activityService.events, activityCategories: nil, activitySubcategories: option, range: range) { statsDict, activities in
                    for (cat, stats) in statsDict ?? [:] {
                        print(cat, stats)
                    }
                    for activity in activities ?? [] {
                        print(activity.name ?? "")
                        print(activity.category ?? "")
                        print(activity.startDate ?? "")
                        print(activity.endDate ?? "")
                    }
                }
            }
        case .tasks:
            print("tasks")

            switch submetric {
            case nil:
                print("nil")
                break
            case .some(.none):
                print("none")
                activityDetailService.getEventCategoriesSamples(activities: activityService.events, activityCategories: nil, activitySubcategories: nil, range: range) { statsDict, activities in
                    for (cat, stats) in statsDict ?? [:] {
                        print(cat, stats)
                    }
                    for activity in activities ?? [] {
                        print(activity.name ?? "")
                        print(activity.category ?? "")
                        print(activity.startDate ?? "")
                        print(activity.endDate ?? "")
                    }
                }
            case .some(.group):
                print("group")
                break
            case .some(.category):
                print("category")
                activityDetailService.getEventCategoriesSamples(activities: activityService.events, activityCategories: option, activitySubcategories: nil, range: range) { statsDict, activities in
                    for (cat, stats) in statsDict ?? [:] {
                        print(cat, stats)
                    }
                    for activity in activities ?? [] {
                        print(activity.name ?? "")
                        print(activity.category ?? "")
                        print(activity.startDate ?? "")
                        print(activity.endDate ?? "")
                    }
                }
            case .some(.subcategory):
                print("subcategory")
                activityDetailService.getEventCategoriesSamples(activities: activityService.events, activityCategories: nil, activitySubcategories: option, range: range) { statsDict, activities in
                    for (cat, stats) in statsDict ?? [:] {
                        print(cat, stats)
                    }
                    for activity in activities ?? [] {
                        print(activity.name ?? "")
                        print(activity.category ?? "")
                        print(activity.startDate ?? "")
                        print(activity.endDate ?? "")
                    }
                }
            }
        case .financialTransactions:
            var transactionDetails = [TransactionDetails]()
            switch submetric {
            case nil:
                print("nil")
                break
            case .some(.none):
                print("none")
                break
                
            case .some(.group):
                print("group")
                for opt in option ?? [] {
                    let transactionDetail = TransactionDetails(name: opt, amount: 0, level: submetric?.transcationCatLevel ?? .group, group: opt)
                    transactionDetails.append(transactionDetail)
                }
                financeDetailService.getSamples(for: range, accountDetails: nil, transactionDetails: transactionDetails, accounts: nil, transactions: financeService.transactions, filterAccounts: nil) { statsList, _, transactions, err in
                    for stats in statsList ?? [] {
                        print(stats)
                    }
                    for transaction in transactions ?? [] {
                        print(transaction.description)
                        print(transaction.group)
                        print(transaction.transacted_at)
                    }
                }
                
            case .some(.category):
                print("category")
                
                for opt in option ?? [] {
                    let transactionDetail = TransactionDetails(name: opt, amount: 0, level: submetric?.transcationCatLevel ?? .group, topLevelCategory: opt)
                    transactionDetails.append(transactionDetail)
                }
                financeDetailService.getSamples(for: range, accountDetails: nil, transactionDetails: transactionDetails, accounts: nil, transactions: financeService.transactions, filterAccounts: nil) { statsList, _, transactions, err in
                    for stats in statsList ?? [] {
                        print(stats)
                    }
                    for transaction in transactions ?? [] {
                        print(transaction.description)
                        print(transaction.top_level_category)
                        print(transaction.transacted_at)
                    }
                }
                
            case .some(.subcategory):
                print("subcategory")
                
                for opt in option ?? [] {
                    let transactionDetail = TransactionDetails(name: opt, amount: 0, level: submetric?.transcationCatLevel ?? .group, category: opt)
                    transactionDetails.append(transactionDetail)
                }
                financeDetailService.getSamples(for: range, accountDetails: nil, transactionDetails: transactionDetails, accounts: nil, transactions: financeService.transactions, filterAccounts: nil) { statsList, _, transactions, err in
                    for stats in statsList ?? [] {
                        print(stats)
                    }
                    for transaction in transactions ?? [] {
                        print(transaction.description)
                        print(transaction.category)
                        print(transaction.transacted_at)
                    }
                }
                
            }
        case .financialAccounts:
            print("financialAccounts")
            
            var accountDetails = [AccountDetails]()
            
            switch submetric {
            case nil:
                print("nil")
                break
            case .some(.none):
                print("none")
                break
                
            case .some(.group):
                print("group")
                for opt in option ?? [] {
                    let accountDetail = AccountDetails(name: opt, balance: 0, level: submetric?.accountCatLevel ?? .bs_type, bs_type: BalanceSheetType(rawValue: opt))
                    accountDetails.append(accountDetail)
                }
                financeDetailService.getSamples(for: range, accountDetails: accountDetails, transactionDetails: nil, accounts: financeService.accounts, transactions: nil, filterAccounts: nil) { statsList, accounts, _, err in
                    for stats in statsList ?? [] {
                        print(stats)
                    }
                    for account in accounts ?? [] {
                        print(account.name)
                        print(account.bs_type)
                        print(account.updated_at)
                    }
                }
                
            case .some(.category):
                print("category")
                
                for opt in option ?? [] {
                    let accountDetail = AccountDetails(name: opt, balance: 0, level: submetric?.accountCatLevel ?? .bs_type, type: MXAccountType(rawValue: opt))
                    accountDetails.append(accountDetail)
                }
                financeDetailService.getSamples(for: range, accountDetails: accountDetails, transactionDetails: nil, accounts: financeService.accounts, transactions: nil, filterAccounts: nil) { statsList, accounts, _, err in
                    for stats in statsList ?? [] {
                        print(stats)
                    }
                    for account in accounts ?? [] {
                        print(account.name)
                        print(account.type)
                        print(account.updated_at)
                    }
                }
                
            case .some(.subcategory):
                print("subcategory")
                
                for opt in option ?? [] {
                    let accountDetail = AccountDetails(name: opt, balance: 0, level: submetric?.accountCatLevel ?? .bs_type, subtype: MXAccountSubType(rawValue: opt))
                    accountDetails.append(accountDetail)
                }
                financeDetailService.getSamples(for: range, accountDetails: accountDetails, transactionDetails: nil, accounts: financeService.accounts, transactions: nil, filterAccounts: nil) { statsList, accounts, _, err in
                    for stats in statsList ?? [] {
                        print(stats)
                    }
                    for account in accounts ?? [] {
                        print(account.name)
                        print(account.subtype)
                        print(account.updated_at)
                    }
                }
                
            }
            
        case .workout:
            print("workout")
        case .mindfulness:
            print("mindfulness")
        case .sleep:
            print("sleep")
        case .steps:
            print("steps")
        case .flightsClimbed:
            print("flightsClimbed")
        case .activeCalories:
            print("activeCalories")
        }
    }
    
    func setupInitialGoals() {
        print("setupInitialGoals")
        if let currentUserID = Auth.auth().currentUser?.uid, let lists = activityService.lists[ListSourceOptions.plot.name] {
            for goal in prebuiltGoals {
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
    
    func deleteGoals() {
        for task in activityService.goalsNoRepeats {
            let activityAction = ActivityActions(activity: task, active: true, selectedFalconUsers: [])
            activityAction.deleteActivity(updateExternal: true, updateDirectAssociation: false)
        }
    }
}
