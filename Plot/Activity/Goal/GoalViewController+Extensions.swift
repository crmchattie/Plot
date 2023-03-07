//
//  GoalViewController+Extensions.swift
//  Plot
//
//  Created by Cory McHattie on 2/14/23.
//  Copyright © 2023 Immature Creations. All rights reserved.
//

import UIKit
import SDWebImage
import Firebase
import Eureka
import SplitRow
import ViewRow
import EventKit
import CodableFirebase
import RRuleSwift

extension GoalViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    @objc func textFieldDidChange(_ textField: UITextField) {
        if textField.text?.count == 0 {
            navigationItem.rightBarButtonItem?.isEnabled = false
        } else {
            navigationItem.rightBarButtonItem?.isEnabled = true
        }
    }
}


//extension GoalViewController: UITextViewDelegate {
//
//    func textViewDidBeginEditing(_ textView: UITextView) {
//        //        createActivityView.activityDescriptionPlaceholderLabel.isHidden = true
//        if textView.textColor == FalconPalette.defaultBlue {
//            textView.text = nil
//            textView.textColor = .label
//        }
//
//
//    }
//
//    func textViewDidEndEditing(_ textView: UITextView) {
//        //        createActivityView.activityDescriptionPlaceholderLabel.isHidden = !textView.text.isEmpty
//        if textView.text.isEmpty {
//            textView.text = "Description"
//            textView.textColor = FalconPalette.defaultBlue
//        }
//    }
//
//    func textViewDidChange(_ textView: UITextView) {
//
//    }
//
//}

extension GoalViewController: UpdateGoalDelegate {
    func update(goal: Goal?, number: Int) {
        if let goal = goal {
            if number == 0, let row: LabelRow = form.rowBy(tag: "Metric") {
                row.value = goal.cellDescriptionFirst ?? goal.metric?.rawValue
                row.updateCell()
                if let _ = self.task.goal {
                    self.task.goal!.metric = goal.metric
                    self.task.goal!.submetric = goal.submetric
                    self.task.goal!.option = goal.option
                    self.task.goal!.unit = goal.unit
                    self.task.goal!.period = goal.period
                    self.task.goal!.targetNumber = goal.targetNumber
                    self.task.goal!.currentNumber = goal.currentNumber
                    self.task.goal!.metricRelationship = goal.metricRelationship
                } else {
                    self.task.goal = Goal(name: nil, metric: goal.metric, submetric: goal.submetric, option: goal.option, unit: goal.unit, period: goal.period, targetNumber: goal.targetNumber, currentNumber: goal.currentNumber, metricRelationship: goal.metricRelationship, frequency: nil, metricSecond: nil, submetricSecond: nil, optionSecond: nil, unitSecond: nil, periodSecond: nil, targetNumberSecond: nil, currentNumberSecond: nil, metricRelationshipSecond: nil, metricsRelationshipType: nil)
                }
            } else if number == 1, let row: LabelRow = form.rowBy(tag: "secondMetric") {
                row.value = goal.cellDescriptionFirst ?? goal.metric?.rawValue
                row.updateCell()
                if let _ = self.task.goal {
                    self.task.goal!.metricSecond = goal.metric
                    self.task.goal!.submetricSecond = goal.submetric
                    self.task.goal!.optionSecond = goal.option
                    self.task.goal!.unitSecond = goal.unit
                    self.task.goal!.periodSecond = goal.period
                    self.task.goal!.targetNumberSecond = goal.targetNumber
                    self.task.goal!.currentNumberSecond = goal.currentNumber
                    self.task.goal!.metricRelationshipSecond = goal.metricRelationship
                }
                if self.task.goal?.metricsRelationshipType == nil, let metricsRelationshipRow : PushRow<String> = self.form.rowBy(tag: "metricsRelationship") {
                    metricsRelationshipRow.value = MetricsRelationshipType.or.rawValue
                    self.task.goal!.metricsRelationshipType = MetricsRelationshipType.or
                    
                }
            }
        }
        self.updateCategorySubCategoryRows()
        self.updateDescriptionRow()
    }
}

extension GoalViewController: UpdateActivityLevelDelegate {
    func update(value: String, level: String) {
        if let row: LabelRow = form.rowBy(tag: level) {
            row.value = value
            row.updateCell()
            if level == "Category" {
                self.task.category = value
            } else if level == "Subcategory" {
                self.task.subcategory = value
            }
        }
    }
}

extension GoalViewController: UpdateListDelegate {
    func update(list: ListType) {
        if let row: LabelRow = form.rowBy(tag: "List"), let listID = list.id {
            //remove old list if updated
            if let oldListID = task.listID, let source = task.listSource, listID != oldListID, source == ListSourceOptions.plot.name {
                let listReference = Database.database().reference().child(listEntity).child(oldListID).child(listTasksEntity)
                listReference.child(self.activityID).setValue(nil)
            }
        
            row.value = list.name
            row.updateCell()
            
            task.listID = listID
            task.listName = list.name
            task.listColor = list.color
            task.listSource = list.source
            
            if active, let source = list.source, source == ListSourceOptions.plot.name {
                let listReference = Database.database().reference().child(listEntity).child(listID).child(listTasksEntity)
                listReference.child(self.activityID).setValue(true)
            }
        }
    }
}

extension GoalViewController: UpdateSubtaskListDelegate {
    func updateSubtaskList(subtaskList: [Activity]) {
        if let row: LabelRow = form.rowBy(tag: "Sub-Tasks") {
            if !subtaskList.isEmpty {
                row.value = String(subtaskList.count)
            } else {
                row.value = "0"
            }
            row.updateCell()
        }
        self.subtaskList = subtaskList
        sortSubtasks()
        updateLists(type: "subtasks")
    }
}

