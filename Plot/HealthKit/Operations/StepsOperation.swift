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
    var annualAverageSteps: Int?
    
    init(date: Date) {
        self.startDate = date
    }
    
    override func main() {
        startFetchRequest()
    }
    
    private func startFetchRequest() {
        HealthKitService.getCumulativeSumSample(forIdentifier: .stepCount, unit: .count(), date: self.startDate) { [weak self] stepsResult in
            guard let stepsResult = stepsResult, stepsResult > 0, let _self = self else {
                self?.finish()
                return
            }

            let steps = Int(stepsResult)
            var metric = HealthMetric(type: .steps, total: steps, date: _self.startDate)
            metric.average = _self.annualAverageSteps
            
            _self.delegate?.insertMetric(_self, metric)
            self?.finish()
        }
    }
}

protocol MetricOperationDelegate: class {
    func insertMetric(_ operation: AsyncOperation, _ metric: HealthMetric)
}
