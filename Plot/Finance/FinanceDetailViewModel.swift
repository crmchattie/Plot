//
//  FinanceDetailViewModel.swift
//  Plot
//
//  Created by Cory McHattie on 11/17/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import Foundation
import Charts

protocol FinanceDetailViewModelInterface {
    var accountDetails: AccountDetails? { get }
    var transactionDetails: TransactionDetails? { get }
    var accounts: [MXAccount]? { get set }
    var transactions: [Transaction]? { get set }
    
    func fetchLineChartData(segmentType: TimeSegmentType, useAll: Bool,completion: @escaping (LineChartData?, Double) -> ())
    
    func fetchBarChartData(segmentType: TimeSegmentType, useAll: Bool, completion: @escaping (BarChartData?, Double) -> ())
    
    func filterSamples(segmentType: TimeSegmentType?, date: Date?, completion: () -> Void)
}

class FinanceDetailViewModel: FinanceDetailViewModelInterface {
    let financeDetailService: FinanceDetailServiceInterface
    
    let accountDetails: AccountDetails?
    let transactionDetails: TransactionDetails?
    var allAccounts: [MXAccount]?
    var allTransactions: [Transaction]?
    var accounts: [MXAccount]?
    var transactions: [Transaction]?
    var priorAccounts: [MXAccount]?
    var priorTransactions: [Transaction]?
    var filterAccounts: [String]?
    
    init(accountDetails: AccountDetails?, allAccounts: [MXAccount]?, accounts: [MXAccount]?, transactionDetails: TransactionDetails?, allTransactions: [Transaction]?, transactions: [Transaction]?, filterAccounts: [String]?, financeDetailService: FinanceDetailServiceInterface) {
        self.accountDetails = accountDetails
        self.allAccounts = allAccounts
        self.accounts = accounts
        self.transactionDetails = transactionDetails
        self.allTransactions = allTransactions
        self.transactions = transactions
        self.financeDetailService = financeDetailService
        self.filterAccounts = filterAccounts
    }
    
    func fetchLineChartData(segmentType: TimeSegmentType, useAll: Bool, completion: @escaping (LineChartData?, Double) -> ()) {
        if useAll {
            financeDetailService.getSamples(accountDetails: accountDetails, transactionDetails: transactionDetails, segmentType: segmentType, accounts: allAccounts, transactions: allTransactions, filterAccounts: filterAccounts) { [weak self] (stats, accounts, transactions, err) in
                
                var lineChartData: LineChartData?
                var minValue: Double = 0
                if let stats = stats, stats.count > 0 {
                    var i = 0
                    var entries: [ChartDataEntry] = []
                    for stat in stats {
                        minValue = min(minValue, stat.value)
                        let entry = ChartDataEntry(x: Double(i), y: stat.value, data: stat.date)
                        entries.append(entry)
                        i += 1
                    }
                    
                    let chartDataSet = LineChartDataSet(entries: entries, label: "")
                    chartDataSet.setDrawHighlightIndicators(false)
                    chartDataSet.axisDependency = .right
                    chartDataSet.colors = [NSUIColor.systemBlue]
                    chartDataSet.lineWidth = 5
                    chartDataSet.fillAlpha = 0
                    chartDataSet.drawFilledEnabled = true
                    chartDataSet.drawCirclesEnabled = false
                    lineChartData = LineChartData(dataSet: chartDataSet)
                    lineChartData?.setDrawValues(false)
                }
                
                DispatchQueue.main.async {
                    self?.accounts = accounts ?? []
                    self?.transactions = transactions ?? []
                    self?.priorAccounts = accounts ?? []
                    self?.priorTransactions = transactions ?? []
                    completion(lineChartData, minValue)
                }
            }
        } else {
            financeDetailService.getSamples(accountDetails: accountDetails, transactionDetails: transactionDetails, segmentType: segmentType, accounts: accounts, transactions: transactions, filterAccounts: filterAccounts) { [weak self] (stats, accounts, transactions, err) in
                
                var lineChartData: LineChartData?
                var minValue: Double = 0
                if let stats = stats, stats.count > 0 {
                    var i = 0
                    var entries: [ChartDataEntry] = []
                    for stat in stats {
                        minValue = min(minValue, stat.value)
                        let entry = ChartDataEntry(x: Double(i), y: stat.value, data: stat.date)
                        entries.append(entry)
                        i += 1
                    }
                    
                    let chartDataSet = LineChartDataSet(entries: entries, label: "")
                    chartDataSet.setDrawHighlightIndicators(false)
                    chartDataSet.axisDependency = .right
                    chartDataSet.colors = [NSUIColor.systemBlue]
                    chartDataSet.lineWidth = 5
                    chartDataSet.fillAlpha = 0
                    chartDataSet.drawFilledEnabled = true
                    chartDataSet.drawCirclesEnabled = false
                    lineChartData = LineChartData(dataSet: chartDataSet)
                    lineChartData?.setDrawValues(false)
                }
                
                DispatchQueue.main.async {
                    self?.accounts = accounts ?? []
                    self?.transactions = transactions ?? []
                    self?.priorAccounts = accounts ?? []
                    self?.priorTransactions = transactions ?? []
                    completion(lineChartData, minValue)
                }
            }
        }
    }
    
