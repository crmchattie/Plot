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
    let verticalAxisValueFormatter: IAxisValueFormatter = HourValueFormatter()
    
    let sectionTitle: String = "Activities"
    private(set) var title: String = "This week"
    private(set) var description: String
    
    var categories: [CategorySummaryViewModel]
    
    let chartData: BarChartData

    init(items: [String: [Statistic]], range: (Date, Date)) {
        let colors = Array(ChartColors.palette().prefix(items.count))
        var categories: [CategorySummaryViewModel] = []
        var activityCount = 0
        for (index, (category, stats)) in items.enumerated() {
            let total = stats.reduce(0, { $0 + $1.value * 60 })
            let totalString = dateFormatter.string(from: total) ?? "NaN"
            categories.append(CategorySummaryViewModel(title: category,
                                                       color: colors[index],
                                                       value: total,
                                                       formattedValue: totalString))
            activityCount += stats.count
        }
        self.categories = Array(categories.sorted(by: { $0.value > $1.value }).prefix(3))
        
        description = "\(activityCount) activities"
        
        let firstDay = range.0
        let daysToCover = range.1.daysSince(range.0)
        let dataEntries = (0..<daysToCover).map { index -> BarChartDataEntry in
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
