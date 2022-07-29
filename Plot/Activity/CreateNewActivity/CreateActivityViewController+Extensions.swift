//
//  CreateActivityViewController+Extensions.swift
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

extension CreateActivityViewController: UITextFieldDelegate {
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


//extension CreateActivityViewController: UITextViewDelegate {
//
//    func textViewDidBeginEditing(_ textView: UITextView) {
//        //        createActivityView.activityDescriptionPlaceholderLabel.isHidden = true
//        if textView.textColor == FalconPalette.defaultBlue {
//            textView.text = nil
//            textView.textColor = ThemeManager.currentTheme().generalTitleColor
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

extension CreateActivityViewController: UpdateActivityCategoryDelegate {
    func update(value: String) {
        if let row = form.rowBy(tag: "Category") {
            row.title = value
            row.updateCell()
            self.activity.category = value
        }
    }
}

extension CreateActivityViewController: UpdateCalendarDelegate {
    func update(calendar: CalendarType) {
        if let row = form.rowBy(tag: "Calendar") {
            row.title = calendar.name
            row.updateCell()
            self.activity.calendarID = calendar.id
            self.activity.calendarName = calendar.name
            self.activity.calendarColor = calendar.color
            guard let currentUserID = Auth.auth().currentUser?.uid else { return }
            let userReference = Database.database().reference().child(userActivitiesEntity).child(currentUserID).child(self.activityID).child(messageMetaDataFirebaseFolder)
            let values:[String : Any] = ["calendarID": calendar.id as Any, "calendarName": calendar.name as Any, "calendarColor": calendar.color as Any]
            userReference.updateChildValues(values)
        }
    }
}

extension CreateActivityViewController: UpdateLocationDelegate {
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

extension CreateActivityViewController: UpdateTimeZoneDelegate {
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

extension CreateActivityViewController: UpdateScheduleDelegate {
    func updateSchedule(schedule: Activity) {
        if let _ = schedule.name {
            if scheduleList.indices.contains(scheduleIndex), let mvs = self.form.sectionBy(tag: "schedulefields") as? MultivaluedSection {
                let scheduleRow = mvs.allRows[scheduleIndex]
                scheduleRow.baseValue = schedule
                scheduleRow.reload()
                scheduleList[scheduleIndex] = schedule
            } else {
                var mvs = (form.sectionBy(tag: "schedulefields") as! MultivaluedSection)
                mvs.insert(ScheduleRow() {
                    $0.value = schedule
                    }.onCellSelection() { cell, row in
                        self.scheduleIndex = row.indexPath!.row
                        self.openSchedule()
                        cell.cellResignFirstResponder()
                }, at: mvs.count - 1)
                
                Analytics.logEvent("new_schedule", parameters: [
                    "schedule_name": schedule.name ?? "name" as NSObject,
                    "schedule_type": schedule.activityType ?? "basic" as NSObject
                ])
                scheduleList.append(schedule)
            }
            
            sortSchedule()
            if let localAddress = schedule.locationAddress {
                for (key, value) in localAddress {
                    locationAddress[key] = value
                }
            }
            updateLists(type: "schedule")
        }
    }
    func updateIngredients(recipe: Recipe?, recipeID: String?) {
//        if let recipe = recipe {
//            updateGrocerylist(recipe: recipe, add: true)
//        } else if let recipeID = recipeID {
//            lookupRecipe(recipeID: Int(recipeID)!, add: true)
//        }
    }
}

extension CreateActivityViewController: ChooseActivityDelegate {
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
        if let _: ScheduleRow = form.rowBy(tag: "label"), let mvs = self.form.sectionBy(tag: "schedulefields") as? MultivaluedSection {
            mvs.remove(at: mvs.count - 2)
        }
        if let _ = mergeActivity.name, let currentUserID = Auth.auth().currentUser?.uid {
            self.getParticipants(forActivity: mergeActivity) { (participants) in
                let deleteActivity = ActivityActions(activity: mergeActivity, active: true, selectedFalconUsers: participants)
                deleteActivity.deleteActivity()
            }
            
            mergeActivity.participantsIDs = [currentUserID]
            mergeActivity.admin = currentUserID
            
            var mvs = (form.sectionBy(tag: "schedulefields") as! MultivaluedSection)
            mvs.insert(ScheduleRow() {
                $0.value = mergeActivity
                }.onCellSelection() { cell, row in
                    self.scheduleIndex = row.indexPath!.row
                    self.openSchedule()
                    cell.cellResignFirstResponder()
            }, at: mvs.count - 1)
            
            Analytics.logEvent("new_schedule", parameters: [
                "schedule_name": mergeActivity.name ?? "name" as NSObject,
                "schedule_type": mergeActivity.activityType ?? "basic" as NSObject
            ])
            
            scheduleList.append(mergeActivity)
            
            sortSchedule()
            if let localAddress = mergeActivity.locationAddress {
                for (key, value) in localAddress {
                    locationAddress[key] = value
                }
            }
            updateLists(type: "schedule")
        }
    }
}

extension CreateActivityViewController: UpdateTransactionDelegate {
    func updateTransaction(transaction: Transaction) {
        var mvs = self.form.sectionBy(tag: "purchasefields") as! MultivaluedSection
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
            updateLists(type: "purchases")
        }
        else if mvs.allRows.count - 1 > purchaseIndex {
            mvs.remove(at: purchaseIndex)
        }
//            purchaseBreakdown()
    }
}

extension CreateActivityViewController: ChooseTransactionDelegate {
    func chosenTransaction(transaction: Transaction) {
        var mvs = self.form.sectionBy(tag: "purchasefields") as! MultivaluedSection
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
            updateLists(type: "purchases")
        }
        else if mvs.allRows.count - 1 > purchaseIndex {
            mvs.remove(at: purchaseIndex)
        }
//            purchaseBreakdown()
    }
}