extension GoalViewController: UpdateActivityDelegate {
    func updateActivity(activity: Activity) {
        if let _ = activity.name, let checkRow: CheckRow = self.form.rowBy(tag: "Completed"), let completedRow: DateTimeInlineRow = self.form.rowBy(tag: "Completed On"), let goal = self.task.goal {
            if goal.metric == .events, let metricRow: LabelRow = form.rowBy(tag: "Metric") {
                if goal.unit == .count {
                    var goalCurrentNumber = goal.currentNumber ?? 0
                    let goalCurrentNumberSecond = goal.currentNumberSecond ?? 0
                    var complete = false
                    
                    goalCurrentNumber = 1
                    switch goal.metricRelationship ?? .equalMore {
                    case .equalMore:
                        complete = goalCurrentNumber >= goal.targetNumber ?? 0
                    case .equalLess:
                        complete = goalCurrentNumber <= goal.targetNumber ?? 0
                    case .or, .and, .equal:
                        break
                    }
                    
                    self.task.isCompleted = complete
                    self.task.goal?.currentNumber = goalCurrentNumber
                    self.task.goal?.currentNumberSecond = goalCurrentNumberSecond
                    
                    checkRow.value = complete
                    checkRow.updateCell()
                    
                    metricRow.value = self.task.goal?.cellDescriptionFirst
                    metricRow.updateCell()
                    
                    if complete {
                        checkRow.cell.tintAdjustmentMode = .automatic
                        
                        let original = Date()
                        let updateDate = Date(timeIntervalSinceReferenceDate:
                                                (original.timeIntervalSinceReferenceDate / 300.0).rounded(.toNearestOrEven) * 300.0)
                        completedRow.value = updateDate
                        completedRow.updateCell()
                        completedRow.hidden = false
                        completedRow.evaluateHidden()
                        
                        self.task.completedDate = NSNumber(value: Int((updateDate).timeIntervalSince1970))
                    } else {
                        checkRow.cell.tintAdjustmentMode = .dimmed
                        
                        completedRow.value = nil
                        completedRow.updateCell()
                        completedRow.hidden = true
                        completedRow.evaluateHidden()
                        
                        self.task.completedDate = nil
                    }
                    
                    let updateTask = ActivityActions(activity: self.task, active: self.active, selectedFalconUsers: self.selectedFalconUsers)
                    updateTask.updateCompletion(isComplete: complete, completeUpdatedByUser: false, goalCurrentNumber: goalCurrentNumber as NSNumber, goalCurrentNumberSecond: goalCurrentNumberSecond as NSNumber)
                } else if let startDate = activity.startDate, let endDate = activity.endDate {
                    var goalCurrentNumber = goal.currentNumber ?? 0
                    let goalCurrentNumberSecond = goal.currentNumberSecond ?? 0
                    var complete = false
                    
                    let duration = (endDate.timeIntervalSince1970 - startDate.timeIntervalSince1970)
                    switch goal.unitSecond {
                    case .minutes:
                        goalCurrentNumber = duration.totalMinutes
                    case .hours:
                        goalCurrentNumber = duration.totalMinutes
                    case .days:
                        goalCurrentNumber = duration.totalMinutes
                    case .none, .count, .calories, .amount, .percent, .multiple, .level:
                        break
                    }
                    
                    switch goal.metricRelationship ?? .equalMore {
                    case .equalMore:
                        complete = goalCurrentNumber > goal.targetNumberSecond ?? 0
                    case .equalLess:
                        complete = goalCurrentNumber < goal.targetNumberSecond ?? 0
                    case .or, .and, .equal:
                        break
                    }
                    
                    self.task.isCompleted = complete
                    self.task.goal?.currentNumber = goalCurrentNumber
                    self.task.goal?.currentNumberSecond = goalCurrentNumberSecond
                    
                    checkRow.value = complete
                    checkRow.updateCell()
                    
                    metricRow.value = self.task.goal?.cellDescriptionFirst
                    metricRow.updateCell()
                    
                    if complete {
                        checkRow.cell.tintAdjustmentMode = .automatic
                        
                        let original = Date()
                        let updateDate = Date(timeIntervalSinceReferenceDate:
                                                (original.timeIntervalSinceReferenceDate / 300.0).rounded(.toNearestOrEven) * 300.0)
                        completedRow.value = updateDate
                        completedRow.updateCell()
                        completedRow.hidden = false
                        completedRow.evaluateHidden()
                        
                        self.task.completedDate = NSNumber(value: Int((updateDate).timeIntervalSince1970))
                    } else {
                        checkRow.cell.tintAdjustmentMode = .dimmed
                        
                        completedRow.value = nil
                        completedRow.updateCell()
                        completedRow.hidden = true
                        completedRow.evaluateHidden()
                        
                        self.task.completedDate = nil
                    }
                    
                    let updateTask = ActivityActions(activity: self.task, active: self.active, selectedFalconUsers: self.selectedFalconUsers)
                    updateTask.updateCompletion(isComplete: complete, completeUpdatedByUser: false, goalCurrentNumber: goalCurrentNumber as NSNumber, goalCurrentNumberSecond: goalCurrentNumberSecond as NSNumber)
                }
            } else if goal.metricSecond == .events, let metricSecondRow: LabelRow = form.rowBy(tag: "secondMetric") {
                if goal.unitSecond == .count {
                    let goalCurrentNumber = goal.currentNumber ?? 0
                    var goalCurrentNumberSecond = goal.currentNumberSecond ?? 0
                    var complete = false
                    
                    goalCurrentNumberSecond = 1
                    switch goal.metricRelationshipSecond ?? .equalMore {
                    case .equalMore:
                        complete = goalCurrentNumberSecond >= goal.targetNumberSecond ?? 0
                    case .equalLess:
                        complete = goalCurrentNumberSecond <= goal.targetNumberSecond ?? 0
                    case .or, .and, .equal:
                        break
                    }
                    
                    self.task.isCompleted = complete
                    self.task.goal?.currentNumber = goalCurrentNumber
                    self.task.goal?.currentNumberSecond = goalCurrentNumberSecond
                    
                    checkRow.value = complete
                    checkRow.updateCell()
                    
                    metricSecondRow.value = self.task.goal?.cellDescriptionSecond
                    metricSecondRow.updateCell()

                    if complete {
                        checkRow.cell.tintAdjustmentMode = .automatic
                        
                        let original = Date()
                        let updateDate = Date(timeIntervalSinceReferenceDate:
                                                (original.timeIntervalSinceReferenceDate / 300.0).rounded(.toNearestOrEven) * 300.0)
                        completedRow.value = updateDate
                        completedRow.updateCell()
                        completedRow.hidden = false
                        completedRow.evaluateHidden()
                        
                        self.task.completedDate = NSNumber(value: Int((updateDate).timeIntervalSince1970))
                    } else {
                        checkRow.cell.tintAdjustmentMode = .dimmed
                        
                        completedRow.value = nil
                        completedRow.updateCell()
                        completedRow.hidden = true
                        completedRow.evaluateHidden()
                        
                        self.task.completedDate = nil
                    }
                    
                    let updateTask = ActivityActions(activity: self.task, active: self.active, selectedFalconUsers: self.selectedFalconUsers)
                    updateTask.updateCompletion(isComplete: complete, completeUpdatedByUser: false, goalCurrentNumber: goalCurrentNumber as NSNumber, goalCurrentNumberSecond: goalCurrentNumberSecond as NSNumber)
                } else if let startDate = activity.startDate, let endDate = activity.endDate {
                    let goalCurrentNumber = goal.currentNumber ?? 0
                    var goalCurrentNumberSecond = goal.currentNumberSecond ?? 0
                    var complete = false
                    
                    let duration = (endDate.timeIntervalSince1970 - startDate.timeIntervalSince1970)
                    switch goal.unitSecond {
                    case .minutes:
                        goalCurrentNumberSecond = duration.totalMinutes
                    case .hours:
                        goalCurrentNumberSecond = duration.totalMinutes
                    case .days:
                        goalCurrentNumberSecond = duration.totalMinutes
                    case .none, .count, .calories, .amount, .percent, .multiple, .level:
                        break
                    }
                    
                    switch goal.metricRelationshipSecond ?? .equalMore {
                    case .equalMore:
                        complete = goalCurrentNumberSecond >= goal.targetNumberSecond ?? 0
                    case .equalLess:
                        complete = goalCurrentNumberSecond <= goal.targetNumberSecond ?? 0
                    case .or, .and, .equal:
                        break
                    }
                    
                    self.task.isCompleted = complete
                    self.task.goal?.currentNumber = goalCurrentNumber
                    self.task.goal?.currentNumberSecond = goalCurrentNumberSecond
                    
                    checkRow.value = complete
                    checkRow.updateCell()
                    
                    metricSecondRow.value = self.task.goal?.cellDescriptionSecond
                    metricSecondRow.updateCell()

                    if complete {
                        checkRow.cell.tintAdjustmentMode = .automatic
                        
                        let original = Date()
                        let updateDate = Date(timeIntervalSinceReferenceDate:
                                                (original.timeIntervalSinceReferenceDate / 300.0).rounded(.toNearestOrEven) * 300.0)
                        completedRow.value = updateDate
                        completedRow.updateCell()
                        completedRow.hidden = false
                        completedRow.evaluateHidden()
                        
                        self.task.completedDate = NSNumber(value: Int((updateDate).timeIntervalSince1970))
                    } else {
                        checkRow.cell.tintAdjustmentMode = .dimmed
                        
                        completedRow.value = nil
                        completedRow.updateCell()
                        completedRow.hidden = true
                        completedRow.evaluateHidden()
                        
                        self.task.completedDate = nil
                    }
                    
                    let updateTask = ActivityActions(activity: self.task, active: self.active, selectedFalconUsers: self.selectedFalconUsers)
                    updateTask.updateCompletion(isComplete: complete, completeUpdatedByUser: false, goalCurrentNumber: goalCurrentNumber as NSNumber, goalCurrentNumberSecond: goalCurrentNumberSecond as NSNumber)
                }
            }
        }
    }
}

