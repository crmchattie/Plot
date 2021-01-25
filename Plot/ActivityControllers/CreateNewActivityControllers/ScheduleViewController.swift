//
//  ScheduleViewController.swift
//  Pigeon-project
//
//  Created by Cory McHattie on 5/22/19.
//  Copyright © 2019 Immature Creations. All rights reserved.
//

import UIKit
import Eureka
import SplitRow
import Firebase
import Contacts
import EventKit


protocol UpdateScheduleDelegate: class {
    func updateSchedule(schedule: Activity)
    func updateIngredients(recipe: Recipe?, recipeID: String?)
}

class ScheduleViewController: FormViewController {
    
    weak var delegate : UpdateScheduleDelegate?
    
    var schedule: Activity!
    
    var users = [User]()
    var filteredUsers = [User]()
    var selectedFalconUsers = [User]()
    var locationName: String = "locationName"
    var locationAddress = [String : [Double]]()
    var checklist = [Checklist]()
    var startDateTime: Date?
    var endDateTime: Date?
    var userNames : [String] = []
    var userNamesString: String = ""
    
    var scheduleID = String()
    
    fileprivate var active: Bool = false
        
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for:.default)
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.navigationBar.layoutIfNeeded()
        
        if schedule != nil {
            title = "Activity"
            active = true
            if schedule.activityID != nil {
                scheduleID = schedule.activityID!
            } else {
                schedule.activityID = UUID().uuidString
            }
            userNamesString = "Participants"
            for ID in schedule!.participantsIDs! {
                // users equals ACTIVITY selected falcon users
                if let user = users.first(where: {$0.id == ID}) {
                    selectedFalconUsers.append(user)
                }
            }
            if let localName = schedule.locationName, localName != "locationName", let localAddress = schedule.locationAddress  {
                locationName = localName
                locationAddress = localAddress
            }
            if schedule.checklist != nil {
                checklist = schedule.checklist!
            }
        } else {
            title = "New Activity"
            scheduleID = UUID().uuidString
            schedule = Activity(dictionary: ["activityID": scheduleID as AnyObject])
        }
        
        setupMainView()
        initializeForm()
        
    }
    
    fileprivate func setupMainView() {
        if #available(iOS 11.0, *) {
            navigationItem.largeTitleDisplayMode = .never
        }
        view.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
        tableView.indicatorStyle = ThemeManager.currentTheme().scrollBarStyle
        tableView.sectionIndexBackgroundColor = view.backgroundColor
        tableView.backgroundColor = view.backgroundColor
        tableView.separatorStyle = UITableViewCell.SeparatorStyle.none
        
        if !active {
            let plusBarButton =  UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(rightBarButtonTapped))
            navigationItem.rightBarButtonItem = plusBarButton
            let cancelBarButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancel))
            navigationItem.leftBarButtonItem = cancelBarButton
        } else {
            if let localName = schedule.locationName, localName != "locationName" {
                let dotsImage = UIImage(named: "dots")
                let plusBarButton =  UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(rightBarButtonTapped))
                let dotsBarButton = UIBarButtonItem(image: dotsImage, style: .plain, target: self, action: #selector(goToExtras))
                navigationItem.rightBarButtonItems = [plusBarButton, dotsBarButton]
            } else {
                let plusBarButton =  UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(rightBarButtonTapped))
                navigationItem.rightBarButtonItem = plusBarButton
            }
            navigationItem.rightBarButtonItem?.isEnabled = true
        }
        
    }
    
    @IBAction func cancel(_ sender: AnyObject) {
        self.dismiss(animated: true, completion: nil)
    }
    
    fileprivate func initializeForm() {
        
        form +++
            Section()
        
            <<< TextRow("Activity Name") {
                $0.cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                $0.cell.textField?.textColor = ThemeManager.currentTheme().generalTitleColor
                $0.placeholderColor = ThemeManager.currentTheme().generalSubtitleColor
                $0.placeholder = $0.tag
                if self.active {
                    $0.value = self.schedule.name
                    self.navigationItem.rightBarButtonItem?.isEnabled = true
                } else {
                    $0.cell.textField.becomeFirstResponder()
                    self.navigationItem.rightBarButtonItem?.isEnabled = false
                }
                }.onChange() { [unowned self] row in
                    if row.value == nil {
                        self.navigationItem.rightBarButtonItem?.isEnabled = false
                    } else {
                        self.navigationItem.rightBarButtonItem?.isEnabled = true
                    }
                }.cellUpdate { cell, row in
                    cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                    cell.textField?.textColor = ThemeManager.currentTheme().generalTitleColor
                    row.placeholderColor = ThemeManager.currentTheme().generalSubtitleColor
            }
            
            <<< TextRow("Activity Type") {
                $0.cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                $0.cell.textField?.textColor = ThemeManager.currentTheme().generalTitleColor
                $0.placeholderColor = ThemeManager.currentTheme().generalSubtitleColor
                $0.placeholder = $0.tag
                if self.active && self.schedule.activityType != nil && self.schedule.activityType != "nothing" {
                    $0.value = self.schedule.activityType
                }
                }.cellUpdate { cell, row in
                    cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                    cell.textField?.textColor = ThemeManager.currentTheme().generalTitleColor
                    row.placeholderColor = ThemeManager.currentTheme().generalSubtitleColor
            }
            
            <<< TextAreaRow("Description") {
                $0.cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                $0.cell.textView?.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                $0.cell.textView?.textColor = ThemeManager.currentTheme().generalTitleColor
                $0.cell.placeholderLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
                $0.placeholder = $0.tag
                if self.active && self.schedule.activityDescription != nil && self.schedule.activityDescription != "nothing" {
                    $0.value = self.schedule.activityDescription
                }
                }.cellUpdate({ (cell, row) in
                    cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                    cell.textView?.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                    cell.textView?.textColor = ThemeManager.currentTheme().generalTitleColor
                    cell.placeholderLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
                })
            
            <<< ButtonRow("Location") { row in
                row.cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                row.cell.textLabel?.textAlignment = .left
                row.cell.textLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
                row.cell.accessoryType = .disclosureIndicator
                row.title = row.tag
                if self.active, let localName = schedule.locationName, localName != "locationName" {
                    row.cell.accessoryType = .detailDisclosureButton
                    row.cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                    row.title = localName
                }
                }.onCellSelection({ _,_ in
                    self.openLocationFinder()
                }).cellUpdate { cell, row in
                    cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                    cell.textLabel?.textAlignment = .left
                    if row.title == "Location" {
                        cell.accessoryType = .disclosureIndicator
                        cell.textLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
                    } else {
                        cell.accessoryType = .detailDisclosureButton
                        cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                    }
            }
            
            <<< ButtonRow("Participants") { row in
                row.cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                row.cell.textLabel?.textAlignment = .left
                row.cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                row.cell.accessoryType = .disclosureIndicator
                row.title = row.tag
                }.onCellSelection({ _,_ in
                    self.openParticipantsInviter()
                }).cellUpdate { cell, row in
                    cell.accessoryType = .disclosureIndicator
                    cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                    cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                    cell.textLabel?.textAlignment = .left
            }
            
            <<< SwitchRow("All-day") {
                $0.cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                $0.cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                $0.title = $0.tag
                if self.active {
                    $0.value = self.schedule.allDay
                } else {
                    $0.value = false
                }
                }.onChange { [weak self] row in
                    let startDate: DateTimeInlineRow! = self?.form.rowBy(tag: "Starts")
                    let endDate: DateTimeInlineRow! = self?.form.rowBy(tag: "Ends")
                    
                    if row.value ?? false {
                        startDate.dateFormatter?.timeStyle = .none
                        endDate.dateFormatter?.timeStyle = .none
                    }
                    else {
                        startDate.dateFormatter?.timeStyle = .short
                        endDate.dateFormatter?.timeStyle = .short
                    }
                    startDate.updateCell()
                    endDate.updateCell()
                    startDate.inlineRow?.updateCell()
                    endDate.inlineRow?.updateCell()
                }.cellUpdate { cell, row in
                    cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                    cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                    
            }

            
            <<< DateTimeInlineRow("Starts") {
                $0.cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                $0.cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                $0.cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
                $0.title = $0.tag
                $0.minuteInterval = 5
                $0.dateFormatter?.dateStyle = .medium
                $0.dateFormatter?.timeStyle = .short
                if self.active {
                    $0.dateFormatter?.timeZone = TimeZone(identifier: schedule.startTimeZone ?? "UTC")
                    $0.value = Date(timeIntervalSince1970: self.schedule!.startDateTime as! TimeInterval)
                    if self.schedule.allDay == true {
                        $0.dateFormatter?.timeStyle = .none
                    }
                    else {
                        $0.dateFormatter?.timeStyle = .short
                    }
                    $0.updateCell()
                } else {
                    $0.dateFormatter?.timeZone = .current
                    let original = Date()
                    let rounded = Date(timeIntervalSinceReferenceDate:
                    (original.timeIntervalSinceReferenceDate / 300.0).rounded(.toNearestOrEven) * 300.0)
                    $0.value = rounded
                    self.schedule.startDateTime = NSNumber(value: Int(($0.value!).timeIntervalSince1970))
                }
                self.startDateTime = $0.value
                }.onChange { [weak self] row in
                    let endRow: DateTimeInlineRow! = self?.form.rowBy(tag: "Ends")
                    if row.value?.compare(endRow.value!) == .orderedDescending {
                        endRow.value = Date(timeInterval: 0, since: row.value!)
                        endRow.updateCell()
                    }
                    self!.schedule.startDateTime = NSNumber(value: Int((row.value!).timeIntervalSince1970))
                    self!.startDateTime = row.value
                    if self!.active {
                        self!.scheduleReminder()
                    }
                }.onExpandInlineRow { [weak self] cell, row, inlineRow in
                    inlineRow.cellUpdate { (cell, row) in
                        row.cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                        row.cell.tintColor = ThemeManager.currentTheme().generalBackgroundColor
                        if #available(iOS 13.4, *) {
                            cell.datePicker.preferredDatePickerStyle = .wheels
                        }
                        let allRow: SwitchRow! = self?.form.rowBy(tag: "All-day")
                        if allRow.value ?? false {
                            cell.datePicker.datePickerMode = .date
                        }
                        else {
                            cell.datePicker.datePickerMode = .dateAndTime
                        }
                        if let startTimeZone = self?.schedule.startTimeZone {
                            cell.datePicker.timeZone = TimeZone(identifier: startTimeZone)
                        } else if self!.active {
                            cell.datePicker.timeZone = NSTimeZone(name: "UTC") as TimeZone?
                        } else {
                            cell.datePicker.timeZone = .current
                        }
                    }
                    cell.detailTextLabel?.textColor = cell.tintColor
                    if let timeZoneRow: LabelRow = self?.form.rowBy(tag: "startTimeZone") {
                        timeZoneRow.hidden = false
                        timeZoneRow.evaluateHidden()
                    }
                }.onCollapseInlineRow { cell, _, _ in
                    cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
                    if let timeZoneRow: LabelRow = self.form.rowBy(tag: "startTimeZone") {
                        timeZoneRow.hidden = true
                        timeZoneRow.evaluateHidden()
                    }
                }.cellUpdate { cell, row in
                    cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                    cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                }
            
            <<< LabelRow("startTimeZone") { row in
                row.cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                row.cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                row.cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
                row.cell.accessoryType = .disclosureIndicator
                row.title = "Time Zone"
                row.hidden = true
                if active {
                    row.value = schedule.startTimeZone ?? "UTC"
                } else {
                    row.value = TimeZone.current.identifier
                    schedule.startTimeZone = TimeZone.current.identifier
                }
                }.onCellSelection({ _,_ in
                    self.openTimeZoneFinder(startOrEndTimeZone: "startTimeZone")
                }).cellUpdate { cell, row in
                    cell.accessoryType = .disclosureIndicator
                    cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                    cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                }
            
            <<< DateTimeInlineRow("Ends") {
                $0.cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                $0.cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                $0.cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
                $0.title = $0.tag
                $0.minuteInterval = 5
                $0.dateFormatter?.dateStyle = .medium
                $0.dateFormatter?.timeStyle = .short
                if self.active {
                    $0.dateFormatter?.timeZone = TimeZone(identifier: schedule.endTimeZone ?? "UTC")
                    $0.value = Date(timeIntervalSince1970: self.schedule!.endDateTime as! TimeInterval)
                    if self.schedule.allDay == true {
                        $0.dateFormatter?.timeStyle = .none
                    }
                    else {
                        $0.dateFormatter?.timeStyle = .short
                    }
                    $0.updateCell()
                } else {
                    $0.dateFormatter?.timeZone = .current
                    let original = Date()
                    let rounded = Date(timeIntervalSinceReferenceDate:
                    (original.timeIntervalSinceReferenceDate / 300.0).rounded(.toNearestOrEven) * 300.0)
                    $0.value = rounded
                    self.schedule.endDateTime = NSNumber(value: Int(($0.value!).timeIntervalSince1970))
                }
                self.endDateTime = $0.value
                }.onChange { [weak self] row in
                    let startRow: DateTimeInlineRow! = self?.form.rowBy(tag: "Starts")
                    if row.value?.compare(startRow.value!) == .orderedAscending {
                        startRow.value = Date(timeInterval: 0, since: row.value!)
                        startRow.updateCell()
                    }
                    self!.schedule.endDateTime = NSNumber(value: Int((row.value!).timeIntervalSince1970))
                    self!.endDateTime = row.value
                }.onExpandInlineRow { [weak self] cell, row, inlineRow in
                inlineRow.cellUpdate { (cell, row) in
                    row.cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                    row.cell.tintColor = ThemeManager.currentTheme().generalBackgroundColor
                    if let endTimeZone = self?.schedule.endTimeZone {
                        cell.datePicker.timeZone = TimeZone(identifier: endTimeZone)
                    } else if self!.active {
                        cell.datePicker.timeZone = NSTimeZone(name: "UTC") as TimeZone?
                    } else {
                        cell.datePicker.timeZone = .current
                    }
                    if #available(iOS 13.4, *) {
                        cell.datePicker.preferredDatePickerStyle = .wheels
                    }
                    let allRow: SwitchRow! = self?.form.rowBy(tag: "All-day")
                    if allRow.value ?? false {
                        cell.datePicker.datePickerMode = .date
                    }
                    else {
                        cell.datePicker.datePickerMode = .dateAndTime
                    }
                }
                cell.detailTextLabel?.textColor = cell.tintColor
                if let timeZoneRow: LabelRow = self?.form.rowBy(tag: "endTimeZone") {
                    timeZoneRow.hidden = false
                    timeZoneRow.evaluateHidden()
                }
                }.onCollapseInlineRow { cell, _, _ in
                    cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
                    if let timeZoneRow: LabelRow = self.form.rowBy(tag: "endTimeZone") {
                        timeZoneRow.hidden = true
                        timeZoneRow.evaluateHidden()
                    }
                }.cellUpdate { cell, row in
                    cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                    cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                    
                }
            
            <<< LabelRow("endTimeZone") { row in
                row.cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                row.cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                row.cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
                row.cell.accessoryType = .disclosureIndicator
                row.title = "Time Zone"
                row.hidden = true
                if active {
                    row.value = schedule.endTimeZone ?? "UTC"
                } else {
                    row.value = TimeZone.current.identifier
                    schedule.endTimeZone = TimeZone.current.identifier
                }
                }.onCellSelection({ _,_ in
                    self.openTimeZoneFinder(startOrEndTimeZone: "endTimeZone")
                }).cellUpdate { cell, row in
                    cell.accessoryType = .disclosureIndicator
                    cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                    cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                }
        
            <<< AlertRow<EventAlert>("Reminder") {
                $0.cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                $0.cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                $0.cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
                $0.title = $0.tag
                $0.selectorTitle = $0.tag
                if self.active && self.schedule.reminder != nil {
                    if let value = self.schedule.reminder {
                        $0.value = EventAlert(rawValue: value)
                    }
                } else {
                    $0.value = .None
                    if let reminder = $0.value?.description {
                        self.schedule.reminder = reminder
                    }
                }
                $0.options = EventAlert.allValues
                }.cellUpdate { cell, row in
                    cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                    cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                    cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
                    
                }.onChange() { [unowned self] row in
                    if let reminder = row.value?.description {
                        self.schedule.reminder = reminder
                        self.scheduleReminder()
                    }
                }

        
        form +++
            MultivaluedSection(multivaluedOptions: [.Insert, .Delete, .Reorder],
                               header: "Checklist",
                               footer: "Add a checklist item") {
                                $0.tag = "checklistfields"
                                $0.addButtonProvider = { section in
                                    return ButtonRow(){
                                        $0.cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                                        $0.title = "Add New Item"
                                        }.cellUpdate { cell, row in
                                            cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                                            cell.textLabel?.textAlignment = .left
                                            
                                    }
                                }
                                $0.multivaluedRowToInsertAt = { index in
                                    return SplitRow<TextRow, CheckRow>(){
                                        $0.rowLeftPercentage = 0.75
                                        $0.rowLeft = TextRow(){
                                            $0.cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                                            $0.cell.textField?.textColor = ThemeManager.currentTheme().generalTitleColor
                                            $0.placeholderColor = ThemeManager.currentTheme().generalSubtitleColor
                                            $0.placeholder = "Item"
                                            }.cellUpdate { cell, row in
                                                cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                                                cell.textField?.textColor = ThemeManager.currentTheme().generalTitleColor
                                                row.placeholderColor = ThemeManager.currentTheme().generalSubtitleColor
                                        }
                                        
                                        $0.rowRight = CheckRow() {
                                            $0.cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                                            $0.cell.tintColor = FalconPalette.defaultBlue
                                            $0.value = false
                                            $0.cell.accessoryType = .checkmark
                                            $0.cell.tintAdjustmentMode = .dimmed
                                            }.cellUpdate { cell, row in
                                                cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                                                cell.tintColor = FalconPalette.defaultBlue
                                                if row.value == false {
                                                    cell.accessoryType = .checkmark
                                                    cell.tintAdjustmentMode = .dimmed
                                                } else {
                                                    cell.tintAdjustmentMode = .automatic
                                                }
                                        }
                                        }.cellUpdate { cell, row in
                                            cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                                    }
                                    
                                }
                                
        }
                            if !checklist.isEmpty, let items = checklist[0].items {
                                for item in items {
                                    var mvs = (form.sectionBy(tag: "checklistfields") as! MultivaluedSection)
                                    mvs.insert(SplitRow<TextRow, CheckRow>() {
                                        $0.rowLeftPercentage = 0.75
                                        $0.rowLeft = TextRow(){
                                            $0.cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                                            $0.cell.textField?.textColor = ThemeManager.currentTheme().generalTitleColor
                                            $0.placeholderColor = ThemeManager.currentTheme().generalSubtitleColor
                                            $0.value = item.key
                                            }.cellUpdate { cell, row in
                                                cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                                                cell.textField?.textColor = ThemeManager.currentTheme().generalTitleColor
                                                row.placeholderColor = ThemeManager.currentTheme().generalSubtitleColor
                                        }
                                        $0.rowRight = CheckRow() {
                                            $0.cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                                            $0.cell.tintColor = FalconPalette.defaultBlue
                                            $0.value = item.value
                                            $0.cell.accessoryType = .checkmark
                                            $0.cell.tintAdjustmentMode = .dimmed
                                            }.cellUpdate { cell, row in
                                                cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                                                cell.tintColor = FalconPalette.defaultBlue
                                                if row.value == false {
                                                    cell.accessoryType = .checkmark
                                                    cell.tintAdjustmentMode = .dimmed
                                                } else {
                                                    cell.tintAdjustmentMode = .automatic
                                                }
                                        }
                                        }.cellUpdate { cell, row in
                                            cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                                    }, at: mvs.count - 1)
                                    
                                }
                            }

    }
    
    @objc fileprivate func rightBarButtonTapped() {
        let mvs = (form.values()["checklistfields"] as! [Any?]).compactMap { $0 }
        if !mvs.isEmpty {
            var checklistDict = [String : Bool]()
            for element in mvs {
                if let value = element as? SplitRowValue<Swift.String, Swift.Bool>, let text = value.left, let state = value.right {
                    checklistDict[text] = state
                }
            }
            if schedule.checklist != nil {
                schedule.checklist![0].items = checklistDict
            } else {
                let check = Checklist(dictionary: ["name" : "ScheduleChecklist" as AnyObject])
                check.items = checklistDict
                schedule.checklist = [check]
            }
        } else {
            schedule.checklist = nil
        }
        
        let valuesDictionary = form.values()
        
        schedule.activityID = scheduleID

        schedule.name = valuesDictionary["Activity Name"] as? String

        if let value = valuesDictionary["Activity Type"] as? String {
            schedule.activityType = value
        }
        
        if let value = valuesDictionary["Description"] as? String {
            schedule.activityDescription = value
        }

        schedule.locationName = self.locationName
        schedule.locationAddress = self.locationAddress

        if let value = valuesDictionary["Transportation"] as? String {
            schedule.transportation = value
        }
        
        schedule.allDay = valuesDictionary["All-day"] as? Bool
        schedule.startDateTime = NSNumber(value: Int((valuesDictionary["Starts"] as! Date).timeIntervalSince1970))
        schedule.endDateTime = NSNumber(value: Int((valuesDictionary["Ends"] as! Date).timeIntervalSince1970))
        
        if let value = valuesDictionary["Reminder"] as? String {
            schedule.reminder = value
        }
        
        let membersIDs = fetchMembersIDs()

        schedule.participantsIDs = membersIDs.0

        delegate?.updateSchedule(schedule: schedule)
        
        if active {
            self.navigationController?.popViewController(animated: true)
        } else {
            self.dismiss(animated: true, completion: nil)
        }
        
    }
    
    func scheduleReminder() {
        let center = UNUserNotificationCenter.current()
        guard schedule.reminder! != "None" else {
            center.removePendingNotificationRequests(withIdentifiers: ["\(scheduleID)_Reminder"])
            return
        }
        let content = UNMutableNotificationContent()
        content.title = "\(String(describing: schedule.name!)) Reminder"
        content.sound = UNNotificationSound.default
        var formattedDate: (String, String) = ("", "")
        if let startDate = startDateTime, let endDate = endDateTime, let allDay = schedule.allDay, let startTimeZone = schedule.startTimeZone, let endTimeZone = schedule.endTimeZone {
            formattedDate = timestampOfActivity(startDate: startDate, endDate: endDate, allDay: allDay, startTimeZone: startTimeZone, endTimeZone: endTimeZone)
            content.subtitle = formattedDate.0
        }
        let reminder = EventAlert(rawValue: schedule.reminder!)
        var reminderDate = startDateTime!.addingTimeInterval(reminder!.timeInterval)
        let timezone = TimeZone(identifier: schedule.startTimeZone ?? "UTC")
        let seconds = TimeInterval(timezone!.secondsFromGMT(for: Date()))
        reminderDate = reminderDate.addingTimeInterval(-seconds)
        let triggerDate = Calendar.current.dateComponents([.year,.month,.day,.hour,.minute,.second,], from: reminderDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate,
                                                    repeats: false)
        let identifier = "\(scheduleID)_Reminder"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        center.add(request, withCompletionHandler: { (error) in
            if let error = error {
                print(error)
            }
        })
    }
    
    @objc fileprivate func openLocationFinder() {
        guard currentReachabilityStatus != .notReachable else {
            basicErrorAlertWith(title: basicErrorTitleForAlert, message: noInternetError, controller: self)
            return
        }
        let destination = LocationFinderTableViewController()
        destination.delegate = self
        self.navigationController?.pushViewController(destination, animated: true)
        
        //        present(destination, animated: true, completion: nil)
    }
    
    fileprivate func openTimeZoneFinder(startOrEndTimeZone: String) {
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
    @objc fileprivate func openParticipantsInviter() {
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
    
    @objc func goToExtras() {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            
        alert.addAction(UIAlertAction(title: "Go to Map", style: .default, handler: { (_) in
            print("User click Edit button")
            self.goToMap()
        }))

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
        destination.sections = [.activity]
        destination.locations = [.activity: schedule]
        navigationController?.pushViewController(destination, animated: true)
        
//        let destination = MapActivityViewController()
//        destination.locationAddress = locationAddress
//        navigationController?.pushViewController(destination, animated: true)
    }
    
    func fetchMembersIDs() -> ([String], [String:AnyObject]) {
        var membersIDs = [String]()
        var membersIDsDictionary = [String:AnyObject]()
        
        guard let currentUserID = Auth.auth().currentUser?.uid else { return (membersIDs, membersIDsDictionary) }
        
        membersIDsDictionary.updateValue(currentUserID as AnyObject, forKey: currentUserID)
        membersIDs.append(currentUserID)
        
        for selectedUser in selectedFalconUsers {
            guard let id = selectedUser.id else { continue }
            membersIDsDictionary.updateValue(id as AnyObject, forKey: id)
            membersIDs.append(id)
        }
        
        return (membersIDs, membersIDsDictionary)
    }
    
    @objc(tableView:accessoryButtonTappedForRowWithIndexPath:) func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
        let latitude = locationAddress[locationName]![0]
        let longitude = locationAddress[locationName]![1]
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
                    self.locationName = "locationName"
                    self.schedule.locationName = "locationName"
                    locationRow.title = "Location"
                    locationRow.updateCell()
                }
            }
            let cancelAlert = UIAlertAction(title: "Cancel", style: .cancel) { (action:UIAlertAction) in
                
            }
            
            alertController.addAction(copyAddress)
            alertController.addAction(changeAddress)
            alertController.addAction(removeAddress)
            alertController.addAction(cancelAlert)
            self.present(alertController, animated: true, completion: nil)
        }
        
    }


}

