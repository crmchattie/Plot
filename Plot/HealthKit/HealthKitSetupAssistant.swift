//
//  HealthKitSetupAssistant.swift
//  Plot
//
//  Created by Hafiz Usama on 2020-08-28.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import HealthKit

class HealthKitSetupAssistant {
    
    static let healthStore = HKHealthStore()
    
    private enum HealthkitSetupError: Error {
        case notAvailableOnDevice
        case dataTypeNotAvailable
    }
    
    class func authorizeHealthKit(completion: @escaping (Bool, Error?) -> Swift.Void) {
        
        // Check to see if HealthKit Is Available on this device
        guard HKHealthStore.isHealthDataAvailable() else {
            completion(false, HealthkitSetupError.notAvailableOnDevice)
            return
        }
        
        // Prepare the data types that will interact with HealthKit
        guard let bodyMassIndex = HKObjectType.quantityType(forIdentifier: .bodyMassIndex),
            let bodyMass = HKObjectType.quantityType(forIdentifier: .bodyMass),
            let heartRate = HKObjectType.quantityType(forIdentifier: .heartRate),
            let stepCount = HKObjectType.quantityType(forIdentifier: .stepCount),
            let dietaryFatTotal = HKObjectType.quantityType(forIdentifier: .dietaryFatTotal),
            let dietaryCarbohydrates = HKObjectType.quantityType(forIdentifier: .dietaryCarbohydrates),
            let dietarySugar = HKObjectType.quantityType(forIdentifier: .dietarySugar),
            let dietaryProtein = HKObjectType.quantityType(forIdentifier: .dietaryProtein),
            let dietaryEnergyConsumed = HKObjectType.quantityType(forIdentifier: .dietaryEnergyConsumed),
            let distanceWalkingRunning = HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning),
            let distanceCycling = HKObjectType.quantityType(forIdentifier: .distanceCycling),
            let sleepAnalysis = HKObjectType.categoryType(forIdentifier: .sleepAnalysis),
            let mindfulSession = HKObjectType.categoryType(forIdentifier: .mindfulSession),
            let activeEnergy = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned) else {
                completion(false, HealthkitSetupError.dataTypeNotAvailable)
                return
        }
        let summaryType = HKObjectType.activitySummaryType()
        
        // Prepare a list of types you want HealthKit to read and write
        let healthKitTypesToRead: Set<HKObjectType> = [summaryType,
                                                        activeEnergy,
                                                        stepCount,
                                                        sleepAnalysis,
                                                        mindfulSession,
                                                        heartRate,
                                                        bodyMass,
                                                        bodyMassIndex,
                                                        distanceWalkingRunning,
                                                        distanceCycling,
                                                        dietaryFatTotal,
                                                        dietaryCarbohydrates,
                                                        dietarySugar,
                                                        dietaryProtein,
                                                        dietaryEnergyConsumed,
                                                        HKObjectType.workoutType()]
        
        let healthKitTypesToWrite: Set<HKSampleType> = [
                                                       distanceWalkingRunning,
                                                       distanceCycling,
                                                       mindfulSession,
                                                       HKObjectType.workoutType()]
        
        // Request Authorization
        healthStore.requestAuthorization(toShare: healthKitTypesToWrite,
                                             read: healthKitTypesToRead) { (success, error) in
                                                completion(success, error)
        }
    }
}
