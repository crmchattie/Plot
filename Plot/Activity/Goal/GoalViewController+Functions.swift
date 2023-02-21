//
//  GoalViewController+Functions.swift
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
import HealthKit

extension GoalViewController {
    
    func decimalRowFunc() {
        var mvs = form.sectionBy(tag: "Balances")
        for user in purchaseUsers {
            if let userName = user.name, let _ : DecimalRow = form.rowBy(tag: "\(userName)") {
                continue
            } else {
                purchaseDict[user] = 0.00
                if let mvsValue = mvs {
                    mvs?.insert(DecimalRow(user.name) {
                        $0.hidden = "$sections != 'Transactions'"
                        $0.tag = user.name
                        $0.useFormatterDuringInput = true
                        $0.cell.backgroundColor = .secondarySystemGroupedBackground
                        $0.cell.textLabel?.textColor = .label
                        $0.cell.textField?.textColor = .label
                        $0.title = user.name
                        $0.value = 0.00
                        $0.baseCell.isUserInteractionEnabled = false
                        let formatter = CurrencyFormatter()
                        formatter.locale = .current
                        formatter.numberStyle = .currency
                        $0.formatter = formatter
                    }.cellUpdate { cell, row in
                        cell.backgroundColor = .secondarySystemGroupedBackground
                        cell.textLabel?.textColor = .label
                        cell.textField?.textColor = .label
                        
                    }, at: mvsValue.count)
                }
            }
        }
        for (key, _) in purchaseDict {
            if !purchaseUsers.contains(key) {
                let sectionMVS : SegmentedRow<String> = form.rowBy(tag: "sections")!
                sectionMVS.value = "Transactions"
                sectionMVS.updateCell()
                purchaseDict[key] = nil
                if let decimalRow : DecimalRow = form.rowBy(tag: "\(key.name!)") {
                    mvs!.remove(at: decimalRow.indexPath!.row)
                }
            }
        }
    }
    
    func purchaseBreakdown() {
        purchaseDict = [User: Double]()
        for user in purchaseUsers {
            purchaseDict[user] = 0.00
        }
        for purchase in purchaseList {
            if let purchaser = purchase.admin {
                var costPerPerson: Double = 0.00
                if let purchaseRowCount = purchase.splitNumber {
                    costPerPerson = purchase.amount / Double(purchaseRowCount)
                } else if let participants = purchase.participantsIDs {
                    costPerPerson = purchase.amount / Double(participants.count)
                }
                // minus cost from purchaser's balance
                if let user = purchaseUsers.first(where: {$0.id == purchaser}) {
                    var value = purchaseDict[user] ?? 0.00
                    value -= costPerPerson
                    purchaseDict[user] = value
                }
                // add cost to non-purchasers balance
                if let participants = purchase.participantsIDs {
                    for ID in participants {
                        if let user = purchaseUsers.first(where: {$0.id == ID}), !purchaser.contains(ID) {
                            var value = purchaseDict[user] ?? 0.00
                            value += costPerPerson
                            purchaseDict[user] = value
                        }
                    }
                    // add cost to non-purchasers balance based on custom input
                } else {
                    for user in purchaseUsers {
                        if let ID = user.id, ID != purchaser {
                            var value = purchaseDict[user] ?? 0.00
                            value += costPerPerson
                            purchaseDict[user] = value
                        }
                    }
                }
            }
        }
        updateDecimalRow()
    }
    
    func updateDecimalRow() {
        for (user, value) in purchaseDict {
            if let userName = user.name, let decimalRow : DecimalRow = form.rowBy(tag: "\(userName)") {
                decimalRow.value = value
                decimalRow.updateCell()
            }
        }
    }
    
