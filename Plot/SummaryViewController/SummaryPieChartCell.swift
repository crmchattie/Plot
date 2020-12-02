//
//  SummaryPieChartCell.swift
//  Plot
//
//  Created by Cory McHattie on 11/30/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import Charts

class SummaryPieChartCell: UICollectionViewCell {
    
    var chartView: PieChartView = {
        let chartView = PieChartView()
        chartView.translatesAutoresizingMaskIntoConstraints = false
        return chartView
    }()

    var pieChartData: PieChartData! {
        didSet {
            if let pieChartData = pieChartData {
                chartView.data = pieChartData
                chartView.highlightValues(nil)
                                
                // entry label styling
                chartView.drawEntryLabelsEnabled = false
                
                chartView.usePercentValuesEnabled = true
                chartView.drawSlicesUnderHoleEnabled = false
                chartView.holeRadiusPercent = 0.58
                chartView.transparentCircleRadiusPercent = 0.61
                chartView.chartDescription?.enabled = false
                chartView.setExtraOffsets(left: 5, top: 10, right: 5, bottom: 5)
                
                chartView.drawHoleEnabled = false
                                        
                chartView.rotationAngle = 0
                chartView.rotationEnabled = true
                chartView.highlightPerTapEnabled = true
                
                let l = chartView.legend
                l.horizontalAlignment = .right
                l.verticalAlignment = .center
                l.orientation = .vertical
                l.drawInside = false
                l.xEntrySpace = 7
                l.yEntrySpace = 0
                l.yOffset = 0
                                
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
