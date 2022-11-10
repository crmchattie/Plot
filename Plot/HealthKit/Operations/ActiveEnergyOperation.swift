//
//  ActiveEnergyOperation.swift
//  Plot
//
//  Created by Cory McHattie on 1/5/21.
//  Copyright © 2021 Immature Creations. All rights reserved.
//

import Foundation
import HealthKit

class ActiveEnergyOperation: AsyncOperation {
    private var startDate: Date
    weak var delegate: MetricOperationDelegate?
    var annualAverageCalories: Double?
    
    init(date: Date) {
        self.startDate = date
    }
    
    override func main() {
        startFetchRequest()
    }
    
    private func startFetchRequest() {
        HealthKitService.getCumulativeSumSampleAverageAndRecent(forIdentifier: .activeEnergyBurned, unit: .kilocalorie(), date: self.startDate) { [weak self] caloriesResult, _, _ in
            guard let caloriesResult = caloriesResult, caloriesResult > 0, let _self = self else {
                self?.finish()
                return
            }

            var metric = HealthMetric(type: HealthMetricType.activeEnergy, total: caloriesResult, date: _self.startDate, unitName: "calories", rank: 0)
            metric.average = _self.annualAverageCalories
            metric.unit = .kilocalorie()
            
            _self.delegate?.insertMetric(_self, metric, HealthMetricCategory.workouts)
            self?.finish()
            
        }
    }
}
