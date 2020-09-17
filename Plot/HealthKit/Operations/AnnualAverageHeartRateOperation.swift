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
    var heartRate: Int?
    
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
        
        let beatsPerMinuteUnit = HKUnit.count().unitDivided(by: HKUnit.minute())
        HealthKitService.getDiscreteAverageSample(forIdentifier: .heartRate, unit: beatsPerMinuteUnit, startDate: lastYear, endDate: date) { [weak self] heartRate in
            guard let heartRate = heartRate, let _self = self else {
                self?.finish()
                return
            }
            
            _self.heartRate = Int(heartRate)
            self?.finish()
        }
    }
}