extension CreateActivityViewController: UpdateMealDelegate {
    func updateMeal(meal: Meal) {
        var mvs = self.form.sectionBy(tag: "healthfields") as! MultivaluedSection
        if meal.name != "Name" {
            if healthList.indices.contains(healthIndex) {
                healthList[healthIndex].meal = meal
            } else {
                var health = HealthContainer()
                health.meal = meal
                healthList.append(health)
            }
            if mvs.allRows.count - 1 == healthIndex {
                mvs.insert(HealthRow() {
                    $0.value = healthList[healthIndex]
                    }.onCellSelection() { cell, row in
                        self.scheduleIndex = row.indexPath!.row
                        self.openSchedule()
                        cell.cellResignFirstResponder()
                }, at: healthIndex)
            } else {
                let row = mvs.allRows[healthIndex]
                row.baseValue = healthList[healthIndex]
                row.updateCell()
            }
            updateLists(type: "health")
        }
        else if mvs.allRows.count - 1 > healthIndex {
            mvs.remove(at: healthIndex)
        }
    }
}

extension CreateActivityViewController: UpdateWorkoutDelegate {
    func updateWorkout(workout: Workout) {
        var mvs = self.form.sectionBy(tag: "healthfields") as! MultivaluedSection
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
                        self.scheduleIndex = row.indexPath!.row
                        self.openSchedule()
                        cell.cellResignFirstResponder()
                }, at: healthIndex)
            } else {
                let row = mvs.allRows[healthIndex]
                row.baseValue = healthList[healthIndex]
                row.updateCell()
            }
            updateLists(type: "health")
        }
        else if mvs.allRows.count - 1 > healthIndex {
            mvs.remove(at: healthIndex)
        }
    }
}

extension CreateActivityViewController: UpdateMindfulnessDelegate {
    func updateMindfulness(mindfulness: Mindfulness) {
        var mvs = self.form.sectionBy(tag: "healthfields") as! MultivaluedSection
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
                        self.scheduleIndex = row.indexPath!.row
                        self.openSchedule()
                        cell.cellResignFirstResponder()
                }, at: healthIndex)
            } else {
                let row = mvs.allRows[healthIndex]
                row.baseValue = healthList[healthIndex]
                row.updateCell()
            }
            updateLists(type: "health")
        }
        else if mvs.allRows.count - 1 > healthIndex {
            mvs.remove(at: healthIndex)
        }
    }
}

