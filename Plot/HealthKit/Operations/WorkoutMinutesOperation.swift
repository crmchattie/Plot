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
            guard let workouts = workouts, !workouts.isEmpty, let errorList = errorList, errorList.isEmpty, let _self = self else {
                self?.finish()
                return
            }
            
            var workout: HKWorkout = workouts.last!
                            
            var averageWorkoutTime: Double = 0
            
            workouts.forEach { currentWorkout in
                let interval = currentWorkout.endDate.timeIntervalSince(currentWorkout.startDate)
                averageWorkoutTime += interval
                if currentWorkout.startDate > workout.startDate {
                    workout = currentWorkout
                }
            }
            
            var metricMinutes = HealthMetric(type: HealthMetricType.workoutMinutes, total: workout.endDate.timeIntervalSince(workout.startDate), date: workout.endDate, unitName: "minutes", rank: -1)
            metricMinutes.hkSample = workout
                                
            if averageWorkoutTime != 0 {
                averageWorkoutTime /= Double(workouts.count)
                metricMinutes.average = averageWorkoutTime
            }

            _self.delegate?.insertMetric(_self, metricMinutes, HealthMetricCategory.workouts)
            
            self?.finish()
        }
    }
}
