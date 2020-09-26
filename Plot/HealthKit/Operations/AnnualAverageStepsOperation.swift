//
//  AnnualAverageStepsOperation.swift
//  Plot
//
//  Created by Hafiz Usama on 2020-09-02.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import Foundation

class AnnualAverageStepsOperation: AsyncOperation {
    private var startDate: Date
    var steps: Double?
    
    init(date: Date) {
        self.startDate = date
    }
    
    override func main() {
        startFetchRequest()
    }
    
    private func startFetchRequest() {
        HealthKitService.getCumulativeSumSample(forIdentifier: .stepCount, unit: .count(), startDate: startDate.lastYear, endDate: startDate) { [weak self] annualSteps in
            guard let annualSteps = annualSteps, let _self = self else {
                self?.finish()
                return
            }
            
            let totalDays = Calendar.current.dateComponents([.day], from: _self.startDate.lastYear, to: _self.startDate).day ?? 0
            _self.steps = annualSteps/Double(totalDays)
            self?.finish()
        }
    }
}
