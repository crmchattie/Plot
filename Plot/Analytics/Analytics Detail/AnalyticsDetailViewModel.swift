//
//  AnalyticsDetailViewModel.swift
//  Plot
//
//  Created by Botond Magyarosi on 16.03.2021.
//  Copyright © 2021 Immature Creations. All rights reserved.
//

import Foundation

class AnalyticsDetailViewModel {
    let chartViewModel: StackedBarChartViewModel
    
    init(chartViewModel: StackedBarChartViewModel) {
        self.chartViewModel = chartViewModel
    }
}
