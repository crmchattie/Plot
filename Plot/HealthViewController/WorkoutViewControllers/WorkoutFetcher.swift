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
    
    
    var workoutsAdded: (([Workout])->())?
    var workoutsRemoved: (([Workout])->())?
    var workoutsChanged: (([Workout])->())?
    
    fileprivate var isGroupAlreadyFinished = false
    
    func fetchWorkouts(completion: @escaping ([Workout])->()) {
        guard let currentUserID = Auth.auth().currentUser?.uid else {
            completion([])
            return
        }
                
        let ref = Database.database().reference()
        userWorkoutsDatabaseRef = Database.database().reference().child(userWorkoutsEntity).child(currentUserID)
        userWorkoutsDatabaseRef.observeSingleEvent(of: .value, with: { snapshot in
            if snapshot.exists(), let workoutIDs = snapshot.value as? [String: AnyObject] {
                var workouts: [Workout] = []
                let group = DispatchGroup()
                for (workoutID, userWorkoutInfo) in workoutIDs {
                    if let userWorkout = try? FirebaseDecoder().decode(Workout.self, from: userWorkoutInfo) {
                        group.enter()
                        ref.child(workoutsEntity).child(workoutID).observeSingleEvent(of: .value, with: { workoutSnapshot in
                            if workoutSnapshot.exists(), let workoutSnapshotValue = workoutSnapshot.value {
                                if let workout = try? FirebaseDecoder().decode(Workout.self, from: workoutSnapshotValue) {
                                    var _workout = workout
                                    _workout.badge = userWorkout.badge
                                    _workout.muted = userWorkout.muted
                                    _workout.pinned = userWorkout.pinned
                                    workouts.append(_workout)
                                }
                            }
                            group.leave()
                        })
                    } else {
                        group.enter()
                        ref.child(workoutsEntity).child(workoutID).observeSingleEvent(of: .value, with: { workoutSnapshot in
                            if workoutSnapshot.exists(), let workoutSnapshotValue = workoutSnapshot.value {
                                if let workout = try? FirebaseDecoder().decode(Workout.self, from: workoutSnapshotValue) {
                                    workouts.append(workout)
                                }
                            }
                            group.leave()
                        })
                    }
                }
                group.notify(queue: .main) {
                    completion(workouts)
                }
            } else {
                completion([])
            }
        })
    }
    
    func observeWorkoutForCurrentUser(workoutsAdded: @escaping ([Workout])->(), workoutsRemoved: @escaping ([Workout])->(), workoutsChanged: @escaping ([Workout])->()) {
        guard let _ = Auth.auth().currentUser?.uid else {
            return
        }
        self.workoutsAdded = workoutsAdded
        self.workoutsRemoved = workoutsRemoved
        self.workoutsChanged = workoutsChanged
        currentUserWorkoutsAddHandle = userWorkoutsDatabaseRef.observe(.childAdded, with: { snapshot in
            if let completion = self.workoutsAdded {
                let workoutID = snapshot.key
                let ref = Database.database().reference()
                var handle = UInt.max
                handle = ref.child(workoutsEntity).child(workoutID).observe(.childChanged) { _ in
                    ref.removeObserver(withHandle: handle)
                    self.getWorkoutsFromSnapshot(snapshot: snapshot, completion: completion)
                }
            }
        })
        
        currentUserWorkoutsChangeHandle = userWorkoutsDatabaseRef.observe(.childChanged, with: { snapshot in
            if let completion = self.workoutsChanged {
                self.getWorkoutsFromSnapshot(snapshot: snapshot, completion: completion)
            }
        })
        
        currentUserWorkoutsRemoveHandle = userWorkoutsDatabaseRef.observe(.childRemoved, with: { snapshot in
            if let completion = self.workoutsRemoved {
                self.getWorkoutsFromSnapshot(snapshot: snapshot, completion: completion)
            }
        })
        
    }
    
    func getWorkoutsFromSnapshot(snapshot: DataSnapshot, completion: @escaping ([Workout])->()) {
        if snapshot.exists() {
            guard let currentUserID = Auth.auth().currentUser?.uid else {
                return
            }
            let workoutID = snapshot.key
            let ref = Database.database().reference()
            var workouts: [Workout] = []
            let group = DispatchGroup()
            group.enter()
            ref.child(userWorkoutsEntity).child(currentUserID).child(workoutID).observeSingleEvent(of: .value, with: { snapshot in
                if snapshot.exists(), let userWorkoutInfo = snapshot.value {
                    if let userWorkout = try? FirebaseDecoder().decode(Workout.self, from: userWorkoutInfo) {
                        ref.child(workoutsEntity).child(workoutID).observeSingleEvent(of: .value, with: { workoutSnapshot in
                            if workoutSnapshot.exists(), let workoutSnapshotValue = workoutSnapshot.value {
                                if let workout = try? FirebaseDecoder().decode(Workout.self, from: workoutSnapshotValue) {
                                    var _workout = workout
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
                    ref.child(workoutsEntity).child(workoutID).observeSingleEvent(of: .value, with: { workoutSnapshot in
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
        } else {
            completion([])
        }
    }
}
