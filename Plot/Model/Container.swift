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
    var transactionIDs: [String]?
    var mealIDs: [String]?
    var participantsIDs: [String]?
    
    init(id: String, activityIDs: [String]?, taskIDs: [String]?, workoutIDs: [String]?, mindfulnessIDs: [String]?, mealIDs: [String]?, transactionIDs: [String]?, participantsIDs: [String]?) {
        self.id = id
        self.activityIDs = activityIDs
        self.taskIDs = taskIDs
        self.workoutIDs = workoutIDs
        self.mindfulnessIDs = mindfulnessIDs
        self.mealIDs = mealIDs
        self.transactionIDs = transactionIDs
        self.participantsIDs = participantsIDs
    }
}

class ContainerFunctions {
    class func updateContainerAndStuffInside(container: Container) {
        guard let _ = Auth.auth().currentUser?.uid else {return}
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
            reference.child(workoutsEntity).child(ID).child(containerIDEntity).setValue(container.id)
        }
        for ID in container.mindfulnessIDs ?? [] {
            reference.child(mindfulnessEntity).child(ID).child(containerIDEntity).setValue(container.id)
        }
    }
    
    class func updateParticipants(containerID: String, selectedFalconUsers: [User]) {
        guard let currentUserID = Auth.auth().currentUser?.uid else {return}
        let dataReference = Database.database().reference().child(containerEntity).child(containerID)
        dataReference.observeSingleEvent(of: .value, with: { (snapshot) in
            if snapshot.exists(), let snapshotValue = snapshot.value, let container = try? FirebaseDecoder().decode(Container.self, from: snapshotValue) {
                var membersIDs = [String]()
                membersIDs.append(currentUserID)
                for selectedUser in selectedFalconUsers {
                    guard let id = selectedUser.id else { continue }
                    membersIDs.append(id)
                }
                let reference = Database.database().reference()
                reference.child(containerEntity).child(container.id).updateChildValues(["participantsIDs": membersIDs.sorted() as AnyObject])
                
                for activityID in container.activityIDs ?? [] {
                    ActivitiesFetcher.getDataFromSnapshot(ID: activityID, parentID: nil) { fetched in
                        if let fetch = fetched.first {
                            let create = ActivityActions(activity: fetch, active: true, selectedFalconUsers: selectedFalconUsers)
                            create.updateActivityParticipants()
                        }
                    }
                }
                for taskID in container.taskIDs ?? [] {
                    ActivitiesFetcher.getDataFromSnapshot(ID: taskID, parentID: nil) { fetched in
                        if let fetch = fetched.first {
                            let create = ActivityActions(activity: fetch, active: true, selectedFalconUsers: selectedFalconUsers)
                            create.updateActivityParticipants()
                        }
                    }
                }
                for transactionID in container.transactionIDs ?? [] {
                    FinancialTransactionFetcher.getDataFromSnapshot(ID: transactionID) { fetched in
                        if let fetch = fetched.first {
                            let create = TransactionActions(transaction: fetch, active: true, selectedFalconUsers: selectedFalconUsers)
                            create.updateTransactionParticipants()
                        }
                    }
                }
                
                for workoutID in container.workoutIDs ?? [] {
                    WorkoutFetcher.getDataFromSnapshot(ID: workoutID) { fetched in
                        if let fetch = fetched.first {
                            let create = WorkoutActions(workout: fetch, active: true, selectedFalconUsers: selectedFalconUsers)
                            create.updateWorkoutParticipants()
                        }
                    }
                }
                for mindfulnessID in container.mindfulnessIDs ?? [] {
                    MindfulnessFetcher.getDataFromSnapshot(ID: mindfulnessID) { fetched in
                        if let fetch = fetched.first {
                            let create = MindfulnessActions(mindfulness: fetch, active: true, selectedFalconUsers: selectedFalconUsers)
                            create.updateMindfulnessParticipants()
                        }
                    }
                }
            }
        })
    }
    
    class func grabContainerAndStuffInside(id: String, completion: @escaping (Container, [Activity]?, [Activity]?, [HealthContainer]?, [Transaction]?) -> Void) {
        let isodateFormatter = ISO8601DateFormatter()
        var container = Container(id: id, activityIDs: nil, taskIDs: nil, workoutIDs: nil, mindfulnessIDs: nil, mealIDs: nil, transactionIDs: nil, participantsIDs: nil)
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
                    ActivitiesFetcher.getDataFromSnapshot(ID: activityID, parentID: nil) { fetched in
                        activities.append(contentsOf: fetched)
                        dispatchGroup.leave()
                    }
                }
                for taskID in container.taskIDs ?? [] {
                    dispatchGroup.enter()
                    ActivitiesFetcher.getDataFromSnapshot(ID: taskID, parentID: nil) { fetched in
                        tasks.append(contentsOf: fetched)
                        dispatchGroup.leave()
                    }
                }
                for transactionID in container.transactionIDs ?? [] {
                    dispatchGroup.enter()
                    FinancialTransactionFetcher.getDataFromSnapshot(ID: transactionID) { fetched in
                        transactions.append(contentsOf: fetched)
                        dispatchGroup.leave()
                    }
                }
                
                for workoutID in container.workoutIDs ?? [] {
                    dispatchGroup.enter()
                    WorkoutFetcher.getDataFromSnapshot(ID: workoutID) { fetched in
                        if let workout = fetched.first {
                            var health = HealthContainer()
                            health.workout = workout
                            healths.append(health)
                            dispatchGroup.leave()
                        }
                    }
                }
                for mindfulnessID in container.mindfulnessIDs ?? [] {
                    dispatchGroup.enter()
                    MindfulnessFetcher.getDataFromSnapshot(ID: mindfulnessID) { fetched in
                        if let mindfulness = fetched.first {
                            var health = HealthContainer()
                            health.mindfulness = mindfulness
                            healths.append(health)
                            dispatchGroup.leave()
                        }
                    }
                }
            }
            dispatchGroup.leave()
        })
        
        dispatchGroup.notify(queue: .main) {
            activities.sort { (schedule1, schedule2) -> Bool in
                return schedule1.startDateTime?.int64Value ?? 0 < schedule2.startDateTime?.int64Value ?? 0
            }
            tasks.sort { (task1, task2) -> Bool in
                if !(task1.isCompleted ?? false) && !(task2.isCompleted ?? false) {
                    if task1.endDate ?? Date.distantFuture == task2.endDate ?? Date.distantFuture {
                        if task1.priority == task2.priority {
                            return task1.name ?? "" < task2.name ?? ""
                        }
                        return TaskPriority(rawValue: task1.priority ?? "None")! > TaskPriority(rawValue: task2.priority ?? "None")!
                    }
                    return task1.endDate ?? Date.distantFuture < task2.endDate ?? Date.distantFuture
                } else if task1.isCompleted ?? false && task2.isCompleted ?? false {
                    if task1.completedDate ?? 0 == task2.completedDate ?? 0 {
                        return task1.name ?? "" < task2.name ?? ""
                    }
                    return Int(truncating: task1.completedDate ?? 0) > Int(truncating: task2.completedDate ?? 0)
                }
                return !(task1.isCompleted ?? false)
            }
            healths.sort { (health1, health2) -> Bool in
                return health1.date < health2.date
            }
            transactions.sort { (transaction1, transaction2) -> Bool in
                if transaction1.should_link ?? true == transaction2.should_link ?? true {
                    if let date1 = isodateFormatter.date(from: transaction1.transacted_at), let date2 = isodateFormatter.date(from: transaction2.transacted_at) {
                        return date1 > date2
                    }
                    return transaction1.description < transaction2.description
                }
                return transaction1.should_link ?? true && !(transaction2.should_link ?? true)
            }
            completion(container, activities, tasks, healths, transactions)
        }
    }
    
    class func deleteStuffInside(type: ContainerType, ID: String) {
        guard let _ = Auth.auth().currentUser?.uid else {return}
        let reference = Database.database().reference()
        switch type {
        case .activity:
            reference.child(activitiesEntity).child(ID).child(messageMetaDataFirebaseFolder).child(containerIDEntity).removeValue()
        case .task:
            reference.child(activitiesEntity).child(ID).child(messageMetaDataFirebaseFolder).child(containerIDEntity).removeValue()
        case .transaction:
            reference.child(financialTransactionsEntity).child(ID).child(containerIDEntity).removeValue()
        case .workout:
            reference.child(workoutsEntity).child(ID).child(containerIDEntity).removeValue()
        case .mindfulness:
            reference.child(mindfulnessEntity).child(ID).child(containerIDEntity).removeValue()
        case .meal:
            print("meal")
        }
    }
}

enum ContainerType {
    case activity
    case task
    case transaction
    case workout
    case mindfulness
    case meal
}
