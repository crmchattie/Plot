//
//  MindfulnessViewController+Extensions.swift
//  Plot
//
//  Created by Cory McHattie on 8/8/22.
//  Copyright © 2022 Immature Creations. All rights reserved.
//

import Foundation
import Firebase
import CodableFirebase
import Eureka

extension MindfulnessViewController {
    func setupLists() {
        let dispatchGroup = DispatchGroup()

        if let containerID = mindfulness.containerID {
            dispatchGroup.enter()
            ContainerFunctions.grabContainerAndStuffInside(id: containerID) { container, activities, tasks, _, transactions in
                self.container = container
                self.taskList = tasks ?? []
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
        if delegate == nil, active, (mindfulness?.participantsIDs?.contains(Auth.auth().currentUser?.uid ?? "") ?? false) {
            for task in taskList {
                var mvs = (form.sectionBy(tag: "Tasks") as! MultivaluedSection)
                mvs.insert(SubtaskRow() {
                    if let listID = task.listID, let list = networkController.activityService.listIDs[listID], let color = list.color {
                        $0.cell.activityTypeButton.tintColor = UIColor(ciColor: CIColor(string: color))
                    } else if let list = networkController.activityService.lists[ListSourceOptions.plot.name]?.first(where: { $0.defaultList ?? false }), let color = list.color {
                        $0.cell.activityTypeButton.tintColor = UIColor(ciColor: CIColor(string: color))
                    }
                    $0.value = task
                    $0.cell.delegate = self
                }.onCellSelection() { cell, row in
                    self.taskIndex = row.indexPath!.row
                    self.openTask()
                    cell.cellResignFirstResponder()
                }, at: mvs.count - 1)
            }
            for activity in eventList {
                var mvs = (form.sectionBy(tag: "Events") as! MultivaluedSection)
                mvs.insert(ScheduleRow() {
                    if let calendarID = activity.calendarID, let calendar = networkController.activityService.calendarIDs[calendarID], let color = calendar.color {
                        $0.cell.activityTypeButton.tintColor = UIColor(ciColor: CIColor(string: color))
                    } else if let calendar = networkController.activityService.calendars[CalendarSourceOptions.plot.name]?.first(where: { $0.defaultCalendar ?? false }), let color = calendar.color {
                        $0.cell.activityTypeButton.tintColor = UIColor(ciColor: CIColor(string: color))
                    }
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
                    self.openPurchases()
                    cell.cellResignFirstResponder()
                }, at: mvs.count - 1)
            }
        }
    }
    
    func openTask() {
        guard currentReachabilityStatus != .notReachable else {
            basicErrorAlertWithClose(title: basicErrorTitleForAlert, message: noInternetError, controller: self)
            return
        }
        if taskList.indices.contains(taskIndex) {
            self.showTaskDetailPush(task: taskList[taskIndex], updateDiscoverDelegate: nil, delegate: self, event: nil, transaction: nil, workout: nil, mindfulness: nil, template: nil, users: self.selectedFalconUsers, container: container, list: nil)
        } else {
            let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            alert.addAction(UIAlertAction(title: "New Task", style: .default, handler: { (_) in
                if let _: SubtaskRow = self.form.rowBy(tag: "label"), let mvs = self.form.sectionBy(tag: "Tasks") as? MultivaluedSection {
                    mvs.remove(at: mvs.count - 2)
                }
                if let container = self.container {
                    self.showTaskDetailPush(task: nil, updateDiscoverDelegate: nil, delegate: self, event: nil, transaction: nil, workout: nil, mindfulness: self.mindfulness, template: nil, users: self.selectedFalconUsers, container: container, list: nil)
                } else {
                    let containerID = Database.database().reference().child(containerEntity).childByAutoId().key ?? ""
                    self.container = Container(id: containerID, activityIDs: self.eventList.map({$0.activityID ?? ""}), taskIDs: self.taskList.map({$0.activityID ?? ""}), workoutIDs: nil, mindfulnessIDs: [self.mindfulness.hkSampleID ?? ""], mealIDs: nil, transactionIDs: self.purchaseList.map({$0.guid}), participantsIDs: self.mindfulness.participantsIDs)
                    self.showTaskDetailPush(task: nil, updateDiscoverDelegate: nil, delegate: self, event: nil, transaction: nil, workout: nil, mindfulness: self.mindfulness, template: nil, users: self.selectedFalconUsers, container: self.container, list: nil)
                }
            }))
            alert.addAction(UIAlertAction(title: "Existing Task", style: .default, handler: { (_) in
                if let _: SubtaskRow = self.form.rowBy(tag: "label"), let mvs = self.form.sectionBy(tag: "Tasks") as? MultivaluedSection {
                    mvs.remove(at: mvs.count - 2)
                }
                self.showChooseTaskDetailPush(needDelegate: true, movingBackwards: true, delegate: self, tasks: self.tasks, existingTasks: self.taskList)
            }))
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (_) in
                if let _: SubtaskRow = self.form.rowBy(tag: "label"), let mvs = self.form.sectionBy(tag: "Tasks") as? MultivaluedSection {
                    mvs.remove(at: mvs.count - 2)
                }
            }))
            self.present(alert, animated: true)
        }
    }
    
    func openEvent() {
        guard currentReachabilityStatus != .notReachable else {
            basicErrorAlertWithClose(title: basicErrorTitleForAlert, message: noInternetError, controller: self)
            return
        }
        if eventList.indices.contains(eventIndex) {
            showEventDetailPush(event: eventList[eventIndex], updateDiscoverDelegate: nil, delegate: self, task: nil, transaction: nil, workout: nil, mindfulness: nil, template: nil, users: selectedFalconUsers, container: nil, startDateTime: nil, endDateTime: nil)
        } else {
            let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            alert.addAction(UIAlertAction(title: "New Event", style: .default, handler: { (_) in
                if let _: ScheduleRow = self.form.rowBy(tag: "label"), let mvs = self.form.sectionBy(tag: "Events") as? MultivaluedSection {
                    mvs.remove(at: mvs.count - 2)
                }
                if let container = self.container {
                    self.showEventDetailPush(event: nil, updateDiscoverDelegate: nil, delegate: self, task: nil, transaction: nil, workout: nil, mindfulness: self.mindfulness, template: nil, users: self.selectedFalconUsers, container: container, startDateTime: nil, endDateTime: nil)
                } else {
                    let containerID = Database.database().reference().child(containerEntity).childByAutoId().key ?? ""
                    self.container = Container(id: containerID, activityIDs: self.eventList.map({$0.activityID ?? ""}), taskIDs: self.taskList.map({$0.activityID ?? ""}), workoutIDs: nil, mindfulnessIDs: [self.mindfulness.hkSampleID ?? ""], mealIDs: nil, transactionIDs: self.purchaseList.map({$0.guid}), participantsIDs: self.mindfulness.participantsIDs)
                    self.showEventDetailPush(event: nil, updateDiscoverDelegate: nil, delegate: self, task: nil, transaction: nil, workout: nil, mindfulness: self.mindfulness, template: nil, users: self.selectedFalconUsers, container: self.container, startDateTime: nil, endDateTime: nil)
                }
            }))
            alert.addAction(UIAlertAction(title: "Existing Event", style: .default, handler: { (_) in
                if let _: ScheduleRow = self.form.rowBy(tag: "label"), let mvs = self.form.sectionBy(tag: "Events") as? MultivaluedSection {
                    mvs.remove(at: mvs.count - 2)
                }
                self.showChooseEventDetailPush(needDelegate: true, movingBackwards: true, delegate: self, events: self.events, existingEvents: self.eventList)
            }))
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (_) in
                if let _: ScheduleRow = self.form.rowBy(tag: "label"), let mvs = self.form.sectionBy(tag: "Events") as? MultivaluedSection {
                    mvs.remove(at: mvs.count - 2)
                }
            }))
            self.present(alert, animated: true)
        }
    }
    
    func openPurchases() {
        guard currentReachabilityStatus != .notReachable else {
            basicErrorAlertWithClose(title: basicErrorTitleForAlert, message: noInternetError, controller: self)
            return
        }
        if purchaseList.indices.contains(purchaseIndex) {
            showTransactionDetailPush(transaction: purchaseList[purchaseIndex], updateDiscoverDelegate: nil, delegate: self, template: nil, users: self.selectedFalconUsers, container: nil, movingBackwards: true)
        } else {
            let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            alert.addAction(UIAlertAction(title: "New Transaction", style: .default, handler: { (_) in
                if let container = self.container {
                    self.showTransactionDetailPush(transaction: nil, updateDiscoverDelegate: nil, delegate: self, template: nil, users: self.selectedFalconUsers, container: container, movingBackwards: true)
                } else {
                    let containerID = Database.database().reference().child(containerEntity).childByAutoId().key ?? ""
                    self.container = Container(id: containerID, activityIDs: self.eventList.map({$0.activityID ?? ""}), taskIDs: self.taskList.map({$0.activityID ?? ""}), workoutIDs: nil, mindfulnessIDs: [self.mindfulness.hkSampleID ?? ""], mealIDs: nil, transactionIDs: self.purchaseList.map({$0.guid}), participantsIDs: self.mindfulness.participantsIDs)
                    self.showTransactionDetailPush(transaction: nil, updateDiscoverDelegate: nil, delegate: self, template: nil, users: self.selectedFalconUsers, container: self.container, movingBackwards: true)
                }
            }))
            alert.addAction(UIAlertAction(title: "Existing Transaction", style: .default, handler: { (_) in
                self.showChooseTransactionDetailPush(movingBackwards: true, delegate: self, transactions: self.transactions, existingTransactions: self.purchaseList)
            }))
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (_) in
                if let mvs = self.form.sectionBy(tag: "Transactions") as? MultivaluedSection {
                    mvs.remove(at: self.purchaseIndex)
                }
            }))
            self.present(alert, animated: true)
        }
    }
    
    func updateLists() {
        if container != nil {
            container = Container(id: container.id, activityIDs: eventList.map({$0.activityID ?? ""}), taskIDs: taskList.map({$0.activityID ?? ""}), workoutIDs: container.workoutIDs, mindfulnessIDs: container.mindfulnessIDs, mealIDs: nil, transactionIDs: purchaseList.map({$0.guid}), participantsIDs: mindfulness.participantsIDs)
        } else {
            let containerID = Database.database().reference().child(containerEntity).childByAutoId().key ?? ""
            container = Container(id: containerID, activityIDs: eventList.map({$0.activityID ?? ""}), taskIDs: taskList.map({$0.activityID ?? ""}), workoutIDs: nil, mindfulnessIDs: [mindfulness.hkSampleID ?? ""], mealIDs: nil, transactionIDs: purchaseList.map({$0.guid}), participantsIDs: mindfulness.participantsIDs)
        }
        ContainerFunctions.updateContainerAndStuffInside(container: container)
        mindfulness.containerID = container.id
        if active {
            ContainerFunctions.updateParticipants(containerID: container.id, selectedFalconUsers: selectedFalconUsers)
        }
    }
    
    func sortSchedule() {
        eventList.sort { (schedule1, schedule2) -> Bool in
            return schedule1.startDateTime?.int64Value ?? 0 < schedule2.startDateTime?.int64Value ?? 0
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

extension MindfulnessViewController: UpdateTaskDelegate {
    func updateTask(task: Activity) {
        if let _ = task.name {
            if taskList.indices.contains(taskIndex), let mvs = self.form.sectionBy(tag: "Tasks") as? MultivaluedSection {
                let row = mvs.allRows[taskIndex]
                row.baseValue = task
                row.reload()
                taskList[taskIndex] = task
            } else {
                var mvs = (form.sectionBy(tag: "Tasks") as! MultivaluedSection)
                mvs.insert(SubtaskRow() {
                    if let listID = task.listID, let list = networkController.activityService.listIDs[listID], let color = list.color {
                        $0.cell.activityTypeButton.tintColor = UIColor(ciColor: CIColor(string: color))
                    } else if let list = networkController.activityService.lists[ListSourceOptions.plot.name]?.first(where: { $0.defaultList ?? false }), let color = list.color {
                        $0.cell.activityTypeButton.tintColor = UIColor(ciColor: CIColor(string: color))
                    }
                    $0.value = task
                    $0.cell.delegate = self
                }.onCellSelection() { cell, row in
                    self.taskIndex = row.indexPath!.row
                    self.openTask()
                    cell.cellResignFirstResponder()
                }, at: mvs.count - 1)
                
                Analytics.logEvent("new_task", parameters: [
                    "task_name": task.name ?? "name" as NSObject,
                    "task_type": task.activityType ?? "basic" as NSObject
                ])
                taskList.append(task)
            }
            updateLists()
        }
    }
}

extension MindfulnessViewController: ChooseTaskDelegate {
    func chosenTask(mergeTask: Activity) {
        if let _: SubtaskRow = form.rowBy(tag: "label"), let mvs = self.form.sectionBy(tag: "Tasks") as? MultivaluedSection {
            mvs.remove(at: mvs.count - 2)
        }
        if let _ = mergeTask.name {
            var mvs = (form.sectionBy(tag: "Tasks") as! MultivaluedSection)
            mvs.insert(SubtaskRow() {
                if let listID = mergeTask.listID, let list = networkController.activityService.listIDs[listID], let color = list.color {
                    $0.cell.activityTypeButton.tintColor = UIColor(ciColor: CIColor(string: color))
                } else if let list = networkController.activityService.lists[ListSourceOptions.plot.name]?.first(where: { $0.defaultList ?? false }), let color = list.color {
                    $0.cell.activityTypeButton.tintColor = UIColor(ciColor: CIColor(string: color))
                }
                $0.value = mergeTask
            }.onCellSelection() { cell, row in
                self.taskIndex = row.indexPath!.row
                self.openTask()
                cell.cellResignFirstResponder()
            }, at: mvs.count - 1)
            
            Analytics.logEvent("new_task", parameters: [
                "task_name": mergeTask.name ?? "name" as NSObject,
                "task_type": mergeTask.activityType ?? "basic" as NSObject
            ])
            
            taskList.append(mergeTask)
            updateLists()
        }
    }
}

extension MindfulnessViewController: UpdateActivityDelegate {
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
                    if let calendarID = activity.calendarID, let calendar = networkController.activityService.calendarIDs[calendarID], let color = calendar.color {
                        $0.cell.activityTypeButton.tintColor = UIColor(ciColor: CIColor(string: color))
                    } else if let calendar = networkController.activityService.calendars[CalendarSourceOptions.plot.name]?.first(where: { $0.defaultCalendar ?? false }), let color = calendar.color {
                        $0.cell.activityTypeButton.tintColor = UIColor(ciColor: CIColor(string: color))
                    }
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
            updateLists()
        }
    }
}

