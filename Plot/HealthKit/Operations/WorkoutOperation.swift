//
//  WorkoutOperation.swift
//  Plot
//
//  Created by Hafiz Usama on 2020-09-24.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import HealthKit

class WorkoutOperation: AsyncOperation {
    private var startDate: Date
    weak var delegate: MetricOperationDelegate?
    var annualAverageWeight: Double?
    
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
        guard let lastSevenDays = Calendar.current.date(from: DateComponents(year: year, month: month, day: day-7)) else {
            self.finish()
            return
        }
        
        HealthKitService.getAllWorkouts(forStartDate: lastSevenDays, endDate: startDate) { [weak self] workouts, error  in

            guard let workouts = workouts, error == nil, let _self = self else {
                self?.finish()
                return
            }
            
            for workout in workouts {
                let total = workout.totalEnergyBurned?.doubleValue(for: .kilocalorie()) ?? 0
                var metric = HealthMetric(type: HealthMetricType.workout, total: total, date: _self.startDate, unit: "calories", rank: HealthMetricType.workout.rank)
                metric.hkWorkout = workout
                _self.delegate?.insertMetric(_self, metric)
            }

            self?.finish()
        }
    }
}
