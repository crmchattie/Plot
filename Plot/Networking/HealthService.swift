//
//  HealthService.swift
//  Plot
//
//  Created by Cory McHattie on 12/24/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import Foundation

extension NSNotification.Name {
    static let healthUpdated = NSNotification.Name(Bundle.main.bundleIdentifier! + ".healthUpdated")
}

class HealthService {
    let healhKitManager = HealthKitManager()
    let mealFetcher = MealFetcher()
    let workoutFetcher = WorkoutFetcher()
    let mindfulnessFetcher = MindfulnessFetcher()
    let moodFetcher = MoodFetcher()

    var healthMetricSections: [String] = []
    var healthMetrics: [String: [HealthMetric]] = [:]
    
    func grabHealth(_ completion: @escaping () -> Void) {
        HealthKitService.authorizeHealthKit { [weak self] authorized in
            if authorized {
                self?.healhKitManager.loadHealthKitActivities { metrics, shouldFetchActivities in
                    DispatchQueue.main.async {
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
            } else {
                let dispatchGroup = DispatchGroup()
                dispatchGroup.enter()
                self?.mealFetcher.fetchMeals { meals in
                    for meal in meals {
                        if let hkMeal = HealthKitSampleBuilder.createHKNutritions(from: meal) {
                            
                        }
                    }
                    dispatchGroup.leave()
                }
                dispatchGroup.enter()
                self?.workoutFetcher.fetchWorkouts { workouts in
                    for workout in workouts {
                        if let hkWorkout = HealthKitSampleBuilder.createHKWorkout(from: workout) {
                            
                        }
                    }
                    
                    dispatchGroup.leave()
                }
                dispatchGroup.enter()
                self?.mindfulnessFetcher.fetchMindfulness { mindfulnesses in
                    for mindfulness in mindfulnesses {
                        if let hkMindfulness = HealthKitSampleBuilder.createHKMindfulness(from: mindfulness) {
                            
                        }
                    }
                    
                    dispatchGroup.leave()
                }
                
                dispatchGroup.notify(queue: .main) {
                    completion()
                }
            }
        }
    }
}
