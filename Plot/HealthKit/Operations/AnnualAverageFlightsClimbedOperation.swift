//
//  AnnualAverageFlightsClimbedOperation.swift
//  Plot
//
//  Created by Cory McHattie on 8/24/22.
//  Copyright © 2022 Immature Creations. All rights reserved.
//

import Foundation

class AnnualAverageFlightsClimbedOperation: AsyncOperation {
    private var startDate: Date
    var flights: Double?
    
    init(date: Date) {
        self.startDate = date
    }
    
    override func main() {
        startFetchRequest()
    }
    
    private func startFetchRequest() {
        HealthKitService.getCumulativeSumSampleAverageAndRecent(forIdentifier: .flightsClimbed, unit: .count(), startDate: startDate.lastYear, endDate: startDate) { [weak self] annualFlights, _, _ in
            guard let annualFlights = annualFlights, let _self = self else {
                self?.finish()
                return
            }
            
            _self.flights = annualFlights
            self?.finish()
        }
    }
}
