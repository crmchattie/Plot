//
//  AnnualAverageHeartRateOperation.swift
//  Plot
//
//  Created by Hafiz Usama on 2020-09-16.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import HealthKit

class AnnualAverageHeartRateOperation: AsyncOperation {
    private var date: Date
    var heartRate: Double?
    
    init(date: Date) {
        self.date = date
    }
    
    override func main() {
        startFetchRequest()
    }
    
    private func startFetchRequest() {
        let beatsPerMinuteUnit = HKUnit.count().unitDivided(by: HKUnit.minute())
        HealthKitService.getDiscreteAverageSample(forIdentifier: .heartRate, unit: beatsPerMinuteUnit, startDate: date.lastYear, endDate: date) { [weak self] heartRate in
            guard let heartRate = heartRate, let _self = self else {
                self?.finish()
                return
            }
            
            _self.heartRate = heartRate
            self?.finish()
        }
    }
}
