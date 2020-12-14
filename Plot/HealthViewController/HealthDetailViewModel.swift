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
    var samples: [HKSample] { get }
    
    func fetchChartData(for segmentType: TimeSegmentType, completion: @escaping (BarChartData?, Double) -> ())
}

class HealthDetailViewModel: HealthDetailViewModelInterface {
    let healthMetric: HealthMetric
    let healthDetailService: HealthDetailServiceInterface
    var samples: [HKSample] = []
    
    init(healthMetric: HealthMetric, healthDetailService: HealthDetailServiceInterface) {
        self.healthMetric = healthMetric
        self.healthDetailService = healthDetailService
    }
    
    func fetchChartData(for segmentType: TimeSegmentType, completion: @escaping (BarChartData?, Double) -> ()) {
        healthDetailService.getSamples(for: healthMetric, segmentType: segmentType) { [weak self] (stats, samples, error) in

            var data: BarChartData?
            var maxValue: Double = 0
            if let stats = stats, stats.count > 0 {
                var i = 0
                var entries: [BarChartDataEntry] = []
                for stat in stats {
                    maxValue = max(maxValue, stat.value)
                    let entry = BarChartDataEntry(x: Double(i), y: stat.value, data: stat.date)
                    entries.append(entry)
                    i += 1
                }
                
                let dataSet = BarChartDataSet(entries: entries, label: "")
                dataSet.colors = [UIColor.systemBlue]
                dataSet.drawValuesEnabled = false
                
                data = BarChartData(dataSet: dataSet)
                data?.setValueFont(UIFont(name: "HelveticaNeue-Light", size: 10)!)
                maxValue *= 1.3
            }
            
            DispatchQueue.main.async {
                self?.samples = samples ?? []
                completion(data, maxValue)
            }
        }
    }
}
