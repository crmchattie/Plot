//
//  HealthKitManager.swift
//  Plot
//
//  Created by Hafiz Usama on 2020-09-01.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import Foundation
import Firebase
import CodableFirebase

class HealthKitManager {
    
    private let lock = NSLock()
    private var queue: OperationQueue
    private var metrics: [String: [HealthMetric]]
    private var activities: [Activity]
    private var isRunning: Bool
    private var saveActivitiesDispatchGroup: DispatchGroup!
    
    init() {
        self.isRunning = false
        self.metrics = [:]
        self.activities = []
        self.queue = OperationQueue()
    }
    
    func loadHealthKitActivities(_ completion: @escaping ([String: [HealthMetric]], Bool) -> Void) {
        guard !isRunning else {
            completion([:], false)
            return
        }
        
        // Start clean
        metrics = [:]
        activities = []
        isRunning = true

        self.getUserHealthLastSyncDate { [weak self] lastSyncDate in
            let today = Date()
            
            // Steps
            
            // Operation to fetch annual average steps
            let annualAverageStepsOperation = AnnualAverageStepsOperation(date: today)
            
            // Operation to fetch daily total steps from date to the number of days in the past
            let groupOperation = StepsGroupOperation(date: today, days: 1)
            groupOperation.delegate = self
            
            // Assign fetched annual average steps to groupOperation that assign it to each daily steps fetch operation
            let adapter = BlockOperation() { [unowned annualAverageStepsOperation, unowned groupOperation] in
                groupOperation.annualAverageSteps = annualAverageStepsOperation.steps
            }
            
            adapter.addDependency(annualAverageStepsOperation)
            groupOperation.addDependency(adapter)
            
            // Heart Rate
            let annualAverageHeartRateOperation = AnnualAverageHeartRateOperation(date: today)
            let heartRateOperation = HeartRateOperation(date: today)
            heartRateOperation.delegate = self
            
            let heartRateOpAdapter = BlockOperation() { [unowned annualAverageHeartRateOperation, unowned heartRateOperation] in
                heartRateOperation.annualAverageHeartRate = annualAverageHeartRateOperation.heartRate
            }
            
            heartRateOpAdapter.addDependency(annualAverageHeartRateOperation)
            heartRateOperation.addDependency(heartRateOpAdapter)
            
            // Weight
            let annualAverageWeightOperation = AnnualAverageWeightOperation(date: today)
            let weightOperation = WeightOperation(date: today)
            weightOperation.delegate = self
            
            let weightOpAdapter = BlockOperation() { [unowned annualAverageWeightOperation, unowned weightOperation] in
                weightOperation.annualAverageWeight = annualAverageWeightOperation.weight
            }
            
            weightOpAdapter.addDependency(annualAverageWeightOperation)
            weightOperation.addDependency(weightOpAdapter)
            
            // Sleep
            let sleepOp = SleepOperation(date: today)
            sleepOp.delegate = self
            
            let mindfulnessOp = MindfulnessOperation(date: today)
            mindfulnessOp.delegate = self
            mindfulnessOp.lastSyncDate = lastSyncDate
            
            // Workouts
            // Consider workouts until a day in future
            let futureDay = today.dayAfter
            let functionalStrengthTrainingOp = WorkoutOperation(date: futureDay, workoutActivityType: .functionalStrengthTraining, rank: 1)
            functionalStrengthTrainingOp.delegate = self
            functionalStrengthTrainingOp.lastSyncDate = lastSyncDate

            let traditionalStrengthTrainingOp = WorkoutOperation(date: futureDay, workoutActivityType: .traditionalStrengthTraining, rank: 2)
            traditionalStrengthTrainingOp.delegate = self
            traditionalStrengthTrainingOp.lastSyncDate = lastSyncDate
            
            let runningOp = WorkoutOperation(date: futureDay, workoutActivityType: .running, rank: 3)
            runningOp.delegate = self
            runningOp.lastSyncDate = lastSyncDate
            
            let cyclingOp = WorkoutOperation(date: futureDay, workoutActivityType: .cycling, rank: 4)
            cyclingOp.delegate = self
            cyclingOp.lastSyncDate = lastSyncDate

            let hiitOp = WorkoutOperation(date: futureDay, workoutActivityType: .highIntensityIntervalTraining, rank: 5)
            hiitOp.delegate = self
            hiitOp.lastSyncDate = lastSyncDate
            
            // Nutrition
            let dietaryEnergyConsumedOp = NutritionOperation(date: today, nutritionTypeIdentifier: .dietaryEnergyConsumed, unit: .kilocalorie(), unitTitle: "calories", rank: 1)
            dietaryEnergyConsumedOp.delegate = self
            
            let gramsText = "grams"
            let dietaryFatTotalOp = NutritionOperation(date: today, nutritionTypeIdentifier: .dietaryFatTotal, unit: .gram(), unitTitle: gramsText, rank: 2)
            dietaryFatTotalOp.delegate = self
            
            let dietaryProteinOp = NutritionOperation(date: today, nutritionTypeIdentifier: .dietaryProtein, unit: .gram(), unitTitle: gramsText, rank: 3)
            dietaryProteinOp.delegate = self
            
            let dietaryCarbohydratesOp = NutritionOperation(date: today, nutritionTypeIdentifier: .dietaryCarbohydrates, unit: .gram(), unitTitle: gramsText, rank: 4)
            dietaryCarbohydratesOp.delegate = self
            
            let dietarySugarOp = NutritionOperation(date: today, nutritionTypeIdentifier: .dietarySugar, unit: .gram(), unitTitle: gramsText, rank: 5)
            dietarySugarOp.delegate = self
            
            // Setup queue
            self?.queue.addOperations([annualAverageStepsOperation, groupOperation, adapter, annualAverageHeartRateOperation, heartRateOperation, heartRateOpAdapter, annualAverageWeightOperation, weightOperation, weightOpAdapter, sleepOp, mindfulnessOp, functionalStrengthTrainingOp, traditionalStrengthTrainingOp, runningOp, cyclingOp, hiitOp, dietaryEnergyConsumedOp, dietaryFatTotalOp, dietaryProteinOp, dietaryCarbohydratesOp, dietarySugarOp], waitUntilFinished: false)
            
            // Once everything is fetched return the activities
            self?.queue.addBarrierBlock { [weak self] in
                guard let _self = self else {
                    completion([:], false)
                    return
                }
                
                // sort each section(items in a category)
                for (key, val) in _self.metrics {
                    _self.metrics[key] = val.sorted(by: {$0.rank < $1.rank})
                }
                
                // if we properly fetched the items then save
                if _self.activities.count > 0 {
                    _self.saveActivitiesOnFirebase(_self.activities, completion: {
                        completion(_self.metrics, true)
                    })
                }
                else {
                    completion(_self.metrics, false)
                }
                
                self?.isRunning = false
            }
        }
    }
    
