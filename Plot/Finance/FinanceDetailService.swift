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
                              segmentType: .week,
                              range: range,
                              accounts: accounts,
                              transactions: transactions,
                              filterAccounts: nil,
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
            startDate = range.startDate
            endDate = range.endDate
        } else if segmentType == .day {
            startDate = Date().localTime.startOfDay
            endDate = Date().localTime.endOfDay
        } else if segmentType == .week {
            startDate = Date().localTime.startOfWeek
            endDate = Date().localTime.endOfWeek
        } else if segmentType == .month {
            startDate = Date().localTime.startOfMonth
            endDate = Date().localTime.endOfMonth
        } else if segmentType == .year {
            startDate = Date().localTime.startOfYear
            endDate = Date().localTime.endOfYear
        }
        
        DispatchQueue.global(qos: .background).async {
            if let accountDetails = accountDetails, let accounts = accounts {
                accountDetailsOverTimeChartData(accounts: accounts, accountDetails: [accountDetails], start: startDate, end: endDate, segmentType: segmentType) { (statisticDict, accountDict) in
                    if let statistics = statisticDict[accountDetails], let accounts = accountDict[accountDetails] {
                        let sortedAccounts = accounts.sorted(by: {$0.name < $1.name})
                        DispatchQueue.main.async {
                            completion(statistics, sortedAccounts, nil, nil)
                        }
                    }
                }
            } else if let transactionDetails = transactionDetails, let transactions = transactions {
                transactionDetailsOverTimeChartData(transactions: transactions, transactionDetails: [transactionDetails], start: startDate, end: endDate, segmentType: segmentType, accounts: filterAccounts) { (statisticDict, transactionDict) in
                    if let statistics = statisticDict[transactionDetails], let transactions = transactionDict[transactionDetails] {
                        let isodateFormatter = ISO8601DateFormatter()
                        var sortTransactions = transactions
                        sortTransactions.sort { (transaction1, transaction2) -> Bool in
                            if let date1 = isodateFormatter.date(from: transaction1.transacted_at), let date2 = isodateFormatter.date(from: transaction2.transacted_at) {
                                return date1 > date2
                            }
                            return transaction1.description < transaction2.description
                        }
                        let sortedTransactions = sortTransactions
                        DispatchQueue.main.async {
                            completion(statistics, nil, sortedTransactions, nil)
                        }
                    }
                }
            }
        }
        
    }
}

struct Statistic {
    var date: Date
    var value: Double
}