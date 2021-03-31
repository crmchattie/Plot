//
//  AnalyticsLineChartCell.swift
//  Plot
//
//  Created by Botond Magyarosi on 31.03.2021.
//  Copyright © 2021 Immature Creations. All rights reserved.
//

import UIKit
import Charts

class AnalyticsLineChartCell: StackedBarChartCell {
    
    private(set) lazy var chartView: LineChartView = {
        let chart = LineChartView()
        
        chart.legend.enabled = false
        chart.pinchZoomEnabled = false
        chart.doubleTapToZoomEnabled = false
        chart.setScaleEnabled(false)
        chart.highlightPerTapEnabled = false
        chart.highlightPerDragEnabled = false
        chart.minOffset = 0
        chart.noDataText = "No data available for the selected period"

        chart.leftAxis.enabled = false
        chart.rightAxis.drawAxisLineEnabled = false
        chart.rightAxis.labelTextColor = .secondaryLabel
        
        chart.xAxis.yOffset = 1

        chart.xAxis.gridColor = .secondaryLabel
        chart.xAxis.gridLineDashLengths = [2, 2]
        chart.xAxis.labelPosition = .bottom
        chart.xAxis.centerAxisLabelsEnabled = true
        chart.xAxis.labelTextColor = .secondaryLabel
        chart.xAxis.valueFormatter = WeekdayAxisValueFormatter()
        
        let marker = XYMarkerView(color: ThemeManager.currentTheme().generalSubtitleColor,
                                  font: .systemFont(ofSize: 12),
                                  textColor: .white,
                                  insets: UIEdgeInsets(top: 8, left: 8, bottom: 20, right: 8),
                                  xAxisValueFormatter: DayAxisValueFormatter(chart: chart), units: "")
        marker.chartView = chart
        marker.minimumSize = CGSize(width: 80, height: 40)
        chart.marker = marker

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
    }
}
