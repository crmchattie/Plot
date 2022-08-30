//
//  EventViewController+Functions.swift
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
import UserNotifications
import CodableFirebase
import RRuleSwift
import HealthKit

extension EventViewController {
    
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
    
    @objc(tableView:accessoryButtonTappedForRowWithIndexPath:) func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
        guard let row: ButtonRow = form.rowBy(tag: "Location"), indexPath == row.indexPath, let latitude = locationAddress[locationName]?[0], let longitude = locationAddress[locationName]?[1] else {
            return
        }
        
        let ceo: CLGeocoder = CLGeocoder()
        let loc: CLLocation = CLLocation(latitude:latitude, longitude: longitude)
        var addressString : String = ""
        ceo.reverseGeocodeLocation(loc) { (placemark, error) in
            if error != nil {
                return
            }
            let place = placemark![0]
            if place.subThoroughfare != nil {
                addressString = addressString + place.subThoroughfare! + " "
            }
            if place.thoroughfare != nil {
                addressString = addressString + place.thoroughfare! + ", "
            }
            if place.locality != nil {
                addressString = addressString + place.locality! + ", "
            }
            if place.country != nil {
                addressString = addressString + place.country! + ", "
            }
            if place.postalCode != nil {
                addressString = addressString + place.postalCode!
            }
            
            let alertController = UIAlertController(title: self.locationName, message: addressString, preferredStyle: .alert)
            let mapAddress = UIAlertAction(title: "Map Address", style: .default) { (action:UIAlertAction) in
                self.goToMap()
            }
            let copyAddress = UIAlertAction(title: "Copy Address", style: .default) { (action:UIAlertAction) in
                let pasteboard = UIPasteboard.general
                pasteboard.string = addressString
            }
            let changeAddress = UIAlertAction(title: "Change Address", style: .default) { (action:UIAlertAction) in
                self.openLocationFinder()
            }
            let removeAddress = UIAlertAction(title: "Remove Address", style: .default) { (action:UIAlertAction) in
                if let locationRow: ButtonRow = self.form.rowBy(tag: "Location") {
                    self.locationAddress[self.locationName] = nil
                    if let localAddress = self.activity.locationAddress, localAddress[self.locationName] != nil {
                        self.activity.locationAddress![self.locationName] = nil
                    }
                    self.activity.locationName = "locationName"
                    self.locationName = "locationName"
                    locationRow.title = "Location"
                    locationRow.updateCell()
                }
            }
            let cancelAlert = UIAlertAction(title: "Cancel", style: .cancel) { (action:UIAlertAction) in
                print("You've pressed cancel")
                
            }
            alertController.addAction(mapAddress)
            alertController.addAction(copyAddress)
            alertController.addAction(changeAddress)
            alertController.addAction(removeAddress)
            alertController.addAction(cancelAlert)
            self.present(alertController, animated: true, completion: nil)
        }
        
    }
    
    func setupLists() {
        guard delegate == nil else {return}
        let dispatchGroup = DispatchGroup()
        for scheduleID in activity.scheduleIDs ?? [] {
            dispatchGroup.enter()
            let dataReference = Database.database().reference().child(activitiesEntity).child(scheduleID).child(messageMetaDataFirebaseFolder)
            dataReference.observeSingleEvent(of: .value, with: { (snapshot) in
                if snapshot.exists(), let snapshotValue = snapshot.value as? [String: AnyObject] {
                    let schedule = Activity(dictionary: snapshotValue)
                    self.scheduleList.append(schedule)

                }
                dispatchGroup.leave()
            })
        }
        for checklistID in activity.checklistIDs ?? [] {
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
        if let containerID = activity.containerID {
            dispatchGroup.enter()
            ContainerFunctions.grabContainerAndStuffInside(id: containerID) { container, _, tasks, health, transactions in
                self.container = container
                for task in tasks ?? [] {
                    print(task.name)
                }
                self.taskList = tasks ?? []
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
        for task in taskList {
            var mvs = (form.sectionBy(tag: "Tasks") as! MultivaluedSection)
            mvs.insert(SubtaskRow() {
                $0.value = task
                $0.cell.delegate = self
            }.onCellSelection() { cell, row in
                self.taskIndex = row.indexPath!.row
                self.openTask()
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
    
    func weatherRow() {
        if let localName = activity.locationName, localName != "locationName", Date(timeIntervalSince1970: self.activity!.endDateTime as! TimeInterval) > Date(), Date(timeIntervalSince1970: self.activity!.startDateTime as! TimeInterval) < Date().addingTimeInterval(1296000) {
            var startDate = Date(timeIntervalSince1970: self.activity!.startDateTime as! TimeInterval)
            var endDate = Date(timeIntervalSince1970: self.activity!.endDateTime as! TimeInterval)
            if startDate < Date() {
                startDate = Date().addingTimeInterval(3600)
            }
            if endDate > Date().addingTimeInterval(1209600) {
                endDate = Date().addingTimeInterval(1209600)
            }
            let startDateString = startDate.toString(dateFormat: "YYYY-MM-dd") + "T24:00:00Z"
            let endDateString = endDate.toString(dateFormat: "YYYY-MM-dd") + "T00:00:00Z"
            if let weatherRow: WeatherRow = self.form.rowBy(tag: "Weather"), let localAddress = activity.locationAddress, let latitude = localAddress[locationName]?[0], let longitude = localAddress[locationName]?[1] {
                let dispatchGroup = DispatchGroup()
                dispatchGroup.enter()
                Service.shared.fetchWeatherDaily(startDateTime: startDateString, endDateTime: endDateString, lat: latitude, long: longitude, unit: "us") { (search, err) in
                    if let weather = search {
                        dispatchGroup.leave()
                        dispatchGroup.notify(queue: .main) {
                            weatherRow.value = weather
                            weatherRow.updateCell()
                            weatherRow.cell.collectionView.reloadData()
                            self.weather = weather
                        }
                    } else if let index = weatherRow.indexPath?.item {
                        dispatchGroup.leave()
                        dispatchGroup.notify(queue: .main) {
                            let section = self.form.allSections[0]
                            section.remove(at: index)
                        }
                    }
                }
            } else if let localAddress = activity.locationAddress, let latitude = localAddress[locationName]?[0], let longitude = localAddress[locationName]?[1] {
                let dispatchGroup = DispatchGroup()
                dispatchGroup.enter()
                Service.shared.fetchWeatherDaily(startDateTime: startDateString, endDateTime: endDateString, lat: latitude, long: longitude, unit: "us") { (search, err) in
                    if let weather = search {
                        dispatchGroup.leave()
                        dispatchGroup.notify(queue: .main) {
                            var section = self.form.allSections[0]
                            if let locationRow: ButtonRow = self.form.rowBy(tag: "Location"), let index = locationRow.indexPath?.item {
                                section.insert(WeatherRow("Weather") { row in
                                    row.value = weather
                                    row.updateCell()
                                    row.cell.collectionView.reloadData()
                                    self.weather = weather
                                }, at: index+1)
                            }
                        }
                    }
                }
            }
        } else if let weatherRow: WeatherRow = self.form.rowBy(tag: "Weather"), let index = weatherRow.indexPath?.item {
            let section = self.form.allSections[0]
            section.remove(at: index)
            self.weather = [DailyWeatherElement]()
        }
    }
    
    func sortSchedule() {
        scheduleList.sort { (schedule1, schedule2) -> Bool in
            return schedule1.startDateTime?.int64Value ?? 0 < schedule2.startDateTime?.int64Value ?? 0
        }
        if let mvs = self.form.sectionBy(tag: "Sub-Events") as? MultivaluedSection {
            if mvs.count == 1 {
                return
            }
            for index in 0...mvs.count - 2 {
                let scheduleRow = mvs.allRows[index]
                scheduleRow.baseValue = scheduleList[index]
                scheduleRow.reload()
            }
        }
    }
    
    func updateLists(type: String) {
        let groupActivityReference = Database.database().reference().child(activitiesEntity).child(activityID).child(messageMetaDataFirebaseFolder)
        if type == "schedule" {
            var scheduleIDs = [String]()
            for schedule in scheduleList {
                if let ID = schedule.activityID {
                    scheduleIDs.append(ID)
                }
            }
            if !scheduleIDs.isEmpty {
                activity.scheduleIDs = scheduleIDs
                groupActivityReference.updateChildValues(["scheduleIDs": scheduleIDs as AnyObject])
            } else {
                activity.scheduleIDs = nil
                groupActivityReference.child("scheduleIDs").removeValue()
            }
        } else if type == "container" {
            if container != nil {
                container = Container(id: container.id, activityIDs: container.activityIDs, taskIDs: taskList.map({$0.activityID ?? ""}), workoutIDs: healthList.filter({ $0.workout != nil }).map({$0.ID}), mindfulnessIDs: healthList.filter({ $0.mindfulness != nil }).map({$0.ID}), mealIDs: nil, transactionIDs: purchaseList.map({$0.guid}))
            } else {
                let containerID = Database.database().reference().child(containerEntity).childByAutoId().key ?? ""
                container = Container(id: containerID, activityIDs: [activityID], taskIDs: taskList.map({$0.activityID ?? ""}), workoutIDs: healthList.filter({ $0.workout != nil }).map({$0.ID}), mindfulnessIDs: healthList.filter({ $0.mindfulness != nil }).map({$0.ID}), mealIDs: nil, transactionIDs: purchaseList.map({$0.guid}))
            }
            ContainerFunctions.updateContainerAndStuffInside(container: container)
        } else {
            if listList.isEmpty {
                activity.checklistIDs = nil
                groupActivityReference.child("checklistIDs").removeValue()
                activity.grocerylistID = nil
                groupActivityReference.child("grocerylistID").removeValue()
                activity.packinglistIDs = nil
                groupActivityReference.child("packinglistIDs").removeValue()
                activity.activitylistIDs = nil
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
                    activity.checklistIDs = checklistIDs
                    groupActivityReference.updateChildValues(["checklistIDs": checklistIDs as AnyObject])
                } else {
                    activity.checklistIDs = nil
                    groupActivityReference.child("checklistIDs").removeValue()
                }
                if !activitylistIDs.isEmpty {
                    activity.activitylistIDs = activitylistIDs
                    groupActivityReference.updateChildValues(["activitylistIDs": activitylistIDs as AnyObject])
                } else {
                    activity.activitylistIDs = nil
                    groupActivityReference.child("activitylistIDs").removeValue()
                }
                if grocerylistID != "nothing" {
                    activity.grocerylistID = grocerylistID
                    groupActivityReference.updateChildValues(["grocerylistID": grocerylistID as AnyObject])
                } else {
                    activity.grocerylistID = nil
                    groupActivityReference.child("grocerylistID").removeValue()
                }
                if !packinglistIDs.isEmpty {
                    activity.packinglistIDs = packinglistIDs
                    groupActivityReference.updateChildValues(["packinglistIDs": packinglistIDs as AnyObject])
                } else {
                    activity.packinglistIDs = nil
                    groupActivityReference.child("packinglistIDs").removeValue()
                }
            }
        }
    }
    
    func updateRepeatReminder() {
        if let _ = activity.recurrences {
            scheduleRecurrences()
        }
        if let _ = activity.reminder {
            scheduleReminder()
        }
        
    }
    
    func scheduleRecurrences() {
        guard let activity = activity, let recurrences = activity.recurrences, let startDate = activity.startDate else {
            return
        }
        if let recurranceIndex = recurrences.firstIndex(where: { $0.starts(with: "RRULE") }) {
            var recurrenceRule = RecurrenceRule(rruleString: recurrences[recurranceIndex])
            recurrenceRule?.startDate = startDate
            var newRecurrences = recurrences
            newRecurrences[recurranceIndex] = recurrenceRule!.toRRuleString()
            self.activity.recurrences = newRecurrences
        }
    }
    
    func scheduleReminder() {
        guard let activity = activity, let activityReminder = activity.reminder, let startDate = activity.startDate, let endDate = activity.endDate, let allDay = activity.allDay, let startTimeZone = activity.startTimeZone, let endTimeZone = activity.endTimeZone else {
            return
        }
        let center = UNUserNotificationCenter.current()
        guard activityReminder != "None" else {
            center.removePendingNotificationRequests(withIdentifiers: ["\(activityID)_Reminder"])
            return
        }
        let content = UNMutableNotificationContent()
        content.title = "\(String(describing: activity.name!)) Reminder"
        content.sound = UNNotificationSound.default
        var formattedDate: (String, String) = ("", "")
        formattedDate = timestampOfEvent(startDate: startDate, endDate: endDate, allDay: allDay, startTimeZone: startTimeZone, endTimeZone: endTimeZone)
        content.subtitle = formattedDate.0
        if let reminder = EventAlert(rawValue: activityReminder) {
            let reminderDate = startDate.addingTimeInterval(reminder.timeInterval)
            var calendar = Calendar.current
            calendar.timeZone = TimeZone(identifier: startTimeZone)!
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
    
    func openCalendar() {
        let destination = ChooseCalendarViewController(networkController: networkController)
        destination.delegate = self
        destination.calendarID = self.activity.calendarID ?? self.calendars[CalendarSourceOptions.plot.name]?.first(where: {$0.name == "Default"})?.id
        if let source = self.activity.calendarSource, let calendars = self.calendars[source] {
            destination.calendars = [source: calendars]
        } else {
            destination.calendars = [CalendarSourceOptions.plot.name: self.calendars[CalendarSourceOptions.plot.name] ?? []]
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
        let recurrences = activity.recurrences
        let occurrenceDate = activity.startDate

        // initialization and configuration
        // RecurrencePicker can be initialized with a recurrence rule or nil, nil means "never repeat"
        var recurrencePicker = RecurrencePicker(recurrenceRule: nil)
        if let recurrences = recurrences, let recurrence = recurrences.first(where: { $0.starts(with: "RRULE") }) {
            let recurrenceRule = RecurrenceRule(rruleString: recurrence)
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
        if let imageURLs = activity.activityPhotos {
            destination.imageURLs = imageURLs
        }
        if let fileURLs = activity.activityFiles {
            destination.fileURLs = fileURLs
        }
        self.navigationController?.pushViewController(destination, animated: true)
    }
    
    func openLocationFinder() {
        guard currentReachabilityStatus != .notReachable else {
            basicErrorAlertWith(title: basicErrorTitleForAlert, message: noInternetError, controller: self)
            return
        }
        let destination = LocationFinderTableViewController()
        destination.delegate = self
        self.navigationController?.pushViewController(destination, animated: true)
    }
    
    func openTimeZoneFinder(startOrEndTimeZone: String) {
        guard currentReachabilityStatus != .notReachable else {
            basicErrorAlertWith(title: basicErrorTitleForAlert, message: noInternetError, controller: self)
            return
        }
        let destination = TimeZoneViewController()
        destination.delegate = self
        destination.startOrEndTimeZone = startOrEndTimeZone
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
        
        destination.ownerID = self.activity.admin
        destination.users = uniqueUsers
        destination.filteredUsers = uniqueUsers
        if !selectedFalconUsers.isEmpty {
            destination.priorSelectedUsers = selectedFalconUsers
        }
        
        destination.delegate = self
        
        if self.selectedFalconUsers.count > 0 {
            let dispatchGroup = DispatchGroup()
            for user in self.selectedFalconUsers {
                dispatchGroup.enter()
                guard let currentUserID = Auth.auth().currentUser?.uid, let userID = user.id, let activityID = activity.activityID else {
                    dispatchGroup.leave()
                    continue
                }
                
                if userID == activity.admin {
                    if userID != currentUserID {
                        self.userInvitationStatus[userID] = .accepted
                    }
                    
                    dispatchGroup.leave()
                    continue
                }
                
                InvitationsFetcher.activityInvitation(forUser: userID, activityID: activityID) { (invitation) in
                    if let invitation = invitation {
                        self.userInvitationStatus[userID] = invitation.status
                    }
                    dispatchGroup.leave()
                }
            }
            dispatchGroup.notify(queue: .main) {
                destination.userInvitationStatus = self.userInvitationStatus
                InvitationsFetcher.getAcceptedParticipant(forActivity: self.activity, allParticipants: self.selectedFalconUsers) { acceptedParticipant in
                    self.acceptedParticipant = acceptedParticipant
                    self.navigationController?.pushViewController(destination, animated: true)
                }
            }
        } else {
            self.navigationController?.pushViewController(destination, animated: true)
        }
    }
    
    func openSchedule() {
        guard currentReachabilityStatus != .notReachable else {
            basicErrorAlertWith(title: basicErrorTitleForAlert, message: noInternetError, controller: self)
            return
        }
        
        let destination = ScheduleListViewController()
        destination.delegate = self
        destination.scheduleList = scheduleList
        destination.acceptedParticipant = acceptedParticipant
        destination.startDateTime = startDateTime
        destination.endDateTime = endDateTime
        destination.activities = activities
        destination.activity = activity
        
        self.navigationController?.pushViewController(destination, animated: true)
    
    }
    
    func openTask() {
        guard currentReachabilityStatus != .notReachable else {
            basicErrorAlertWith(title: basicErrorTitleForAlert, message: noInternetError, controller: self)
            return
        }
        if taskList.indices.contains(taskIndex) {
            showActivityIndicator()
            let destination = TaskViewController(networkController: networkController)
            destination.task = taskList[taskIndex]
            destination.delegate = self
            self.hideActivityIndicator()
            self.navigationController?.pushViewController(destination, animated: true)
        } else {
            let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            alert.addAction(UIAlertAction(title: "New Task", style: .default, handler: { (_) in
                if let _: SubtaskRow = self.form.rowBy(tag: "label"), let mvs = self.form.sectionBy(tag: "Tasks") as? MultivaluedSection {
                    mvs.remove(at: mvs.count - 2)
                }
                let destination = TaskViewController(networkController: self.networkController)
                destination.users = self.selectedFalconUsers
                destination.filteredUsers = self.selectedFalconUsers
                destination.delegate = self
                self.navigationController?.pushViewController(destination, animated: true)
            }))
            alert.addAction(UIAlertAction(title: "Existing Task", style: .default, handler: { (_) in
                if let _: SubtaskRow = self.form.rowBy(tag: "label"), let mvs = self.form.sectionBy(tag: "Tasks") as? MultivaluedSection {
                    mvs.remove(at: mvs.count - 2)
                }
                let destination = ChooseTaskTableViewController(networkController: self.networkController)
                destination.needDelegate = true
                destination.movingBackwards = true
                destination.delegate = self
                destination.tasks = self.tasks
                destination.filteredTasks = self.tasks
                destination.existingTasks = self.taskList
                self.navigationController?.pushViewController(destination, animated: true)
            }))
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (_) in
                if let _: SubtaskRow = self.form.rowBy(tag: "label"), let mvs = self.form.sectionBy(tag: "Tasks") as? MultivaluedSection {
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
                destination.users = self.acceptedParticipant
                destination.filteredUsers = self.acceptedParticipant
                self.navigationController?.pushViewController(destination, animated: true)
            }))
            alert.addAction(UIAlertAction(title: "Existing Transaction", style: .default, handler: { (_) in
                let destination = ChooseTransactionTableViewController(networkController: self.networkController)
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
        destination.activity = activity
        self.navigationController?.pushViewController(destination, animated: true)
    }
    
    func openTags() {
        let destination = TagsViewController()
        destination.delegate = self
        destination.tags = activity.tags
        self.navigationController?.pushViewController(destination, animated: true)
    }
    
    @IBAction func cancel(_ sender: AnyObject) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @objc func createNewActivity() {        
        if active, let oldRecurrences = self.activityOld.recurrences, let oldRecurranceIndex = oldRecurrences.firstIndex(where: { $0.starts(with: "RRULE") }), let oldRecurrenceRule = RecurrenceRule(rruleString: oldRecurrences[oldRecurranceIndex]), let startDate = activityOld.startDate, oldRecurrenceRule.typeOfRecurrence(language: .english, occurrence: startDate) != "Never" {
            let alert = UIAlertController(title: nil, message: "This is a repeating event.", preferredStyle: .actionSheet)
            alert.addAction(UIAlertAction(title: "Save For This Event Only", style: .default, handler: { (_) in
                print("Save for this event only")
                //update activity's recurrence to skip repeat on this date
                var oldActivityRule = oldRecurrenceRule
                //duplicate updated activity w/ new ID and no recurrence rule
                self.duplicateActivity(recurrenceRule: nil)
                //update existing activity with exlusion date that fall's on this date
                //FIX-ME: need to make sure oldActivityRule dates correspond to self.activity.startDate
                oldActivityRule.exdate = ExclusionDate(dates: [startDate], granularity: .day)
                self.activityOld.recurrences?.append(oldActivityRule.exdate!.toExDateString()!)
                self.updateRecurrences(recurrences: self.activityOld.recurrences!)
            }))
            
            alert.addAction(UIAlertAction(title: "Save For Future Events", style: .default, handler: { (_) in
                print("Save for future events")
                //update activity's recurrence to stop repeating just before this event
                var oldActivityRule = oldRecurrenceRule
                //will equal true if first instance of repeating event
                if let dateIndex = oldActivityRule.allOccurrences().firstIndex(of: startDate) {
                    if dateIndex == 0 {
                        //update all instances of activity
                        if self.activity.recurrences == nil {
                            self.deleteRecurrences()
                        }
                        self.createActivity(activity: nil)
                    } else if let newRecurrences = self.activity.recurrences, let newRecurranceIndex = newRecurrences.firstIndex(where: { $0.starts(with: "RRULE") }) {

                        //update only future instances of activity
                        var newActivityRule = RecurrenceRule(rruleString: newRecurrences[newRecurranceIndex])
                        newActivityRule!.startDate = self.activity.startDate ?? Date()
                        
                        var newRecurrences = oldRecurrences
                        newRecurrences[newRecurranceIndex] = newActivityRule!.toRRuleString()
                        
                        //duplicate activity w/ new ID and same recurrence rule starting from this event's date
                        self.duplicateActivity(recurrenceRule: newRecurrences)
                        
                        //update existing activity with end date equaling ocurrence before this date
                        oldActivityRule.recurrenceEnd = EKRecurrenceEnd(occurrenceCount: dateIndex)
                        
                        self.activityOld.recurrences![oldRecurranceIndex] = oldActivityRule.toRRuleString()
                        
                        self.updateRecurrences(recurrences: self.activityOld.recurrences!)
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
        // do not want to have in duplicate functionality
        else if !active || true {
            self.createActivity(activity: nil)
        } else {
            let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            
            alert.addAction(UIAlertAction(title: "Update Event", style: .default, handler: { (_) in
                print("User click Edit button")
                self.createActivity(activity: nil)
            }))
            
            alert.addAction(UIAlertAction(title: "Duplicate Event", style: .default, handler: { (_) in
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
    
    func updateRecurrences(recurrences: [String]) {
        showActivityIndicator()
        let createActivity = ActivityActions(activity: self.activity, active: active, selectedFalconUsers: selectedFalconUsers)
        createActivity.updateRecurrences(recurrences: recurrences)
        hideActivityIndicator()
        if navigationItem.leftBarButtonItem != nil {
            self.dismiss(animated: true, completion: nil)
        } else {
            self.delegate?.updateActivity(activity: self.activity)
            self.navigationController?.popViewController(animated: true)
        }
    }
    
    func deleteRecurrences() {
        let createActivity = ActivityActions(activity: self.activity, active: active, selectedFalconUsers: selectedFalconUsers)
        createActivity.deleteRecurrences()
    }
    
    func createActivity(activity: Activity?) {
        showActivityIndicator()
        let createActivity = ActivityActions(activity: activity ?? self.activity, active: active, selectedFalconUsers: selectedFalconUsers)
        createActivity.createNewActivity()
        hideActivityIndicator()
        if navigationItem.leftBarButtonItem != nil {
            self.dismiss(animated: true, completion: nil)
        } else {
            self.navigationController?.popViewController(animated: true)
            self.delegate?.updateActivity(activity: activity ?? self.activity)
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
    
    @objc func goToExtras() {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "Delete Event", style: .default, handler: { (_) in
            self.deleteActivity()
        }))
        
        if let localName = activity.locationName, localName != "locationName", let _ = activity.locationAddress {
            alert.addAction(UIAlertAction(title: "Go to Map", style: .default, handler: { (_) in
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
            basicErrorAlertWith(title: basicErrorTitleForAlert, message: noInternetError, controller: self)
            return
        }
        
        let destination = MapViewController()
        destination.sections = [.event]
        var locations = [activity]
        
        if locationAddress.count > 1 {
            locations.append(contentsOf: scheduleList)
            destination.locations = [.event: locations]
        } else {
            destination.locations = [.event: locations]
        }
        navigationController?.pushViewController(destination, animated: true)
    }
    
    func deleteActivity() {
        //need to look into equatable protocol for activities
        if let oldRecurrences = self.activityOld.recurrences, let oldRecurranceIndex = oldRecurrences.firstIndex(where: { $0.starts(with: "RRULE") }), let oldRecurrenceRule = RecurrenceRule(rruleString: oldRecurrences[oldRecurranceIndex]), let startDate = activityOld.startDate, oldRecurrenceRule.typeOfRecurrence(language: .english, occurrence: startDate) != "Never", activity.calendarName != "Birthdays", activity.calendarSource != CalendarSourceOptions.apple.name {
            let alert = UIAlertController(title: nil, message: "This is a repeating event.", preferredStyle: .actionSheet)
            
            alert.addAction(UIAlertAction(title: "Delete This Event Only", style: .default, handler: { (_) in
                print("Save for this event only")
                
                //update activity's recurrence to skip repeat on this date
                var oldActivityRule = oldRecurrenceRule
                //update existing activity with exlusion date that fall's on this date
                oldActivityRule.exdate = ExclusionDate(dates: [startDate], granularity: .day)
                self.activity.recurrences!.append(oldActivityRule.exdate!.toExDateString()!)
                self.updateRecurrences(recurrences: self.activity.recurrences!)
            }))
            
            alert.addAction(UIAlertAction(title: "Delete All Future Events", style: .default, handler: { (_) in
                //update activity's recurrence to stop repeating at this event
                var oldActivityRule = oldRecurrenceRule
                if let dateIndex = oldActivityRule.allOccurrences().firstIndex(of: startDate) {
                    //will equal true if first instance of repeating event
                    if dateIndex == 0 {
                        self.showActivityIndicator()
                        let deleteActivity = ActivityActions(activity: self.activity, active: self.active, selectedFalconUsers: self.selectedFalconUsers)
                        deleteActivity.deleteActivity()
                        self.hideActivityIndicator()
                        if self.navigationItem.leftBarButtonItem != nil {
                            self.dismiss(animated: true, completion: nil)
                        } else {
                            self.navigationController?.popViewController(animated: true)
                        }
                    } else {
                        //update existing activity with end date equaling ocurrence of this date
                        oldActivityRule.recurrenceEnd = EKRecurrenceEnd(occurrenceCount: dateIndex)
                        self.activity.recurrences = [oldActivityRule.toRRuleString()]
                        self.updateRecurrences(recurrences: self.activity.recurrences!)
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
                let deleteActivity = ActivityActions(activity: self.activity, active: self.active, selectedFalconUsers: self.selectedFalconUsers)
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
        if let activity = activity, let currentUserID = Auth.auth().currentUser?.uid {
            var newActivityID: String!
            newActivityID = Database.database().reference().child(userActivitiesEntity).child(currentUserID).childByAutoId().key ?? ""
            
            let newActivity = activity.copy() as! Activity
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
