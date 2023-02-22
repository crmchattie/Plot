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
    DateRangeFormatter(currentWeek: "Over the last week", currentMonth: "Over the last month", currentYear: "Over the last year")
        .format(range: range)
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
                                                        units: "currencyShifted",
                                                        formatType: range.timeSegment))
    }
    
    func loadData(completion: (() -> Void)?) {
        var newChartViewModel = chartViewModel.value
        newChartViewModel.rangeDescription = getTitle(range: range)
        newChartViewModel.formatType = range.timeSegment
        
        let networkTransactions = networkController.financeService.transactions
        let daysInRange = range.daysInRange + 1
        let startDate = range.startDate.startOfDay
                
        financeService.getSamples(financialType: .transactions, segmentType: range.timeSegment, range: range, accounts: nil, accountLevel: nil, transactions: networkTransactions, transactionLevel: TransactionCatLevel.group, filterAccounts: nil) { _, _, _, transDetailsStats, _, transactionValues, _ in
            guard let transDetailsStats = transDetailsStats, let transactionValues = transactionValues, let expenseDetails = transDetailsStats.keys.first(where: {$0.name == "Expense"}), let stats = transDetailsStats[expenseDetails], !transDetailsStats.keys.filter( {$0.name != "Income" && $0.name != "Expense" && $0.name != "Net Savings" && $0.name != "Net Spending"}).isEmpty else {
                newChartViewModel.chartData = nil
                newChartViewModel.categories = []
                newChartViewModel.rangeAverageValue = "-"
                self.chartViewModel.send(newChartViewModel)
                completion?()
                return
            }
            
            self.dataExists = true
            
            self.transactions = transactionValues.sorted(by: { (transaction1, transaction2) -> Bool in
                if transaction1.should_link ?? true == transaction2.should_link ?? true {
                    if let date1 = dateFormatter.date(from: transaction1.transacted_at), let date2 = dateFormatter.date(from: transaction2.transacted_at) {
                        return date1 > date2
                    }
                    return transaction1.description < transaction2.description
                }
                return transaction1.should_link ?? true && !(transaction2.should_link ?? true)
            })
                        
            DispatchQueue.global(qos: .userInteractive).async {
                let spendingDetails = transDetailsStats.keys.filter( {$0.name != "Income" && $0.name != "Expense" && $0.name != "Net Savings" && $0.name != "Net Spending"})
                var categories: [CategorySummaryViewModel] = []
                
                for detail in spendingDetails {
                    let finalAmount = detail.amount * -1
                    if let formatterValue = self.currencyFormatter.string(from: NSNumber(value: finalAmount)) {
                        categories.append(CategorySummaryViewModel(title: detail.name,
                                                                   color: .systemBlue,
                                                                   value: finalAmount,
                                                                   formattedValue: formatterValue))
                    }
                }
                
                categories.sort(by: { $0.value > $1.value })
                
                newChartViewModel.categories = Array(categories.prefix(3))
                
                let totalValue = expenseDetails.amount * -1
                
                if totalValue > 0 {
                    newChartViewModel.rangeAverageValue = "Spent \(self.currencyFormatter.string(from: NSNumber(value: totalValue))!)"
                } else {
                    newChartViewModel.rangeAverageValue = "Saved \(self.currencyFormatter.string(from: NSNumber(value: totalValue))!)"

                }
                
                var cumulativeSpend: Double = 0
                let dataEntries = (0...daysInRange).map { index -> ChartDataEntry in
                    let current = startDate.addDays(index)
                    if let stat = stats.first(where: {$0.date == current}) {
                        cumulativeSpend += stat.value
                    }
                    return ChartDataEntry(x: Double(index) + 1, y: cumulativeSpend, data: current)
                }
                
                DispatchQueue.main.async {
                    let chartDataSet = LineChartDataSet(entries: dataEntries)
                    chartDataSet.setDrawHighlightIndicators(false)
                    chartDataSet.axisDependency = .right
                    chartDataSet.fillColor = .systemBlue
                    chartDataSet.fillAlpha = 1
                    chartDataSet.drawFilledEnabled = true
                    chartDataSet.drawCirclesEnabled = false
                    let chartData = LineChartData(dataSets: [chartDataSet])
                    chartData.setDrawValues(false)
                    newChartViewModel.chartData = chartData
                    self.chartViewModel.send(newChartViewModel)
                    completion?()
                }
            }
        }
    }
    
    func fetchEntries(range: DateRange, completion: ([AnalyticsBreakdownEntry]) -> Void) {
        if range.filterOff {
            completion(transactions.map { .transaction($0) })
        } else {
            let startDate = range.startDate.dayBefore
            let endDate = range.endDate.dayBefore
            let filteredTransactions = transactions
                .filter { transaction -> Bool in
                    guard let date = dateFormatter.date(from: transaction.transacted_at) else { return false }
                    return startDate <= date && date <= endDate
                }
            completion(filteredTransactions.map { .transaction($0) })
        }
    }
}

