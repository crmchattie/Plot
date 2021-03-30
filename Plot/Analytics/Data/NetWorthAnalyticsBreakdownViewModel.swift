//
//  NetWorthAnalyticsBreakdownViewModel.swift
//  Plot
//
//  Created by Botond Magyarosi on 28.03.2021.
//  Copyright © 2021 Immature Creations. All rights reserved.
//

import Foundation
import Combine
import Charts

// Spending over time + net worth
class NetWorthAnalyticsBreakdownViewModel: AnalyticsBreakdownViewModel {
    
    private let networkController: NetworkController
    private let financeService = FinanceDetailService()
    
    let onChange = PassthroughSubject<Void, Never>()
    let verticalAxisValueFormatter: IAxisValueFormatter = IntAxisValueFormatter()
    let fixToZeroOnVertical: Bool = true
    var range: DateRange
    
    var title: String = "Net worth"
    private(set) var rangeDescription: String = "-"
    private(set) var rangeAverageValue: String = "_"

    var categories: [CategorySummaryViewModel] = []
    
    private(set) var chartData: ChartData? = nil
    private var transactions: [Transaction] = []

    init(
        range: DateRange,
        networkController: NetworkController
    ) {
        self.range = range
        self.networkController = networkController
        updateTitle()
    }
    
    func loadData(completion: (() -> Void)?) {
        updateTitle()
        let daysInRange = range.daysInRange
        
        let accounts = networkController.financeService.accounts
        let transactions = networkController.financeService.transactions
        
        let detail = AccountDetails(name: "Net Worth", balance: 0, level: .bs_type, subtype: nil, type: nil, bs_type: .NetWorth, currencyCode: "USD")
        financeService.getSamples(for: range, accountDetails: detail, transactionDetails: nil, accounts: accounts, transactions: transactions) { [range] (stats, _, _, _) in
            let stats = stats ?? []
            
//            self.transactions = self.networkController.financeService.transactions
//                .filter { $0.type == "DEBIT" || $0.type == "CREDIT" }
//                .filter { transaction -> Bool in
//                    guard let date = dateFormatter.date(from: transaction.created_at) else { return false }
//                    return range.startDate <= date && date <= range.endDate
//                }
            
            var dataEntries: [BarChartDataEntry] = []
            var maxValue: Double = 0
            var firstValue: Double?
            var lastValue: Double?
            for (index, stat) in stats.enumerated() {
                maxValue = max(maxValue, stat.value)
                if firstValue == nil { firstValue = stat.value }
                else { lastValue = stat.value }
                dataEntries.append(BarChartDataEntry(x: Double(index), y: stat.value, data: stat.date))
            }
            maxValue *= 1.2
            
            let chartDataSet = BarChartDataSet(entries: dataEntries)
            
            if let firstValue = firstValue, let lastValue = lastValue {
                self.rangeAverageValue = currencyFormatter.string(from: NSNumber(value: lastValue - firstValue))!
            } else {
                self.rangeAverageValue = "-"
            }
            
            chartDataSet.colors = [.green]
            let chartData = BarChartData(dataSets: [chartDataSet])
//            chartData.barWidth = 0.5
            chartData.setDrawValues(false)
            
            self.chartData = chartData
            self.onChange.send()
            completion?()
        }
    }
    
    func fetchEntries(range: DateRange, completion: ([AnalyticsBreakdownEntry]) -> Void) {
        completion(transactions.map { .transaction($0) })
    }
    
    // MARK: - Private
    
    private func updateTitle() {
        rangeDescription = DateRangeFormatter(currentWeek: "This week", currentMonth: "This month", currentYear: "This year")
            .format(range: range)
    }
}

private let dateFormatter = ISO8601DateFormatter()

private var currencyFormatter: NumberFormatter = {
    let numberFormatter = NumberFormatter()
    numberFormatter.currencyCode = "USD"
    numberFormatter.positivePrefix = "+"
    numberFormatter.numberStyle = .currency
    return numberFormatter
}()
