//
//  SummaryHorizontalBarChart.swift
//  Plot
//
//  Created by Cory McHattie on 12/16/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import Charts

class SummaryHorizontalBarChartCell: UICollectionViewCell {
    
    var units = String()
        
    var chartView: HorizontalBarChartView = {
        let chartView = HorizontalBarChartView()
        chartView.translatesAutoresizingMaskIntoConstraints = false
        return chartView
    }()
    
    var chartData: BarChartData! {
        didSet {
            if let chartData = chartData {
                let set = chartData.dataSets[0] as! BarChartDataSet
                let values = set.entries.map{ $0.data as! String }
                print("values \(values)")
                
                chartData.barWidth = 0.5
                chartView.data = chartData
                chartView.chartDescription?.enabled = false
                
                chartView.dragEnabled = true
                chartView.setScaleEnabled(true)
                chartView.pinchZoomEnabled = true
                chartView.drawBarShadowEnabled = false
                chartView.drawValueAboveBarEnabled = false
                
                chartView.maxVisibleCount = 60
                
                let xAxis = chartView.xAxis
                xAxis.valueFormatter = IndexAxisValueFormatter(values: values)
                xAxis.labelPosition = .bottom
                xAxis.labelFont = .systemFont(ofSize: 10)
                xAxis.drawAxisLineEnabled = true
                xAxis.drawGridLinesEnabled = false
                xAxis.granularity = 10
                                        
                chartView.rightAxis.enabled = true
                chartView.leftAxis.enabled = false
                
                let rightAxisFormatter = NumberFormatter()
                rightAxisFormatter.numberStyle = .currency
                rightAxisFormatter.maximumFractionDigits = 0
                let rightAxis = chartView.rightAxis
                rightAxis.valueFormatter = DefaultAxisValueFormatter(formatter: rightAxisFormatter)
                rightAxis.labelFont = .systemFont(ofSize: 10)
                rightAxis.drawAxisLineEnabled = true
                rightAxis.drawGridLinesEnabled = false
                
                chartView.legend.enabled = false
                let l = chartView.legend
                l.horizontalAlignment = .center
                l.verticalAlignment = .bottom
                l.orientation = .horizontal
                l.drawInside = false
                l.form = .circle
                l.formSize = 9
                l.font = UIFont(name: "HelveticaNeue-Light", size: 11)!
                l.xEntrySpace = 4
                
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
