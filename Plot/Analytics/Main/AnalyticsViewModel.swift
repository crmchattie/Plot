//
//  AnalyticsViewModel.swift
//  Plot
//
//  Created by Botond Magyarosi on 15.03.2021.
//  Copyright © 2021 Immature Creations. All rights reserved.
//

import Foundation
import Charts
import HealthKit

class AnalyticsViewModel {
    
    private let activityService = SummaryService()
    private let healthDetailService = HealthDetailService()
    private let healthService = HealthService()
    
    let networkController: NetworkController
    
    private(set) var items: [StackedBarChartViewModel] = []
    private let range = (Date().startOfWeek, Date().endOfWeek)
    
    init(networkController: NetworkController) {
        self.networkController = networkController
    }
    
    func fetchActivities(completion: @escaping (Result<Void, Error>) -> Void) {
        activityService.getSamples(segmentType: .week,
                                   activities: networkController.activityService.activities,
                                   transactions: nil) { (_, foo, bar, stats, err) in
            DispatchQueue.global(qos: .background).async {
                if let activities = stats?[.calendarSummary] {
                    self.items.append(ActivityStackedBarChartViewModel(items: activities, range: self.range))
                }
                DispatchQueue.main.async {
                    completion(.success(()))
                }
            }
        }
        
        let units: Set<Calendar.Component> = [.day, .month, .year]
        var startDate = Calendar.current.dateComponents(units, from: range.0)
        startDate.calendar = .current
        var endDate = Calendar.current.dateComponents(units, from: range.1)
        endDate.calendar = .current
        
        let predicate = HKQuery.predicate(forActivitySummariesBetweenStart: startDate, end: endDate)
        let query = HKActivitySummaryQuery(predicate: predicate) { (_, summary, error) in
            self.items.append(HealthStackedBarChartViewModel(summary: summary ?? [], range: self.range))
        }
        HKHealthStore().execute(query)
    }
}
