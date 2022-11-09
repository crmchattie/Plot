//
//  NetWorthAnalyticsDataSource.swift
//  Plot
//
//  Created by Botond Magyarosi on 28.03.2021.
//  Copyright © 2021 Immature Creations. All rights reserved.
//

import Foundation
import Combine
import Charts

private func getTitle(range: DateRange) -> String {
    DateRangeFormatter(currentWeek: "The last week", currentMonth: "The last month", currentYear: "The last year")
        .format(range: range)
}

class NetWorthAnalyticsDataSource: AnalyticsDataSource {
    
    private let networkController: NetworkController
    private let financeService = FinanceDetailService()
    
    var range: DateRange
    
    var title: String = "Net worth"
    
    let chartViewModel: CurrentValueSubject<StackedBarChartViewModel, Never>

    private var accounts: [MXAccount] = []
    
    private lazy var dateFormatter = ISO8601DateFormatter()

    var currencyFormatter: NumberFormatter = {
        let numberFormatter = NumberFormatter()
        numberFormatter.currencyCode = "USD"
        numberFormatter.numberStyle = .currency
        numberFormatter.maximumFractionDigits = 0
        return numberFormatter
    }()

    init(
        range: DateRange,
        networkController: NetworkController
    ) {
        self.range = range
        self.networkController = networkController
        
        chartViewModel = .init(StackedBarChartViewModel(chartType: .continous,
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
        
        let accounts = networkController.financeService.accounts
        
        let detail = AccountDetails(name: "Net Worth", balance: 0, level: .bs_type, subtype: nil, type: nil, bs_type: .NetWorth, currencyCode: "USD")
        financeService.getSamples(for: range, segment: range.timeSegment, accountDetails: detail, transactionDetails: nil, accounts: accounts, transactions: nil) { (stats, _, _, _) in
            let stats = stats ?? []
            
            self.accounts = self.networkController.financeService.accounts
                .filter { $0.should_link ?? true }
                .sorted(by: { $0.updated_at > $1.updated_at })
            
            if stats.isEmpty {
                newChartViewModel.chartData = nil
                self.chartViewModel.send(newChartViewModel)
                completion?()
                return
            }
            
            var dataEntries: [ChartDataEntry] = []
            var firstValue: Double?
            var lastValue: Double?
            for (index, stat) in stats.enumerated() {
                if firstValue == nil { firstValue = stat.value }
                else { lastValue = stat.value }
                dataEntries.append(ChartDataEntry(x: Double(index) + 1, y: stat.value, data: stat.date))
            }
            
            if let firstValue = firstValue, let lastValue = lastValue {
                newChartViewModel.rangeAverageValue = self.currencyFormatter.string(from: NSNumber(value: lastValue - firstValue))!
            } else {
                newChartViewModel.rangeAverageValue = "-"
            }
            
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
    
    func fetchEntries(range: DateRange, completion: ([AnalyticsBreakdownEntry]) -> Void) {
        completion(accounts.map { .account($0) })
    }
}
