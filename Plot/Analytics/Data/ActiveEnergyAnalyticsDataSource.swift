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
    DateRangeFormatter(currentWeek: "Daily average vs. prior week's", currentMonth: "Daily average vs. prior month's", currentYear: "Daily average vs. prior year's")
        .format(range: range)
    //    DateRangeFormatter(currentWeek: "Daily average", currentMonth: "Monthly average", currentYear: "Yearly average")
    //        .format(range: range)
}

// Active calories
class ActiveEnergyAnalyticsDataSource: AnalyticsDataSource {
    func updateRange(_ newRange: DateRange) {
        
    }
    
    private let networkController: NetworkController
    private let healthDetailService = HealthDetailService()
    
    var range: DateRange

    var title: String = "Active Calories"
    let chartViewModel: CurrentValueSubject<StackedBarChartViewModel, Never>
    var healthMetric: HealthMetric?
    private var samples: [HKSample] = []
    
    var dataExists: Bool?
    
    var numberFormatter: NumberFormatter = {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        numberFormatter.maximumFractionDigits = 0
        return numberFormatter
    }()
    
    init(
        range: DateRange,
        networkController: NetworkController
    ) {
        self.networkController = networkController
        self.range = range
     
        chartViewModel = .init(StackedBarChartViewModel(chartType: .line,
                                                        rangeDescription: getTitle(range: range),
                                                        verticalAxisType: .fixZeroToMaximumOnVertical,
                                                        units: "calories",
                                                        formatType: range.timeSegment))
    }
    