extension GoalViewController: ChooseActivityDelegate {
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
            updateLists(type: "container")
        }
    }
}

extension GoalViewController: UpdateTaskDelegate {
    func updateTask(task: Activity) {
        if let _ = task.name, let checkRow: CheckRow = self.form.rowBy(tag: "Completed"), let completedRow: DateTimeInlineRow = self.form.rowBy(tag: "Completed On"), let goal = self.task.goal {
            if goal.metric == .tasks, task.isCompleted ?? false, let metricRow: LabelRow = form.rowBy(tag: "Metric") {
                var goalCurrentNumber = goal.currentNumber ?? 0
                let goalCurrentNumberSecond = goal.currentNumberSecond ?? 0
                var complete = false
                
                goalCurrentNumber = 1
                switch goal.metricRelationship ?? .equalMore {
                case .equalMore:
                    complete = goalCurrentNumber >= goal.targetNumber ?? 0
                case .equalLess:
                    complete = goalCurrentNumber <= goal.targetNumber ?? 0
                case .or, .and, .equal:
                    break
                }
                
                self.task.isCompleted = complete
                self.task.goal?.currentNumber = goalCurrentNumber
                self.task.goal?.currentNumberSecond = goalCurrentNumberSecond
                
                checkRow.value = complete
                checkRow.updateCell()
                
                metricRow.value = self.task.goal?.cellDescriptionFirst
                metricRow.updateCell()
                
                if complete {
                    checkRow.cell.tintAdjustmentMode = .automatic
                    
                    let original = Date()
                    let updateDate = Date(timeIntervalSinceReferenceDate:
                                            (original.timeIntervalSinceReferenceDate / 300.0).rounded(.toNearestOrEven) * 300.0)
                    completedRow.value = updateDate
                    completedRow.updateCell()
                    completedRow.hidden = false
                    completedRow.evaluateHidden()
                    
                    self.task.completedDate = NSNumber(value: Int((updateDate).timeIntervalSince1970))
                } else {
                    checkRow.cell.tintAdjustmentMode = .dimmed
                    
                    completedRow.value = nil
                    completedRow.updateCell()
                    completedRow.hidden = true
                    completedRow.evaluateHidden()
                    
                    self.task.completedDate = nil
                }
                
                let updateTask = ActivityActions(activity: self.task, active: self.active, selectedFalconUsers: self.selectedFalconUsers)
                updateTask.updateCompletion(isComplete: complete, completeUpdatedByUser: false, goalCurrentNumber: goalCurrentNumber as NSNumber, goalCurrentNumberSecond: goalCurrentNumberSecond as NSNumber)
            } else if goal.metricSecond == .tasks, task.isCompleted ?? false, let metricSecondRow: LabelRow = form.rowBy(tag: "secondMetric") {
                let goalCurrentNumber = goal.currentNumber ?? 0
                var goalCurrentNumberSecond = goal.currentNumberSecond ?? 0
                var complete = false
                
                goalCurrentNumberSecond = 1
                switch goal.metricRelationshipSecond ?? .equalMore {
                case .equalMore:
                    complete = goalCurrentNumberSecond >= goal.targetNumberSecond ?? 0
                case .equalLess:
                    complete = goalCurrentNumberSecond <= goal.targetNumberSecond ?? 0
                case .or, .and, .equal:
                    break
                }
                
                self.task.isCompleted = complete
                self.task.goal?.currentNumber = goalCurrentNumber
                self.task.goal?.currentNumberSecond = goalCurrentNumberSecond
                
                checkRow.value = complete
                checkRow.updateCell()
                
                metricSecondRow.value = self.task.goal?.cellDescriptionSecond
                metricSecondRow.updateCell()

                if complete {
                    checkRow.cell.tintAdjustmentMode = .automatic
                    
                    let original = Date()
                    let updateDate = Date(timeIntervalSinceReferenceDate:
                                            (original.timeIntervalSinceReferenceDate / 300.0).rounded(.toNearestOrEven) * 300.0)
                    completedRow.value = updateDate
                    completedRow.updateCell()
                    completedRow.hidden = false
                    completedRow.evaluateHidden()
                    
                    self.task.completedDate = NSNumber(value: Int((updateDate).timeIntervalSince1970))
                } else {
                    checkRow.cell.tintAdjustmentMode = .dimmed
                    
                    completedRow.value = nil
                    completedRow.updateCell()
                    completedRow.hidden = true
                    completedRow.evaluateHidden()
                    
                    self.task.completedDate = nil
                }
                
                let updateTask = ActivityActions(activity: self.task, active: self.active, selectedFalconUsers: self.selectedFalconUsers)
                updateTask.updateCompletion(isComplete: complete, completeUpdatedByUser: false, goalCurrentNumber: goalCurrentNumber as NSNumber, goalCurrentNumberSecond: goalCurrentNumberSecond as NSNumber)
            }
        }
    }
}

