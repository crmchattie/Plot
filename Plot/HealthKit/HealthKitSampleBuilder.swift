//
//  HealthKitSampleBuilder.swift
//  Plot
//
//  Created by Hafiz Usama on 2020-12-23.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import HealthKit
import Firebase

class HealthKitSampleBuilder {
    class func createHKWorkout(from workout: Workout) -> HKWorkout? {
        guard let start = workout.startDateTime, let end = workout.endDateTime, let currentUserID = Auth.auth().currentUser?.uid else {
            return nil
        }
        
        var totalEnergyBurned: HKQuantity?
        if let val = workout.totalEnergyBurned {
            totalEnergyBurned = HKQuantity(unit: HKUnit.kilocalorie(), doubleValue: val)
        }
                
        var totalDistance: HKQuantity?
        if let val = workout.totalDistance {
            if workout.hkWorkoutActivityType == .swimming {
                totalDistance = HKQuantity(unit: HKUnit.yard(), doubleValue: val)
            } else {
                totalDistance = HKQuantity(unit: HKUnit.mile(), doubleValue: val)
            }
        }
                
        let hkWorkout = HKWorkout(
            activityType: workout.hkWorkoutActivityType,
            start: start,
            end: end,
            workoutEvents: nil,
            totalEnergyBurned: totalEnergyBurned,
            totalDistance: totalDistance,
            device: nil,
            metadata: nil
        )
        
        let ref = Database.database().reference()
        
        ref.child(userHealthEntity).child(currentUserID).child(healthkitWorkoutsKey).child(hkWorkout.uuid.uuidString).child(identifierKey).setValue(workout.id)
        
        ref.child(userWorkoutsEntity).child(currentUserID).child(workout.id).child(hkSampleIDKey).setValue(hkWorkout.uuid.uuidString)
        
        HealthKitService.storeSample(sample: hkWorkout) { (_, _) in
            NotificationCenter.default.post(name: .healthKitUpdated, object: nil)
        }
        
        return hkWorkout
    }
    
    class func editHKWorkout(from workout: Workout) -> HKWorkout? {
        guard let hkSampleID = workout.hkSampleID, let uuid = UUID(uuidString: hkSampleID), let start = workout.startDateTime, let end = workout.endDateTime, let currentUserID = Auth.auth().currentUser?.uid else {
            return nil
        }
        
        let ref = Database.database().reference()
        
        ref.child(userHealthEntity).child(currentUserID).child(healthkitWorkoutsKey).child(hkSampleID).child(identifierKey).removeValue()
                
        HealthKitService.deleteSample(sampleType: .workoutType(), uuid: uuid) { _,_ in }
        
        var totalEnergyBurned: HKQuantity?
        if let val = workout.totalEnergyBurned {
            totalEnergyBurned = HKQuantity(unit: HKUnit.kilocalorie(), doubleValue: val)
        }
                
        var totalDistance: HKQuantity?
        if let val = workout.totalDistance {
            if workout.hkWorkoutActivityType == .swimming {
                totalDistance = HKQuantity(unit: HKUnit.yard(), doubleValue: val)
            } else {
                totalDistance = HKQuantity(unit: HKUnit.mile(), doubleValue: val)
            }
        }
                
        let hkWorkout = HKWorkout(
            activityType: workout.hkWorkoutActivityType,
            start: start,
            end: end,
            workoutEvents: nil,
            totalEnergyBurned: totalEnergyBurned,
            totalDistance: totalDistance,
            device: nil,
            metadata: nil
        )
                
        ref.child(userHealthEntity).child(currentUserID).child(healthkitWorkoutsKey).child(hkWorkout.uuid.uuidString).child(identifierKey).setValue(workout.id)
        
        ref.child(userWorkoutsEntity).child(currentUserID).child(workout.id).child(hkSampleIDKey).setValue(hkWorkout.uuid.uuidString)
        
        HealthKitService.storeSample(sample: hkWorkout) { (_, _) in
            NotificationCenter.default.post(name: .healthKitUpdated, object: nil)
        }
        
        return hkWorkout
    }
    
    class func createHKMindfulness(from mindfulness: Mindfulness) -> HKCategorySample? {
        guard let start = mindfulness.startDateTime, let end = mindfulness.endDateTime, let mindfulSessionType = HKObjectType.categoryType(forIdentifier: .mindfulSession), let currentUserID = Auth.auth().currentUser?.uid else {
            return nil
        }
        
        let hkMindfulness = HKCategorySample(type: mindfulSessionType, value: 0, start: start, end: end)
        
        let ref = Database.database().reference()
        
        ref.child(userHealthEntity).child(currentUserID).child(healthkitMindfulnessKey).child(hkMindfulness.uuid.uuidString).child(identifierKey).setValue(mindfulness.id)
        
