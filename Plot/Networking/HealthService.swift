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

    var healthMetricSections: [String] = [] {
        didSet {
            if oldValue != healthMetricSections {
                healthMetricSections.sort(by: { (v1, v2) -> Bool in
                    if let cat1 = HealthMetricCategory(rawValue: v1), let cat2 = HealthMetricCategory(rawValue: v2) {
                        return cat1.rank < cat2.rank
                    }
                    return false
                })
                NotificationCenter.default.post(name: .healthUpdated, object: nil)
            }
        }
    }
    
    var healthMetrics: [String: [HealthMetric]] = [:] {
        didSet {
            if oldValue != healthMetrics {
                NotificationCenter.default.post(name: .healthUpdated, object: nil)
            }
        }
    }
    
    var nutrition = [String: [HKQuantitySample]]()
    var workouts = [String: [HKWorkout]]()
    var mindfulnesses = [HKCategorySample]()
    
    var askedforAuthorization: Bool = false
    
    func grabHealth(_ completion: @escaping () -> Void) {
        HealthKitService.authorizeHealthKit { [weak self] askedforAuthorization in
            self?.askedforAuthorization = askedforAuthorization
            self?.healhKitManager.loadHealthKitActivities { metrics, shouldFetchActivities in
                if !metrics.isEmpty {
                    HealthKitService.authorized = true
                    DispatchQueue.main.async {
                        self?.healthMetricSections = Array(metrics.keys)
                        self?.healthMetrics = metrics
                        completion()
                    }
                } else {
                    var metrics: [String: [HealthMetric]] = [:]
                    HealthKitService.authorized = false
                    let dispatchGroup = DispatchGroup()
                    dispatchGroup.enter()
                    self?.mealFetcher.fetchMeals { firebaseMeals in
                        guard !firebaseMeals.isEmpty else {
                            dispatchGroup.leave()
                            return
                        }
                        let sortedFirebaseMeals = firebaseMeals.sorted {
                            $0.startDateTime! < $1.startDateTime!
                        }
                        var nutrients = [HKQuantityTypeIdentifier: [Double]]()
                        var latestNutrients = [HKQuantityTypeIdentifier: Double]()
                        let recentStatDate = sortedFirebaseMeals.last?.startDateTime!
                        for firebaseMeal in sortedFirebaseMeals {
                            if let mealNutrients = HealthKitSampleBuilder.createHKNutritions(from: firebaseMeal) {
                                for nutrient in mealNutrients {
                                    var double: Double = 0
                                    let type = HKQuantityTypeIdentifier(rawValue: nutrient.quantityType.identifier)
                                    
                                    self?.nutrition[type.name, default: []].append(nutrient)
                                    
                                    if nutrient.quantityType.is(compatibleWith: .gram()) {
                                        double = nutrient.quantity.doubleValue(for: .gram())
                                    } else if nutrient.quantityType.is(compatibleWith: .jouleUnit(with: .kilo)) {
                                        double = nutrient.quantity.doubleValue(for: .jouleUnit(with: .kilo))
                                    }
                                    nutrients[type, default: []].append(double)
                                    if Calendar.current.compare(firebaseMeal.startDateTime!, to: recentStatDate!, toGranularity: .day) == .orderedSame {
                                        latestNutrients[type, default: 0] += double
                                    }
                                }
                            }
                        }
                        
                        for (type, list) in nutrients {
                            if let dailyTotal = latestNutrients[type] {
                                let average = list.reduce(0, +) / Double(list.count)
                                if type == .dietaryEnergyConsumed {
                                    var metric = HealthMetric(type: HealthMetricType.nutrition(type.name), total: dailyTotal, date: recentStatDate!, unitName: "calories", rank: 1)
                                    metric.unit = .kilocalorie()
                                    metric.quantityTypeIdentifier = type
                                    metric.average = average
                                    metrics[HealthMetricCategory.nutrition.rawValue, default: []].append(metric)
                                } else if type == .dietaryFatTotal {
                                    var metric = HealthMetric(type: HealthMetricType.nutrition(type.name), total: dailyTotal, date: recentStatDate!, unitName: "grams", rank: 2)
                                    metric.unit = .gram()
                                    metric.quantityTypeIdentifier = type
                                    metric.average = average
                                    metrics[HealthMetricCategory.nutrition.rawValue, default: []].append(metric)
                                } else if type == .dietaryProtein {
                                    var metric = HealthMetric(type: HealthMetricType.nutrition(type.name), total: dailyTotal, date: recentStatDate!, unitName: "grams", rank: 3)
                                    metric.unit = .gram()
                                    metric.quantityTypeIdentifier = type
                                    metric.average = average
                                    metrics[HealthMetricCategory.nutrition.rawValue, default: []].append(metric)
                                } else if type == .dietaryCarbohydrates {
                                    var metric = HealthMetric(type: HealthMetricType.nutrition(type.name), total: dailyTotal, date: recentStatDate!, unitName: "grams", rank: 4)
                                    metric.unit = .gram()
                                    metric.quantityTypeIdentifier = type
                                    metric.average = average
                                    metrics[HealthMetricCategory.nutrition.rawValue, default: []].append(metric)
                                } else if type == .dietarySugar {
                                    var metric = HealthMetric(type: HealthMetricType.nutrition(type.name), total: dailyTotal, date: recentStatDate!, unitName: "grams", rank: 5)
                                    metric.unit = .gram()
                                    metric.quantityTypeIdentifier = type
                                    metric.average = average
                                    metrics[HealthMetricCategory.nutrition.rawValue, default: []].append(metric)
                                }
                            }
                        }
                        
                        dispatchGroup.leave()
                    }
                    dispatchGroup.enter()
                    self?.workoutFetcher.fetchWorkouts { firebaseWorkouts in
                        guard !firebaseWorkouts.isEmpty else {
                            dispatchGroup.leave()
                            return
                        }
                        let sortedFirebaseWorkouts = firebaseWorkouts.sorted {
                            $0.startDateTime! < $1.startDateTime!
                        }
                        for firebaseWorkout in sortedFirebaseWorkouts {
                            if let workout = HealthKitSampleBuilder.createHKWorkout(from: firebaseWorkout) {
                                let type = workout.workoutActivityType.name
                                self?.workouts[type, default: []].append(workout)
                            }
                        }
                        
                        for (_, workouts) in self!.workouts {
                            if
                                // Most recent workout
                                let workout = workouts.last {
                                let total = workout.totalEnergyBurned?.doubleValue(for: .kilocalorie()) ?? 0
                                
                                var metric = HealthMetric(type: HealthMetricType.workout, total: total, date: Date().dayAfter, unitName: "calories", rank: 7)
                                
                                let workoutType = workout.workoutActivityType
                                if workoutType == .functionalStrengthTraining {
                                    metric.rank = 2
                                } else if workoutType == .traditionalStrengthTraining {
                                    metric.rank = 3
                                } else if workoutType == .running {
                                    metric.rank = 4
                                } else if workoutType == .cycling {
                                    metric.rank = 5
                                } else if workoutType == .highIntensityIntervalTraining {
                                    metric.rank = 6
                                }
                                
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
                                metrics[HealthMetricCategory.workouts.rawValue, default: []].append(metric)
                            }
                        }
                        
                        dispatchGroup.leave()
                    }
                    
                    dispatchGroup.enter()
                    self?.mindfulnessFetcher.fetchMindfulness { [self] firebaseMindfulnesses in
                        guard !firebaseMindfulnesses.isEmpty else {
                            dispatchGroup.leave()
                            return
                        }
                        for firebaseMindfulness in firebaseMindfulnesses {
                            if let mindfulness = HealthKitSampleBuilder.createHKMindfulness(from: firebaseMindfulness) {
                                self?.mindfulnesses.append(mindfulness)
                            }
                        }
                        
                        let endDate = Date()
                        var startDay = endDate.lastYear.dayBefore
                        var interval = NSDateInterval(start: startDay, duration: 86400)
                        var map: [Date: Double] = [:]
                        var sum: Double = 0
                        for mindfuless in self!.mindfulnesses {
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
                            
                            metrics[HealthMetricCategory.general.rawValue, default: []].append(metric)
                        }
                        
                        dispatchGroup.leave()
                    }
                    
                    dispatchGroup.notify(queue: .main) {
                        if !metrics.isEmpty {
                            self?.healthMetrics = metrics
                            self?.healthMetricSections = Array(metrics.keys)
                        }
                        completion()
                    }
                }
            }
        }
    }
}
