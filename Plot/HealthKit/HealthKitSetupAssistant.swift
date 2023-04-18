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
        guard let healthKitTypesToRead = dataTypesToRead(),
              let healthKitTypesToWrite = dataTypesToWrite() else {
            completion(false, HealthkitSetupError.dataTypeNotAvailable)
            return
        }
        healthStore.requestAuthorization(toShare: healthKitTypesToWrite,
                                         read: healthKitTypesToRead) { (success, error) in
            completion(success, error)
        }
    }
    
    class func dataTypesToRead() -> Set<HKObjectType>? {
        guard let bodyMass = HKObjectType.quantityType(forIdentifier: .bodyMass),
              let heartRate = HKObjectType.quantityType(forIdentifier: .heartRate),
              let stepCount = HKObjectType.quantityType(forIdentifier: .stepCount),
              let flightCount = HKObjectType.quantityType(forIdentifier: .flightsClimbed),
              let distanceWalkingRunning = HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning),
              let distanceCycling = HKObjectType.quantityType(forIdentifier: .distanceCycling),
              let sleepAnalysis = HKObjectType.categoryType(forIdentifier: .sleepAnalysis),
              let mindfulSession = HKObjectType.categoryType(forIdentifier: .mindfulSession),
              let activeEnergy = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned) else {
            return nil
        }
        let summaryType = HKObjectType.activitySummaryType()
        
        // Prepare a list of types you want HealthKit to read and write
        let healthKitTypesToRead: Set<HKObjectType> = [summaryType,
                                                       activeEnergy,
                                                       stepCount,
                                                       flightCount,
                                                       sleepAnalysis,
                                                       mindfulSession,
                                                       heartRate,
                                                       bodyMass,
                                                       distanceWalkingRunning,
                                                       distanceCycling,
                                                       HKObjectType.workoutType()]
        return healthKitTypesToRead
    }
    
    class func dataTypesToWrite() -> Set<HKSampleType>? {
        guard let distanceWalkingRunning = HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning),
              let distanceCycling = HKObjectType.quantityType(forIdentifier: .distanceCycling),
              let mindfulSession = HKObjectType.categoryType(forIdentifier: .mindfulSession) else {
            return nil
        }
        
        let healthKitTypesToWrite: Set<HKSampleType> = [
            distanceWalkingRunning,
            distanceCycling,
            mindfulSession,
            HKObjectType.workoutType()]
        return healthKitTypesToWrite
    }
}

//let exerciseTime = HKObjectType.quantityType(forIdentifier: .appleExerciseTime),
//let standTime = HKObjectType.quantityType(forIdentifier: .appleStandTime),
//let moveTime = HKObjectType.quantityType(forIdentifier: .appleMoveTime),

//            let dietaryFatTotal = HKObjectType.quantityType(forIdentifier: .dietaryFatTotal),
//            let dietaryCarbohydrates = HKObjectType.quantityType(forIdentifier: .dietaryCarbohydrates),
//            let dietarySugar = HKObjectType.quantityType(forIdentifier: .dietarySugar),
//            let dietaryProtein = HKObjectType.quantityType(forIdentifier: .dietaryProtein),
//            let dietaryEnergyConsumed = HKObjectType.quantityType(forIdentifier: .dietaryEnergyConsumed),