extension GoalViewController: ChooseTaskDelegate {
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
            updateLists(type: "container")
        }
    }
}

extension GoalViewController: UpdateTransactionDelegate {
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
            updateLists(type: "container")
        }
        else if mvs.allRows.count - 1 > purchaseIndex {
            mvs.remove(at: purchaseIndex)
        }
//            purchaseBreakdown()
    }
}

extension GoalViewController: ChooseTransactionDelegate {
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
            updateLists(type: "container")
        }
        else if mvs.allRows.count - 1 > purchaseIndex {
            mvs.remove(at: purchaseIndex)
        }
//            purchaseBreakdown()
    }
}

extension GoalViewController: UpdateWorkoutDelegate {
    func updateWorkout(workout: Workout) {
        if workout.name != "Name", let checkRow: CheckRow = self.form.rowBy(tag: "Completed"), let completedRow: DateTimeInlineRow = self.form.rowBy(tag: "Completed On"), let goal = self.task.goal {
            if goal.metric == .workout, let metricRow: LabelRow = form.rowBy(tag: "Metric") {
                if goal.unit == .count {
                    var goalCurrentNumber = goal.currentNumber ?? 0
                    let goalCurrentNumberSecond = goal.currentNumberSecond ?? 0
                    var complete = false
                    
                    goalCurrentNumber = 1
                    switch goal.metricRelationship ?? .equalMore {
                    case .equalMore:
                        complete = goalCurrentNumber >= goal.targetNumber ?? 0
                    case .equalLess:
                        complete = goalCurrentNumber <= goal.targetNumber ?? 0
                    case .or, .and, .equal:
                        break
                    }
                    
                    self.task.isCompleted = complete
                    self.task.goal?.currentNumber = goalCurrentNumber
                    self.task.goal?.currentNumberSecond = goalCurrentNumberSecond
                    
                    checkRow.value = complete
                    checkRow.updateCell()
                    
                    metricRow.value = self.task.goal?.cellDescriptionFirst
                    metricRow.updateCell()
                    
                    if complete {
                        checkRow.cell.tintAdjustmentMode = .automatic
                        
                        let original = Date()
                        let updateDate = Date(timeIntervalSinceReferenceDate:
                                                (original.timeIntervalSinceReferenceDate / 300.0).rounded(.toNearestOrEven) * 300.0)
                        completedRow.value = updateDate
                        completedRow.updateCell()
                        completedRow.hidden = false
                        completedRow.evaluateHidden()
                        
                        self.task.completedDate = NSNumber(value: Int((updateDate).timeIntervalSince1970))
                    } else {
                        checkRow.cell.tintAdjustmentMode = .dimmed
                        
                        completedRow.value = nil
                        completedRow.updateCell()
                        completedRow.hidden = true
                        completedRow.evaluateHidden()
                        
                        self.task.completedDate = nil
                    }
                    
                    let updateTask = ActivityActions(activity: self.task, active: self.active, selectedFalconUsers: self.selectedFalconUsers)
                    updateTask.updateCompletion(isComplete: complete, completeUpdatedByUser: false, goalCurrentNumber: goalCurrentNumber as NSNumber, goalCurrentNumberSecond: goalCurrentNumberSecond as NSNumber)
                } else if goal.unit == .minutes, let startDate = workout.startDateTime?.localTime, let endDate = workout.endDateTime?.localTime {
                    var goalCurrentNumber = goal.currentNumber ?? 0
                    let goalCurrentNumberSecond = goal.currentNumberSecond ?? 0
                    var complete = false
                    
                    goalCurrentNumber = (endDate.timeIntervalSince1970 - startDate.timeIntervalSince1970) / 60
                    switch goal.metricRelationship ?? .equalMore {
                    case .equalMore:
                        complete = goalCurrentNumber >= goal.targetNumber ?? 0
                    case .equalLess:
                        complete = goalCurrentNumber <= goal.targetNumber ?? 0
                    case .or, .and, .equal:
                        break
                    }
                    
                    self.task.isCompleted = complete
                    self.task.goal?.currentNumber = goalCurrentNumber
                    self.task.goal?.currentNumberSecond = goalCurrentNumberSecond
                    
                    checkRow.value = complete
                    checkRow.updateCell()
                    
                    metricRow.value = self.task.goal?.cellDescriptionFirst
                    metricRow.updateCell()
                    
                    if complete {
                        checkRow.cell.tintAdjustmentMode = .automatic
                        
                        let original = Date()
                        let updateDate = Date(timeIntervalSinceReferenceDate:
                                                (original.timeIntervalSinceReferenceDate / 300.0).rounded(.toNearestOrEven) * 300.0)
                        completedRow.value = updateDate
                        completedRow.updateCell()
                        completedRow.hidden = false
                        completedRow.evaluateHidden()
                        
                        self.task.completedDate = NSNumber(value: Int((updateDate).timeIntervalSince1970))
                    } else {
                        checkRow.cell.tintAdjustmentMode = .dimmed
                        
                        completedRow.value = nil
                        completedRow.updateCell()
                        completedRow.hidden = true
                        completedRow.evaluateHidden()
                        
                        self.task.completedDate = nil
                    }
                    
                    let updateTask = ActivityActions(activity: self.task, active: self.active, selectedFalconUsers: self.selectedFalconUsers)
                    updateTask.updateCompletion(isComplete: complete, completeUpdatedByUser: false, goalCurrentNumber: goalCurrentNumber as NSNumber, goalCurrentNumberSecond: goalCurrentNumberSecond as NSNumber)
                } else if goal.unit == .calories, let calories = workout.totalEnergyBurned {
                    var goalCurrentNumber = goal.currentNumber ?? 0
                    let goalCurrentNumberSecond = goal.currentNumberSecond ?? 0
                    var complete = false
                    
                    goalCurrentNumber = calories
                    switch goal.metricRelationship ?? .equalMore {
                    case .equalMore:
                        complete = goalCurrentNumber >= goal.targetNumber ?? 0
                    case .equalLess:
                        complete = goalCurrentNumber <= goal.targetNumber ?? 0
                    case .or, .and, .equal:
                        break
                    }
                    
                    self.task.isCompleted = complete
                    self.task.goal?.currentNumber = goalCurrentNumber
                    self.task.goal?.currentNumberSecond = goalCurrentNumberSecond
                    
                    checkRow.value = complete
                    checkRow.updateCell()
                    
                    metricRow.value = self.task.goal?.cellDescriptionFirst
                    metricRow.updateCell()
                    
                    if complete {
                        checkRow.cell.tintAdjustmentMode = .automatic
                        
                        let original = Date()
                        let updateDate = Date(timeIntervalSinceReferenceDate:
                                                (original.timeIntervalSinceReferenceDate / 300.0).rounded(.toNearestOrEven) * 300.0)
                        completedRow.value = updateDate
                        completedRow.updateCell()
                        completedRow.hidden = false
                        completedRow.evaluateHidden()
                        
                        self.task.completedDate = NSNumber(value: Int((updateDate).timeIntervalSince1970))
                    } else {
                        checkRow.cell.tintAdjustmentMode = .dimmed
                        
                        completedRow.value = nil
                        completedRow.updateCell()
                        completedRow.hidden = true
                        completedRow.evaluateHidden()
                        
                        self.task.completedDate = nil
                    }
                    
                    let updateTask = ActivityActions(activity: self.task, active: self.active, selectedFalconUsers: self.selectedFalconUsers)
                    updateTask.updateCompletion(isComplete: complete, completeUpdatedByUser: false, goalCurrentNumber: goalCurrentNumber as NSNumber, goalCurrentNumberSecond: goalCurrentNumberSecond as NSNumber)
                }
            } else if goal.metricSecond == .workout, let metricSecondRow: LabelRow = form.rowBy(tag: "secondMetric") {
                if goal.unitSecond == .count {
                    let goalCurrentNumber = goal.currentNumber ?? 0
                    var goalCurrentNumberSecond = goal.currentNumberSecond ?? 0
                    var complete = false
                    
                    goalCurrentNumberSecond = 1
                    switch goal.metricRelationshipSecond ?? .equalMore {
                    case .equalMore:
                        complete = goalCurrentNumberSecond >= goal.targetNumberSecond ?? 0
                    case .equalLess:
                        complete = goalCurrentNumberSecond <= goal.targetNumberSecond ?? 0
                    case .or, .and, .equal:
                        break
                    }
                    
                    self.task.isCompleted = complete
                    self.task.goal?.currentNumber = goalCurrentNumber
                    self.task.goal?.currentNumberSecond = goalCurrentNumberSecond
                    
                    checkRow.value = complete
                    checkRow.updateCell()
                    
                    metricSecondRow.value = self.task.goal?.cellDescriptionSecond
                    metricSecondRow.updateCell()

                    if complete {
                        checkRow.cell.tintAdjustmentMode = .automatic
                        
                        let original = Date()
                        let updateDate = Date(timeIntervalSinceReferenceDate:
                                                (original.timeIntervalSinceReferenceDate / 300.0).rounded(.toNearestOrEven) * 300.0)
                        completedRow.value = updateDate
                        completedRow.updateCell()
                        completedRow.hidden = false
                        completedRow.evaluateHidden()
                        
                        self.task.completedDate = NSNumber(value: Int((updateDate).timeIntervalSince1970))
                    } else {
                        checkRow.cell.tintAdjustmentMode = .dimmed
                        
                        completedRow.value = nil
                        completedRow.updateCell()
                        completedRow.hidden = true
                        completedRow.evaluateHidden()
                        
                        self.task.completedDate = nil
                    }
                    
                    let updateTask = ActivityActions(activity: self.task, active: self.active, selectedFalconUsers: self.selectedFalconUsers)
                    updateTask.updateCompletion(isComplete: complete, completeUpdatedByUser: false, goalCurrentNumber: goalCurrentNumber as NSNumber, goalCurrentNumberSecond: goalCurrentNumberSecond as NSNumber)
                } else if goal.unitSecond == .minutes, let startDate = workout.startDateTime?.localTime, let endDate = workout.endDateTime?.localTime {
                    let goalCurrentNumber = goal.currentNumber ?? 0
                    var goalCurrentNumberSecond = goal.currentNumberSecond ?? 0
                    var complete = false
                    
                    goalCurrentNumberSecond = (endDate.timeIntervalSince1970 - startDate.timeIntervalSince1970) / 60
                    switch goal.metricRelationshipSecond ?? .equalMore {
                    case .equalMore:
                        complete = goalCurrentNumberSecond >= goal.targetNumberSecond ?? 0
                    case .equalLess:
                        complete = goalCurrentNumberSecond <= goal.targetNumberSecond ?? 0
                    case .or, .and, .equal:
                        break
                    }
                    
                    self.task.isCompleted = complete
                    self.task.goal?.currentNumber = goalCurrentNumber
                    self.task.goal?.currentNumberSecond = goalCurrentNumberSecond
                    
                    checkRow.value = complete
                    checkRow.updateCell()
                    
                    metricSecondRow.value = self.task.goal?.cellDescriptionSecond
                    metricSecondRow.updateCell()

                    if complete {
                        checkRow.cell.tintAdjustmentMode = .automatic
                        
                        let original = Date()
                        let updateDate = Date(timeIntervalSinceReferenceDate:
                                                (original.timeIntervalSinceReferenceDate / 300.0).rounded(.toNearestOrEven) * 300.0)
                        completedRow.value = updateDate
                        completedRow.updateCell()
                        completedRow.hidden = false
                        completedRow.evaluateHidden()
                        
                        self.task.completedDate = NSNumber(value: Int((updateDate).timeIntervalSince1970))
                    } else {
                        checkRow.cell.tintAdjustmentMode = .dimmed
                        
                        completedRow.value = nil
                        completedRow.updateCell()
                        completedRow.hidden = true
                        completedRow.evaluateHidden()
                        
                        self.task.completedDate = nil
                    }
                    
                    let updateTask = ActivityActions(activity: self.task, active: self.active, selectedFalconUsers: self.selectedFalconUsers)
                    updateTask.updateCompletion(isComplete: complete, completeUpdatedByUser: false, goalCurrentNumber: goalCurrentNumber as NSNumber, goalCurrentNumberSecond: goalCurrentNumberSecond as NSNumber)
                } else if goal.unitSecond == .calories, let calories = workout.totalEnergyBurned {
                    let goalCurrentNumber = goal.currentNumber ?? 0
                    var goalCurrentNumberSecond = goal.currentNumberSecond ?? 0
                    var complete = false
                    
                    goalCurrentNumberSecond = calories
                    switch goal.metricRelationshipSecond ?? .equalMore {
                    case .equalMore:
                        complete = goalCurrentNumberSecond >= goal.targetNumberSecond ?? 0
                    case .equalLess:
                        complete = goalCurrentNumberSecond <= goal.targetNumberSecond ?? 0
                    case .or, .and, .equal:
                        break
                    }
                    
                    self.task.isCompleted = complete
                    self.task.goal?.currentNumber = goalCurrentNumber
                    self.task.goal?.currentNumberSecond = goalCurrentNumberSecond
                    
                    checkRow.value = complete
                    checkRow.updateCell()
                    
                    metricSecondRow.value = self.task.goal?.cellDescriptionSecond
                    metricSecondRow.updateCell()

                    if complete {
                        checkRow.cell.tintAdjustmentMode = .automatic
                        
                        let original = Date()
                        let updateDate = Date(timeIntervalSinceReferenceDate:
                                                (original.timeIntervalSinceReferenceDate / 300.0).rounded(.toNearestOrEven) * 300.0)
                        completedRow.value = updateDate
                        completedRow.updateCell()
                        completedRow.hidden = false
                        completedRow.evaluateHidden()
                        
                        self.task.completedDate = NSNumber(value: Int((updateDate).timeIntervalSince1970))
                    } else {
                        checkRow.cell.tintAdjustmentMode = .dimmed
                        
                        completedRow.value = nil
                        completedRow.updateCell()
                        completedRow.hidden = true
                        completedRow.evaluateHidden()
                        
                        self.task.completedDate = nil
                    }
                    
                    let updateTask = ActivityActions(activity: self.task, active: self.active, selectedFalconUsers: self.selectedFalconUsers)
                    updateTask.updateCompletion(isComplete: complete, completeUpdatedByUser: false, goalCurrentNumber: goalCurrentNumber as NSNumber, goalCurrentNumberSecond: goalCurrentNumberSecond as NSNumber)
                }
            }
        }
    }
}

