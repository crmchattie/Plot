//
//  ActiveEnergyAnalyticsDataSource.swift
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

// Active calories
class ActiveEnergyAnalyticsDataSource: AnalyticsDataSource {
    
    private let networkController: NetworkController
    private let healthDetailService = HealthDetailService()
    
    var range: DateRange

    var title: String = "Active Calories"
    let chartViewModel: CurrentValueSubject<StackedBarChartViewModel, Never>
    var healthMetric: HealthMetric?
    private var samples: [HKSample] = []
    
    var dataExists: Bool?
    
    init(
        range: DateRange,
        networkController: NetworkController
    ) {
        self.networkController = networkController
        self.range = range
     
        chartViewModel = .init(StackedBarChartViewModel(chartType: .values,
                                                        rangeDescription: getTitle(range: range),
                                                        units: "calories",
                                                        formatType: range.timeSegment))
    }
    
    func loadData(completion: (() -> Void)?) {
        
        let format = DateFormatter()
        format.dateStyle = .full
        
        var newChartViewModel = chartViewModel.value
        newChartViewModel.rangeDescription = getTitle(range: range)
        newChartViewModel.formatType = range.timeSegment
        
        if let workoutMetrics = networkController.healthService.healthMetrics[.workouts], let healthMetric = workoutMetrics.first(where: {$0.type == .activeEnergy}) {
            dataExists = true
            newChartViewModel.healthMetric = healthMetric
            healthDetailService.getSamples(for: healthMetric, segmentType: range.timeSegment) { stats, samples, error in
                var data: BarChartData?
                if let stats = stats, stats.count > 0 {
                    var i = 0
                    var entries: [BarChartDataEntry] = []
                    for stat in stats {
                        let entry = BarChartDataEntry(x: Double(i) + 0.5, y: stat.value, data: stat.date)
                        entries.append(entry)
                        i += 1
                    }
                    
                    let dataSet = BarChartDataSet(entries: entries, label: "")
                    dataSet.drawValuesEnabled = false
                    dataSet.axisDependency = .right
                    dataSet.colors = [ChartColors.palette()[7]]
                    data = BarChartData(dataSets: [dataSet])
                    data?.barWidth = 0.5
                    data?.setDrawValues(false)
                }
                
                DispatchQueue.main.async {
                    newChartViewModel.chartData = data
                    if let averageValue = healthMetric.average {
                        newChartViewModel.rangeAverageValue = "\(Int(averageValue)) calories"
                    }
                    self.samples = samples?.sorted(by: { $0.startDate > $1.startDate }) ?? []
                    self.chartViewModel.send(newChartViewModel)
                    completion?()
                }
            }
        } else {
            newChartViewModel.chartData = nil
            newChartViewModel.categories = []
            newChartViewModel.rangeAverageValue = "-"
            self.chartViewModel.send(newChartViewModel)
            completion?()
            return
        }
    }
    
    func fetchEntries(range: DateRange, completion: ([AnalyticsBreakdownEntry]) -> Void) {
        completion(samples.map { .sample($0) })
    }
}
