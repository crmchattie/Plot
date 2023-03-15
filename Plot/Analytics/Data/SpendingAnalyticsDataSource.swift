//
//  TransactionAnalyticsDataSource.swift
//  Plot
//
//  Created by Botond Magyarosi on 20.03.2021.
//  Copyright © 2021 Immature Creations. All rights reserved.
//

import Foundation
import Combine
import Charts

private func getTitle(range: DateRange) -> String {
    DateRangeFormatter(currentWeek: "Vs. prior week", currentMonth: "Vs. prior month", currentYear: "Vs. prior year")
        .format(range: range)
//    DateRangeFormatter(currentWeek: "Over the last week", currentMonth: "Over the last month", currentYear: "Over the last year").format(range: range)
}

class SpendingAnalyticsDataSource: AnalyticsDataSource {
    func updateRange(_ newRange: DateRange) {
        
    }
    
    private let networkController: NetworkController
    private let financeService = FinanceDetailService()
    
    var range: DateRange
    
    var title: String = "Transactions"
    
    let chartViewModel: CurrentValueSubject<StackedBarChartViewModel, Never>
    
    private var transactions: [Transaction] = []
    
    var currencyFormatter: NumberFormatter = {
        let numberFormatter = NumberFormatter()
        numberFormatter.currencyCode = "USD"
        numberFormatter.numberStyle = .currency
        numberFormatter.maximumFractionDigits = 0
        return numberFormatter
    }()
    
    var dataExists: Bool?
    
    init(
        range: DateRange,
        networkController: NetworkController
    ) {
        self.range = range
        self.networkController = networkController
        
        chartViewModel = .init(StackedBarChartViewModel(chartType: .line,
                                                        rangeDescription: getTitle(range: range),
                                                        verticalAxisValueFormatter: DefaultAxisValueFormatter(formatter: currencyFormatter),
                                                        verticalAxisType: .fixZeroToMiddleOnVertical,
                                                        units: "currency",
                                                        formatType: range.timeSegment))
    }
    
