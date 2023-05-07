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
        var interval = DateComponents()
        interval.year = 1
        HealthKitService.getDiscreteAverageSample(forIdentifier: .heartRate, unit: beatsPerMinuteUnit, startDate: date.lastYear, endDate: date, interval: interval) { [weak self] heartRate, date in
            guard let heartRate = heartRate, let _self = self else {
                print("finish AnnualAverageHeartRateOperation")
                self?.finish()
                return
            }
            
            _self.heartRate = heartRate
            print("finish AnnualAverageHeartRateOperation")
            self?.finish()
        }
    }
}
