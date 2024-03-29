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
        HealthKitService.getWorkouts(forWorkoutActivityType: workoutActivityType, startDate: startDate.lastYear, endDate: startDate) { [weak self] workouts, error  in
            guard let workouts = workouts, error == nil, let _self = self, let currentUserID = Auth.auth().currentUser?.uid else {
                self?.finish()
                return
            }

            let healthkitWorkoutsReference = Database.database().reference().child(userHealthEntity).child(currentUserID).child(healthkitWorkoutsKey)
            healthkitWorkoutsReference.observeSingleEvent(of: .value) { dataSnapshot in
                var existingWorkoutKeys: [String: Any] = [:]
                if dataSnapshot.exists(), let dataSnapshotValue = dataSnapshot.value as? [String: Any] {
                    existingWorkoutKeys = dataSnapshotValue
                }
                            
                if
                    // Most recent workout
                    let workout = workouts.last {
                    let workoutTotalCalories = workout.totalEnergyBurned?.doubleValue(for: .kilocalorie()) ?? 0
                    
                    var metricCalories = HealthMetric(type: HealthMetricType.workout, total: workoutTotalCalories, date: workout.endDate, unitName: "calories", rank: _self.rank)
                    metricCalories.hkSample = workout
                                        
                    var averageEnergyBurned: Double = 0
                    
                        workouts.forEach { workout in
                            let totalEnergyBurned = workout.totalEnergyBurned?.doubleValue(for: .kilocalorie()) ?? 0
                            averageEnergyBurned += totalEnergyBurned
                            
                            // Only create activities that past lastSync date time
                            if (_self.lastSyncDate == nil || (workout.startDate >= _self.lastSyncDate!)) && existingWorkoutKeys[workout.uuid.uuidString] == nil {
                                let ref = Database.database().reference()
                                var workoutID = UUID().uuidString
                                
                                if let newWorkoutId = ref.child(userWorkoutsEntity).child(currentUserID).childByAutoId().key {
                                    workoutID = newWorkoutId
                                }
                                
                                ref.child(userHealthEntity).child(currentUserID).child(healthkitWorkoutsKey).child(workout.uuid.uuidString).child(identifierKey).setValue(workoutID)
                                
                                ref.child(userWorkoutsEntity).child(currentUserID).child(workoutID).child(hkSampleIDKey).setValue(workout.uuid.uuidString)
                                ref.child(userWorkoutsEntity).child(currentUserID).child(workoutID).child("totalEnergyBurned").setValue(totalEnergyBurned)
                                                                                                
                                let workoutFB = Workout(forInitialSave: workoutID, hkWorkout: workout)
                                let workoutActions = WorkoutActions(workout: workoutFB, active: false, selectedFalconUsers: [])
                                workoutActions.createNewWorkout(updateDirectAssociation: false)
                            }
                        }
                    
                    if averageEnergyBurned != 0 {
                        averageEnergyBurned /= Double(workouts.count)
                        metricCalories.average = averageEnergyBurned
                    }
                    
                    _self.delegate?.insertMetric(_self, metricCalories, HealthMetricCategory.workouts)
                }
                
                self?.finish()
            }
        }
    }
}
