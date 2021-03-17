//
//  ActivityStackedBarChartViewModel.swift
//  Plot
//
//  Created by Botond Magyarosi on 16.03.2021.
//  Copyright © 2021 Immature Creations. All rights reserved.
//

import Foundation
import Charts
import Combine

private let dateFormatter: DateComponentsFormatter = {
    let formatter = DateComponentsFormatter()
    formatter.unitsStyle = .abbreviated
    formatter.allowedUnits = [.hour, .minute]
    return formatter
}()

struct ActivityStackedBarChartViewModel: StackedBarChartViewModel {
    
    let onChange = PassthroughSubject<Void, Never>()

    let sectionTitle: String = "Activities"
    private(set) var title: String = "Daily average"
    private(set) var description: String
    
    var categories: [CategorySummaryViewModel]
    
    let chartData: BarChartData

    init(items: [String: [Statistic]]) {
        let colors = Array(ChartColors.palette().prefix(items.count))
        var categories: [CategorySummaryViewModel] = []
        var average: Double = 0
        for (index, (category, stats)) in items.enumerated() {
            let total = stats.reduce(0, { $0 + $1.value * 60 })
            let totalString = dateFormatter.string(from: total) ?? "NaN"
            categories.append(CategorySummaryViewModel(title: category,
                                                       color: colors[index],
                                                       value: total,
                                                       formattedValue: totalString))
            average += total
        }
        average /= 7
        self.categories = Array(categories.sorted(by: { $0.value > $1.value }).prefix(3))
        
        description = dateFormatter.string(from: average) ?? "NaN"
        
        let firstDay = Date().startOfWeek
        let dataEntries = (0..<7).map { index -> BarChartDataEntry in
            let current = firstDay.addDays(index)
            let yValues = items.map {
                $0.value.filter({ $0.date.isSameDay(as: current) }).reduce(0, { $0 + $1.value * 60 })
            }
            return BarChartDataEntry(x: Double(index) + 0.5, yValues: yValues)
        }
        
        let chartDataSet = BarChartDataSet(entries: dataEntries)
        chartDataSet.colors = colors
        chartData = BarChartData(dataSets: [chartDataSet])
        chartData.barWidth = 0.5
        chartData.setDrawValues(false)
    }
}
