//
//  WorkoutMinutesOperation.swift
//  Plot
//
//  Created by Cory McHattie on 8/27/22.
//  Copyright © 2022 Immature Creations. All rights reserved.
//

import HealthKit
import Firebase

class WorkoutMinutesOperation: AsyncOperation {
    private var startDate: Date
    weak var delegate: MetricOperationDelegate?

    init(date: Date) {
        self.startDate = date
    }
    
    override func main() {
        startFetchRequest()
    }
    
    private func startFetchRequest() {
        HealthKitService.getAllWorkouts(startDate: startDate.lastYear, endDate: startDate) { [weak self] workouts, errorList  in
            guard let workouts = workouts, let errorList = errorList, errorList.isEmpty, let _self = self else {
                self?.finish()
                return
            }
            
            if
                // Most recent workout
                let workout = workouts.last {
                let workoutTotalMinutes = workout.endDate.timeIntervalSince(workout.startDate)
                                    
                var metricMinutes = HealthMetric(type: HealthMetricType.workoutMinutes, total: workoutTotalMinutes, date: workout.endDate, unitName: "hrs", rank: -1)
                metricMinutes.hkSample = workout
                
                var averageWorkoutTime: Double = 0
                
                workouts.forEach { workout in                    
                    let interval = workout.endDate.timeIntervalSince(workout.startDate)
                    averageWorkoutTime += interval
                }
                                    
                if averageWorkoutTime != 0 {
                    averageWorkoutTime /= Double(workouts.count)
                    metricMinutes.average = averageWorkoutTime
                }

                _self.delegate?.insertMetric(_self, metricMinutes, HealthMetricCategory.workouts.rawValue)
            }
            self?.finish()
        }
    }
}
