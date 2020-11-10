//
//  WorkoutOperation.swift
//  Plot
//
//  Created by Hafiz Usama on 2020-09-24.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import HealthKit
import Firebase

class WorkoutOperation: AsyncOperation {
    private var startDate: Date
    private var workoutActivityType: HKWorkoutActivityType
    weak var delegate: MetricOperationDelegate?
    var lastSyncDate: Date?

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
                // Most recent workout
                let workout = workouts.last {
                let total = workout.totalEnergyBurned?.doubleValue(for: .kilocalorie()) ?? 0
                var metric = HealthMetric(type: HealthMetricType.workout, total: total, date: _self.startDate, unit: "calories", rank: HealthMetricType.workout.rank)
                metric.hkSample = workout
                
                var activities: [Activity] = []
                var averageEnergyBurned: Double = 0
                workouts.forEach { workout in
                    let totalEnergyBurned = workout.totalEnergyBurned?.doubleValue(for: .kilocalorie()) ?? 0
                    averageEnergyBurned += totalEnergyBurned
                    
                    // Only create activities that past lastSync date time
                    if _self.lastSyncDate == nil || (workout.startDate >= _self.lastSyncDate!) {
                        var activityID = UUID().uuidString
                        if let currentUserID = Auth.auth().currentUser?.uid, let newId = Database.database().reference().child(userActivitiesEntity).child(currentUserID).childByAutoId().key {
                            activityID = newId
                        }

                        let activity = Activity(dictionary: ["activityID": activityID as AnyObject])
                        activity.activityType = ActivityType.workout.rawValue
                        activity.name = workout.workoutActivityType.name
                        activity.activityDescription = "\(totalEnergyBurned.clean) calories"
                        activity.startDateTime = NSNumber(value: workout.startDate.timeIntervalSince1970)
                        activity.endDateTime = NSNumber(value: workout.endDate.timeIntervalSince1970)
                        activity.allDay = false
                        activities.append(activity)
                    }
                }
                
                if averageEnergyBurned != 0 {
                    averageEnergyBurned /= Double(workouts.count)
                    metric.average = averageEnergyBurned
                }

                _self.delegate?.insertMetric(_self, metric, activities)
            }

            self?.finish()
        }
    }
}
