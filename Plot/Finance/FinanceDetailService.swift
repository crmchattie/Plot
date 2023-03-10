//
//  FinanceDetailService.swift
//  Plot
//
//  Created by Cory McHattie on 11/17/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import Foundation

protocol FinanceDetailServiceInterface {
    func getSamples(accountDetails: AccountDetails?, transactionDetails: TransactionDetails?, segmentType: TimeSegmentType, accounts: [MXAccount]?, transactions: [Transaction]?, filterAccounts: [String]?, completion: @escaping ([Statistic]?, [MXAccount]?, [Transaction]?, Error?) -> Void)
    
    func getSamples(for range: DateRange, segment: TimeSegmentType, accountDetails: AccountDetails?, transactionDetails: TransactionDetails?, accounts: [MXAccount]?, transactions: [Transaction]?, completion: @escaping ([Statistic]?, [MXAccount]?, [Transaction]?, Error?) -> Void)
    
    func getSamples(financialType: FinancialType, segmentType: TimeSegmentType, range: DateRange?, accounts: [MXAccount]?, accountLevel: AccountCatLevel?, accountDetails: [AccountDetails]?,                    transactions: [Transaction]?, transactionLevel: TransactionCatLevel?, transactionDetails: [TransactionDetails]?, filterAccounts: [String]?, completion: @escaping ([AccountDetails: [Statistic]]?, [AccountDetails: [MXAccount]]?, [MXAccount]?, [TransactionDetails: [Statistic]]?, [TransactionDetails: [Transaction]]?, [Transaction]?, Error?) -> Void)
    
    func getSamples(for range: DateRange, accountDetails: [AccountDetails]?, transactionDetails: [TransactionDetails]?, accounts: [MXAccount]?, transactions: [Transaction]?, filterAccounts: [String]?, ignore_plot_created: Bool?, ignore_transfer_between_accounts: Bool?, completion: @escaping (Statistic?, [MXAccount]?, [Transaction]?, Error?) -> Void)
}

class FinanceDetailService: FinanceDetailServiceInterface {
    
    func getSamples(accountDetails: AccountDetails?, transactionDetails: TransactionDetails?, segmentType: TimeSegmentType, accounts: [MXAccount]?, transactions: [Transaction]?, filterAccounts: [String]?, completion: @escaping ([Statistic]?, [MXAccount]?, [Transaction]?, Error?) -> Swift.Void) {
        getStatisticalSamples(accountDetails: accountDetails,
                              transactionDetails: transactionDetails,
                              segmentType: segmentType,
                              range: nil,
                              accounts: accounts,
                              transactions: transactions,
                              filterAccounts: filterAccounts,
                              completion: completion)
    }
    
    func getSamples(for range: DateRange, segment: TimeSegmentType, accountDetails: AccountDetails?, transactionDetails: TransactionDetails?, accounts: [MXAccount]?, transactions: [Transaction]?, completion: @escaping ([Statistic]?, [MXAccount]?, [Transaction]?, Error?) -> Void) {
        getStatisticalSamples(accountDetails: accountDetails,
                              transactionDetails: transactionDetails,
                              segmentType: segment,
                              range: range,
                              accounts: accounts,
                              transactions: transactions,
                              filterAccounts: nil,
                              completion: completion)
    }
    
    func getSamples(financialType: FinancialType, segmentType: TimeSegmentType, range: DateRange?, accounts: [MXAccount]?, accountLevel: AccountCatLevel?, accountDetails: [AccountDetails]?,                    transactions: [Transaction]?, transactionLevel: TransactionCatLevel?, transactionDetails: [TransactionDetails]?, filterAccounts: [String]?, completion: @escaping ([AccountDetails: [Statistic]]?, [AccountDetails: [MXAccount]]?, [MXAccount]?, [TransactionDetails: [Statistic]]?, [TransactionDetails: [Transaction]]?, [Transaction]?, Error?) -> Void) {
        getStatisticalSamplesWCategories(financialType: financialType,
                              segmentType: segmentType,
                              range: range,
                              accounts: accounts,
                              accountLevel: accountLevel,
                              accountDetails: accountDetails,
                              transactions: transactions,
                              transactionLevel: transactionLevel,
                              transactionDetails: transactionDetails,
                              filterAccounts: filterAccounts,
                              completion: completion)
    }
    