    func loadData(completion: (() -> Void)?) {
        var newChartViewModel = chartViewModel.value
        newChartViewModel.rangeDescription = getTitle(range: range)
        newChartViewModel.formatType = range.timeSegment
        
        let networkTransactions = networkController.financeService.transactions
                
        switch chartViewModel.value.chartType {
        case .line:
            var transactionDetails = [TransactionDetails]()
            for cat in financialTransactionsGroupsStaticSpending {
                transactionDetails.append(TransactionDetails(name: cat, amount: 0, level: .group, group: cat))
            }
            financeService.getSamples(financialType: .transactions, segmentType: range.timeSegment, range: range, accounts: nil, accountLevel: nil, accountDetails: nil, transactions: networkTransactions, transactionLevel: TransactionCatLevel.group, transactionDetails: transactionDetails, filterAccounts: nil) { _, _, _, transDetailsStatsCurrent, _, transactionValuesCurrent, _ in
                guard let transDetailsStatsCurrent = transDetailsStatsCurrent, let transactionValuesCurrent = transactionValuesCurrent, let expenseDetailsCurrent = transDetailsStatsCurrent.keys.first(where: {$0.name == "Expense"}), let statsCurrent = transDetailsStatsCurrent[expenseDetailsCurrent], !transDetailsStatsCurrent.keys.filter( {$0.name != "Expense"}).isEmpty, let previousRange = self.range.previousDatesForComparison() else {
                    newChartViewModel.chartData = nil
                    newChartViewModel.categories = []
                    newChartViewModel.rangeAverageValue = "-"
                    self.chartViewModel.send(newChartViewModel)
                    self.transactions = []
                    completion?()
                    return
                }
                
                self.financeService.getSamples(financialType: .transactions, segmentType: self.range.timeSegment, range: previousRange, accounts: nil, accountLevel: nil, accountDetails: nil, transactions: networkTransactions, transactionLevel: TransactionCatLevel.group, transactionDetails: transactionDetails, filterAccounts: nil) { _, _, _, transDetailsStatsPast, _, transactionValuesPast, _ in
                    
                    self.dataExists = true
                    
                    let daysInRange = self.range.daysInRange + 1
                    let startDateCurrent = self.range.startDate.startOfDay
                    let startDatePast = self.range.pastStartDate?.startOfDay ?? startDateCurrent
                    
                    self.transactions = Array(Set(transactionValuesCurrent + (transactionValuesPast ?? [])))
                                
                    DispatchQueue.global(qos: .userInteractive).async {
                        var chartDataSets = [LineChartDataSet]()
                        var categories: [CategorySummaryViewModel] = []
                        
                        var totalValue: Double = 0
                        var cumulative: Double = 0
                        var dataEntries = (0...daysInRange).map { index -> ChartDataEntry in
                            let current = startDateCurrent.addDays(index)
                            if let stat = statsCurrent.first(where: {$0.date == current}) {
                                cumulative += stat.value
                            }
                            return ChartDataEntry(x: Double(index) + 1, y: cumulative, data: current)
                        }
                        
                        totalValue += cumulative
                        
                        let chartDataSetCurrent = LineChartDataSet(entries: dataEntries)
                        chartDataSetCurrent.setDrawHighlightIndicators(false)
                        chartDataSetCurrent.axisDependency = .right
                        chartDataSetCurrent.colors = [NSUIColor.systemBlue]
                        chartDataSetCurrent.lineWidth = 5
                        chartDataSetCurrent.fillAlpha = 0
                        chartDataSetCurrent.drawFilledEnabled = true
                        chartDataSetCurrent.drawCirclesEnabled = false
                                                
                        let categoryCurrent = CategorySummaryViewModel(title: "This " + (self.range.type?.title ?? ""),
                                                                       color: .systemBlue,
                                                                       value: cumulative,
                                                                       formattedValue: "\(self.currencyFormatter.string(from: NSNumber(value: cumulative))!)")
                        categories.append(categoryCurrent)
                                                                        
                        if let transDetailsStatsPast = transDetailsStatsPast, let expenseDetailsPast = transDetailsStatsPast.keys.first(where: {$0.name == "Expense"}), let statsPast = transDetailsStatsPast[expenseDetailsPast], !transDetailsStatsPast.keys.filter({$0.name != "Expense"}).isEmpty {
                                                        
                            let spendingDetailsPast = transDetailsStatsPast.keys.filter( {$0.name != "Expense"})
                            var categoriesPast: [CategorySummaryViewModel] = []
                            
                            for detail in spendingDetailsPast {
                                let finalAmount = detail.amount
                                if let formatterValue = self.currencyFormatter.string(from: NSNumber(value: finalAmount)) {
                                    categoriesPast.append(CategorySummaryViewModel(title: detail.name,
                                                                               color: .systemBlue,
                                                                               value: finalAmount,
                                                                               formattedValue: formatterValue))
                                }
                            }
                            
                            var cumulative: Double = 0
                            dataEntries = (0...daysInRange).map { index -> ChartDataEntry in
                                let current = startDatePast.addDays(index)
                                if let stat = statsPast.first(where: {$0.date == current}) {
                                    cumulative += stat.value
                                }
                                return ChartDataEntry(x: Double(index) + 1, y: cumulative, data: current)
                            }
                            
                            totalValue -= cumulative
                            
                            let chartDataSetPast = LineChartDataSet(entries: dataEntries)
                            chartDataSetPast.setDrawHighlightIndicators(false)
                            chartDataSetPast.axisDependency = .right
                            chartDataSetPast.colors = [NSUIColor.systemGray4]
                            chartDataSetPast.lineWidth = 5
                            chartDataSetPast.fillAlpha = 0
                            chartDataSetPast.drawFilledEnabled = true
                            chartDataSetPast.drawCirclesEnabled = false
                            chartDataSets.append(chartDataSetPast)
                            
                            let categoryCurrent = CategorySummaryViewModel(title: "Last " + (self.range.type?.title ?? ""),
                                                                           color: .secondaryLabel,
                                                                           value: cumulative,
                                                                           formattedValue: "\(self.currencyFormatter.string(from: NSNumber(value: cumulative))!)")
                            categories.append(categoryCurrent)
                            
                        }
                        
                        chartDataSets.append(chartDataSetCurrent)
                        
                        newChartViewModel.categories = categories
                        
                        if totalValue > 0 {
                            newChartViewModel.rangeAverageValue = "Spent \(self.currencyFormatter.string(from: NSNumber(value: totalValue))!) More"
                        } else {
                            newChartViewModel.rangeAverageValue = "Spent \(self.currencyFormatter.string(from: NSNumber(value: totalValue * -1))!) Less"
                        }
                                            
                        DispatchQueue.main.async {
                            let chartData = LineChartData(dataSets: chartDataSets)
                            chartData.setDrawValues(false)
                            newChartViewModel.chartData = chartData
                            self.chartViewModel.send(newChartViewModel)
                            completion?()
                        }
                    }
                }
            }
        case .horizontalBar:
            break
        case .verticalBar:
            break
        }
    }
    
    func fetchEntries(range: DateRange, completion: ([AnalyticsBreakdownEntry]) -> Void) {
        if range.filterOff {
            completion(transactions.sorted(by: {
                if let date1 = $0.transactionDate, let date2 = $1.transactionDate {
                    return date1 > date2
                }
                return $0.description < $1.description
            }).map { .transaction($0) })
        } else {
            switch chartViewModel.value.chartType {
            case .line:
                let startDate = range.startDate.dayBefore
                let endDate = range.endDate.dayBefore
                let filteredTransactions = transactions
                    .filter { transaction -> Bool in
                        guard let date = transaction.transactionDate else { return false }
                        return startDate <= date && date <= endDate
                    }
                completion(filteredTransactions.map { .transaction($0) })
            case .horizontalBar:
                let filteredTransactions = transactions
                    .filter { transaction -> Bool in
                        guard let date = transaction.transactionDate else { return false }
                        return range.startDate <= date && date <= range.endDate
                    }
                completion(filteredTransactions.map { .transaction($0) })
            case .verticalBar:
                let filteredTransactions = transactions
                    .filter { transaction -> Bool in
                        guard let date = transaction.transactionDate else { return false }
                        return range.startDate <= date && date <= range.endDate
                    }
                completion(filteredTransactions.map { .transaction($0) })
            }
        }
    }
}

private let dateFormatter = ISO8601DateFormatter()
