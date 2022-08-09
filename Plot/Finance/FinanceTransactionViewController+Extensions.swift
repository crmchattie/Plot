//
//  FinanceTransactionViewController+Extensions.swift
//  Plot
//
//  Created by Cory McHattie on 8/9/22.
//  Copyright © 2022 Immature Creations. All rights reserved.
//

import Foundation
import Firebase
import CodableFirebase
import Eureka

extension FinanceTransactionViewController {
    func setupLists() {
        guard delegate == nil && active else { return }
        let dispatchGroup = DispatchGroup()
        if let containerID = transaction.containerID {
            print(containerID)
            dispatchGroup.enter()
            ContainerFunctions.grabContainerAndStuffInside(id: containerID) { container, activities, health, _ in
                self.container = container
                self.eventList = activities ?? []
                self.healthList = health ?? []
                dispatchGroup.leave()
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            self.listRow()
        }
        
    }
    
    func listRow() {
        for activity in eventList {
            var mvs = (form.sectionBy(tag: "schedulefields") as! MultivaluedSection)
            mvs.insert(ScheduleRow() {
                $0.value = activity
            }.onCellSelection() { cell, row in
                self.eventIndex = row.indexPath!.row
                self.openEvent()
                cell.cellResignFirstResponder()
            }, at: mvs.count - 1)
        }
        for health in healthList {
            var mvs = (form.sectionBy(tag: "healthfields") as! MultivaluedSection)
            mvs.insert(HealthRow() {
                $0.value = health
                }.onCellSelection() { cell, row in
                    self.healthIndex = row.indexPath!.row
                    self.openHealth()
                    cell.cellResignFirstResponder()
            }, at: mvs.count - 1)
            
        }
    }
    
    func openEvent() {
        guard currentReachabilityStatus != .notReachable else {
            basicErrorAlertWith(title: basicErrorTitleForAlert, message: noInternetError, controller: self)
            return
        }
        if eventList.indices.contains(eventIndex) {
            showActivityIndicator()
            let destination = EventViewController(networkController: networkController)
            destination.activity = eventList[eventIndex]
            destination.delegate = self
            self.hideActivityIndicator()
            self.navigationController?.pushViewController(destination, animated: true)
        } else {
            let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            alert.addAction(UIAlertAction(title: "New Activity", style: .default, handler: { (_) in
                if let _: ScheduleRow = self.form.rowBy(tag: "label"), let mvs = self.form.sectionBy(tag: "schedulefields") as? MultivaluedSection {
                    mvs.remove(at: mvs.count - 2)
                }
                let destination = EventViewController(networkController: self.networkController)
                destination.users = self.selectedFalconUsers
                destination.filteredUsers = self.selectedFalconUsers
                destination.delegate = self
                if let date = self.isodateFormatter.date(from: self.transaction.transacted_at) {
                    destination.startDateTime = date
                    destination.endDateTime = date
                }
                self.navigationController?.pushViewController(destination, animated: true)
            }))
            alert.addAction(UIAlertAction(title: "Existing Activity", style: .default, handler: { (_) in
                if let _: ScheduleRow = self.form.rowBy(tag: "label"), let mvs = self.form.sectionBy(tag: "schedulefields") as? MultivaluedSection {
                    mvs.remove(at: mvs.count - 2)
                }
                let destination = ChooseActivityTableViewController()
                destination.needDelegate = true
                destination.movingBackwards = true
                destination.delegate = self
                destination.activities = self.activities
                destination.filteredActivities = self.activities
                destination.existingActivities = self.eventList
                self.navigationController?.pushViewController(destination, animated: true)
            }))
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (_) in
                if let _: ScheduleRow = self.form.rowBy(tag: "label"), let mvs = self.form.sectionBy(tag: "schedulefields") as? MultivaluedSection {
                    mvs.remove(at: mvs.count - 2)
                }
            }))
            self.present(alert, animated: true)
        }
    }
    
    func openHealth() {
        if healthList.indices.contains(healthIndex), let workout = healthList[healthIndex].workout {
            let destination = WorkoutViewController(networkController: networkController)
            destination.workout = workout
            destination.delegate = self
            self.navigationController?.pushViewController(destination, animated: true)
        } else if healthList.indices.contains(healthIndex), let mindfulness = healthList[healthIndex].mindfulness {
            let destination = MindfulnessViewController(networkController: networkController)
            destination.mindfulness = mindfulness
            destination.delegate = self
            self.navigationController?.pushViewController(destination, animated: true)
        } else {
            let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            alert.addAction(UIAlertAction(title: "New Workout", style: .default, handler: { (_) in
                let destination = WorkoutViewController(networkController: self.networkController)
                destination.delegate = self
                destination.movingBackwards = true
                self.navigationController?.pushViewController(destination, animated: true)
            }))
            alert.addAction(UIAlertAction(title: "New Mindfulness", style: .default, handler: { (_) in
                let destination = MindfulnessViewController(networkController: self.networkController)
                destination.delegate = self
                destination.movingBackwards = true
                self.navigationController?.pushViewController(destination, animated: true)
            }))
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (_) in
                if let mvs = self.form.sectionBy(tag: "healthfields") as? MultivaluedSection {
                    mvs.remove(at: self.healthIndex)
                }
            }))
            self.present(alert, animated: true)
        }
    }
    
    func updateLists() {
        if container != nil {
            container = Container(id: container.id, activityIDs: eventList.map({$0.activityID ?? ""}), workoutIDs: healthList.filter({ $0.workout != nil }).map({$0.ID}), mindfulnessIDs: healthList.filter({ $0.mindfulness != nil }).map({$0.ID}), mealIDs: nil, transactionIDs: container.transactionIDs)
        } else {
            let containerID = Database.database().reference().child(containerEntity).childByAutoId().key ?? ""
            container = Container(id: containerID, activityIDs: eventList.map({$0.activityID ?? ""}), workoutIDs: healthList.filter({ $0.workout != nil }).map({$0.ID}), mindfulnessIDs: healthList.filter({ $0.mindfulness != nil }).map({$0.ID}), mealIDs: nil, transactionIDs: [transaction.guid])
        }
        ContainerFunctions.updateContainerAndStuffInside(container: container)
    }
    
    func sortSchedule() {
        eventList.sort { (schedule1, schedule2) -> Bool in
            return schedule1.startDateTime!.int64Value < schedule2.startDateTime!.int64Value
        }
        if let mvs = self.form.sectionBy(tag: "schedulefields") as? MultivaluedSection {
            if mvs.count == 1 {
                return
            }
            for index in 0...mvs.count - 2 {
                let scheduleRow = mvs.allRows[index]
                scheduleRow.baseValue = eventList[index]
                scheduleRow.reload()
            }
        }
    }
}

