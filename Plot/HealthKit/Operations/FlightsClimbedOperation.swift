//
//  FlightsClimbedOperation.swift
//  Plot
//
//  Created by Cory McHattie on 8/24/22.
//  Copyright © 2022 Immature Creations. All rights reserved.
//

import Foundation
import HealthKit

class FlightsClimbedOperation: AsyncOperation {
    private var startDate: Date
    weak var delegate: MetricOperationDelegate?
    var annualAverageFloors: Double?
    
    init(date: Date) {
        self.startDate = date
    }
    
    override func main() {
        startFetchRequest()
    }
    
    private func startFetchRequest() {
        HealthKitService.getCumulativeSumSampleAverageAndRecent(forIdentifier: .flightsClimbed, unit: .count(), date: self.startDate) { [weak self]  floorsResult, _, _ in
            guard let floorsResult = floorsResult, floorsResult > 0, let _self = self else {
                self?.finish()
                return
            }
            
            var metric = HealthMetric(type: HealthMetricType.flightsClimbed, total: floorsResult, date: _self.startDate, unitName: "floors", rank: HealthMetricType.flightsClimbed.rank)
            metric.average = _self.annualAverageFloors
            _self.delegate?.insertMetric(_self, metric, HealthMetricCategory.general)
            self?.finish()

        }
    }
}
