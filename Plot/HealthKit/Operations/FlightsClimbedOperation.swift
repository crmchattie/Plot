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
    private var date: Date
    weak var delegate: MetricOperationDelegate?
    
    init(date: Date) {
        self.date = date
    }
    
    override func main() {
        startFetchRequest()
    }
    
    private func startFetchRequest() {
        let endDate = date
        let startDate = endDate.lastYear
        HealthKitService.getCumulativeSumSampleAverageAndRecent(forIdentifier: .flightsClimbed, unit: .count(), startDate: startDate, endDate: endDate) { [weak self] annualAverage, dailyTotal, recentStatDate in
            guard let annualAverage = annualAverage, let dailyTotal = dailyTotal, let recentStatDate = recentStatDate, let _self = self else {
                self?.finish()
                return
            }
            
            var metric = HealthMetric(type: HealthMetricType.flightsClimbed, total: dailyTotal, date: recentStatDate, unitName: "floors", rank: HealthMetricType.flightsClimbed.rank)
            metric.average = annualAverage
            _self.delegate?.insertMetric(_self, metric, HealthMetricCategory.general)
            self?.finish()

        }
    }
}
