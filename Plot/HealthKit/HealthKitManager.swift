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
import HealthKit

class HealthKitManager {
    
    private let lock = NSLock()
    private var queue: OperationQueue
    private var metrics: [HealthMetricCategory: [HealthMetric]]
    private var containers: [Container]
    private var isRunning: Bool
    private var dispatchGroup: DispatchGroup!
    
    init() {
        self.isRunning = false
        self.metrics = [:]
        self.containers = []
        self.queue = OperationQueue()
    }
    
    func loadHealthKitActivities(_ completion: @escaping ([HealthMetricCategory: [HealthMetric]], Bool) -> Void) {
        guard !isRunning else {
            completion([:], false)
            return
        }
        
        // Start clean
        metrics = [:]
        containers = []
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
            
            // Flights Climbed
            let flightsClimbedOperation = FlightsClimbedOperation(date: today)
            flightsClimbedOperation.delegate = self
    
            
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
            
            let activeEnergyOp = ActiveEnergyOperation(date: today)
            activeEnergyOp.delegate = self
            
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
            
            let futureDay = today.dayAfter
            
            let workoutMinutesOp = WorkoutMinutesOperation(date: futureDay)
            workoutMinutesOp.delegate = self
            
            // Setup queue
            self?.queue.addOperations([workoutMinutesOp, annualAverageStepsOperation, groupOperation, adapter, flightsClimbedOperation, annualAverageHeartRateOperation, heartRateOperation, heartRateOpAdapter, annualAverageWeightOperation, weightOperation, weightOpAdapter, sleepOp, mindfulnessOp, activeEnergyOp, dietaryEnergyConsumedOp, dietaryFatTotalOp, dietaryProteinOp, dietaryCarbohydratesOp, dietarySugarOp], waitUntilFinished: false)
            
            if #available(iOS 14.0, *) {
                for workout in HKWorkoutActivityType.allCases {
                    let op = WorkoutOperation(date: futureDay, workoutActivityType: workout, rank: Int(workout.rawValue))
                    op.delegate = self
                    op.lastSyncDate = lastSyncDate
                    self?.queue.addOperations([op], waitUntilFinished: false)
                }
            } else {
                // Fallback on earlier versions
                for workout in HKWorkoutActivityType.oldAllCases {
                    let op = WorkoutOperation(date: futureDay, workoutActivityType: workout, rank: Int(workout.rawValue))
                    op.delegate = self
                    op.lastSyncDate = lastSyncDate
                    self?.queue.addOperations([op], waitUntilFinished: false)
                }
            }
            
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
                if _self.containers.count > 0 {
                    _self.saveFirebase{
                        completion(_self.metrics, true)
                    }
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
    
    func saveFirebase(completion: @escaping () -> Void) {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            completion()
            return
        }
        
        dispatchGroup = DispatchGroup()
        
        dispatchGroup.notify(queue: DispatchQueue.global(), execute: {
            completion()
        })

        let reference = Database.database().reference().child(userHealthEntity).child(currentUserId)
        dispatchGroup.enter()
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
            
            self?.dispatchGroup.leave()
        })
    }
    
    func checkHealthAuthorizationStatus(_ completion: @escaping () -> Void) {
        HealthKitService.checkHealthAuthorizationStatus()
    }
}

extension HealthKitManager: MetricOperationDelegate {
    func insertMetric(_ operation: AsyncOperation, _ metric: HealthMetric, _ category: HealthMetricCategory) {
        lock.lock(); defer { lock.unlock() }
        metrics[category, default: []].append(metric)
    }
    
    func insertMetric(_ operation: AsyncOperation, _ metric: HealthMetric, _ category: HealthMetricCategory, _ containers: [Container]) {
        lock.lock(); defer { lock.unlock() }
        metrics[category, default: []].append(metric)
        self.containers.append(contentsOf: containers)
    }
}

protocol MetricOperationDelegate: AnyObject {
    func insertMetric(_ operation: AsyncOperation, _ metric: HealthMetric, _ category: HealthMetricCategory)
    func insertMetric(_ operation: AsyncOperation, _ metric: HealthMetric, _ category: HealthMetricCategory, _ containers: [Container])
}
