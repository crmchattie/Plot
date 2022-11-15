//
//  SleepAnalyticsDataSource.swift
//  Plot
//
//  Created by Cory McHattie on 11/9/22.
//  Copyright © 2022 Immature Creations. All rights reserved.
//

import Foundation
import Charts
import Combine
import HealthKit

private func getTitle(range: DateRange) -> String {
    DateRangeFormatter(currentWeek: "Daily average", currentMonth: "Monthly average", currentYear: "Yearly average")
        .format(range: range)
}

// Steps
class SleepAnalyticsDataSource: AnalyticsDataSource {
    func updateRange(_ newRange: DateRange) {
        
    }
    
    private let networkController: NetworkController
    private let healthDetailService = HealthDetailService()
    
    var range: DateRange

    var title: String = "Sleep"
    let chartViewModel: CurrentValueSubject<StackedBarChartViewModel, Never>
    var healthMetric: HealthMetric?
    private var samples: [HKSample] = []
    
    private lazy var dateFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .abbreviated
        formatter.allowedUnits = [.hour, .minute]
        return formatter
    }()
    
    var dataExists: Bool?
    
    init(
        range: DateRange,
        networkController: NetworkController
    ) {
        self.networkController = networkController
        self.range = range
     
        chartViewModel = .init(StackedBarChartViewModel(chartType: .verticalBar,
                                                        rangeDescription: getTitle(range: range),
                                                        units: "hrs",
                                                        formatType: range.timeSegment))
    }
    
    func loadData(completion: (() -> Void)?) {
        
        let format = DateFormatter()
        format.dateStyle = .full
        
        var newChartViewModel = chartViewModel.value
        newChartViewModel.rangeDescription = getTitle(range: range)
        newChartViewModel.formatType = range.timeSegment
        
        if let workoutMetrics = networkController.healthService.healthMetrics[.general], let healthMetric = workoutMetrics.first(where: {$0.type == .sleep}) {
            dataExists = true
            newChartViewModel.healthMetric = healthMetric
            healthDetailService.getSamples(for: healthMetric, segmentType: range.timeSegment, anchorDate: range.endDate.dayBefore.advanced(by: 1)) { stats, samples, error in
                var data: BarChartData?
                var sum = 0.0
                if let stats = stats, stats.count > 0 {
                    var i = 0
                    var entries: [BarChartDataEntry] = []
                    for stat in stats {
                        let entry = BarChartDataEntry(x: Double(i) + 0.5, y: stat.value, data: stat.date)
                        entries.append(entry)
                        sum += stat.value
                        i += 1
                    }
                    
                    let dataSet = BarChartDataSet(entries: entries, label: "")
                    dataSet.drawValuesEnabled = false
                    dataSet.axisDependency = .right
                    dataSet.colors = [ChartColors.palette()[6]]
                    data = BarChartData(dataSets: [dataSet])
                    data?.setDrawValues(false)
                }
                
                DispatchQueue.main.async {
                    newChartViewModel.chartData = data
                    let averageValue = sum / Double(stats!.count) * 3600
                    if let totalString = self.dateFormatter.string(from: averageValue) {
                        newChartViewModel.rangeAverageValue = totalString
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
        }
    }
    
    func fetchEntries(range: DateRange, completion: ([AnalyticsBreakdownEntry]) -> Void) {
        if range.filterOff {
            completion(samples.map { .sample($0) })
        } else {
            let filteredSamples = samples
                .filter { sample -> Bool in
                    return range.startDate <= sample.startDate && sample.startDate <= range.endDate
                }
            completion(filteredSamples.map { .sample($0) })
        }
    }
}
