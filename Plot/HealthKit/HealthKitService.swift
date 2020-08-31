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
                    print(weight)
                })
                
                HealthKitService.getCumulativeSumSample(forIdentifier: .stepCount, unit: .count(), date: Date()) { steps in
                    print(steps)
                }
                
                HealthKitService.getCumulativeSumSample(forIdentifier: .distanceWalkingRunning, unit: .mile(), date: Date()) { distance in
                    print(distance)
                }
                
                HealthKitService.getCumulativeSumSample(forIdentifier: .activeEnergyBurned, unit: .kilocalorie(), date: Date()) { steps in
                    print(steps)
                }
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
        
        getMostRecentSample(for: weightSampleType, start: Date.distantPast, end: Date()) { (sample, error) in
            guard let sample = sample else {
                if let error = error {
                    print(error)
                }
                
                completion(nil)
                return
            }
            
            // HKUnit.gramUnit(with: .kilo)
            let weightInKilograms = sample.quantity.doubleValue(for: unit)
            completion(weightInKilograms)
        }
    }
    
    class func getMostRecentSample(for sampleType: HKSampleType,
                                   start: Date,
                                   end: Date,
                                   completion: @escaping (HKQuantitySample?, Error?) -> Swift.Void) {
        
        // Use HKQuery to load the most recent samples.
        let mostRecentPredicate = HKQuery.predicateForSamples(withStart: start,
                                                              end: end,
                                                              options: .strictEndDate)
        
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate,
                                              ascending: false)
        
        let limit = 1
        
        let sampleQuery = HKSampleQuery(sampleType: sampleType,
                                        predicate: mostRecentPredicate,
                                        limit: limit,
                                        sortDescriptors: [sortDescriptor]) { (query, samples, error) in
                                            guard let samples = samples,
                                                let mostRecentSample = samples.first as? HKQuantitySample else {
                                                    
                                                    completion(nil, error)
                                                    return
                                            }
                                            completion(mostRecentSample, nil)
        }
        
        healthStore.execute(sampleQuery)
    }
    
    class func getCumulativeSumSample(forIdentifier identifier: HKQuantityTypeIdentifier,
                                      unit: HKUnit,
                                      date: Date,
                                      completion: @escaping (Double?) -> Void) {
        guard let quantityType = HKQuantityType.quantityType(forIdentifier: identifier) else {
            completion(nil)
            return
        }
        
        let calendar = Calendar.current
        let startDate = calendar.startOfDay(for: date)
        let endDate = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: date)
        
        //  Set the Predicates & Interval
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        var interval = DateComponents()
        interval.day = 1
        
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
}
