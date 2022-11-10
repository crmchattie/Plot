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
    DateRangeFormatter(currentWeek: "The last week", currentMonth: "The last month", currentYear: "The last year")
        .format(range: range)
}

class ActivityAnalyticsDataSource: AnalyticsDataSource {
    
    private let networkController: NetworkController
    private let activityDetailService = ActivityDetailService()
    
    var range: DateRange
    
    let chartViewModel: CurrentValueSubject<StackedBarChartViewModel, Never>
    
    let title: String = "Events"
    
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
        
        chartViewModel = .init(StackedBarChartViewModel(chartType: .values,
                                                        rangeDescription: getTitle(range: range),
                                                        verticalAxisValueFormatter: HourAxisValueFormatter(),
                                                        units: "time",
                                                        formatType: range.timeSegment))
    }
    
    func loadData(completion: (() -> Void)?) {
        var newChartViewModel = chartViewModel.value
        newChartViewModel.rangeDescription = getTitle(range: range)
        newChartViewModel.formatType = range.timeSegment
        
        activityDetailService.getSamples(for: range, segment: range.timeSegment, activities: networkController.activityService.events) { stats in
            let activities = stats[.calendarSummary] ?? [:]
            
            guard !activities.isEmpty else {
                newChartViewModel.chartData = nil
                newChartViewModel.categories = []
                newChartViewModel.rangeAverageValue = "-"
                self.chartViewModel.send(newChartViewModel)
                completion?()
                return
            }
            
            self.dataExists = true
            
            DispatchQueue.global(qos: .background).async {
                var categories: [CategorySummaryViewModel] = []
                var activityCount = 0
                
                let activityKeys = activities.keys.sorted(by: <)
                for index in 0...activityKeys.count - 1 {
                    guard let stats = activities[activityKeys[index]] else { continue }
                    let total = stats.reduce(0, { $0 + $1.value * 60 })
                    let totalString = self.dateFormatter.string(from: total) ?? "NaN"
                    let categoryColor = ChartColors.palette()[index % 9]
                    categories.append(CategorySummaryViewModel(title: activityKeys[index],
                                                               color: categoryColor,
                                                               value: total,
                                                               formattedValue: totalString))
                    activityCount += stats.count
                }
                categories.sort(by: { $0.value > $1.value })
                newChartViewModel.categories = Array(categories.prefix(3))
                newChartViewModel.rangeAverageValue = "\(activityCount) events"
                
                let daysInRange = self.range.daysInRange
                let dataEntries = (0...daysInRange).map { index -> BarChartDataEntry in
                    let current = self.range.startDate.addDays(index)
                    let yValues = categories.map {
                        (activities[$0.title] ?? []).filter({ $0.date.isSameDay(as: current) }).reduce(0, { $0 + $1.value * 60 })
                    }
                    return BarChartDataEntry(x: Double(index) + 0.5, yValues: yValues, data: current)
                }
                
                DispatchQueue.main.async {
                    let chartDataSet = BarChartDataSet(entries: dataEntries)
                    chartDataSet.axisDependency = .right
                    chartDataSet.colors = categories.map { $0.color }
                    let chartData = BarChartData(dataSets: [chartDataSet])
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
        let entries = networkController.activityService.events
            .filter {
                if let startDate = $0.startDate, let endDate = $0.endDate {
                    return startDate < range.endDate && endDate > range.startDate && !($0.allDay ?? false) && (endDate.timeIntervalSince1970 - startDate.timeIntervalSince1970 > 0)
                }
                return false
            }
            // at this point all activities should have a startDate (see above)
            .sorted(by: { $0.startDate! > $1.startDate! })
            .map { AnalyticsBreakdownEntry.activity($0) }
        completion(entries)
    }
}
