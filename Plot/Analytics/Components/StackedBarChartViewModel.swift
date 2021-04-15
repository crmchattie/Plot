//
//  StackedBarChartViewModel.swift
//  Plot
//
//  Created by Botond Magyarosi on 31.03.2021.
//  Copyright © 2021 Immature Creations. All rights reserved.
//

import Foundation
import Charts

struct StackedBarChartViewModel {
    enum ChartType {
        case continous, values
    }
    
    var chartType: ChartType
    
    var rangeDescription: String
    var rangeAverageValue: String
    var categories: [CategorySummaryViewModel]
    var chartData: ChartData?
    var fixToZeroOnVertical: Bool
    var verticalAxisValueFormatter: IAxisValueFormatter?
    var horizontalAxisValueFormatter: IAxisValueFormatter?
    
    init(
        chartType: ChartType,
        rangeDescription: String,
        horizontalAxisValueFormatter: IAxisValueFormatter?,
        verticalAxisValueFormatter: IAxisValueFormatter? = nil,
        fixToZeroOnVertical: Bool = true
    ) {
        self.chartType = chartType
        self.rangeDescription = rangeDescription
        self.rangeAverageValue = "-"
        self.categories = []
        self.chartData = nil
        self.fixToZeroOnVertical = fixToZeroOnVertical
        self.verticalAxisValueFormatter = verticalAxisValueFormatter
        self.horizontalAxisValueFormatter = horizontalAxisValueFormatter
    }
}

struct CategorySummaryViewModel {
    let title: String
    let color: UIColor
    let value: Double
    let formattedValue: String
}
