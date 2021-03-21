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
    
    private(set) var items: [AnalyticsBreakdownViewModel] = []
    private let range = ActivityFilterOption.weekly.initialRange
    
    init(networkController: NetworkController) {
        self.networkController = networkController
    }
    
    func fetchActivities(completion: @escaping (Result<Void, Error>) -> Void) {
        activityService.getSamples(segmentType: .week,
                                   activities: networkController.activityService.activities,
                                   transactions: nil) { (_, foo, bar, stats, err) in
            DispatchQueue.global(qos: .background).async {
                if let activities = stats?[.calendarSummary] {
                    self.items.append(ActivityAnalyticsBreakdownViewModel(items: activities, canNavigate: false,
                                                                          range: self.range,
                                                                          networkController: self.networkController))
                }
                DispatchQueue.main.async {
                    completion(.success(()))
                }
            }
        }
        
        
        let type = HKQuantityType.quantityType(forIdentifier: .dietaryEnergyConsumed)!
        let eat = HKSampleQuery(sampleType: type, predicate: nil, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { (_, samples, error) in
            samples?.forEach { sample in
                
            }
        }

        
        let units: Set<Calendar.Component> = [.day, .month, .year]
        var startDate = Calendar.current.dateComponents(units, from: range.0)
        startDate.calendar = .current
        var endDate = Calendar.current.dateComponents(units, from: range.1)
        endDate.calendar = .current
        
        let predicate = HKQuery.predicate(forActivitySummariesBetweenStart: startDate, end: endDate)
        let query = HKActivitySummaryQuery(predicate: predicate) { (_, summary, error) in
            self.items.append(HealthAnalyticsBreakdownViewModel(summary: summary ?? [], filterOption: .weekly, canNavigate: false, networkController: self.networkController))
        }
        let store = HKHealthStore()
        store.execute(query)
        store.execute(eat)
    }
}
