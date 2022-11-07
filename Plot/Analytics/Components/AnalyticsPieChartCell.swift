//
//  AnalyticsPieChartCell.swift
//  Plot
//
//  Created by Cory McHattie on 11/7/22.
//  Copyright © 2022 Immature Creations. All rights reserved.
//

import UIKit
import Charts

class AnalyticsPieChartCell: StackedBarChartCell {
    
    private(set) lazy var chartView: PieChartView = {
        let chart = PieChartView()
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
        
        chartView.data = viewModel.chartData
        chartView.notifyDataSetChanged()
    }
}
