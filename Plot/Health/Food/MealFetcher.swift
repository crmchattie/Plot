//
//  MealFetcher.swift
//  Plot
//
//  Created by Cory McHattie on 11/11/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import UIKit
import Firebase
import CodableFirebase

class MealFetcher: NSObject {
        
    fileprivate var userMealsDatabaseRef: DatabaseReference!
    fileprivate var currentUserMealsAddHandle = DatabaseHandle()
    fileprivate var currentUserMealsChangeHandle = DatabaseHandle()
    fileprivate var currentUserMealsRemoveHandle = DatabaseHandle()
    
    var mealsInitialAdd: (([Meal])->())?
    var mealsAdded: (([Meal])->())?
    var mealsRemoved: (([Meal])->())?
    var mealsChanged: (([Meal])->())?
        
    func observeMealForCurrentUser(mealsInitialAdd: @escaping ([Meal])->(), mealsAdded: @escaping ([Meal])->(), mealsRemoved: @escaping ([Meal])->(), mealsChanged: @escaping ([Meal])->()) {
        guard let currentUserID = Auth.auth().currentUser?.uid else {
            return
        }
                
        let ref = Database.database().reference()
        userMealsDatabaseRef = ref.child(userMealsEntity).child(currentUserID)
        
        self.mealsInitialAdd = mealsInitialAdd
        self.mealsAdded = mealsAdded
        self.mealsRemoved = mealsRemoved
        self.mealsChanged = mealsChanged
        
        var userMeals: [String: Meal] = [:]
        
        userMealsDatabaseRef.observeSingleEvent(of: .value, with: { snapshot in
            guard snapshot.exists() else {
                mealsInitialAdd([])
                return
            }
            
            if let completion = self.mealsInitialAdd {
                var meals: [Meal] = []
                let group = DispatchGroup()
                var counter = 0
                let mealIDs = snapshot.value as? [String: AnyObject] ?? [:]
                for (ID, userMealInfo) in mealIDs {
                    var handle = UInt.max
                    if let userMeal = try? FirebaseDecoder().decode(Meal.self, from: userMealInfo) {
                        userMeals[ID] = userMeal
                        group.enter()
                        counter += 1
                        handle = ref.child(mealsEntity).child(ID).observe(.value) { snapshot in
                            ref.removeObserver(withHandle: handle)
                            if snapshot.exists(), let snapshotValue = snapshot.value {
                                if let meal = try? FirebaseDecoder().decode(Meal.self, from: snapshotValue), let userMeal = userMeals[ID] {
                                    var _meal = meal
                                    _meal.amount = userMeal.amount
                                    _meal.nutrition = userMeal.nutrition
                                    _meal.badge = userMeal.badge
                                    _meal.muted = userMeal.muted
                                    _meal.pinned = userMeal.pinned
                                    if counter > 0 {
                                        meals.append(_meal)
                                        group.leave()
                                        counter -= 1
                                    } else {
                                        meals = [_meal]
                                        completion(meals)
                                    }
                                }
                            } else {
                                if counter > 0 {
                                    group.leave()
                                    counter -= 1
                                }
                            }
                        }
                    }
                }
                group.notify(queue: .main) {
                    completion(meals)
                }
            }
        })
        
        currentUserMealsAddHandle = userMealsDatabaseRef.observe(.childAdded, with: { snapshot in
            if userMeals[snapshot.key] == nil {
                if let completion = self.mealsAdded {
                    var handle = UInt.max
                    let ID = snapshot.key
                    self.getUserDataFromSnapshot(ID: ID) { mealsList in
                        for userMeal in mealsList {
                            userMeals[ID] = userMeal
                            handle = ref.child(activitiesEntity).child(ID).child(messageMetaDataFirebaseFolder).observe(.value) { snapshot in
                                ref.removeObserver(withHandle: handle)
                                if snapshot.exists(), let snapshotValue = snapshot.value {
                                    if let meal = try? FirebaseDecoder().decode(Meal.self, from: snapshotValue), let userMeal = userMeals[ID] {
                                        var _meal = meal
                                        _meal.amount = userMeal.amount
                                        _meal.nutrition = userMeal.nutrition
                                        _meal.badge = userMeal.badge
                                        _meal.muted = userMeal.muted
                                        _meal.pinned = userMeal.pinned
                                        completion([_meal])
                                    }
                                }
                            }
                        }
                    }
                }
            }
        })
        
        currentUserMealsChangeHandle = userMealsDatabaseRef.observe(.childChanged, with: { snapshot in
            if let completion = self.mealsChanged {
                MealFetcher.getDataFromSnapshot(ID: snapshot.key) { mealsList in
                    for meal in mealsList {
                        userMeals[meal.id] = meal
                    }
                    completion(mealsList)
                }
            }
        })
        
        currentUserMealsRemoveHandle = userMealsDatabaseRef.observe(.childRemoved, with: { snapshot in
            if let completion = self.mealsRemoved {
                userMeals[snapshot.key] = nil
                MealFetcher.getDataFromSnapshot(ID: snapshot.key, completion: completion)
            }
        })
        
    }
    
    class func getDataFromSnapshot(ID: String, completion: @escaping ([Meal])->()) {
        guard let currentUserID = Auth.auth().currentUser?.uid else {
            return
        }
        let ref = Database.database().reference()
        var meals: [Meal] = []
        let group = DispatchGroup()
        group.enter()
        ref.child(userMealsEntity).child(currentUserID).child(ID).observeSingleEvent(of: .value, with: { snapshot in
            if snapshot.exists(), let userMealInfo = snapshot.value {
                if let userMeal = try? FirebaseDecoder().decode(Meal.self, from: userMealInfo) {
                    ref.child(mealsEntity).child(ID).observeSingleEvent(of: .value, with: { mealSnapshot in
                        if mealSnapshot.exists(), let mealSnapshotValue = mealSnapshot.value {
                            if let meal = try? FirebaseDecoder().decode(Meal.self, from: mealSnapshotValue) {
                                var _meal = meal
                                _meal.amount = userMeal.amount
                                _meal.nutrition = userMeal.nutrition
                                _meal.badge = userMeal.badge
                                _meal.muted = userMeal.muted
                                _meal.pinned = userMeal.pinned
                                meals.append(_meal)
                            }
                        }
                        group.leave()
                    })
                }
            } else {
                ref.child(mealsEntity).child(ID).observeSingleEvent(of: .value, with: { mealSnapshot in
                    if mealSnapshot.exists(), let mealSnapshotValue = mealSnapshot.value {
                        if let meal = try? FirebaseDecoder().decode(Meal.self, from: mealSnapshotValue) {
                            meals.append(meal)
                        }
                    }
                    group.leave()
                })
            }
        })
        
        group.notify(queue: .main) {
            completion(meals)
        }
    }
    
    func getUserDataFromSnapshot(ID: String, completion: @escaping ([Meal])->()) {
        guard let currentUserID = Auth.auth().currentUser?.uid else {
            return
        }
        let ref = Database.database().reference()
        var meals: [Meal] = []
        let group = DispatchGroup()
        group.enter()
        ref.child(userMealsEntity).child(currentUserID).child(ID).observeSingleEvent(of: .value, with: { snapshot in
            if snapshot.exists(), let userMealInfo = snapshot.value {
                if let userMeal = try? FirebaseDecoder().decode(Meal.self, from: userMealInfo) {
                    meals.append(userMeal)
                    group.leave()
                }
            }
        })
        group.notify(queue: .main) {
            completion(meals)
        }
    }
}
