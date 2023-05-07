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
        let beatsPerMinuteUnit = HKUnit.pound()
        var interval = DateComponents()
        interval.year = 1
        HealthKitService.getDiscreteAverageSample(forIdentifier: .bodyMass, unit: beatsPerMinuteUnit, startDate: date.lastYear, endDate: date, interval: interval) { [weak self] weight, date in
            guard let weight = weight, let _self = self else {
                print("finish AnnualAverageWeightOperation")
                self?.finish()
                return
            }
            
            _self.weight = weight
            print("finish AnnualAverageWeightOperation")
            self?.finish()
        }
    }
}
