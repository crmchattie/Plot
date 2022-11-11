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
    DateRangeFormatter(currentWeek: "The last week", currentMonth: "The last month", currentYear: "The last year")
        .format(range: range)
}

class TaskAnalyticsDataSource: AnalyticsDataSource {
    func updateRange(_ newRange: DateRange) {
        
    }
    
    private let networkController: NetworkController
    private let activityDetailService = ActivityDetailService()
    
    var range: DateRange
    
    let chartViewModel: CurrentValueSubject<StackedBarChartViewModel, Never>
    
    let title: String = "Completed Tasks"
    
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
        
        let daysInRange = range.daysInRange
        
        tasks = networkController.activityService.tasks
            .filter { $0.isTask ?? false }
            .filter { $0.isCompleted ?? false }
            .filter { task -> Bool in
                guard let date = task.completedDateDate else { return false }
                return range.startDate <= date && date <= range.endDate
            }
        
        var totalValue: Double = 0
        var categoryValues: [[Double]] = []
        var categoryColors: [UIColor] = []
        var categories: [CategorySummaryViewModel] = []
        
        tasks.grouped(by: \.category).forEach { (uncertainCategory, tasks) in
            let category = uncertainCategory ?? "Uncategorized"
            var values: [Double] = Array(repeating: 0, count: daysInRange + 1)
            var sum: Double = 0
            tasks.forEach { task in
                guard let day = task.completedDateDate else { return }
                let daysInBetween = day.daysSince(range.startDate)
                totalValue += 1
                values[daysInBetween] += 1
                sum += 1
            }
            
            var categoryColor = UIColor()
            if let activityCategory = ActivityCategory(rawValue: category) {
                categoryColor = activityCategory.color
            } else {
                categoryColor = ActivityCategory.uncategorized.color
            }
            
            var totalString = String()
            if sum == 1 {
                totalString = "1 tasks"
            } else {
                totalString = "\(Int(sum)) tasks"
            }
            
            categories.append(CategorySummaryViewModel(title: category,
                                                       color: categoryColor,
                                                       value: sum,
                                                       formattedValue: totalString))
            categoryColors.append(categoryColor)
            categoryValues.append(values)
        }
                
        var maxValue = Double()
        let dataEntries = (0...daysInRange).map { index -> BarChartDataEntry in
            let current = self.range.startDate.addDays(index)
            let yValues = categoryValues.map { $0[index] }
            maxValue = max(maxValue, yValues.reduce(0, +))
            return BarChartDataEntry(x: Double(index) + 0.5, yValues: yValues, data: current)
        }
        
        newChartViewModel.categories = Array(categories.sorted(by: { $0.value > $1.value }).prefix(3))
        if totalValue == 0 {
            newChartViewModel.rangeAverageValue = "No tasks"
        } else {
            newChartViewModel.rangeAverageValue = "\(Int(totalValue)) tasks"
            newChartViewModel.maxValue = maxValue + 1
        }
                
        if !tasks.isEmpty {
            dataExists = true
            let chartDataSet = BarChartDataSet(entries: dataEntries)
            chartDataSet.axisDependency = .right
            if !categoryColors.isEmpty {
                chartDataSet.colors = categoryColors
            }
            let chartData = BarChartData(dataSets: [chartDataSet])
            chartData.setDrawValues(false)
            newChartViewModel.chartData = chartData
        } else {
            newChartViewModel.chartData = nil
            newChartViewModel.categories = []
            newChartViewModel.rangeAverageValue = "-"
        }
        
        chartViewModel.send(newChartViewModel)
        completion?()
        
    }
    
    func fetchEntries(range: DateRange, completion: ([AnalyticsBreakdownEntry]) -> Void) {
        completion(tasks.sorted(by: { $0.completedDateDate! > $1.completedDateDate! }).map { .activity($0) })
    }
}

