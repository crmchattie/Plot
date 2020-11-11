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
    init(date: Date, nutritionTypeIdentifier: HKQuantityTypeIdentifier) {
        self.date = date
        self.nutritionTypeIdentifier = nutritionTypeIdentifier
    }
    
    override func main() {
        startFetchRequest()
    }
    
    private func startFetchRequest() {
        let endDate = date
        let startDate = endDate.lastYear
        HealthKitService.getCumulativeSumSampleAverageAndRecent(forIdentifier: nutritionTypeIdentifier, unit: .gram(), startDate: startDate, endDate: endDate) { [weak self] annualAverage, dailyTotal in
            guard let annualAverage = annualAverage, let dailyTotal = dailyTotal, let _self = self else {
                self?.finish()
                return
            }

            var metric = HealthMetric(type: HealthMetricType.nutrition, total: dailyTotal, date: endDate, unit: "grams", rank: HealthMetricType.nutrition.rank)
            metric.average = annualAverage
            
            _self.delegate?.insertMetric(_self, metric)
            self?.finish()
        }
    }
}
