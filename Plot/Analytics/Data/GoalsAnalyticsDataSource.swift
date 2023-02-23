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
    DateRangeFormatter(currentWeek: "Vs. the prior week", currentMonth: "Vs. the prior month", currentYear: "Vs. the prior year")
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
                                                        units: "shifted_completed",
                                                        formatType: range.timeSegment))
    }
    
    func loadData(completion: (() -> Void)?) {
        var newChartViewModel = chartViewModel.value
        newChartViewModel.rangeDescription = getTitle(range: range)
        newChartViewModel.formatType = range.timeSegment

        switch chartViewModel.value.chartType {
        case .line:
            
            let daysInRange = range.daysInRange + 1
            let currentStartDate = range.startDate.startOfDay
            let pastStartDate = range.pastStartDate?.startOfDay ?? currentStartDate
            
            activityDetailService.getActivityCategoriesSamples(for: range, segment: range.timeSegment, activities: networkController.activityService.goals, isEvent: false) { currentCategoryStats, currentGoalList in
                guard !currentCategoryStats.isEmpty, let previousRange = self.range.previousDatesForComparison() else {
                    newChartViewModel.chartData = nil
                    newChartViewModel.categories = []
                    newChartViewModel.rangeAverageValue = "-"
                    self.chartViewModel.send(newChartViewModel)
                    self.goals = []
                    completion?()
                    return
                }
                
                self.activityDetailService.getActivityCategoriesSamples(for: previousRange, segment: self.range.timeSegment, activities: self.networkController.activityService.goals, isEvent: false) { pastCategoryStats, pastGoalList in
                    
                    self.goals = currentGoalList
                    self.dataExists = true
                    
                    DispatchQueue.global(qos: .userInteractive).async {
                        var currentCategories: [CategorySummaryViewModel] = []
                        let currentKeys = currentCategoryStats.keys.sorted(by: <)
                        for index in 0...currentKeys.count - 1 {
                            guard let currentStats = currentCategoryStats[currentKeys[index]] else { continue }
                            let total = currentStats.reduce(0, { $0 + $1.value })
                            var totalString = String()
                            if total == 1 {
                                totalString = "1 goal"
                            } else {
                                totalString = "\(Int(total)) goals"
                            }
                            
                            var categoryColor = UIColor()
                            if let activityCategory = ActivityCategory(rawValue: currentKeys[index]) {
                                categoryColor = activityCategory.color
                            } else {
                                categoryColor = ActivityCategory.uncategorized.color
                            }
                            currentCategories.append(CategorySummaryViewModel(title: currentKeys[index],
                                                                       color: categoryColor,
                                                                       value: total,
                                                                       formattedValue: totalString))
                        }
                        
                        currentCategories.sort(by: { $0.value > $1.value })
                                                
                        newChartViewModel.categories = Array(currentCategories.prefix(3))
                        
                        let changeInGoals = currentGoalList.count - pastGoalList.count
                        
                        if changeInGoals == 0 {
                            newChartViewModel.rangeAverageValue = "On Track"
                        } else if changeInGoals == 1 {
                            newChartViewModel.rangeAverageValue = "+1 completed goal"
                        } else if changeInGoals == -1 {
                            newChartViewModel.rangeAverageValue = "1 completed goal"
                        } else if changeInGoals < -1 {
                            newChartViewModel.rangeAverageValue = "\(Int(changeInGoals)) completed goals"
                        } else if changeInGoals > 1 {
                            newChartViewModel.rangeAverageValue = "+\(Int(changeInGoals)) completed goals"
                        }
                        
                        var cumulative: Double = 0
                        let currentDataEntries = (0...daysInRange).map { index -> ChartDataEntry in
                            let date = currentStartDate.addDays(index)
                            let yValues = currentCategories.map {
                                (currentCategoryStats[$0.title] ?? []).filter({ $0.date.isSameDay(as: date) }).reduce(0, { $0 + $1.value })
                            }.reduce(0, +)
                            cumulative += yValues
                            return ChartDataEntry(x: Double(index) + 1, y: cumulative, data: date)
                        }
                        
                        let currentChartDataSet = LineChartDataSet(entries: currentDataEntries)
                        currentChartDataSet.setDrawHighlightIndicators(false)
                        currentChartDataSet.axisDependency = .right
                        currentChartDataSet.colors = [NSUIColor.systemBlue]
                        currentChartDataSet.lineWidth = 5
                        currentChartDataSet.fillAlpha = 0
                        currentChartDataSet.drawFilledEnabled = true
                        currentChartDataSet.drawCirclesEnabled = false
                        
                        var chartDataSets = [currentChartDataSet]
                        
                        if !pastCategoryStats.isEmpty {
                            var pastCategories: [CategorySummaryViewModel] = []
                            let pastKeys = pastCategoryStats.keys.sorted(by: <)
                            for index in 0...pastKeys.count - 1 {
                                guard let pastStats = pastCategoryStats[pastKeys[index]] else { continue }
                                let total = pastStats.reduce(0, { $0 + $1.value })
                                var totalString = String()
                                if total == 1 {
                                    totalString = "1 goal"
                                } else {
                                    totalString = "\(Int(total)) goals"
                                }
                                
                                var categoryColor = UIColor()
                                if let activityCategory = ActivityCategory(rawValue: pastKeys[index]) {
                                    categoryColor = activityCategory.color
                                } else {
                                    categoryColor = ActivityCategory.uncategorized.color
                                }
                                pastCategories.append(CategorySummaryViewModel(title: pastKeys[index],
                                                                           color: categoryColor,
                                                                           value: total,
                                                                           formattedValue: totalString))
                            }
                            
                            cumulative = 0
                            let pastDataEntries = (0...daysInRange).map { index -> ChartDataEntry in
                                let date = pastStartDate.addDays(index)
                                let yValues = pastCategories.map {
                                    (pastCategoryStats[$0.title] ?? []).filter({ $0.date.isSameDay(as: date) }).reduce(0, { $0 + $1.value })
                                }.reduce(0, +)
                                cumulative += yValues
                                return ChartDataEntry(x: Double(index) + 1, y: cumulative, data: date)
                            }
                            
                            let pastChartDataSet = LineChartDataSet(entries: pastDataEntries)
                            pastChartDataSet.setDrawHighlightIndicators(false)
                            pastChartDataSet.axisDependency = .right
                            pastChartDataSet.colors = [NSUIColor.systemGray]
                            pastChartDataSet.lineWidth = 5
                            pastChartDataSet.fillAlpha = 0
                            pastChartDataSet.drawFilledEnabled = true
                            pastChartDataSet.drawCirclesEnabled = false
                            pastChartDataSet.highlightEnabled = false
                            chartDataSets.append(pastChartDataSet)
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
