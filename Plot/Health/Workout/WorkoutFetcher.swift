//
//  WorkoutFetcher.swift
//  Plot
//
//  Created by Cory McHattie on 11/11/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import UIKit
import Firebase
import CodableFirebase

class WorkoutFetcher: NSObject {
        
    fileprivate var userWorkoutsDatabaseRef: DatabaseReference!
    fileprivate var currentUserWorkoutsAddHandle = DatabaseHandle()
    fileprivate var currentUserWorkoutsChangeHandle = DatabaseHandle()
    fileprivate var currentUserWorkoutsRemoveHandle = DatabaseHandle()
    
    var workoutsInitialAdd: (([Workout])->())?
    var workoutsAdded: (([Workout])->())?
    var workoutsRemoved: (([Workout])->())?
    var workoutsChanged: (([Workout])->())?
        
    func observeWorkoutForCurrentUser(workoutsInitialAdd: @escaping ([Workout])->(), workoutsAdded: @escaping ([Workout])->(), workoutsRemoved: @escaping ([Workout])->(), workoutsChanged: @escaping ([Workout])->()) {
        guard let currentUserID = Auth.auth().currentUser?.uid else {
            return
        }
                
        let ref = Database.database().reference()
        userWorkoutsDatabaseRef = ref.child(userWorkoutsEntity).child(currentUserID)
        
        self.workoutsInitialAdd = workoutsInitialAdd
        self.workoutsAdded = workoutsAdded
        self.workoutsRemoved = workoutsRemoved
        self.workoutsChanged = workoutsChanged
        
        var userWorkouts: [String: UserWorkout] = [:]
        
        userWorkoutsDatabaseRef.observeSingleEvent(of: .value, with: { snapshot in
            guard snapshot.exists() else {
                workoutsInitialAdd([])
                return
            }
            
            if let completion = self.workoutsInitialAdd {
                var workouts: [Workout] = []
                let group = DispatchGroup()
                var counter = 0
                let workoutIDs = snapshot.value as? [String: AnyObject] ?? [:]
                for (ID, userWorkoutInfo) in workoutIDs {
                    var handle = UInt.max
                    if let userWorkout = try? FirebaseDecoder().decode(UserWorkout.self, from: userWorkoutInfo) {
                        userWorkouts[ID] = userWorkout
                        group.enter()
                        counter += 1
                        handle = ref.child(workoutsEntity).child(ID).observe(.value) { snapshot in
                            ref.removeObserver(withHandle: handle)
                            if snapshot.exists(), let snapshotValue = snapshot.value {
                                if let workout = try? FirebaseDecoder().decode(Workout.self, from: snapshotValue), let userWorkout = userWorkouts[ID] {
                                    var _workout = workout
                                    _workout.hkSampleID = userWorkout.hkSampleID
                                    _workout.totalEnergyBurned = userWorkout.totalEnergyBurned
                                    _workout.badge = userWorkout.badge
                                    _workout.muted = userWorkout.muted
                                    _workout.pinned = userWorkout.pinned
                                    if counter > 0 {
                                        workouts.append(_workout)
                                        group.leave()
                                        counter -= 1
                                    } else {
                                        workouts = [_workout]
                                        completion(workouts)
                                        return
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
                    completion(workouts)
                }
            }
        })
        
        currentUserWorkoutsAddHandle = userWorkoutsDatabaseRef.observe(.childAdded, with: { snapshot in
            if userWorkouts[snapshot.key] == nil {
                if let completion = self.workoutsAdded {
                    var handle = UInt.max
                    let ID = snapshot.key
                    self.getUserDataFromSnapshot(ID: ID) { workoutsList in
                        for userWorkout in workoutsList {
                            userWorkouts[ID] = userWorkout
                            handle = ref.child(workoutsEntity).child(ID).observe(.value) { snapshot in
                                ref.removeObserver(withHandle: handle)
                                if snapshot.exists(), let snapshotValue = snapshot.value {
                                    if let workout = try? FirebaseDecoder().decode(Workout.self, from: snapshotValue), let userWorkout = userWorkouts[ID] {
                                        var _workout = workout
                                        _workout.hkSampleID = userWorkout.hkSampleID
                                        _workout.totalEnergyBurned = userWorkout.totalEnergyBurned
                                        _workout.badge = userWorkout.badge
                                        _workout.muted = userWorkout.muted
                                        _workout.pinned = userWorkout.pinned
                                        completion([_workout])
                                    }
                                }
                            }
                        }
                    }
                }
            }
        })
        
        currentUserWorkoutsChangeHandle = userWorkoutsDatabaseRef.observe(.childChanged, with: { snapshot in
            if let completion = self.workoutsChanged {
                WorkoutFetcher.getDataFromSnapshot(ID: snapshot.key) { workoutsList in
                    for workout in workoutsList {
                        userWorkouts[workout.id] = UserWorkout(workout: workout)
                    }
                    completion(workoutsList)
                }
            }
        })
        
        currentUserWorkoutsRemoveHandle = userWorkoutsDatabaseRef.observe(.childRemoved, with: { snapshot in
            if let completion = self.workoutsRemoved {
                userWorkouts[snapshot.key] = nil
                WorkoutFetcher.getDataFromSnapshot(ID: snapshot.key, completion: completion)
            }
        })
        
    }
    

    
    class func getDataFromSnapshot(ID: String, completion: @escaping ([Workout])->()) {
        guard let currentUserID = Auth.auth().currentUser?.uid else {
            return
        }
        let ref = Database.database().reference()
        var workouts: [Workout] = []
        let group = DispatchGroup()
        group.enter()
        ref.child(userWorkoutsEntity).child(currentUserID).child(ID).observeSingleEvent(of: .value, with: { snapshot in
            if snapshot.exists(), let userWorkoutInfo = snapshot.value {
                if let userWorkout = try? FirebaseDecoder().decode(UserWorkout.self, from: userWorkoutInfo) {
                    ref.child(workoutsEntity).child(ID).observeSingleEvent(of: .value, with: { workoutSnapshot in
                        if workoutSnapshot.exists(), let workoutSnapshotValue = workoutSnapshot.value {
                            if let workout = try? FirebaseDecoder().decode(Workout.self, from: workoutSnapshotValue) {
                                var _workout = workout
                                _workout.hkSampleID = userWorkout.hkSampleID
                                _workout.totalEnergyBurned = userWorkout.totalEnergyBurned
                                _workout.badge = userWorkout.badge
                                _workout.muted = userWorkout.muted
                                _workout.pinned = userWorkout.pinned
                                workouts.append(_workout)
                            }
                        }
                        group.leave()
                    })
                }
            } else {
                ref.child(workoutsEntity).child(ID).observeSingleEvent(of: .value, with: { workoutSnapshot in
                    if workoutSnapshot.exists(), let workoutSnapshotValue = workoutSnapshot.value {
                        if let workout = try? FirebaseDecoder().decode(Workout.self, from: workoutSnapshotValue) {
                            workouts.append(workout)
                        }
                    }
                    group.leave()
                })
            }
        })
        
        group.notify(queue: .main) {
            completion(workouts)
        }
    }
    
    func getUserDataFromSnapshot(ID: String, completion: @escaping ([UserWorkout])->()) {
        guard let currentUserID = Auth.auth().currentUser?.uid else {
            return
        }
        let ref = Database.database().reference()
        var workouts: [UserWorkout] = []
        let group = DispatchGroup()
        group.enter()
        ref.child(userWorkoutsEntity).child(currentUserID).child(ID).observeSingleEvent(of: .value, with: { snapshot in
            if snapshot.exists(), let userWorkoutInfo = snapshot.value {
                if let userWorkout = try? FirebaseDecoder().decode(UserWorkout.self, from: userWorkoutInfo) {
                    workouts.append(userWorkout)
                    group.leave()
                }
            }
        })
        group.notify(queue: .main) {
            completion(workouts)
        }
    }
}
