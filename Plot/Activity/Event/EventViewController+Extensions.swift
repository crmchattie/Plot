//
//  EventViewController+Extensions.swift
//  Plot
//
//  Created by Cory McHattie on 7/5/22.
//  Copyright © 2022 Immature Creations. All rights reserved.
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

extension EventViewController: UITextFieldDelegate {
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


//extension EventViewController: UITextViewDelegate {
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

extension EventViewController: UpdateActivityLevelDelegate {
    func update(value: String, level: String) {
        if let row: LabelRow = form.rowBy(tag: level) {
            row.value = value
            row.updateCell()
            if level == "Category" {
                self.activity.category = value
            } else if level == "Subcategory" {
                self.activity.activityType = value
            }
        }
    }
}

extension EventViewController: UpdateCalendarDelegate {
    func update(calendar: CalendarType) {
        if let row: LabelRow = form.rowBy(tag: "Calendar"), let calendarID = calendar.id {
            row.value = calendar.name
            row.updateCell()
            activity.calendarID = calendar.id
            activity.calendarName = calendar.name
            activity.calendarColor = calendar.color
            activity.calendarSource = calendar.source
            guard let currentUserID = Auth.auth().currentUser?.uid else { return }
            let userReference = Database.database().reference().child(userActivitiesEntity).child(currentUserID).child(self.activityID).child(messageMetaDataFirebaseFolder)
            let values:[String : Any] = ["calendarID": calendarID as Any, "calendarName": calendar.name as Any, "calendarColor": calendar.color as Any, "calendarSource": calendar.source as Any]
            userReference.updateChildValues(values)

            let calendarReference = Database.database().reference().child(calendarEntity).child(calendarID).child(calendarEventsEntity)
            calendarReference.child(self.activityID).setValue(true)
            
        }
    }
}

extension EventViewController: UpdateLocationDelegate {
    func updateLocation(locationName: String, locationAddress: [String : [Double]], zipcode: String, city: String, state: String, country: String) {
        if let locationRow: ButtonRow = form.rowBy(tag: "Location") {
            self.locationAddress[self.locationName] = nil
            if self.activity.locationAddress != nil {
                self.activity.locationAddress![self.locationName] = nil
            }
            for (key, value) in locationAddress {
                let newLocationName = key.removeCharacters()
                locationRow.title = newLocationName
                locationRow.updateCell()

                self.locationName = newLocationName
                self.locationAddress[newLocationName] = value
                
                self.activity.locationName = newLocationName
                if activity.locationAddress == nil {
                    self.activity.locationAddress = self.locationAddress
                } else {
                    self.activity.locationAddress![newLocationName] = value
                }
//                self.weatherRow()
            }
        }
    }
}

extension EventViewController: UpdateTimeZoneDelegate {
    func updateTimeZone(startOrEndTimeZone: String, timeZone: TimeZone) {
        if startOrEndTimeZone == "startTimeZone" {
            if let timeZoneRow: LabelRow = self.form.rowBy(tag: "startTimeZone"), let startRow: DateTimeInlineRow = self.form.rowBy(tag: "Starts") {
                startRow.dateFormatter?.timeZone = timeZone
                startRow.updateCell()
                startRow.inlineRow?.cell.datePicker.timeZone = timeZone
                startRow.inlineRow?.updateCell()
                timeZoneRow.value = timeZone.identifier
                timeZoneRow.updateCell()
                activity.startTimeZone = timeZone.identifier
            }
        } else if startOrEndTimeZone == "endTimeZone" {
            if let timeZoneRow: LabelRow = self.form.rowBy(tag: "endTimeZone"), let endRow: DateTimeInlineRow = self.form.rowBy(tag: "Ends") {
                endRow.dateFormatter?.timeZone = timeZone
                endRow.updateCell()
                endRow.inlineRow?.cell.datePicker.timeZone = timeZone
                endRow.inlineRow?.updateCell()
                timeZoneRow.value = timeZone.identifier
                timeZoneRow.updateCell()
                activity.endTimeZone = timeZone.identifier
            }
        }
    }
}

extension EventViewController: UpdateScheduleListDelegate {
    func updateScheduleList(scheduleList: [Activity]) {
        if let row: ButtonRow = form.rowBy(tag: "Sub-Events") {
            if scheduleList.isEmpty {
                row.cell.textLabel?.textColor = .secondaryLabel
            } else {
                row.cell.textLabel?.textColor = .label
            }
        }
        self.scheduleList = scheduleList
        sortSchedule()
        if let localAddress = activity.locationAddress {
            for (key, value) in localAddress {
                locationAddress[key] = value
            }
        }
        updateLists(type: "schedule")
    }
}

extension EventViewController: UpdateTaskDelegate {
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
                        task.listColor = color
                    } else if let list = networkController.activityService.lists[ListSourceOptions.plot.name]?.first(where: { $0.name == "Default"}), let color = list.color {
                        task.listColor = color
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
            updateLists(type: "container")
        }
    }
}

