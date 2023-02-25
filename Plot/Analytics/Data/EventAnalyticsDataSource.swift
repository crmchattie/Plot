//
//  EventAnalyticsDataSource.swift
//  Plot
//
//  Created by Botond Magyarosi on 16.03.2021.
//  Copyright © 2021 Immature Creations. All rights reserved.
//

import Foundation
import Charts
import Combine

private func getTitle(range: DateRange) -> String {
//    DateRangeFormatter(currentWeek: "Vs. the prior week", currentMonth: "Vs. the prior month", currentYear: "Vs. the prior year").format(range: range)
    DateRangeFormatter(currentWeek: "Over the last week", currentMonth: "Over the last month", currentYear: "Over the last year").format(range: range)
}

class EventAnalyticsDataSource: AnalyticsDataSource {
    func updateRange(_ newRange: DateRange) {
        
    }
    
    private let networkController: NetworkController
    private let activityDetailService = ActivityDetailService()
    
    var range: DateRange
    
    let chartViewModel: CurrentValueSubject<StackedBarChartViewModel, Never>
    
    let title: String = "Events"
    let titleStringSingular = "event"
    let titleStringPlural = "events"
    
    private var activities: [Activity] = []
        
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
                                                        verticalAxisValueFormatter: HourAxisValueFormatter(),
                                                        verticalAxisType: .fixZeroToMinimumOnVertical,
                                                        units: "time",
                                                        formatType: range.timeSegment))
    }
    
    func loadData(completion: (() -> Void)?) {
        var newChartViewModel = chartViewModel.value
        newChartViewModel.rangeDescription = getTitle(range: range)
        newChartViewModel.formatType = range.timeSegment
        
        switch chartViewModel.value.chartType {
        case .line:
            
            activityDetailService.getActivityCategoriesSamples(for: range, segment: range.timeSegment, activities: networkController.activityService.events, isEvent: true) { categoryStatsCurrent, activityListCurrent in
                guard !categoryStatsCurrent.isEmpty, let previousRange = self.range.previousDatesForComparison() else {
                    newChartViewModel.chartData = nil
                    newChartViewModel.categories = []
                    newChartViewModel.rangeAverageValue = "-"
                    self.chartViewModel.send(newChartViewModel)
                    self.activities = []
                    completion?()
                    return
                }
                
                self.activityDetailService.getActivityCategoriesSamples(for: previousRange, segment: self.range.timeSegment, activities: self.networkController.activityService.events, isEvent: true) { categoryStatsPast, activityListPast in
                    
                    self.dataExists = true
                    
                    let daysInRange = self.range.daysInRange + 1
                    let startDateCurrent = self.range.startDate.startOfDay
                    let startDatePast = self.range.pastStartDate?.startOfDay ?? startDateCurrent        
                    
                    self.activities = Array(Set(activityListCurrent + activityListPast))
                    
                    DispatchQueue.global(qos: .userInteractive).async {
                        var chartDataSets = [LineChartDataSet]()
                        var categories: [CategorySummaryViewModel] = []
                        let keysCurrent = categoryStatsCurrent.keys.sorted(by: <)
                        
                        var cumulative: Double = 0
                        var dataEntries = (0...daysInRange).map { index -> ChartDataEntry in
                            let date = startDateCurrent.addDays(index)
                            let yValues = keysCurrent.map {
                                (categoryStatsCurrent[$0] ?? []).filter({ $0.date.isSameDay(as: date) }).reduce(0, { $0 + $1.value * 60 })
                            }.reduce(0, +)
                            cumulative += yValues
                            return ChartDataEntry(x: Double(index) + 1, y: cumulative, data: date)
                        }
                        
                        let chartDataSetCurrent = LineChartDataSet(entries: dataEntries)
                        chartDataSetCurrent.setDrawHighlightIndicators(false)
                        chartDataSetCurrent.axisDependency = .right
                        chartDataSetCurrent.colors = [NSUIColor.systemBlue]
                        chartDataSetCurrent.lineWidth = 5
                        chartDataSetCurrent.fillAlpha = 0
                        chartDataSetCurrent.drawFilledEnabled = true
                        chartDataSetCurrent.drawCirclesEnabled = false
                                                
                        let categoryCurrent = CategorySummaryViewModel(title: "This " + (self.range.type?.title ?? ""),
                                                                       color: .systemBlue,
                                                                       value: Double(activityListCurrent.count),
                                                                       formattedValue: "\(Int(activityListCurrent.count)) " + (activityListCurrent.count == 1 ? self.titleStringSingular : self.titleStringPlural))
                        categories.append(categoryCurrent)
                        
                        if !categoryStatsPast.isEmpty {
                            let keysPast = categoryStatsPast.keys.sorted(by: <)
                            
                            cumulative = 0
                            dataEntries = (0...daysInRange).map { index -> ChartDataEntry in
                                let date = startDatePast.addDays(index)
                                let yValues = keysPast.map {
                                    (categoryStatsPast[$0] ?? []).filter({ $0.date.isSameDay(as: date) }).reduce(0, { $0 + $1.value * 60 })
                                }.reduce(0, +)
                                cumulative += yValues
                                return ChartDataEntry(x: Double(index) + 1, y: cumulative, data: date)
                            }
                            
                            let chartDataSetPast = LineChartDataSet(entries: dataEntries)
                            chartDataSetPast.setDrawHighlightIndicators(false)
                            chartDataSetPast.axisDependency = .right
                            chartDataSetPast.colors = [NSUIColor.systemGray4]
                            chartDataSetPast.lineWidth = 5
                            chartDataSetPast.fillAlpha = 0
                            chartDataSetPast.drawFilledEnabled = true
                            chartDataSetPast.drawCirclesEnabled = false
                            chartDataSets.append(chartDataSetPast)
                            
                            let categoryPast = CategorySummaryViewModel(title: "This " + (self.range.type?.title ?? ""),
                                                                           color: .systemBlue,
                                                                           value: Double(activityListPast.count),
                                                                           formattedValue: "\(Int(activityListPast.count)) " + (activityListPast.count == 1 ? self.titleStringSingular : self.titleStringPlural))
                            categories.append(categoryPast)
                        }
                        
                        chartDataSets.append(chartDataSetCurrent)
                                                
                        newChartViewModel.categories = categories
                        
                        let change = activityListCurrent.count - activityListPast.count
                        
                        if change == 0 {
                            newChartViewModel.rangeAverageValue = "On Track"
                        } else if change == 1 {
                            newChartViewModel.rangeAverageValue = "+1 " + self.titleStringSingular
                        } else if change == -1 {
                            newChartViewModel.rangeAverageValue = "-1 " + self.titleStringSingular
                        } else if change < -1 {
                            newChartViewModel.rangeAverageValue = "\(Int(change)) " + self.titleStringPlural
                        } else if change > 1 {
                            newChartViewModel.rangeAverageValue = "+\(Int(change)) " + self.titleStringPlural
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
            }
        case .horizontalBar:
            break
        case .verticalBar:
            activityDetailService.getActivityCategoriesSamples(for: range, segment: range.timeSegment, activities: networkController.activityService.events, isEvent: true) { categoryStats, activityList in
                guard !categoryStats.isEmpty else {
                    newChartViewModel.chartData = nil
                    newChartViewModel.categories = []
                    newChartViewModel.rangeAverageValue = "-"
                    self.chartViewModel.send(newChartViewModel)
                    self.activities = []
                    completion?()
                    return
                }
                
                self.activities = activityList
                            
                self.dataExists = true
                
                DispatchQueue.global(qos: .userInteractive).async {
                    var categories: [CategorySummaryViewModel] = []
                    var count = 0
                    
                    let keys = categoryStats.keys.sorted(by: <)
                    for index in 0...keys.count - 1 {
                        guard let stats = categoryStats[keys[index]] else { continue }
                        let total = stats.reduce(0, { $0 + $1.value * 60 })
                        let totalString = self.dateFormatter.string(from: total) ?? "NaN"
                        
                        var categoryColor = UIColor()
                        if let activityCategory = ActivityCategory(rawValue: keys[index]) {
                            categoryColor = activityCategory.color
                        } else {
                            categoryColor = ActivityCategory.uncategorized.color
                        }
                        categories.append(CategorySummaryViewModel(title: keys[index],
                                                                   color: categoryColor,
                                                                   value: total,
                                                                   formattedValue: totalString))
                        count += stats.count
                    }
                    categories.sort(by: { $0.value > $1.value })
                    
                    newChartViewModel.categories = Array(categories.prefix(3))
                    if activityList.count == 0 {
                        newChartViewModel.rangeAverageValue = "No " + self.titleStringPlural
                    } else if activityList.count == 1 {
                        newChartViewModel.rangeAverageValue = "1 " + self.titleStringSingular
                    } else {
                        newChartViewModel.rangeAverageValue = "\(Int(activityList.count)) " + self.titleStringPlural
                    }
                    
                    let daysInRange = self.range.daysInRange
                    let dataEntries = (0...daysInRange).map { index -> BarChartDataEntry in
                        let current = self.range.startDate.addDays(index)
                        let yValues = categories.map {
                            (categoryStats[$0.title] ?? []).filter({ $0.date.isSameDay(as: current) }).reduce(0, { $0 + $1.value * 60 })
                        }
                        return BarChartDataEntry(x: Double(index) + 0.5, yValues: yValues, data: current)
                    }
                    
                    DispatchQueue.main.async {
                        let chartDataSet = BarChartDataSet(entries: dataEntries)
                        chartDataSet.axisDependency = .right
                        chartDataSet.colors = categories.map { $0.color }
                        let chartData = BarChartData(dataSets: [chartDataSet])
                        chartData.setDrawValues(false)
                        newChartViewModel.chartData = chartData
                        self.chartViewModel.send(newChartViewModel)
                        completion?()
                    }
                }
            }
        }
    }
    
    func fetchEntries(range: DateRange, completion: ([AnalyticsBreakdownEntry]) -> Void) {
        if range.filterOff {
            completion(activities.sorted(by: { $0.startDate ?? Date() > $1.startDate ?? Date() }).map { .activity($0) })
        } else {
            switch chartViewModel.value.chartType {
            case .line:
                let startDate = range.startDate.dayBefore
                let endDate = range.endDate.dayBefore
                let filteredActivities = activities
                    .filter { activity -> Bool in
                        guard let date = activity.startDate?.localTime else { return false }
                        return startDate <= date && date <= endDate
                    }
                completion(filteredActivities.map { .activity($0) })
            case .horizontalBar:
                let filteredActivities = activities
                    .filter { activity -> Bool in
                        guard let date = activity.startDate?.localTime else { return false }
                        return range.startDate <= date && date <= range.endDate
                    }
                completion(filteredActivities.map { .activity($0) })
            case .verticalBar:
                let filteredActivities = activities
                    .filter { activity -> Bool in
                        guard let date = activity.startDate?.localTime else { return false }
                        return range.startDate <= date && date <= range.endDate
                    }
                completion(filteredActivities.map { .activity($0) })
            }
        }
    }
}
