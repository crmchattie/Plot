//
//  SummaryBarChartCell.swift
//  Plot
//
//  Created by Cory McHattie on 12/11/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import Charts

class SummaryValueBarChartCell: UICollectionViewCell {
    
    var units = String()
        
    var chartView: BarChartView = {
        let chartView = BarChartView()
        chartView.translatesAutoresizingMaskIntoConstraints = false
        return chartView
    }()
    
    var chartData: BarChartData! {
        didSet {
            if let chartData = chartData {
                let set = chartData.dataSets[0] as! BarChartDataSet
                let values = set.entries.map{ $0.data as! String }
                
                let barWidth = 0.85
                
                let numberFormatter = NumberFormatter()
                numberFormatter.numberStyle = .currency
                numberFormatter.maximumFractionDigits = 0
                let valuesNumberFormatter = ChartValueFormatter(numberFormatter: numberFormatter)
                chartData.setDrawValues(true)
                chartData.setValueFont(UIFont.footnote.with(weight: .regular))
                chartData.setValueFormatter(valuesNumberFormatter)
                chartData.barWidth = barWidth
                chartView.data = chartData
                chartView.chartDescription.enabled = false
                
                chartView.dragEnabled = true
                chartView.setScaleEnabled(true)
                chartView.pinchZoomEnabled = true
                chartView.drawBarShadowEnabled = false
                chartView.drawValueAboveBarEnabled = true
                
                chartView.maxVisibleCount = 60
                
                let xAxis = chartView.xAxis
                xAxis.valueFormatter = IndexAxisValueFormatter(values: values)
                xAxis.labelPosition = .bottom
                xAxis.labelFont = UIFont.caption2.with(weight: .regular)
                xAxis.drawGridLinesEnabled = false
                                        
                chartView.rightAxis.enabled = true
                chartView.leftAxis.enabled = false
                
                let rightAxisFormatter = NumberFormatter()
                rightAxisFormatter.numberStyle = .currency
                rightAxisFormatter.maximumFractionDigits = 0
                let rightAxis = chartView.rightAxis
                rightAxis.enabled = true
                rightAxis.labelFont = UIFont.caption2.with(weight: .regular)
                rightAxis.labelCount = 8
                rightAxis.valueFormatter = DefaultAxisValueFormatter(formatter: rightAxisFormatter)
                rightAxis.spaceTop = 0.15
                rightAxis.drawGridLinesEnabled = false
                
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
                
//
//                let marker = XYMarkerView(color: .secondaryLabel,
//                                          font: .systemFont(ofSize: 12),
//                                          textColor: .white,
//                                          insets: UIEdgeInsets(top: 8, left: 8, bottom: 20, right: 8),
//                                          xAxisValueFormatter: nil, units: units)
//                marker.chartView = chartView
//                marker.minimumSize = CGSize(width: 80, height: 40)
//                chartView.marker = marker
                
                chartView.notifyDataSetChanged()
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