extension FinanceTransactionViewController: UpdateActivityDelegate {
    func updateActivity(activity: Activity) {
        if let _ = activity.name {
            if eventList.indices.contains(eventIndex), let mvs = self.form.sectionBy(tag: "schedulefields") as? MultivaluedSection {
                let scheduleRow = mvs.allRows[eventIndex]
                scheduleRow.baseValue = activity
                scheduleRow.reload()
                eventList[eventIndex] = activity
            } else {
                var mvs = (form.sectionBy(tag: "schedulefields") as! MultivaluedSection)
                mvs.insert(ScheduleRow() {
                    $0.value = activity
                }.onCellSelection() { cell, row in
                    self.eventIndex = row.indexPath!.row
                    self.openEvent()
                    cell.cellResignFirstResponder()
                }, at: mvs.count - 1)
                
                Analytics.logEvent("new_schedule", parameters: [
                    "schedule_name": activity.name ?? "name" as NSObject,
                    "schedule_type": activity.activityType ?? "basic" as NSObject
                ])
                eventList.append(activity)
            }
            
            sortSchedule()
        }
    }
}

extension FinanceTransactionViewController: ChooseActivityDelegate {
    func getParticipants(forActivity activity: Activity, completion: @escaping ([User])->()) {
        guard let participantsIDs = activity.participantsIDs, let currentUserID = Auth.auth().currentUser?.uid else {
            return
        }
        
        let group = DispatchGroup()
        var participants: [User] = []
        for id in participantsIDs {
            // Only if the current user is created this activity
            if activity.admin == currentUserID && id == currentUserID {
                continue
            }
            
            group.enter()
            let participantReference = Database.database().reference().child("users").child(id)
            participantReference.observeSingleEvent(of: .value, with: { (snapshot) in
                if snapshot.exists(), var dictionary = snapshot.value as? [String: AnyObject] {
                    dictionary.updateValue(snapshot.key as AnyObject, forKey: "id")
                    let user = User(dictionary: dictionary)
                    participants.append(user)
                }
                
                group.leave()
            })
        }
        
        group.notify(queue: .main) {
            completion(participants)
        }
    }
    
