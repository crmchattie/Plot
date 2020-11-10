//
//  NutritionOperation.swift
//  Plot
//
//  Created by Hafiz Usama on 2020-11-09.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import Foundation

class NutritionOperation: AsyncOperation {
    weak var delegate: MetricOperationDelegate?
    
    override init() {
    }
    
    override func main() {
        startFetchRequest()
    }
    
    private func startFetchRequest() {
        let startDate = Date()
        HealthKitService.getCumulativeSumSample(forIdentifier: .dietaryFatTotal, unit: .gram(), date: startDate) { [weak self] stepsResult in
            guard let stepsResult = stepsResult, stepsResult > 0, let _self = self else {
                self?.finish()
                return
            }

            let steps = stepsResult
            var metric = HealthMetric(type: HealthMetricType.nutrition, total: steps, date: startDate, unit: "Fat", rank: HealthMetricType.steps.rank)
            metric.average = 0
            
            _self.delegate?.insertMetric(_self, metric)
            self?.finish()
        }
    }
}