private let dateFormatter = ISO8601DateFormatter()

//bar chart with daily spend broken down into categories

//transactions = networkController.financeService.transactions
//    .filter { $0.should_link ?? true }
//    .filter { $0.top_level_category != "Investments" && $0.category != "Investments" }
//    .filter { $0.group != "Income" }
//    .filter { transaction -> Bool in
////                #warning("This is extremely unoptimal. A stored Date object should be saved inside the Transaction.")
//        guard let date = dateFormatter.date(from: transaction.transacted_at) else { return false }
//        return range.startDate <= date && date <= range.endDate
//    }
//
//var totalValue: Double = 0
//var categoryValues: [[Double]] = []
//var categoryColors: [UIColor] = []
//var categories: [CategorySummaryViewModel] = []
//
//transactions.grouped(by: \.group).forEach { (category, transactions) in
//    var values: [Double] = Array(repeating: 0, count: daysInRange + 1)
//    var sum: Double = 0
//    transactions.forEach { transaction in
//        guard let day = dateFormatter.date(from: transaction.transacted_at) else { return }
//        let daysInBetween = day.daysSince(range.startDate)
//        if transaction.type == .credit {
//            totalValue -= transaction.amount
//            values[daysInBetween] -= transaction.amount
//            sum -= transaction.amount
//        } else {
//            totalValue += transaction.amount
//            values[daysInBetween] += transaction.amount
//            sum += transaction.amount
//        }
//    }
//
//    var categoryColor = UIColor()
//    if let index = financialTransactionsGroupsStatic.firstIndex(where: {$0 == category} ) {
//        categoryColor = ChartColors.palette()[index % 9]
//    } else {
//        categoryColor = topLevelCategoryColor(category)
//    }
//    categories.append(CategorySummaryViewModel(title: category,
//                                               color: categoryColor,
//                                               value: sum,
//                                               formattedValue: self.currencyFormatter.string(from: NSNumber(value: sum))!))
//    categoryColors.append(categoryColor)
//    categoryValues.append(values)
//}
//
//newChartViewModel.categories = Array(categories.sorted(by: { $0.value > $1.value }).prefix(3))
//if totalValue > 0 {
//    newChartViewModel.rangeAverageValue = "Spent \(self.currencyFormatter.string(from: NSNumber(value: totalValue))!)"
//} else {
//    newChartViewModel.rangeAverageValue = "Saved \(self.currencyFormatter.string(from: NSNumber(value: totalValue))!)"
//
//}
//let dataEntries = (0...daysInRange).map { index -> BarChartDataEntry in
//    let current = self.range.startDate.addDays(index)
//    let yValues = categoryValues.map { $0[index] }
//    return BarChartDataEntry(x: Double(index) + 0.5, yValues: yValues, data: current)
//}
//
//if !transactions.isEmpty {
//    dataExists = true
//    let chartDataSet = BarChartDataSet(entries: dataEntries)
//    chartDataSet.axisDependency = .right
//    if !categoryColors.isEmpty {
//        chartDataSet.colors = categoryColors
//    }
//    let chartData = BarChartData(dataSets: [chartDataSet])
//    chartData.setDrawValues(false)
//    newChartViewModel.chartData = chartData
//} else {
//    newChartViewModel.chartData = nil
//    newChartViewModel.categories = []
//    newChartViewModel.rangeAverageValue = "-"
//}
//
//chartViewModel.send(newChartViewModel)
//completion?()
