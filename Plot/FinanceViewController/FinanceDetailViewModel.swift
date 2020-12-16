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
    
    func fetchLineChartData(for segmentType: TimeSegmentType, completion: @escaping (LineChartData?, Double) -> ())
    
    func fetchBarChartData(for segmentType: TimeSegmentType, completion: @escaping (BarChartData?, Double) -> ())
}

class FinanceDetailViewModel: FinanceDetailViewModelInterface {
    let financeDetailService: FinanceDetailServiceInterface
    
    let accountDetails: AccountDetails?
    let transactionDetails: TransactionDetails?
    var allAccounts: [MXAccount]?
    var allTransactions: [Transaction]?
    var accounts: [MXAccount]?
    var transactions: [Transaction]?
    
    init(accountDetails: AccountDetails?, accounts: [MXAccount]?, transactionDetails: TransactionDetails?, transactions: [Transaction]?, financeDetailService: FinanceDetailServiceInterface) {
        self.accountDetails = accountDetails
        self.allAccounts = accounts
        self.accounts = accounts
        self.transactionDetails = transactionDetails
        self.allTransactions = transactions
        self.transactions = transactions
        self.financeDetailService = financeDetailService
    }
    
    func fetchLineChartData(for segmentType: TimeSegmentType, completion: @escaping (LineChartData?, Double) -> ()) {
        financeDetailService.getSamples(accountDetails: accountDetails, transactionDetails: transactionDetails, segmentType: segmentType, accounts: allAccounts, transactions: allTransactions) { [weak self] (stats, accounts, transactions, err) in
            
            var lineChartData: LineChartData?
            var maxValue: Double = 0
            if let stats = stats, stats.count > 0 {
                var i = 0
                var entries: [ChartDataEntry] = []
                for stat in stats {
                    maxValue = max(maxValue, stat.value)
                    let entry = ChartDataEntry(x: Double(i), y: stat.value, data: stat.date)
                    entries.append(entry)
                    i += 1
                }
                maxValue *= 1.2
                
                let dataSet = LineChartDataSet(entries: entries, label: nil)
                dataSet.drawIconsEnabled = false
                dataSet.mode = .cubicBezier
                dataSet.setColor(UIColor.systemBlue)
                dataSet.setCircleColor(UIColor.systemBlue)
                dataSet.drawCirclesEnabled = false
                dataSet.drawValuesEnabled = false
                dataSet.circleRadius = 3
                dataSet.drawCircleHoleEnabled = false
                dataSet.valueFont = .systemFont(ofSize: 9)
                dataSet.formSize = 15
                dataSet.lineWidth = 0
                
                let colorTop = UIColor.systemBlue.cgColor
                let colorBottom = UIColor(red: 16.0/255.0, green: 28.0/255.0, blue: 56.0/255.0, alpha: 1.0).cgColor
                let gradientColors = [colorBottom, colorTop] as CFArray
                let gradient = CGGradient(colorsSpace: nil, colors: gradientColors as CFArray, locations: nil)!
                dataSet.fillAlpha = 1
                dataSet.fill = Fill(linearGradient: gradient, angle: 90)
                
                dataSet.drawFilledEnabled = true
                dataSet.axisDependency = .right
                
                lineChartData = LineChartData(dataSet: dataSet)
                lineChartData?.setValueFont(UIFont(name: "HelveticaNeue-Light", size: 10)!)
            }
            
            DispatchQueue.main.async {
                self?.accounts = accounts ?? []
                self?.transactions = transactions ?? []
                completion(lineChartData, maxValue)
            }
        }
    }
    
    func fetchBarChartData(for segmentType: TimeSegmentType, completion: @escaping (BarChartData?, Double) -> ()) {
        financeDetailService.getSamples(accountDetails: accountDetails, transactionDetails: transactionDetails, segmentType: segmentType, accounts: allAccounts, transactions: allTransactions) { [weak self] (stats, accounts, transactions, err) in
            
            var barChartData: BarChartData?
            var maxValue: Double = 0
            if let stats = stats, stats.count > 0 {
                var i = 0
                var entries: [BarChartDataEntry] = []
                for stat in stats {
                    maxValue = max(maxValue, stat.value)
                    let entry = BarChartDataEntry(x: Double(i), y: stat.value, data: stat.date)
                    entries.append(entry)
                    i += 1
                }
                maxValue *= 1.2
                
                let dataSet = BarChartDataSet(entries: entries, label: "")
                dataSet.setColor(ChartColors.palette()[0])
                dataSet.drawValuesEnabled = false
                dataSet.axisDependency = .right
                
                barChartData = BarChartData(dataSet: dataSet)
                barChartData?.setValueFont(UIFont(name: "HelveticaNeue-Light", size: 10)!)
            }
            
            DispatchQueue.main.async {
                self?.accounts = accounts ?? []
                self?.transactions = transactions ?? []
                completion(barChartData, maxValue)
            }
        }
    }
}
