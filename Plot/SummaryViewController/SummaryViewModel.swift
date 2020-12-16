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
        summaryService.getSamples(segmentType: segmentType, activities: activities, transactions: transactions) { (activitySummary, calendarEntries, financesEntries, err) in
            self.sections = []
            if let activitySummary = activitySummary, !activitySummary.isEmpty {
                self.sections.append(.activitySummary)
                self.groups[.activitySummary] = activitySummary
            }
            
            if let entriesDictionary = calendarEntries, !entriesDictionary.isEmpty {
                for (_, entries) in entriesDictionary {
                    if entries.count > 0 {
                        let sortedEntries = entries.sorted(by: {$0.label < $1.label})
                        self.createPieChartData(entries: sortedEntries) { (pieChartData) in
                            self.sections.insert(.calendarSummary, at: 0)
                            self.groups[.calendarSummary] = [pieChartData]
                        }
                    }
                }
            }
            
            if let entriesDictionary = financesEntries, !entriesDictionary.isEmpty {
                for key in Array(entriesDictionary.keys).sorted() {
                    if let entries = entriesDictionary[key], entries.count > 0 {
                        self.createPieChartData(entries: entries) { (pieChartData) in
                            if key == "Financial Summary" {
                                self.sections.append(.financialSummary)
                                self.groups[.financialSummary] = [pieChartData]
                            } else {
                                self.sections.append(.spendingSummary)
                                self.groups[.spendingSummary] = [pieChartData]
                            }
                        }
                    }
                }
            }
            
            DispatchQueue.main.async {
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
        
        let set = PieChartDataSet(entries: chartEntries, label: nil)
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
        data.setValueFont(.systemFont(ofSize: 11, weight: .light))
        data.setValueTextColor(.white)
        completion(data)
    }
    
    func createBarChartData(statsDictionary: [String: [Statistic]], completion: @escaping (BarChartData) -> Void) {
        
        let data = BarChartData()
        data.setValueFont(UIFont(name: "HelveticaNeue-Light", size: 10)!)
        
        var maxValue: Double = 0
        var y = 0
        for (label, stats) in statsDictionary {
            var i = 0
            var chartEntries: [BarChartDataEntry] = []
            for stat in stats {
                maxValue = max(maxValue, stat.value)
                let entry = BarChartDataEntry(x: Double(i), y: stat.value, data: stat.date)
                chartEntries.append(entry)
                i += 1
            }
            let dataSet = BarChartDataSet(entries: chartEntries, label: label)
            dataSet.setColor(ChartColors.palette()[y])
            dataSet.drawValuesEnabled = false
            dataSet.axisDependency = .right
            data.addDataSet(dataSet)
            y += 1
        }
        maxValue *= 1.2
        
        completion(data)
    }
    
    func createLineChartData(statsDictionary: [String: [Statistic]], completion: @escaping (LineChartData) -> Void) {
        
        let data = LineChartData()
        data.setValueFont(UIFont(name: "HelveticaNeue-Light", size: 10)!)
        
        var maxValue: Double = 0
        var y = 0
        for (label, stats) in statsDictionary {
            var i = 0
            var chartEntries: [ChartDataEntry] = []
            for stat in stats {
                maxValue = max(maxValue, stat.value)
                let entry = ChartDataEntry(x: Double(i), y: stat.value, data: stat.date)
                chartEntries.append(entry)
                i += 1
            }
            let dataSet = LineChartDataSet(entries: chartEntries, label: label)
            dataSet.drawIconsEnabled = false
            dataSet.mode = .cubicBezier
            dataSet.setColor(UIColor.systemBlue)
            dataSet.setCircleColor(UIColor.systemBlue)
            dataSet.drawCirclesEnabled = false
            dataSet.drawValuesEnabled = false
            dataSet.circleRadius = 3
            dataSet.drawCircleHoleEnabled = false
            dataSet.valueFont = .systemFont(ofSize: 9)
            dataSet.formSize = 15
            dataSet.lineWidth = 0
            
            let colorTop = UIColor.systemBlue.cgColor
            let colorBottom = UIColor(red: 16.0/255.0, green: 28.0/255.0, blue: 56.0/255.0, alpha: 1.0).cgColor
            let gradientColors = [colorBottom, colorTop] as CFArray
            let gradient = CGGradient(colorsSpace: nil, colors: gradientColors as CFArray, locations: nil)!
            dataSet.fillAlpha = 1
            dataSet.fill = Fill(linearGradient: gradient, angle: 90)
            
            dataSet.drawFilledEnabled = true
            dataSet.axisDependency = .right
            
            data.addDataSet(dataSet)
            y += 1
        }
        maxValue *= 1.2
        
        completion(data)
    }
}
