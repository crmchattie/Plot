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
    var annualAverageHeartRate: Int?
    
    init(date: Date) {
        self.startDate = date
    }
    
    override func main() {
        startFetchRequest()
    }
    
    private func startFetchRequest() {
        let beatsPerMinuteUnit = HKUnit.count().unitDivided(by: HKUnit.minute())
        HealthKitService.getDiscreteAverageSample(forIdentifier: .heartRate, unit: beatsPerMinuteUnit, date: self.startDate) { [weak self] heartRate in
            
            guard let heartRate = heartRate, let _self = self else {
                self?.finish()
                return
            }

            var metric = HealthMetric(type: .heartRate, total: Int(heartRate), date: _self.startDate)
            metric.average = _self.annualAverageHeartRate
            
            _self.delegate?.insertMetric(_self, metric)
            self?.finish()
        }
    }
}
