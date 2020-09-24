//
//  HealthKitManager.swift
//  Plot
//
//  Created by Hafiz Usama on 2020-09-01.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import Foundation

class HealthKitManager {
    
    private let lock = NSLock()
    private var queue: OperationQueue
    private var metrics: [HealthMetric]
    
    init() {
        self.metrics = []
        self.queue = OperationQueue()
        //self.queue.maxConcurrentOperationCount = 1
    }
    
    func loadHealthKitActivities(_ completion: @escaping ([HealthMetric]) -> Void) {
        // Start clean
        metrics = []
        
        HealthKitService.authorizeHealthKit { [weak self] authorized in
            guard authorized, let queue = self?.queue else {
                completion([])
                return
            }
            
            //let today = Date().dayBefore
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
            
            queue.addOperations([annualAverageStepsOperation, groupOperation, adapter, annualAverageHeartRateOperation, heartRateOperation, heartRateOpAdapter, annualAverageWeightOperation, weightOperation, weightOpAdapter], waitUntilFinished: false)
            
            // Once everything is fetched return the activities
            queue.addBarrierBlock { [weak self] in
                DispatchQueue.main.async {
                    self?.metrics.sort(by: {$0.rank < $1.rank})
                    completion(self?.metrics ?? [])
                }
            }
        }
    }
}

extension HealthKitManager: MetricOperationDelegate {
    func insertMetric(_ operation: AsyncOperation, _ metric: HealthMetric) {
        lock.lock(); defer { lock.unlock() }
        metrics.append(metric)
    }
}