    func getUserHealthLastSyncDate(_ completion: @escaping (Date?) -> Void) {
        guard let currentUser = Auth.auth().currentUser?.uid else {
            completion(nil)
            return
        }
            
        let reference = Database.database().reference().child(userHealthEntity).child(currentUser)
        reference.observeSingleEvent(of: .value, with: { (snapshot) in
            
            if snapshot.exists(),
               let value = snapshot.value as? [String: Any], let lastSyncDateTimeInterval = value[lastSyncDateKey] as? Double {
                let lastSyncDate = Date(timeIntervalSince1970: lastSyncDateTimeInterval)
                completion(lastSyncDate)
            } else {
                completion(nil)
            }
            
            reference.removeAllObservers()
        })
    }
    
    func saveActivitiesOnFirebase(_ activities: [Activity], completion: @escaping () -> Void) {
        guard activities.count > 0, let currentUserId = Auth.auth().currentUser?.uid else {
            completion()
            return
        }
        
        saveActivitiesDispatchGroup = DispatchGroup()
        
        saveActivitiesDispatchGroup.notify(queue: DispatchQueue.global(), execute: {
            completion()
        })
        
        for activity in activities {
            if let activityID = activity.activityID {
                
                saveActivitiesDispatchGroup.enter()
                let activityReference = Database.database().reference().child(activitiesEntity).child(activityID).child(messageMetaDataFirebaseFolder)
                activityReference.updateChildValues(activity.toAnyObject(), withCompletionBlock: { [weak self] (error, reference) in
                    self?.saveActivitiesDispatchGroup.leave()
                })
                
                saveActivitiesDispatchGroup.enter()
                let userActivityReference = Database.database().reference().child(userActivitiesEntity).child(currentUserId).child(activityID).child(messageMetaDataFirebaseFolder)
        
                let values: [String : Any] = ["isGroupActivity": false, "badge": 0]
                userActivityReference.updateChildValues(values, withCompletionBlock: { [weak self] (error, reference) in
                    self?.saveActivitiesDispatchGroup.leave()
                })
                
                if let hkSampleID = activity.hkSampleID {
                    let healthkitWorkoutsReference = Database.database().reference().child(userHealthEntity).child(currentUserId).child(healthkitWorkoutsKey).child(hkSampleID).child("activityID")
                    healthkitWorkoutsReference.setValue(activityID)
                }
            }
        }
        
        let reference = Database.database().reference().child(userHealthEntity).child(currentUserId)
        saveActivitiesDispatchGroup.enter()
        reference.observeSingleEvent(of: .value, with: { [weak self] (snapshot) in
            if snapshot.exists() {
                let values = [lastSyncDateKey: Date().timeIntervalSince1970]
                reference.updateChildValues(values)
            }
            else if !snapshot.exists() {
                let identifier = UUID().uuidString
                let values = [identifierKey: identifier, lastSyncDateKey: Date().timeIntervalSince1970] as [String : Any]
                reference.setValue(values)
            }
            
            self?.saveActivitiesDispatchGroup.leave()
        })
    }
}

extension HealthKitManager: MetricOperationDelegate {
    func insertMetric(_ operation: AsyncOperation, _ metric: HealthMetric, _ category: String) {
        lock.lock(); defer { lock.unlock() }
        metrics[category, default: []].append(metric)
    }
    
    func insertMetric(_ operation: AsyncOperation, _ metric: HealthMetric, _ category: String, _ activities: [Activity]) {
        lock.lock(); defer { lock.unlock() }
        metrics[category, default: []].append(metric)
        self.activities.append(contentsOf: activities)
    }
}

protocol MetricOperationDelegate: class {
    func insertMetric(_ operation: AsyncOperation, _ metric: HealthMetric, _ category: String)
    func insertMetric(_ operation: AsyncOperation, _ metric: HealthMetric, _ category: String, _ activities: [Activity])
}