    func getSamples(for range: DateRange, accountDetails: [AccountDetails]?, transactionDetails: [TransactionDetails]?, accounts: [MXAccount]?, transactions: [Transaction]?, filterAccounts: [String]?, ignore_plot_created: Bool?, ignore_transfer_between_accounts: Bool?, completion: @escaping (Statistic?, [MXAccount]?, [Transaction]?, Error?) -> Void) {
        getStatisticalSamples(accountDetails: accountDetails,
                              transactionDetails: transactionDetails,
                              range: range,
                              accounts: accounts,
                              transactions: transactions,
                              filterAccounts: filterAccounts,
                              ignore_plot_created: ignore_plot_created,
                              ignore_transfer_between_accounts: ignore_transfer_between_accounts,
                              completion: completion)
    }

    private func getStatisticalSamples(
        accountDetails: AccountDetails?,
        transactionDetails: TransactionDetails?,
        segmentType: TimeSegmentType,
        range: DateRange?,
        accounts: [MXAccount]?,
        transactions: [Transaction]?,
        filterAccounts: [String]?,
        completion: @escaping ([Statistic]?, [MXAccount]?, [Transaction]?, Error?) -> Void
    ) {

        let anchorDate = Date()
        var startDate = anchorDate
        var endDate = anchorDate

        if let range = range {
            startDate = range.startDate.startOfDay.dayBefore
            endDate = range.endDate
        } else if segmentType == .day {
            startDate = Date().localTime.startOfDay
            endDate = Date().localTime.dayAfter
        } else if segmentType == .week {
            startDate = Date().localTime.startOfWeek
            endDate = Date().localTime.dayAfter
        } else if segmentType == .month {
            startDate = Date().localTime.startOfMonth
            endDate = Date().localTime.dayAfter
        } else if segmentType == .year {
            startDate = Date().localTime.startOfYear
            endDate = Date().localTime.dayAfter
        }
        
        if let accountDetails = accountDetails, let accounts = accounts {
            accountDetailsOverTimeChartData(accounts: accounts, accountDetails: [accountDetails], start: startDate, end: endDate, segmentType: segmentType) { (statisticDict, accountDict) in
                if let statistics = statisticDict[accountDetails], let accounts = accountDict[accountDetails] {
                    let sortedAccounts = accounts.sorted(by: {$0.name < $1.name})
                    completion(statistics, sortedAccounts, nil, nil)
                }
            }
        } else if let transactionDetails = transactionDetails, let transactions = transactions {
            transactionDetailsOverTimeChartData(transactions: transactions, transactionDetails: [transactionDetails], start: startDate, end: endDate, segmentType: segmentType, accounts: filterAccounts) { (statisticDict, transactionDict) in
                if let statistics = statisticDict[transactionDetails], let transactions = transactionDict[transactionDetails] {
                    var sortTransactions = transactions
                    sortTransactions.sort { (transaction1, transaction2) -> Bool in
                        if let date1 = transaction1.transactionDate, let date2 = transaction2.transactionDate {
                            return date1 > date2
                        }
                        return transaction1.description < transaction2.description
                    }
                    let sortedTransactions = sortTransactions
                    completion(statistics, nil, sortedTransactions, nil)
                }
            }
        } else {
            completion(nil, nil, nil, nil)
        }
    }
    
