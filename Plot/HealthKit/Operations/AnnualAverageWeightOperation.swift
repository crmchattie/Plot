//
//  AnnualAverageWeightOperation.swift
//  Plot
//
//  Created by Hafiz Usama on 2020-09-23.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import HealthKit

class AnnualAverageWeightOperation: AsyncOperation {
    private var date: Date
    var weight: Double?
    
    init(date: Date) {
        self.date = date
    }
    
    override func main() {
        startFetchRequest()
    }
    
    private func startFetchRequest() {
        let year = Calendar.current.component(.year, from: date)
        let month = Calendar.current.component(.month, from: date)
        let day = Calendar.current.component(.day, from: date)
        guard let lastYear = Calendar.current.date(from: DateComponents(year: year-1, month: month, day: day)) else {
            self.finish()
            return
        }
        
        let beatsPerMinuteUnit = HKUnit.pound()
        HealthKitService.getDiscreteAverageSample(forIdentifier: .bodyMass, unit: beatsPerMinuteUnit, startDate: lastYear, endDate: date) { [weak self] weight in
            guard let weight = weight, let _self = self else {
                self?.finish()
                return
            }
            
            _self.weight = weight
            self?.finish()
        }
    }
}
