//
//  GoalsAnalyticsDataSource.swift
//  Plot
//
//  Created by Cory McHattie on 2/15/23.
//  Copyright © 2023 Immature Creations. All rights reserved.
//

import Foundation
import Charts
import Combine

private func getTitle(range: DateRange) -> String {
    DateRangeFormatter(currentWeek: "Vs. prior week", currentMonth: "Vs. prior month", currentYear: "Vs. prior year")
        .format(range: range)
//    DateRangeFormatter(currentWeek: "Over the last week", currentMonth: "Over the last month", currentYear: "Over the last year").format(range: range)
}

class GoalAnalyticsDataSource: AnalyticsDataSource {    
    func updateRange(_ newRange: DateRange) {
        
    }
    
    private let networkController: NetworkController
    private let activityDetailService = ActivityDetailService()
    
    var range: DateRange
    
    let chartViewModel: CurrentValueSubject<StackedBarChartViewModel, Never>
    
    let title: String = "Goals"
    
    private var goals: [Activity] = []
    
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
        
        chartViewModel = .init(StackedBarChartViewModel(chartType: .line,
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
            
            let daysInRange = range.daysInRange + 1
            let startDateCurrent = range.startDate.startOfDay
            let startDatePast = range.pastStartDate?.startOfDay ?? startDateCurrent
            
            activityDetailService.getActivityCategoriesSamples(for: range, segment: range.timeSegment, activities: networkController.activityService.goals, isEvent: false) { categoryStatsCurrent, goalListCurrent in
                guard !categoryStatsCurrent.isEmpty, let previousRange = self.range.previousDatesForComparison() else {
                    newChartViewModel.chartData = nil
                    newChartViewModel.categories = []
                    newChartViewModel.rangeAverageValue = "-"
                    self.chartViewModel.send(newChartViewModel)
                    self.goals = []
                    completion?()
                    return
                }
                
                self.activityDetailService.getActivityCategoriesSamples(for: previousRange, segment: self.range.timeSegment, activities: self.networkController.activityService.goals, isEvent: false) { categoryStatsPast, goalListPast in
                    
                    self.goals = Array(Set(goalListCurrent + goalListPast))
                    self.dataExists = true
                    
                    DispatchQueue.global(qos: .userInteractive).async {
                        var categoriesCurrent: [CategorySummaryViewModel] = []
                        let keysCurrent = categoryStatsCurrent.keys.sorted(by: <)
                        for index in 0...keysCurrent.count - 1 {
                            guard let statsCurrent = categoryStatsCurrent[keysCurrent[index]] else { continue }
                            let total = statsCurrent.reduce(0, { $0 + $1.value })
                            var totalString = String()
                            if total == 1 {
                                totalString = "1 goal"
                            } else {
                                totalString = "\(Int(total)) goals"
                            }
                            
                            var categoryColor = UIColor()
                            if let activityCategory = ActivityCategory(rawValue: keysCurrent[index]) {
                                categoryColor = activityCategory.color
                            } else {
                                categoryColor = ActivityCategory.uncategorized.color
                            }
                            categoriesCurrent.append(CategorySummaryViewModel(title: keysCurrent[index],
                                                                       color: categoryColor,
                                                                       value: total,
                                                                       formattedValue: totalString))
                        }
                        
                        var cumulative: Double = 0
                        var dataEntries = (0...daysInRange).map { index -> ChartDataEntry in
                            let date = startDateCurrent.addDays(index)
                            let yValues = categoriesCurrent.map {
                                (categoryStatsCurrent[$0.title] ?? []).filter({ $0.date.isSameDay(as: date) }).reduce(0, { $0 + $1.value })
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
                        
                        var chartDataSets = [chartDataSetCurrent]
                        
                        if !categoryStatsPast.isEmpty {
                            var categoriesPast: [CategorySummaryViewModel] = []
                            let keysPast = categoryStatsPast.keys.sorted(by: <)
                            for index in 0...keysPast.count - 1 {
                                guard let statsPast = categoryStatsPast[keysPast[index]] else { continue }
                                let total = statsPast.reduce(0, { $0 + $1.value })
                                var totalString = String()
                                if total == 1 {
                                    totalString = "1 goal"
                                } else {
                                    totalString = "\(Int(total)) goals"
                                }
                                
                                var categoryColor = UIColor()
                                if let activityCategory = ActivityCategory(rawValue: keysPast[index]) {
                                    categoryColor = activityCategory.color
                                } else {
                                    categoryColor = ActivityCategory.uncategorized.color
                                }
                                categoriesPast.append(CategorySummaryViewModel(title: keysPast[index],
                                                                           color: categoryColor,
                                                                           value: total,
                                                                           formattedValue: totalString))
                            }
                            
                            cumulative = 0
                            dataEntries = (0...daysInRange).map { index -> ChartDataEntry in
                                let date = startDatePast.addDays(index)
                                let yValues = categoriesPast.map {
                                    (categoryStatsPast[$0.title] ?? []).filter({ $0.date.isSameDay(as: date) }).reduce(0, { $0 + $1.value })
                                }.reduce(0, +)
                                cumulative += yValues
                                return ChartDataEntry(x: Double(index) + 1, y: cumulative, data: date)
                            }
                            
                            let chartDataSetPast = LineChartDataSet(entries: dataEntries)
                            chartDataSetPast.setDrawHighlightIndicators(false)
                            chartDataSetPast.axisDependency = .right
                            chartDataSetPast.colors = [NSUIColor.systemGray]
                            chartDataSetPast.lineWidth = 5
                            chartDataSetPast.fillAlpha = 0
                            chartDataSetPast.drawFilledEnabled = true
                            chartDataSetPast.drawCirclesEnabled = false
                            chartDataSets.append(chartDataSetPast)
                        }
                        
                        categoriesCurrent.sort(by: { $0.value > $1.value })
                                                
                        newChartViewModel.categories = Array(categoriesCurrent.prefix(3))
                        
                        let change = goalListCurrent.count - goalListPast.count
                        
                        if change == 0 {
                            newChartViewModel.rangeAverageValue = "On Track"
                        } else if change == 1 {
                            newChartViewModel.rangeAverageValue = "+1 completed goal"
                        } else if change == -1 {
                            newChartViewModel.rangeAverageValue = "-1 completed goal"
                        } else if change < -1 {
                            newChartViewModel.rangeAverageValue = "\(Int(change)) completed goals"
                        } else if change > 1 {
                            newChartViewModel.rangeAverageValue = "+\(Int(change)) completed goals"
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
            activityDetailService.getActivityCategoriesSamples(for: range, segment: range.timeSegment, activities: networkController.activityService.goals, isEvent: false) { categoryStats, goalList in
                            
                guard !categoryStats.isEmpty else {
                    newChartViewModel.chartData = nil
                    newChartViewModel.categories = []
                    newChartViewModel.rangeAverageValue = "-"
                    self.chartViewModel.send(newChartViewModel)
                    completion?()
                    return
                }
                
                self.goals = goalList
                            
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
                            totalString = "1 goal"
                        } else {
                            totalString = "\(Int(total)) goals"
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
                    if goalList.count == 0 {
                        newChartViewModel.rangeAverageValue = "No completed goals"
                    } else if goalList.count == 1 {
                        newChartViewModel.rangeAverageValue = "1 completed goal"
                    } else {
                        newChartViewModel.rangeAverageValue = "\(Int(goalList.count)) completed goals"
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
            completion(goals.sorted(by: { $0.completedDateDate ?? Date() > $1.completedDateDate ?? Date() }).map { .activity($0) })
        } else {
            switch chartViewModel.value.chartType {
            case .line:
                let startDate = range.startDate.dayBefore
                let endDate = range.endDate.dayBefore
                let filteredGoals = goals
                    .filter { goal -> Bool in
                        guard let date = goal.completedDateDate?.localTime else { return false }
                        return startDate <= date && date <= endDate
                    }
                completion(filteredGoals.map { .activity($0) })
            case .horizontalBar:
                let filteredGoals = goals
                    .filter { goal -> Bool in
                        guard let date = goal.completedDateDate?.localTime else { return false }
                        return range.startDate <= date && date <= range.endDate
                    }
                completion(filteredGoals.map { .activity($0) })
            case .verticalBar:
                let filteredGoals = goals
                    .filter { goal -> Bool in
                        guard let date = goal.completedDateDate?.localTime else { return false }
                        return range.startDate <= date && date <= range.endDate
                    }
                completion(filteredGoals.map { .activity($0) })
            }
        }
    }
}