    func loadData(completion: (() -> Void)?) {
        
        let format = DateFormatter()
        format.dateStyle = .full
        
        var newChartViewModel = chartViewModel.value
        newChartViewModel.rangeDescription = getTitle(range: range)
        newChartViewModel.formatType = range.timeSegment
        
        switch chartViewModel.value.chartType {
        case .line:
            if let workoutMetrics = networkController.healthService.healthMetrics[.workouts], let healthMetric = workoutMetrics.first(where: {$0.type == .activeEnergy}) {
                dataExists = true
                
                let daysInRange = range.daysInRange + 1
                let startDateCurrent = range.startDate.dayBefore
                let startDatePast = range.pastStartDate?.dayBefore ?? startDateCurrent

                newChartViewModel.healthMetric = healthMetric
                
                healthDetailService.getSamples(for: healthMetric, segmentType: range.timeSegment, anchorDate: range.endDate.dayBefore.advanced(by: 1)) { statsCurrent, samplesCurrent, error in
                    var totalValue = 0.0
                    
                    self.healthDetailService.getSamples(for: healthMetric, segmentType: self.range.timeSegment, anchorDate: self.range.pastEndDate?.dayBefore.advanced(by: 1)) { statsPast, samplesPast, error in
                        self.samples = Array(Set((samplesCurrent ?? []) + (samplesPast ?? [])))

                        var chartDataSets = [LineChartDataSet]()
                        
                        var sum = 0.0
                        if let statsCurrent = statsCurrent, statsCurrent.count > 0 {
                            var dataEntriesCurrent: [ChartDataEntry] = []
                            for index in 0...daysInRange {
                                let date = startDateCurrent.addDays(index)
                                if let stat = statsCurrent.first(where: { $0.date == date }) {
                                    if !dataEntriesCurrent.contains(where: {$0.data as? Date == stat.date }) {
                                        sum += stat.value
                                        let entry = ChartDataEntry(x: Double(index) + 1, y: stat.value, data: date)
                                        dataEntriesCurrent.append(entry)
                                    }
                                } else {
                                    let entry = ChartDataEntry(x: Double(index) + 1, y: 0, data: date)
                                    dataEntriesCurrent.append(entry)
                                }
                            }
                            totalValue += sum / Double(statsCurrent.count)

                            let chartDataSetCurrent = LineChartDataSet(entries: dataEntriesCurrent)
                            chartDataSetCurrent.setDrawHighlightIndicators(false)
                            chartDataSetCurrent.axisDependency = .right
                            chartDataSetCurrent.colors = [NSUIColor.systemBlue]
                            chartDataSetCurrent.lineWidth = 5
                            chartDataSetCurrent.fillAlpha = 0
                            chartDataSetCurrent.drawFilledEnabled = true
                            chartDataSetCurrent.drawCirclesEnabled = false
                            chartDataSets.append(chartDataSetCurrent)

                            sum = 0
                            if let statsPast = statsPast, statsPast.count > 0 {
                                var dataEntriesPast: [ChartDataEntry] = []
                                for index in 0...daysInRange {
                                    let date = startDatePast.addDays(index)
                                    if let stat = statsPast.first(where: { $0.date == date }) {
                                        if !dataEntriesPast.contains(where: {$0.data as? Date == stat.date }) {
                                            sum += stat.value
                                            let entry = ChartDataEntry(x: Double(index) + 1, y: stat.value, data: date)
                                            dataEntriesPast.append(entry)
                                        }
                                    } else {
                                        let entry = ChartDataEntry(x: Double(index) + 1, y: 0, data: date)
                                        dataEntriesPast.append(entry)
                                    }
                                }
                                totalValue -= sum / Double(statsPast.count)
                                
                                let chartDataSetPast = LineChartDataSet(entries: dataEntriesPast)
                                chartDataSetPast.setDrawHighlightIndicators(false)
                                chartDataSetPast.axisDependency = .right
                                chartDataSetPast.colors = [NSUIColor.systemGray]
                                chartDataSetPast.lineWidth = 5
                                chartDataSetPast.fillAlpha = 0
                                chartDataSetPast.drawFilledEnabled = true
                                chartDataSetPast.drawCirclesEnabled = false
                                chartDataSets.append(chartDataSetPast)
                                                        
                            }
                            
                        }
                        
                        if totalValue > 0 {
                            newChartViewModel.rangeAverageValue = "+\(self.numberFormatter.string(from: NSNumber(value: totalValue))!) calories"
                        } else {
                            newChartViewModel.rangeAverageValue = "\(self.numberFormatter.string(from: NSNumber(value: totalValue))!) calories"
                        }
                        
                        DispatchQueue.main.async {
                            let chartData = LineChartData(dataSets: chartDataSets)
                            chartData.setDrawValues(false)
                            newChartViewModel.chartData = chartData
                            self.chartViewModel.send(newChartViewModel)
                            completion?()
                        }
                    }
                }
            } else {
                newChartViewModel.chartData = nil
                newChartViewModel.categories = []
                newChartViewModel.rangeAverageValue = "-"
                self.chartViewModel.send(newChartViewModel)
                self.samples = []
                completion?()
            }
        case .horizontalBar:
            break
        case .verticalBar:
            if let workoutMetrics = networkController.healthService.healthMetrics[.workouts], let healthMetric = workoutMetrics.first(where: {$0.type == .activeEnergy}) {
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
                        dataSet.colors = [ChartColors.palette()[7]]
                        data = BarChartData(dataSets: [dataSet])
                        data?.setDrawValues(false)
                    }
                    
                    DispatchQueue.main.async {
                        newChartViewModel.chartData = data
                        let averageValue = sum / Double(stats!.count)
                        let totalValue = self.numberFormatter.string(from: averageValue as NSNumber) ?? ""
                        newChartViewModel.rangeAverageValue = "\(totalValue) calories"
                        self.samples = samples ?? []
                        self.chartViewModel.send(newChartViewModel)
                        completion?()
                    }
                }
            } else {
                newChartViewModel.chartData = nil
                newChartViewModel.categories = []
                newChartViewModel.rangeAverageValue = "-"
                self.chartViewModel.send(newChartViewModel)
                self.samples = []
                completion?()
            }
        }
    }
    
    func fetchEntries(range: DateRange, completion: ([AnalyticsBreakdownEntry]) -> Void) {
        if range.filterOff {
            completion(samples.sorted(by: { $0.startDate > $1.startDate }).map { .sample($0) })
        } else {
            switch chartViewModel.value.chartType {
            case .line:
                let filteredSamples = samples
                    .filter { sample -> Bool in
                        return range.startDate <= sample.startDate && sample.startDate <= range.endDate
                    }
                completion(filteredSamples.map { .sample($0) })
            case .horizontalBar:
                let filteredSamples = samples
                    .filter { sample -> Bool in
                        return range.startDate <= sample.startDate && sample.startDate <= range.endDate
                    }
                completion(filteredSamples.map { .sample($0) })
            case .verticalBar:
                let filteredSamples = samples
                    .filter { sample -> Bool in
                        return range.startDate <= sample.startDate && sample.startDate <= range.endDate
                    }
                completion(filteredSamples.map { .sample($0) })
            }
        }
    }
}
