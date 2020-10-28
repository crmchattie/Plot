//
//  HealthDetailViewController.swift
//  Plot
//
//  Created by Hafiz Usama on 2020-10-05.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import UIKit
import Charts
import HealthKit

class HealthDetailViewController: UIViewController {
    
    var healthMetric: HealthMetric?
    var dayAxisValueFormatter: DayAxisValueFormatter?
    
    lazy var chartView: LineChartView = {
        let chartView = LineChartView()
        chartView.translatesAutoresizingMaskIntoConstraints = false
        return chartView
    }()
    
    lazy var segmentedControl: UISegmentedControl = {
        let segmentedControl = UISegmentedControl(items: ["D", "W", "M", "Y"])
        segmentedControl.addTarget(self, action: #selector(changeSegment(_:)), for: .valueChanged)
        segmentedControl.translatesAutoresizingMaskIntoConstraints = false
        return segmentedControl
    }()
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    fileprivate func addObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(changeTheme), name: .themeUpdated, object: nil)
    }
    
    @objc fileprivate func changeTheme() {
        let theme = ThemeManager.currentTheme()
        view.backgroundColor = theme.generalBackgroundColor
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        addObservers()
        changeTheme()
        
        view.addSubview(chartView)
        chartView.delegate = self
        
        view.addSubview(segmentedControl)
        segmentedControl.selectedSegmentIndex = 0
        
        configureView()
        configureChart()
        
        //updateChartData()
        fetchHealthKitData()
    }
    
    private func configureView() {
        NSLayoutConstraint.activate([
            segmentedControl.topAnchor.constraint(equalTo: view.topAnchor, constant: 10),
            segmentedControl.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 16),
            segmentedControl.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -16),
            
            chartView.topAnchor.constraint(equalTo: segmentedControl.bottomAnchor, constant: 10),
            chartView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 16),
            chartView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -16),
            chartView.heightAnchor.constraint(equalToConstant: 260)
        ])
    }
    
    func configureChart() {
        
        chartView.chartDescription?.enabled = false
        chartView.dragEnabled = true
        chartView.setScaleEnabled(true)
        chartView.pinchZoomEnabled = true
        
        let xAxis = chartView.xAxis
        xAxis.labelPosition = .bottom
        xAxis.labelPosition = .bottom
        xAxis.labelFont = .systemFont(ofSize: 10)
        xAxis.granularity = 1
        xAxis.labelCount = 5
        dayAxisValueFormatter = DayAxisValueFormatter(chart: chartView)
        dayAxisValueFormatter?.formatType = segmentedControl.selectedSegmentIndex
        xAxis.valueFormatter = dayAxisValueFormatter

        let rightAxis = chartView.rightAxis
        rightAxis.removeAllLimitLines()
        rightAxis.axisMinimum = 0
        rightAxis.drawLimitLinesBehindDataEnabled = true
        
        chartView.leftAxis.enabled = false

        let marker = BalloonMarker(color: UIColor(white: 180/255, alpha: 1),
                                   font: .systemFont(ofSize: 12),
                                   textColor: .white,
                                   insets: UIEdgeInsets(top: 8, left: 8, bottom: 20, right: 8))
        marker.chartView = chartView
        marker.minimumSize = CGSize(width: 80, height: 40)
        chartView.marker = marker
        
        chartView.legend.form = .line
        
        chartView.animate(xAxisDuration: 2.5)
    }
    
    @objc func changeSegment(_ segmentedControl: UISegmentedControl) {
        switch (segmentedControl.selectedSegmentIndex) {
        case 0:
        break // Uno
        case 1:
        break // Dos
        case 2:
        break // Tres
        case 3:
            // not implemented
            return
        default:
            break
        }
        
        fetchHealthKitData()
    }
    
    // MARK: HealthKit Data
    func fetchHealthKitData() {
        guard let healthMetric = healthMetric else {
            return
        }
        
        let endDate = Date()
        let calendar = Calendar.current
        var startDate = calendar.startOfDay(for: endDate)
        switch (segmentedControl.selectedSegmentIndex) {
        case 0:
            break
        case 1:
            startDate = endDate.weekBefore
        case 2:
            startDate = endDate.monthBefore
        case 3:
            startDate = endDate.lastYear
        default:
            break
        }
        
        if healthMetric.type == .steps {
            guard let stepCountSampleType = HKSampleType.quantityType(forIdentifier: .stepCount) else {
                return
            }
            
//            let count = 45
//            let range: UInt32 = 100
//            let values = (0..<count).map { (i) -> ChartDataEntry in
//                let val = Double(arc4random_uniform(range) + 3)
//                return ChartDataEntry(x: Double(i), y: val)
//            }
            
            HealthKitService.getAllTheSamples(for: stepCountSampleType, startDate: startDate, endDate: endDate) { (samples, error) in
                if let samples = samples {
                    var i = 0
                    var entries: [ChartDataEntry] = []
                    var maxValue: Double = 0
                    for sample in samples {
                        if let quantitySample = sample as? HKQuantitySample {
                            let steps = quantitySample.quantity.doubleValue(for: .count())
                            maxValue = max(maxValue, steps)
                            let entry = ChartDataEntry(x: Double(i), y: steps, data: quantitySample.endDate)
                            entries.append(entry)
                            i += 1
                        }
                    }
                    
                    let dataSet = LineChartDataSet(entries: entries, label: "")
                    dataSet.drawIconsEnabled = false
                    dataSet.mode = .cubicBezier
                    dataSet.setColor(.black)
                    dataSet.setCircleColor(.black)
                    dataSet.drawCirclesEnabled = false
                    dataSet.drawValuesEnabled = false
                    dataSet.circleRadius = 3
                    dataSet.drawCircleHoleEnabled = false
                    dataSet.valueFont = .systemFont(ofSize: 9)
                    dataSet.formSize = 15
                    dataSet.lineWidth = 0
                    
                    let gradientColors = [ChartColorTemplates.colorFromString("#00ff0000").cgColor,
                                          ChartColorTemplates.colorFromString("#ffff0000").cgColor]
                    let gradient = CGGradient(colorsSpace: nil, colors: gradientColors as CFArray, locations: nil)!
                    
                    dataSet.fillAlpha = 1
                    dataSet.fill = Fill(linearGradient: gradient, angle: 90)
                    dataSet.drawFilledEnabled = true
                    
                    let data = LineChartData(dataSet: dataSet)
                    data.setValueFont(UIFont(name: "HelveticaNeue-Light", size: 10)!)
                    maxValue *= 1.2
                    DispatchQueue.main.async {
                        self.dayAxisValueFormatter?.formatType = self.segmentedControl.selectedSegmentIndex
                        self.chartView.rightAxis.axisMaximum = maxValue
                        self.chartView.data = data
                    }
                }
            }
        }
    }
}

extension HealthDetailViewController: ChartViewDelegate {
    func chartValueSelected(_ chartView: ChartViewBase, entry: ChartDataEntry, highlight: Highlight) {
        
    }
    
    func chartValueNothingSelected(_ chartView: ChartViewBase) {
        
    }
    
    func chartScaled(_ chartView: ChartViewBase, scaleX: CGFloat, scaleY: CGFloat) {
        
    }
    
    func chartTranslated(_ chartView: ChartViewBase, dX: CGFloat, dY: CGFloat) {
        
    }
}
