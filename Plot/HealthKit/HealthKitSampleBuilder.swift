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
    
    class func createWorkoutFromHKWorkout(from hkWorkout: HKWorkout, completion: @escaping (Workout?)->()) {
        var workout: Workout!
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            return completion(workout)
        }
        
        workout = Workout(from: hkWorkout)
        let hkSampleID = hkWorkout.uuid.uuidString
        let healthkitWorkoutsReference = Database.database().reference().child(userHealthEntity).child(currentUserId).child(healthkitWorkoutsKey).child(hkSampleID).child(containerIDEntity)
        healthkitWorkoutsReference.observeSingleEvent(of: .value) { snapshot in
            if snapshot.exists(), let ID = snapshot.value as? String {
                workout.containerID = ID
                completion(workout)
            } else {
                completion(workout)
            }
        }
    }
    
    class func createHKMindfulness(from mindfulness: Mindfulness) -> HKCategorySample? {
        guard let start = mindfulness.startDateTime, let end = mindfulness.endDateTime, let mindfulSessionType = HKObjectType.categoryType(forIdentifier: .mindfulSession) else {
            return nil
        }
        
        let hkMindfulness = HKCategorySample(type: mindfulSessionType, value: 0, start: start, end: end)
        return hkMindfulness
    }
    
    class func createMindfulnessFromHKMindfulness(from hkMindfulness: HKCategorySample, completion: @escaping (Mindfulness?)->()) {
        var mindfulness: Mindfulness!
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            return completion(mindfulness)
        }
        
        mindfulness = Mindfulness(from: hkMindfulness)
        let hkSampleID = hkMindfulness.uuid.uuidString
        let healthkitWorkoutsReference = Database.database().reference().child(userHealthEntity).child(currentUserId).child(healthkitWorkoutsKey).child(hkSampleID).child(containerIDEntity)
        healthkitWorkoutsReference.observeSingleEvent(of: .value) { snapshot in
            if snapshot.exists(), let ID = snapshot.value as? String {
                mindfulness.containerID = ID
                completion(mindfulness)
            } else {
                completion(mindfulness)
            }
        }
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