    func setupLists() {
        let dispatchGroup = DispatchGroup()
        for taskID in task.subtaskIDs ?? [] {
            dispatchGroup.enter()
            ActivitiesFetcher.getDataFromSnapshot(ID: taskID, parentID: task.instanceID ?? activityID) { fetched in
                self.subtaskList.append(contentsOf: fetched)
                dispatchGroup.leave()
            }
        }
        for checklistID in task.checklistIDs ?? [] {
            dispatchGroup.enter()
            let checklistDataReference = Database.database().reference().child(checklistsEntity).child(checklistID)
            checklistDataReference.observeSingleEvent(of: .value, with: { (snapshot) in
                if snapshot.exists(), let checklistSnapshotValue = snapshot.value, let checklist = try? FirebaseDecoder().decode(Checklist.self, from: checklistSnapshotValue) {
                    var list = ListContainer()
                    list.checklist = checklist
                    self.listList.append(list)
                }
                dispatchGroup.leave()
            })
        }
        if let containerID = task.containerID {
            dispatchGroup.enter()
            ContainerFunctions.grabContainerAndStuffInside(id: containerID) { container, activities, _, health, transactions in
                self.container = container
                self.eventList = activities ?? []
                self.healthList = health ?? []
                self.purchaseList = transactions ?? []
                dispatchGroup.leave()
            }
        }
        dispatchGroup.notify(queue: .main) {
//            self.listRow()
//                self.decimalRowFunc()
//                self.purchaseBreakdown()
        }
    }

    
    func listRow() {
        if delegate == nil && (!active || ((task?.participantsIDs?.contains(Auth.auth().currentUser?.uid ?? "") ?? false || task?.admin == Auth.auth().currentUser?.uid))) && !(task?.isGoal ?? false) {
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
            
            for health in healthList {
                var mvs = (form.sectionBy(tag: "Health") as! MultivaluedSection)
                mvs.insert(HealthRow() {
                    $0.value = health
                    }.onCellSelection() { cell, row in
                        self.healthIndex = row.indexPath!.row
                        self.openHealth()
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
    
    func sortSubtasks() {
        subtaskList.sort { (task1, task2) -> Bool in
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
        if let mvs = self.form.sectionBy(tag: "Sub-Tasks") as? MultivaluedSection {
            if mvs.count == 1 {
                return
            }
            for index in 0...mvs.count - 2 {
                let row = mvs.allRows[index]
                row.baseValue = subtaskList[index]
                row.reload()
            }
        }
    }
    
    func updateLists(type: String) {
        if type == "subtasks" {
            var subtaskIDs = [String]()
            for subtask in subtaskList {
                if let ID = subtask.activityID {
                    subtaskIDs.append(ID)
                }
            }
            if !subtaskIDs.isEmpty {
                task.subtaskIDs = subtaskIDs
            } else {
                task.subtaskIDs = nil
            }
        } else if type == "container" {
            if container != nil {
                container = Container(id: container.id, activityIDs: eventList.map({$0.activityID ?? ""}), taskIDs: container.taskIDs, workoutIDs: healthList.filter({ $0.workout != nil }).map({$0.ID}), mindfulnessIDs: healthList.filter({ $0.mindfulness != nil }).map({$0.ID}), mealIDs: nil, transactionIDs: purchaseList.map({$0.guid}), participantsIDs: task.participantsIDs)
            } else {
                let containerID = Database.database().reference().child(containerEntity).childByAutoId().key ?? ""
                container = Container(id: containerID, activityIDs: eventList.map({$0.activityID ?? ""}), taskIDs: [activityID], workoutIDs: healthList.filter({ $0.workout != nil }).map({$0.ID}), mindfulnessIDs: healthList.filter({ $0.mindfulness != nil }).map({$0.ID}), mealIDs: nil, transactionIDs: purchaseList.map({$0.guid}), participantsIDs: task.participantsIDs)
            }
            task.containerID = container.id
        } else {
            if listList.isEmpty {
                task.checklistIDs = nil
                task.grocerylistID = nil
                task.packinglistIDs = nil
                task.activitylistIDs = nil
            } else {
                var checklistIDs = [String]()
                var packinglistIDs = [String]()
                var activitylistIDs = [String]()
                var grocerylistID = "nothing"
                for list in listList {
                    if let checklist = list.checklist {
                        checklistIDs.append(checklist.ID!)
                    } else if let packinglist = list.packinglist {
                        packinglistIDs.append(packinglist.ID!)
                    } else if let grocerylist = list.grocerylist {
                        grocerylistID = grocerylist.ID!
                    } else if let activitylist = list.activitylist {
                        activitylistIDs.append(activitylist.ID!)
                    }
                }
                if !checklistIDs.isEmpty {
                    task.checklistIDs = checklistIDs
                } else {
                    task.checklistIDs = nil
                }
                if !activitylistIDs.isEmpty {
                    task.activitylistIDs = activitylistIDs
                } else {
                    task.activitylistIDs = nil
                }
                if grocerylistID != "nothing" {
                    task.grocerylistID = grocerylistID
                } else {
                    task.grocerylistID = nil
                }
                if !packinglistIDs.isEmpty {
                    task.packinglistIDs = packinglistIDs
                } else {
                    task.packinglistIDs = nil
                }
            }
        }
    }
    
    func updateListsFirebase(id: String) {
        let groupActivityReference = Database.database().reference().child(activitiesEntity).child(id).child(messageMetaDataFirebaseFolder)
        
        //subtasks
        var subtaskIDs = [String]()
        for subtask in subtaskList {
            if let ID = subtask.activityID {
                subtaskIDs.append(ID)
            }
        }
        if !subtaskIDs.isEmpty {
            groupActivityReference.updateChildValues(["subtaskIDs": subtaskIDs as AnyObject])
        } else {
            groupActivityReference.child("subtaskIDs").removeValue()
        }
        
        //container
        if let container = container {
            ContainerFunctions.updateContainerAndStuffInside(container: container)
//            if active {
//                ContainerFunctions.updateParticipants(containerID: container.id, selectedFalconUsers: selectedFalconUsers)
//            }
        }
        
        //lists
        if listList.isEmpty {
            groupActivityReference.child("checklistIDs").removeValue()
            groupActivityReference.child("grocerylistID").removeValue()
            groupActivityReference.child("packinglistIDs").removeValue()
            groupActivityReference.child("activitylistIDs").removeValue()
        } else {
            var checklistIDs = [String]()
            var packinglistIDs = [String]()
            var activitylistIDs = [String]()
            var grocerylistID = "nothing"
            for list in listList {
                if let checklist = list.checklist {
                    checklistIDs.append(checklist.ID!)
                } else if let packinglist = list.packinglist {
                    packinglistIDs.append(packinglist.ID!)
                } else if let grocerylist = list.grocerylist {
                    grocerylistID = grocerylist.ID!
                } else if let activitylist = list.activitylist {
                    activitylistIDs.append(activitylist.ID!)
                }
            }
            if !checklistIDs.isEmpty {
                groupActivityReference.updateChildValues(["checklistIDs": checklistIDs as AnyObject])
            } else {
                groupActivityReference.child("checklistIDs").removeValue()
            }
            if !activitylistIDs.isEmpty {
                groupActivityReference.updateChildValues(["activitylistIDs": activitylistIDs as AnyObject])
            } else {
                groupActivityReference.child("activitylistIDs").removeValue()
            }
            if grocerylistID != "nothing" {
                groupActivityReference.updateChildValues(["grocerylistID": grocerylistID as AnyObject])
            } else {
                groupActivityReference.child("grocerylistID").removeValue()
            }
            if !packinglistIDs.isEmpty {
                groupActivityReference.updateChildValues(["packinglistIDs": packinglistIDs as AnyObject])
            } else {
                groupActivityReference.child("packinglistIDs").removeValue()
            }
        }
    }
    
    func updateRepeatReminder() {
        if let _ = task.recurrences, !active {
            scheduleRecurrences()
        }
    }
    
    func scheduleRecurrences() {
        guard let task = task, let recurrences = task.recurrences, let endDate = task.endDate else {
            return
        }
        if let recurranceIndex = recurrences.firstIndex(where: { $0.starts(with: "RRULE") }) {
            var recurrenceRule = RecurrenceRule(rruleString: recurrences[recurranceIndex])
            recurrenceRule?.startDate = endDate
            var newRecurrences = recurrences
            newRecurrences[recurranceIndex] = recurrenceRule!.toRRuleString()
            self.task.recurrences = newRecurrences
        }
    }
    
    func updateRightBarButton() {
        if let _ = task.name, let goal = task.goal, let _ = goal.description {
            if goal.metric?.type != .pointInTime || (goal.metricSecond != nil && goal.metricSecond?.type != .pointInTime) {
                if task.endDateTime != nil && (goal.period != nil || task.startDateTime != nil) {
                    self.navigationItem.rightBarButtonItem?.isEnabled = true
                } else {
                    self.navigationItem.rightBarButtonItem?.isEnabled = false
                }
            } else {
                self.navigationItem.rightBarButtonItem?.isEnabled = true
            }
        } else {
            self.navigationItem.rightBarButtonItem?.isEnabled = false
        }
    }
    
    func updateGoal(selectedGoalProperty: SelectedGoalProperty, value: String?) {
        if let unitRow : PushRow<String> = self.form.rowBy(tag: "Unit"), let submetricRow : PushRow<String> = self.form.rowBy(tag: "Submetric"), let optionRow : MultipleSelectorRow<String> = self.form.rowBy(tag: "Option") {
            switch selectedGoalProperty {
            case .metric:
                if let value = value, let updatedValue = GoalMetric(rawValue: value) {
                    if let _ = task.goal {
                        task.goal!.metric = updatedValue
                    } else {
                        task.goal = Goal(name: nil, metric: updatedValue, submetric: nil, option: nil, unit: nil, period: nil, targetNumber: nil, currentNumber: nil, frequency: nil, metricSecond: nil, submetricSecond: nil, optionSecond: nil, unitSecond: nil, periodSecond: nil, targetNumberSecond: nil, currentNumberSecond: nil, metricsRelationshipType: nil)
                    }
                    
                    //units
                    if updatedValue.units.count > 0 {
                        task.goal!.unit = updatedValue.units[0]
                        unitRow.value = updatedValue.units[0].rawValue
                        unitRow.options = updatedValue.allValuesUnits
                    } else {
                        task.goal!.unit = nil
                        unitRow.value = nil
                    }
                    
                    //submetric
                    if updatedValue.submetrics.count > 0 {
                        submetricRow.hidden = false
                        submetricRow.evaluateHidden()
                        task.goal!.submetric = updatedValue.submetrics[0]
                        if submetricRow.value == updatedValue.submetrics[0].rawValue {
                            if let options = task.goal!.options() {
                                optionRow.value = Set(arrayLiteral: options[0])
                                optionRow.options = options
                                optionRow.hidden = false
                                optionRow.evaluateHidden()
                            } else {
                                task.goal!.option = nil
                                optionRow.hidden = true
                                optionRow.evaluateHidden()
                                optionRow.value = nil
                            }
                        } else {
                            submetricRow.value = updatedValue.submetrics[0].rawValue
                        }
                        submetricRow.options = updatedValue.allValuesSubmetrics
                    } else {
                        task.goal!.submetric = nil
                        submetricRow.hidden = true
                        submetricRow.evaluateHidden()
                        submetricRow.value = nil
                    }

                    
                    if let periodRow: PushRow<String> = form.rowBy(tag: "Period"), let switchDateRow: SwitchRow = self.form.rowBy(tag: "startDateSwitch") {
                        if updatedValue.type != .pointInTime || (task.goal!.metricSecond != nil && task.goal!.metricSecond?.type != .pointInTime) {
                            periodRow.hidden = Condition(booleanLiteral: task.goal?.period == nil && task.startDate != nil)
                            switchDateRow.hidden = Condition(booleanLiteral: task.goal?.period != nil)
                        } else {
                            periodRow.hidden = true
                            switchDateRow.hidden = true
                        }
                        periodRow.evaluateHidden()
                        switchDateRow.evaluateHidden()
                    }
                    
                }
            case .submetric:
                if let value = value, let updatedValue = GoalSubMetric(rawValue: value) {
                    if let _ = task.goal {
                        task.goal!.submetric = updatedValue
                    } else {
                        task.goal = Goal(name: nil, metric: nil, submetric: updatedValue, option: nil, unit: nil, period: nil, targetNumber: nil, currentNumber: nil, frequency: nil, metricSecond: nil, submetricSecond: nil, optionSecond: nil, unitSecond: nil, periodSecond: nil, targetNumberSecond: nil, currentNumberSecond: nil, metricsRelationshipType: nil)
                    }
                    if let options = task.goal!.options() {
                        optionRow.value = Set(arrayLiteral: options[0])
                        optionRow.options = options
                        optionRow.hidden = false
                        optionRow.evaluateHidden()
                    } else {
                        task.goal!.option = nil
                        optionRow.hidden = true
                        optionRow.evaluateHidden()
                        optionRow.value = nil
                    }
                } else {
                    task.goal!.option = nil
                    optionRow.hidden = true
                    optionRow.evaluateHidden()
                    optionRow.value = nil

                }
            case .unit, .option:
                break
            }
            updateDescriptionRow()
            updateCategorySubCategoryRows()
        }
    }
    
    func updateGoalSecondary(selectedGoalProperty: SelectedGoalProperty, value: String?) {
        if let unitRow : PushRow<String> = self.form.rowBy(tag: "secondUnit"), let submetricRow : PushRow<String> = self.form.rowBy(tag: "Second Submetric"), let optionRow : MultipleSelectorRow<String> = self.form.rowBy(tag: "Second Option"), let _ = task.goal {
            switch selectedGoalProperty {
            case .metric:
                if let value = value, let updatedValue = GoalMetric(rawValue: value) {
                    task.goal!.metricSecond = updatedValue
                    
                    //units
                    if updatedValue.units.count > 0 {
                        task.goal!.unitSecond = updatedValue.units[0]
                        unitRow.value = updatedValue.units[0].rawValue
                        unitRow.options = updatedValue.allValuesUnits
                    } else {
                        task.goal!.unitSecond = nil
                        unitRow.value = nil
                    }
                                                            
                    //submetric
                    if value != "None", updatedValue.submetrics.count > 0 {
                        submetricRow.hidden = false
                        submetricRow.evaluateHidden()
                        task.goal!.submetricSecond = updatedValue.submetrics[0]
                        if submetricRow.value == updatedValue.submetrics[0].rawValue {
                            if let options = task.goal!.options() {
                                optionRow.value = Set(arrayLiteral: options[0])
                                optionRow.options = options
                                optionRow.hidden = false
                                optionRow.evaluateHidden()
                            } else {
                                task.goal!.option = nil
                                optionRow.hidden = true
                                optionRow.evaluateHidden()
                                optionRow.value = nil
                            }
                        } else {
                            submetricRow.value = updatedValue.submetrics[0].rawValue
                        }
                        submetricRow.options = updatedValue.allValuesSubmetrics
                    } else {
                        task.goal!.submetricSecond = nil
                        submetricRow.hidden = true
                        submetricRow.evaluateHidden()
                        submetricRow.value = nil
                    }
                    
                    if let periodRow: PushRow<String> = form.rowBy(tag: "Period"), let switchDateRow: SwitchRow = self.form.rowBy(tag: "startDateSwitch") {
                        if updatedValue.type != .pointInTime || (task.goal!.metricSecond != nil && task.goal!.metricSecond?.type != .pointInTime) {
                            periodRow.hidden = Condition(booleanLiteral: task.goal?.period == nil && task.startDate != nil)
                            switchDateRow.hidden = Condition(booleanLiteral: task.goal?.period != nil)
                        } else {
                            periodRow.hidden = true
                            switchDateRow.hidden = true
                        }
                        periodRow.evaluateHidden()
                        switchDateRow.evaluateHidden()
                    }
                    
                } else {
                    task.goal!.metricSecond = nil
                    task.goal!.submetricSecond = nil
                    task.goal!.unitSecond = nil
                    task.goal!.periodSecond = nil
                    submetricRow.hidden = true
                    submetricRow.evaluateHidden()
                    submetricRow.value = nil
                    unitRow.value = nil
                    
                    if let periodRow: PushRow<String> = form.rowBy(tag: "Period"), let switchDateRow: SwitchRow = self.form.rowBy(tag: "startDateSwitch") {
                        if task.goal!.metric!.type != .pointInTime {
                            periodRow.hidden = Condition(booleanLiteral: task.goal?.period == nil && task.startDate != nil)
                            switchDateRow.hidden = Condition(booleanLiteral: task.goal?.period != nil)
                        } else {
                            periodRow.hidden = true
                            switchDateRow.hidden = true
                        }
                        periodRow.evaluateHidden()
                        switchDateRow.evaluateHidden()
                    }
                }
                
            case .submetric:
                if let value = value, let updatedValue = GoalSubMetric(rawValue: value) {
                    task.goal!.submetricSecond = updatedValue
                    if let options = task.goal!.optionsSecond() {
                        optionRow.value = Set(arrayLiteral: options[0])
                        optionRow.options = options
                        optionRow.hidden = false
                        optionRow.evaluateHidden()
                    } else {
                        task.goal!.optionSecond = nil
                        optionRow.hidden = true
                        optionRow.evaluateHidden()
                        optionRow.value = nil
                    }
                } else {
                    task.goal!.optionSecond = nil
                    optionRow.hidden = true
                    optionRow.evaluateHidden()
                    optionRow.value = nil

                }
            case .unit, .option:
                break
            }
            updateDescriptionRow()
        }
    }
    
    func updateDescriptionRow() {
        if let descriptionRow: LabelRow = self.form.rowBy(tag: "Description") {
            if let goal = task.goal, let description = goal.description {
                var updatedDescription = description
                if let secondaryDescription = goal.descriptionSecondary {
                    updatedDescription += secondaryDescription
                }
                if let task = task, let recurrences = task.recurrences, let recurrenceRule = RecurrenceRule(rruleString: recurrences[0]) {
                    var value = String()
                    if let endDate = self.task.instanceOriginalStartDate {
                        value = recurrenceRule.typeOfRecurrence(language: .english, occurrence: endDate)
                    } else if let endDate = self.task.endDate {
                        value = recurrenceRule.typeOfRecurrence(language: .english, occurrence: endDate)
                    }
                    updatedDescription += " " + value.lowercased()
                } else if let startDate = self.task.startDate, let endDate = self.task.endDate {
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateStyle = .medium
                    dateFormatter.timeStyle = task.hasDeadlineTime ?? false ? .short : .none
                    updatedDescription += " from " + dateFormatter.string(from: startDate) + " to " + dateFormatter.string(from: endDate)
                } else if let endDate = self.task.endDate {
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateStyle = .medium
                    dateFormatter.timeStyle = task.hasDeadlineTime ?? false ? .short : .none
                    updatedDescription += " by " + dateFormatter.string(from: endDate)
                }
                
                descriptionRow.title = updatedDescription
                descriptionRow.updateCell()
                descriptionRow.hidden = false
                descriptionRow.evaluateHidden()
            } else {
                descriptionRow.hidden = true
                descriptionRow.evaluateHidden()
            }
            updateRightBarButton()
        }
    }
    
    func updateSecondTargetRow() {
        if let secondTargetRow : DecimalRow = self.form.rowBy(tag: "Second Target"), let targetRow : DecimalRow = self.form.rowBy(tag: "Target"), let metricsRelationshipRow : PushRow<String> = self.form.rowBy(tag: "metricsRelationship") {
            if let metricsRelationshipValue = metricsRelationshipRow.value {
                if targetRow.value == nil, secondTargetRow.value == nil {
                    targetRow.hidden = false
                    targetRow.evaluateHidden()
                    secondTargetRow.hidden = false
                    secondTargetRow.evaluateHidden()
                } else if metricsRelationshipValue == "Equal" || metricsRelationshipValue == "More" || metricsRelationshipValue == "Less" {
                    if targetRow.value != nil {
                        secondTargetRow.hidden = true
                        secondTargetRow.evaluateHidden()
                    } else if secondTargetRow.value != nil {
                        targetRow.hidden = true
                        targetRow.evaluateHidden()
                    }
                } else {
                    targetRow.hidden = false
                    targetRow.evaluateHidden()
                    secondTargetRow.hidden = false
                    secondTargetRow.evaluateHidden()
                }
                
                if let currentRow : DecimalRow = self.form.rowBy(tag: "Current") {
                    currentRow.hidden = Condition(booleanLiteral: targetRow.isHidden)
                    currentRow.evaluateHidden()
                }
                
                if let secondCurrentRow : DecimalRow = self.form.rowBy(tag: "Second Current") {
                    secondCurrentRow.hidden = Condition(booleanLiteral: secondTargetRow.isHidden)
                    secondCurrentRow.evaluateHidden()
                }
                                
                //hide second target and current row given metricsRelationship value is nil
            } else if !secondTargetRow.isHidden {
                secondTargetRow.value = nil
                secondTargetRow.hidden = true
                secondTargetRow.evaluateHidden()
                
                if let secondCurrentRow : DecimalRow = self.form.rowBy(tag: "Second Current") {
                    secondCurrentRow.value = nil
                    secondCurrentRow.hidden = true
                    secondCurrentRow.evaluateHidden()
                }
            }
            self.updateDescriptionRow()

        }
    }
    
    func updateCategorySubCategoryRows() {
        if let categoryRow: LabelRow = self.form.rowBy(tag: "Category"), let subcategoryRow: LabelRow = self.form.rowBy(tag: "Subcategory"), let goal = task.goal {
            let category = goal.category
            let subcategory = goal.subcategory
            
            categoryRow.value = category.rawValue
            categoryRow.updateCell()
            subcategoryRow.value = subcategory.rawValue
            subcategoryRow.updateCell()
            
            task.category = category.rawValue
            task.category = subcategory.rawValue
            
            if let listRow: LabelRow = self.form.rowBy(tag: "List"), let lists = self.lists[ListSourceOptions.plot.name] {
                var list: ListType?
                if category == .finances, let newList = lists.first(where: { $0.financeList ?? false }) {
                    list = newList
                } else if category == .health, let newList = lists.first(where: { $0.healthList ?? false }) {
                    list = newList
                } else if let newList = lists.first(where: { $0.defaultList ?? false }) {
                    list = newList
                }
                
                if let list = list, let ID = list.id {
                    listRow.value = list.name
                    listRow.updateCell()
                    
                    task.listID = ID
                    task.listName = list.name
                    task.listColor = list.color
                    task.listSource = list.source
                    
                    if active, let source = list.source, source == ListSourceOptions.plot.name {
                        let listReference = Database.database().reference().child(listEntity).child(ID).child(listTasksEntity)
                        listReference.child(self.activityID).setValue(true)
                    }
                }
            }
        }
    }
    
    func updateNumberRows() {
        let numberFormatter = NumberFormatter()
        numberFormatter.currencyCode = "USD"
        numberFormatter.maximumFractionDigits = 0
        if let goal = task.goal, let unit = goal.unit {
            switch unit {
            case .calories:
                numberFormatter.numberStyle = .decimal
            case .count:
                numberFormatter.numberStyle = .decimal
            case .amount:
                numberFormatter.numberStyle = .currency
            case .percent:
                numberFormatter.numberStyle = .percent
            case .multiple:
                numberFormatter.numberStyle = .decimal
            case .minutes:
                numberFormatter.numberStyle = .decimal
            case .hours:
                numberFormatter.numberStyle = .decimal
                numberFormatter.maximumFractionDigits = 1
            case .days:
                numberFormatter.numberStyle = .decimal
            case .level:
                numberFormatter.numberStyle = .decimal
            }
            if let targetRow : DecimalRow = self.form.rowBy(tag: "Target") {
                targetRow.formatter = numberFormatter
                if let value = goal.targetNumber {
                    targetRow.value = value
                }
                if let currentRow : DecimalRow = self.form.rowBy(tag: "Current") {
                    currentRow.formatter = numberFormatter
                    if let value = goal.currentNumber {
                        currentRow.value = value
                    }
                }
            }
        }
    }
    
    func updateNumberRowsSecond() {
        let numberFormatter = NumberFormatter()
        numberFormatter.currencyCode = "USD"
        numberFormatter.maximumFractionDigits = 0
        if let targetRow : DecimalRow = self.form.rowBy(tag: "Second Target") {
            if let goal = task.goal, let unit = goal.unitSecond {
                switch unit {
                case .calories:
                    numberFormatter.numberStyle = .decimal
                case .count:
                    numberFormatter.numberStyle = .decimal
                case .amount:
                    numberFormatter.numberStyle = .currency
                case .percent:
                    numberFormatter.numberStyle = .percent
                case .multiple:
                    numberFormatter.numberStyle = .decimal
                case .minutes:
                    numberFormatter.numberStyle = .decimal
                case .hours:
                    numberFormatter.numberStyle = .decimal
                    numberFormatter.maximumFractionDigits = 1
                case .days:
                    numberFormatter.numberStyle = .decimal
                case .level:
                    numberFormatter.numberStyle = .decimal
                }
                targetRow.formatter = numberFormatter
                if let value = goal.targetNumberSecond {
                    targetRow.value = value
                }
                if let currentRow : DecimalRow = self.form.rowBy(tag: "Second Current") {
                    currentRow.formatter = numberFormatter
                    if let value = goal.currentNumberSecond {
                        currentRow.value = value
                    }
                }
            } else {
                targetRow.value = nil
            }
        }
    }
    
    func openLevel(value: String, level: String) {
        let destination = ActivityLevelViewController()
        destination.delegate = self
        destination.value = value
        destination.level = level
        self.navigationController?.pushViewController(destination, animated: true)
    }
    
    func openTaskList() {
        let destination = ChooseListViewController(networkController: networkController)
        destination.delegate = self
        destination.listID = self.task.listID ?? self.lists[ListSourceOptions.plot.name]?.first(where: {$0.defaultList ?? false})?.id
        if let source = self.task.listSource, let lists = self.lists[source] {
            destination.lists = [source: lists]
        } else {
            destination.lists = [ListSourceOptions.plot.name: self.lists[ListSourceOptions.plot.name] ?? []]
        }
        self.navigationController?.pushViewController(destination, animated: true)
    }
    
    func openRepeat() {
        guard currentReachabilityStatus != .notReachable else {
            basicErrorAlertWithClose(title: basicErrorTitleForAlert, message: noInternetError, controller: self)
            return
        }
        
        // initialization and configuration
        // RecurrencePicker can be initialized with a recurrence rule or nil, nil means "never repeat"
        var recurrencePicker = RecurrencePicker(recurrenceRule: nil)
        if let recurrences = task.recurrences, let recurrence = recurrences.first(where: { $0.starts(with: "RRULE") }) {
            let recurrenceRule = RecurrenceRule(rruleString: recurrence)
            recurrencePicker = RecurrencePicker(recurrenceRule: recurrenceRule)
        }
        recurrencePicker.language = .english
        recurrencePicker.calendar = Calendar.current
        recurrencePicker.tintColor = FalconPalette.defaultBlue
        recurrencePicker.occurrenceDate = task.endDate ?? Date()
        recurrencePicker.isGoal = true

        // assign delegate
        recurrencePicker.delegate = self

        // push to the picker scene
        navigationController?.pushViewController(recurrencePicker, animated: true)
    }
    
    func openMedia() {
        guard currentReachabilityStatus != .notReachable else {
            basicErrorAlertWithClose(title: basicErrorTitleForAlert, message: noInternetError, controller: self)
            return
        }
        let destination = MediaViewController()
        destination.delegate = self
        if let imageURLs = task.activityPhotos {
            destination.imageURLs = imageURLs
        }
        if let fileURLs = task.activityFiles {
            destination.fileURLs = fileURLs
        }
        self.navigationController?.pushViewController(destination, animated: true)
    }
    
    //update so existing invitees are shown as selected
    func openParticipantsInviter() {
        guard currentReachabilityStatus != .notReachable else {
            basicErrorAlertWithClose(title: basicErrorTitleForAlert, message: noInternetError, controller: self)
            return
        }
        let destination = SelectActivityMembersViewController()
        var uniqueUsers = users
        for participant in selectedFalconUsers {
            if let userIndex = users.firstIndex(where: { (user) -> Bool in
                return user.id == participant.id }) {
                uniqueUsers[userIndex] = participant
            } else {
                uniqueUsers.append(participant)
            }
        }
        destination.ownerID = task.admin
        destination.users = uniqueUsers
        destination.filteredUsers = uniqueUsers
        if !selectedFalconUsers.isEmpty {
            destination.priorSelectedUsers = selectedFalconUsers
        }
        destination.delegate = self
        self.navigationController?.pushViewController(destination, animated: true)
    }
    
    func openSubtasks() {
        guard currentReachabilityStatus != .notReachable else {
            basicErrorAlertWithClose(title: basicErrorTitleForAlert, message: noInternetError, controller: self)
            return
        }
        
        let destination = SubtaskListViewController()
        destination.delegate = self
        destination.subtaskList = subtaskList
        destination.selectedFalconUsers = selectedFalconUsers
        destination.tasks = tasks
        destination.task = task
        self.navigationController?.pushViewController(destination, animated: true)
    
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
                    self.showEventDetailPush(event: nil, updateDiscoverDelegate: nil, delegate: self, task: self.task, transaction: nil, workout: nil, mindfulness: nil, template: nil, users: self.selectedFalconUsers, container: container, startDateTime: nil, endDateTime: nil)
                } else {
                    let containerID = Database.database().reference().child(containerEntity).childByAutoId().key ?? ""
                    self.container = Container(id: containerID, activityIDs: self.eventList.map({$0.activityID ?? ""}), taskIDs: [self.activityID], workoutIDs: self.healthList.filter({ $0.workout != nil }).map({$0.ID}), mindfulnessIDs: self.healthList.filter({ $0.mindfulness != nil }).map({$0.ID}), mealIDs: nil, transactionIDs: self.purchaseList.map({$0.guid}), participantsIDs: self.task.participantsIDs)
                    self.showEventDetailPush(event: nil, updateDiscoverDelegate: nil, delegate: self, task: self.task, transaction: nil, workout: nil, mindfulness: nil, template: nil, users: self.selectedFalconUsers, container: self.container, startDateTime: nil, endDateTime: nil)
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
                    self.container = Container(id: containerID, activityIDs: self.eventList.map({$0.activityID ?? ""}), taskIDs: [self.activityID], workoutIDs: self.healthList.filter({ $0.workout != nil }).map({$0.ID}), mindfulnessIDs: self.healthList.filter({ $0.mindfulness != nil }).map({$0.ID}), mealIDs: nil, transactionIDs: self.purchaseList.map({$0.guid}), participantsIDs: self.task.participantsIDs)
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
    
    func openHealth() {
        if healthList.indices.contains(healthIndex), let workout = healthList[healthIndex].workout {
            showWorkoutDetailPush(workout: workout, updateDiscoverDelegate: nil, delegate: self, template: nil, users: self.selectedFalconUsers, container: nil, movingBackwards: true)
        } else if healthList.indices.contains(healthIndex), let mindfulness = healthList[healthIndex].mindfulness {
            showMindfulnessDetailPush(mindfulness: mindfulness, updateDiscoverDelegate: nil, delegate: self, template: nil, users: self.selectedFalconUsers, container: nil, movingBackwards: true)
        } else {
            let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            alert.addAction(UIAlertAction(title: "New Workout", style: .default, handler: { (_) in
                if let container = self.container {
                    self.showWorkoutDetailPush(workout: nil, updateDiscoverDelegate: nil, delegate: self, template: nil, users: self.selectedFalconUsers, container: container, movingBackwards: true)
                } else {
                    let containerID = Database.database().reference().child(containerEntity).childByAutoId().key ?? ""
                    self.container = Container(id: containerID, activityIDs: self.eventList.map({$0.activityID ?? ""}), taskIDs: [self.activityID], workoutIDs: self.healthList.filter({ $0.workout != nil }).map({$0.ID}), mindfulnessIDs: self.healthList.filter({ $0.mindfulness != nil }).map({$0.ID}), mealIDs: nil, transactionIDs: self.purchaseList.map({$0.guid}), participantsIDs: self.task.participantsIDs)
                    self.showWorkoutDetailPush(workout: nil, updateDiscoverDelegate: nil, delegate: self, template: nil, users: self.selectedFalconUsers, container: self.container, movingBackwards: true)
                }
            }))
            alert.addAction(UIAlertAction(title: "New Mindfulness", style: .default, handler: { (_) in
                if let container = self.container {
                    self.showMindfulnessDetailPush(mindfulness: nil, updateDiscoverDelegate: nil, delegate: self, template: nil, users: self.selectedFalconUsers, container: container, movingBackwards: true)
                } else {
                    let containerID = Database.database().reference().child(containerEntity).childByAutoId().key ?? ""
                    self.container = Container(id: containerID, activityIDs: self.eventList.map({$0.activityID ?? ""}), taskIDs: [self.activityID], workoutIDs: self.healthList.filter({ $0.workout != nil }).map({$0.ID}), mindfulnessIDs: self.healthList.filter({ $0.mindfulness != nil }).map({$0.ID}), mealIDs: nil, transactionIDs: self.purchaseList.map({$0.guid}), participantsIDs: self.task.participantsIDs)
                    self.showMindfulnessDetailPush(mindfulness: nil, updateDiscoverDelegate: nil, delegate: self, template: nil, users: self.selectedFalconUsers, container: self.container, movingBackwards: true)
                }
            }))
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (_) in
                if let mvs = self.form.sectionBy(tag: "Health") as? MultivaluedSection {
                    mvs.remove(at: self.healthIndex)
                }
            }))
            self.present(alert, animated: true)
        }
    }
    
    func openList() {
        guard currentReachabilityStatus != .notReachable else {
            basicErrorAlertWithClose(title: basicErrorTitleForAlert, message: noInternetError, controller: self)
            return
        }
        
        let destination = ActivityListViewController()
        destination.delegate = self
        destination.listList = listList
        destination.activity = task
        self.navigationController?.pushViewController(destination, animated: true)
    }
    
    func openTags() {
        let destination = TagsViewController()
        destination.delegate = self
        destination.tags = task.tags
        self.navigationController?.pushViewController(destination, animated: true)
    }
    
    @IBAction func cancel(_ sender: AnyObject) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @objc func createNewActivity() {
        if active, let oldRecurrences = self.taskOld.recurrences, let oldRecurranceIndex = oldRecurrences.firstIndex(where: { $0.starts(with: "RRULE") }), let oldRecurrenceRule = RecurrenceRule(rruleString: oldRecurrences[oldRecurranceIndex]), let endDate = taskOld.endDate, oldRecurrenceRule.typeOfRecurrence(language: .english, occurrence: endDate) != "Never", let currentUserID = Auth.auth().currentUser?.uid {
            if self.task.recurrences == nil {
                self.deleteRecurrences()
            } else {
                let alert = UIAlertController(title: nil, message: "This is a repeating goal.", preferredStyle: .actionSheet)
                alert.addAction(UIAlertAction(title: "Save For This Goal Only", style: .default, handler: { (_) in
                    if self.task.instanceID == nil {
                        let instanceID = Database.database().reference().child(userActivitiesEntity).child(currentUserID).childByAutoId().key ?? ""
                        self.task.instanceID = instanceID
                        
                        var instanceIDs = self.task.instanceIDs ?? []
                        instanceIDs.append(instanceID)
                        self.task.instanceIDs = instanceIDs
                    }
                    
                    self.updateListsFirebase(id: self.task.instanceID!)
                    
                    let newActivity = self.task.getDifferenceBetweenActivitiesNewInstance(otherActivity: self.taskOld)
                    var instanceValues = newActivity.toAnyObject()
                    
                    if self.task.instanceOriginalStartDateTime == nil {
                        instanceValues["instanceOriginalStartDateTime"] = self.taskOld.finalDateTime
                        self.task.instanceOriginalStartDateTime = self.taskOld.finalDateTime
                    }
                    
                    let createActivity = ActivityActions(activity: self.task, active: self.active, selectedFalconUsers: self.selectedFalconUsers)
                    createActivity.updateInstance(instanceValues: instanceValues, updateExternal: true)
                    self.closeController(title: taskUpdatedMessage)
                }))
                
                alert.addAction(UIAlertAction(title: "Save For Future Goals", style: .default, handler: { (_) in
                    print("Save for future events")
                    //update task's recurrence to stop repeating just before this event
                    if let dateIndex = self.task.instanceIndex {
                        if dateIndex == 0 {
                            //update all instances of task
                            self.createActivity(title: tasksUpdatedMessage)
                        } else if let newRecurrences = self.task.recurrences, let newRecurranceIndex = newRecurrences.firstIndex(where: { $0.starts(with: "RRULE") }) {
                            var oldActivityRule = oldRecurrenceRule
                            //update only future instances of task
                            var newActivityRule = RecurrenceRule(rruleString: newRecurrences[newRecurranceIndex])
                            newActivityRule!.startDate = self.task.endDate ?? Date()
                            
                            var newRecurrences = oldRecurrences
                            newRecurrences[newRecurranceIndex] = newActivityRule!.toRRuleString()
                            
                            //duplicate task w/ new ID and same recurrence rule starting from this event's date
                            self.duplicateActivity(recurrenceRule: newRecurrences)
                            
                            //update existing task with end date equaling ocurrence before this date
                            oldActivityRule.recurrenceEnd = EKRecurrenceEnd(occurrenceCount: dateIndex)
                            
                            self.taskOld.recurrences![oldRecurranceIndex] = oldActivityRule.toRRuleString()
                            self.updateRecurrences(recurrences: self.taskOld.recurrences!, title: tasksUpdatedMessage)
                        }
                    }
                }))
                
                alert.addAction(UIAlertAction(title: "Save For All Goals", style: .default, handler: { (_) in
                    //update all instances of activity
                    if let dateIndex = self.task.instanceIndex {
                        if dateIndex == 0 {
                            //update all instances of task
                            self.createActivity(title: tasksUpdatedMessage)
                        } else if let date = self.task.recurrenceStartDateTime {
                            //update all instances of activity
                            self.task.endDateTime = date
                            self.createActivity(title: tasksUpdatedMessage)
                        }
                    }
                }))
                
                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (_) in
                    print("User click Dismiss button")
                }))
                
                self.present(alert, animated: true, completion: {
                    print("completion block")
                })
            }
        } else {
            if !active {
                self.createActivity(title: taskCreatedMessage)
            } else {
                self.createActivity(title: taskUpdatedMessage)
            }
        }
//        do not want to have in duplicate functionality
//        else {
//            let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
//
//            alert.addAction(UIAlertAction(title: "Update Task", style: .default, handler: { (_) in
//                print("User click Edit button")
//                self.createActivity(title: taskUpdatedMessage)
//            }))
//
//            alert.addAction(UIAlertAction(title: "Duplicate Task", style: .default, handler: { (_) in
//                print("User click Edit button")
//                self.duplicateActivity(recurrenceRule: nil)
//            }))
//
//            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (_) in
//                print("User click Dismiss button")
//            }))
//
//            self.present(alert, animated: true, completion: {
//                print("completion block")
//            })
//
//        }
    }
    
    
    func closeController(title: String) {
        if let updateDiscoverDelegate = self.updateDiscoverDelegate {
            updateDiscoverDelegate.itemCreated(title: title)
            if navigationItem.leftBarButtonItem != nil {
                self.dismiss(animated: true, completion: nil)
            } else {
                self.navigationController?.popViewController(animated: true)
            }
        } else {
            if navigationItem.leftBarButtonItem != nil {
                self.dismiss(animated: true, completion: nil)
            } else {
                self.navigationController?.popViewController(animated: true)
            }
            basicAlert(title: title, message: nil, controller: self.navigationController?.presentingViewController)
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
    
    func updateRecurrences(recurrences: [String], title: String) {
        showActivityIndicator()
        let createActivity = ActivityActions(activity: self.task, active: active, selectedFalconUsers: selectedFalconUsers)
        createActivity.updateRecurrences(recurrences: recurrences)
        hideActivityIndicator()
        closeController(title: title)
    }
    
    func deleteRecurrences() {
        let createActivity = ActivityActions(activity: self.task, active: active, selectedFalconUsers: selectedFalconUsers)
        createActivity.deleteRecurrences()
    }
    
    func createActivity(title: String) {
        showActivityIndicator()
        self.updateListsFirebase(id: activityID)
        let createActivity = ActivityActions(activity: self.task, active: active, selectedFalconUsers: selectedFalconUsers)
        createActivity.createNewActivity(updateDirectAssociation: true)
        hideActivityIndicator()
        self.delegate?.updateTask(task: self.task)
        closeController(title: title)
    }
    
    func showActivityIndicator() {
        if let navController = self.navigationController {
            self.showSpinner(onView: navController.view)
        } else {
            self.showSpinner(onView: self.view)
        }
        self.navigationController?.view.isUserInteractionEnabled = false
    }
    
    func hideActivityIndicator() {
        self.navigationController?.view.isUserInteractionEnabled = true
        self.removeSpinner()
    }
    
    func updateStartDateGoal() {
        if let dateSwitchRow: SwitchRow = form.rowBy(tag: "startDateSwitch"), let dateSwitchRowValue = dateSwitchRow.value, let dateRow: DatePickerRow = form.rowBy(tag: "StartDate"), let periodRow: PushRow<String> = form.rowBy(tag: "Period") {
            if dateSwitchRowValue, let dateRowValue = dateRow.value {
                periodRow.hidden = true
                periodRow.evaluateHidden()
                var dateComponents = DateComponents()
                dateComponents.year = dateRowValue.yearNumber()
                dateComponents.month = dateRowValue.monthNumber()
                dateComponents.day = dateRowValue.dayNumber()
                let date = Calendar.current.date(from: dateComponents)
                self.task.startDateTime = NSNumber(value: Int((date)?.timeIntervalSince1970 ?? 0))
                self.task.hasStartTime = false                
            } else {
                periodRow.hidden = false
                periodRow.evaluateHidden()
                self.task.startDateTime = nil
                self.task.hasStartTime = false
            }
            self.updateDescriptionRow()
        }
    }
    
    func updateDeadlineDateGoal() {
        if let dateSwitchRow: SwitchRow = form.rowBy(tag: "deadlineDateSwitch"), let dateSwitchRowValue = dateSwitchRow.value, let dateRow: DatePickerRow = form.rowBy(tag: "DeadlineDate") {
            if dateSwitchRowValue, let dateRowValue = dateRow.value {
                var dateComponents = DateComponents()
                dateComponents.year = dateRowValue.yearNumber()
                dateComponents.month = dateRowValue.monthNumber()
                dateComponents.day = dateRowValue.dayNumber()
                let date = Calendar.current.date(from: dateComponents)
                self.task.endDateTime = NSNumber(value: Int((date)?.timeIntervalSince1970 ?? 0))
                self.task.hasDeadlineTime = false
            } else {
                self.task.endDateTime = nil
                self.task.hasDeadlineTime = false
            }
            self.updateDescriptionRow()
            self.updateRepeatReminder()
        }
    }
    
    @objc func goToExtras() {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        let title = "Delete Goal"
        alert.addAction(UIAlertAction(title: title, style: .default, handler: { (_) in
            self.deleteActivity()
        }))
        
        if let name = task.name, let locationName = task.locationName, locationName != "locationName", let locationAddress = task.locationAddress, let longlat = locationAddress[locationName] {
            alert.addAction(UIAlertAction(title: "Route Address", style: .default, handler: { (_) in
                OpenMapDirections.present(in: self, name: name, latitude: longlat[0], longitude: longlat[1])
            }))
            alert.addAction(UIAlertAction(title: "Map Address", style: .default, handler: { (_) in
                self.goToMap()
            }))
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (_) in
            print("User click Dismiss button")
        }))
        
        self.present(alert, animated: true, completion: {
            print("completion block")
        })
        print("shareButtonTapped")
        
    }
    
    @objc func goToMap() {
        guard currentReachabilityStatus != .notReachable else {
            basicErrorAlertWithClose(title: basicErrorTitleForAlert, message: noInternetError, controller: self)
            return
        }
        
        
        let destination = MapViewController()
        destination.sections = [.event]
        var locations = [task]
        
        for subtask in subtaskList {
            if subtask.locationName != nil, subtask.locationName != "locationName" {
                locations.append(subtask)
            }
        }
        
        destination.locations = [.event: locations]
        navigationController?.pushViewController(destination, animated: true)
        
    }
    
    func deleteActivity() {
        //need to look into equatable protocol for activities
        if let oldRecurrences = self.taskOld.recurrences, let oldRecurranceIndex = oldRecurrences.firstIndex(where: { $0.starts(with: "RRULE") }), let oldRecurrenceRule = RecurrenceRule(rruleString: oldRecurrences[oldRecurranceIndex]), let endDate = taskOld.endDate, oldRecurrenceRule.typeOfRecurrence(language: .english, occurrence: endDate) != "Never" {
            let alert = UIAlertController(title: nil, message: "This is a repeating goal.", preferredStyle: .actionSheet)
            
            alert.addAction(UIAlertAction(title: "Delete This Goal Only", style: .default, handler: { (_) in
                print("Save for this event only")
                //update activity's recurrence to skip repeat on this date
                var oldActivityRule = oldRecurrenceRule
                //update existing activity with exlusion date that fall's on this date
                oldActivityRule.exdate = ExclusionDate(dates: [endDate], granularity: .day)
                self.task.recurrences!.append(oldActivityRule.exdate!.toExDateString()!)
                self.updateRecurrences(recurrences: self.task.recurrences!, title: taskDeletedMessage)
            }))
            
            alert.addAction(UIAlertAction(title: "Delete All Future Goals", style: .default, handler: { (_) in
                //update activity's recurrence to stop repeating at this event
                if let dateIndex = self.task.instanceIndex {
                    //will equal true if first instance of repeating event
                    if dateIndex == 0 {
                        self.showActivityIndicator()
                        let deleteActivity = ActivityActions(activity: self.task, active: self.active, selectedFalconUsers: self.selectedFalconUsers)
                        deleteActivity.deleteActivity(updateExternal: true, updateDirectAssociation: true)
                        self.hideActivityIndicator()
                        self.closeController(title: tasksDeletedMessage)
                    } else {
                        var oldActivityRule = oldRecurrenceRule
                        //update existing activity with end date equaling ocurrence of this date
                        oldActivityRule.recurrenceEnd = EKRecurrenceEnd(occurrenceCount: dateIndex)
                        self.task.recurrences = [oldActivityRule.toRRuleString()]
                        self.updateRecurrences(recurrences: self.task.recurrences!, title: tasksDeletedMessage)
                    }
                }
            }))
            
            alert.addAction(UIAlertAction(title: "Delete All Goals", style: .default, handler: { (_) in
                self.showActivityIndicator()
                let deleteActivity = ActivityActions(activity: self.task, active: self.active, selectedFalconUsers: self.selectedFalconUsers)
                deleteActivity.deleteActivity(updateExternal: true, updateDirectAssociation: true)
                self.hideActivityIndicator()
                self.closeController(title: tasksDeletedMessage)
            }))
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (_) in
                print("User click Dismiss button")
            }))
            
