//
//  SummaryBarChartCell.swift
//  Plot
//
//  Created by Cory McHattie on 12/11/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import Charts

class SummaryBarChartCell: UICollectionViewCell {
    
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
                chartView.pinchZoomEnabled = false
                
                let xAxis = chartView.xAxis
                xAxis.labelPosition = .bottom
                
                chartView.rightAxis.enabled = false
                
                chartView.drawBarShadowEnabled = false
                chartView.drawValueAboveBarEnabled = false
                
                chartView.maxVisibleCount = 60
                
                xAxis.labelPosition = .bottom
                xAxis.labelFont = .systemFont(ofSize: 10)
                xAxis.granularity = 1
                xAxis.labelCount = 5
                
                dayAxisValueFormatter = DayAxisValueFormatter(chart: chartView)
                
                xAxis.valueFormatter = dayAxisValueFormatter
                
                let leftAxisFormatter = NumberFormatter()
                leftAxisFormatter.minimumFractionDigits = 0
                leftAxisFormatter.maximumFractionDigits = 1
                leftAxisFormatter.negativeSuffix = ""
                leftAxisFormatter.positiveSuffix = ""
                
                let leftAxis = chartView.leftAxis
                leftAxis.labelFont = .systemFont(ofSize: 10)
                leftAxis.labelCount = 8
                leftAxis.valueFormatter = DefaultAxisValueFormatter(formatter: leftAxisFormatter)
                leftAxis.labelPosition = .outsideChart
                leftAxis.spaceTop = 0.15
                leftAxis.axisMinimum = 0 // FIXME: HUH?? this replaces startAtZero = YES
                
                let rightAxis = chartView.rightAxis
                rightAxis.enabled = true
                rightAxis.labelFont = .systemFont(ofSize: 10)
                rightAxis.labelCount = 8
                rightAxis.valueFormatter = leftAxis.valueFormatter
                rightAxis.spaceTop = 0.15
                rightAxis.axisMinimum = 0
                
                let l = chartView.legend
                l.horizontalAlignment = .left
                l.verticalAlignment = .bottom
                l.orientation = .horizontal
                l.drawInside = false
                l.form = .circle
                l.formSize = 9
                l.font = UIFont(name: "HelveticaNeue-Light", size: 11)!
                l.xEntrySpace = 4
                
                let marker = XYMarkerView(color: UIColor(white: 180/250, alpha: 1),
                                          font: .systemFont(ofSize: 12),
                                          textColor: .white,
                                          insets: UIEdgeInsets(top: 8, left: 8, bottom: 20, right: 8),
                                          xAxisValueFormatter: chartView.xAxis.valueFormatter!)
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