extension CreateActivityViewController: UpdateActivityMediaDelegate {
    func updateActivityMedia(activityPhotos: [String], activityFiles: [String]) {
        activity.activityPhotos = activityPhotos
        activity.activityFiles = activityFiles
        if let mediaRow: ButtonRow = form.rowBy(tag: "Media") {
            if self.activity.activityPhotos == nil || self.activity.activityPhotos!.isEmpty || self.activity.activityFiles == nil || self.activity.activityFiles!.isEmpty {
                mediaRow.cell.textLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
            } else {
                mediaRow.cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
            }
        }
    }
}

extension CreateActivityViewController: UpdateActivityListDelegate {
    func updateActivityList(listList: [ListContainer]) {
        if let row: ButtonRow = form.rowBy(tag: "Checklist") {
            if listList.isEmpty {
                row.cell.textLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
            } else {
                row.cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
            }
        }
        self.listList = listList
        self.updateLists(type: "lists")
    }
}

extension CreateActivityViewController: RecurrencePickerDelegate {
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
//                let reference = Database.database().reference().child(activitiesEntity).child(self.activityID).child(messageMetaDataFirebaseFolder).child("recurrences")
//                reference.removeValue()
            }
        }
    }
}

extension CreateActivityViewController: ChooseChatDelegate {
    func chosenChat(chatID: String, activityID: String?, grocerylistID: String?, checklistID: String?, packinglistID: String?, activitylistID: String?) {
        if let activityID = activityID {
            let updatedConversationID = ["conversationID": chatID as AnyObject]
            Database.database().reference().child("activities").child(activityID).child(messageMetaDataFirebaseFolder).updateChildValues(updatedConversationID)

            if let conversation = conversations.first(where: {$0.chatID == chatID}) {
                if conversation.activities != nil {
                    var activities = conversation.activities!
                    activities.append(activityID)
                    let updatedActivities = ["activities": activities as AnyObject]
                    Database.database().reference().child("groupChats").child(conversation.chatID!).child(messageMetaDataFirebaseFolder).updateChildValues(updatedActivities)
                } else {
                    let updatedActivities = ["activities": [activityID] as AnyObject]
                    Database.database().reference().child("groupChats").child(conversation.chatID!).child(messageMetaDataFirebaseFolder).updateChildValues(updatedActivities)
                }
                if activity.grocerylistID != nil {
                    if conversation.grocerylists != nil {
                        var grocerylists = conversation.grocerylists!
                        grocerylists.append(activity.grocerylistID!)
                        let updatedGrocerylists = [grocerylistsEntity: grocerylists as AnyObject]
                        Database.database().reference().child("groupChats").child(conversation.chatID!).child(messageMetaDataFirebaseFolder).updateChildValues(updatedGrocerylists)
                    } else {
                        let updatedGrocerylists = [grocerylistsEntity: [activity.grocerylistID!] as AnyObject]
                        Database.database().reference().child("groupChats").child(conversation.chatID!).child(messageMetaDataFirebaseFolder).updateChildValues(updatedGrocerylists)
                    }
                    Database.database().reference().child(grocerylistsEntity).child(activity.grocerylistID!).updateChildValues(updatedConversationID)
                }
                if activity.checklistIDs != nil {
                    if conversation.checklists != nil {
                        let checklists = conversation.checklists! + activity.checklistIDs!
                        let updatedChecklists = [checklistsEntity: checklists as AnyObject]
                        Database.database().reference().child("groupChats").child(conversation.chatID!).child(messageMetaDataFirebaseFolder).updateChildValues(updatedChecklists)
                    } else {
                        let updatedChecklists = [checklistsEntity: activity.checklistIDs! as AnyObject]
                        Database.database().reference().child("groupChats").child(conversation.chatID!).child(messageMetaDataFirebaseFolder).updateChildValues(updatedChecklists)
                    }
                    for ID in activity.checklistIDs! {
                        Database.database().reference().child(checklistsEntity).child(ID).updateChildValues(updatedConversationID)

                    }
                }
                if activity.activitylistIDs != nil {
                    if conversation.activitylists != nil {
                        let activitylists = conversation.activitylists! + activity.activitylistIDs!
                        let updatedActivitylists = [activitylistsEntity: activitylists as AnyObject]
                        Database.database().reference().child("groupChats").child(conversation.chatID!).child(messageMetaDataFirebaseFolder).updateChildValues(updatedActivitylists)
                    } else {
                        let updatedActivitylists = [activitylistsEntity: activity.activitylistIDs! as AnyObject]
                        Database.database().reference().child("groupChats").child(conversation.chatID!).child(messageMetaDataFirebaseFolder).updateChildValues(updatedActivitylists)
                    }
                    for ID in activity.activitylistIDs! {
                        Database.database().reference().child(activitylistsEntity).child(ID).updateChildValues(updatedConversationID)

                    }
                }
                if activity.packinglistIDs != nil {
                    if conversation.packinglists != nil {
                        let packinglists = conversation.packinglists! + activity.packinglistIDs!
                        let updatedPackinglists = [packinglistsEntity: packinglists as AnyObject]
                        Database.database().reference().child("groupChats").child(conversation.chatID!).child(messageMetaDataFirebaseFolder).updateChildValues(updatedPackinglists)
                    } else {
                        let updatedPackinglists = [packinglistsEntity: activity.packinglistIDs! as AnyObject]
                        Database.database().reference().child("groupChats").child(conversation.chatID!).child(messageMetaDataFirebaseFolder).updateChildValues(updatedPackinglists)
                    }
                   for ID in activity.packinglistIDs! {
                        Database.database().reference().child(packinglistsEntity).child(ID).updateChildValues(updatedConversationID)

                    }
                }
            }
            self.connectedToChatAlert()
            self.dismiss(animated: true, completion: nil)
        }
    }
}