extension MindfulnessViewController: ChooseActivityDelegate {
    func chosenActivity(mergeActivity: Activity) {
        if let _: ScheduleRow = form.rowBy(tag: "label"), let mvs = self.form.sectionBy(tag: "Events") as? MultivaluedSection {
            mvs.remove(at: mvs.count - 2)
        }
        if let _ = mergeActivity.name {
            var mvs = (form.sectionBy(tag: "Events") as! MultivaluedSection)
            mvs.insert(ScheduleRow() {
                if let calendarID = mergeActivity.calendarID, let calendar = networkController.activityService.calendarIDs[calendarID], let color = calendar.color {
                    $0.cell.activityTypeButton.tintColor = UIColor(ciColor: CIColor(string: color))
                } else if let calendar = networkController.activityService.calendars[CalendarSourceOptions.plot.name]?.first(where: { $0.defaultCalendar ?? false }), let color = calendar.color {
                    $0.cell.activityTypeButton.tintColor = UIColor(ciColor: CIColor(string: color))
                }
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
            updateLists()

        }
    }
}

extension MindfulnessViewController: UpdateTransactionDelegate {
    func updateTransaction(transaction: Transaction) {
        var mvs = self.form.sectionBy(tag: "Transactions") as! MultivaluedSection
        if transaction.description != "Name" {
            if mvs.allRows.count - 1 == purchaseIndex {
                mvs.insert(PurchaseRow() {
                    $0.value = transaction
                }.onCellSelection() { cell, row in
                    self.purchaseIndex = row.indexPath!.row
                    self.openPurchases()
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
            updateLists()
        }
        else if mvs.allRows.count - 1 > purchaseIndex {
            mvs.remove(at: purchaseIndex)
        }
        //            purchaseBreakdown()
    }
}

extension MindfulnessViewController: ChooseTransactionDelegate {
    func chosenTransaction(transaction: Transaction) {
        var mvs = self.form.sectionBy(tag: "Transactions") as! MultivaluedSection
        if transaction.description != "Name" {
            if mvs.allRows.count - 1 == purchaseIndex {
                mvs.insert(PurchaseRow() {
                    $0.value = transaction
                }.onCellSelection() { cell, row in
                    self.purchaseIndex = row.indexPath!.row
                    self.openPurchases()
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
            updateLists()
        }
        else if mvs.allRows.count - 1 > purchaseIndex {
            mvs.remove(at: purchaseIndex)
        }
    }
}

extension MindfulnessViewController: UpdateTaskCellDelegate {
    func updateCompletion(task: Activity) {
        if let index = taskList.firstIndex(where: {$0.activityID == task.activityID} ) {
            taskList[index].isCompleted = task.isCompleted ?? false
            if (taskList[index].isCompleted ?? false) {
                let original = Date()
                let updateDate = Date(timeIntervalSinceReferenceDate:
                                    (original.timeIntervalSinceReferenceDate / 300.0).rounded(.toNearestOrEven) * 300.0)
                taskList[index].completedDate = NSNumber(value: Int((updateDate).timeIntervalSince1970))
            } else {
                taskList[index].completedDate = nil
            }
            
            let updateTask = ActivityActions(activity: taskList[index], active: true, selectedFalconUsers: [])
            updateTask.updateCompletion(isComplete: taskList[index].isCompleted ?? false)
        }
    }
}
