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
    
    func fetchChartData(for segmentType: TimeSegmentType, completion: @escaping (BarChartData?) -> ())
    func filterSamples(date: Date?, completion: () -> Void)
}

class HealthDetailViewModel: HealthDetailViewModelInterface {
    let healthMetric: HealthMetric
    let healthDetailService: HealthDetailServiceInterface
    var samples: [HKSample] = []
    var priorSamples: [HKSample] = []
    
    init(healthMetric: HealthMetric, healthDetailService: HealthDetailServiceInterface) {
        self.healthMetric = healthMetric
        self.healthDetailService = healthDetailService
    }
    
    func fetchChartData(for segmentType: TimeSegmentType, completion: @escaping (BarChartData?) -> ()) {
        healthDetailService.getSamples(for: healthMetric, segmentType: segmentType, anchorDate: nil) { [weak self] (stats, samples, error) in

            var data: BarChartData?
            if let stats = stats, stats.count > 0 {
                var i = 0
                var entries: [BarChartDataEntry] = []
                for stat in stats {
                    let entry = BarChartDataEntry(x: Double(i) + 0.5, y: stat.value, data: stat.date)
                    entries.append(entry)
                    i += 1
                }
                
                let dataSet = BarChartDataSet(entries: entries, label: "")
                dataSet.setColor(ChartColors.palette()[5])
                dataSet.drawValuesEnabled = false
                dataSet.axisDependency = .right
                
                data = BarChartData(dataSet: dataSet)
            }
            
            DispatchQueue.main.async {
                self?.samples = samples?.sorted(by: { $0.startDate > $1.startDate }) ?? []
                self?.priorSamples = self?.samples ?? []
                completion(data)
            }
        }
    }
    
    func filterSamples(date: Date?, completion: () -> Void) {
        if let date = date {
            samples = priorSamples
            
            samples = samples.filter { sample -> Bool in
                return date == sample.startDate
            }
            completion()
        } else {
            samples = priorSamples
            completion()
        }
    }
}
