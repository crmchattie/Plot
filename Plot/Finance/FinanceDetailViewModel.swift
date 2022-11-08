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
    
    func fetchLineChartData(segmentType: TimeSegmentType, useAll: Bool,completion: @escaping (LineChartData?, Double, Double) -> ())
    
    func fetchBarChartData(segmentType: TimeSegmentType, useAll: Bool, completion: @escaping (BarChartData?, Double, Double) -> ())
}

class FinanceDetailViewModel: FinanceDetailViewModelInterface {
    let financeDetailService: FinanceDetailServiceInterface
    
    let accountDetails: AccountDetails?
    let transactionDetails: TransactionDetails?
    var allAccounts: [MXAccount]?
    var allTransactions: [Transaction]?
    var accounts: [MXAccount]?
    var transactions: [Transaction]?
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
    
    func fetchLineChartData(segmentType: TimeSegmentType, useAll: Bool, completion: @escaping (LineChartData?, Double, Double) -> ()) {
        if useAll {
            financeDetailService.getSamples(accountDetails: accountDetails, transactionDetails: transactionDetails, segmentType: segmentType, accounts: allAccounts, transactions: allTransactions, filterAccounts: filterAccounts) { [weak self] (stats, accounts, transactions, err) in
                
                var lineChartData: LineChartData?
                var maxValue: Double = 0
                var minValue: Double = 0
                if let stats = stats, stats.count > 0 {
                    var i = 0
                    var entries: [ChartDataEntry] = []
                    for stat in stats {
                        maxValue = max(maxValue, stat.value)
                        minValue = min(minValue, stat.value)
                        let entry = ChartDataEntry(x: Double(i) + 0.5, y: stat.value, data: stat.date)
                        entries.append(entry)
                        i += 1
                    }
                                        
                    let dataSet = LineChartDataSet(entries: entries, label: "")
                    dataSet.fillColor = .systemBlue
                    dataSet.fillAlpha = 0.5
                    dataSet.drawFilledEnabled = true
                    dataSet.drawCirclesEnabled = false
                    
                    lineChartData = LineChartData(dataSet: dataSet)
                    lineChartData?.setDrawValues(false)
                }
                
                DispatchQueue.main.async {
                    self?.accounts = accounts ?? []
                    self?.transactions = transactions ?? []
                    completion(lineChartData, maxValue, minValue)
                }
            }
        } else {
            financeDetailService.getSamples(accountDetails: accountDetails, transactionDetails: transactionDetails, segmentType: segmentType, accounts: accounts, transactions: transactions, filterAccounts: filterAccounts) { [weak self] (stats, accounts, transactions, err) in
                
                var lineChartData: LineChartData?
                var maxValue: Double = 0
                var minValue: Double = 0
                if let stats = stats, stats.count > 0 {
                    var i = 0
                    var entries: [ChartDataEntry] = []
                    for stat in stats {
                        maxValue = max(maxValue, stat.value)
                        minValue = min(minValue, stat.value)
                        let entry = ChartDataEntry(x: Double(i) + 0.5, y: stat.value, data: stat.date)
                        entries.append(entry)
                        i += 1
                    }
                                        
                    let dataSet = LineChartDataSet(entries: entries, label: "")
                    dataSet.fillColor = .systemBlue
                    dataSet.fillAlpha = 0.5
                    dataSet.drawFilledEnabled = true
                    dataSet.drawCirclesEnabled = false
                    
                    lineChartData = LineChartData(dataSet: dataSet)
                    lineChartData?.setDrawValues(false)
                }
                
                DispatchQueue.main.async {
                    self?.accounts = accounts ?? []
                    self?.transactions = transactions ?? []
                    completion(lineChartData, maxValue, minValue)
                }
            }
        }
    }
    
    func fetchBarChartData(segmentType: TimeSegmentType, useAll: Bool, completion: @escaping (BarChartData?, Double, Double) -> ()) {
        if useAll {
            financeDetailService.getSamples(accountDetails: accountDetails, transactionDetails: transactionDetails, segmentType: segmentType, accounts: allAccounts, transactions: allTransactions, filterAccounts: filterAccounts) { [weak self] (stats, accounts, transactions, err) in
                
                var barChartData: BarChartData?
                var maxValue: Double = 0
                var minValue: Double = 0
                if let stats = stats, stats.count > 0 {
                    var i = 0
                    var entries: [BarChartDataEntry] = []
                    for stat in stats {
                        maxValue = max(maxValue, stat.value)
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
                    completion(barChartData, maxValue, minValue)
                }
            }
        } else {
            financeDetailService.getSamples(accountDetails: accountDetails, transactionDetails: transactionDetails, segmentType: segmentType, accounts: accounts, transactions: transactions, filterAccounts: filterAccounts) { [weak self] (stats, accounts, transactions, err) in
                
                var barChartData: BarChartData?
                var maxValue: Double = 0
                var minValue: Double = 0
                if let stats = stats, stats.count > 0 {
                    var i = 0
                    var entries: [BarChartDataEntry] = []
                    for stat in stats {
                        maxValue = max(maxValue, stat.value)
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
                    completion(barChartData, maxValue, minValue)
                }
            }
        }
    }
}