            self.present(alert, animated: true, completion: {
                print("completion block")
            })
        } else {
            let alert = UIAlertController(title: nil, message: "Are you sure?", preferredStyle: .actionSheet)
            
            alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { (_) in
                print("Save for this event only")
                self.showActivityIndicator()
                let deleteActivity = ActivityActions(activity: self.task, active: self.active, selectedFalconUsers: self.selectedFalconUsers)
                deleteActivity.deleteActivity(updateExternal: true, updateDirectAssociation: true)
                self.hideActivityIndicator()
                self.closeController(title: taskDeletedMessage)
            }))
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (_) in
                print("User click Dismiss button")
            }))
            
            self.present(alert, animated: true, completion: {
                print("completion block")
            })
        }
    }
    
    func duplicateActivity(recurrenceRule: [String]?) {
        if let task = task, let currentUserID = Auth.auth().currentUser?.uid {
            var newActivityID: String!
            newActivityID = Database.database().reference().child(userActivitiesEntity).child(currentUserID).childByAutoId().key ?? ""
            
            let newActivity = task.copy() as! Activity
            newActivity.activityID = newActivityID
            if let recurrenceRule = recurrenceRule {
                updateListsFirebase(id: newActivityID)
                newActivity.recurrences = recurrenceRule
            } else {
                updateListsFirebase(id: activityID)
                updateListsFirebase(id: newActivityID)
                newActivity.recurrences = nil
            }
            
            let createActivity = ActivityActions(activity: newActivity, active: false, selectedFalconUsers: selectedFalconUsers)
            createActivity.createNewActivity(updateDirectAssociation: false)
        }
    }
    
    func resetBadgeForSelf() {
        guard let currentUserID = Auth.auth().currentUser?.uid else { return }
        let badgeRef = Database.database().reference().child(userActivitiesEntity).child(currentUserID).child(activityID).child(messageMetaDataFirebaseFolder).child("badge")
        badgeRef.runTransactionBlock({ (mutableData) -> TransactionResult in
            var value = mutableData.value as? Int
            value = 0
            mutableData.value = value!
            return TransactionResult.success(withValue: mutableData)
        })
        if let task = task, task.badgeDate != nil {
            let badgeRef = Database.database().reference().child(userActivitiesEntity).child(currentUserID).child(activityID).child(messageMetaDataFirebaseFolder).child("badgeDate")
            badgeRef.runTransactionBlock({ (mutableData) -> TransactionResult in
                var value = mutableData.value as? [String: AnyObject]
                if value == nil, let finalDateTime = self.task.finalDateTime {
                    value = [String(describing: Int(truncating: finalDateTime)): 0 as AnyObject]
                } else if let finalDateTime = self.task.finalDateTime {
                    value![String(describing: Int(truncating: finalDateTime))] = 0 as AnyObject
                }
                mutableData.value = value
                return TransactionResult.success(withValue: mutableData)
            })
        }
    }
    
    func incrementBadgeForReciever(activityID: String?, participantsIDs: [String]) {
        guard let currentUserID = Auth.auth().currentUser?.uid, let activityID = activityID else { return }
        for participantID in participantsIDs where participantID != currentUserID {
            runActivityBadgeUpdate(firstChild: participantID, secondChild: activityID)
            runUserBadgeUpdate(firstChild: participantID)
        }
    }
    
    func runActivityBadgeUpdate(firstChild: String, secondChild: String) {
        var ref = Database.database().reference().child(userActivitiesEntity).child(firstChild).child(secondChild)
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            
            guard snapshot.hasChild(messageMetaDataFirebaseFolder) else {
                ref = ref.child(messageMetaDataFirebaseFolder)
                ref.updateChildValues(["badge": 1])
                return
            }
            ref = ref.child(messageMetaDataFirebaseFolder).child("badge")
            ref.runTransactionBlock({ (mutableData) -> TransactionResult in
                var value = mutableData.value as? Int
                if value == nil { value = 0 }
                mutableData.value = value! + 1
                return TransactionResult.success(withValue: mutableData)
            })
        })
    }
}
