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
            let annualAverageFlightsClimbedOperation = AverageAnnualFlightsClimbedOperation(date: today)
            let flightsClimbedOperation = FlightsClimbedOperation(date: today)
            flightsClimbedOperation.delegate = self
            
            let flightsClimbedOpAdapter = BlockOperation() { [unowned annualAverageFlightsClimbedOperation, unowned flightsClimbedOperation] in
                flightsClimbedOperation.annualAverageFloors = annualAverageFlightsClimbedOperation.floors
            }
            
            flightsClimbedOpAdapter.addDependency(annualAverageFlightsClimbedOperation)
            flightsClimbedOperation.addDependency(flightsClimbedOpAdapter)
            
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
            
            
            //Mindfulness
            let mindfulnessOp = MindfulnessOperation(date: today)
            mindfulnessOp.delegate = self
            mindfulnessOp.lastSyncDate = lastSyncDate
            
            
            //Active energy
            let annualAverageActiveEnergyOperation = AnnualAverageActiveEnergyOperation(date: today)
            let activeEnergyOp = ActiveEnergyOperation(date: today)
            activeEnergyOp.delegate = self
            
            let activeEnergyOpAdapter = BlockOperation() { [unowned annualAverageActiveEnergyOperation, unowned activeEnergyOp] in
                activeEnergyOp.annualAverageCalories = annualAverageActiveEnergyOperation.calories
            }
            
            activeEnergyOpAdapter.addDependency(annualAverageActiveEnergyOperation)
            activeEnergyOp.addDependency(activeEnergyOpAdapter)
            
            let futureDay = today.dayAfter
            
            //Workout minutes
            let workoutMinutesOp = WorkoutMinutesOperation(date: futureDay)
            workoutMinutesOp.delegate = self
            
            // Setup queue
            self?.queue.addOperations([workoutMinutesOp, annualAverageStepsOperation, groupOperation, adapter, annualAverageFlightsClimbedOperation, flightsClimbedOperation, flightsClimbedOpAdapter, annualAverageHeartRateOperation, heartRateOperation, heartRateOpAdapter, annualAverageWeightOperation, weightOperation, weightOpAdapter, sleepOp, mindfulnessOp, annualAverageActiveEnergyOperation, activeEnergyOp, activeEnergyOpAdapter], waitUntilFinished: false)
            
            if #available(iOS 16.0, *) {
                for index in 0...HKWorkoutActivityType.allCases.count - 1 {
                    let op = WorkoutOperation(date: futureDay, workoutActivityType: HKWorkoutActivityType.allCases[index], rank: index + 1)
                    op.delegate = self
                    op.lastSyncDate = lastSyncDate
                    self?.queue.addOperations([op], waitUntilFinished: false)
                }
            } else if #available(iOS 14.0, *) {
                for index in 0...HKWorkoutActivityType.oldAllCases.count - 1 {
                    let op = WorkoutOperation(date: futureDay, workoutActivityType: HKWorkoutActivityType.oldAllCases[index], rank: index + 1)
                    op.delegate = self
                    op.lastSyncDate = lastSyncDate
                    self?.queue.addOperations([op], waitUntilFinished: false)
                }
            } else {
                // Fallback on earlier versions
                for index in 0...HKWorkoutActivityType.oldOldAllCases.count - 1 {
                    let op = WorkoutOperation(date: futureDay, workoutActivityType: HKWorkoutActivityType.oldOldAllCases[index], rank: index + 1)
                    op.delegate = self
                    op.lastSyncDate = lastSyncDate
                    self?.queue.addOperations([op], waitUntilFinished: false)
                }
            }
            
            var dateComponents = DateComponents()
            dateComponents.day = 1
            
            var syncDate = lastSyncDate?.addDays(-1) ?? today.addDays(-1)
            
            while syncDate <= today {
                // Perform operations with syncDate here
                let stepsOp = StepsStorageOperation(date: syncDate)
                self?.queue.addOperations([stepsOp], waitUntilFinished: false)
                
                let flightsOp = FlightsClimbedStorageOperation(date: syncDate)
                self?.queue.addOperations([flightsOp], waitUntilFinished: false)
                
                let heartOp = HeartRateStorageOperation(date: syncDate)
                self?.queue.addOperations([heartOp], waitUntilFinished: false)
                
                let weightOp = WeightStorageOperation(date: syncDate)
                self?.queue.addOperations([weightOp], waitUntilFinished: false)
                
                let sleepOp = SleepStorageOperation(date: syncDate)
                self?.queue.addOperations([sleepOp], waitUntilFinished: false)
                
                let activeEnergyOp = ActiveEnergyStorageOperation(date: syncDate)
                self?.queue.addOperations([activeEnergyOp], waitUntilFinished: false)
                
                // Increment syncDate by one day
                syncDate = Calendar.current.date(byAdding: dateComponents, to: syncDate) ?? today
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
                _self.saveFirebase {
                    completion(_self.metrics, true)
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
            
            if snapshot.exists(), let value = snapshot.value as? [String: Any], let lastSyncDateTimeInterval = value[lastSyncDateKey] as? Double {
                let lastSyncDate = Date(timeIntervalSince1970: lastSyncDateTimeInterval)
                completion(lastSyncDate)
            } else {
                completion(nil)
            }
            
            reference.removeAllObservers()
        })
    }
    
    func saveFirebase(completion: @escaping () -> Void) {
        guard let currentUserID = Auth.auth().currentUser?.uid else {
            completion()
            return
        }
                
        dispatchGroup = DispatchGroup()
        
        dispatchGroup.notify(queue: DispatchQueue.global(), execute: {
            completion()
        })

        let reference = Database.database().reference().child(userHealthEntity).child(currentUserID)
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
    
    func setUpBackgroundDeliveryForDataTypes() {
        guard let dataTypesToRead = HealthKitSetupAssistant.dataTypesToRead() else {
            return
        }
        print("setUpBackgroundDeliveryForDataTypes")
        self.getUserHealthLastSyncDate { [weak self] lastSyncDate in
            for type in dataTypesToRead {
                guard let sampleType = type as? HKSampleType else { print("ERROR: \(type) is not an HKSampleType"); continue }
                let query = HKObserverQuery(sampleType: sampleType, predicate: nil) { query, completionHandler, error in
                    debugPrint("observer query update handler called for type \(type), error: \(String(describing: error))")
                    self?.queryForUpdates(type: type)
                    completionHandler()
                }
                HealthKitService.healthStore.execute(query)
                HealthKitService.healthStore.enableBackgroundDelivery(for: type, frequency: .immediate) { success, error in
                    debugPrint("enableBackgroundDeliveryForType handler called for \(type) - success: \(success), error: \(String(describing: error))")
                }
            }
        }
    }

        /// Initiates HK queries for new data based on the given type
        ///
        /// - parameter type: `HKObjectType` which has new data avilable.
    func queryForUpdates(type: HKObjectType) {
        switch type {
        case HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.stepCount):
            debugPrint("HKQuantityTypeIdentifierSteps")
        case HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRate):
            debugPrint("HKQuantityTypeIdentifierHeartRate")
        case HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.flightsClimbed):
            debugPrint("HKQuantityTypeIdentifierFlightsClimbed")
        case HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.activeEnergyBurned):
            debugPrint("HKQuantityTypeIdentifierActiveEnergy")
        case HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.bodyMass):
            debugPrint("HKQuantityTypeIdentifierBodyMass")
        case HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.distanceWalkingRunning):
            debugPrint("HKQuantityTypeIdentifierDistanceWalkinRunning")
        case HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.distanceCycling):
            debugPrint("HKQuantityTypeIdentifierCycling")
        case HKObjectType.categoryType(forIdentifier: HKCategoryTypeIdentifier.sleepAnalysis):
            debugPrint("HKQuantityTypeIdentifierSleepAnalysis")
        case HKObjectType.categoryType(forIdentifier: HKCategoryTypeIdentifier.mindfulSession):
            debugPrint("HKQuantityTypeIdentifierMindfulness")
        case is HKWorkoutType:
            debugPrint("HKWorkoutType")
        default: debugPrint("Unhandled HKObjectType: \(type)")
        }
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

//// Nutrition
//let dietaryEnergyConsumedOp = NutritionOperation(date: today, nutritionTypeIdentifier: .dietaryEnergyConsumed, unit: .kilocalorie(), unitTitle: "calories", rank: 1)
//dietaryEnergyConsumedOp.delegate = self
//
//let gramsText = "grams"
//let dietaryFatTotalOp = NutritionOperation(date: today, nutritionTypeIdentifier: .dietaryFatTotal, unit: .gram(), unitTitle: gramsText, rank: 2)
//dietaryFatTotalOp.delegate = self
//
//let dietaryProteinOp = NutritionOperation(date: today, nutritionTypeIdentifier: .dietaryProtein, unit: .gram(), unitTitle: gramsText, rank: 3)
//dietaryProteinOp.delegate = self
//
//let dietaryCarbohydratesOp = NutritionOperation(date: today, nutritionTypeIdentifier: .dietaryCarbohydrates, unit: .gram(), unitTitle: gramsText, rank: 4)
//dietaryCarbohydratesOp.delegate = self
//
//let dietarySugarOp = NutritionOperation(date: today, nutritionTypeIdentifier: .dietarySugar, unit: .gram(), unitTitle: gramsText, rank: 5)
//dietarySugarOp.delegate = self
