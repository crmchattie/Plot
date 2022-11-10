//
//  HeartRateOperation.swift
//  Plot
//
//  Created by Hafiz Usama on 2020-09-16.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import HealthKit

class HeartRateOperation: AsyncOperation {
    private var startDate: Date
    weak var delegate: MetricOperationDelegate?
    var annualAverageHeartRate: Double?
    
    init(date: Date) {
        self.startDate = date
    }
    
    override func main() {
        startFetchRequest()
    }
    
    private func startFetchRequest() {
        guard let _ = HKObjectType.quantityType(forIdentifier: .heartRate) else {
            self.finish()
            return
        }
        
            
        let beatsPerMinuteUnit = HKUnit.count().unitDivided(by: HKUnit.minute())
        // Get average day heart rate for the most recent heart rate sample endDate
        HealthKitService.getLatestDiscreteDailyAverageSample(forIdentifier: .heartRate, unit: beatsPerMinuteUnit) { [weak self] heartRate, date in
            guard let heartRate = heartRate, heartRate > 0, let date = date, let _self = self else {
                self?.finish()
                return
            }

            var metric = HealthMetric(type: HealthMetricType.heartRate, total: heartRate, date: date, unitName: "bpm", rank: HealthMetricType.heartRate.rank)
            metric.average = _self.annualAverageHeartRate
            
            _self.delegate?.insertMetric(_self, metric, HealthMetricCategory.general)
            self?.finish()
        }
    }
}
