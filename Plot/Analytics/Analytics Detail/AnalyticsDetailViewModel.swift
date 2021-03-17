//
//  AnalyticsDetailViewModel.swift
//  Plot
//
//  Created by Botond Magyarosi on 16.03.2021.
//  Copyright © 2021 Immature Creations. All rights reserved.
//

import Foundation

class AnalyticsDetailViewModel {
    
    private let networkController: NetworkController
    let chartViewModel: StackedBarChartViewModel
    
    var filter: ActivityFilterOption = .weekly
    var range: (Date, Date) = (Date().startOfWeek, Date().endOfWeek)
    
    var activities: [Activity] = []
    
    init(chartViewModel: StackedBarChartViewModel, networkController: NetworkController) {
        self.chartViewModel = chartViewModel
        self.networkController = networkController
        
        activities = networkController.activityService.activities.filter {
            if let startDate = $0.startDate {
                return startDate >= range.0 && startDate <= range.1
            }
            return false
        }
    }
}
