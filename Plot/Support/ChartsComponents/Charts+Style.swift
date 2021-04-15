//
//  Charts+Style.swift
//  Plot
//
//  Created by Botond Magyarosi on 05.04.2021.
//  Copyright © 2021 Immature Creations. All rights reserved.
//

import Charts

extension BarChartView {
    
    func defaultChartStyle() {
        legend.enabled = false
        pinchZoomEnabled = false
        doubleTapToZoomEnabled = false
        setScaleEnabled(false)
        highlightPerTapEnabled = false
        highlightPerDragEnabled = false
        minOffset = 0
        noDataText = "No data available for the selected period"

        leftAxis.enabled = false
        rightAxis.drawAxisLineEnabled = false
        rightAxis.labelTextColor = .secondaryLabel
        rightAxis.spaceTop = 0.15
        
        xAxis.yOffset = 1

        xAxis.gridColor = .secondaryLabel
        xAxis.gridLineDashLengths = [2, 2]
        xAxis.labelPosition = .bottom
        xAxis.centerAxisLabelsEnabled = true
        xAxis.labelTextColor = .secondaryLabel
        xAxis.valueFormatter = WeekdayAxisValueFormatter()
    }
}

extension LineChartView {
    
    func defaultChartStyle() {
        legend.enabled = false
        pinchZoomEnabled = false
        doubleTapToZoomEnabled = false
        setScaleEnabled(false)
        highlightPerTapEnabled = false
        highlightPerDragEnabled = false
        minOffset = 0
        noDataText = "No data available for the selected period"

        leftAxis.enabled = false
        rightAxis.drawAxisLineEnabled = false
        rightAxis.labelTextColor = .secondaryLabel
        
        xAxis.yOffset = 1
        xAxis.gridColor = .secondaryLabel
        xAxis.gridLineDashLengths = [2, 2]
        xAxis.labelPosition = .bottom
        xAxis.centerAxisLabelsEnabled = true
        xAxis.labelTextColor = .secondaryLabel
        xAxis.valueFormatter = WeekdayAxisValueFormatter()
        
        let marker = XYMarkerView(color: ThemeManager.currentTheme().generalSubtitleColor,
                                  font: .systemFont(ofSize: 12),
                                  textColor: .white,
                                  insets: UIEdgeInsets(top: 8, left: 8, bottom: 20, right: 8),
                                  xAxisValueFormatter: DayAxisValueFormatter(chart: self), units: "")
        marker.chartView = self
        marker.minimumSize = CGSize(width: 80, height: 40)
        self.marker = marker
    }
}