extension GoalViewController: UpdateMindfulnessDelegate {
    func updateMindfulness(mindfulness: Mindfulness) {
        if mindfulness.name != "Name", let checkRow: CheckRow = self.form.rowBy(tag: "Completed"), let completedRow: DateTimeInlineRow = self.form.rowBy(tag: "Completed On"), let goal = self.task.goal {
            if goal.metric == .mindfulness, let metricRow: LabelRow = form.rowBy(tag: "Metric") {
                if goal.unit == .count {
                    var goalCurrentNumber = goal.currentNumber ?? 0
                    let goalCurrentNumberSecond = goal.currentNumberSecond ?? 0
                    var complete = false
                    
                    goalCurrentNumber = 1
                    switch goal.metricRelationship ?? .equalMore {
                    case .equalMore:
                        complete = goalCurrentNumber >= goal.targetNumber ?? 0
                    case .equalLess:
                        complete = goalCurrentNumber <= goal.targetNumber ?? 0
                    case .or, .and, .equal:
                        break
                    }
                    
                    self.task.isCompleted = complete
                    self.task.goal?.currentNumber = goalCurrentNumber
                    self.task.goal?.currentNumberSecond = goalCurrentNumberSecond
                    
                    checkRow.value = complete
                    checkRow.updateCell()
                    
                    metricRow.value = self.task.goal?.cellDescriptionFirst
                    metricRow.updateCell()
                    
                    if complete {
                        checkRow.cell.tintAdjustmentMode = .automatic
                        
                        let original = Date()
                        let updateDate = Date(timeIntervalSinceReferenceDate:
                                                (original.timeIntervalSinceReferenceDate / 300.0).rounded(.toNearestOrEven) * 300.0)
                        completedRow.value = updateDate
                        completedRow.updateCell()
                        completedRow.hidden = false
                        completedRow.evaluateHidden()
                        
                        self.task.completedDate = NSNumber(value: Int((updateDate).timeIntervalSince1970))
                    } else {
                        checkRow.cell.tintAdjustmentMode = .dimmed
                        
                        completedRow.value = nil
                        completedRow.updateCell()
                        completedRow.hidden = true
                        completedRow.evaluateHidden()
                        
                        self.task.completedDate = nil
                    }
                    
                    let updateTask = ActivityActions(activity: self.task, active: self.active, selectedFalconUsers: self.selectedFalconUsers)
                    updateTask.updateCompletion(isComplete: complete, completeUpdatedByUser: false, goalCurrentNumber: goalCurrentNumber as NSNumber, goalCurrentNumberSecond: goalCurrentNumberSecond as NSNumber)
                } else if goal.unit == .minutes, let startDate = mindfulness.startDateTime?.localTime, let endDate = mindfulness.endDateTime?.localTime {
                    var goalCurrentNumber = goal.currentNumber ?? 0
                    let goalCurrentNumberSecond = goal.currentNumberSecond ?? 0
                    var complete = false
                    
                    goalCurrentNumber = (endDate.timeIntervalSince1970 - startDate.timeIntervalSince1970) / 60
                    switch goal.metricRelationship ?? .equalMore {
                    case .equalMore:
                        complete = goalCurrentNumber >= goal.targetNumber ?? 0
                    case .equalLess:
                        complete = goalCurrentNumber <= goal.targetNumber ?? 0
                    case .or, .and, .equal:
                        break
                    }
                    
                    self.task.isCompleted = complete
                    self.task.goal?.currentNumber = goalCurrentNumber
                    self.task.goal?.currentNumberSecond = goalCurrentNumberSecond
                    
                    checkRow.value = complete
                    checkRow.updateCell()
                    
                    metricRow.value = self.task.goal?.cellDescriptionFirst
                    metricRow.updateCell()
                    
                    if complete {
                        checkRow.cell.tintAdjustmentMode = .automatic
                        
                        let original = Date()
                        let updateDate = Date(timeIntervalSinceReferenceDate:
                                                (original.timeIntervalSinceReferenceDate / 300.0).rounded(.toNearestOrEven) * 300.0)
                        completedRow.value = updateDate
                        completedRow.updateCell()
                        completedRow.hidden = false
                        completedRow.evaluateHidden()
                        
                        self.task.completedDate = NSNumber(value: Int((updateDate).timeIntervalSince1970))
                    } else {
                        checkRow.cell.tintAdjustmentMode = .dimmed
                        
                        completedRow.value = nil
                        completedRow.updateCell()
                        completedRow.hidden = true
                        completedRow.evaluateHidden()
                        
                        self.task.completedDate = nil
                    }
                    
                    let updateTask = ActivityActions(activity: self.task, active: self.active, selectedFalconUsers: self.selectedFalconUsers)
                    updateTask.updateCompletion(isComplete: complete, completeUpdatedByUser: false, goalCurrentNumber: goalCurrentNumber as NSNumber, goalCurrentNumberSecond: goalCurrentNumberSecond as NSNumber)
                }
                
            } else if goal.metricSecond == .mindfulness, let metricSecondRow: LabelRow = form.rowBy(tag: "secondMetric") {
                if goal.unitSecond == .count {
                    let goalCurrentNumber = goal.currentNumber ?? 0
                    var goalCurrentNumberSecond = goal.currentNumberSecond ?? 0
                    var complete = false
                    
                    goalCurrentNumberSecond = 1
                    switch goal.metricRelationshipSecond ?? .equalMore {
                    case .equalMore:
                        complete = goalCurrentNumberSecond >= goal.targetNumberSecond ?? 0
                    case .equalLess:
                        complete = goalCurrentNumberSecond <= goal.targetNumberSecond ?? 0
                    case .or, .and, .equal:
                        break
                    }
                    
                    self.task.isCompleted = complete
                    self.task.goal?.currentNumber = goalCurrentNumber
                    self.task.goal?.currentNumberSecond = goalCurrentNumberSecond
                    
                    checkRow.value = complete
                    checkRow.updateCell()
                    
                    metricSecondRow.value = self.task.goal?.cellDescriptionSecond
                    metricSecondRow.updateCell()
                    
                    if complete {
                        checkRow.cell.tintAdjustmentMode = .automatic
                        
                        let original = Date()
                        let updateDate = Date(timeIntervalSinceReferenceDate:
                                                (original.timeIntervalSinceReferenceDate / 300.0).rounded(.toNearestOrEven) * 300.0)
                        completedRow.value = updateDate
                        completedRow.updateCell()
                        completedRow.hidden = false
                        completedRow.evaluateHidden()
                        
                        self.task.completedDate = NSNumber(value: Int((updateDate).timeIntervalSince1970))
                    } else {
                        checkRow.cell.tintAdjustmentMode = .dimmed
                        
                        completedRow.value = nil
                        completedRow.updateCell()
                        completedRow.hidden = true
                        completedRow.evaluateHidden()
                        
                        self.task.completedDate = nil
                    }
                    
                    let updateTask = ActivityActions(activity: self.task, active: self.active, selectedFalconUsers: self.selectedFalconUsers)
                    updateTask.updateCompletion(isComplete: complete, completeUpdatedByUser: false, goalCurrentNumber: goalCurrentNumber as NSNumber, goalCurrentNumberSecond: goalCurrentNumberSecond as NSNumber)
                } else if goal.unitSecond == .minutes, let startDate = mindfulness.startDateTime?.localTime, let endDate = mindfulness.endDateTime?.localTime {
                    let goalCurrentNumber = goal.currentNumber ?? 0
                    var goalCurrentNumberSecond = goal.currentNumberSecond ?? 0
                    var complete = false
                    
                    goalCurrentNumberSecond = (endDate.timeIntervalSince1970 - startDate.timeIntervalSince1970) / 60
                    switch goal.metricRelationshipSecond ?? .equalMore {
                    case .equalMore:
                        complete = goalCurrentNumberSecond >= goal.targetNumberSecond ?? 0
                    case .equalLess:
                        complete = goalCurrentNumberSecond <= goal.targetNumberSecond ?? 0
                    case .or, .and, .equal:
                        break
                    }
                    
                    self.task.isCompleted = complete
                    self.task.goal?.currentNumber = goalCurrentNumber
                    self.task.goal?.currentNumberSecond = goalCurrentNumberSecond
                    
                    checkRow.value = complete
                    checkRow.updateCell()
                    
                    metricSecondRow.value = self.task.goal?.cellDescriptionSecond
                    metricSecondRow.updateCell()

                    if complete {
                        checkRow.cell.tintAdjustmentMode = .automatic
                        
                        let original = Date()
                        let updateDate = Date(timeIntervalSinceReferenceDate:
                                                (original.timeIntervalSinceReferenceDate / 300.0).rounded(.toNearestOrEven) * 300.0)
                        completedRow.value = updateDate
                        completedRow.updateCell()
                        completedRow.hidden = false
                        completedRow.evaluateHidden()
                        
                        self.task.completedDate = NSNumber(value: Int((updateDate).timeIntervalSince1970))
                    } else {
                        checkRow.cell.tintAdjustmentMode = .dimmed
                        
                        completedRow.value = nil
                        completedRow.updateCell()
                        completedRow.hidden = true
                        completedRow.evaluateHidden()
                        
                        self.task.completedDate = nil
                    }
                    
                    let updateTask = ActivityActions(activity: self.task, active: self.active, selectedFalconUsers: self.selectedFalconUsers)
                    updateTask.updateCompletion(isComplete: complete, completeUpdatedByUser: false, goalCurrentNumber: goalCurrentNumber as NSNumber, goalCurrentNumberSecond: goalCurrentNumberSecond as NSNumber)
                }
            }
        }
    }
}

