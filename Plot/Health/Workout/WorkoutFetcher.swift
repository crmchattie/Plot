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
    
    var userWorkouts: [String: UserWorkout] = [:]
    var unloadedWorkouts: [String: UserWorkout] = [:]
    
    var handles = [String: UInt]()
        
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
                        self.userWorkouts[ID] = userWorkout
                        
                        guard let startDateTime = userWorkout.startDateTime, startDateTime > Date().addMonths(-2) else {
                            self.unloadedWorkouts[ID] = userWorkout
                            continue
                        }
                        
                        group.enter()
                        counter += 1
                        handle = ref.child(workoutsEntity).child(ID).observe(.value) { snapshot in
                            ref.removeObserver(withHandle: handle)
                            if snapshot.exists(), let snapshotValue = snapshot.value {
                                if let workout = try? FirebaseDecoder().decode(Workout.self, from: snapshotValue), let userWorkout = self.userWorkouts[ID] {
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
            if self.userWorkouts[snapshot.key] == nil {
                if let completion = self.workoutsAdded {
                    var handle = UInt.max
                    let ID = snapshot.key
                    self.getUserDataFromSnapshot(ID: ID) { workoutsList in
                        for userWorkout in workoutsList {
                            self.userWorkouts[ID] = userWorkout
                            handle = ref.child(workoutsEntity).child(ID).observe(.value) { snapshot in
                                ref.removeObserver(withHandle: handle)
                                if snapshot.exists(), let snapshotValue = snapshot.value {
                                    if let workout = try? FirebaseDecoder().decode(Workout.self, from: snapshotValue), let userWorkout = self.userWorkouts[ID] {
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
                        self.userWorkouts[workout.id] = UserWorkout(workout: workout)
                    }
                    completion(workoutsList)
                }
            }
        })
        
        currentUserWorkoutsRemoveHandle = userWorkoutsDatabaseRef.observe(.childRemoved, with: { snapshot in
            if let completion = self.workoutsRemoved {
                self.userWorkouts[snapshot.key] = nil
                self.unloadedWorkouts[snapshot.key] = nil
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
    
    func getDataFromSnapshotWObserver(ID: String, completion: @escaping ([Workout])->()) {
        let ref = Database.database().reference()
        var handle = UInt.max
        handle = ref.child(workoutsEntity).child(ID).observe(.value) { snapshot in
            self.handles[ID] = handle
            if snapshot.exists(), let snapshotValue = snapshot.value {
                if let workout = try? FirebaseDecoder().decode(Workout.self, from: snapshotValue), let userWorkout = self.userWorkouts[ID] {
                    var _workout = workout
                    _workout.hkSampleID = userWorkout.hkSampleID
                    _workout.totalEnergyBurned = userWorkout.totalEnergyBurned
                    _workout.badge = userWorkout.badge
                    _workout.muted = userWorkout.muted
                    _workout.pinned = userWorkout.pinned
                    completion([_workout])
                } else {
                    completion([])
                }
            } else {
                completion([])
            }
        }
    }
    
    func removeObservers() {
        let ref = Database.database().reference()
        for (ID, handle) in handles {
            ref.child(workoutsEntity).child(ID).removeObserver(withHandle: handle)
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
    
    func loadUnloadedWorkouts(startDate: Date?, endDate: Date?, completion: @escaping ([Workout])->()) {
        let group = DispatchGroup()
        var counter = 0
        var workouts: [Workout] = []
        if let startDate = startDate, let endDate = endDate {
            let IDs = unloadedWorkouts.filter {
                $0.value.startDateTime ?? Date.distantPast > startDate &&
                $0.value.startDateTime ?? Date.distantFuture < endDate
            }
            for (ID, _) in IDs {
                group.enter()
                counter += 1
                self.getDataFromSnapshotWObserver(ID: ID) { workoutList in
                    if counter > 0 {
                        workouts.append(contentsOf: workoutList)
                        group.leave()
                        counter -= 1
                    } else {
                        completion(workoutList)
                    }
                }
            }
            group.notify(queue: .main) {
                workouts.sort(by: {
                    $0.startDateTime ?? Date.distantPast > $1.startDateTime ?? Date.distantPast
                })
                completion(workouts)
            }
        } else {
            for (ID, _) in unloadedWorkouts {
                group.enter()
                counter += 1
                self.getDataFromSnapshotWObserver(ID: ID) { workoutList in
                    if counter > 0 {
                        workouts.append(contentsOf: workoutList)
                        group.leave()
                        counter -= 1
                    } else {
                        completion(workoutList)
                    }
                }
            }
            group.notify(queue: .main) {
                workouts.sort(by: {
                    $0.startDateTime ?? Date.distantPast > $1.startDateTime ?? Date.distantPast
                })
                completion(workouts)
            }
        }
    }
}
