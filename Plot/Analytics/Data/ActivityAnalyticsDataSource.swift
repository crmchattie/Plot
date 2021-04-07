//
//  ActivityAnalyticsDataSource.swift
//  Plot
//
//  Created by Botond Magyarosi on 16.03.2021.
//  Copyright © 2021 Immature Creations. All rights reserved.
//

import Foundation
import Charts
import Combine

private func getTitle(range: DateRange) -> String {
    DateRangeFormatter(currentWeek: "This week", currentMonth: "This month", currentYear: "This year")
        .format(range: range)
}

class ActivityAnalyticsDataSource: AnalyticsDataSource {
    
    private let networkController: NetworkController
    private let summaryService = SummaryService()
    
    var range: DateRange
    
    let chartViewModel: CurrentValueSubject<StackedBarChartViewModel, Never>
    
    let title: String = "Activities"
    
    private lazy var dateFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .abbreviated
        formatter.allowedUnits = [.hour, .minute]
        return formatter
    }()
    
    init(
        range: DateRange,
        networkController: NetworkController
    ) {
        self.networkController = networkController
        self.range = range
        
        chartViewModel = .init(StackedBarChartViewModel(chartType: .values,
                                                        rangeDescription: getTitle(range: range),
                                                        horizontalAxisValueFormatter: range.axisValueFormatter,
                                                        verticalAxisValueFormatter: HourAxisValueFormatter()))
    }
    
    func loadData(completion: (() -> Void)?) {
        var newChartViewModel = chartViewModel.value
        newChartViewModel.rangeDescription = getTitle(range: range)
        newChartViewModel.horizontalAxisValueFormatter = range.axisValueFormatter
        
        summaryService.getSamples(for: range, segment: range.timeSegment, activities: networkController.activityService.activities) { stats in
            let activities = stats[.calendarSummary] ?? [:]
            
            print(activities)
            
            guard !activities.isEmpty else {
                newChartViewModel.chartData = nil
                newChartViewModel.categories = []
                newChartViewModel.rangeAverageValue = "0 activities"
                self.chartViewModel.send(newChartViewModel)
                completion?()
                return
            }
            
            DispatchQueue.global(qos: .background).async {
                var categories: [CategorySummaryViewModel] = []
                var activityCount = 0
                
                let activityKeys = activities.keys.sorted(by: <)
                for category in activityKeys {
                    guard let stats = activities[category] else { continue }
                    let total = stats.reduce(0, { $0 + $1.value * 60 })
                    let totalString = self.dateFormatter.string(from: total) ?? "NaN"
                    categories.append(CategorySummaryViewModel(title: category,
                                                               color: (ActivityCategory(rawValue: category) ?? .uncategorized).color,
                                                               value: total,
                                                               formattedValue: totalString))
                    activityCount += stats.count
                }
                categories.sort(by: { $0.value > $1.value })
                newChartViewModel.categories = Array(categories.prefix(3))
                newChartViewModel.rangeAverageValue = "\(activityCount) activities"
                
                let daysInRange = self.range.daysInRange
                let dataEntries = (0...daysInRange).map { index -> BarChartDataEntry in
                    let current = self.range.startDate.addDays(index)
                    let yValues = categories.map {
                        (activities[$0.title] ?? []).filter({ $0.date.isSameDay(as: current) }).reduce(0, { $0 + $1.value * 60 })
                    }
                    return BarChartDataEntry(x: Double(index) + 0.5, yValues: yValues)
                }
                
                DispatchQueue.main.async {
                    let chartDataSet = BarChartDataSet(entries: dataEntries)
                    let chartData = BarChartData(dataSets: [chartDataSet])
                    chartDataSet.colors = categories.map { $0.color }
                    chartData.barWidth = 0.5
                    chartData.setDrawValues(false)
                    newChartViewModel.chartData = chartData
                    self.chartViewModel.send(newChartViewModel)
                    completion?()
                }
            }
        }
    }
    
    func fetchEntries(range: DateRange, completion: ([AnalyticsBreakdownEntry]) -> Void) {
        let entries = networkController.activityService.activities
            .filter {
                if let startDate = $0.startDate, let category = $0.category {
                    return startDate >= range.startDate && startDate <= range.endDate && ActivityCategory(rawValue: category) != .notApplicable
                }
                return false
            }
            // at this point all activities should have a startDate (see above)
            .sorted(by: { $0.startDate! > $1.startDate! })
            .map { AnalyticsBreakdownEntry.activity($0) }
        completion(entries)
    }
}
