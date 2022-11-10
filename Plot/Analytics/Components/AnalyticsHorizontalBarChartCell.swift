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
        
        switch viewModel.verticalAxisType {
        case .fixZeroToMinimumOnVertical:
            chartView.rightAxis.axisMinimum = 0
            chartView.rightAxis.resetCustomAxisMax()
        case .fixZeroToMiddleOnVertical:
            chartView.rightAxis.resetCustomAxisMin()
            print("")
        case .fixZeroToMaximumOnVertical:
            print("")
        }
        
        let dayAxisValueFormatter = DayAxisValueFormatter(chart: chartView)
        dayAxisValueFormatter.formatType = viewModel.formatType.rawValue
        chartView.xAxis.valueFormatter = dayAxisValueFormatter
        chartView.xAxis.labelFont = UIFont.caption1.with(weight: .regular)
        chartView.xAxis.granularity = 1
        chartView.xAxis.labelCount = 5
        chartView.rightAxis.valueFormatter = viewModel.verticalAxisValueFormatter
        let marker = XYMarkerView(color: .systemGroupedBackground,
                                  font: UIFont.body.with(weight: .regular),
                                  textColor: .label,
                                  insets: UIEdgeInsets(top: 8, left: 8, bottom: 20, right: 8),
                                  xAxisValueFormatter: dayAxisValueFormatter, units: viewModel.units)
        marker.chartView = chartView
        marker.minimumSize = CGSize(width: 80, height: 40)
        chartView.marker = marker
        chartView.data = viewModel.chartData
        chartView.extraBottomOffset = 3
        chartView.resetZoom()
        chartView.notifyDataSetChanged()
    }
}
