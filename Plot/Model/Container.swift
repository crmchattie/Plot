//
//  Container.swift
//  Plot
//
//  Created by Cory McHattie on 8/8/22.
//  Copyright © 2022 Immature Creations. All rights reserved.
//

import Foundation
import Firebase
import CodableFirebase

let containerEntity = "container"
let containerIDEntity = "containerID"

struct Container: Codable, Equatable, Hashable {
    static func == (lhs: Container, rhs: Container) -> Bool {
        return lhs.id == rhs.id
    }
    
    var id: String
    var activityIDs: [String]?
    var taskIDs: [String]?
    var workoutIDs: [String]?
    var mindfulnessIDs: [String]?
    var mealIDs: [String]?
    var transactionIDs: [String]?
    var participantsIDs: [String]?
    
    init(id: String, activityIDs: [String]?, taskIDs: [String]?, workoutIDs: [String]?, mindfulnessIDs: [String]?, mealIDs: [String]?, transactionIDs: [String]?) {
        self.id = id
        self.activityIDs = activityIDs
        self.taskIDs = taskIDs
        self.workoutIDs = workoutIDs
        self.mindfulnessIDs = mindfulnessIDs
        self.mealIDs = mealIDs
        self.transactionIDs = transactionIDs
    }
}

class ContainerFunctions {
    class func updateContainerAndStuffInside(container: Container) {
        guard let currentUserId = Auth.auth().currentUser?.uid else {return}
        let reference = Database.database().reference()
        do {
            let value = try FirebaseEncoder().encode(container)
            reference.child(containerEntity).child(container.id).setValue(value)
        } catch let error {
            print(error)
        }
        for ID in container.activityIDs ?? [] {
            reference.child(activitiesEntity).child(ID).child(messageMetaDataFirebaseFolder).child(containerIDEntity).setValue(container.id)
        }
        for ID in container.taskIDs ?? [] {
            reference.child(activitiesEntity).child(ID).child(messageMetaDataFirebaseFolder).child(containerIDEntity).setValue(container.id)
        }
        for ID in container.transactionIDs ?? [] {
            reference.child(financialTransactionsEntity).child(ID).child(containerIDEntity).setValue(container.id)
        }
        for ID in container.workoutIDs ?? [] {
            reference.child(userHealthEntity).child(currentUserId).child(healthkitWorkoutsKey).child(ID).child(containerIDEntity).setValue(container.id)
        }
        for ID in container.mindfulnessIDs ?? [] {
            reference.child(userHealthEntity).child(currentUserId).child(healthkitMindfulnessKey).child(ID).child(containerIDEntity).setValue(container.id)
        }
    }
    
    class func grabContainerAndStuffInside(id: String, completion: @escaping (Container, [Activity]?, [Activity]?, [HealthContainer]?, [Transaction]?) -> Void) {
        var container = Container(id: id, activityIDs: nil, taskIDs: nil, workoutIDs: nil, mindfulnessIDs: nil, mealIDs: nil, transactionIDs: nil)
        var activities = [Activity]()
        var tasks = [Activity]()
        var healths = [HealthContainer]()
        var transactions = [Transaction]()
        
        let dispatchGroup = DispatchGroup()
        dispatchGroup.enter()
        let dataReference = Database.database().reference().child(containerEntity).child(id)
        dataReference.observeSingleEvent(of: .value, with: { (snapshot) in
            if snapshot.exists(), let snapshotValue = snapshot.value, let contain = try? FirebaseDecoder().decode(Container.self, from: snapshotValue) {
                container = contain
                for activityID in container.activityIDs ?? [] {
                    dispatchGroup.enter()
                    let dataReference = Database.database().reference().child(activitiesEntity).child(activityID).child(messageMetaDataFirebaseFolder)
                    dataReference.observeSingleEvent(of: .value, with: { (snapshot) in
                        if snapshot.exists(), let snapshotValue = snapshot.value as? [String: AnyObject] {
                            let activity = Activity(dictionary: snapshotValue)
                            activities.append(activity)

                        }
                        dispatchGroup.leave()
                    })
                }
                for taskID in container.taskIDs ?? [] {
                    dispatchGroup.enter()
                    let dataReference = Database.database().reference().child(activitiesEntity).child(taskID).child(messageMetaDataFirebaseFolder)
                    dataReference.observeSingleEvent(of: .value, with: { (snapshot) in
                        if snapshot.exists(), let snapshotValue = snapshot.value as? [String: AnyObject] {
                            let task = Activity(dictionary: snapshotValue)
                            tasks.append(task)
                        }
                        dispatchGroup.leave()
                    })
                }
                for transactionID in container.transactionIDs ?? [] {
                    dispatchGroup.enter()
                    let dataReference = Database.database().reference().child(financialTransactionsEntity).child(transactionID)
                    dataReference.observeSingleEvent(of: .value, with: { (snapshot) in
                        if snapshot.exists(), let snapshotValue = snapshot.value {
                            if let transaction = try? FirebaseDecoder().decode(Transaction.self, from: snapshotValue) {
                                transactions.append(transaction)
                            }
                        }
                        dispatchGroup.leave()
                    })
                }
                for workoutID in container.workoutIDs ?? [] {
                    dispatchGroup.enter()
                    if let uuid = UUID(uuidString: workoutID) {
                        HealthKitService.grabSpecificWorkoutSample(uuid: uuid) { samples, err in
                            if let sample = samples?.first {
                                HealthKitSampleBuilder.createWorkoutFromHKWorkout(from: sample) { workout in
                                    guard workout != nil else {
                                        dispatchGroup.leave()
                                        return }
                                    var health = HealthContainer()
                                    health.workout = workout
                                    healths.append(health)
                                    dispatchGroup.leave()
                                }
                            }
                        }
                    }
                }
                for mindfulnessID in container.mindfulnessIDs ?? [] {
                    dispatchGroup.enter()
                    if let uuid = UUID(uuidString: mindfulnessID) {
                        HealthKitService.grabSpecificCategorySample(uuid: uuid, identifier: .mindfulSession) { samples, err in
                            if let sample = samples?.first {
                                HealthKitSampleBuilder.createMindfulnessFromHKMindfulness(from: sample) { mindfulness in
                                    guard mindfulness != nil else {
                                        dispatchGroup.leave()
                                        return }
                                    var health = HealthContainer()
                                    health.mindfulness = mindfulness
                                    healths.append(health)
                                    dispatchGroup.leave()
                                }
                            }
                        }
                    }
                }
            }
            dispatchGroup.leave()
        })
        
        dispatchGroup.notify(queue: .main) {
            completion(container, activities, tasks, healths, transactions)
        }
    }
}
