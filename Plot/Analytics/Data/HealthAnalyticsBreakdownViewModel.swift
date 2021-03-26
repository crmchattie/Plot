//
//  HealthAnalyticsBreakdownViewModel.swift
//  Plot
//
//  Created by Botond Magyarosi on 17.03.2021.
//  Copyright © 2021 Immature Creations. All rights reserved.
//

import Foundation
import Charts
import Combine
import HealthKit

// Active calories + consumed calories
struct HealthAnalyticsBreakdownViewModel: AnalyticsBreakdownViewModel {
    
    private let networkController: NetworkController
    
    let onChange = PassthroughSubject<Void, Never>()
    let verticalAxisValueFormatter: IAxisValueFormatter = IntAxisValueFormatter()
    var canNavigate: Bool
    var range: DateRange
    
    var sectionTitle: String = "Health"
    let title: String
    let description: String
    
    var categories: [CategorySummaryViewModel] = []

    let chartData: BarChartData

    init(
        activity: [HKActivitySummary],
        energyConsumed: [HKQuantitySample],
        range: DateRange,
        canNavigate: Bool,
        networkController: NetworkController
    ) {
        self.networkController = networkController
        self.canNavigate = canNavigate
        self.range = range
        
        let daysToCover = range.endDate.daysSince(range.startDate)
        
        var energyValues: [Int: Double] = [:]
        var dietaryValues: [Int: Double] = [:]
        var average: Double = 0
        activity.forEach { summary in
            guard let entryDate = summary.dateComponents(for: .current).date else { return }
            let indexInRange = entryDate.daysSince(range.startDate)
            let value = summary.activeEnergyBurned.doubleValue(for: HKUnit.kilocalorie())
            energyValues[indexInRange] = value
            average += value
        }
        average /= Double(daysToCover)
        description = "\(Int(average)) kcal"
        
        title = DateRangeFormatter(currentWeek: "Daily average", currentMonth: "Monthly average", currentYear: "Yearly average")
            .format(range: range)
        
        energyConsumed.forEach { summary in
            let indexInRange = summary.startDate.daysSince(range.startDate)
            let value = summary.quantity.doubleValue(for: HKUnit.kilocalorie())
            dietaryValues[indexInRange] = value
        }
        
        let dataEntries = (0...daysToCover).map {
            BarChartDataEntry(x: Double($0) + 0.5, y: energyValues[$0] ?? 0)
        }
        
        let dataEntries2 = (0...daysToCover).map {
            BarChartDataEntry(x: Double($0) + 0.5, y: dietaryValues[$0] ?? 0)
        }
        
        let chartDataSet = BarChartDataSet(dataEntries)
        chartDataSet.colors = [.red]
        let dataSet2 = BarChartDataSet(dataEntries2)
        dataSet2.colors = [.green]
        chartData = BarChartData(dataSets: [chartDataSet, dataSet2])
//        float barSpace = 0.02f; // x2 dataset
//        float barWidth = 0.45f; // x2 dataset
        chartData.groupBars(fromX: 0, groupSpace: 0.1, barSpace: 0.2)
//        chartData.groupWidth(groupSpace: 0.1, barSpace: 0.1)
//        // make this BarData object grouped
//        [d groupBarsFromX:0.0 groupSpace:groupSpace barSpace:barSpace]; // start at x = 0
        chartData.barWidth = 0.5
        chartData.setDrawValues(false)
    }
    
    func fetchEntries(range: DateRange, completion: ([AnalyticsBreakdownEntry]) -> Void) {
        print(networkController.healthService.nutrition)
        completion([])
    }
}
