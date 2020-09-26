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
    private var workoutActivityType: HKWorkoutActivityType
    weak var delegate: MetricOperationDelegate?

    init(date: Date, workoutActivityType: HKWorkoutActivityType) {
        self.startDate = date
        self.workoutActivityType = workoutActivityType
    }
    
    override func main() {
        startFetchRequest()
    }
    
    private func startFetchRequest() {
        HealthKitService.getAllWorkouts(forWorkoutActivityType: workoutActivityType, startDate: startDate.lastYear, endDate: startDate) { [weak self] workouts, error  in
            guard let workouts = workouts, error == nil, let _self = self else {
                self?.finish()
                return
            }
            
            if
                let workout = workouts.last,
                // Take last 48-hours
                workout.endDate >= Date().dayBefore.dayBefore,
                let total = workout.totalEnergyBurned?.doubleValue(for: .kilocalorie()),
                total > 0 {
                
                var metric = HealthMetric(type: HealthMetricType.workout, total: total, date: _self.startDate, unit: "calories", rank: HealthMetricType.workout.rank)
                metric.hkWorkout = workout
                
                var averageEnergyBurned: Double = 0
                workouts.forEach { workout in
                    averageEnergyBurned += workout.totalEnergyBurned?.doubleValue(for: .kilocalorie()) ?? 0
                }
                if averageEnergyBurned != 0 {
                    averageEnergyBurned /= Double(workouts.count)
                    metric.average = averageEnergyBurned
                }

                _self.delegate?.insertMetric(_self, metric)
            }

            self?.finish()
        }
    }
}