extension GoalViewController: UpdateMoodDelegate {
    func updateMood(mood: Mood) {
        if mood.mood != nil, let checkRow: CheckRow = self.form.rowBy(tag: "Completed"), let completedRow: DateTimeInlineRow = self.form.rowBy(tag: "Completed On"), let metricRow: LabelRow = form.rowBy(tag: "Metric"), let metricSecondRow: LabelRow = form.rowBy(tag: "secondMetric"), let goal = self.task.goal {
            var goalCurrentNumber = goal.currentNumber ?? 0
            var goalCurrentNumberSecond = goal.currentNumberSecond ?? 0
            var complete = false
            
            if goal.metric == .mood {
                goalCurrentNumber = 1
                switch goal.metricRelationship ?? .equalMore {
                case .equalMore:
                    complete = goalCurrentNumber >= goal.targetNumber ?? 0
                case .equalLess:
                    complete = goalCurrentNumber <= goal.targetNumber ?? 0
                case .or, .and, .equal:
                    break
                }
                
            } else if goal.metricSecond == .mood {
                goalCurrentNumberSecond = 1
                switch goal.metricRelationshipSecond ?? .equalMore {
                case .equalMore:
                    complete = goalCurrentNumberSecond >= goal.targetNumberSecond ?? 0
                case .equalLess:
                    complete = goalCurrentNumberSecond <= goal.targetNumberSecond ?? 0
                case .or, .and, .equal:
                    break
                }
            }
            
            self.task.isCompleted = complete
            self.task.goal?.currentNumber = goalCurrentNumber
            self.task.goal?.currentNumberSecond = goalCurrentNumberSecond
            
            checkRow.value = complete
            checkRow.updateCell()
            
            metricRow.value = self.task.goal?.cellDescriptionFirst
            metricRow.updateCell()
            
            metricSecondRow.value = self.task.goal?.cellDescriptionSecond
            metricSecondRow.updateCell()

            if complete {
                checkRow.cell.tintAdjustmentMode = .automatic
                
                let original = Date()
                let updateDate = Date(timeIntervalSinceReferenceDate:
                                        (original.timeIntervalSinceReferenceDate / 300.0).rounded(.toNearestOrEven) * 300.0)
                completedRow.value = updateDate
                completedRow.updateCell()
                completedRow.hidden = false
                completedRow.evaluateHidden()
                
                self.task.completedDate = NSNumber(value: Int((updateDate).timeIntervalSince1970))
            } else {
                checkRow.cell.tintAdjustmentMode = .dimmed
                
                completedRow.value = nil
                completedRow.updateCell()
                completedRow.hidden = true
                completedRow.evaluateHidden()
                
                self.task.completedDate = nil
            }
            
            let updateTask = ActivityActions(activity: self.task, active: self.active, selectedFalconUsers: self.selectedFalconUsers)
            updateTask.updateCompletion(isComplete: complete, completeUpdatedByUser: false, goalCurrentNumber: goalCurrentNumber as NSNumber, goalCurrentNumberSecond: goalCurrentNumberSecond as NSNumber)
        }
    }
}

