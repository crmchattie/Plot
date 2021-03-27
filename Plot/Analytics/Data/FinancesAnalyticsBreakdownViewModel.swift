//
//  FinancesAnalyticsBreakdownViewModel.swift
//  Plot
//
//  Created by Botond Magyarosi on 20.03.2021.
//  Copyright © 2021 Immature Creations. All rights reserved.
//

import Foundation
import Combine
import Charts

// Spending over time + net worth
class FinancesAnalyticsBreakdownViewModel: AnalyticsBreakdownViewModel {
    
    let onChange = PassthroughSubject<Void, Never>()
    let verticalAxisValueFormatter: IAxisValueFormatter = IntAxisValueFormatter()
    var canNavigate: Bool
    var range: DateRange
    
    var sectionTitle: String = "Health"
    let title: String = "Daily average"
    let description: String = "6h 1m"

    var categories: [CategorySummaryViewModel] = []
    
    private(set) var chartData: ChartData? = nil

    init(
        canNavigate: Bool,
        range: DateRange
    ) {
        self.canNavigate = canNavigate
        self.range = range
        let dataEntries = (0..<7).map {
            BarChartDataEntry(x: Double($0) + 0.5, yValues: [Double.random(in: 0...20), Double.random(in: 0...20), Double.random(in: 0...20)])
        }
        let chartDataSet = BarChartDataSet(entries: dataEntries)
        chartDataSet.colors = [.blue, .orange, .darkGray]
        let chartData = BarChartData(dataSets: [chartDataSet])
        chartData.barWidth = 0.5
        chartData.setDrawValues(false)
        
        self.chartData = chartData
    }
    
    func loadData(completion: (() -> Void)?) {
        
    }
    
    func fetchEntries(range: DateRange, completion: ([AnalyticsBreakdownEntry]) -> Void) {
        completion([])
    }
}
