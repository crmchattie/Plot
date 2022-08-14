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
        let items: [StackedBarChartViewModel]
        fileprivate let dataSources: [AnalyticsDataSource]
    }
    
    private let activityService = SummaryService()
    private let healthDetailService = HealthDetailService()
    private let healthService = HealthService()
    
    let networkController: NetworkController
    
    private(set) var sections: [Section] = []
    private let range = DateRange(type: .week)
    
    init(networkController: NetworkController) {
        self.networkController = networkController
    }
    
    func loadData(completion: @escaping () -> Void) {
        let group = DispatchGroup()

        let activitiesDataSource = ActivityAnalyticsDataSource(range: range, networkController: networkController)
        group.enter()
        activitiesDataSource.loadData {
            group.leave()
        }
        
        group.enter()
        let healthDataSource = HealthAnalyticsDataSource(range: range, networkController: networkController)
        healthDataSource.loadData {
            group.leave()
        }
        
        group.enter()
        let financeDataSource = TransactionAnalyticsDataSource(range: range, networkController: networkController)
        financeDataSource.loadData {
            group.leave()
        }
        
        group.enter()
        let netWorthViewModel = NetWorthAnalyticsDataSource(range: range, networkController: networkController)
        netWorthViewModel.loadData {
            group.leave()
        }
        
        group.notify(queue: .main) {
            self.sections = [
                Section(title: "Calendar", items: [activitiesDataSource.chartViewModel.value], dataSources: [activitiesDataSource]),
                Section(title: "Active Calories", items: [healthDataSource.chartViewModel.value], dataSources: [healthDataSource]),
                Section(title: "Finances", items: [financeDataSource.chartViewModel.value, netWorthViewModel.chartViewModel.value], dataSources: [financeDataSource, netWorthViewModel])
            ]
            completion()
        }
    }
    
    func makeDetailViewModel(for indexPath: IndexPath) -> AnalyticsDetailViewModel {
        let dataSource = sections[indexPath.section].dataSources[indexPath.row / 2]
        return AnalyticsDetailViewModel(dataSource: dataSource, networkController: networkController)
    }
}