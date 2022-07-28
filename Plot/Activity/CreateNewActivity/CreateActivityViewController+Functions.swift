//
//  CreateActivityViewController+Functions.swift
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

extension CreateActivityViewController {
    
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
        if activity.scheduleIDs != nil {
            for scheduleID in activity.scheduleIDs! {
                dispatchGroup.enter()
                let dataReference = Database.database().reference().child(activitiesEntity).child(scheduleID)
                dataReference.observeSingleEvent(of: .value, with: { (snapshot) in
                    if snapshot.exists(), let snapshotValue = snapshot.value {
                        if let schedule = try? FirebaseDecoder().decode(Activity.self, from: snapshotValue) {
                            self.scheduleList.append(schedule)
                        }
                    }
                    self.dispatchGroup.leave()
                })
            }
        }
        if activity.checklistIDs != nil {
            for checklistID in activity.checklistIDs! {
                dispatchGroup.enter()
                let checklistDataReference = Database.database().reference().child(checklistsEntity).child(checklistID)
                checklistDataReference.observeSingleEvent(of: .value, with: { (snapshot) in
                    if snapshot.exists(), let checklistSnapshotValue = snapshot.value {
                        if let checklist = try? FirebaseDecoder().decode(Checklist.self, from: checklistSnapshotValue) {
                            var list = ListContainer()
                            list.checklist = checklist
                            self.listList.append(list)
                        }
                    }
                    self.dispatchGroup.leave()
                })
            }
        }
        if activity.grocerylistID != nil {
            dispatchGroup.enter()
            let grocerylistDataReference = Database.database().reference().child(grocerylistsEntity).child(activity.grocerylistID!)
            grocerylistDataReference.observeSingleEvent(of: .value, with: { (snapshot) in
                if snapshot.exists(), let grocerylistSnapshotValue = snapshot.value {
                    if let grocerylist = try? FirebaseDecoder().decode(Grocerylist.self, from: grocerylistSnapshotValue) {
                        var list = ListContainer()
                        list.grocerylist = grocerylist
                        self.listList.append(list)
                        self.grocerylistIndex = self.listList.count - 1
                    }
                }
                self.dispatchGroup.leave()
            })
        }
        if activity.packinglistIDs != nil {
            for packinglistID in activity.packinglistIDs! {
                dispatchGroup.enter()
                let packinglistDataReference = Database.database().reference().child(packinglistsEntity).child(packinglistID)
                packinglistDataReference.observeSingleEvent(of: .value, with: { (snapshot) in
                    if snapshot.exists(), let packinglistSnapshotValue = snapshot.value {
                        if let packinglist = try? FirebaseDecoder().decode(Packinglist.self, from: packinglistSnapshotValue) {
                            var list = ListContainer()
                            list.packinglist = packinglist
                            self.listList.append(list)
                        }
                    }
                    self.dispatchGroup.leave()
                })
            }
        }
        if activity.activitylistIDs != nil {
            for activitylistID in activity.activitylistIDs! {
                dispatchGroup.enter()
                let activitylistDataReference = Database.database().reference().child(activitylistsEntity).child(activitylistID)
                activitylistDataReference.observeSingleEvent(of: .value, with: { (snapshot) in
                    if snapshot.exists(), let activitylistSnapshotValue = snapshot.value {
                        if let activitylist = try? FirebaseDecoder().decode(Activitylist.self, from: activitylistSnapshotValue) {
                            var list = ListContainer()
                            list.activitylist = activitylist
                            self.listList.append(list)
                        }
                    }
                    self.dispatchGroup.leave()
                })
            }
        }
        if activity.transactionIDs != nil {
            for transactionID in activity.transactionIDs! {
                dispatchGroup.enter()
                let dataReference = Database.database().reference().child(financialTransactionsEntity).child(transactionID)
                dataReference.observeSingleEvent(of: .value, with: { (snapshot) in
                    if snapshot.exists(), let snapshotValue = snapshot.value {
                        if let transaction = try? FirebaseDecoder().decode(Transaction.self, from: snapshotValue) {
                            self.purchaseList.append(transaction)
                        }
                    }
                    self.dispatchGroup.leave()
                })
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            self.listRow()
//            self.decimalRowFunc()
//            self.purchaseBreakdown()
        }
    }

    
    func listRow() {
//        for list in listList {
//            if let groceryList = list.grocerylist {
//                var mvs = (form.sectionBy(tag: "listsfields") as! MultivaluedSection)
//                mvs.insert(ButtonRow() { row in
//                    row.cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
//                    row.cell.textLabel?.textAlignment = .left
//                    row.cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
//                    row.title = groceryList.name
//                    self.grocerylistIndex = mvs.count - 1
//                }.onCellSelection({ cell, row in
//                    self.listIndex = row.indexPath!.row
//                    self.openList()
//                }).cellUpdate { cell, row in
//                    cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
//                    cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
//                    cell.textLabel?.textAlignment = .left
//                }, at: mvs.count - 1)
//            } else if let checklist = list.checklist {
//                var mvs = (form.sectionBy(tag: "listsfields") as! MultivaluedSection)
//                mvs.insert(ButtonRow() { row in
//                    row.cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
//                    row.cell.textLabel?.textAlignment = .left
//                    row.cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
//                    row.title = checklist.name
//                }.onCellSelection({ cell, row in
//                    self.listIndex = row.indexPath!.row
//                    self.openList()
//                }).cellUpdate { cell, row in
//                    cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
//                    cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
//                    cell.textLabel?.textAlignment = .left
//                }, at: mvs.count - 1)
//            } else if let activitylist = list.activitylist {
//                var mvs = (form.sectionBy(tag: "listsfields") as! MultivaluedSection)
//                mvs.insert(ButtonRow() { row in
//                    row.cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
//                    row.cell.textLabel?.textAlignment = .left
//                    row.cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
//                    row.title = activitylist.name
//                }.onCellSelection({ cell, row in
//                    self.listIndex = row.indexPath!.row
//                    self.openList()
//                }).cellUpdate { cell, row in
//                    cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
//                    cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
//                    cell.textLabel?.textAlignment = .left
//                }, at: mvs.count - 1)
//            } else if let packinglist = list.packinglist {
//                var mvs = (form.sectionBy(tag: "listsfields") as! MultivaluedSection)
//                mvs.insert(ButtonRow() { row in
//                    row.cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
//                    row.cell.textLabel?.textAlignment = .left
//                    row.cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
//                    row.title = packinglist.name
//                }.onCellSelection({ cell, row in
//                    self.listIndex = row.indexPath!.row
//                    self.openList()
//                }).cellUpdate { cell, row in
//                    cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
//                    cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
//                    cell.textLabel?.textAlignment = .left
//                }, at: mvs.count - 1)
//            }
//        }
        
        scheduleList.sort { (schedule1, schedule2) -> Bool in
            return schedule1.startDateTime!.int64Value < schedule2.startDateTime!.int64Value
        }
        for schedule in scheduleList {
            var mvs = (form.sectionBy(tag: "schedulefields") as! MultivaluedSection)
            mvs.insert(ScheduleRow() {
                $0.value = schedule
                }.onCellSelection() { cell, row in
                    self.scheduleIndex = row.indexPath!.row
                    self.openSchedule()
                    cell.cellResignFirstResponder()
            }, at: mvs.count - 1)
            
        }
        
        for health in healthList {
            var mvs = (form.sectionBy(tag: "healthfields") as! MultivaluedSection)
            mvs.insert(HealthRow() {
                $0.value = health
                }.onCellSelection() { cell, row in
                    self.scheduleIndex = row.indexPath!.row
                    self.openSchedule()
                    cell.cellResignFirstResponder()
            }, at: mvs.count - 1)
            
        }
        
        for purchase in purchaseList {
            var mvs = (form.sectionBy(tag: "purchasefields") as! MultivaluedSection)
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
            return schedule1.startDateTime!.int64Value < schedule2.startDateTime!.int64Value
        }
        if let mvs = self.form.sectionBy(tag: "schedulefields") as? MultivaluedSection {
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
//        let groupActivityReference = Database.database().reference().child("activities").child(activityID).child(messageMetaDataFirebaseFolder)
        if type == "schedule" {
            var scheduleIDs = [String]()
            for schedule in scheduleList {
                if let ID = schedule.activityID {
                    scheduleIDs.append(ID)
                }
            }
            if !scheduleIDs.isEmpty {
                activity.scheduleIDs = scheduleIDs
//                groupActivityReference.updateChildValues(["scheduleIDs": scheduleIDs as AnyObject])
            } else {
                activity.scheduleIDs = nil
//                groupActivityReference.child("scheduleIDs").removeValue()
            }
        } else if type == "purchases" {
            var transactionIDs = [String]()
            for transaction in purchaseList {
                transactionIDs.append(transaction.guid)
            }
            if !transactionIDs.isEmpty {
                activity.transactionIDs = transactionIDs
//                groupActivityReference.updateChildValues(["transactionIDs": transactionIDs as AnyObject])
            } else {
                activity.transactionIDs = nil
//                groupActivityReference.child("transactionIDs").removeValue()
            }
        } else if type == "health" {
            if healthList.isEmpty {
                activity.workoutIDs = nil
//                groupActivityReference.child("workoutIDs").removeValue()
                activity.mealIDs = nil
//                groupActivityReference.child("mealIDs").removeValue()
                activity.mindfulnessIDs = nil
//                groupActivityReference.child("mindfulnessIDs").removeValue()
            } else {
                var workoutIDs = [String]()
                var mealIDs = [String]()
                var mindfulnessIDs = [String]()
                for healthItem in healthList {
                    if let workout = healthItem.workout {
                        workoutIDs.append(workout.id)
                    } else if let meal = healthItem.meal {
                        mealIDs.append(meal.id)
                    } else if let mindfulness = healthItem.mindfulness {
                        mindfulnessIDs.append(mindfulness.id)
                    }
                }
                if !workoutIDs.isEmpty {
                    activity.workoutIDs = workoutIDs
//                    groupActivityReference.updateChildValues(["workoutIDs": workoutIDs as AnyObject])
                } else {
                    activity.workoutIDs = nil
//                    groupActivityReference.child("workoutIDs").removeValue()
                }
                if !mealIDs.isEmpty {
                    activity.mealIDs = mealIDs
//                    groupActivityReference.updateChildValues(["mealIDs": mealIDs as AnyObject])
                } else {
                    activity.mealIDs = nil
//                    groupActivityReference.child("mealIDs").removeValue()
                }
                if !mindfulnessIDs.isEmpty {
                    activity.packinglistIDs = mindfulnessIDs
//                    groupActivityReference.updateChildValues(["mindfulnessIDs": mindfulnessIDs as AnyObject])
                } else {
                    activity.mindfulnessIDs = nil
//                    groupActivityReference.child("mindfulnessIDs").removeValue()
                }
            }
        } else {
            if listList.isEmpty {
                activity.checklistIDs = nil
//                groupActivityReference.child("checklistIDs").removeValue()
                activity.grocerylistID = nil
//                groupActivityReference.child("grocerylistID").removeValue()
                activity.packinglistIDs = nil
//                groupActivityReference.child("packinglistIDs").removeValue()
                activity.activitylistIDs = nil
//                groupActivityReference.child("activitylistIDs").removeValue()
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
//                    groupActivityReference.updateChildValues(["checklistIDs": checklistIDs as AnyObject])
                } else {
                    activity.checklistIDs = nil
//                    groupActivityReference.child("checklistIDs").removeValue()
                }
                if !activitylistIDs.isEmpty {
                    activity.activitylistIDs = activitylistIDs
//                    groupActivityReference.updateChildValues(["activitylistIDs": activitylistIDs as AnyObject])
                } else {
                    activity.activitylistIDs = nil
//                    groupActivityReference.child("activitylistIDs").removeValue()
                }
                if grocerylistID != "nothing" {
                    activity.grocerylistID = grocerylistID
//                    groupActivityReference.updateChildValues(["grocerylistID": grocerylistID as AnyObject])
                } else {
                    activity.grocerylistID = nil
//                    groupActivityReference.child("grocerylistID").removeValue()
                }
                if !packinglistIDs.isEmpty {
                    activity.packinglistIDs = packinglistIDs
//                    groupActivityReference.updateChildValues(["packinglistIDs": packinglistIDs as AnyObject])
                } else {
                    activity.packinglistIDs = nil
//                    groupActivityReference.child("packinglistIDs").removeValue()
                }
            }
        }
    }
    
