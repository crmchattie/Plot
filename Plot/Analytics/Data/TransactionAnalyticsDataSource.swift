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
    DateRangeFormatter(currentWeek: "This week", currentMonth: "This month", currentYear: "This year")
        .format(range: range)
}

class TransactionAnalyticsDataSource: AnalyticsDataSource {
    
    private let networkController: NetworkController
    private let financeService = FinanceDetailService()
    
    var range: DateRange
    
    var title: String = "Transactions"
    
    let chartViewModel: CurrentValueSubject<StackedBarChartViewModel, Never>
    
    private var transactions: [Transaction] = []
    
    init(
        range: DateRange,
        networkController: NetworkController
    ) {
        self.range = range
        self.networkController = networkController
        
        chartViewModel = .init(StackedBarChartViewModel(chartType: .values,
                                                        rangeDescription: getTitle(range: range),
                                                        horizontalAxisValueFormatter: range.axisValueFormatter,
                                                        fixToZeroOnVertical: false))
    }
    
    func loadData(completion: (() -> Void)?) {
        var newChartViewModel = chartViewModel.value
        newChartViewModel.rangeDescription = getTitle(range: range)
        newChartViewModel.horizontalAxisValueFormatter = range.axisValueFormatter
        
        let daysInRange = range.daysInRange
        
        transactions = networkController.financeService.transactions
            .filter { $0.type == "DEBIT" || $0.type == "CREDIT" }
            .filter { transaction -> Bool in
                #warning("This is extremely unoptimal. A stored Date object should be saved inside the Transaction.")
                guard let date = dateFormatter.date(from: transaction.created_at) else { return false }
                return range.startDate <= date && date <= range.endDate
            }
        
        var incomeValue: Double = 0
        var expenseValue: Double = 0
        
        var categoryValues: [[Double]] = []
        var categoryColors: [UIColor] = []
        var categories: [CategorySummaryViewModel] = []
        
        transactions.grouped(by: \.top_level_category).forEach { (category, transactions) in
            var values: [Double] = Array(repeating: 0, count: daysInRange + 1)
            var sum: Double = 0
            transactions.forEach { transaction in
                guard let day = dateFormatter.date(from: transaction.created_at) else { return }
                let daysInBetween = day.daysSince(range.startDate)
                if transaction.is_income ?? false {
                    incomeValue += transaction.amount
                    values[daysInBetween] += transaction.amount
                } else {
                    expenseValue += transaction.amount
                    values[daysInBetween] -= transaction.amount
                }
                sum += transaction.amount
            }
            
            let categoryColor = topLevelCategoryColor(category)
            categories.append(CategorySummaryViewModel(title: category,
                                                       color: categoryColor,
                                                       value: sum,
                                                       formattedValue: "$\(Int(sum))"))
            categoryColors.append(categoryColor)
            categoryValues.append(values)
        }
        
        newChartViewModel.categories = Array(categories.sorted(by: { $0.value > $1.value }).prefix(3))
        newChartViewModel.rangeAverageValue = "out $\(Int(expenseValue)), in $\(Int(incomeValue))"
        
        let dataEntries = (0...daysInRange).map { index in
            BarChartDataEntry(x: Double(index) + 0.5, yValues: categoryValues.map { $0[index] })
        }
        
        if !transactions.isEmpty {
            let chartDataSet = BarChartDataSet(entries: dataEntries)
            if !categoryColors.isEmpty {
                chartDataSet.colors = categoryColors
            }
            let chartData = BarChartData(dataSets: [chartDataSet])
            chartData.barWidth = 0.5
            chartData.setDrawValues(false)
            newChartViewModel.chartData = chartData
        } else {
            newChartViewModel.chartData = nil
        }
        
        chartViewModel.send(newChartViewModel)
        completion?()
    }
    
    func fetchEntries(range: DateRange, completion: ([AnalyticsBreakdownEntry]) -> Void) {
        completion(transactions.map { .transaction($0) })
    }
}

private let dateFormatter = ISO8601DateFormatter()
