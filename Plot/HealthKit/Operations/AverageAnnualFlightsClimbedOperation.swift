//
//  AverageAnnualFlightsClimbedOperation.swift
//  Plot
//
//  Created by Cory McHattie on 11/9/22.
//  Copyright © 2022 Immature Creations. All rights reserved.
//

import HealthKit

class AverageAnnualFlightsClimbedOperation: AsyncOperation {
    private var startDate: Date
    var floors: Double?
    
    init(date: Date) {
        self.startDate = date
    }
    
    override func main() {
        startFetchRequest()
    }
    
    private func startFetchRequest() {
        HealthKitService.getCumulativeSumSampleAverageAndRecent(forIdentifier: .flightsClimbed, unit: .count(), startDate: startDate.lastYear, endDate: startDate) { [weak self] annualFloors, _, _ in
            guard let annualFloors = annualFloors, let _self = self else {
                print("finish AverageAnnualFlightsClimbedOperation")
                self?.finish()
                return
            }
            
            _self.floors = annualFloors
            print("finish AverageAnnualFlightsClimbedOperation")
            self?.finish()
        }
    }
}

