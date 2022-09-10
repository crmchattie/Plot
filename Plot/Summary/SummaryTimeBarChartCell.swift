//
//  SummaryTimeBarChart.swift
//  Plot
//
//  Created by Cory McHattie on 12/17/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import Charts

class SummaryTimeBarChartCell: UICollectionViewCell {
    
    var units = String()
    
    var dayAxisValueFormatter: DayAxisValueFormatter?
    
    var chartView: BarChartView = {
        let chartView = BarChartView()
        chartView.translatesAutoresizingMaskIntoConstraints = false
        return chartView
    }()
    
    var chartData: BarChartData! {
        didSet {
            if let chartData = chartData {
                let barWidth = 0.85
                
                chartData.barWidth = barWidth
                chartView.data = chartData
                chartView.chartDescription?.enabled = false
                
                chartView.dragEnabled = true
                chartView.setScaleEnabled(true)
                chartView.pinchZoomEnabled = true
                chartView.drawBarShadowEnabled = false
                chartView.drawValueAboveBarEnabled = true
                
                chartView.maxVisibleCount = 60
                                
                let xAxis = chartView.xAxis
                dayAxisValueFormatter = DayAxisValueFormatter(chart: chartView)
                xAxis.valueFormatter = dayAxisValueFormatter
                xAxis.labelPosition = .bottom
                xAxis.labelFont = UIFont.caption2.with(weight: .regular)
                xAxis.granularity = 1
                xAxis.labelCount = 5
                xAxis.drawGridLinesEnabled = false
                                        
                chartView.rightAxis.enabled = true
                chartView.leftAxis.enabled = false
                
                let rightAxisFormatter = NumberFormatter()
                rightAxisFormatter.numberStyle = .decimal
                rightAxisFormatter.maximumFractionDigits = 0
                let rightAxis = chartView.rightAxis
                rightAxis.enabled = true
                rightAxis.labelFont = UIFont.caption2.with(weight: .regular)
                rightAxis.labelCount = 8
                rightAxis.valueFormatter = DefaultAxisValueFormatter(formatter: rightAxisFormatter)
                rightAxis.spaceTop = 0.15
                rightAxis.drawGridLinesEnabled = false
                rightAxis.axisMinimum = 0
                
                chartView.legend.enabled = false
                let l = chartView.legend
                l.horizontalAlignment = .center
                l.verticalAlignment = .bottom
                l.orientation = .horizontal
                l.drawInside = false
                l.form = .circle
                l.formSize = 9
                l.font = UIFont.caption2.with(weight: .regular)
                l.xEntrySpace = 4

                let marker = XYMarkerView(color: ThemeManager.currentTheme().generalSubtitleColor,
                                          font: .systemFont(ofSize: 12),
                                          textColor: .white,
                                          insets: UIEdgeInsets(top: 8, left: 8, bottom: 20, right: 8),
                                          xAxisValueFormatter: dayAxisValueFormatter!, units: units)
                
                marker.chartView = chartView
                marker.minimumSize = CGSize(width: 80, height: 40)
                chartView.marker = marker
                
                setupViews()
            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupViews() {
        addSubview(chartView)
        chartView.fillSuperview()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
    }
    
}
