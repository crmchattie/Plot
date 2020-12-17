//
//  SleepOperation.swift
//  Plot
//
//  Created by Hafiz Usama on 2020-12-09.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import Foundation
import HealthKit

class SleepOperation: AsyncOperation {
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
        HealthKitService.getAllSleepDataSamples(startDate: startDate, endDate: endDate) { [weak self] sleepSamples, error  in
            guard let sleepSamples = sleepSamples, sleepSamples.count > 0, error == nil, let _self = self else {
                self?.finish()
                return
            }
            
            // 12 hours = 43200 seconds
            var midDay = startDate.dayBefore.startOfDay.advanced(by: 43200)
            var interval = NSDateInterval(start: midDay, duration: 86400)
            var map: [Date: Double] = [:]
            var sum: Double = 0
            for sample in sleepSamples {
                while !(interval.contains(sample.endDate)) && interval.endDate < endDate {
                    midDay = midDay.advanced(by: 86400)
                    interval = NSDateInterval(start: midDay, duration: 86400)
                }
                
                let timeSum = sample.endDate.timeIntervalSince(sample.startDate)
                map[midDay, default: 0] += timeSum
                sum += timeSum
            }
            
            let sortedDates = Array(map.sorted(by: { $0.0 < $1.0 }))
            let average = sum / Double(map.count)
            
            if let last = sortedDates.last?.key, let val = map[last] {
                var metric = HealthMetric(type: .sleep, total: val, date: last, unitName: "", rank: HealthMetricType.sleep.rank)
                metric.average = average
                _self.delegate?.insertMetric(_self, metric, HealthMetricCategory.general.rawValue)
            }

            self?.finish()
        }
    }
}
