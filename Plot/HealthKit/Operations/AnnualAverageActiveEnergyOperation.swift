//
//  AnnualAverageActiveEnergyOperation.swift
//  Plot
//
//  Created by Cory McHattie on 11/9/22.
//  Copyright © 2022 Immature Creations. All rights reserved.
//

import HealthKit

class AnnualAverageActiveEnergyOperation: AsyncOperation {
    private var startDate: Date
    var calories: Double?
    
    init(date: Date) {
        self.startDate = date
    }
    
    override func main() {
        startFetchRequest()
    }
    
    private func startFetchRequest() {
        HealthKitService.getCumulativeSumSampleAverageAndRecent(forIdentifier: .activeEnergyBurned, unit: .kilocalorie(), startDate: startDate.lastYear, endDate: startDate) { [weak self] annualCalories, _, _ in
            guard let annualCalories = annualCalories, let _self = self else {
                self?.finish()
                return
            }
            
            _self.calories = annualCalories
            self?.finish()
        }
    }
}
