//
//  TaskAnalyticsDataSource.swift
//  Plot
//
//  Created by Cory McHattie on 11/10/22.
//  Copyright © 2022 Immature Creations. All rights reserved.
//

import Foundation
import Charts
import Combine

private func getTitle(range: DateRange) -> String {
//    DateRangeFormatter(currentWeek: "Vs. prior week", currentMonth: "Vs. prior month", currentYear: "Vs. prior year").format(range: range)
    DateRangeFormatter(currentWeek: "Over the last week", currentMonth: "Over the last month", currentYear: "Over the last year").format(range: range)
}

class TaskAnalyticsDataSource: AnalyticsDataSource {
    func updateRange(_ newRange: DateRange) {
        
    }
    
    private let networkController: NetworkController
    private let activityDetailService = ActivityDetailService()
    
    var range: DateRange
    
    let chartViewModel: CurrentValueSubject<StackedBarChartViewModel, Never>
    
    let title: String = "Tasks"
    let titleStringSingular = "task"
    let titleStringPlural = "tasks"
    
    private var tasks: [Activity] = []
    
    var dataExists: Bool?
    
    private var numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 0
        formatter.minimumFractionDigits = 0
        return formatter
    }()
    
    init(
        range: DateRange,
        networkController: NetworkController
    ) {
        self.networkController = networkController
        self.range = range
        
        chartViewModel = .init(StackedBarChartViewModel(chartType: .verticalBar,
                                                        rangeDescription: getTitle(range: range),
                                                        verticalAxisValueFormatter: DefaultAxisValueFormatter(formatter: numberFormatter),
                                                        units: "completed",
                                                        formatType: range.timeSegment))
    }
    
    func loadData(completion: (() -> Void)?) {
        var newChartViewModel = chartViewModel.value
        newChartViewModel.rangeDescription = getTitle(range: range)
        newChartViewModel.formatType = range.timeSegment
        
        switch chartViewModel.value.chartType {
        case .line:
            
            activityDetailService.getActivityCategoriesSamples(for: range, segment: range.timeSegment, activities: networkController.activityService.tasks, isEvent: false) { categoryStatsCurrent, taskListCurrent in
                guard !categoryStatsCurrent.isEmpty, let previousRange = self.range.previousDatesForComparison() else {
                    newChartViewModel.chartData = nil
                    newChartViewModel.categories = []
                    newChartViewModel.rangeAverageValue = "-"
                    self.chartViewModel.send(newChartViewModel)
                    self.tasks = []
                    completion?()
                    return
                }
                
                self.activityDetailService.getActivityCategoriesSamples(for: previousRange, segment: self.range.timeSegment, activities: self.networkController.activityService.tasks, isEvent: false) { categoryStatsPast, taskListPast in
                    
                    self.dataExists = true

                    let daysInRange = self.range.daysInRange + 1
                    let startDateCurrent = self.range.startDate.startOfDay
                    let startDatePast = self.range.pastStartDate?.startOfDay ?? startDateCurrent
                
                    
                    self.tasks = Array(Set(taskListCurrent + taskListPast))
                    
                    DispatchQueue.global(qos: .userInteractive).async {
                        var chartDataSets = [LineChartDataSet]()
                        var categories: [CategorySummaryViewModel] = []
                        let keysCurrent = categoryStatsCurrent.keys.sorted(by: <)
                        
                        var cumulative: Double = 0
                        var dataEntries = (0...daysInRange).map { index -> ChartDataEntry in
                            let date = startDateCurrent.addDays(index)
                            let yValues = keysCurrent.map {
                                (categoryStatsCurrent[$0] ?? []).filter({ $0.date.dayAfter.isSameDay(as: date) }).reduce(0, { $0 + $1.value })
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
                                                                       value: Double(taskListCurrent.count),
                                                                       formattedValue: "\(Int(taskListCurrent.count)) " + (taskListCurrent.count == 1 ? self.titleStringSingular : self.titleStringPlural))
                        categories.append(categoryCurrent)
                        
                        if !categoryStatsPast.isEmpty {
                            let keysPast = categoryStatsPast.keys.sorted(by: <)
                            
                            cumulative = 0
                            dataEntries = (0...daysInRange).map { index -> ChartDataEntry in
                                let date = startDatePast.addDays(index)
                                let yValues = keysPast.map {
                                    (categoryStatsPast[$0] ?? []).filter({ $0.date.dayAfter.isSameDay(as: date) }).reduce(0, { $0 + $1.value })
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
                            
                            let categoryPast = CategorySummaryViewModel(title: "Last " + (self.range.type?.title ?? ""),
                                                                        color: .secondaryLabel,
                                                                        value: Double(taskListPast.count),
                                                                        formattedValue: "\(Int(taskListPast.count)) " + (taskListPast.count == 1 ? self.titleStringSingular : self.titleStringPlural))
                            categories.append(categoryPast)
                        }
                                    
                        chartDataSets.append(chartDataSetCurrent)
                        
                        newChartViewModel.categories = categories
                        
                        let change = taskListCurrent.count - taskListPast.count
                        
                        if change == 0 {
                            newChartViewModel.rangeAverageValue = "On Track"
                        } else if change == 1 {
                            newChartViewModel.rangeAverageValue = "+1 completed " + self.titleStringSingular
                        } else if change == -1 {
                            newChartViewModel.rangeAverageValue = "-1 completed " + self.titleStringSingular
                        } else if change < -1 {
                            newChartViewModel.rangeAverageValue = "\(Int(change)) completed " + self.titleStringPlural
                        } else if change > 1 {
                            newChartViewModel.rangeAverageValue = "+\(Int(change)) completed " + self.titleStringPlural
                        }
            
                        
                        DispatchQueue.main.async {
                            if !self.tasks.isEmpty {
                                self.dataExists = true
                                let chartData = LineChartData(dataSets: chartDataSets)
                                chartData.setDrawValues(false)
                                newChartViewModel.chartData = chartData
                                self.chartViewModel.send(newChartViewModel)
                                completion?()
                            } else {
                                self.dataExists = false
                                newChartViewModel.chartData = nil
                                newChartViewModel.categories = []
                                newChartViewModel.rangeAverageValue = "-"
                                self.chartViewModel.send(newChartViewModel)
                                completion?()
                            }
                        }
                    }
                }
            }
        case .horizontalBar:
            break
        case .verticalBar:
            
//            print("load data tasks")
//            print(range.startDate)
//            print(range.endDate)
//            print(range.startDate.localTime)
//            print(range.endDate.localTime)
            
            activityDetailService.getActivityCategoriesSamples(for: range, segment: range.timeSegment, activities: networkController.activityService.tasks, isEvent: false) { categoryStats, taskList in
                            
                guard !taskList.isEmpty else {
                    newChartViewModel.chartData = nil
                    newChartViewModel.categories = []
                    newChartViewModel.rangeAverageValue = "-"
                    self.chartViewModel.send(newChartViewModel)
                    self.tasks = []
                    completion?()
                    return
                }
                
                self.tasks = taskList
                            
                self.dataExists = true
                
                DispatchQueue.global(qos: .userInteractive).async {
                    var categories: [CategorySummaryViewModel] = []
                    var activityCount = 0
                    
                    let keys = categoryStats.keys.sorted(by: <)
                    for index in 0...keys.count - 1 {
                        guard let stats = categoryStats[keys[index]] else { continue }
                        let total = stats.reduce(0, { $0 + $1.value })
                        var totalString = String()
                        if total == 1 {
                            totalString = "1 task"
                        } else {
                            totalString = "\(Int(total)) tasks"
                        }
                        
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
                        activityCount += stats.count
                    }
                    categories.sort(by: { $0.value > $1.value })
                    
                    newChartViewModel.categories = Array(categories.prefix(3))
                    if taskList.count == 0 {
                        newChartViewModel.rangeAverageValue = "No completed tasks"
                    } else if taskList.count == 1 {
                        newChartViewModel.rangeAverageValue = "1 completed task"
                    } else {
                        newChartViewModel.rangeAverageValue = "\(Int(taskList.count)) completed tasks"
                    }
                    
                    let daysInRange = self.range.daysInRange
                    let dataEntries = (0...daysInRange).map { index -> BarChartDataEntry in
                        let current = self.range.startDate.addDays(index)
                        let yValues = categories.map {
                            (categoryStats[$0.title] ?? []).filter({ $0.date.isSameDay(as: current) }).reduce(0, { $0 + $1.value })
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
            completion(tasks.sorted(by: { $0.completedDateDate ?? Date() > $1.completedDateDate ?? Date() }).map { .activity($0) })
        } else {
            switch chartViewModel.value.chartType {
            case .line:
                let startDate = range.startDate.dayBefore
                let endDate = range.endDate.dayBefore
                let filteredTasks = tasks
                    .filter { task -> Bool in
                        guard let date = task.completedDateDate?.localTime else { return false }
                        return startDate <= date && date <= endDate
                    }
                completion(filteredTasks.map { .activity($0) })
            case .horizontalBar:
                let filteredTasks = tasks
                    .filter { task -> Bool in
                        guard let date = task.completedDateDate?.localTime else { return false }
                        return range.startDate <= date && date <= range.endDate
                    }
                completion(filteredTasks.map { .activity($0) })
            case .verticalBar:
                let filteredTasks = tasks
                    .filter { task -> Bool in
                        guard let date = task.completedDateDate?.localTime else { return false }
                        return range.startDate <= date && date <= range.endDate
                    }
                completion(filteredTasks.map { .activity($0) })
            }
        }
    }
}