    private func getStatisticalSamplesWCategories(
        financialType: FinancialType,
        segmentType: TimeSegmentType,
        range: DateRange?,
        accounts: [MXAccount]?,
        accountLevel: AccountCatLevel?,
        accountDetails: [AccountDetails]?,
        transactions: [Transaction]?,
        transactionLevel: TransactionCatLevel?,
        transactionDetails: [TransactionDetails]?,
        filterAccounts: [String]?,
        completion: @escaping ([AccountDetails: [Statistic]]?, [AccountDetails: [MXAccount]]?, [MXAccount]?, [TransactionDetails: [Statistic]]?, [TransactionDetails: [Transaction]]?, [Transaction]?, Error?) -> Void) {
        let anchorDate = Date()
        var startDate = anchorDate
        var endDate = anchorDate

        if let range = range {
            startDate = range.startDate.startOfDay
            endDate = range.endDate
        } else if segmentType == .day {
            startDate = Date().localTime.startOfDay
            endDate = Date().localTime.dayAfter
        } else if segmentType == .week {
            startDate = Date().localTime.startOfWeek
            endDate = Date().localTime.dayAfter
        } else if segmentType == .month {
            startDate = Date().localTime.startOfMonth
            endDate = Date().localTime.dayAfter
        } else if segmentType == .year {
            startDate = Date().localTime.startOfYear
            endDate = Date().localTime.dayAfter
        }
        
        if financialType == .accounts, let accounts = accounts {
            categorizeAccounts(accounts: accounts, timeSegment: segmentType, level: accountLevel, accountDetails: accountDetails, date: endDate) { accountDetailsFinal, accountDetailsDict in
                let accountValues = Array(Set(accountDetailsDict.values.flatMap({ $0 })))
                accountDetailsOverTimeChartData(accounts: accountValues, accountDetails: accountDetailsFinal, start: startDate, end: endDate, segmentType: segmentType) { (statisticDict, accountDict) in
                    completion(statisticDict, accountDict, accountValues, nil, nil, nil, nil)
                    
                }
            }
        } else if financialType == .transactions, let transactions = transactions {
            categorizeTransactions(transactions: transactions, start: startDate, end: endDate, level: transactionLevel, transactionDetails: transactionDetails, accounts: filterAccounts) { transactionsDetailsFinal, transactionsDetailsDict in
                let transactionValues = Array(Set(transactionsDetailsDict.values.flatMap({ $0 })))
                transactionDetailsOverTimeChartData(transactions: transactionValues, transactionDetails: transactionsDetailsFinal, start: startDate, end: endDate, segmentType: segmentType, accounts: filterAccounts) { (statisticDict, transactionDict) in
                    completion(nil, nil, nil, statisticDict, transactionDict, transactionValues, nil)

                }
            }
        } else {
            completion(nil, nil, nil, nil, nil, nil, nil)
        }
    }
    
    private func getStatisticalSamples(
        accountDetails: [AccountDetails]?,
        transactionDetails: [TransactionDetails]?,
        range: DateRange,
        accounts: [MXAccount]?,
        transactions: [Transaction]?,
        filterAccounts: [String]?,
        ignore_plot_created: Bool?,
        ignore_transfer_between_accounts: Bool?,
        completion: @escaping (Statistic?, [MXAccount]?, [Transaction]?, Error?) -> Void
    ) {

        let startDate = range.startDate
        let endDate = range.endDate
        
        var finalStat = Statistic(date: startDate, value: 0)
        
        if let accountDetails = accountDetails, let accounts = accounts {
            var accts = [MXAccount]()
            for accountDetail in accountDetails {
                accountListStats(accounts: accounts, accountDetail: accountDetail, date: startDate, nextDate: endDate) { (stats, a) in
                    for stat in stats {
                        finalStat.value += stat.value
                    }
                    accts.append(contentsOf: a)
                }
            }
            completion(finalStat, accts, nil, nil)
        } else if let transactionDetails = transactionDetails, let transactions = transactions {
            var trans = [Transaction]()
            for transactionDetail in transactionDetails {
                transactionListStats(transactions: transactions, transactionDetail: transactionDetail, date: startDate, nextDate: endDate, accounts: filterAccounts, ignore_plot_created: ignore_plot_created, ignore_transfer_between_accounts: ignore_transfer_between_accounts) { stats, t in
                    for stat in stats {
                        finalStat.value += stat.value
                    }
                    trans.append(contentsOf: t)
                }
            }
            completion(finalStat, nil, trans, nil)
        } else {
            completion(nil, nil, nil, nil)
        }
    }
}

struct Statistic {
    var date: Date
    var value: Double
    var xValue: Int?
}

enum FinancialType {
    case transactions, accounts
}
