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
    static var authorized = false
    
    class var healthStore: HKHealthStore {
        return HealthKitSetupAssistant.healthStore
    }
    
    class func checkHealthAuthorizationStatus() {
        let status = healthStore.authorizationStatus(for: .workoutType())
        switch (status) {
        case .notDetermined:
            print("notDetermined")
        case .sharingDenied:
            print("sharingDenied")
        case .sharingAuthorized:
            print("sharingAuthorized")
        @unknown default:
            print("default")
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
    
    class func getAllTheSamples(for sampleType: HKSampleType,
                                startDate: Date,
                                endDate: Date,
                                completion: @escaping ([HKSample]?, Error?) -> Swift.Void) {
        
        // Use HKQuery to load the most recent samples.
        let mostRecentPredicate = HKQuery.predicateForSamples(withStart: startDate,
                                                              end: endDate,
                                                              options: .strictEndDate)
        
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate,
                                              ascending: false)
        
        let sampleQuery = HKSampleQuery(sampleType: sampleType,
                                        predicate: mostRecentPredicate,
                                        limit: Int(HKObjectQueryNoLimit),
                                        sortDescriptors: [sortDescriptor]) { (query, samples, error) in
            completion(samples, error)
        }
        
        healthStore.execute(sampleQuery)
    }
    
    class func getIntervalBasedSamples(for quantityType: HKQuantityType,
                                       statisticsOptions: HKStatisticsOptions,
                                       startDate: Date, endDate: Date,
                                       anchorDate: Date,
                                       interval: DateComponents,
                                       completion: @escaping ([HKStatistics]?, Error?) -> Void) {
        
        // Create the query
        let query = HKStatisticsCollectionQuery(quantityType: quantityType,
                                                quantitySamplePredicate: nil,
                                                options: statisticsOptions,
                                                anchorDate: anchorDate,
                                                intervalComponents: interval)
        // Set the results handler
        query.initialResultsHandler = {
            query, results, error in
            guard let statsCollection = results else {
                // Perform proper error handling here
                print("*** An error occurred while calculating the statistics: \(String(describing: error?.localizedDescription)) ***")
                completion(nil, nil)
                return
            }
            
            var data: [HKStatistics] = []
            statsCollection.enumerateStatistics(from: startDate, to: endDate) {statistics, stop in
                data.append(statistics)
            }
            
            completion(data, nil)
        }
        
        healthStore.execute(query)
    }
    
    class func getCumulativeSumSampleAverageAndRecent(forIdentifier identifier: HKQuantityTypeIdentifier,
                                                      unit: HKUnit,
                                                      date: Date,
                                                      completion: @escaping (Double?, Double?, Date?) -> Void) {
        let calendar = Calendar.current
        let startDate = calendar.startOfDay(for: date)
        let endDate = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: date)!
        
        getCumulativeSumSampleAverageAndRecent(forIdentifier: identifier, unit: unit, startDate: startDate, endDate: endDate, completion: completion)
    }
    
    class func getCumulativeSumSampleAverageAndRecent(forIdentifier identifier: HKQuantityTypeIdentifier,
                                                      unit: HKUnit,
                                                      startDate: Date,
                                                      endDate: Date,
                                                      completion: @escaping (Double?, Double?, Date?) -> Void) {
        guard let quantityType = HKQuantityType.quantityType(forIdentifier: identifier) else {
            completion(nil, nil, nil)
            return
        }
        
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
            let statistics = results?.statistics() ?? []
            var total: Double = 0
            for statistic in statistics {
                total += statistic.sumQuantity()?.doubleValue(for: unit) ?? 0
            }
            
            if total > 0 {
                total /= Double(statistics.count)
            }
            
            let recent = statistics.last?.sumQuantity()?.doubleValue(for: unit)
            let recentStatDate = statistics.last?.startDate
            
            completion(total, recent, recentStatDate)
        }
        
        healthStore.execute(query)
    }
    
    class func getLatestDiscreteDailyAverageSample(forIdentifier identifier: HKQuantityTypeIdentifier,
                                                   unit: HKUnit,
                                                   completion: @escaping (Double?, Date?) -> Void) {
        let calendar = Calendar.current
        let endDate = Date()
        let startDate = calendar.date(byAdding: .year, value: -1, to: endDate)!
        var interval = DateComponents()
        interval.day = 1
        getDiscreteAverageSample(forIdentifier: identifier, unit: unit, startDate: startDate, endDate: endDate, interval: interval, completion: completion)
    }
    
    class func getDiscreteAverageSample(forIdentifier identifier: HKQuantityTypeIdentifier,
                                        unit: HKUnit,
                                        startDate: Date,
                                        endDate: Date,
                                        interval: DateComponents,
                                        completion: @escaping (Double?, Date?) -> Void) {
        guard let quantityType = HKQuantityType.quantityType(forIdentifier: identifier) else {
            completion(nil, nil)
            return
        }
        
        //  Set the Predicates & Interval
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        
        //  Perform the Query
        let query = HKStatisticsCollectionQuery(
            quantityType: quantityType,
            quantitySamplePredicate: predicate,
            options: [.discreteAverage],
            anchorDate: startDate,
            intervalComponents: interval)
        
        query.initialResultsHandler = { query, results, error in
            let statistics = results?.statistics()
            let mostRecent = statistics?.last
            let date = mostRecent?.endDate
            let count = mostRecent?.averageQuantity()?.doubleValue(for: unit)
            completion(count, date)
        }
        
        healthStore.execute(query)
    }
    
    class func getWorkouts(forWorkoutActivityType workoutActivityType: HKWorkoutActivityType,
                           startDate: Date,
                           endDate: Date,
                           completion: @escaping ([HKWorkout]?, Error?) -> Void) {
        // Get all workouts with the given workoutActivityType
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
        
        healthStore.execute(query)
    }
    
    class func getAllWorkouts(startDate: Date,
                              endDate: Date,
                              completion: @escaping ([HKWorkout]?, [Error]?) -> Void) {
        // Get all workouts with the given workoutActivityType
        let dispatchGroup = DispatchGroup()
        var workouts = [HKWorkout]()
        var errors = [Error]()
        if #available(iOS 14.0, *) {
            for workout in HKWorkoutActivityType.allCases {
                dispatchGroup.enter()
                let workoutPredicate = HKQuery.predicateForWorkouts(with: workout)
                
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
                                if let error = error {
                                    errors.append(error)
                                }
                                dispatchGroup.leave()
                                return
                            }
                            workouts.append(contentsOf: samples)
                            dispatchGroup.leave()
                        }
                    }
                
                healthStore.execute(query)
            }
            
            dispatchGroup.notify(queue: .main) {
                completion(workouts, errors)
            }
        } else {
            // Fallback on earlier versions
            for workout in HKWorkoutActivityType.oldAllCases {
                dispatchGroup.enter()
                let workoutPredicate = HKQuery.predicateForWorkouts(with: workout)
                
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
                                if let error = error {
                                    errors.append(error)
                                }
                                dispatchGroup.leave()
                                return
                            }
                            workouts.append(contentsOf: samples)
                            dispatchGroup.leave()
                        }
                    }
                
                healthStore.execute(query)
            }
            
            dispatchGroup.notify(queue: .main) {
                completion(workouts, errors)
            }
        }
    }
    
    class func getAllCategoryTypeSamples(forIdentifier identifier: HKCategoryTypeIdentifier,
                                         startDate: Date,
                                         endDate: Date,
                                         completion: @escaping ([HKCategorySample]?, Error?) -> Void) {
        
        guard let type = HKObjectType.categoryType(forIdentifier: identifier) else {
            completion(nil, nil)
            return
        }
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: true)
        
        let query = HKSampleQuery(sampleType: type, predicate: predicate, limit: 0, sortDescriptors: [sortDescriptor]) { (query, result, error) in
            guard let result = result, error == nil else {
                completion(nil, error)
                return
            }
            
            let categorySamples = result.compactMap({ $0 as? HKCategorySample })
            completion(categorySamples, nil)
        }
        
        // finally, we execute our query
        healthStore.execute(query)
    }
    
    class func getSummaryActivityData(startDate: Date,
                                      endDate: Date,
                                      completion: @escaping ([HKActivitySummary]?, Error?) -> Void) {
        
        let calendar = Calendar.current
        var startComponents = calendar.dateComponents([.day, .month, .year], from: startDate)
        startComponents.calendar = calendar
        var endComponents = calendar.dateComponents([.day, .month, .year], from: endDate)
        endComponents.calendar = calendar
        
        let predicate = HKQuery.predicate(forActivitySummariesBetweenStart: startComponents, end: endComponents)
        
        let query = HKActivitySummaryQuery(predicate: predicate) { (query, summaries, error) in
            completion(summaries, error)
        }
        
        healthStore.execute(query)
    }
    
    // MARK:- Storing data
    
    class func storeSample(sample: HKSample, completion: @escaping (Bool, Error?) -> Void) {
        healthStore.save(sample, withCompletion: completion)
    }
    
    class func storeSamples(samples: [HKSample], completion: @escaping (Bool, Error?) -> Void) {
        healthStore.save(samples, withCompletion: completion)
    }
    
    class func grabSpecificWorkoutSample(uuid: UUID, completion: @escaping ([HKWorkout]?, Error?) -> Void) {
        let predicate = HKQuery.predicateForObject(with: uuid)
        let workoutQuery = HKSampleQuery(
            sampleType: .workoutType(),
            predicate: predicate,
            limit: 1,
            sortDescriptors: nil) { (query, samples, error) in
                DispatchQueue.main.async {
                    
                    // Cast the samples as HKWorkout
                    guard let samples = samples as? [HKWorkout], error == nil else {
                        completion(nil, error)
                        return
                    }
                    
                    completion(samples, nil)
                }
            }
        
        healthStore.execute(workoutQuery)
    }
    
    class func grabSpecificCategorySample(uuid: UUID, identifier: HKCategoryTypeIdentifier, completion: @escaping ([HKCategorySample]?, Error?) -> Void) {
        guard let type = HKObjectType.categoryType(forIdentifier: identifier) else {
            completion(nil, nil)
            return
        }
        
        let predicate = HKQuery.predicateForObject(with: uuid)
        let workoutQuery = HKSampleQuery(
            sampleType: type,
            predicate: predicate,
            limit: 1,
            sortDescriptors: nil) { (query, samples, error) in
                DispatchQueue.main.async {
                    // Cast the samples as HKWorkout
                    guard let samples = samples as? [HKCategorySample], error == nil else {
                        completion(nil, error)
                        return
                    }
                    
                    completion(samples, nil)
                }
            }
        
        healthStore.execute(workoutQuery)
    }
    
    class func fetchHealthKitSample(for healthSampleType: HKSampleType, withPredicate predicate: NSPredicate, completion: @escaping (HKSample?, Error?) -> Swift.Void) {
        
        let query = HKSampleQuery(sampleType: healthSampleType, predicate: predicate, limit: 1, sortDescriptors: nil) { (query, samples, error) in
            
            if let error = error {
                // Handler error
                completion(nil,error)
            } else {
                guard let fetchedObject = samples?.first else {
                    // Handler unexisting object
                    completion(nil,nil)
                    return
                }
                
                completion(fetchedObject,nil)
            }
        }
        
        healthStore.execute(query)
    }
    
    class func deleteSample(sampleType: HKSampleType, uuid: UUID, completion: @escaping (Bool, Error?) -> Void) {
        let predicate = HKQuery.predicateForObject(with: uuid)
        HealthKitService.fetchHealthKitSample(for: sampleType, withPredicate: predicate) { (fetchedObject, error) in
            if let error = error {
                // Handle error
                completion(false,error)
            } else if let unwrappedFetchedObject = fetchedObject {
                healthStore.delete(unwrappedFetchedObject, withCompletion: { (success, error) in
                    if let error = error {
                        // Handle error
                        completion(false,error)
                    } else {
                        completion(success,nil)
                    }
                })
            }
        }
    }
}
