//
//  SummaryService.swift
//  Plot
//
//  Created by Cory McHattie on 11/27/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import Foundation
import HealthKit

protocol SummaryServiceInterface {
    func getSamples(segmentType: TimeSegmentType, activities: [Activity]?, transactions: [Transaction]?, completion: @escaping ([HKActivitySummary]?, [String: [Entry]]?, [String: [Entry]]?, Error?) -> Swift.Void)
}

class SummaryService: SummaryServiceInterface {
    func getSamples(segmentType: TimeSegmentType, activities: [Activity]?, transactions: [Transaction]?, completion: @escaping ([HKActivitySummary]?, [String: [Entry]]?, [String: [Entry]]?, Error?) -> Swift.Void) {
        getStatisticalSamples(segmentType: segmentType, activities: activities, transactions: transactions, completion: completion)
    }

    private func getStatisticalSamples(segmentType: TimeSegmentType, activities: [Activity]?, transactions: [Transaction]?, completion: @escaping ([HKActivitySummary]?, [String: [Entry]]?, [String: [Entry]]?, Error?) -> Void) {

        let dispatchGroup = DispatchGroup()
        var activitySummary: [HKActivitySummary]?
        var calendarEntries = [String: [Entry]]()
        var financesEntries = [String: [Entry]]()
        
        let anchorDate = Date()
        var startDate = anchorDate
        var endDate = anchorDate

        if segmentType == .day {
            startDate = Date().startOfDay
            endDate = Date().endOfDay
        }
        else if segmentType == .week {
            startDate = Date().startOfWeek
            endDate = Date().endOfWeek
        }
        else if segmentType == .month {
            startDate = Date().startOfMonth
            endDate = Date().endOfMonth
        }
        else if segmentType == .year {
            startDate = Date().startOfYear
            endDate = Date().endOfYear
        }
        
        HealthKitService.authorizeHealthKit { authorized in
            guard authorized else {
                return
            }
            
            dispatchGroup.enter()
            HealthKitService.getSummaryActivityData(startDate: startDate, endDate: endDate) { (summaries, error) in
                activitySummary = summaries
                dispatchGroup.leave()
            }
        }
        
        if let activities = activities {
            dispatchGroup.enter()
            categorizeActivities(activities: activities, start: startDate, end: endDate) { (categoryDict, _) in
                let totalValue: Double = endDate.timeIntervalSince(startDate)                
                var entries = [Entry]()
                for (key, value) in categoryDict {
                    let entry = Entry(label: key.capitalized, value: value / totalValue, icon: nil)
                    entries.append(entry)
                }
                if !entries.isEmpty {
                    calendarEntries["Calendar Summary"] = entries
                }
                dispatchGroup.leave()
            }
        }
        
        if let transactions = transactions {
            dispatchGroup.enter()
            categorizeTransactions(transactions: transactions, start: startDate, end: endDate) { (transactionDetailsList, _) in
                //total groups excluding 'Expense'
                var totalValue : Double = 0
                var entries = [Entry]()
                if let incomeTransactionDetail = transactionDetailsList.first(where: { ($0.level == .group && $0.group == "Income") }), let expenseTransactionDetail = transactionDetailsList.first(where: { ($0.level == .group && $0.group == "Expense") }) {
                    totalValue = incomeTransactionDetail.amount + abs(expenseTransactionDetail.amount) + incomeTransactionDetail.amount + expenseTransactionDetail.amount
                    for transactionDetail in transactionDetailsList {
                        if transactionDetail.level == .group {
                            if transactionDetail.name == "Expense" || transactionDetail.name == "Income" || transactionDetail.name == "Difference" {
                                let entry = Entry(label: transactionDetail.name, value: abs(transactionDetail.amount) / totalValue, icon: nil)
                                entries.append(entry)
                            } else {
                                continue
                            }
                        }
                    }
                    if !entries.isEmpty {
                        financesEntries["Financial Summary"] = entries
                    }
                }
                
                if let expenseTransactionDetail = transactionDetailsList.first(where: { ($0.level == .group && $0.group == "Expense") }) {
                    totalValue = abs(expenseTransactionDetail.amount)
                    entries = []
                    //just expense groups excluding 'Expense'
                    for transactionDetail in transactionDetailsList {
                        if transactionDetail.level == .group {
                            if transactionDetail.name == "Expense" || transactionDetail.name == "Income" || transactionDetail.name == "Difference" {
                                continue
                            } else {
                                let entry = Entry(label: transactionDetail.name, value: abs(transactionDetail.amount) / totalValue, icon: nil)
                                entries.append(entry)
                            }
                        }
                    }
                    if !entries.isEmpty {
                        financesEntries["Spending Summary"] = entries
                    }
                }
                dispatchGroup.leave()
            }
        }
        dispatchGroup.notify(queue: .main) {
            completion(activitySummary, calendarEntries, financesEntries, nil)
        }
    }
}

struct Entry {
    var label: String
    var value: Double
    var icon: UIImage?
}
