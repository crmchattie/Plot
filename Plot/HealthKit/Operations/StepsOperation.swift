//
//  StepsOperation.swift
//  Plot
//
//  Created by Hafiz Usama on 2020-09-01.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import Foundation
import HealthKit

class StepsOperation: AsyncOperation {
    private var startDate: Date
    weak var delegate: MetricOperationDelegate?
    var annualAverageSteps: Double?
    
    init(date: Date) {
        self.startDate = date
    }
    
    override func main() {
        startFetchRequest()
    }
    
    private func startFetchRequest() {
        HealthKitService.getCumulativeSumSampleAverageAndRecent(forIdentifier: .stepCount, unit: .count(), date: self.startDate) { [weak self] stepsResult, _ in
            guard let stepsResult = stepsResult, stepsResult > 0, let _self = self else {
                self?.finish()
                return
            }

            let steps = stepsResult
            var metric = HealthMetric(type: HealthMetricType.steps, total: steps, date: _self.startDate, unit: "steps", rank: HealthMetricType.steps.rank)
            metric.average = _self.annualAverageSteps
            
            _self.delegate?.insertMetric(_self, metric)
            self?.finish()
        }
    }
}