extension ScheduleViewController: UpdateLocationDelegate {
    func updateLocation(locationName: String, locationAddress: [String : [Double]], zipcode: String, city: String, state: String, country: String) {
        if let locationRow: ButtonRow = form.rowBy(tag: "Location") {
            self.locationAddress[self.locationName] = nil
            if self.schedule.locationAddress != nil {
                self.schedule.locationAddress![self.locationName] = nil
            }
            for (key, value) in locationAddress {
                let newLocationName = key.removeCharacters()
                locationRow.title = newLocationName
                locationRow.updateCell()

                self.locationName = newLocationName
                self.locationAddress[newLocationName] = value
                
                self.schedule.locationName = newLocationName
                if schedule.locationAddress == nil {
                    self.schedule.locationAddress = self.locationAddress
                } else {
                    self.schedule.locationAddress![newLocationName] = value
                }
            }
        }
    }
}

extension ScheduleViewController: UpdateTimeZoneDelegate {
    func updateTimeZone(startOrEndTimeZone: String, timeZone: TimeZone) {
        if startOrEndTimeZone == "startTimeZone" {
            if let timeZoneRow: LabelRow = self.form.rowBy(tag: "startTimeZone"), let startRow: DateTimeInlineRow = self.form.rowBy(tag: "Starts") {
                startRow.dateFormatter?.timeZone = timeZone
                startRow.updateCell()
                startRow.inlineRow?.cell.datePicker.timeZone = timeZone
                startRow.inlineRow?.updateCell()
                timeZoneRow.value = timeZone.identifier
                timeZoneRow.updateCell()
                schedule.startTimeZone = timeZone.identifier
            }
        } else if startOrEndTimeZone == "endTimeZone" {
            if let timeZoneRow: LabelRow = self.form.rowBy(tag: "endTimeZone"), let endRow: DateTimeInlineRow = self.form.rowBy(tag: "Ends") {
                endRow.dateFormatter?.timeZone = timeZone
                endRow.updateCell()
                endRow.inlineRow?.cell.datePicker.timeZone = timeZone
                endRow.inlineRow?.updateCell()
                timeZoneRow.value = timeZone.identifier
                timeZoneRow.updateCell()
                schedule.endTimeZone = timeZone.identifier
            }
        }
    }
}

extension ScheduleViewController: UpdateInvitees {
    func updateInvitees(selectedFalconUsers: [User]) {
        if let _: ButtonRow = form.rowBy(tag: "Participants") {
            if !selectedFalconUsers.isEmpty {
                self.selectedFalconUsers = selectedFalconUsers
//                self.userNamesString = "\(self.selectedFalconUsers.count + 1) participants"
//                inviteesRow.title = self.userNamesString
//                inviteesRow.updateCell()
            } else {
                self.selectedFalconUsers = selectedFalconUsers
//                inviteesRow.title = "Participants"
//                inviteesRow.updateCell()
            }
        }
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
