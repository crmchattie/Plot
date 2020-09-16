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
    private var activities: [Activity]
    private var metrics: [HealthMetric]
    
    init() {
        self.activities = []
        self.metrics = []
        self.queue = OperationQueue()
        self.queue.maxConcurrentOperationCount = 1
    }
    
    func loadHealthKitActivities(_ completion: @escaping ([Activity]) -> Void) {
        // Start clean
        activities = []
        
        HealthKitService.authorizeHealthKit { [weak self] authorized in
            guard authorized, let queue = self?.queue else {
                completion([])
                return
            }
            
            let today = Date()
            // Operation to fetch annual average steps
            let annualAverageStepsOperation = HealthKitAnnualAverageStepsOperation(date: today)
            
            // Operation to fetch daily total steps from date to the number of days in the past
            let groupOperation = HealthKitStepsActivityGroupOperation(date: today, days: 7)
            groupOperation.delegate = self
            
            // Assign fetched annual average steps to groupOperation that assign it to each daily steps fetch operation
            let adapter = BlockOperation() { [unowned annualAverageStepsOperation, unowned groupOperation] in
                groupOperation.annualAverageSteps = annualAverageStepsOperation.steps
            }
            
            adapter.addDependency(annualAverageStepsOperation)
            groupOperation.addDependency(adapter)
            
            queue.addOperations([annualAverageStepsOperation, groupOperation, adapter], waitUntilFinished: false)
            
            // Once everything is fetched return the activities
            queue.addBarrierBlock { [weak self] in
                completion(self?.activities ?? [])
            }
        }
    }
}

extension HealthKitManager: HealthKitActivityOperationDelegate {
    func insertActivity(_ operation: HealthKitStepsActivityOperation, _ activity: Activity) {
        lock.lock(); defer { lock.unlock() }
        activities.append(activity)
    }
    
    func insertMetric(_ operation: HealthKitStepsActivityOperation, _ metric: HealthMetric) {
        lock.lock(); defer { lock.unlock() }
        metrics.append(metric)
    }
}