extension EventViewController: ChooseTaskDelegate {
    func chosenTask(mergeTask: Activity) {
        if let _: SubtaskRow = form.rowBy(tag: "label"), let mvs = self.form.sectionBy(tag: "Tasks") as? MultivaluedSection {
            mvs.remove(at: mvs.count - 2)
        }
        if let _ = mergeTask.name {
            var mvs = (form.sectionBy(tag: "Tasks") as! MultivaluedSection)
            mvs.insert(SubtaskRow() {
                if let listID = mergeTask.listID, let list = networkController.activityService.listIDs[listID], let color = list.color {
                    mergeTask.listColor = color
                } else if let list = networkController.activityService.lists[ListSourceOptions.plot.name]?.first(where: { $0.name == "Default"}), let color = list.color {
                    mergeTask.listColor = color
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

extension EventViewController: UpdateTransactionDelegate {
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

extension EventViewController: ChooseTransactionDelegate {
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

extension EventViewController: UpdateWorkoutDelegate {
    func updateWorkout(workout: Workout) {
        print("updateWorkout")
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

extension EventViewController: UpdateMindfulnessDelegate {
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

extension EventViewController: UpdateMediaDelegate {
    func updateMedia(imageURLs: [String], fileURLs: [String]) {
        activity.activityPhotos = imageURLs
        activity.activityFiles = fileURLs
        let activityReference = Database.database().reference().child(activitiesEntity).child(activityID).child(messageMetaDataFirebaseFolder)
        activityReference.updateChildValues(["activityPhotos": imageURLs as AnyObject])
        activityReference.updateChildValues(["activityFiles": fileURLs as AnyObject])
        if let mediaRow: ButtonRow = form.rowBy(tag: "Media") {
            if self.activity.activityPhotos == nil || self.activity.activityPhotos!.isEmpty || self.activity.activityFiles == nil || self.activity.activityFiles!.isEmpty {
                mediaRow.cell.textLabel?.textColor = .secondaryLabel
            } else {
                mediaRow.cell.textLabel?.textColor = .label
            }
        }
    }
}

extension EventViewController: UpdateActivityListDelegate {
    func updateActivityList(listList: [ListContainer]) {
        if let row: ButtonRow = form.rowBy(tag: "Checklist") {
            if listList.isEmpty {
                row.cell.textLabel?.textColor = .secondaryLabel
            } else {
                row.cell.textLabel?.textColor = .label
            }
        }
        self.listList = listList
        updateLists(type: "lists")
    }
}

extension EventViewController: RecurrencePickerDelegate {
    func recurrencePicker(_ picker: RecurrencePicker, didPickRecurrence recurrenceRule: RecurrenceRule?) {
        // do something, if recurrenceRule is nil, that means "never repeat".
        if let row: LabelRow = form.rowBy(tag: "Repeat"), let startDate = activity.startDate {
            if let recurrenceRule = recurrenceRule {
                let rowText = recurrenceRule.typeOfRecurrence(language: .english, occurrence: startDate)
                row.value = rowText
                row.updateCell()
                activity.recurrences = [recurrenceRule.toRRuleString()]
            } else {
                row.value = "Never"
                row.updateCell()
                activity.recurrences = nil
            }
        }
    }
}

extension EventViewController: UpdateTagsDelegate {
    func updateTags(tags: [String]?) {
        activity.tags = tags
        let groupActivityReference = Database.database().reference().child(activitiesEntity).child(activityID).child(messageMetaDataFirebaseFolder)
        groupActivityReference.updateChildValues(["tags": tags as AnyObject])
    }
}

extension EventViewController: UpdateTaskCellDelegate {
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
