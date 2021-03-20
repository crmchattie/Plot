//
//  HealthStackedBarChartViewModel.swift
//  Plot
//
//  Created by Botond Magyarosi on 17.03.2021.
//  Copyright © 2021 Immature Creations. All rights reserved.
//

import Foundation
import Charts
import Combine
import HealthKit

struct HealthStackedBarChartViewModel: StackedBarChartViewModel {
    
    let onChange = PassthroughSubject<Void, Never>()
    let verticalAxisValueFormatter: IAxisValueFormatter = IntAxisValueFormatter()

    var sectionTitle: String = "Health"
    let title: String = "Daily average"
    let description: String
    
    var categories: [CategorySummaryViewModel] = []

    let chartData: BarChartData

    init(summary: [HKActivitySummary], range: (Date, Date)) {
        let daysToCover = range.1.daysSince(range.0)
        
        var values: [Int: Double] = [:]
        var averange: Double = 0
        summary.forEach { summary in
            guard let entryDate = summary.dateComponents(for: .current).date else { return }
            let indexInRange = entryDate.daysSince(range.0)
            let value = summary.activeEnergyBurned.doubleValue(for: HKUnit.kilocalorie())
            values[indexInRange] = value
            averange += value
        }
        averange /= Double(range.1.daysSince(range.0))
        description = "\(Int(averange)) kcal"
        
        let dataEntries = (0..<daysToCover).map {
            BarChartDataEntry(x: Double($0) + 0.5, y: values[$0] ?? 0)
        }
        
        let chartDataSet = BarChartDataSet(entries: dataEntries)
        chartDataSet.colors = [.red]
        chartData = BarChartData(dataSets: [chartDataSet])
        chartData.barWidth = 0.5
        chartData.setDrawValues(false)
    }
}