    func fetchBarChartData(segmentType: TimeSegmentType, useAll: Bool, completion: @escaping (BarChartData?, Double) -> ()) {
        if useAll {
            financeDetailService.getSamples(accountDetails: accountDetails, transactionDetails: transactionDetails, segmentType: segmentType, accounts: allAccounts, transactions: allTransactions, filterAccounts: filterAccounts) { [weak self] (stats, accounts, transactions, err) in
                
                var barChartData: BarChartData?
                var minValue: Double = 0
                if let stats = stats, stats.count > 0 {
                    var i = 0
                    var entries: [BarChartDataEntry] = []
                    for stat in stats {
                        minValue = min(minValue, stat.value)
                        let entry = BarChartDataEntry(x: Double(i) + 0.5, y: stat.value, data: stat.date)
                        entries.append(entry)
                        i += 1
                    }
                    
                    let dataSet = BarChartDataSet(entries: entries, label: "")
                    dataSet.setColor(ChartColors.palette()[5])
                    dataSet.drawValuesEnabled = false
                    dataSet.axisDependency = .right
                    
                    barChartData = BarChartData(dataSet: dataSet)
                }
                
                DispatchQueue.main.async {
                    self?.accounts = accounts ?? []
                    self?.transactions = transactions ?? []
                    self?.priorAccounts = accounts ?? []
                    self?.priorTransactions = transactions ?? []
                    completion(barChartData, minValue)
                }
            }
        } else {
            financeDetailService.getSamples(accountDetails: accountDetails, transactionDetails: transactionDetails, segmentType: segmentType, accounts: accounts, transactions: transactions, filterAccounts: filterAccounts) { [weak self] (stats, accounts, transactions, err) in
                
                var barChartData: BarChartData?
                var minValue: Double = 0
                if let stats = stats, stats.count > 0 {
                    var i = 0
                    var entries: [BarChartDataEntry] = []
                    for stat in stats {
                        minValue = min(minValue, stat.value)
                        let entry = BarChartDataEntry(x: Double(i) + 0.5, y: stat.value, data: stat.date)
                        entries.append(entry)
                        i += 1
                    }
                    
                    let dataSet = BarChartDataSet(entries: entries, label: "")
                    dataSet.setColor(ChartColors.palette()[5])
                    dataSet.drawValuesEnabled = false
                    dataSet.axisDependency = .right
                    
                    barChartData = BarChartData(dataSet: dataSet)
                }
                
                DispatchQueue.main.async {
                    self?.accounts = accounts ?? []
                    self?.transactions = transactions ?? []
                    self?.priorAccounts = accounts ?? []
                    self?.priorTransactions = transactions ?? []
                    completion(barChartData, minValue)
                }
            }
        }
    }
    
    func filterSamples(segmentType: TimeSegmentType?, date: Date?, completion: () -> Void) {
        if let _ = transactions {
            if let segmentType = segmentType, let date = date {
                self.transactions = priorTransactions ?? []
                
                switch segmentType {
                case .day:
                    self.transactions = self.transactions!.filter { transaction -> Bool in
                        guard let transactionDate = transaction.transactionDate else { return false }
                        return date.UTCTime.hourBefore < transactionDate && transactionDate < date.UTCTime
                    }
                    completion()
                case .week:
                    self.transactions = self.transactions!.filter { transaction -> Bool in
                        guard let transactionDate = transaction.transactionDate else { return false }
                        return date.UTCTime.dayBefore < transactionDate && transactionDate < date.UTCTime
                    }
                    completion()
                case .month:
                    self.transactions = self.transactions!.filter { transaction -> Bool in
                        guard let transactionDate = transaction.transactionDate else { return false }
                        return date.UTCTime.dayBefore < transactionDate && transactionDate < date.UTCTime
                    }
                    completion()
                case .year:
                    self.transactions = self.transactions!.filter { transaction -> Bool in
                        guard let transactionDate = transaction.transactionDate else { return false }
                        return date.UTCTime.monthBefore < transactionDate && transactionDate < date.UTCTime
                    }
                    completion()
                }
            } else {
                self.transactions = priorTransactions
                completion()
            }
        }
    }
}

private let dateFormatter = ISO8601DateFormatter()
