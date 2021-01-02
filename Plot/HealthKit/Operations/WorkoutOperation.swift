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
    private var rank: Int
    weak var delegate: MetricOperationDelegate?
    var lastSyncDate: Date?

    init(date: Date, workoutActivityType: HKWorkoutActivityType, rank: Int) {
        self.startDate = date
        self.workoutActivityType = workoutActivityType
        self.rank = rank
    }
    
    override func main() {
        startFetchRequest()
    }
    
    private func startFetchRequest() {
        HealthKitService.getAllWorkouts(forWorkoutActivityType: workoutActivityType, startDate: startDate.lastYear, endDate: startDate) { [weak self] workouts, error  in
            guard let workouts = workouts, error == nil, let _self = self, let currentUserId = Auth.auth().currentUser?.uid else {
                self?.finish()
                return
            }

            let healthkitWorkoutsReference = Database.database().reference().child(userHealthEntity).child(currentUserId).child(healthkitWorkoutsKey)
            healthkitWorkoutsReference.observeSingleEvent(of: .value) { dataSnapshot in
                var existingWorkoutKeys: [String: Any] = [:]
                if dataSnapshot.exists(), let dataSnapshotValue = dataSnapshot.value as? [String: Any] {
                    existingWorkoutKeys = dataSnapshotValue
                }
            
                if
                    // Most recent workout
                    let workout = workouts.last {
                    let total = workout.totalEnergyBurned?.doubleValue(for: .kilocalorie()) ?? 0
                    var metric = HealthMetric(type: HealthMetricType.workout, total: total, date: _self.startDate, unitName: "calories", rank: _self.rank)
                    metric.hkSample = workout
                    
                    var activities: [Activity] = []
                    var averageEnergyBurned: Double = 0
                    
                        workouts.forEach { workout in
                            let totalEnergyBurned = workout.totalEnergyBurned?.doubleValue(for: .kilocalorie()) ?? 0
                            averageEnergyBurned += totalEnergyBurned
                            
                            // Only create activities that past lastSync date time
                            if (_self.lastSyncDate == nil || (workout.startDate >= _self.lastSyncDate!)) && existingWorkoutKeys[workout.uuid.uuidString] == nil {
                                var activityID = UUID().uuidString
                                if let currentUserID = Auth.auth().currentUser?.uid, let newId = Database.database().reference().child(userActivitiesEntity).child(currentUserID).childByAutoId().key {
                                    activityID = newId
                                }

                                let activity = Activity(dictionary: ["activityID": activityID as AnyObject])
                                activity.activityType = "Workout"
                                activity.category = "Exercise"
                                activity.name = workout.workoutActivityType.name
                                activity.activityDescription = "\(totalEnergyBurned.clean) calories"
                                
                                let timezone = TimeZone.current
                                let seconds = TimeInterval(timezone.secondsFromGMT(for: Date()))
                                let startDateTime = workout.startDate.addingTimeInterval(seconds)
                                let endDateTime = workout.endDate.addingTimeInterval(seconds)
                                activity.startDateTime = NSNumber(value: startDateTime.timeIntervalSince1970)
                                activity.endDateTime = NSNumber(value: endDateTime.timeIntervalSince1970)

                                activity.allDay = false
                                activity.hkSampleID = workout.uuid.uuidString
                                activities.append(activity)
                                
                            }
                        }
                    
                    if averageEnergyBurned != 0 {
                        averageEnergyBurned /= Double(workouts.count)
                        metric.average = averageEnergyBurned
                    }

                    _self.delegate?.insertMetric(_self, metric, HealthMetricCategory.workouts.rawValue, activities)
                }

                self?.finish()
            }
        }
    }
}
