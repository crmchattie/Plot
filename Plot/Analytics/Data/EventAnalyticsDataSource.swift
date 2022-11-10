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
    DateRangeFormatter(currentWeek: "The last week", currentMonth: "The last month", currentYear: "The last year")
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
        activityDetailService.getEventCategoriesSamples(for: range, segment: range.timeSegment, activities: networkController.activityService.events) { stats, activityList in
            let categoryStats = stats[.calendarSummary] ?? [:]
            
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
            
            DispatchQueue.global(qos: .background).async {
                var categories: [CategorySummaryViewModel] = []
                var activityCount = 0
                
                let activityKeys = categoryStats.keys.sorted(by: <)
                for index in 0...activityKeys.count - 1 {
                    guard let stats = categoryStats[activityKeys[index]] else { continue }
                    let total = stats.reduce(0, { $0 + $1.value * 60 })
                    let totalString = self.dateFormatter.string(from: total) ?? "NaN"
                    
                    var categoryColor = UIColor()
                    if let activityCategory = ActivityCategory(rawValue: activityKeys[index]) {
                        categoryColor = activityCategory.color
                    } else {
                        categoryColor = ActivityCategory.uncategorized.color
                    }
                    categories.append(CategorySummaryViewModel(title: activityKeys[index],
                                                               color: categoryColor,
                                                               value: total,
                                                               formattedValue: totalString))
                    activityCount += stats.count
                }
                categories.sort(by: { $0.value > $1.value })
                newChartViewModel.categories = Array(categories.prefix(3))
                newChartViewModel.rangeAverageValue = "\(activityList.count) events"
                
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
        completion(activities.map { .activity($0) })
    }
}
