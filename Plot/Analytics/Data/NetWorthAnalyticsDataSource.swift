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
    DateRangeFormatter(currentWeek: "Over the last week", currentMonth: "Over the last month", currentYear: "Over the last year")
        .format(range: range)
}

class NetWorthAnalyticsDataSource: AnalyticsDataSource {
    func updateRange(_ newRange: DateRange) {
        
    }
    
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
        
        let accounts = networkController.financeService.accounts
        
        financeService.getSamples(financialType: .accounts, segmentType: range.timeSegment, range: range, accounts: accounts, accountLevel: AccountCatLevel.bs_type, transactions: nil, transactionLevel: nil, filterAccounts: nil) { accountDetailsStats, _, accountValues, _, _, _, _ in
            guard let accountDetailsStats = accountDetailsStats, let accountValues = accountValues, let netWorthDetails = accountDetailsStats.keys.first(where: {$0.name == "Net Worth"}), let stats = accountDetailsStats[netWorthDetails] else {
                newChartViewModel.chartData = nil
                self.chartViewModel.send(newChartViewModel)
                completion?()
                return
            }
            self.dataExists = true
            
            self.accounts = accountValues.sorted(by: { $0.name < $1.name })
            
            DispatchQueue.global(qos: .userInteractive).async {
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
        completion(accounts.map { .account($0) })
    }
}
