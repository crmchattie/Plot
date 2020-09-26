//
//  HealthKitService.swift
//  Plot
//
//  Created by Hafiz Usama on 2020-08-29.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import HealthKit

// Completion closures might not be on the main thread when executed.
class HealthKitService {
    
    class var healthStore: HKHealthStore {
        return HealthKitSetupAssistant.healthStore
    }
    
    class func syncEventsFromHealthKitData() {
        authorizeHealthKit { result in
            if result {
                
                HealthKitService.loadAndDisplayMostRecentWeight(for: .pound(), completion: { weight in
                })
                
                HealthKitService.getCumulativeSumSample(forIdentifier: .distanceWalkingRunning, unit: .mile(), date: Date()) { distance in
                }

                HealthKitService.getCumulativeSumSample(forIdentifier: .activeEnergyBurned, unit: .kilocalorie(), date: Date()) { steps in
                }
                
                let date = Date()
                let year = Calendar.current.component(.year, from: date)
                let month = Calendar.current.component(.month, from: date)
                let day = Calendar.current.component(.day, from: date)
                guard let lastYear = Calendar.current.date(from: DateComponents(year: year-1, month: month, day: day)) else {
                    return
                }
                let beatsPerMinuteUnit = HKUnit.count().unitDivided(by: HKUnit.minute())
                HealthKitService.getDiscreteAverageSample(forIdentifier: .heartRate, unit: beatsPerMinuteUnit, date: date, completion: { heartRate in
                })
            }
        }
    }
    
    class func authorizeHealthKit(completion: @escaping (Bool) -> Void) {
        HealthKitSetupAssistant.authorizeHealthKit { (authorized, error) in
            guard authorized else {
                let baseMessage = "HealthKit Authorization Failed"
                if let error = error {
                    print("\(baseMessage). Reason: \(error.localizedDescription)")
                } else {
                    print(baseMessage)
                }
                completion(false)
                return
            }
            completion(true)
        }
    }
    
    class func loadAndDisplayMostRecentWeight(for unit: HKUnit,
                                              completion: @escaping (Double?) -> Void) {
        guard let weightSampleType = HKSampleType.quantityType(forIdentifier: .bodyMass) else {
            print("Body Mass Sample Type is no longer available in HealthKit")
            completion(nil)
            return
        }
        
        getMostRecentSamples(for: weightSampleType, startDate: Date.distantPast, endDate: Date()) { (samples, error) in
            guard let sample = samples?.first as? HKQuantitySample else {
                if let error = error {
                    print(error)
                }
                
                completion(nil)
                return
            }
            //
            // HKUnit.gramUnit(with: .kilo)
            let weightInKilograms = sample.quantity.doubleValue(for: unit)
            completion(weightInKilograms)
        }
    }
    
    class func getMostRecentSamples(for sampleType: HKSampleType,
                                   startDate: Date,
                                   endDate: Date,
                                   completion: @escaping ([HKSample]?, Error?) -> Swift.Void) {
        
        // Use HKQuery to load the most recent samples.
        let mostRecentPredicate = HKQuery.predicateForSamples(withStart: startDate,
                                                              end: endDate,
                                                              options: .strictEndDate)
        
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate,
                                              ascending: false)
        
        let limit = 1
        
        let sampleQuery = HKSampleQuery(sampleType: sampleType,
                                        predicate: mostRecentPredicate,
                                        limit: limit,
                                        sortDescriptors: [sortDescriptor]) { (query, samples, error) in
                                            completion(samples, error)
        }
        
        healthStore.execute(sampleQuery)
    }
    
    class func getCumulativeSumSample(forIdentifier identifier: HKQuantityTypeIdentifier,
                                      unit: HKUnit,
                                      date: Date,
                                      completion: @escaping (Double?) -> Void) {
        let calendar = Calendar.current
        let startDate = calendar.startOfDay(for: date)
        let endDate = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: date)!
        
        getCumulativeSumSample(forIdentifier: identifier, unit: unit, startDate: startDate, endDate: endDate, completion: completion)
    }
    
    class func getCumulativeSumSample(forIdentifier identifier: HKQuantityTypeIdentifier,
                                      unit: HKUnit,
                                      startDate: Date,
                                      endDate: Date,
                                      completion: @escaping (Double?) -> Void) {
        guard let quantityType = HKQuantityType.quantityType(forIdentifier: identifier) else {
            completion(nil)
            return
        }
        
        //  Set the Predicates & Interval
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        var interval = DateComponents()
        interval.year = 1
        
        //  Perform the Query
        let query = HKStatisticsCollectionQuery(
            quantityType: quantityType,
            quantitySamplePredicate: predicate,
            options: [.cumulativeSum],
            anchorDate: startDate,
            intervalComponents: interval)
        
        query.initialResultsHandler = { query, results, error in
            let count = results?.statistics().first?.sumQuantity()?.doubleValue(for: unit)
            completion(count)
        }

        healthStore.execute(query)
    }
    
    class func getDiscreteAverageSample(forIdentifier identifier: HKQuantityTypeIdentifier,
                                      unit: HKUnit,
                                      date: Date,
                                      completion: @escaping (Double?) -> Void) {
        let calendar = Calendar.current
        let startDate = calendar.startOfDay(for: date)
        let endDate = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: date)!
        
        getDiscreteAverageSample(forIdentifier: identifier, unit: unit, startDate: startDate, endDate: endDate, completion: completion)
    }
    
    class func getDiscreteAverageSample(forIdentifier identifier: HKQuantityTypeIdentifier,
                                      unit: HKUnit,
                                      startDate: Date,
                                      endDate: Date,
                                      completion: @escaping (Double?) -> Void) {
        guard let quantityType = HKQuantityType.quantityType(forIdentifier: identifier) else {
            completion(nil)
            return
        }
        
        //  Set the Predicates & Interval
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        var interval = DateComponents()
        interval.year = 1
        
        //  Perform the Query
        let query = HKStatisticsCollectionQuery(
            quantityType: quantityType,
            quantitySamplePredicate: predicate,
            options: [.discreteAverage],
            anchorDate: startDate,
            intervalComponents: interval)
        
        query.initialResultsHandler = { query, results, error in
            let count = results?.statistics().first?.averageQuantity()?.doubleValue(for: unit)
            completion(count)
        }

        healthStore.execute(query)
    }
    
    class func getAllWorkouts(forWorkoutActivityType workoutActivityType: HKWorkoutActivityType,
                              startDate: Date,
                              endDate: Date,
                              completion: @escaping ([HKWorkout]?, Error?) -> Void) {
        // Get all workouts with the "Other" activity type.
        let workoutPredicate = HKQuery.predicateForWorkouts(with: workoutActivityType)
        
        let datePredicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        
        // Combine the predicates into a single predicate.
        let compound = NSCompoundPredicate(andPredicateWithSubpredicates:
            [workoutPredicate, datePredicate])
        
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate,
                                              ascending: true)
        
        let query = HKSampleQuery(
            sampleType: .workoutType(),
            predicate: compound,
            limit: 0,
            sortDescriptors: [sortDescriptor]) { (query, samples, error) in
                DispatchQueue.main.async {
                    
                    // Cast the samples as HKWorkout
                    guard let samples = samples as? [HKWorkout], error == nil else {
                        completion(nil, error)
                        return
                    }
                    
                    completion(samples, nil)
                }
        }
        
        HKHealthStore().execute(query)
    }
}
