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
                for (key, entries) in entriesDictionary {
                    if entries.count > 0 {
                        self.createPieChartData(label: key, entries: entries) { (pieChartData) in
                            self.sections.insert(.calendarSummary, at: 0)
                            self.groups[.calendarSummary] = [pieChartData]
                        }
                    }
                }
                
            }
            
            if let entriesDictionary = financesEntries, !entriesDictionary.isEmpty {
                for key in Array(entriesDictionary.keys).sorted() {
                    if let entries = entriesDictionary[key], entries.count > 0 {
                        self.createPieChartData(label: key, entries: entries) { (pieChartData) in
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
    
    func createPieChartData(label: String, entries: [Entry], completion: @escaping (PieChartData) -> Void) {
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
}
