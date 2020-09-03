//
//  HealthKitAnnualAverageStepsOperation.swift
//  Plot
//
//  Created by Hafiz Usama on 2020-09-02.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import Foundation

class HealthKitAnnualAverageStepsOperation: AsyncOperation {
    private var startDate: Date
    var steps: Int?
    
    init(date: Date) {
        self.startDate = date
    }
    
    override func main() {
        startFetchRequest()
    }
    
    private func startFetchRequest() {
        let year = Calendar.current.component(.year, from: startDate)
        let month = Calendar.current.component(.month, from: startDate)
        let day = Calendar.current.component(.day, from: startDate)
        guard let lastYear = Calendar.current.date(from: DateComponents(year: year-1, month: month, day: day)) else {
            self.finish()
            return
        }
        
        HealthKitService.getCumulativeSumSample(forIdentifier: .stepCount, unit: .count(), startDate: lastYear, endDate: startDate) { [weak self] annualSteps in
            guard let annualSteps = annualSteps, let _self = self else {
                self?.finish()
                return
            }
            
            let totalDays = Calendar.current.dateComponents([.day], from: lastYear, to: _self.startDate).day ?? 0
            _self.steps = Int(annualSteps)/totalDays
            self?.finish()
        }
    }
}
