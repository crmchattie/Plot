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
            
            let workout: HKWorkout = workouts.sorted(by: { $0.endDate < $1.endDate }).last!
                        
            var averageWorkoutTime: Double = 0
            var totalWorkoutTime: Double = workout.endDate.timeIntervalSince(workout.startDate)
            
            workouts.forEach { currentWorkout in
                let interval = currentWorkout.endDate.timeIntervalSince(currentWorkout.startDate)
                averageWorkoutTime += interval
                if currentWorkout.endDate.isSameDay(as: workout.endDate) {
                    totalWorkoutTime += interval
                }
            }
            
            var metricMinutes = HealthMetric(type: HealthMetricType.workoutMinutes, total: totalWorkoutTime, date: workout.endDate, unitName: "minutes", rank: -1)
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
