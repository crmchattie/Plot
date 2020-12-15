//
//  SummaryBarChartCell.swift
//  Plot
//
//  Created by Cory McHattie on 12/11/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import Charts

class SummaryBarChartCell: UICollectionViewCell {
    
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
                chartView.data = chartData
                chartView.chartDescription?.enabled = false
                
                chartView.dragEnabled = true
                chartView.setScaleEnabled(true)
                chartView.pinchZoomEnabled = true
                
                let xAxis = chartView.xAxis
                xAxis.labelPosition = .bottom
                
                chartView.drawBarShadowEnabled = false
                chartView.drawValueAboveBarEnabled = false
                
                chartView.maxVisibleCount = 60
                
                dayAxisValueFormatter = DayAxisValueFormatter(chart: chartView)
                xAxis.valueFormatter = dayAxisValueFormatter
                xAxis.labelPosition = .bottom
                xAxis.labelFont = .systemFont(ofSize: 10)
                xAxis.granularity = 1
                xAxis.labelCount = 5
                xAxis.drawGridLinesEnabled = false
                                        
                chartView.rightAxis.enabled = true
                chartView.leftAxis.enabled = false
                
                let rightAxisFormatter = NumberFormatter()
                rightAxisFormatter.numberStyle = .currency
                rightAxisFormatter.maximumFractionDigits = 0
                let rightAxis = chartView.rightAxis
                rightAxis.enabled = true
                rightAxis.labelFont = .systemFont(ofSize: 10)
                rightAxis.labelCount = 8
                rightAxis.valueFormatter = DefaultAxisValueFormatter(formatter: rightAxisFormatter)
                rightAxis.spaceTop = 0.15
                rightAxis.drawGridLinesEnabled = false
                
                chartView.legend.enabled = false
                let l = chartView.legend
                l.horizontalAlignment = .left
                l.verticalAlignment = .bottom
                l.orientation = .horizontal
                l.drawInside = false
                l.form = .circle
                l.formSize = 9
                l.font = UIFont(name: "HelveticaNeue-Light", size: 11)!
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
