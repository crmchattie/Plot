//
//  HealthKitSampleBuilder.swift
//  Plot
//
//  Created by Hafiz Usama on 2020-12-23.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import HealthKit

class HealthKitSampleBuilder {
    class func createHKWorkout(from workout: Workout) -> HKWorkout? {
        guard let start = workout.startDateTime, let end = workout.endDateTime else {
            return nil
        }

        var totalEnergyBurned: HKQuantity?
        if let cals = workout.totalEnergyBurned {
            totalEnergyBurned = HKQuantity(unit: HKUnit.kilocalorie(), doubleValue: cals)
        }
        
        let workout = HKWorkout(
            activityType: workout.hkWorkoutActivityType,
            start: start,
            end: end,
            workoutEvents: nil,
            totalEnergyBurned: totalEnergyBurned,
            totalDistance: nil,
            device: nil,
            metadata: nil
        )
        
        return workout
    }
    
    class func createHKMindfulness(from mindfulness: Mindfulness) -> HKCategorySample? {
        guard let start = mindfulness.startDateTime, let end = mindfulness.endDateTime, let mindfulSessionType = HKObjectType.categoryType(forIdentifier: .mindfulSession) else {
            return nil
        }
        
        let hkMindfulness = HKCategorySample(type: mindfulSessionType, value: 0, start: start, end: end)
        return hkMindfulness
    }
}
