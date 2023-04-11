//
//  WorkoutAnalyticsDataSource.swift
//  Plot
//
//  Created by Cory McHattie on 2/27/23.
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

class WorkoutAnalyticsDataSource: AnalyticsDataSource {
    func updateRange(_ newRange: DateRange) {
        
    }
    
    private let networkController: NetworkController
    private let healthDetailService = HealthDetailService()
    
    var range: DateRange
    
    let chartViewModel: CurrentValueSubject<StackedBarChartViewModel, Never>
    
    let title: String = "Workouts"
    let titleStringSingular = "workout"
    let titleStringPlural = "workouts"
    
    private var workouts: [Workout] = []
    lazy var loadedWorkouts: [Workout] = networkController.healthService.workouts
    
    var dataExists: Bool?
    var dateLoadedPast = Date().addMonths(-2)
    
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
        
        chartViewModel = .init(StackedBarChartViewModel(chartType: .line,
                                                        rangeDescription: getTitle(range: range),
                                                        verticalAxisValueFormatter: HourAxisValueFormatter(),
                                                        units: "time",
                                                        formatType: range.timeSegment))
    }
    
    func loadData(completion: (() -> Void)?) {
        let startDate = range.pastStartDate ?? range.startDate
        if startDate < dateLoadedPast {
            networkController.healthService.workoutFetcher.loadUnloadedWorkouts(startDate: startDate, endDate: range.endDate) { workoutList in
                self.dateLoadedPast = startDate
                for workout in workoutList {
                    if let index = self.loadedWorkouts.firstIndex(where: { $0.id == workout.id }) {
                        self.loadedWorkouts[index] = workout
                    } else {
                        self.loadedWorkouts.append(workout)
                    }
                }
                self.setupChart(completion: completion)
            }
        }  else {
            self.setupChart(completion: completion)
        }
    }
    
    func setupChart(completion: (() -> Void)?) {
        var newChartViewModel = chartViewModel.value
        newChartViewModel.rangeDescription = getTitle(range: range)
        newChartViewModel.formatType = range.timeSegment

        switch chartViewModel.value.chartType {
        case .line:
            
            healthDetailService.getSamples(for: range, segment: range.timeSegment, workouts: self.loadedWorkouts, measure: .duration) { categoryStatsCurrent, workoutListCurrent in
                guard !categoryStatsCurrent.isEmpty, let previousRange = self.range.previousDatesForComparison() else {
                    newChartViewModel.chartData = nil
                    newChartViewModel.categories = []
                    newChartViewModel.rangeAverageValue = "-"
                    self.chartViewModel.send(newChartViewModel)
                    self.workouts = []
                    completion?()
                    return
                }
                
                self.healthDetailService.getSamples(for: previousRange, segment: self.range.timeSegment, workouts: self.loadedWorkouts, measure: .duration) { categoryStatsPast, workoutListPast in
                    
                    self.dataExists = true

                    let daysInRange = self.range.daysInRange + 1
                    let startDateCurrent = self.range.startDate.startOfDay
                    let startDatePast = self.range.pastStartDate?.startOfDay ?? startDateCurrent
                                    
                    self.workouts = Array(Set(workoutListCurrent + workoutListPast))
                    
                    DispatchQueue.global(qos: .userInteractive).async {
                        var chartDataSets = [LineChartDataSet]()
                        var categories: [CategorySummaryViewModel] = []
                        let keysCurrent = categoryStatsCurrent.keys.sorted(by: <)
                        var cumulativeCurrent: Double = 0
                        var dataEntries = (0...daysInRange).map { index -> ChartDataEntry in
                            let date = startDateCurrent.addDays(index)
                            let yValues = keysCurrent.map {
                                (categoryStatsCurrent[$0] ?? []).filter({ $0.date.dayAfter.isSameDay(as: date) }).reduce(0, { $0 + $1.value * 60 })
                            }.reduce(0, +)
                            cumulativeCurrent += yValues
                            return ChartDataEntry(x: Double(index) + 1, y: cumulativeCurrent, data: date)
                        }
                        
                        let chartDataSetCurrent = LineChartDataSet(entries: dataEntries)
                        chartDataSetCurrent.setDrawHighlightIndicators(false)
                        chartDataSetCurrent.axisDependency = .right
                        chartDataSetCurrent.colors = [NSUIColor.systemBlue]
                        chartDataSetCurrent.lineWidth = 5
                        chartDataSetCurrent.fillAlpha = 0
                        chartDataSetCurrent.drawFilledEnabled = true
                        chartDataSetCurrent.drawCirclesEnabled = false
                                                
                        let categoryCurrent = CategorySummaryViewModel(title: "This " + (self.range.type?.title ?? ""),
                                                                       color: .systemBlue,
                                                                       value: Double(cumulativeCurrent),
                                                                       formattedValue: "\(self.dateFormatter.string(from: cumulativeCurrent)!)")
                        categories.append(categoryCurrent)
                        var cumulativePast: Double = 0
                        
                        if !categoryStatsPast.isEmpty {
                            let keysPast = categoryStatsPast.keys
                            
                            dataEntries = (0...daysInRange).map { index -> ChartDataEntry in
                                let date = startDatePast.addDays(index)
                                let yValues = keysPast.map {
                                    (categoryStatsPast[$0] ?? []).filter({ $0.date.dayAfter.isSameDay(as: date) }).reduce(0, { $0 + $1.value * 60 })
                                }.reduce(0, +)
                                cumulativePast += yValues
                                return ChartDataEntry(x: Double(index) + 1, y: cumulativePast, data: date)
                            }
                            
                            let chartDataSetPast = LineChartDataSet(entries: dataEntries)
                            chartDataSetPast.setDrawHighlightIndicators(false)
                            chartDataSetPast.axisDependency = .right
                            chartDataSetPast.colors = [NSUIColor.systemGray4]
                            chartDataSetPast.lineWidth = 5
                            chartDataSetPast.fillAlpha = 0
                            chartDataSetPast.drawFilledEnabled = true
                            chartDataSetPast.drawCirclesEnabled = false
                            chartDataSets.append(chartDataSetPast)
                            
                            let categoryPast = CategorySummaryViewModel(title: "Last " + (self.range.type?.title ?? ""),
                                                                        color: .secondaryLabel,
                                                                        value: Double(cumulativePast),
                                                                        formattedValue: "\(self.dateFormatter.string(from: cumulativePast)!)")
                            categories.append(categoryPast)
                            
                        }
                                
                        chartDataSets.append(chartDataSetCurrent)
                        
                        newChartViewModel.categories = categories
                        
                        let change = cumulativeCurrent - cumulativePast
                        
                        if let changeString = self.dateFormatter.string(from: change) {
                            if change > 0 {
                                newChartViewModel.rangeAverageValue = "+" + changeString
                            } else {
                                newChartViewModel.rangeAverageValue = changeString
                            }
                        }
            
                        
                        DispatchQueue.main.async {
                            if !self.workouts.isEmpty {
                                self.dataExists = true
                                let chartData = LineChartData(dataSets: chartDataSets)
                                chartData.setDrawValues(false)
                                newChartViewModel.chartData = chartData
                                self.chartViewModel.send(newChartViewModel)
                                completion?()
                            } else {
                                self.dataExists = false
                                newChartViewModel.chartData = nil
                                newChartViewModel.categories = []
                                newChartViewModel.rangeAverageValue = "-"
                                self.chartViewModel.send(newChartViewModel)
                                completion?()
                            }
                        }
                    }
                }
            }
        case .horizontalBar:
            break
        case .verticalBar:
            healthDetailService.getSamples(for: range, segment: range.timeSegment, workouts: self.loadedWorkouts, measure: .duration) { categoryStats, workoutList in
                guard !workoutList.isEmpty else {
                    newChartViewModel.chartData = nil
                    newChartViewModel.categories = []
                    newChartViewModel.rangeAverageValue = "-"
                    self.chartViewModel.send(newChartViewModel)
                    completion?()
                    return
                }
                
                self.workouts = workoutList
                            
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
                            totalString = "1 " + self.titleStringSingular
                        } else {
                            totalString = "\(Int(total)) " + self.titleStringPlural
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
                    if workoutList.count == 0 {
                        newChartViewModel.rangeAverageValue = "No " + self.titleStringPlural
                    } else if workoutList.count == 1 {
                        newChartViewModel.rangeAverageValue = "1 " + self.titleStringSingular
                    } else {
                        newChartViewModel.rangeAverageValue = "\(Int(workoutList.count)) completed " + self.titleStringPlural
                    }
                    
                    let daysInRange = self.range.daysInRange
                    let dataEntries = (0...daysInRange).map { index -> BarChartDataEntry in
                        let current = self.range.startDate.addDays(index)
                        let yValues = categories.map {
                            (categoryStats[$0.title] ?? []).filter({ $0.date.dayAfter.isSameDay(as: current) }).reduce(0, { $0 + $1.value * 60 })
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
            completion(workouts.sorted(by: { $0.startDateTime ?? Date() > $1.startDateTime ?? Date() }).map { .workout($0) })
        } else {
            switch chartViewModel.value.chartType {
            case .line:
                let startDate = range.startDate.dayBefore
                let endDate = range.endDate.dayBefore
                let filteredWorkouts = workouts
                    .filter { workout -> Bool in
                        guard let date = workout.startDateTime?.localTime else { return false }
                        return startDate <= date && date <= endDate
                    }
                completion(filteredWorkouts.map { .workout($0) })
            case .horizontalBar:
                let filteredWorkouts = workouts
                    .filter { workout -> Bool in
                        guard let date = workout.startDateTime?.localTime else { return false }
                        return range.startDate <= date && date <= range.endDate
                    }
                completion(filteredWorkouts.map { .workout($0) })
            case .verticalBar:
                let filteredWorkouts = workouts
                    .filter { workout -> Bool in
                        guard let date = workout.startDateTime?.localTime else { return false }
                        return range.startDate <= date && date <= range.endDate
                    }
                completion(filteredWorkouts.map { .workout($0) })
            }
        }
    }
}
