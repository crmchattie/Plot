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
    private(set) var chartViewModel: AnalyticsBreakdownViewModel
    
    var filter: ActivityFilterOption = .weekly {
        didSet { updateRange() }
    }
    var range: (Date, Date) = (Date().startOfWeek, Date().endOfWeek)
    
    @Published private(set) var entries: [AnalyticsBreakdownEntry] = []
    
    init(chartViewModel: AnalyticsBreakdownViewModel, networkController: NetworkController) {
        self.chartViewModel = chartViewModel
        self.networkController = networkController
        updateRange()
    }
    
    private func updateRange() {
        range = filter.initialRange
        
        chartViewModel.fetchEntries(range: range) { entries in
            self.entries = entries
        }
    }
}
