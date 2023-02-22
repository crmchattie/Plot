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
    DateRangeFormatter(currentWeek: "Over the last week", currentMonth: "Over the last month", currentYear: "Over the last year")
        .format(range: range)
}

class EventAnalyticsDataSource: AnalyticsDataSource {
    func updateRange(_ newRange: DateRange) {
        
    }
    
    private let networkController: NetworkController
    private let activityDetailService = ActivityDetailService()
    
    var range: DateRange
    
    let chartViewModel: CurrentValueSubject<StackedBarChartViewModel, Never>
    
    let title: String = "Events"
    
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
                                                        units: "time",
                                                        formatType: range.timeSegment))
    }
    
    func loadData(completion: (() -> Void)?) {
        var newChartViewModel = chartViewModel.value
        newChartViewModel.rangeDescription = getTitle(range: range)
        newChartViewModel.formatType = range.timeSegment
        activityDetailService.getActivityCategoriesSamples(for: range, segment: range.timeSegment, activities: networkController.activityService.events, isEvent: true) { categoryStats, activityList in
                        
            guard !categoryStats.isEmpty else {
                newChartViewModel.chartData = nil
                newChartViewModel.categories = []
                newChartViewModel.rangeAverageValue = "-"
                self.chartViewModel.send(newChartViewModel)
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
                    newChartViewModel.rangeAverageValue = "No events"
                } else if activityList.count == 1 {
                    newChartViewModel.rangeAverageValue = "1 event"
                } else {
                    newChartViewModel.rangeAverageValue = "\(Int(activityList.count)) events"
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
    
    func fetchEntries(range: DateRange, completion: ([AnalyticsBreakdownEntry]) -> Void) {
        if range.filterOff {
            completion(activities.sorted(by: { $0.startDate ?? Date() > $1.startDate ?? Date() }).map { .activity($0) })
        } else {
            let filteredActivities = activities
                .filter { activity -> Bool in
                    guard let date = activity.startDate?.localTime else { return false }
                    return range.startDate <= date && date <= range.endDate
                }
            completion(filteredActivities.map { .activity($0) })
        }
    }
}
