//
//  HealthAnalyticsDataSource.swift
//  Plot
//
//  Created by Botond Magyarosi on 17.03.2021.
//  Copyright © 2021 Immature Creations. All rights reserved.
//

import Foundation
import Charts
import Combine
import HealthKit

private func getTitle(range: DateRange) -> String {
    DateRangeFormatter(currentWeek: "Daily average", currentMonth: "Monthly average", currentYear: "Yearly average")
        .format(range: range)
}

// Active calories + consumed calories
class HealthAnalyticsDataSource: AnalyticsDataSource {
    
    private let networkController: NetworkController
    private let healthStore = HKHealthStore()
    
    var range: DateRange

    var title: String = "Health"
    let chartViewModel: CurrentValueSubject<StackedBarChartViewModel, Never>
    
    init(
        range: DateRange,
        networkController: NetworkController
    ) {
        self.networkController = networkController
        self.range = range
     

        chartViewModel = .init(StackedBarChartViewModel(chartType: .values,
                                                        rangeDescription: getTitle(range: range),
                                                        horizontalAxisValueFormatter: range.axisValueFormatter))
    }
    
    func loadData(completion: (() -> Void)?) {
        var newChartViewModel = chartViewModel.value
        newChartViewModel.rangeDescription = getTitle(range: range)
        newChartViewModel.horizontalAxisValueFormatter = range.axisValueFormatter
        
        let predicate: NSPredicate = {
            let units: Set<Calendar.Component> = [.day, .month, .year]
            var startDate = Calendar.current.dateComponents(units, from: range.startDate)
            startDate.calendar = .current
            var endDate = Calendar.current.dateComponents(units, from: range.endDate)
            endDate.calendar = .current
            return HKQuery.predicate(forActivitySummariesBetweenStart: startDate, end: endDate)
        }()
        
        let group = DispatchGroup()
        var eneryResult: [HKQuantitySample] = []
        var activityResult: [HKActivitySummary] = []
        
        let type = HKQuantityType.quantityType(forIdentifier: .dietaryEnergyConsumed)!
        let caloriesConsumedQuery = HKSampleQuery(sampleType: type, predicate: nil, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { (_, samples, error) in
            eneryResult = samples?.compactMap { $0 as? HKQuantitySample } ?? []
            group.leave()
        }
        
        let activityQuery = HKActivitySummaryQuery(predicate: predicate) { (_, summary, error) in
            activityResult = summary ?? []
            group.leave()
        }
        
        group.enter()
        healthStore.execute(activityQuery)
        group.enter()
        healthStore.execute(caloriesConsumedQuery)
        
        group.notify(queue: .main) { [range] in
            let daysInRange = range.daysInRange
            
            var energyValues: [Int: Double] = [:]
            var dietaryValues: [Int: Double] = [:]
            var average: Double = 0
            activityResult.forEach { summary in
                guard let entryDate = summary.dateComponents(for: .current).date else { return }
                let indexInRange = entryDate.daysSince(range.startDate)
                let value = summary.activeEnergyBurned.doubleValue(for: HKUnit.kilocalorie())
                energyValues[indexInRange] = value
                average += value
            }
            average /= Double(activityResult.count)
            if average.isInfinite || average.isNaN {
                average = 0
            }
            
            newChartViewModel.rangeAverageValue = "\(Int(average)) kcal"
    
            eneryResult.forEach { summary in
                let indexInRange = summary.startDate.daysSince(range.startDate)
                let value = summary.quantity.doubleValue(for: HKUnit.kilocalorie())
                dietaryValues[indexInRange] = value
            }
    
            let dataEntries = (0...daysInRange).map {
                BarChartDataEntry(x: Double($0) + 0.5, y: energyValues[$0] ?? 0)
            }
    
            let dataEntries2 = (0...daysInRange).map {
                BarChartDataEntry(x: Double($0) + 0.5, y: dietaryValues[$0] ?? 0)
            }
    
            let chartDataSet = BarChartDataSet(dataEntries)
            chartDataSet.colors = [.red]
            let dataSet2 = BarChartDataSet(dataEntries2)
            dataSet2.colors = [.green]
            let chartData = BarChartData(dataSets: [chartDataSet])
//            float barSpace = 0.02f; // x2 dataset
//            float barWidth = 0.45f; // x2 dataset
//            chartData.groupBars(fromX: 0, groupSpace: 0.1, barSpace: 0.2)
//            chartData.groupWidth(groupSpace: 0.1, barSpace: 0.1)
    //        // make this BarData object grouped
    //        [d groupBarsFromX:0.0 groupSpace:groupSpace barSpace:barSpace]; // start at x = 0
            chartData.barWidth = 0.5
            chartData.setDrawValues(false)
    
            newChartViewModel.chartData = chartData
            
            self.chartViewModel.send(newChartViewModel)
            completion?()
        }
    }
    
    func fetchEntries(range: DateRange, completion: ([AnalyticsBreakdownEntry]) -> Void) {
        print(networkController.healthService.nutrition)
        completion([])
    }
}
