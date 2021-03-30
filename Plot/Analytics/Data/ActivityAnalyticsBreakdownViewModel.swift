//
//  ActivityAnalyticsBreakdownViewModel.swift
//  Plot
//
//  Created by Botond Magyarosi on 16.03.2021.
//  Copyright © 2021 Immature Creations. All rights reserved.
//

import Foundation
import Charts
import Combine

private let dateFormatter: DateComponentsFormatter = {
    let formatter = DateComponentsFormatter()
    formatter.unitsStyle = .abbreviated
    formatter.allowedUnits = [.hour, .minute]
    return formatter
}()

class ActivityAnalyticsBreakdownViewModel: AnalyticsBreakdownViewModel {
    
    private let networkController: NetworkController
    private let summaryService = SummaryService()
    
    let onChange = PassthroughSubject<Void, Never>()
    let verticalAxisValueFormatter: IAxisValueFormatter = HourValueFormatter()
    let fixToZeroOnVertical: Bool = true
    var range: DateRange
    
    let title: String = "Activities"
    private(set) var rangeDescription: String = ""
    private(set) var rangeAverageValue: String = "-"
    
    private(set) var categories: [CategorySummaryViewModel] = []
    
    private(set) var chartData: ChartData? = nil

    init(
        range: DateRange,
        networkController: NetworkController
    ) {
        self.networkController = networkController
        self.range = range
        
        updateTitle()
    }
    
    func loadData(completion: (() -> Void)?) {
        updateTitle()
        summaryService.getSamples(for: range, activities: networkController.activityService.activities) { stats in
            DispatchQueue.global(qos: .background).async {
                let activities = stats[.calendarSummary] ?? [:]
                
                let colors = activities.count > 0 ? Array(ChartColors.palette().prefix(activities.count)) : []
                var categories: [CategorySummaryViewModel] = []
                var activityCount = 0
                for (index, (category, stats)) in activities.enumerated() {
                    let total = stats.reduce(0, { $0 + $1.value * 60 })
                    let totalString = dateFormatter.string(from: total) ?? "NaN"
                    categories.append(CategorySummaryViewModel(title: category,
                                                               color: colors[index],
                                                               value: total,
                                                               formattedValue: totalString))
                    activityCount += stats.count
                }
                self.categories = Array(categories.sorted(by: { $0.value > $1.value }).prefix(3))
                
                
                self.rangeAverageValue = "\(activityCount) activities"
                
                let daysInRange = self.range.daysInRange
                let dataEntries = (0...daysInRange).map { index -> BarChartDataEntry in
                    let current = self.range.startDate.addDays(index)
                    let yValues = activities.map {
                        $0.value.filter({ $0.date.isSameDay(as: current) }).reduce(0, { $0 + $1.value * 60 })
                    }
                    return BarChartDataEntry(x: Double(index) + 0.5, yValues: yValues)
                }
                
                DispatchQueue.main.async {
                    if !activities.isEmpty {
                        let chartDataSet = BarChartDataSet(entries: dataEntries)
                        let chartData = BarChartData(dataSets: [chartDataSet])
                        chartDataSet.colors = colors
                        chartData.barWidth = 0.5
                        chartData.setDrawValues(false)
                        self.chartData = chartData
                    } else {
                        self.chartData = nil
                    }
                    self.onChange.send(())
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
            .map { AnalyticsBreakdownEntry.activity($0) }
        completion(entries)
    }
    
    // MARK: - Title
    
    private func updateTitle() {
        rangeDescription = DateRangeFormatter(currentWeek: "This week", currentMonth: "This month", currentYear: "This year")
            .format(range: range)
    }
}
