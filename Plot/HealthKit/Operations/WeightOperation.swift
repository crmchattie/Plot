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
        let unit = HKUnit.pound()
        HealthKitService.getLatestDiscreteDailyAverageSample(forIdentifier: .bodyMass, unit: unit) { [weak self] weight, date in
            
            guard let weight = weight, let date = date, let _self = self else {
                print("finish WeightOperation")
                self?.finish()
                return
            }

            var metric = HealthMetric(type: HealthMetricType.weight, total: weight, date: date,  unitName: "lb", rank: HealthMetricType.weight.rank)
            metric.average = _self.annualAverageWeight
            
            _self.delegate?.insertMetric(_self, metric, HealthMetricCategory.general)
            print("finish WeightOperation")
            self?.finish()
        }
    }
}
