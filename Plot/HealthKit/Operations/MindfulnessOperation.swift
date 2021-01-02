//
//  MindfulnessOperation.swift
//  Plot
//
//  Created by Hafiz Usama on 2020-12-18.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import Foundation
import HealthKit

class MindfulnessOperation: AsyncOperation {
    weak var delegate: MetricOperationDelegate?
    
    private var date: Date
    init(date: Date) {
        self.date = date
    }
    
    override func main() {
        startFetchRequest()
    }
    
    private func startFetchRequest() {
        let endDate = date
        let startDate = endDate.lastYear
        HealthKitService.getAllCategoryTypeSamples(forIdentifier:.mindfulSession, startDate: startDate, endDate: endDate) { [weak self] samples, error  in
            guard let samples = samples, samples.count > 0, error == nil, let _self = self else {
                self?.finish()
                return
            }
            
            var startDay = startDate.dayBefore
            var interval = NSDateInterval(start: startDay, duration: 86400)
            var map: [Date: Double] = [:]
            var sum: Double = 0
            for sample in samples {
                while !(interval.contains(sample.endDate)) && interval.endDate < endDate {
                    startDay = startDay.advanced(by: 86400)
                    interval = NSDateInterval(start: startDay, duration: 86400)
                }
                
                let timeSum = sample.endDate.timeIntervalSince(sample.startDate)
                map[startDay, default: 0] += timeSum
                sum += timeSum
            }
            
            let sortedDates = Array(map.sorted(by: { $0.0 < $1.0 }))
            let average = sum / Double(map.count)
            
            if let last = sortedDates.last?.key, let val = map[last] {
                var metric = HealthMetric(type: .mindfulness, total: val, date: last, unitName: "hrs", rank: HealthMetricType.mindfulness.rank)
                metric.average = average
                _self.delegate?.insertMetric(_self, metric, HealthMetricCategory.general.rawValue)
            }

            self?.finish()
        }
    }
}
