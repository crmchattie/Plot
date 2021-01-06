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
    
    init(date: Date) {
        self.startDate = date
    }
    
    override func main() {
        startFetchRequest()
    }
    
    private func startFetchRequest() {
        HealthKitService.getCumulativeSumSampleAverageAndRecent(forIdentifier: .activeEnergyBurned, unit: .kilocalorie(), date: self.startDate) { [weak self]
            annualAverage, dailyTotal, recentStatDate in
            guard let annualAverage = annualAverage, let dailyTotal = dailyTotal, let recentStatDate = recentStatDate, let _self = self else {
                self?.finish()
                return
            }

            var metric = HealthMetric(type: HealthMetricType.activeEnergy, total: dailyTotal, date: recentStatDate, unitName: "calories", rank: 1)
            metric.average = annualAverage
            metric.unit = .kilocalorie()
            
            _self.delegate?.insertMetric(_self, metric, HealthMetricCategory.workouts.rawValue)
            self?.finish()
            
        }
    }
}
