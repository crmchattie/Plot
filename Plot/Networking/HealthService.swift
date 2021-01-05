//
//  HealthService.swift
//  Plot
//
//  Created by Cory McHattie on 12/24/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import Foundation
import HealthKit

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
                self?.mealFetcher.fetchMeals { firebaseMeals in
                    let sortedFirebaseMeals = firebaseMeals.sorted {
                        $0.startDateTime! < $1.startDateTime!
                    }
                    var nutrients = [HKQuantitySample]()
                    var latestNutrients = [HKQuantitySample]()
                    var recentStatDate = Date.distantPast
                    for firebaseMeal in sortedFirebaseMeals {
                        if firebaseMeal.startDateTime!.compare(recentStatDate) == .orderedAscending {
                            recentStatDate = firebaseMeal.startDateTime!
                            
                        }
                        if let mealNutrients = HealthKitSampleBuilder.createHKNutritions(from: firebaseMeal) {
                            for nutrient in mealNutrients {
                                
                            }
                        }
                    }
                    
//                    let type = HealthMetricType.nutrition(_self.nutritionTypeIdentifier.name)
//                    var metric = HealthMetric(type: type, total: dailyTotal, date: recentStatDate, unitName: _self.unitTitle, rank: _self.rank)
//                    metric.unit = _self.unit
//                    metric.quantityTypeIdentifier = _self.nutritionTypeIdentifier
//                    metric.average = annualAverage
                    
                    
                    
                    dispatchGroup.leave()
                }
                dispatchGroup.enter()
                self?.workoutFetcher.fetchWorkouts { firebaseWorkouts in
                    let sortedFirebaseWorkouts = firebaseWorkouts.sorted {
                        $0.startDateTime! < $1.startDateTime!
                    }
                    var workoutsDict = [String: [HKWorkout]]()
                    for firebaseWorkout in sortedFirebaseWorkouts {
                        if let workout = HealthKitSampleBuilder.createHKWorkout(from: firebaseWorkout) {
                            if let type = firebaseWorkout.type {
                                workoutsDict[type, default: []].append(workout)
                            }
                        }
                    }
                    
                    for (_, workouts) in workoutsDict {
                        if
                            // Most recent workout
                            let workout = workouts.last {
                            let total = workout.totalEnergyBurned?.doubleValue(for: .kilocalorie()) ?? 0
                            
                            var metric = HealthMetric(type: HealthMetricType.workout, total: total, date: Date().dayAfter, unitName: "calories", rank: 1)
                            metric.hkSample = workout
                            
                            var averageEnergyBurned: Double = 0
                            
                                workouts.forEach { workout in
                                    let totalEnergyBurned = workout.totalEnergyBurned?.doubleValue(for: .kilocalorie()) ?? 0
                                    averageEnergyBurned += totalEnergyBurned
                                    
                                }
                            
                            if averageEnergyBurned != 0 {
                                averageEnergyBurned /= Double(workouts.count)
                                metric.average = averageEnergyBurned
                            }
                            self?.healthMetrics[HealthMetricCategory.workouts.rawValue, default: []].append(metric)
                        }
                    }
                    
                    dispatchGroup.leave()
                }
                dispatchGroup.enter()
                self?.mindfulnessFetcher.fetchMindfulness { firebaseMindfulnesses in
                    var mindfulnesses = [HKCategorySample]()
                    for firebaseMindfulness in firebaseMindfulnesses {
                        if let mindfulness = HealthKitSampleBuilder.createHKMindfulness(from: firebaseMindfulness) {
                            mindfulnesses.append(mindfulness)
                        }
                    }
                    
                    let endDate = Date()
                    var startDay = endDate.lastYear.dayBefore
                    var interval = NSDateInterval(start: startDay, duration: 86400)
                    var map: [Date: Double] = [:]
                    var sum: Double = 0
                    for mindfuless in mindfulnesses {
                        while !(interval.contains(mindfuless.endDate)) && interval.endDate < endDate {
                            startDay = startDay.advanced(by: 86400)
                            interval = NSDateInterval(start: startDay, duration: 86400)
                        }
                        
                        let timeSum = mindfuless.endDate.timeIntervalSince(mindfuless.startDate)
                        map[startDay, default: 0] += timeSum
                        sum += timeSum
                        
                    }
                    
                    let sortedDates = Array(map.sorted(by: { $0.0 < $1.0 }))
                    let average = sum / Double(map.count)
                    
                    if let last = sortedDates.last?.key, let val = map[last] {
                        var metric = HealthMetric(type: .mindfulness, total: val, date: last, unitName: "hrs", rank: HealthMetricType.mindfulness.rank)
                        metric.average = average
                        
                        self?.healthMetrics[HealthMetricCategory.general.rawValue, default: []].append(metric)
                        
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
