//
//  WorkoutViewController+Extensions.swift
//  Plot
//
//  Created by Cory McHattie on 8/8/22.
//  Copyright © 2022 Immature Creations. All rights reserved.
//

import Foundation
import Firebase
import CodableFirebase
import Eureka

extension WorkoutViewController {
    func setupLists() {
        guard delegate == nil && active else { return }
        let dispatchGroup = DispatchGroup()
        if let containerID = workout.containerID {
            dispatchGroup.enter()
            ContainerFunctions.grabContainerAndStuffInside(id: containerID) { container, activities, _, transactions in
                self.container = container
                self.eventList = activities ?? []
                self.purchaseList = transactions ?? []
                dispatchGroup.leave()
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            self.listRow()
        }
        
    }
    
    func listRow() {
        for activity in eventList {
            var mvs = (form.sectionBy(tag: "Events") as! MultivaluedSection)
            mvs.insert(ScheduleRow() {
                $0.value = activity
            }.onCellSelection() { cell, row in
                self.eventIndex = row.indexPath!.row
                self.openEvent()
                cell.cellResignFirstResponder()
            }, at: mvs.count - 1)
        }
        for purchase in purchaseList {
            var mvs = (form.sectionBy(tag: "Transactions") as! MultivaluedSection)
            mvs.insert(PurchaseRow() {
                $0.value = purchase
            }.onCellSelection() { cell, row in
                self.purchaseIndex = row.indexPath!.row
                self.openTransaction()
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
                if let _: ScheduleRow = self.form.rowBy(tag: "label"), let mvs = self.form.sectionBy(tag: "Events") as? MultivaluedSection {
                    mvs.remove(at: mvs.count - 2)
                }
                let destination = EventViewController(networkController: self.networkController)
                destination.users = self.selectedFalconUsers
                destination.filteredUsers = self.selectedFalconUsers
                destination.delegate = self
                destination.startDateTime = self.workout.startDateTime
                destination.endDateTime = self.workout.endDateTime
                self.navigationController?.pushViewController(destination, animated: true)
            }))
            alert.addAction(UIAlertAction(title: "Existing Activity", style: .default, handler: { (_) in
                if let _: ScheduleRow = self.form.rowBy(tag: "label"), let mvs = self.form.sectionBy(tag: "Events") as? MultivaluedSection {
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
                if let _: ScheduleRow = self.form.rowBy(tag: "label"), let mvs = self.form.sectionBy(tag: "Events") as? MultivaluedSection {
                    mvs.remove(at: mvs.count - 2)
                }
            }))
            self.present(alert, animated: true)
        }
    }
    
    func openTransaction() {
        guard currentReachabilityStatus != .notReachable else {
            basicErrorAlertWith(title: basicErrorTitleForAlert, message: noInternetError, controller: self)
            return
        }
        if purchaseList.indices.contains(purchaseIndex) {
            let destination = FinanceTransactionViewController(networkController: networkController)
            destination.delegate = self
            destination.movingBackwards = true
            destination.transaction = purchaseList[purchaseIndex]
            self.navigationController?.pushViewController(destination, animated: true)
        } else {
            let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            alert.addAction(UIAlertAction(title: "New Transaction", style: .default, handler: { (_) in
                let destination = FinanceTransactionViewController(networkController: self.networkController)
                destination.delegate = self
                destination.movingBackwards = true
                destination.users = self.selectedFalconUsers
                destination.filteredUsers = self.selectedFalconUsers
                self.navigationController?.pushViewController(destination, animated: true)
            }))
            alert.addAction(UIAlertAction(title: "Existing Transaction", style: .default, handler: { (_) in
                print("Existing")
                let destination = ChooseTransactionTableViewController()
                destination.delegate = self
                destination.movingBackwards = true
                destination.existingTransactions = self.purchaseList
                destination.transactions = self.transactions
                self.navigationController?.pushViewController(destination, animated: true)
            }))
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (_) in
                if let mvs = self.form.sectionBy(tag: "Transactions") as? MultivaluedSection {
                    mvs.remove(at: mvs.count - 2)
                }
            }))
            self.present(alert, animated: true)
        }
    }
    
    func updateLists() {
        if container != nil {
            container = Container(id: container.id, activityIDs: eventList.map({$0.activityID ?? ""}), workoutIDs: container.workoutIDs, mindfulnessIDs: container.mindfulnessIDs, mealIDs: nil, transactionIDs: purchaseList.map({$0.guid}))
        } else {
            let containerID = Database.database().reference().child(containerEntity).childByAutoId().key ?? ""
            container = Container(id: containerID, activityIDs: eventList.map({$0.activityID ?? ""}), workoutIDs: [workout.hkSampleID ?? ""], mindfulnessIDs: nil, mealIDs: nil, transactionIDs: purchaseList.map({$0.guid}))
        }
        ContainerFunctions.updateContainerAndStuffInside(container: container)
    }
    
    func sortSchedule() {
        eventList.sort { (schedule1, schedule2) -> Bool in
            return schedule1.startDateTime!.int64Value < schedule2.startDateTime!.int64Value
        }
        if let mvs = self.form.sectionBy(tag: "Events") as? MultivaluedSection {
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

extension WorkoutViewController: UpdateActivityDelegate {
    func updateActivity(activity: Activity) {
        if let _ = activity.name {
            if eventList.indices.contains(eventIndex), let mvs = self.form.sectionBy(tag: "Events") as? MultivaluedSection {
                let scheduleRow = mvs.allRows[eventIndex]
                scheduleRow.baseValue = activity
                scheduleRow.reload()
                eventList[eventIndex] = activity
            } else {
                var mvs = (form.sectionBy(tag: "Events") as! MultivaluedSection)
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

extension WorkoutViewController: ChooseActivityDelegate {
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
        if let _: ScheduleRow = form.rowBy(tag: "label"), let mvs = self.form.sectionBy(tag: "Events") as? MultivaluedSection {
            mvs.remove(at: mvs.count - 2)
        }
        if let _ = mergeActivity.name {
            var mvs = (form.sectionBy(tag: "Events") as! MultivaluedSection)
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

extension WorkoutViewController: UpdateTransactionDelegate {
    func updateTransaction(transaction: Transaction) {
        var mvs = self.form.sectionBy(tag: "Transactions") as! MultivaluedSection
        if transaction.description != "Name" {
            if mvs.allRows.count - 1 == purchaseIndex {
                mvs.insert(PurchaseRow() {
                    $0.value = transaction
                }.onCellSelection() { cell, row in
                    self.purchaseIndex = row.indexPath!.row
                    self.openTransaction()
                    cell.cellResignFirstResponder()
                }, at: purchaseIndex)
            } else {
                let row = mvs.allRows[purchaseIndex]
                row.baseValue = transaction
                row.updateCell()
            }
            if purchaseList.indices.contains(purchaseIndex) {
                purchaseList[purchaseIndex] = transaction
            } else {
                purchaseList.append(transaction)
            }
        }
        else if mvs.allRows.count - 1 > purchaseIndex {
            mvs.remove(at: purchaseIndex)
        }
        //            purchaseBreakdown()
    }
}

extension WorkoutViewController: ChooseTransactionDelegate {
    func chosenTransaction(transaction: Transaction) {
        var mvs = self.form.sectionBy(tag: "Transactions") as! MultivaluedSection
        if transaction.description != "Name" {
            if mvs.allRows.count - 1 == purchaseIndex {
                mvs.insert(PurchaseRow() {
                    $0.value = transaction
                }.onCellSelection() { cell, row in
                    self.purchaseIndex = row.indexPath!.row
                    self.openTransaction()
                    cell.cellResignFirstResponder()
                }, at: purchaseIndex)
            } else {
                let row = mvs.allRows[purchaseIndex]
                row.baseValue = transaction
                row.updateCell()
            }
            if purchaseList.indices.contains(purchaseIndex) {
                purchaseList[purchaseIndex] = transaction
            } else {
                purchaseList.append(transaction)
            }
        }
        else if mvs.allRows.count - 1 > purchaseIndex {
            mvs.remove(at: purchaseIndex)
        }
    }
}