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
        print("updateGoal")
        if let goal = goal {
            if number == 0, let row: LabelRow = form.rowBy(tag: "Metric") {
                print("row exists")
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
            updateLists(type: "container")
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
        var mvs = self.form.sectionBy(tag: "Health") as! MultivaluedSection
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
            updateLists(type: "container")
        }
        else if mvs.allRows.count - 1 > healthIndex {
            mvs.remove(at: healthIndex)
        }
    }
}

extension GoalViewController: UpdateMindfulnessDelegate {
    func updateMindfulness(mindfulness: Mindfulness) {
        var mvs = self.form.sectionBy(tag: "Health") as! MultivaluedSection
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
            updateLists(type: "container")
        }
        else if mvs.allRows.count - 1 > healthIndex {
            mvs.remove(at: healthIndex)
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
