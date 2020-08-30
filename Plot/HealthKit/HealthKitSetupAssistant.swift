//
//  HealthKitSetupAssistant.swift
//  Plot
//
//  Created by Hafiz Usama on 2020-08-28.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import HealthKit

class HealthKitSetupAssistant {
    
    class let healthStore = HKHealthStore()
    
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
            let stepCount = HKObjectType.quantityType(forIdentifier: .stepCount),
            let distanceWalkingRunning = HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning),
            let distanceCycling = HKObjectType.quantityType(forIdentifier: .distanceCycling),
            let activeEnergy = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned) else {
                completion(false, HealthkitSetupError.dataTypeNotAvailable)
                return
        }
        
        // Prepare a list of types you want HealthKit to read and write
        let healthKitTypesToRead: Set<HKObjectType> = [activeEnergy,
                                                        stepCount,
                                                        distanceWalkingRunning,
                                                        distanceCycling,
                                                        bodyMass,
                                                        bodyMassIndex,
                                                        HKObjectType.workoutType()]
        
        let healthKitTypesToWrite: Set<HKSampleType> = [
                                                       distanceWalkingRunning,
                                                       distanceCycling,
                                                       activeEnergy,
                                                       HKObjectType.workoutType()]
        
        // Request Authorization
        healthStore.requestAuthorization(toShare: healthKitTypesToWrite,
                                             read: healthKitTypesToRead) { (success, error) in
                                                completion(success, error)
        }
    }
}