extension CreateActivityViewController: MessagesDelegate {
    
    func messages(shouldChangeMessageStatusToReadAt reference: DatabaseReference) {
        chatLogController?.updateMessageStatus(messageRef: reference)
    }
    
    func messages(shouldBeUpdatedTo messages: [Message], conversation: Conversation) {
        
        chatLogController?.hidesBottomBarWhenPushed = true
        chatLogController?.messagesFetcher = messagesFetcher
        chatLogController?.messages = messages
        chatLogController?.conversation = conversation
        
        if let membersIDs = conversation.chatParticipantsIDs, let uid = Auth.auth().currentUser?.uid, membersIDs.contains(uid) {
            chatLogController?.observeTypingIndicator()
            chatLogController?.configureTitleViewWithOnlineStatus()
        }
        
        chatLogController?.messagesFetcher.collectionDelegate = chatLogController
        guard let destination = chatLogController else { return }
        
        if #available(iOS 11.0, *) {
        } else {
            self.chatLogController?.startCollectionViewAtBottom()
        }
        
        navigationController?.pushViewController(destination, animated: true)
        chatLogController = nil
        messagesFetcher?.delegate = nil
        messagesFetcher = nil
    }
}

public extension Form {
    func valuesForFirebase(includeHidden: Bool = false) -> [String: Any?] {
        let rows = includeHidden ? self.allRows : self.rows
        return rows.filter({ $0.tag != nil })
            .reduce([:], { (dictionary, row) -> [String: Any?] in
                var dictionary = dictionary
                dictionary[row.tag!] = row.firebaseValue
                return dictionary
            })
    }
}

public extension Dictionary {
    func valuesForEureka(forForm form: Form) -> [String: Any?] {
        return self.reduce([:], { (dictionary, tuple) -> [String: Any?] in
            var dictionary = dictionary
            let row = form.rowBy(tag: tuple.key as! String)
            if row is SwitchRow || row is CheckRow {
                let typedValue = tuple.value as! Int
                dictionary[tuple.key as! String] = (typedValue == 1) ? true : false
            } else if row is DateRow || row is TimeRow || row is DateTimeRow {
                let typedValue = tuple.value as! TimeInterval
                dictionary[tuple.key as! String] = Date(timeIntervalSince1970: typedValue)
            } else {
                dictionary[tuple.key as! String] = tuple.value
            }
            return dictionary
        })
    }
}

private extension BaseRow {
    var firebaseValue: Any? {
        get {
            if self is SwitchRow || self is CheckRow {
                return (self.baseValue as! Bool) ? true : false
            } else if self is DateRow || self is TimeRow || self is DateTimeRow || self is DateTimeInlineRow {
                return NSNumber(value: Int((self.baseValue as! Date).timeIntervalSince1970))
            }
            else {
                if self.baseValue == nil {
                    return "nothing"
                } else {
                    return self.baseValue
                }
            }
        }
    }
}
