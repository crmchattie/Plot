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
    func getSamples(
        segmentType: TimeSegmentType,
        activities: [Activity]?,
        transactions: [Transaction]?,
        completion: @escaping ([HKActivitySummary]?, [SectionType: [Entry]]?, [SectionType: [Entry]]?, [SectionType: [String: [Statistic]]]?, Error?) -> Swift.Void)
}

class SummaryService: SummaryServiceInterface {
    
    func getSamples(segmentType: TimeSegmentType, activities: [Activity]?, transactions: [Transaction]?, completion: @escaping ([HKActivitySummary]?, [SectionType: [Entry]]?, [SectionType: [Entry]]?, [SectionType: [String: [Statistic]]]?, Error?) -> Swift.Void) {
        getStatisticalSamples(segmentType: segmentType, activities: activities, transactions: transactions, completion: completion)
    }

    private func getStatisticalSamples(segmentType: TimeSegmentType, activities: [Activity]?, transactions: [Transaction]?, completion: @escaping ([HKActivitySummary]?, [SectionType: [Entry]]?, [SectionType: [Entry]]?, [SectionType: [String: [Statistic]]]?, Error?) -> Void) {

        let dispatchGroup = DispatchGroup()
        var activitySummary: [HKActivitySummary]?
        var pieChartEntries = [SectionType: [Entry]]()
        var barChartEntries = [SectionType: [Entry]]()
        var barChartStats = [SectionType: [String: [Statistic]]]()
        
        let anchorDate = Date()
        var startDate = anchorDate
        var endDate = anchorDate

        if segmentType == .day {
            startDate = Date().localTime.startOfDay
            endDate = Date().localTime.endOfDay
        }
        else if segmentType == .week {
            startDate = Date().localTime.startOfWeek
            endDate = Date().localTime.endOfWeek
        }
        else if segmentType == .month {
            startDate = Date().localTime.startOfMonth
            endDate = Date().localTime.endOfMonth
        }
        else if segmentType == .year {
            startDate = Date().localTime.startOfYear
            endDate = Date().localTime.endOfYear
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
            var entries = [Entry]()
            dispatchGroup.enter()
            categorizeActivities(activities: activities, start: startDate, end: endDate) { (categoryDict, _) in
                activitiesOverTimeChartData(activities: activities, activityCategories: Array(categoryDict.keys), start: startDate, end: endDate, segmentType: segmentType) { (statsDict, _) in
                    if !statsDict.isEmpty {
                        barChartStats[.calendarSummary] = statsDict
                    }
                }
                
                let totalValue: Double = endDate.timeIntervalSince(startDate)                
                for (key, value) in categoryDict {
                    let entry = Entry(label: key.capitalized, value: value / totalValue, icon: nil)
                    entries.append(entry)
                }
                if !entries.isEmpty {
                    pieChartEntries[.calendarMix] = entries
                }
                dispatchGroup.leave()
            }
        }
        
        if let transactions = transactions {
            dispatchGroup.enter()
            categorizeTransactions(transactions: transactions, start: startDate, end: endDate, level: .none) { (transactionDetailsList, _) in
                //total groups excluding 'Expense'
                var totalValue : Double = 0
                var entries = [Entry]()
                for transactionDetail in transactionDetailsList {
                    if transactionDetail.level == .group {
                        if transactionDetail.name == "Expense" || transactionDetail.name == "Income" || transactionDetail.name == "Difference" {
                            let entry = Entry(label: transactionDetail.name, value: transactionDetail.amount, icon: nil)
                            entries.append(entry)
                        } else {
                            continue
                        }
                    }
                }
                if !entries.isEmpty {
                    barChartEntries[.cashFlowSummary] = entries
                }

                    
                    
//                    transactionDetailsOverTimeChartData(transactions: transactions, transactionDetails: [incomeTransactionDetail, expenseTransactionDetail, differenceTransactionDetail], start: startDate, end: endDate, segmentType: segmentType) { (statisticDict, _) in
//                        if let incomeStatistics = statisticDict[incomeTransactionDetail], let expenseStatistics = statisticDict[expenseTransactionDetail], let differenceStatistics = statisticDict[differenceTransactionDetail] {
//                            barChartEntries["Financial Summary"] = ["Income": incomeStatistics, "Expense": expenseStatistics, "Difference": differenceStatistics]
//                        }
//                    }
//                }
                
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
                        pieChartEntries[.spendingMix] = entries
                    }
                }
                dispatchGroup.leave()
            }
        }
        dispatchGroup.notify(queue: .main) {
            completion(activitySummary, pieChartEntries, barChartEntries, barChartStats, nil)
        }
    }
}

struct Entry {
    var label: String
    var value: Double
    var icon: UIImage?
}