    func scheduleReminder() {
        let center = UNUserNotificationCenter.current()
        guard activity.reminder! != "None" else {
            center.removePendingNotificationRequests(withIdentifiers: ["\(activityID)_Reminder"])
            return
        }
        let content = UNMutableNotificationContent()
        content.title = "\(String(describing: activity.name!)) Reminder"
        content.sound = UNNotificationSound.default
        var formattedDate: (String, String) = ("", "")
        if let startDate = startDateTime, let endDate = endDateTime, let allDay = activity.allDay, let startTimeZone = activity.startTimeZone, let endTimeZone = activity.endTimeZone {
            formattedDate = timestampOfActivity(startDate: startDate, endDate: endDate, allDay: allDay, startTimeZone: startTimeZone, endTimeZone: endTimeZone)
            content.subtitle = formattedDate.0
        }
        let reminder = EventAlert(rawValue: activity.reminder!)
        let reminderDate = startDateTime!.addingTimeInterval(reminder!.timeInterval)
        var calendar = Calendar.current
        calendar.timeZone = TimeZone(identifier: activity.startTimeZone ?? "UTC")!
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
    
    func openCategory(value: String) {
        let destination = ActivityCategoryViewController()
        destination.delegate = self
        destination.value = value
        self.navigationController?.pushViewController(destination, animated: true)
    }
    
    func openCalendar(value: String) {
        let destination = CalendarListViewController()
        destination.delegate = self
        destination.calendarID = self.activity.calendarID
        self.navigationController?.pushViewController(destination, animated: true)
    }
    
    func openRepeat() {
        guard currentReachabilityStatus != .notReachable else {
            basicErrorAlertWith(title: basicErrorTitleForAlert, message: noInternetError, controller: self)
            return
        }
//        let destination = RepeatViewController()
//        destination.delegate = self
//        self.navigationController?.pushViewController(destination, animated: true)
        
        // prepare a recurrence rule and an occurrence date
        // occurrence date is the date which the repeat event occurs this time
        let recurrences = activity.recurrences
        let occurrenceDate = activity.startDate!

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
        destination.activityID = activityID
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
        if scheduleList.indices.contains(scheduleIndex) {
            showActivityIndicator()
            let scheduleItem = scheduleList[scheduleIndex]
            let destination = ScheduleViewController()
            destination.schedule = scheduleItem
            destination.users = acceptedParticipant
            destination.filteredUsers = acceptedParticipant
            destination.startDateTime = startDateTime
            destination.endDateTime = endDateTime
            if let scheduleLocationAddress = scheduleList[scheduleIndex].locationAddress {
                for (key, _) in scheduleLocationAddress {
                    locationAddress[key] = nil
                }
            }
            destination.delegate = self
            self.hideActivityIndicator()
            self.navigationController?.pushViewController(destination, animated: true)
        } else {
            let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            alert.addAction(UIAlertAction(title: "New Activity", style: .default, handler: { (_) in
                if let _: ScheduleRow = self.form.rowBy(tag: "label"), let mvs = self.form.sectionBy(tag: "schedulefields") as? MultivaluedSection {
                    mvs.remove(at: mvs.count - 2)
                }
                let destination = ScheduleViewController()
                destination.users = self.acceptedParticipant
                destination.filteredUsers = self.acceptedParticipant
                destination.delegate = self
                destination.startDateTime = self.startDateTime
                destination.endDateTime = self.endDateTime
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
                destination.activity = self.activity
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
    
    func openPurchases() {
        guard currentReachabilityStatus != .notReachable else {
            basicErrorAlertWith(title: basicErrorTitleForAlert, message: noInternetError, controller: self)
            return
        }
        if purchaseList.indices.contains(purchaseIndex) {
            let destination = FinanceTransactionViewController()
            destination.delegate = self
            destination.movingBackwards = true
            destination.users = self.acceptedParticipant
            destination.filteredUsers = self.acceptedParticipant
            destination.transaction = purchaseList[purchaseIndex]
            self.getParticipants(transaction: purchaseList[purchaseIndex]) { (participants) in
                destination.selectedFalconUsers = participants
                self.navigationController?.pushViewController(destination, animated: true)
            }
        } else {
            let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            alert.addAction(UIAlertAction(title: "New Transaction", style: .default, handler: { (_) in
                let destination = FinanceTransactionViewController()
                destination.delegate = self
                destination.movingBackwards = true
                destination.users = self.acceptedParticipant
                destination.filteredUsers = self.acceptedParticipant
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
                if let mvs = self.form.sectionBy(tag: "purchasefields") as? MultivaluedSection {
                    mvs.remove(at: self.purchaseIndex)
                }
            }))
            self.present(alert, animated: true)
        }
    }
    
    func openHealth() {
        if healthList.indices.contains(healthIndex), let workout = healthList[healthIndex].workout {
            let destination = WorkoutViewController()
            destination.workout = workout
            destination.delegate = self
            self.navigationController?.pushViewController(destination, animated: true)
        } else if healthList.indices.contains(healthIndex), let meal = healthList[healthIndex].meal {
            let destination = MealViewController()
            destination.meal = meal
            destination.delegate = self
            self.navigationController?.pushViewController(destination, animated: true)
        } else if healthList.indices.contains(healthIndex), let mindfulness = healthList[healthIndex].mindfulness {
            let destination = MindfulnessViewController()
            destination.mindfulness = mindfulness
            destination.users = self.users
            destination.filteredUsers = self.users
            destination.delegate = self
            self.navigationController?.pushViewController(destination, animated: true)
        } else {
            let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            alert.addAction(UIAlertAction(title: "New Workout", style: .default, handler: { (_) in
                let destination = WorkoutViewController()
                destination.delegate = self
                destination.movingBackwards = true
                destination.users = self.users
                destination.filteredUsers = self.users
                self.navigationController?.pushViewController(destination, animated: true)
            }))
            alert.addAction(UIAlertAction(title: "New Meal", style: .default, handler: { (_) in
                let destination = MealViewController()
                destination.delegate = self
                destination.movingBackwards = true
                destination.users = self.users
                destination.filteredUsers = self.users
                self.navigationController?.pushViewController(destination, animated: true)
            }))
            alert.addAction(UIAlertAction(title: "New Mindfulness", style: .default, handler: { (_) in
                let destination = MindfulnessViewController()
                destination.delegate = self
                destination.movingBackwards = true
                destination.users = self.users
                destination.filteredUsers = self.users
                self.navigationController?.pushViewController(destination, animated: true)
            }))
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (_) in
                if let mvs = self.form.sectionBy(tag: "purchasefields") as? MultivaluedSection {
                    mvs.remove(at: self.purchaseIndex)
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
        self.navigationController?.pushViewController(destination, animated: true)
    }
    
    @IBAction func cancel(_ sender: AnyObject) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @objc func createNewActivity() {
        if activity.recurrences != nil {
            let alert = UIAlertController(title: nil, message: "This is a repeating event.", preferredStyle: .actionSheet)
            
            alert.addAction(UIAlertAction(title: "Save For This Event Only", style: .default, handler: { (_) in
                print("Save for this event only")
                //update activity's recurrence to skip repeat on this date
                if let recurrences = self.activityOld.recurrences {
                    if let recurrence = recurrences.first(where: { $0.starts(with: "RRULE") }) {
                        var rule = RecurrenceRule(rruleString: recurrence)
                        if rule != nil {
//                          duplicate updated activity w/ new ID and no recurrence rule
                            self.duplicateActivity(recurrenceRule: nil)
    //                      update existing activity with exlusion date that fall's on this date
                            rule!.exdate = ExclusionDate(dates: [self.activity.startDate ?? Date()], granularity: .day)
                            self.activityOld.recurrences?.append(rule!.exdate!.toExDateString()!)
                            self.updateRecurrences(recurrences: self.activityOld.recurrences!)
                        }
                    }
                }
            }))
            
            alert.addAction(UIAlertAction(title: "Save For Future Events", style: .default, handler: { (_) in
                print("Save for future events")
                //update activity's recurrence to stop repeating just before this event
                if let oldRecurrences = self.activityOld.recurrences, let oldRecurranceIndex = oldRecurrences.firstIndex(where: { $0.starts(with: "RRULE") }) {
                    var oldActivityRule = RecurrenceRule(rruleString: oldRecurrences[oldRecurranceIndex])
                    //will equal true if first instance of repeating event
                    if oldActivityRule?.startDate == self.activityOld.startDate {
                        //update all instances of activity
                        self.createActivity(activity: nil)
                    } else if oldActivityRule != nil, let dateIndex = oldActivityRule!.allOccurrences().firstIndex(of: self.activityOld.startDate ?? Date()), let newRecurrences = self.activity.recurrences, let newRecurranceIndex = newRecurrences.firstIndex(where: { $0.starts(with: "RRULE") }) {
                        
                        //update only future instances of activity
                        var newActivityRule = RecurrenceRule(rruleString: newRecurrences[newRecurranceIndex])
                        newActivityRule!.startDate = self.activity.startDate ?? Date()
                        
                        var newRecurrences = oldRecurrences
                        newRecurrences[newRecurranceIndex] = newActivityRule!.toRRuleString()
                        
                        for recurrence in newRecurrences {
                            print(recurrence)
                        }
                        //duplicate activity w/ new ID and same recurrence rule starting from this event's date
                        self.duplicateActivity(recurrenceRule: newRecurrences)
                        
                        //update existing activity with end date equaling ocurrence before this date
                        oldActivityRule!.recurrenceEnd = EKRecurrenceEnd(occurrenceCount: dateIndex)
                        
                        self.activityOld.recurrences![oldRecurranceIndex] = oldActivityRule!.toRRuleString()
                        
                        for recurrence in self.activityOld.recurrences! {
                            print(recurrence)
                        }
                        
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
        else if !active || sentActivity || true {
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
            self.navigationController?.popViewController(animated: true)
        }
    }
    
    func createActivity(activity: Activity?) {
        if sentActivity {
            showActivityIndicator()
            let createActivity = ActivityActions(activity: activity ?? self.activity, active: false, selectedFalconUsers: [])
            createActivity.createNewActivity()
            hideActivityIndicator()
            if navigationItem.leftBarButtonItem != nil {
                self.dismiss(animated: true, completion: nil)
            } else {
                self.navigationController?.popViewController(animated: true)
            }
        } else {
            showActivityIndicator()
            let createActivity = ActivityActions(activity: activity ?? self.activity, active: active, selectedFalconUsers: selectedFalconUsers)
            createActivity.createNewActivity()
            hideActivityIndicator()
            if navigationItem.leftBarButtonItem != nil {
                self.dismiss(animated: true, completion: nil)
            } else {
                self.navigationController?.popViewController(animated: true)
            }
        }
    }
    
    func fetchMembersIDs() -> ([String], [String:AnyObject]) {
        var membersIDs = [String]()
        var membersIDsDictionary = [String:AnyObject]()
        
        guard let currentUserID = Auth.auth().currentUser?.uid else { return (membersIDs, membersIDsDictionary) }
        
        // Only append current user when admin/creator of the activity
        if self.activity.admin == currentUserID {
            membersIDsDictionary.updateValue(currentUserID as AnyObject, forKey: currentUserID)
            membersIDs.append(currentUserID)
        }
        
        for selectedUser in selectedFalconUsers {
            guard let id = selectedUser.id else { continue }
            membersIDsDictionary.updateValue(id as AnyObject, forKey: id)
            membersIDs.append(id)
        }
        
        return (membersIDs, membersIDsDictionary)
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
        
//        if activity.conversationID == nil {
//            alert.addAction(UIAlertAction(title: "Connect Activity to a Chat", style: .default, handler: { (_) in
//                print("User click Approve button")
//                self.goToChat()
//
//            }))
//        } else {
//            alert.addAction(UIAlertAction(title: "Go to Chat", style: .default, handler: { (_) in
//                print("User click Approve button")
//                self.goToChat()
//
//
//            }))
//        }
        
        alert.addAction(UIAlertAction(title: "Delete Event", style: .default, handler: { (_) in
            self.deleteActivity()
        }))
        
        if let localName = activity.locationName, localName != "locationName", let _ = activity.locationAddress {
            alert.addAction(UIAlertAction(title: "Go to Map", style: .default, handler: { (_) in
                self.goToMap()
            }))
        }
        
//                alert.addAction(UIAlertAction(title: "Share Event", style: .default, handler: { (_) in
//                    print("User click Edit button")
//                    self.share()
//                }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (_) in
            print("User click Dismiss button")
        }))
        
        self.present(alert, animated: true, completion: {
            print("completion block")
        })
        print("shareButtonTapped")
        
    }
    
    @objc func goToChat() {
        if activity!.conversationID != nil {
            if let convo = conversations.first(where: {$0.chatID == activity!.conversationID}) {
                self.chatLogController = ChatLogController(collectionViewLayout: AutoSizingCollectionViewFlowLayout())
                self.messagesFetcher = MessagesFetcher()
                self.messagesFetcher?.delegate = self
                self.messagesFetcher?.loadMessagesData(for: convo)
            }
        } else {
            let destination = ChooseChatTableViewController()
            let navController = UINavigationController(rootViewController: destination)
            destination.delegate = self
            destination.activity = activity
            destination.conversations = conversations
            destination.pinnedConversations = conversations
            destination.filteredConversations = conversations
            destination.filteredPinnedConversations = conversations
            present(navController, animated: true, completion: nil)
        }
    }
    
    @objc func goToMap() {
        guard currentReachabilityStatus != .notReachable else {
            basicErrorAlertWith(title: basicErrorTitleForAlert, message: noInternetError, controller: self)
            return
        }
        
        let destination = MapViewController()
        destination.sections = [.activity]
        var locations = [activity]
        
        if locationAddress.count > 1 {
            locations.append(contentsOf: scheduleList)
            destination.locations = [.activity: locations]
        } else {
            destination.locations = [.activity: locations]
        }
        navigationController?.pushViewController(destination, animated: true)
    }
    
    func deleteActivity() {
        //need to look into equatable protocol for activities
        if activity.recurrences != nil {
            let alert = UIAlertController(title: nil, message: "This is a repeating event.", preferredStyle: .actionSheet)
            
            alert.addAction(UIAlertAction(title: "Delete This Event Only", style: .default, handler: { (_) in
                print("Save for this event only")
                //update activity's recurrence to skip repeat on this date
                if let recurrences = self.activity.recurrences {
                    if let recurrence = recurrences.first(where: { $0.starts(with: "RRULE") }) {
                        var rule = RecurrenceRule(rruleString: recurrence)
                        if rule != nil {
    //                      update existing activity with exlusion date that fall's on this date
                            rule!.exdate = ExclusionDate(dates: [self.activity.startDate ?? Date()], granularity: .day)
                            self.activity.recurrences!.append(rule!.exdate!.toExDateString()!)
                            self.updateRecurrences(recurrences: self.activity.recurrences!)
                        }
                    }
                }
            }))
            
            alert.addAction(UIAlertAction(title: "Delete All Future Events", style: .default, handler: { (_) in
                print("Save for future events")
                //update activity's recurrence to stop repeating at this event
                if let recurrences = self.activity.recurrences {
                    if let recurrence = recurrences.first(where: { $0.starts(with: "RRULE") }) {
                        var rule = RecurrenceRule(rruleString: recurrence)
                        if rule != nil, let index = rule!.allOccurrences().firstIndex(of: self.activity.startDate ?? Date()) {
                            if index > 0 {
                                //update existing activity with end date equaling ocurrence of this date
                                rule!.recurrenceEnd = EKRecurrenceEnd(occurrenceCount: index)
                                self.activity.recurrences = [rule!.toRRuleString()]
                                self.updateRecurrences(recurrences: self.activity.recurrences!)
                            } else {
                                self.showActivityIndicator()
                                let deleteActivity = ActivityActions(activity: self.activity, active: self.active, selectedFalconUsers: self.selectedFalconUsers)
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
            
            alert.addAction(UIAlertAction(title: "Delete Event", style: .default, handler: { (_) in
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
        }
    }
    
    func share() {
        if let activity = activity, let name = activity.name {
            let imageName = "activityLarge"
            if let image = UIImage(named: imageName) {
                let data = compressImage(image: image)
                let aO = ["activityName": "\(name)",
                          "activityID": activityID,
                          "activityImageURL": "\(imageName)",
                          "object": data] as [String: AnyObject]
                let activityObject = ActivityObject(dictionary: aO)
                
                let alert = UIAlertController(title: "Share Event", message: nil, preferredStyle: .actionSheet)
                
                alert.addAction(UIAlertAction(title: "Inside of Plot", style: .default, handler: { (_) in
                    print("User click Approve button")
                    let destination = ChooseChatTableViewController()
                    let navController = UINavigationController(rootViewController: destination)
                    destination.activityObject = activityObject
                    destination.users = self.users
                    destination.filteredUsers = self.filteredUsers
                    destination.conversations = self.conversations
                    destination.filteredConversations = self.conversations
                    destination.filteredPinnedConversations = self.conversations
                    self.present(navController, animated: true, completion: nil)
                    
                }))
                
                alert.addAction(UIAlertAction(title: "Outside of Plot", style: .default, handler: { (_) in
                    print("User click Edit button")
                    // Fallback on earlier versions
                    let shareText = "Hey! Download Plot on the App Store so I can share an activity with you."
                    guard let url = URL(string: "https://apps.apple.com/us/app/plot-scheduling-app/id1473764067?ls=1")
                    else { return }
                    let shareContent: [Any] = [shareText, url]
                    let activityController = UIActivityViewController(activityItems: shareContent,
                                                                      applicationActivities: nil)
                    self.present(activityController, animated: true, completion: nil)
                    activityController.completionWithItemsHandler = { (activityType: UIActivity.ActivityType?, completed:
                                                                        Bool, arrayReturnedItems: [Any]?, error: Error?) in
                        if completed {
                            print("share completed")
                            return
                        } else {
                            print("cancel")
                        }
                        if let shareError = error {
                            print("error while sharing: \(shareError.localizedDescription)")
                        }
                    }
                    
                }))
                
                
                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (_) in
                    print("User click Dismiss button")
                }))
                
                self.present(alert, animated: true, completion: {
                    print("completion block")
                })
                print("shareButtonTapped")
            }
            
            
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
    
//    func lookupRecipe(recipeID: Int, add: Bool) {
//        guard currentReachabilityStatus != .notReachable else {
//            basicErrorAlertWith(title: basicErrorTitleForAlert, message: noInternetError, controller: self)
//            return
//        }
//
//        let dispatchGroup = DispatchGroup()
//        dispatchGroup.enter()
//        Service.shared.fetchRecipesInfo(id: recipeID) { (search, err) in
//            dispatchGroup.leave()
//            dispatchGroup.notify(queue: .main) {
//                if let recipe = search {
//                    if add {
//                        self.updateGrocerylist(recipe: recipe, add: true)
//                    } else {
//                        self.updateGrocerylist(recipe: recipe, add: false)
//                    }
//                }
//            }
//        }
//    }
    
//    func updateGrocerylist(recipe: Recipe, add: Bool) {
//        if self.activity.grocerylistID != nil, let grocerylist = listList[grocerylistIndex].grocerylist, grocerylist.ingredients != nil, let recipeIngredients = recipe.extendedIngredients {
//            var glIngredients = grocerylist.ingredients!
//            if let grocerylistServings = grocerylist.servings!["\(recipe.id)"], grocerylistServings != recipe.servings {
//                grocerylist.servings!["\(recipe.id)"] = recipe.servings
//                for recipeIngredient in recipeIngredients {
//                    if let index = glIngredients.firstIndex(where: {$0 == recipeIngredient}) {
//                        glIngredients[index].recipe![recipe.title] = recipeIngredient.amount ?? 0.0
//                        if glIngredients[index].amount != nil && recipeIngredient.amount != nil  {
//                            glIngredients[index].amount! +=  recipeIngredient.amount! - recipeIngredient.amount! * Double(grocerylistServings) / Double(recipe.servings!)
//                        }
//                    }
//                }
//            } else if grocerylist.recipes!["\(recipe.id)"] != nil && add {
//                return
//            } else {
//                if add {
//                    if grocerylist.recipes != nil {
//                        grocerylist.recipes!["\(recipe.id)"] = recipe.title
//                        grocerylist.servings!["\(recipe.id)"] = recipe.servings
//                    } else {
//                        grocerylist.recipes = ["\(recipe.id)": recipe.title]
//                        grocerylist.servings = ["\(recipe.id)": recipe.servings!]
//                    }
//                } else {
//                    grocerylist.recipes!["\(recipe.id)"] = nil
//                    grocerylist.servings!["\(recipe.id)"] = nil
//                }
//                for recipeIngredient in recipeIngredients {
//                    if let index = glIngredients.firstIndex(where: {$0 == recipeIngredient}) {
//                        if add {
//                            glIngredients[index].recipe![recipe.title] = recipeIngredient.amount ?? 0.0
//                            if glIngredients[index].amount != nil {
//                                glIngredients[index].amount! += recipeIngredient.amount ?? 0.0
//                            }
//                        } else {
//                            if glIngredients[index].amount != nil {
//                                glIngredients[index].amount! -= recipeIngredient.amount ?? 0.0
//                                if glIngredients[index].amount! == 0 {
//                                    glIngredients.remove(at: index)
//                                    continue
//                                } else {
//                                    glIngredients[index].recipe![recipe.title] = nil
//                                }
//                            }
//                        }
//                    } else {
//                        if add {
//                            var recIngredient = recipeIngredient
//                            recIngredient.recipe = [recipe.title: recIngredient.amount ?? 0.0]
//                            glIngredients.append(recIngredient)
//                        }
//                    }
//                }
//            }
//            if glIngredients.isEmpty {
//                let mvs = (form.sectionBy(tag: "listsfields") as! MultivaluedSection)
//                mvs.remove(at: grocerylistIndex)
//                listList.remove(at: grocerylistIndex)
//                grocerylistIndex = -1
//                self.activity.grocerylistID = nil
//
//                let deleteGrocerylist = GrocerylistActions(grocerylist: grocerylist, ID: grocerylist.ID, active: true, selectedFalconUsers: self.selectedFalconUsers)
//                deleteGrocerylist.deleteGrocerylist()
//
//            } else {
//                grocerylist.ingredients = glIngredients
//                let createGrocerylist = GrocerylistActions(grocerylist: grocerylist, ID: grocerylist.ID, active: true, selectedFalconUsers: self.selectedFalconUsers)
//                createGrocerylist.createNewGrocerylist()
//                if listList.indices.contains(grocerylistIndex) {
//                    listList[grocerylistIndex].grocerylist = grocerylist
//                }
//            }
//        } else if let recipeIngredients = recipe.extendedIngredients, add, let currentUserID = Auth.auth().currentUser?.uid {
//            let ID = Database.database().reference().child(userGrocerylistsEntity).child(currentUserID).childByAutoId().key ?? ""
//            let grocerylist = Grocerylist(dictionary: ["name" : "\(activity.name ?? "") Grocery List"] as [String: AnyObject])
//
//            var mvs = (form.sectionBy(tag: "listsfields") as! MultivaluedSection)
//            mvs.insert(ButtonRow() { row in
//                row.cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
//                row.cell.textLabel?.textAlignment = .left
//                row.cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
//                row.title = grocerylist.name
//                self.grocerylistIndex = mvs.count - 1
//            }.onCellSelection({ cell, row in
//                self.listIndex = row.indexPath!.row
//                self.openList()
//            }).cellUpdate { cell, row in
//                cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
//                cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
//                cell.textLabel?.textAlignment = .left
//            }, at: mvs.count - 1)
//
//            grocerylist.ID = ID
//            grocerylist.activityID = activityID
//
//            grocerylist.ingredients = recipeIngredients
//            for index in 0...grocerylist.ingredients!.count - 1 {
//                grocerylist.ingredients![index].recipe = [recipe.title: grocerylist.ingredients![index].amount ?? 0.0]
//            }
//            grocerylist.recipes = ["\(recipe.id)": recipe.title]
//            grocerylist.servings = ["\(recipe.id)": recipe.servings!]
//
//            let createGrocerylist = GrocerylistActions(grocerylist: grocerylist, ID: grocerylist.ID, active: false, selectedFalconUsers: self.selectedFalconUsers)
//            createGrocerylist.createNewGrocerylist()
//
//            var list = ListContainer()
//            list.grocerylist = grocerylist
//            listList.append(list)
//
//            grocerylistIndex = listList.count - 1
//
//            self.updateLists(type: "lists")
//        }
//    }
    
    func resetBadgeForSelf() {
        guard let currentUserID = Auth.auth().currentUser?.uid else { return }
        let badgeRef = Database.database().reference().child("user-activities").child(currentUserID).child(activityID).child(messageMetaDataFirebaseFolder).child("badge")
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
        var ref = Database.database().reference().child("user-activities").child(firstChild).child(secondChild)
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
