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
    
    struct Section {
        let title: String
    }
    
    private let activityService = SummaryService()
    private let healthDetailService = HealthDetailService()
    private let healthService = HealthService()
    
    let networkController: NetworkController
    
    private(set) var items: [AnalyticsBreakdownViewModel] = []
    private let range = DateRange(type: .week)
    
    init(networkController: NetworkController) {
        self.networkController = networkController
    }
    
    func loadData(completion: @escaping () -> Void) {
        let group = DispatchGroup()

        let activitiesViewModel = ActivityAnalyticsBreakdownViewModel(range: range, networkController: networkController)
        group.enter()
        activitiesViewModel.loadData {
            group.leave()
        }
        
        group.enter()
        let healthViewModel = HealthAnalyticsBreakdownViewModel(range: range, networkController: networkController)
        healthViewModel.loadData {
            group.leave()
        }
        
        group.enter()
        let financeViewModel = FinancesAnalyticsBreakdownViewModel(range: range, networkController: networkController)
        financeViewModel.loadData {
            group.leave()
        }
        
        group.notify(queue: .main) {
            self.items = [activitiesViewModel, healthViewModel, financeViewModel]
            completion()
        }
    }
}