extension GoalViewController: UpdateMediaDelegate {
    func updateMedia(imageURLs: [String], fileURLs: [String]) {
        task.activityPhotos = imageURLs
        task.activityFiles = fileURLs
        let activityReference = Database.database().reference().child(activitiesEntity).child(activityID).child(messageMetaDataFirebaseFolder)
        activityReference.updateChildValues(["activityPhotos": imageURLs as AnyObject])
        activityReference.updateChildValues(["activityFiles": fileURLs as AnyObject])
        if let row: LabelRow = form.rowBy(tag: "Media") {
            if let photos = self.task.activityPhotos, let files = self.task.activityFiles, photos.isEmpty, files.isEmpty {
                row.value = "0"
            } else {
                row.value = String((self.task.activityPhotos?.count ?? 0) + (self.task.activityFiles?.count ?? 0))
            }
            row.updateCell()
        }
    }
}

extension GoalViewController: UpdateActivityListDelegate {
    func updateActivityList(listList: [ListContainer]) {
        if let row: LabelRow = form.rowBy(tag: "Checklist") {
            if listList.isEmpty {
                row.value = "0"
            } else {
                row.value = String(listList.count)
            }
            row.updateCell()
        }
        self.listList = listList
        self.updateLists(type: "lists")
    }
}

