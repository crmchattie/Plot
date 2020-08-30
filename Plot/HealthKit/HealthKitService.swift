//
//  HealthKitService.swift
//  Plot
//
//  Created by Hafiz Usama on 2020-08-29.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import HealthKit

class HealthKitService {
    
    class var healthStore: HKHealthStore {
        return HealthKitSetupAssistant.healthStore
    }
    
    class func loadAndDisplayMostRecentWeight() {
        guard let weightSampleType = HKSampleType.quantityType(forIdentifier: .bodyMass) else {
            print("Body Mass Sample Type is no longer available in HealthKit")
            return
        }
        
        getMostRecentSample(for: weightSampleType, start: Date.distantPast, end: Date()) { (sample, error) in
            guard let sample = sample else {
                
                if let error = error {
                    print(error)
                }
                return
            }
            
            let weightInKilograms = sample.quantity.doubleValue(for: HKUnit.gramUnit(with: .kilo))
            
            print("Weight: \(weightInKilograms)")
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
                                            
                                            //Always dispatch to the main thread when complete.
                                            DispatchQueue.main.async {
                                                guard let samples = samples,
                                                    let mostRecentSample = samples.first as? HKQuantitySample else {
                                                        
                                                        completion(nil, error)
                                                        return
                                                }
                                                completion(mostRecentSample, nil)
                                            }
        }
        
        healthStore.execute(sampleQuery)
    }
    
    class func getCumulativeSumSample() {
        guard let quantityType = HKQuantityType.quantityType(forIdentifier: .stepCount) else { return }
        
        let endDate = Date()
        let calendar = Calendar.current
        let startDate = calendar.startOfDay(for: endDate)
        
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
            guard let results = results else { return }
                let stepsCount = Int(results.statistics().first?.sumQuantity()?.doubleValue(for: .count()) ?? 0)
        }

        healthStore.execute(query)
    }
}