        ref.child(userMindfulnessEntity).child(currentUserID).child(mindfulness.id).child(hkSampleIDKey).setValue(hkMindfulness.uuid.uuidString)
        
        HealthKitService.storeSample(sample: hkMindfulness) { (_, _) in
            NotificationCenter.default.post(name: .healthKitUpdated, object: nil)
        }
        
        return hkMindfulness
    }
    
    class func editHKMindfulness(from mindfulness: Mindfulness) -> HKCategorySample? {
        guard let hkSampleID = mindfulness.hkSampleID, let uuid = UUID(uuidString: hkSampleID), let categoryType = HKCategoryType.categoryType(forIdentifier: .mindfulSession), let start = mindfulness.startDateTime, let end = mindfulness.endDateTime, let mindfulSessionType = HKObjectType.categoryType(forIdentifier: .mindfulSession), let currentUserID = Auth.auth().currentUser?.uid else {
            return nil
        }
        
        let ref = Database.database().reference()
        
        ref.child(userHealthEntity).child(currentUserID).child(healthkitMindfulnessKey).child(hkSampleID).child(identifierKey).removeValue()
                
        HealthKitService.deleteSample(sampleType: categoryType, uuid: uuid) { _,_ in }
        
        let hkMindfulness = HKCategorySample(type: mindfulSessionType, value: 0, start: start, end: end)
                
        ref.child(userHealthEntity).child(currentUserID).child(healthkitMindfulnessKey).child(hkMindfulness.uuid.uuidString).child(identifierKey).setValue(mindfulness.id)
        
        ref.child(userMindfulnessEntity).child(currentUserID).child(mindfulness.id).child(hkSampleIDKey).setValue(hkMindfulness.uuid.uuidString)
        
        HealthKitService.storeSample(sample: hkMindfulness) { (_, _) in
            NotificationCenter.default.post(name: .healthKitUpdated, object: nil)
        }
        
        return hkMindfulness
    }
    
    class func createHKNutritions(from meal: Meal) -> [HKQuantitySample]? {
        guard let start = meal.startDateTime, let end = meal.endDateTime else {
            return nil
        }
        
        var samples: [HKQuantitySample] = []
        
        if let dietaryEnergyConsumed = HKQuantityType.quantityType(forIdentifier: .dietaryEnergyConsumed), let nutrient = meal.nutrition?.nutrients?.first(where: {$0.name == "Calories"}), let cals = nutrient.amount {
            let calsQuantity = HKQuantity(unit: .jouleUnit(with: .kilo), doubleValue: cals)
            let calsSample = HKQuantitySample(type: dietaryEnergyConsumed, quantity: calsQuantity, start: start, end: end)
            samples.append(calsSample)
        }
        
        if let dietaryFatTotal = HKQuantityType.quantityType(forIdentifier: .dietaryFatTotal), let nutrient = meal.nutrition?.nutrients?.first(where: {$0.name == "Fat"}), let fats = nutrient.amount {
            let fatQuantity = HKQuantity(unit: .gram(), doubleValue: fats)
            let fatSample = HKQuantitySample(type: dietaryFatTotal, quantity: fatQuantity, start: start, end: end)
            samples.append(fatSample)
        }
        
        if let dietaryProtein = HKQuantityType.quantityType(forIdentifier: .dietaryProtein), let nutrient = meal.nutrition?.nutrients?.first(where: {$0.name == "Protein"}), let protien = nutrient.amount {
            let protienQuantity = HKQuantity(unit: .gram(), doubleValue: protien)
            let protienSample = HKQuantitySample(type: dietaryProtein, quantity: protienQuantity, start: start, end: end)
            samples.append(protienSample)
        }
        
        if let dietaryCarbohydrates = HKQuantityType.quantityType(forIdentifier: .dietaryCarbohydrates), let nutrient = meal.nutrition?.nutrients?.first(where: {$0.name == "Carbohydrates"}), let carbs = nutrient.amount {
            let quantity = HKQuantity(unit: .gram(), doubleValue: carbs)
            let sample = HKQuantitySample(type: dietaryCarbohydrates, quantity: quantity, start: start, end: end)
            samples.append(sample)
        }
        
        //sugar?
        if let dietarySugar = HKQuantityType.quantityType(forIdentifier: .dietarySugar), let nutrient = meal.nutrition?.nutrients?.first(where: {$0.name == "Sugar"}), let sugar = nutrient.amount {
            let quantity = HKQuantity(unit: .gram(), doubleValue: sugar)
            let sample = HKQuantitySample(type: dietarySugar, quantity: quantity, start: start, end: end)
            samples.append(sample)
        }
        
        return samples
    }
}
