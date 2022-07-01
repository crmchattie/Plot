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
    
    
    var mealsAdded: (([Meal])->())?
    var mealsRemoved: (([Meal])->())?
    var mealsChanged: (([Meal])->())?
    
    fileprivate var isGroupAlreadyFinished = false
    
    func fetchMeals(completion: @escaping ([Meal])->()) {
        guard let currentUserID = Auth.auth().currentUser?.uid else {
            completion([])
            return
        }
                
        let ref = Database.database().reference()
        userMealsDatabaseRef = Database.database().reference().child(userMealsEntity).child(currentUserID)
        userMealsDatabaseRef.observeSingleEvent(of: .value, with: { snapshot in
            if snapshot.exists(), let mealIDs = snapshot.value as? [String: AnyObject] {
                var meals: [Meal] = []
                let group = DispatchGroup()
                for (mealID, userMealInfo) in mealIDs {
                    if let userMeal = try? FirebaseDecoder().decode(Meal.self, from: userMealInfo) {
                        group.enter()
                        ref.child(mealsEntity).child(mealID).observeSingleEvent(of: .value, with: { mealSnapshot in
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
                    } else {
                        group.enter()
                        ref.child(mealsEntity).child(mealID).observeSingleEvent(of: .value, with: { mealSnapshot in
                            if mealSnapshot.exists(), let mealSnapshotValue = mealSnapshot.value {
                                if let meal = try? FirebaseDecoder().decode(Meal.self, from: mealSnapshotValue) {
                                    meals.append(meal)
                                }
                            }
                            group.leave()
                        })
                    }
                }
                group.notify(queue: .main) {
                    completion(meals)
                }
            } else {
                completion([])
            }
        })
    }
    
    func observeMealForCurrentUser(mealsAdded: @escaping ([Meal])->(), mealsRemoved: @escaping ([Meal])->(), mealsChanged: @escaping ([Meal])->()) {
        guard let _ = Auth.auth().currentUser?.uid else {
            return
        }
        self.mealsAdded = mealsAdded
        self.mealsRemoved = mealsRemoved
        self.mealsChanged = mealsChanged
        currentUserMealsAddHandle = userMealsDatabaseRef.observe(.childAdded, with: { snapshot in
            if let completion = self.mealsAdded {
                let mealID = snapshot.key
                let ref = Database.database().reference()
                var handle = UInt.max
                handle = ref.child(mealsEntity).child(mealID).observe(.childChanged) { _ in
                    ref.removeObserver(withHandle: handle)
                    self.getMealsFromSnapshot(snapshot: snapshot, completion: completion)
                }
            }
        })
        
        currentUserMealsChangeHandle = userMealsDatabaseRef.observe(.childChanged, with: { snapshot in
            if let completion = self.mealsChanged {
                self.getMealsFromSnapshot(snapshot: snapshot, completion: completion)
            }
        })
        
        currentUserMealsRemoveHandle = userMealsDatabaseRef.observe(.childRemoved, with: { snapshot in
            if let completion = self.mealsRemoved {
                self.getMealsFromSnapshot(snapshot: snapshot, completion: completion)
            }
        })
        
    }
    
    func getMealsFromSnapshot(snapshot: DataSnapshot, completion: @escaping ([Meal])->()) {
        if snapshot.exists() {
            guard let currentUserID = Auth.auth().currentUser?.uid else {
                return
            }
            let mealID = snapshot.key
            let ref = Database.database().reference()
            var meals: [Meal] = []
            let group = DispatchGroup()
            group.enter()
            ref.child(userMealsEntity).child(currentUserID).child(mealID).observeSingleEvent(of: .value, with: { snapshot in
                if snapshot.exists(), let userMealInfo = snapshot.value {
                    if let userMeal = try? FirebaseDecoder().decode(Meal.self, from: userMealInfo) {
                        ref.child(mealsEntity).child(mealID).observeSingleEvent(of: .value, with: { mealSnapshot in
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
                    ref.child(mealsEntity).child(mealID).observeSingleEvent(of: .value, with: { mealSnapshot in
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
        } else {
            completion([])
        }
    }
}
