//
//  NutritionOperation.swift
//  Plot
//
//  Created by Hafiz Usama on 2020-11-09.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import Foundation
import HealthKit

class NutritionOperation: AsyncOperation {
    weak var delegate: MetricOperationDelegate?
    
    private var date: Date
    private var nutritionTypeIdentifier: HKQuantityTypeIdentifier
    private var unit: HKUnit
    private var unitTitle: String
    private var rank: Int
    init(date: Date, nutritionTypeIdentifier: HKQuantityTypeIdentifier, unit: HKUnit, unitTitle: String, rank: Int) {
        self.date = date
        self.nutritionTypeIdentifier = nutritionTypeIdentifier
        self.unit = unit
        self.unitTitle = unitTitle
        self.rank = rank
    }
    
    override func main() {
        startFetchRequest()
    }
    
    private func startFetchRequest() {
        let endDate = date.dayAfter
        let startDate = endDate.lastYear
        HealthKitService.getCumulativeSumSampleAverageAndRecent(forIdentifier: nutritionTypeIdentifier, unit: unit, startDate: startDate, endDate: endDate) { [weak self] annualAverage, dailyTotal, recentStatDate in
            guard let annualAverage = annualAverage, let dailyTotal = dailyTotal, let recentStatDate = recentStatDate, let _self = self else {
                self?.finish()
                return
            }

            let type = HealthMetricType.nutrition(_self.nutritionTypeIdentifier.name)
            var metric = HealthMetric(type: type, total: dailyTotal, date: recentStatDate, unitName: _self.unitTitle, rank: _self.rank)
            metric.unit = _self.unit
            metric.quantityTypeIdentifier = _self.nutritionTypeIdentifier
            metric.average = annualAverage
            
            _self.delegate?.insertMetric(_self, metric, HealthMetricCategory.nutrition)
            self?.finish()
        }
    }
}