    func chosenActivity(mergeActivity: Activity) {
        if let _: ScheduleRow = form.rowBy(tag: "label"), let mvs = self.form.sectionBy(tag: "schedulefields") as? MultivaluedSection {
            mvs.remove(at: mvs.count - 2)
        }
        if let _ = mergeActivity.name {
            var mvs = (form.sectionBy(tag: "schedulefields") as! MultivaluedSection)
            mvs.insert(ScheduleRow() {
                $0.value = mergeActivity
            }.onCellSelection() { cell, row in
                self.eventIndex = row.indexPath!.row
                self.openEvent()
                cell.cellResignFirstResponder()
            }, at: mvs.count - 1)
            
            Analytics.logEvent("new_schedule", parameters: [
                "schedule_name": mergeActivity.name ?? "name" as NSObject,
                "schedule_type": mergeActivity.activityType ?? "basic" as NSObject
            ])
            
            eventList.append(mergeActivity)
            sortSchedule()
        }
    }
}

extension FinanceTransactionViewController: UpdateWorkoutDelegate {
    func updateWorkout(workout: Workout) {
        var mvs = self.form.sectionBy(tag: "healthfields") as! MultivaluedSection
        if workout.name != "Name" {
            if healthList.indices.contains(healthIndex) {
                healthList[healthIndex].workout = workout
            } else {
                var health = HealthContainer()
                health.workout = workout
                healthList.append(health)
            }
            if mvs.allRows.count - 1 == healthIndex {
                mvs.insert(HealthRow() {
                    $0.value = healthList[healthIndex]
                    }.onCellSelection() { cell, row in
                        self.healthIndex = row.indexPath!.row
                        self.openHealth()
                        cell.cellResignFirstResponder()
                }, at: healthIndex)
            } else {
                let row = mvs.allRows[healthIndex]
                row.baseValue = healthList[healthIndex]
                row.updateCell()
            }
            updateLists()
        }
        else if mvs.allRows.count - 1 > healthIndex {
            mvs.remove(at: healthIndex)
        }
    }
}

extension FinanceTransactionViewController: UpdateMindfulnessDelegate {
    func updateMindfulness(mindfulness: Mindfulness) {
        var mvs = self.form.sectionBy(tag: "healthfields") as! MultivaluedSection
        if mindfulness.name != "Name" {
            if healthList.indices.contains(healthIndex) {
                healthList[healthIndex].mindfulness = mindfulness
            } else {
                var health = HealthContainer()
                health.mindfulness = mindfulness
                healthList.append(health)
            }
            if mvs.allRows.count - 1 == healthIndex {
                mvs.insert(HealthRow() {
                    $0.value = healthList[healthIndex]
                    }.onCellSelection() { cell, row in
                        self.healthIndex = row.indexPath!.row
                        self.openHealth()
                        cell.cellResignFirstResponder()
                }, at: healthIndex)
            } else {
                let row = mvs.allRows[healthIndex]
                row.baseValue = healthList[healthIndex]
                row.updateCell()
            }
            updateLists()
        }
        else if mvs.allRows.count - 1 > healthIndex {
            mvs.remove(at: healthIndex)
        }
    }
}
