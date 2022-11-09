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
        
        switch viewModel.verticalAxisType {
        case .fixZeroToMinimumOnVertical:
            chartView.rightAxis.axisMinimum = 0
            chartView.rightAxis.resetCustomAxisMax()
        case .fixZeroToMiddleOnVertical:
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
        chartView.resetZoom()
        chartView.notifyDataSetChanged()
    }
}
