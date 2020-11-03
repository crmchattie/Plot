//
//  HealthDetailViewModel.swift
//  Plot
//
//  Created by Hafiz Usama on 2020-10-28.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import Foundation
import Charts
import HealthKit

protocol HealthDetailViewModelInterface {
    var healthMetric: HealthMetric { get }
    
    func fetchChartData(for segmentType: TimeSegmentType, completion: @escaping (LineChartData?, Double) -> ())
}

class HealthDetailViewModel: HealthDetailViewModelInterface {
    let healthMetric: HealthMetric
    let healthDetailService: HealthDetailServiceInterface
    
    init(healthMetric: HealthMetric, healthDetailService: HealthDetailServiceInterface) {
        self.healthMetric = healthMetric
        self.healthDetailService = healthDetailService
    }
    
    func fetchChartData(for segmentType: TimeSegmentType, completion: @escaping (LineChartData?, Double) -> ()) {
        healthDetailService.getSamples(for: healthMetric.type, segmentType: segmentType) { (stats, error) in
            guard let stats = stats, stats.count > 0 else {
                completion(nil, 0)
                return
            }
            
            var i = 0
            var entries: [ChartDataEntry] = []
            var maxValue: Double = 0
            for stat in stats {
                maxValue = max(maxValue, stat.value)
                let entry = ChartDataEntry(x: Double(i), y: stat.value, data: stat.date)
                entries.append(entry)
                i += 1
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
            maxValue *= 1.3
            DispatchQueue.main.async {
                completion(data, maxValue)
            }
        }
    }
}
