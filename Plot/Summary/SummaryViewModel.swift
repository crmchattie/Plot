//
//  SummaryViewModel.swift
//  Plot
//
//  Created by Cory McHattie on 11/27/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import Foundation
import Charts
import HealthKit

protocol SummaryViewModelInterface {
    var activities: [Activity]? { get }
    var transactions: [Transaction]? { get set }
    var sections: [SectionType] { get }
    var groups: [SectionType: [AnyHashable]] { get }
    func fetchChartData(for segmentType: TimeSegmentType, completion: @escaping () -> ())
}

class SummaryViewModel: SummaryViewModelInterface {
    let summaryService: SummaryServiceInterface
    var fixedSections: [SectionType] = [.calendarSummary, .calendarMix, .activitySummary, .cashFlowSummary, .spendingMix]
    var sections = [SectionType]()
    var groups = [SectionType: [AnyHashable]]()
    
    var activities: [Activity]?
    var transactions: [Transaction]?
    
    init(activities: [Activity]?, transactions: [Transaction]?, summaryService: SummaryServiceInterface) {
        self.activities = activities
        self.transactions = transactions
        self.summaryService = summaryService
    }
    
    func fetchChartData(for segmentType: TimeSegmentType, completion: @escaping () -> ()) {
        summaryService.getSamples(segmentType: segmentType, activities: activities, transactions: transactions) { (activitySummary, pieChartEntries, barChartEntries, barChartStats, err) in
            self.sections = []
            if let activitySummary = activitySummary, !activitySummary.isEmpty {
                self.groups[.activitySummary] = activitySummary
            }
            
            if let entriesDictionary = barChartStats, !entriesDictionary.isEmpty {
                for (key, entries) in entriesDictionary {
                    self.createBarChartStats(statsDictionary: entries) { (barChartData) in
                        if key == .calendarSummary, barChartData.entryCount > 0 {
                            self.groups[.calendarSummary] = [barChartData]
                        }
                    }
                }
            }
            
            if let entriesDictionary = pieChartEntries, !entriesDictionary.isEmpty {
                for (key, entries) in entriesDictionary {
                    self.createPieChartData(entries: entries) { (pieChartData) in
                        if key == .spendingMix {
                            self.groups[.spendingMix] = [pieChartData]
                        } else if key == .calendarMix {
                            let sortedEntries = entries.sorted(by: {$0.label < $1.label})
                            self.createPieChartData(entries: sortedEntries) { (pieChartData) in
                                self.groups[.calendarMix] = [pieChartData]
                            }
                        }
                    }
                }
            }
            
            if let entriesDictionary = barChartEntries, !entriesDictionary.isEmpty {
                for (key, entries) in entriesDictionary {
                    self.createBarChartEntries(entries: entries) { (barChartData) in
                        if key == .cashFlowSummary {
                            self.groups[.cashFlowSummary] = [barChartData]
                        }
                    }
                }
            }
            
            DispatchQueue.main.async {
                self.sections = Array(self.groups.keys)
                self.sections = self.fixedSections.filter { self.sections.contains($0) }
                completion()
            }
        }
    }
    
    func createPieChartData(entries: [Entry], completion: @escaping (PieChartData) -> Void) {
        var i = 0
        var chartEntries: [ChartDataEntry] = []
        for entry in entries {
            let chartEntry = PieChartDataEntry(value: entry.value,
                                               label: entry.label,
                                               icon: entry.icon)
            chartEntries.append(chartEntry)
            i += 1
        }
        
        let set = PieChartDataSet(entries: chartEntries, label: "")
        set.drawIconsEnabled = false
        set.sliceSpace = 2
        
        set.colors = ChartColors.palette()
        
        let data = PieChartData(dataSet: set)
        
        let pFormatter = NumberFormatter()
        pFormatter.numberStyle = .percent
        pFormatter.maximumFractionDigits = 1
        pFormatter.minimumFractionDigits = 1
        pFormatter.multiplier = 1
        data.setValueFormatter(DefaultValueFormatter(formatter: pFormatter))
        data.setValueFont(UIFont.caption2.with(weight: .light))
        completion(data)
    }
    
    func createBarChartEntries(entries: [Entry], completion: @escaping (BarChartData) -> Void) {
        
        let data = BarChartData()
        data.setValueFont(UIFont(name: "HelveticaNeue-Light", size: 10)!)
        
        var chartEntries: [BarChartDataEntry] = []
        var maxValue: Double = 0
        var i = 0
        for entry in entries {
            let chartEntry = BarChartDataEntry(x: Double(i),
                                               y: entry.value,
                                               data: entry.label)
            chartEntries.append(chartEntry)
            i += 1
        }
        maxValue *= 1.2
        
        let dataSet = BarChartDataSet(entries: chartEntries, label: "")
        dataSet.colors = ChartColors.palette()
        dataSet.drawValuesEnabled = false
        dataSet.axisDependency = .right
        completion(data)
    }
    
    func createBarChartStats(statsDictionary: [String: [Statistic]], completion: @escaping (BarChartData) -> Void) {
        
        let data = BarChartData()
        data.setValueFont(UIFont(name: "HelveticaNeue-Light", size: 10)!)
        
        var y = 0
        var maxValue: Double = 0
        for (key, stats) in statsDictionary {
            print("key \(key)")
            var i = 0
            var entries: [BarChartDataEntry] = []
            for stat in stats {
                print("stat \(stat)")
                maxValue = max(maxValue, stat.value)
                let entry = BarChartDataEntry(x: Double(i), y: stat.value, data: stat.date)
                entries.append(entry)
                i += 1
            }
            
            let dataSet = BarChartDataSet(entries: entries, label: key)
            dataSet.setColor(ChartColors.palette()[y])
            dataSet.drawValuesEnabled = false
            dataSet.axisDependency = .right
            y += 1
        }
        
        maxValue *= 1.2
        
        completion(data)
    }
    
    func createLineChartData(statsDictionary: [String: [Statistic]], completion: @escaping (LineChartData) -> Void) {
        
        let data = LineChartData()
        data.setValueFont(UIFont(name: "HelveticaNeue-Light", size: 10)!)
        
        var y = 0
        var maxValue: Double = 0
        for (key, stats) in statsDictionary {
            var i = 0
            var entries: [ChartDataEntry] = []
            for stat in stats {
                maxValue = max(maxValue, stat.value)
                let entry = ChartDataEntry(x: Double(i), y: stat.value, data: stat.date)
                entries.append(entry)
                i += 1
            }
            
            let dataSet = LineChartDataSet(entries: entries, label: key)
            dataSet.drawIconsEnabled = false
            dataSet.mode = .cubicBezier
            dataSet.setColor(UIColor.systemBlue)
            dataSet.setCircleColor(UIColor.systemBlue)
            dataSet.drawCirclesEnabled = false
            dataSet.drawValuesEnabled = false
            dataSet.circleRadius = 3
            dataSet.drawCircleHoleEnabled = false
            dataSet.valueFont = UIFont.caption2.with(weight: .regular)
            dataSet.formSize = 15
            dataSet.lineWidth = 0            
            dataSet.fillAlpha = 1
            dataSet.drawFilledEnabled = true
            dataSet.axisDependency = .right
            y += 1
        }
        maxValue *= 1.2
        
        completion(data)
    }
}