extension GoalViewController: RecurrencePickerDelegate {
    func recurrencePicker(_ picker: RecurrencePicker, didPickRecurrence recurrenceRule: RecurrenceRule?) {
        if let row: LabelRow = form.rowBy(tag: "Repeat") {
            if let recurrenceRule = recurrenceRule {
                task.hasStartTime = false
                task.hasDeadlineTime = false
                task.recurrences = [recurrenceRule.toRRuleString()]
                let rowText = recurrenceRule.typeOfRecurrence(language: .english, occurrence: task.startDate ?? Date())
                row.value = rowText
                row.updateCell()
            } else {
                row.value = "Never"
                row.updateCell()
                self.task.recurrences = nil
            }
            self.updateDescriptionRow()
        }
    }
}

extension GoalViewController: UpdateTagsDelegate {
    func updateTags(tags: [String]?) {
        task.tags = tags
        let groupActivityReference = Database.database().reference().child(activitiesEntity).child(activityID).child(messageMetaDataFirebaseFolder)
        groupActivityReference.updateChildValues(["tags": tags as AnyObject])
    }
}

extension GoalViewController: UpdateTaskCellDelegate {
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
            updateTask.updateCompletion(isComplete: taskList[index].isCompleted ?? false, completeUpdatedByUser: taskList[index].isCompleted ?? false, goalCurrentNumber: nil, goalCurrentNumberSecond: nil)
        }
    }
}
