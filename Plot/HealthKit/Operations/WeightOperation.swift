//
//  WeightOperation.swift
//  Plot
//
//  Created by Hafiz Usama on 2020-09-23.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import HealthKit

class WeightOperation: AsyncOperation {
    private var startDate: Date
    weak var delegate: MetricOperationDelegate?
    var annualAverageWeight: Double?
    
    init(date: Date) {
        self.startDate = date
    }
    
    override func main() {
        startFetchRequest()
    }
    
    private func startFetchRequest() {
        let beatsPerMinuteUnit = HKUnit.pound()
        HealthKitService.getDiscreteAverageSample(forIdentifier: .bodyMass, unit: beatsPerMinuteUnit, date: self.startDate) { [weak self] weight in
            
            guard let weight = weight, let _self = self else {
                self?.finish()
                return
            }

            var metric = HealthMetric(type: .weight, total: weight, date: _self.startDate, unit: "lb", rank: HealthMetricType.weight.rank)
            metric.average = _self.annualAverageWeight
            
            _self.delegate?.insertMetric(_self, metric)
            self?.finish()
        }
    }
}
