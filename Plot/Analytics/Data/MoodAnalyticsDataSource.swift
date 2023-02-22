//
//  MoodAnalyticsDataSource.swift
//  Plot
//
//  Created by Cory McHattie on 2/21/23.
//  Copyright © 2023 Immature Creations. All rights reserved.
//

import Foundation
import Charts
import Combine
import HealthKit

private func getTitle(range: DateRange) -> String {
    DateRangeFormatter(currentWeek: "Daily average", currentMonth: "Monthly average", currentYear: "Yearly average")
        .format(range: range)
}

// Active calories
class MoodAnalyticsDataSource: AnalyticsDataSource {
    func updateRange(_ newRange: DateRange) {
        
    }
    
    private let networkController: NetworkController
    private let healthDetailService = HealthDetailService()
    
    var range: DateRange

    var title: String = "Active Calories"
    let chartViewModel: CurrentValueSubject<StackedBarChartViewModel, Never>
    private var moods: [Mood] = []
    
    var dataExists: Bool?
    
    var numberFormatter: NumberFormatter = {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        numberFormatter.maximumFractionDigits = 0
        return numberFormatter
    }()
    
    init(
        range: DateRange,
        networkController: NetworkController
    ) {
        self.networkController = networkController
        self.range = range
     
        chartViewModel = .init(StackedBarChartViewModel(chartType: .verticalBar,
                                                        rangeDescription: getTitle(range: range),
                                                        units: "mood",
                                                        formatType: range.timeSegment))
    }
    
    func loadData(completion: (() -> Void)?) {
        var newChartViewModel = chartViewModel.value
        newChartViewModel.rangeDescription = getTitle(range: range)
        newChartViewModel.formatType = range.timeSegment
        healthDetailService.getSamples(for: range, segment: range.timeSegment, moods: networkController.healthService.moods) { categoryStats, moodList in
                        
            guard !categoryStats.isEmpty else {
                newChartViewModel.chartData = nil
                newChartViewModel.categories = []
                newChartViewModel.rangeAverageValue = "-"
                self.chartViewModel.send(newChartViewModel)
                completion?()
                return
            }
            
            self.moods = moodList
                        
            self.dataExists = true
            
            DispatchQueue.global(qos: .userInteractive).async {
                var categories: [CategorySummaryViewModel] = []
                var count = 0
                var maxValue = Double()
                
                let keys = categoryStats.keys.sorted(by: <)
                for index in 0...keys.count - 1 {
                    guard let stats = categoryStats[keys[index]] else { continue }
                    let total = stats.reduce(0, { $0 + $1.value })
                    var totalString = String()
                    if total == 1 {
                        totalString = "1 mood"
                    } else {
                        totalString = "\(Int(total)) moods"
                    }
                    
                    var color = UIColor()
                    if let moodType = MoodType(rawValue: keys[index]) {
                        color = moodType.color
                    } else {
                        color = ChartColors.palette()[6]
                    }
                    categories.append(CategorySummaryViewModel(title: keys[index],
                                                               color: color,
                                                               value: total,
                                                               formattedValue: totalString))
                    count += stats.count
                }
                
                let daysInRange = self.range.daysInRange
                let dataEntries = (0...daysInRange).map { index -> BarChartDataEntry in
                    let current = self.range.startDate.addDays(index)
                    let yValues = categories.map {
                        (categoryStats[$0.title] ?? []).filter({ $0.date.isSameDay(as: current) }).reduce(0, { $0 + $1.value })
                    }
                    maxValue = max(maxValue, yValues.reduce(0, +))
                    return BarChartDataEntry(x: Double(index) + 0.5, yValues: yValues, data: current)
                }
                
                newChartViewModel.categories = Array(categories.sorted(by: { $0.value > $1.value }).prefix(3))
                if moodList.count == 0 {
                    newChartViewModel.rangeAverageValue = "No moods"
                } else if moodList.count == 1 {
                    newChartViewModel.rangeAverageValue = "1 mood"
                } else {
                    newChartViewModel.rangeAverageValue = "\(moodList.count) moods"
                    newChartViewModel.maxValue = maxValue + 1
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
            completion(moods.sorted(by: { $0.moodDate ?? Date() > $1.moodDate ?? Date() }).map { .mood($0) })
        } else {
            let filteredMoods = moods
                .filter { mood -> Bool in
                    guard let date = mood.moodDate?.localTime else { return false }
                    return range.startDate <= date && date <= range.endDate
                }
            completion(filteredMoods.map { .mood($0) })
        }
    }
}
