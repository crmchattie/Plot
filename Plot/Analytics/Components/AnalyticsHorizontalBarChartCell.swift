//
//  AnalyticsHorizontalBarChartCell.swift
//  Plot
//
//  Created by Cory McHattie on 11/7/22.
//  Copyright © 2022 Immature Creations. All rights reserved.
//

import UIKit
import Charts

class AnalyticsHorizontalBarChartCell: StackedBarChartCell {
    
    private(set) lazy var chartView: HorizontalBarChartView = {
        let chart = HorizontalBarChartView()
        chart.defaultChartStyle()
        return chart
    }()
    
    override func initUI() {
        super.initUI()
        chartView.frame = chartContainer.bounds
        chartView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        chartContainer.addSubview(chartView)
    }

    override func updateData() {
        super.updateData()
        
        guard let viewModel = viewModel else {
            chartView.data = nil
            return
        }
        
        if viewModel.fixToZeroOnVertical {
            chartView.leftAxis.axisMinimum = 0
            chartView.rightAxis.axisMinimum = 0
        } else {
            chartView.leftAxis.resetCustomAxisMin()
            chartView.rightAxis.resetCustomAxisMin()
        }
        
        chartView.rightAxis.valueFormatter = viewModel.verticalAxisValueFormatter
        chartView.data = viewModel.chartData
        chartView.notifyDataSetChanged()
    }
}
