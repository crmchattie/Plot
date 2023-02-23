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
    DateRangeFormatter(currentWeek: "Over the last week", currentMonth: "Over the last month", currentYear: "Over the last year")
        .format(range: range)
}

class TaskAnalyticsDataSource: AnalyticsDataSource {
    func updateRange(_ newRange: DateRange) {
        
    }
    
    private let networkController: NetworkController
    private let activityDetailService = ActivityDetailService()
    
    var range: DateRange
    
    let chartViewModel: CurrentValueSubject<StackedBarChartViewModel, Never>
    
    let title: String = "Tasks"
    
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
        activityDetailService.getActivityCategoriesSamples(for: range, segment: range.timeSegment, activities: networkController.activityService.tasks, isEvent: false) { categoryStats, taskList in
                        
            guard !categoryStats.isEmpty else {
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
    
    func fetchEntries(range: DateRange, completion: ([AnalyticsBreakdownEntry]) -> Void) {
        if range.filterOff {
            completion(tasks.sorted(by: { $0.completedDateDate ?? Date() > $1.completedDateDate ?? Date() }).map { .activity($0) })
        } else {
            let filteredTasks = tasks
                .filter { task -> Bool in
                    guard let date = task.completedDateDate?.localTime else { return false }
                    return range.startDate <= date && date <= range.endDate
                }
            completion(filteredTasks.map { .activity($0) })
        }
    }
}

