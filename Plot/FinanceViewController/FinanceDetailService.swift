//
//  FinanceDetailService.swift
//  Plot
//
//  Created by Cory McHattie on 11/17/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import Foundation

protocol FinanceDetailServiceInterface {
    func getSamples(accountDetails: AccountDetails?, transactionDetails: TransactionDetails?, segmentType: TimeSegmentType, accounts: [MXAccount]?, transactions: [Transaction]?, completion: @escaping ([Statistic]?, [MXAccount]?, [Transaction]?, Error?) -> Swift.Void)
}

class FinanceDetailService: FinanceDetailServiceInterface {
    func getSamples(accountDetails: AccountDetails?, transactionDetails: TransactionDetails?, segmentType: TimeSegmentType, accounts: [MXAccount]?, transactions: [Transaction]?, completion: @escaping ([Statistic]?, [MXAccount]?, [Transaction]?, Error?) -> Swift.Void) {

        getStatisticalSamples(accountDetails: accountDetails, transactionDetails: transactionDetails, segmentType: segmentType, accounts: accounts, transactions: transactions, completion: completion)
    }

    private func getStatisticalSamples(accountDetails: AccountDetails?, transactionDetails: TransactionDetails?, segmentType: TimeSegmentType, accounts: [MXAccount]?, transactions: [Transaction]?, completion: @escaping ([Statistic]?, [MXAccount]?, [Transaction]?, Error?) -> Void) {
        print("getStatisticalSamples")

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

        if let accountDetails = accountDetails, let accounts = accounts {
            accountDetailsChartData(accounts: accounts, accountDetails: accountDetails, start: startDate, end: endDate, segmentType: segmentType) { (statistics, accounts) in
                let sortedAccounts = accounts.sorted(by: {$0.name > $1.name})
                completion(statistics, sortedAccounts, nil, nil)
            }
        } else if let transactionDetails = transactionDetails, let transactions = transactions {
            transactionDetailsChartData(transactions: transactions, transactionDetails: transactionDetails, start: startDate, end: endDate, segmentType: segmentType) { (statistics, transactions) in
                let isodateFormatter = ISO8601DateFormatter()
                var sortTransactions = transactions
                sortTransactions.sort { (transaction1, transaction2) -> Bool in
                    if let date1 = isodateFormatter.date(from: transaction1.transacted_at), let date2 = isodateFormatter.date(from: transaction2.transacted_at) {
                        return date1 > date2
                    }
                    return transaction1.description < transaction2.description
                }
                let sortedTransactions = sortTransactions
                completion(statistics, nil, sortedTransactions, nil)
            }
        }
    }
}

struct Statistic {
    var date: Date
    var value: Double
}
