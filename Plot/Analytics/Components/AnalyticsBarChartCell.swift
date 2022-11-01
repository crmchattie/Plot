//
//  AnalyticsBarChartCell.swift
//  Plot
//
//  Created by Botond Magyarosi on 31.03.2021.
//  Copyright © 2021 Immature Creations. All rights reserved.
//

import UIKit
import Charts

class AnalyticsBarChartCell: StackedBarChartCell {
    
    private(set) lazy var chartView: BarChartView = {
        let chart = BarChartView()
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
        
        chartView.xAxis.valueFormatter = viewModel.horizontalAxisValueFormatter
        chartView.rightAxis.valueFormatter = viewModel.verticalAxisValueFormatter
        chartView.data = viewModel.chartData
        chartView.notifyDataSetChanged()
    }
}
