//
//  HealthService.swift
//  Plot
//
//  Created by Cory McHattie on 12/24/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import Foundation

class HealthService {
    let healhKitManager = HealthKitManager()

    var healthMetricSections: [String] = []
    var healthMetrics: [String: [HealthMetric]] = [:]
    
    func grabHealth(_ completion: @escaping () -> Void) {
        HealthKitService.authorizeHealthKit { [weak self] authorized in
            guard authorized else {
                completion()
                return
            }
            
            self?.healhKitManager.loadHealthKitActivities { metrics, shouldFetchActivities in
                DispatchQueue.main.async {
                    print("healthMetrics grabbed \(metrics.count)")
                    self?.healthMetrics = metrics
                    self?.healthMetricSections = Array(metrics.keys)
                    
                    self?.healthMetricSections.sort(by: { (v1, v2) -> Bool in
                        if let cat1 = HealthMetricCategory(rawValue: v1), let cat2 = HealthMetricCategory(rawValue: v2) {
                            return cat1.rank < cat2.rank
                        }
                        return false
                    })
                    completion()
                }
            }
        }
    }
}
