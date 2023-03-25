//
//  MindfulnessAnalyticsDataSource.swift
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

class MindfulnessAnalyticsDataSource: AnalyticsDataSource {
    func updateRange(_ newRange: DateRange) {
        
    }
    
    private let networkController: NetworkController
    private let healthDetailService = HealthDetailService()
    
    var range: DateRange
    
    let chartViewModel: CurrentValueSubject<StackedBarChartViewModel, Never>
    
    let title: String = "Mindfulnesss"
    let titleStringSingular = "mindfulness"
    let titleStringPlural = "mindfulness"
    
    private var mindfulness: [Mindfulness] = []
    
    var dataExists: Bool?
    
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
        var newChartViewModel = chartViewModel.value
        newChartViewModel.rangeDescription = getTitle(range: range)
        newChartViewModel.formatType = range.timeSegment

        switch chartViewModel.value.chartType {
        case .line:
            
            healthDetailService.getSamples(for: range, segment: range.timeSegment, mindfulness: networkController.healthService.mindfulnesses) { statsCurrent, mindfulnessListCurrent in
                guard !statsCurrent.isEmpty, let previousRange = self.range.previousDatesForComparison() else {
                    newChartViewModel.chartData = nil
                    newChartViewModel.categories = []
                    newChartViewModel.rangeAverageValue = "-"
                    self.chartViewModel.send(newChartViewModel)
                    self.mindfulness = []
                    completion?()
                    return
                }
                
                self.healthDetailService.getSamples(for: previousRange, segment: self.range.timeSegment, mindfulness: self.networkController.healthService.mindfulnesses) { statsPast, mindfulnessListPast in
                    
                    self.dataExists = true

                    let daysInRange = self.range.daysInRange + 1
                    let startDateCurrent = self.range.startDate.startOfDay
                    let startDatePast = self.range.pastStartDate?.startOfDay ?? startDateCurrent
                                    
                    self.mindfulness = Array(Set(mindfulnessListCurrent + mindfulnessListPast))
                    
                    DispatchQueue.global(qos: .userInteractive).async {
                        var chartDataSets = [LineChartDataSet]()
                        var categories: [CategorySummaryViewModel] = []
                        var dataEntriesCurrent: [ChartDataEntry] = []
                        let sumCurrent = statsCurrent.reduce(0, { $0 + $1.value * 60 })
//                        print("creating data entries mindfulness")
//                        print(sumCurrent)
//                        print(startDateCurrent)
//                        for current in statsCurrent {
//                            print(current.date)
//                            print(current.value)
//                        }
                        for index in 0...daysInRange {
                            let date = startDateCurrent.addDays(index)
                            if let stat = statsCurrent.first(where: { $0.date.startOfDay == date.startOfDay }) {
//                                print("found stat")
//                                print(stat.date)
//                                print(stat.value)
                                if !dataEntriesCurrent.contains(where: {$0.data as? Date == stat.date }) {
                                    let entry = ChartDataEntry(x: Double(index) + 1, y: stat.value * 60, data: date)
                                    dataEntriesCurrent.append(entry)
                                }
                            } else {
//                                print("did not find stat")
//                                print(date)
                                let entry = ChartDataEntry(x: Double(index) + 1, y: 0, data: date)
                                dataEntriesCurrent.append(entry)
                            }
                            
//                                let entry = ChartDataEntry(x: Double(index) + 1, y: average, data: date)
//                                dataEntriesCurrent.append(entry)
                        }
                        
                        let chartDataSetCurrent = LineChartDataSet(entries: dataEntriesCurrent)
                        chartDataSetCurrent.setDrawHighlightIndicators(false)
                        chartDataSetCurrent.axisDependency = .right
                        chartDataSetCurrent.colors = [NSUIColor.systemBlue]
                        chartDataSetCurrent.lineWidth = 5
                        chartDataSetCurrent.fillAlpha = 0
                        chartDataSetCurrent.drawFilledEnabled = true
                        chartDataSetCurrent.drawCirclesEnabled = false
                                                
                        let categoryCurrent = CategorySummaryViewModel(title: "This " + (self.range.type?.title ?? ""),
                                                                       color: .systemBlue,
                                                                       value: Double(sumCurrent),
                                                                       formattedValue: "\(self.dateFormatter.string(from: sumCurrent)!)")
                        categories.append(categoryCurrent)
                        var sumPast: Double = 0
                        if !statsPast.isEmpty {
                            var dataEntriesPast: [ChartDataEntry] = []
                            sumPast = statsPast.reduce(0, { $0 + $1.value * 60 })
                            for index in 0...daysInRange {
                                let date = startDatePast.addDays(index)
                                if let stat = statsPast.first(where: { $0.date.startOfDay == date.startOfDay }) {
                                    if !dataEntriesPast.contains(where: {$0.data as? Date == stat.date }) {
                                        let entry = ChartDataEntry(x: Double(index) + 1, y: stat.value * 60, data: date)
                                        dataEntriesPast.append(entry)
                                    }
                                } else {
                                    let entry = ChartDataEntry(x: Double(index) + 1, y: 0, data: date)
                                    dataEntriesPast.append(entry)
                                }

//
//                                    let entry = ChartDataEntry(x: Double(index) + 1, y: average, data: date)
//                                    dataEntriesPast.append(entry)
                            }
                            
                            let chartDataSetPast = LineChartDataSet(entries: dataEntriesPast)
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
                                                                        value: Double(sumPast),
                                                                        formattedValue: "\(self.dateFormatter.string(from: sumPast)!)")
                            categories.append(categoryPast)
                            
                        }
                                
                        chartDataSets.append(chartDataSetCurrent)
                        
                        newChartViewModel.categories = categories
                        
                        let change = sumCurrent - sumPast
                        
                        if let changeString = self.dateFormatter.string(from: change) {
                            if change > 0 {
                                newChartViewModel.rangeAverageValue = "+" + changeString
                            } else {
                                newChartViewModel.rangeAverageValue = changeString
                            }
                        }
            
                        
                        DispatchQueue.main.async {
                            if !self.mindfulness.isEmpty {
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
            break
        }
    }
    
    func fetchEntries(range: DateRange, completion: ([AnalyticsBreakdownEntry]) -> Void) {
        if range.filterOff {
            completion(mindfulness.sorted(by: { $0.startDateTime ?? Date() > $1.startDateTime ?? Date() }).map { .mindfulness($0) })
        } else {
            switch chartViewModel.value.chartType {
            case .line:
                let startDate = range.startDate
                let endDate = range.endDate
                print(startDate)
                print(endDate)
                let filteredMindfulnesss = mindfulness
                    .filter { mindfulness -> Bool in
                        guard let date = mindfulness.startDateTime?.localTime else { return false }
                        return startDate <= date && date <= endDate
                    }
                completion(filteredMindfulnesss.map { .mindfulness($0) })
            case .horizontalBar:
                let filteredMindfulnesss = mindfulness
                    .filter { mindfulness -> Bool in
                        guard let date = mindfulness.startDateTime?.localTime else { return false }
                        return range.startDate <= date && date <= range.endDate
                    }
                completion(filteredMindfulnesss.map { .mindfulness($0) })
            case .verticalBar:
                let filteredMindfulnesss = mindfulness
                    .filter { mindfulness -> Bool in
                        guard let date = mindfulness.startDateTime?.localTime else { return false }
                        return range.startDate <= date && date <= range.endDate
                    }
                completion(filteredMindfulnesss.map { .mindfulness($0) })
            }
        }
    }
}

