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
import Combine

class AnalyticsViewModel {
    
    private let activityService = SummaryService()
    private let healthDetailService = HealthDetailService()
    private let healthService = HealthService()
    
    let networkController: NetworkController
    
    private(set) var items: [AnalyticsBreakdownViewModel] = []
    private let range = DateRange(type: .week)
    
    init(networkController: NetworkController) {
        self.networkController = networkController
    }
    
    func fetchActivities(completion: @escaping () -> Void) {
        let group = DispatchGroup()

        let activitiesViewModel = ActivityAnalyticsBreakdownViewModel(canNavigate: false, range: range, networkController: networkController)
        group.enter()
        activitiesViewModel.loadData {
            group.leave()
        }
        
        group.enter()
        let healthViewModel = HealthAnalyticsBreakdownViewModel(range: range, canNavigate: false, networkController: networkController)
        healthViewModel.loadData {
            group.leave()
        }
//
//        fetchHealth { (energyResult, activityResult) in
//            self.items.append(HealthAnalyticsBreakdownViewModel(activity: activityResult,
//                                                                energyConsumed: energyResult,
//                                                                range: self.range,
//                                                                canNavigate: false,
//                                                                networkController: self.networkController))
//
//        }
        
        group.notify(queue: .main) {
            self.items = [activitiesViewModel, healthViewModel]
            completion()
        }
    }
    
    private func fetchHealth(completion: @escaping (_ eneryResult: [HKQuantitySample], _ activityResult: [HKActivitySummary]) -> Void) {
        let healthStore = HKHealthStore()
        let predicate: NSPredicate = {
            let units: Set<Calendar.Component> = [.day, .month, .year]
            var startDate = Calendar.current.dateComponents(units, from: range.startDate)
            startDate.calendar = .current
            var endDate = Calendar.current.dateComponents(units, from: range.endDate)
            endDate.calendar = .current
            return HKQuery.predicate(forActivitySummariesBetweenStart: startDate, end: endDate)
        }()
        
        let group = DispatchGroup()
        var eneryResult: [HKQuantitySample] = []
        var activityResult: [HKActivitySummary] = []
        
        let type = HKQuantityType.quantityType(forIdentifier: .dietaryEnergyConsumed)!
        let caloriesConsumedQuery = HKSampleQuery(sampleType: type, predicate: nil, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { (_, samples, error) in
            eneryResult = samples?.compactMap { $0 as? HKQuantitySample } ?? []
            group.leave()
        }
        
        let activityQuery = HKActivitySummaryQuery(predicate: predicate) { (_, summary, error) in
            activityResult = summary ?? []
            group.leave()
        }
        
        group.enter()
        healthStore.execute(activityQuery)
        group.enter()
        healthStore.execute(caloriesConsumedQuery)
        
        group.notify(queue: .main) {
            completion(eneryResult, activityResult)
        }
    }
}
