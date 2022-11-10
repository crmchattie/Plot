//
//  TaskViewController+Functions.swift
//  Plot
//
//  Created by Cory McHattie on 8/16/22.
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
import HealthKit

extension TaskViewController {
    
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
            print("containerID")
            print(containerID)
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
            self.listRow()
//                self.decimalRowFunc()
//                self.purchaseBreakdown()
        }
    }

    
    func listRow() {
        if delegate == nil && (!active || ((task?.participantsIDs?.contains(Auth.auth().currentUser?.uid ?? "") ?? false || task?.admin == Auth.auth().currentUser?.uid))) {
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
            if active {
                ContainerFunctions.updateParticipants(containerID: container.id, selectedFalconUsers: selectedFalconUsers)
            }
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
        if let _ = task.reminder {
            scheduleReminder()
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
    
    func scheduleReminder() {
        guard let task = task, let activityReminder = task.reminder, let endDate = task.endDate else {
            return
        }
        let center = UNUserNotificationCenter.current()
        guard activityReminder != "None" else {
            center.removePendingNotificationRequests(withIdentifiers: ["\(activityID)_Reminder"])
            return
        }
        let content = UNMutableNotificationContent()
        content.title = "\(String(describing: task.name!)) Reminder"
        content.sound = UNNotificationSound.default
        var formattedDate: (Int, String, String) = (1, "", "")
        formattedDate = timestampOfTask(endDate: endDate, hasDeadlineTime: task.hasDeadlineTime ?? false, startDate: task.startDate, hasStartTime: task.hasStartTime)
        content.subtitle = formattedDate.2
        if let reminder = EventAlert(rawValue: activityReminder) {
            let reminderDate = endDate.addingTimeInterval(reminder.timeInterval)
            let calendar = Calendar.current
            let triggerDate = calendar.dateComponents([.year,.month,.day,.hour,.minute,.second], from: reminderDate)
            let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate,
                                                        repeats: false)
            let identifier = "\(activityID)_Reminder"
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
            center.add(request, withCompletionHandler: { (error) in
                if let error = error {
                    print(error)
                }
            })
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
        
        // prepare a recurrence rule and an occurrence date
        // occurrence date is the date which the repeat event occurs this time
        let recurrences = task.recurrences
        let occurrenceDate = task.endDate ?? Date()

        // initialization and configuration
        // RecurrencePicker can be initialized with a recurrence rule or nil, nil means "never repeat"
        var recurrencePicker = RecurrencePicker(recurrenceRule: nil)
        if let recurrences = recurrences {
            let recurrenceRule = RecurrenceRule(rruleString: recurrences[0])
            recurrencePicker = RecurrencePicker(recurrenceRule: recurrenceRule)
        }
        recurrencePicker.language = .english
        recurrencePicker.calendar = Calendar.current
        recurrencePicker.tintColor = FalconPalette.defaultBlue
        recurrencePicker.occurrenceDate = occurrenceDate

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
        if active, let oldRecurrences = self.taskOld.recurrences, let oldRecurranceIndex = oldRecurrences.firstIndex(where: { $0.starts(with: "RRULE") }), let oldRecurrenceRule = RecurrenceRule(rruleString: oldRecurrences[oldRecurranceIndex]), let endDate = taskOld.endDate, let recurrenceStartDate = task.recurrenceStartDate, oldRecurrenceRule.typeOfRecurrence(language: .english, occurrence: endDate) != "Never", let currentUserID = Auth.auth().currentUser?.uid {
            let alert = UIAlertController(title: nil, message: "This is a repeating event.", preferredStyle: .actionSheet)
            alert.addAction(UIAlertAction(title: "Save For This Task Only", style: .default, handler: { (_) in
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
            
            alert.addAction(UIAlertAction(title: "Save For Future Tasks", style: .default, handler: { (_) in
                print("Save for future events")
                //update task's recurrence to stop repeating just before this event
                var oldActivityRule = oldRecurrenceRule
                //will equal true if first instance of repeating event
                let futureDate = Calendar.current.date(byAdding: .month, value: 3, to: Date())
                let dayBeforeNowDate = Calendar.current.date(byAdding: .day, value: -1, to: recurrenceStartDate)
                let dates = iCalUtility()
                    .recurringDates(forRules: oldRecurrences, ruleStartDate: recurrenceStartDate, startDate: dayBeforeNowDate ?? Date(), endDate: futureDate ?? Date())
                if let dateIndex = dates.firstIndex(of: endDate) {
                    if dateIndex == 0 {
                        //update all instances of task
                        if self.task.recurrences == nil {
                            self.deleteRecurrences()
                        }
                        self.createActivity(title: tasksUpdatedMessage)
                    } else if let newRecurrences = self.task.recurrences, let newRecurranceIndex = newRecurrences.firstIndex(where: { $0.starts(with: "RRULE") }) {

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
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (_) in
                print("User click Dismiss button")
            }))
            
            self.present(alert, animated: true, completion: {
                print("completion block")
            })
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
    
    func updateStartDate() {
        if let dateSwitchRow: SwitchRow = form.rowBy(tag: "startDateSwitch"), let dateSwitchRowValue = dateSwitchRow.value, let dateRow: DatePickerRow = form.rowBy(tag: "StartDate"), let timeSwitchRow: SwitchRow = form.rowBy(tag: "startTimeSwitch"), let timeSwitchRowValue = timeSwitchRow.value, let timeRow: TimePickerRow = form.rowBy(tag: "StartTime") {
            if dateSwitchRowValue, timeSwitchRowValue, let dateRowValue = dateRow.value, let timeRowValue = timeRow.value {
                var dateComponents = DateComponents()
                dateComponents.year = dateRowValue.yearNumber()
                dateComponents.month = dateRowValue.monthNumber()
                dateComponents.day = dateRowValue.dayNumber()
                dateComponents.hour = timeRowValue.hourNumber()
                dateComponents.minute = timeRowValue.minuteNumber()
                let date = Calendar.current.date(from: dateComponents)
                self.task.startDateTime = NSNumber(value: Int((date)?.timeIntervalSince1970 ?? 0))
                self.task.hasStartTime = true
            } else if dateSwitchRowValue, let dateRowValue = dateRow.value {
                var dateComponents = DateComponents()
                dateComponents.year = dateRowValue.yearNumber()
                dateComponents.month = dateRowValue.monthNumber()
                dateComponents.day = dateRowValue.dayNumber()
                let date = Calendar.current.date(from: dateComponents)
                self.task.startDateTime = NSNumber(value: Int((date)?.timeIntervalSince1970 ?? 0))
                self.task.hasStartTime = false
            } else {
                self.task.startDateTime = nil
                self.task.hasStartTime = false
            }
            self.updateRepeatReminder()
        }
    }
    
    func updateDeadlineDate() {
        if let dateSwitchRow: SwitchRow = form.rowBy(tag: "deadlineDateSwitch"), let dateSwitchRowValue = dateSwitchRow.value, let dateRow: DatePickerRow = form.rowBy(tag: "DeadlineDate"), let timeSwitchRow: SwitchRow = form.rowBy(tag: "deadlineTimeSwitch"), let timeSwitchRowValue = timeSwitchRow.value, let timeRow: TimePickerRow = form.rowBy(tag: "DeadlineTime") {
            if dateSwitchRowValue, timeSwitchRowValue, let dateRowValue = dateRow.value, let timeRowValue = timeRow.value {
                var dateComponents = DateComponents()
                dateComponents.year = dateRowValue.yearNumber()
                dateComponents.month = dateRowValue.monthNumber()
                dateComponents.day = dateRowValue.dayNumber()
                dateComponents.hour = timeRowValue.hourNumber()
                dateComponents.minute = timeRowValue.minuteNumber()
                let date = Calendar.current.date(from: dateComponents)
                self.task.endDateTime = NSNumber(value: Int((date)?.timeIntervalSince1970 ?? 0))
                self.task.hasDeadlineTime = true
            } else if dateSwitchRowValue, let dateRowValue = dateRow.value {
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
            self.updateRepeatReminder()
        }
    }
    
    @objc func goToExtras() {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "Delete Task", style: .default, handler: { (_) in
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
        if let oldRecurrences = self.taskOld.recurrences, let oldRecurranceIndex = oldRecurrences.firstIndex(where: { $0.starts(with: "RRULE") }), let oldRecurrenceRule = RecurrenceRule(rruleString: oldRecurrences[oldRecurranceIndex]), let endDate = taskOld.endDate, let recurrenceStartDate = task.recurrenceStartDate, oldRecurrenceRule.typeOfRecurrence(language: .english, occurrence: endDate) != "Never" {
            let alert = UIAlertController(title: nil, message: "This is a repeating event.", preferredStyle: .actionSheet)
            
            alert.addAction(UIAlertAction(title: "Delete This Task Only", style: .default, handler: { (_) in
                print("Save for this event only")
                //update activity's recurrence to skip repeat on this date
                var oldActivityRule = oldRecurrenceRule
                //update existing activity with exlusion date that fall's on this date
                oldActivityRule.exdate = ExclusionDate(dates: [endDate], granularity: .day)
                self.task.recurrences!.append(oldActivityRule.exdate!.toExDateString()!)
                self.updateRecurrences(recurrences: self.task.recurrences!, title: taskDeletedMessage)
            }))
            
            alert.addAction(UIAlertAction(title: "Delete All Future Tasks", style: .default, handler: { (_) in
                //update activity's recurrence to stop repeating at this event
                var oldActivityRule = oldRecurrenceRule
                let yearFromNowDate = Calendar.current.date(byAdding: .year, value: 1, to: Date())
                let dayBeforeNowDate = Calendar.current.date(byAdding: .day, value: -1, to: recurrenceStartDate)
                let dates = iCalUtility()
                    .recurringDates(forRules: oldRecurrences, ruleStartDate: recurrenceStartDate, startDate: dayBeforeNowDate ?? Date(), endDate: yearFromNowDate ?? Date())
                if let dateIndex = dates.firstIndex(of: endDate) {
                    //will equal true if first instance of repeating event
                    if dateIndex == 0 {
                        self.showActivityIndicator()
                        let deleteActivity = ActivityActions(activity: self.task, active: self.active, selectedFalconUsers: self.selectedFalconUsers)
                        deleteActivity.deleteActivity(updateExternal: true, updateDirectAssociation: true)
                        self.hideActivityIndicator()
                        self.closeController(title: tasksDeletedMessage)
                    } else {
                        //update existing activity with end date equaling ocurrence of this date
                        oldActivityRule.recurrenceEnd = EKRecurrenceEnd(occurrenceCount: dateIndex)
                        self.task.recurrences = [oldActivityRule.toRRuleString()]
                        self.updateRecurrences(recurrences: self.task.recurrences!, title: tasksDeletedMessage)
                    }
                }
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
                    print(finalDateTime)
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
