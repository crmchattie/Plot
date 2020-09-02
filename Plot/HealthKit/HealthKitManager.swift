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
    
    init() {
        self.activities = []
        self.queue = OperationQueue()
        self.queue.maxConcurrentOperationCount = 1
    }
    
    func loadHealthKitActivities() {
        
    }
}

extension HealthKitManager: HealthKitActivityOperationDelegate {
    func insertActivity(_ operation: HealthKitActivityOperation, _ activity: Activity) {
        lock.lock(); defer { lock.unlock() }
        activities.append(activity)
    }
}
