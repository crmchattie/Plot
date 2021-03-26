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

struct ActivityAnalyticsBreakdownViewModel: AnalyticsBreakdownViewModel {
    
    private let networkController: NetworkController
    private let summaryService = SummaryService()
    
    let onChange = PassthroughSubject<Void, Never>()
    let verticalAxisValueFormatter: IAxisValueFormatter = HourValueFormatter()
    var canNavigate: Bool
    var range: DateRange
    
    let sectionTitle: String = "Activities"
    private(set) var title: String
    private(set) var description: String
    
    var categories: [CategorySummaryViewModel]
    
    let chartData: BarChartData

    init(
        items: [String: [Statistic]],
        canNavigate: Bool,
        range: DateRange,
        networkController: NetworkController
    ) {
        self.networkController = networkController
        self.canNavigate = canNavigate
        self.range = range
        
        let colors = items.count > 0 ? Array(ChartColors.palette().prefix(items.count)) : []
        var categories: [CategorySummaryViewModel] = []
        var activityCount = 0
        for (index, (category, stats)) in items.enumerated() {
            let total = stats.reduce(0, { $0 + $1.value * 60 })
            let totalString = dateFormatter.string(from: total) ?? "NaN"
            categories.append(CategorySummaryViewModel(title: category,
                                                       color: colors[index],
                                                       value: total,
                                                       formattedValue: totalString))
            activityCount += stats.count
        }
        self.categories = Array(categories.sorted(by: { $0.value > $1.value }).prefix(3))
        
        title = DateRangeFormatter(currentWeek: "This week", currentMonth: "This month", currentYear: "This year")
            .format(range: range)
        
        description = "\(activityCount) activities"
        
        let daysToCover = range.endDate.daysSince(range.startDate)
        let dataEntries = (0...daysToCover).map { index -> BarChartDataEntry in
            let current = range.startDate.addDays(index)
            let yValues = items.map {
                $0.value.filter({ $0.date.isSameDay(as: current) }).reduce(0, { $0 + $1.value * 60 })
            }
            return BarChartDataEntry(x: Double(index) + 0.5, yValues: yValues)
        }
        
        let chartDataSet = BarChartDataSet(entries: dataEntries)
        if !items.isEmpty {
            chartDataSet.colors = colors
        }
        chartData = BarChartData(dataSets: [chartDataSet])
        chartData.barWidth = 0.5
        chartData.setDrawValues(false)
    }
    
//    private func loadData() {
//        summaryService.getSamples(segmentType: .week,
//                                   activities: networkController.activityService.activities,
//                                   transactions: nil) { (_, foo, bar, stats, err) in
//            DispatchQueue.global(qos: .background).async {
//                let activities = stats?[.calendarSummary] ?? [:]
//                self.items.append(ActivityAnalyticsBreakdownViewModel(items: activities, canNavigate: false,
//                                                                      range: self.range,
//                                                                      networkController: self.networkController))
//                DispatchQueue.main.async {
//                    completion(.success(()))
//                }
//            }
//
//        summaryService.getSamples(segmentType: .week, activities: <#T##[Activity]?#>, transactions: <#T##[Transaction]?#>, completion: <#T##([HKActivitySummary]?, [SectionType : [Entry]]?, [SectionType : [Entry]]?, [SectionType : [String : [Statistic]]]?, Error?) -> Void#>)
//        networkController.activityService
//    }
    
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
}
