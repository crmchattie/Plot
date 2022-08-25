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
import UserNotifications
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
                        $0.cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                        $0.cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                        $0.cell.textField?.textColor = ThemeManager.currentTheme().generalTitleColor
                        $0.title = user.name
                        $0.value = 0.00
                        $0.baseCell.isUserInteractionEnabled = false
                        let formatter = CurrencyFormatter()
                        formatter.locale = .current
                        formatter.numberStyle = .currency
                        $0.formatter = formatter
                    }.cellUpdate { cell, row in
                        cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                        cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                        cell.textField?.textColor = ThemeManager.currentTheme().generalTitleColor
                        
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
        guard delegate == nil else {return}
        let dispatchGroup = DispatchGroup()
        for ID in task.subtaskIDs ?? [] {
            dispatchGroup.enter()
            let dataReference = Database.database().reference().child(activitiesEntity).child(ID).child(messageMetaDataFirebaseFolder)
            dataReference.observeSingleEvent(of: .value, with: { (snapshot) in
                if snapshot.exists(), let snapshotValue = snapshot.value as? [String: AnyObject] {
                    let subtask = Activity(dictionary: snapshotValue)
                    self.subtaskList.append(subtask)

                }
                dispatchGroup.leave()
            })
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
            self.listRow()
//            self.decimalRowFunc()
//            self.purchaseBreakdown()
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
    
    func sortSubtasks() {
        subtaskList.sort { (task1, task2) -> Bool in
            return task1.name ?? "" < task2.name ?? ""
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
        let groupActivityReference = Database.database().reference().child(activitiesEntity).child(activityID).child(messageMetaDataFirebaseFolder)
        if type == "subtasks" {
            var subtaskIDs = [String]()
            for subtask in subtaskList {
                if let ID = subtask.activityID {
                    subtaskIDs.append(ID)
                }
            }
            if !subtaskIDs.isEmpty {
                task.subtaskIDs = subtaskIDs
                groupActivityReference.updateChildValues(["subtaskIDs": subtaskIDs as AnyObject])
            } else {
                task.subtaskIDs = nil
                groupActivityReference.child("subtaskIDs").removeValue()
            }
        } else if type == "container" {
            if container != nil {
                container = Container(id: container.id, activityIDs: eventList.map({$0.activityID ?? ""}), taskIDs: container.taskIDs, workoutIDs: healthList.filter({ $0.workout != nil }).map({$0.ID}), mindfulnessIDs: healthList.filter({ $0.mindfulness != nil }).map({$0.ID}), mealIDs: nil, transactionIDs: purchaseList.map({$0.guid}))
            } else {
                let containerID = Database.database().reference().child(containerEntity).childByAutoId().key ?? ""
                container = Container(id: containerID, activityIDs: eventList.map({$0.activityID ?? ""}), taskIDs: [activityID], workoutIDs: healthList.filter({ $0.workout != nil }).map({$0.ID}), mindfulnessIDs: healthList.filter({ $0.mindfulness != nil }).map({$0.ID}), mealIDs: nil, transactionIDs: purchaseList.map({$0.guid}))
            }
            ContainerFunctions.updateContainerAndStuffInside(container: container)
        } else {
            if listList.isEmpty {
                task.checklistIDs = nil
                groupActivityReference.child("checklistIDs").removeValue()
                task.grocerylistID = nil
                groupActivityReference.child("grocerylistID").removeValue()
                task.packinglistIDs = nil
                groupActivityReference.child("packinglistIDs").removeValue()
                task.activitylistIDs = nil
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
                    task.checklistIDs = checklistIDs
                    groupActivityReference.updateChildValues(["checklistIDs": checklistIDs as AnyObject])
                } else {
                    task.checklistIDs = nil
                    groupActivityReference.child("checklistIDs").removeValue()
                }
                if !activitylistIDs.isEmpty {
                    task.activitylistIDs = activitylistIDs
                    groupActivityReference.updateChildValues(["activitylistIDs": activitylistIDs as AnyObject])
                } else {
                    task.activitylistIDs = nil
                    groupActivityReference.child("activitylistIDs").removeValue()
                }
                if grocerylistID != "nothing" {
                    task.grocerylistID = grocerylistID
                    groupActivityReference.updateChildValues(["grocerylistID": grocerylistID as AnyObject])
                } else {
                    task.grocerylistID = nil
                    groupActivityReference.child("grocerylistID").removeValue()
                }
                if !packinglistIDs.isEmpty {
                    task.packinglistIDs = packinglistIDs
                    groupActivityReference.updateChildValues(["packinglistIDs": packinglistIDs as AnyObject])
                } else {
                    task.packinglistIDs = nil
                    groupActivityReference.child("packinglistIDs").removeValue()
                }
            }
        }
    }
    
    func updateRepeatReminder() {
        if let _ = task.recurrences {
            scheduleRecurrences()
        }
        if let _ = task.reminder {
            scheduleReminder()
        }
        
    }
    
    func scheduleRecurrences() {
        guard let task = task, let recurrences = task.recurrences, let startDate = task.startDate else {
            return
        }
        if let recurranceIndex = recurrences.firstIndex(where: { $0.starts(with: "RRULE") }) {
            var recurrenceRule = RecurrenceRule(rruleString: recurrences[recurranceIndex])
            recurrenceRule?.startDate = startDate
            var newRecurrences = recurrences
            newRecurrences[recurranceIndex] = recurrenceRule!.toRRuleString()
            self.task.recurrences = newRecurrences
        }
    }
    
    func scheduleReminder() {
        guard let task = task, let activityReminder = task.reminder, let startDate = task.startDate else {
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
        var formattedDate: (String, String) = ("", "")
        formattedDate = timestampOfTask(startDate: startDate, endDate: task.endDate)
        content.subtitle = formattedDate.0
        if let reminder = EventAlert(rawValue: activityReminder) {
            let reminderDate = startDate.addingTimeInterval(reminder.timeInterval)
            let calendar = Calendar.current
            let triggerDate = calendar.dateComponents([.year,.month,.day,.hour,.minute,.second,], from: reminderDate)
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
        destination.listID = self.task.listID ?? self.lists[ListOptions.plot.name]?.first(where: {$0.name == "Default"})?.id
        if let source = self.task.listSource, let lists = self.lists[source] {
            destination.lists = [source: lists]
        } else {
            destination.lists = [ListOptions.plot.name: self.lists[ListOptions.plot.name] ?? []]
        }
        self.navigationController?.pushViewController(destination, animated: true)
    }
    
    func openRepeat() {
        guard currentReachabilityStatus != .notReachable else {
            basicErrorAlertWith(title: basicErrorTitleForAlert, message: noInternetError, controller: self)
            return
        }
        
        // prepare a recurrence rule and an occurrence date
        // occurrence date is the date which the repeat event occurs this time
        let recurrences = task.recurrences
        let occurrenceDate = task.startDate ?? Date()

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
            basicErrorAlertWith(title: basicErrorTitleForAlert, message: noInternetError, controller: self)
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
            basicErrorAlertWith(title: basicErrorTitleForAlert, message: noInternetError, controller: self)
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
            basicErrorAlertWith(title: basicErrorTitleForAlert, message: noInternetError, controller: self)
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
                destination.startDateTime = self.task.startDate
                destination.endDateTime = self.task.endDate
                self.navigationController?.pushViewController(destination, animated: true)
            }))
            alert.addAction(UIAlertAction(title: "Existing Activity", style: .default, handler: { (_) in
                if let _: ScheduleRow = self.form.rowBy(tag: "label"), let mvs = self.form.sectionBy(tag: "Events") as? MultivaluedSection {
                    mvs.remove(at: mvs.count - 2)
                }
                let destination = ChooseEventTableViewController()
                destination.needDelegate = true
                destination.movingBackwards = true
                destination.delegate = self
                destination.events = self.events
                destination.filteredEvents = self.events
                destination.existingEvents = self.eventList
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
    
    func openPurchases() {
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
                let destination = ChooseTransactionTableViewController()
                destination.delegate = self
                destination.movingBackwards = true
                destination.existingTransactions = self.purchaseList
                destination.transactions = self.transactions
                self.navigationController?.pushViewController(destination, animated: true)
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
                if let mvs = self.form.sectionBy(tag: "Health") as? MultivaluedSection {
                    mvs.remove(at: self.healthIndex)
                }
            }))
            self.present(alert, animated: true)
        }
    }
    
    func openList() {
        guard currentReachabilityStatus != .notReachable else {
            basicErrorAlertWith(title: basicErrorTitleForAlert, message: noInternetError, controller: self)
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
        if active, let oldRecurrences = self.taskOld.recurrences, let oldRecurranceIndex = oldRecurrences.firstIndex(where: { $0.starts(with: "RRULE") }), let oldRecurrenceRule = RecurrenceRule(rruleString: oldRecurrences[oldRecurranceIndex]), let startDate = taskOld.startDate, oldRecurrenceRule.typeOfRecurrence(language: .english, occurrence: startDate) != "Never" {
            let alert = UIAlertController(title: nil, message: "This is a repeating event.", preferredStyle: .actionSheet)
            alert.addAction(UIAlertAction(title: "Save For This Event Only", style: .default, handler: { (_) in
                print("Save for this event only")
                //update activity's recurrence to skip repeat on this date
                var oldActivityRule = oldRecurrenceRule
                //duplicate updated activity w/ new ID and no recurrence rule
                self.duplicateActivity(recurrenceRule: nil)
                //update existing activity with exlusion date that fall's on this date
                oldActivityRule.exdate = ExclusionDate(dates: [self.task.startDate ?? Date()], granularity: .day)
                self.taskOld.recurrences?.append(oldActivityRule.exdate!.toExDateString()!)
                self.updateRecurrences(recurrences: self.taskOld.recurrences!)
            }))
            
            alert.addAction(UIAlertAction(title: "Save For Future Tasks", style: .default, handler: { (_) in
                print("Save for future events")
                //update activity's recurrence to stop repeating just before this event
                var oldActivityRule = oldRecurrenceRule
                //will equal true if first instance of repeating event
                if oldActivityRule.startDate == self.taskOld.startDate {
                    //update all instances of activity
                    if self.task.recurrences == nil {
                        self.deleteRecurrences()
                    }
                    self.createActivity(activity: nil)
                } else if let dateIndex = oldActivityRule.allOccurrences().firstIndex(of: self.taskOld.startDate ?? Date()), let newRecurrences = self.task.recurrences, let newRecurranceIndex = newRecurrences.firstIndex(where: { $0.starts(with: "RRULE") }) {
                    
                    //update only future instances of activity
                    var newActivityRule = RecurrenceRule(rruleString: newRecurrences[newRecurranceIndex])
                    newActivityRule!.startDate = self.task.startDate ?? Date()
                    
                    var newRecurrences = oldRecurrences
                    newRecurrences[newRecurranceIndex] = newActivityRule!.toRRuleString()
                    
                    //duplicate activity w/ new ID and same recurrence rule starting from this event's date
                    self.duplicateActivity(recurrenceRule: newRecurrences)
                    
                    //update existing activity with end date equaling ocurrence before this date
                    oldActivityRule.recurrenceEnd = EKRecurrenceEnd(occurrenceCount: dateIndex)
                    
                    self.taskOld.recurrences![oldRecurranceIndex] = oldActivityRule.toRRuleString()
                    
                    self.updateRecurrences(recurrences: self.taskOld.recurrences!)
                }
            }))
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (_) in
                print("User click Dismiss button")
            }))
            
            self.present(alert, animated: true, completion: {
                print("completion block")
            })
        }
        // do not want to have in duplicate functionality
        else if !active || true {
            self.createActivity(activity: nil)
        } else {
            let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            
            alert.addAction(UIAlertAction(title: "Update Task", style: .default, handler: { (_) in
                print("User click Edit button")
                self.createActivity(activity: nil)
            }))
            
            alert.addAction(UIAlertAction(title: "Duplicate Task", style: .default, handler: { (_) in
                print("User click Edit button")
                self.duplicateActivity(recurrenceRule: nil)
            }))
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (_) in
                print("User click Dismiss button")
            }))
            
            self.present(alert, animated: true, completion: {
                print("completion block")
            })
            
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
    
    func updateRecurrences(recurrences: [String]) {
        showActivityIndicator()
        let createActivity = ActivityActions(activity: self.task, active: active, selectedFalconUsers: selectedFalconUsers)
        createActivity.updateRecurrences(recurrences: recurrences)
        hideActivityIndicator()
        if navigationItem.leftBarButtonItem != nil {
            self.dismiss(animated: true, completion: nil)
        } else {
            self.delegate?.updateTask(task: self.task)
            self.navigationController?.popViewController(animated: true)
        }
    }
    
    func deleteRecurrences() {
        let createActivity = ActivityActions(activity: self.task, active: active, selectedFalconUsers: selectedFalconUsers)
        createActivity.deleteRecurrences()
    }
    
    func createActivity(activity: Activity?) {
        showActivityIndicator()
        let createActivity = ActivityActions(activity: activity ?? self.task, active: active, selectedFalconUsers: selectedFalconUsers)
        createActivity.createNewActivity()
        hideActivityIndicator()
        if navigationItem.leftBarButtonItem != nil {
            self.dismiss(animated: true, completion: nil)
        } else {
            self.navigationController?.popViewController(animated: true)
            self.delegate?.updateTask(task: activity ?? self.task)
            self.updateDiscoverDelegate?.itemCreated()
        }
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
        if let dateSwitchRow: SwitchRow = form.rowBy(tag: "Start Date"), let dateSwitchRowValue = dateSwitchRow.value, let dateRow: DatePickerRow = form.rowBy(tag: "StartDate"), let timeSwitchRow: SwitchRow = form.rowBy(tag: "Start Time"), let timeSwitchRowValue = timeSwitchRow.value, let timeRow: TimePickerRow = form.rowBy(tag: "StartTime") {
            if dateSwitchRowValue && timeSwitchRowValue, let dateRowValue = dateRow.value, let timeRowValue = timeRow.value {
                var dateComponents = DateComponents()
                print(dateRowValue.yearNumber())
                dateComponents.year = dateRowValue.yearNumber()
                dateComponents.month = dateRowValue.monthNumber()
                dateComponents.day = dateRowValue.dayNumber()
                dateComponents.hour = timeRowValue.hourNumber()
                dateComponents.minute = timeRowValue.minuteNumber()
                let date = Calendar.current.date(from: dateComponents)
                self.task.startDateTime = NSNumber(value: Int((date)?.timeIntervalSince1970 ?? 0))
                self.task.hasStartTime = true
            } else if dateSwitchRowValue, let dateRowValue = dateRow.value {
                print(dateRowValue.yearNumber())
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
                if let currentUserID = Auth.auth().currentUser?.uid, active {
                    let userReference = Database.database().reference().child(userActivitiesEntity).child(currentUserID).child(self.activityID).child(messageMetaDataFirebaseFolder).child("startDateTime")
                    userReference.removeValue()
                }
            }
            self.updateRepeatReminder()
        }
    }
    
    func updateDeadlineDate() {
        if let dateSwitchRow: SwitchRow = form.rowBy(tag: "Deadline Date"), let dateSwitchRowValue = dateSwitchRow.value, let dateRow: DatePickerRow = form.rowBy(tag: "DeadlineDate"), let timeSwitchRow: SwitchRow = form.rowBy(tag: "Deadline Time"), let timeSwitchRowValue = timeSwitchRow.value, let timeRow: TimePickerRow = form.rowBy(tag: "DeadlineTime") {
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
                if let currentUserID = Auth.auth().currentUser?.uid, active {
                    let userReference = Database.database().reference().child(userActivitiesEntity).child(currentUserID).child(self.activityID).child(messageMetaDataFirebaseFolder).child("endDateTime")
                    userReference.removeValue()
                }
            }
            self.updateRepeatReminder()
        }
    }
    
    @objc func goToExtras() {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "Delete Task", style: .default, handler: { (_) in
            self.deleteActivity()
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (_) in
            print("User click Dismiss button")
        }))
        
        self.present(alert, animated: true, completion: {
            print("completion block")
        })
        print("shareButtonTapped")
        
    }
    
    func deleteActivity() {
        //need to look into equatable protocol for activities
        if task.recurrences != nil {
            let alert = UIAlertController(title: nil, message: "This is a repeating event.", preferredStyle: .actionSheet)
            
            alert.addAction(UIAlertAction(title: "Delete This Event Only", style: .default, handler: { (_) in
                print("Save for this event only")
                //update activity's recurrence to skip repeat on this date
                if let recurrences = self.task.recurrences {
                    if let recurrence = recurrences.first(where: { $0.starts(with: "RRULE") }) {
                        var rule = RecurrenceRule(rruleString: recurrence)
                        if rule != nil {
    //                      update existing activity with exlusion date that fall's on this date
                            rule!.exdate = ExclusionDate(dates: [self.task.startDate ?? Date()], granularity: .day)
                            self.task.recurrences!.append(rule!.exdate!.toExDateString()!)
                            self.updateRecurrences(recurrences: self.task.recurrences!)
                        }
                    }
                }
            }))
            
            alert.addAction(UIAlertAction(title: "Delete All Future Tasks", style: .default, handler: { (_) in
                print("Save for future events")
                //update activity's recurrence to stop repeating at this event
                if let recurrences = self.task.recurrences {
                    if let recurrence = recurrences.first(where: { $0.starts(with: "RRULE") }) {
                        var rule = RecurrenceRule(rruleString: recurrence)
                        if rule != nil, let index = rule!.allOccurrences().firstIndex(of: self.task.startDate ?? Date()) {
                            if index > 0 {
                                //update existing activity with end date equaling ocurrence of this date
                                rule!.recurrenceEnd = EKRecurrenceEnd(occurrenceCount: index)
                                self.task.recurrences = [rule!.toRRuleString()]
                                self.updateRecurrences(recurrences: self.task.recurrences!)
                            } else {
                                self.showActivityIndicator()
                                let deleteActivity = ActivityActions(activity: self.task, active: self.active, selectedFalconUsers: self.selectedFalconUsers)
                                deleteActivity.deleteActivity()
                                self.hideActivityIndicator()
                                if self.navigationItem.leftBarButtonItem != nil {
                                    self.dismiss(animated: true, completion: nil)
                                } else {
                                    self.navigationController?.popViewController(animated: true)
                                }
                            }
                        }
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
                deleteActivity.deleteActivity()
                self.hideActivityIndicator()
                if self.navigationItem.leftBarButtonItem != nil {
                    self.dismiss(animated: true, completion: nil)
                } else {
                    self.navigationController?.popViewController(animated: true)
                }
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
                newActivity.recurrences = recurrenceRule
            } else {
                newActivity.recurrences = nil
            }
            
            let createActivity = ActivityActions(activity: newActivity, active: false, selectedFalconUsers: selectedFalconUsers)
            createActivity.createNewActivity()
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
    
    func getParticipants(transaction: Transaction?, completion: @escaping ([User])->()) {
        if let transaction = transaction, let participantsIDs = transaction.participantsIDs, let currentUserID = Auth.auth().currentUser?.uid {
            let group = DispatchGroup()
            var participants: [User] = []
            for id in participantsIDs {
                if transaction.admin == currentUserID && id == currentUserID {
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
        } else {
            let participants: [User] = []
            completion(participants)
        }
    }
}