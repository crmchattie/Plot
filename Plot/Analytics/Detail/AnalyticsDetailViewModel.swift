//
//  AnalyticsDetailViewModel.swift
//  Plot
//
//  Created by Botond Magyarosi on 16.03.2021.
//  Copyright © 2021 Immature Creations. All rights reserved.
//

import Foundation
import Combine
import SwiftUI

class AnalyticsDetailViewModel {
    
    private let networkController: NetworkController
    private(set) var chartViewModel: StackedBarChartViewModel
    
    var filter: ActivityFilterOption = .weekly {
        didSet { updateRange() }
    }
    var range: (Date, Date) = (Date().startOfWeek, Date().endOfWeek)
    
    @Published var activities: [Activity] = []
    
    init(chartViewModel: StackedBarChartViewModel, networkController: NetworkController) {
        self.chartViewModel = chartViewModel
        self.networkController = networkController
        
        updateRange()
    }
    
    private func updateRange() {
        switch filter {
        case .weekly:
            range = (Date().startOfWeek, Date().endOfWeek)
        case .monthly:
            range = (Date().startOfMonth, Date().endOfMonth)
        case .yearly:
            range = (Date().startOfYear, Date().endOfYear)
        }
        
        activities = networkController.activityService.activities.filter {
            if let startDate = $0.startDate {
                return startDate >= range.0 && startDate <= range.1
            }
            return false
        }
    }
}
