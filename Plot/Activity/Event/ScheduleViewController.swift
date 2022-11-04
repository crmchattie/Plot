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
import CodableFirebase


protocol UpdateActivityDelegate: AnyObject {
    func updateActivity(activity: Activity)
}

class ScheduleViewController: FormViewController {
    
    weak var delegate : UpdateActivityDelegate?
    
    var schedule: Activity!
    var event: Activity!
    
    var users = [User]()
    var filteredUsers = [User]()
    var selectedFalconUsers = [User]()
    var checklist: Checklist!
    
    var scheduleID = String()
    
    var movingBackwards = true
    
    fileprivate var active = false
    
    init() {
        super.init(style: .insetGrouped)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
        
    override func viewDidLoad() {
        super.viewDidLoad()        
        if schedule != nil {
            title = "Sub-Event"
            active = true
            if schedule.activityID != nil {
                scheduleID = schedule.activityID!
            } else {
                schedule.activityID = UUID().uuidString
            }
            if let participants = schedule.participantsIDs {
                for ID in participants {
                    // users equals ACTIVITY selected falcon users
                    if let user = users.first(where: {$0.id == ID}) {
                        selectedFalconUsers.append(user)
                    }
                }
            }
            setupLists()
            schedule.isSchedule = true
        } else {
            title = "New Sub-Event"
            if let event = event {
                schedule = EventBuilder.createSchedule(event: event)
                scheduleID = schedule.activityID ?? UUID().uuidString
            } else {
                scheduleID = UUID().uuidString
                schedule = Activity(dictionary: ["activityID": scheduleID as AnyObject])
                schedule.isSchedule = true
                schedule.admin = Auth.auth().currentUser?.uid
            }
        }
        
        setupMainView()
        initializeForm()
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if movingBackwards && navigationController?.visibleViewController is ScheduleListViewController {
            delegate?.updateActivity(activity: schedule)
        }
    }
    
    fileprivate func setupMainView() {
        
        view.backgroundColor = .systemGroupedBackground
        tableView.indicatorStyle = .default
        tableView.sectionIndexBackgroundColor = view.backgroundColor
        tableView.backgroundColor = view.backgroundColor
        tableView.separatorStyle = UITableViewCell.SeparatorStyle.none
        
        extendedLayoutIncludesOpaqueBars = true
                
        if !active {
            let plusBarButton =  UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(rightBarButtonTapped))
            navigationItem.rightBarButtonItem = plusBarButton
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
        if navigationItem.leftBarButtonItem != nil {
            navigationItem.leftBarButtonItem?.action = #selector(cancel)
        }

        navigationOptions = .Disabled
        
    }
    
    @IBAction func cancel(_ sender: AnyObject) {
        self.dismiss(animated: true, completion: nil)
    }
    
    fileprivate func initializeForm() {
        
        form +++
            Section()
        
            <<< TextRow("Name") {
                $0.cell.backgroundColor = .secondarySystemGroupedBackground
                $0.cell.textField?.textColor = .label
                $0.placeholderColor = .secondaryLabel
                $0.placeholder = $0.tag
                if let schedule = schedule, let name = schedule.name {
                    $0.value = name
                    self.navigationItem.rightBarButtonItem?.isEnabled = true
                } else {
//                    $0.cell.textField.becomeFirstResponder()
                    self.navigationItem.rightBarButtonItem?.isEnabled = false
                }
                }.onChange() { [unowned self] row in
                    if row.value == nil {
                        self.navigationItem.rightBarButtonItem?.isEnabled = false
                    } else {
                        self.navigationItem.rightBarButtonItem?.isEnabled = true
                    }
                }.cellUpdate { cell, row in
                    cell.backgroundColor = .secondarySystemGroupedBackground
                    cell.textField?.textColor = .label
                    row.placeholderColor = .secondaryLabel
            }
            
//            <<< TextRow("Type") {
//                $0.cell.backgroundColor = .secondarySystemGroupedBackground
//                $0.cell.textField?.textColor = .label
//                $0.placeholderColor = .secondaryLabel
//                $0.placeholder = $0.tag
//                if let schedule = schedule, schedule.activityType != nil, schedule.activityType != "nothing" {
//                    $0.value = self.schedule.activityType
//                }
//                }.cellUpdate { cell, row in
//                    cell.backgroundColor = .secondarySystemGroupedBackground
//                    cell.textField?.textColor = .label
//                    row.placeholderColor = .secondaryLabel
//            }
            
            <<< TextAreaRow("Description") {
                $0.cell.backgroundColor = .secondarySystemGroupedBackground
                $0.cell.textView?.backgroundColor = .secondarySystemGroupedBackground
                $0.cell.textView?.textColor = .label
                $0.cell.placeholderLabel?.textColor = .secondaryLabel
                $0.placeholder = $0.tag
                if let schedule = schedule, schedule.activityDescription != nil, schedule.activityDescription != "nothing" {
                    $0.value = self.schedule.activityDescription
                }
                }.cellUpdate({ (cell, row) in
                    cell.backgroundColor = .secondarySystemGroupedBackground
                    cell.textView?.backgroundColor = .secondarySystemGroupedBackground
                    cell.textView?.textColor = .label
                    cell.placeholderLabel?.textColor = .secondaryLabel
                })
            
        <<< LabelRow("Location") { row in
            row.cell.backgroundColor = .secondarySystemGroupedBackground
            row.cell.textLabel?.textColor = .label
            row.cell.accessoryType = .disclosureIndicator
            row.cell.selectionStyle = .default
            if let schedule = schedule, let localName = schedule.locationName, localName != "locationName" {
                row.cell.textLabel?.textColor = .label
                row.cell.accessoryType = .detailDisclosureButton
                row.title = localName
            } else {
                row.cell.textLabel?.textColor = .secondaryLabel
                row.cell.accessoryType = .disclosureIndicator
                row.title = row.tag
            }
            }.onCellSelection({ _,_ in
                self.openLocationFinder()
            }).cellUpdate { cell, row in
                cell.backgroundColor = .secondarySystemGroupedBackground
                cell.detailTextLabel?.textColor = .secondaryLabel
                cell.textLabel?.textAlignment = .left
                if row.title == "Location" {
                    cell.textLabel?.textColor = .secondaryLabel
                    cell.accessoryType = .disclosureIndicator
                } else if let value = row.title, !value.isEmpty {
                    cell.textLabel?.textColor = .label
                    cell.accessoryType = .detailDisclosureButton
                } else {
                    cell.textLabel?.textColor = .secondaryLabel
                    cell.accessoryType = .disclosureIndicator
                    cell.textLabel?.text = "Location"
                }
            }
            
//            <<< LabelRow("Participants") { row in
//                row.cell.backgroundColor = .secondarySystemGroupedBackground
//                row.cell.textLabel?.textColor = .label
//                row.cell.detailTextLabel?.textColor = .secondaryLabel
//                row.cell.accessoryType = .disclosureIndicator
//                row.cell.textLabel?.textAlignment = .left
//                row.cell.selectionStyle = .default
//                row.title = row.tag
//                if active {
//                    row.value = String(self.selectedFalconUsers.count)
//                } else {
//                    row.value = String(1)
//                }
//            }.onCellSelection({ _, row in
//                self.openParticipantsInviter()
//            }).cellUpdate { cell, row in
//                cell.accessoryType = .disclosureIndicator
//                cell.backgroundColor = .secondarySystemGroupedBackground
//                cell.textLabel?.textColor = .label
//                cell.detailTextLabel?.textColor = .secondaryLabel
//                cell.textLabel?.textAlignment = .left
//            }
            
            <<< SwitchRow("All-day") {
                $0.cell.backgroundColor = .secondarySystemGroupedBackground
                $0.cell.textLabel?.textColor = .label
                $0.title = $0.tag
                if let schedule = schedule, let allDay = schedule.allDay {
                    $0.value = allDay
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
                    cell.backgroundColor = .secondarySystemGroupedBackground
                    cell.textLabel?.textColor = .label
                    
            }

            
            <<< DateTimeInlineRow("Starts") {
                $0.cell.backgroundColor = .secondarySystemGroupedBackground
                $0.cell.textLabel?.textColor = .label
                $0.cell.detailTextLabel?.textColor = .secondaryLabel
                $0.title = $0.tag
                $0.minuteInterval = 5
                $0.dateFormatter?.dateStyle = .medium
                $0.dateFormatter?.timeStyle = .short
                if let schedule = schedule {
                    if let timeZone = schedule.startTimeZone {
                        $0.dateFormatter?.timeZone = TimeZone(identifier: timeZone)
                    }
                    $0.value = Date(timeIntervalSince1970: schedule.startDateTime as! TimeInterval)
                    if self.schedule.allDay == true {
                        $0.dateFormatter?.timeStyle = .none
                    }
                    else {
                        $0.dateFormatter?.timeStyle = .short
                    }
                    $0.updateCell()
                } else {
                    let original = Date()
                    let rounded = Date(timeIntervalSinceReferenceDate:
                    (original.timeIntervalSinceReferenceDate / 300.0).rounded(.toNearestOrEven) * 300.0)
                    $0.value = rounded
                    self.schedule.startDateTime = NSNumber(value: Int(($0.value!).timeIntervalSince1970))
                }
                }.onChange { [weak self] row in
                    let endRow: DateTimeInlineRow! = self?.form.rowBy(tag: "Ends")
                    if row.value?.compare(endRow.value!) == .orderedDescending {
                        endRow.value = Date(timeInterval: 0, since: row.value!)
                        endRow.updateCell()
                    }
                    self!.schedule.startDateTime = NSNumber(value: Int((row.value!).timeIntervalSince1970))
                    if self!.active {
                        self!.scheduleReminder()
                    }
                }.onExpandInlineRow { [weak self] cell, row, inlineRow in
                    inlineRow.cellUpdate { (cell, row) in
                        row.cell.backgroundColor = .secondarySystemGroupedBackground
                        row.cell.tintColor = .secondarySystemGroupedBackground
                        if #available(iOS 14.0, *) {
                            cell.datePicker.preferredDatePickerStyle = .inline
                            cell.datePicker.tintColor = .systemBlue
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
                        }
                    }
                    cell.detailTextLabel?.textColor = cell.tintColor
                    if let timeZoneRow: LabelRow = self?.form.rowBy(tag: "startTimeZone") {
                        timeZoneRow.hidden = false
                        timeZoneRow.evaluateHidden()
                    }
                }.onCollapseInlineRow { cell, _, _ in
                    cell.detailTextLabel?.textColor = .secondaryLabel
                    if let timeZoneRow: LabelRow = self.form.rowBy(tag: "startTimeZone") {
                        timeZoneRow.hidden = true
                        timeZoneRow.evaluateHidden()
                    }
                }.cellUpdate { cell, row in
                    cell.backgroundColor = .secondarySystemGroupedBackground
                    cell.textLabel?.textColor = .label
                }
            
            <<< LabelRow("startTimeZone") { row in
                row.cell.backgroundColor = .secondarySystemGroupedBackground
                row.cell.textLabel?.textColor = .label
                row.cell.detailTextLabel?.textColor = .secondaryLabel
                row.cell.accessoryType = .disclosureIndicator
                row.cell.textLabel?.textAlignment = .left
                row.cell.selectionStyle = .default
                row.title = "Time Zone"
                row.hidden = true
                if let schedule = schedule, let startTimeZone = schedule.startTimeZone {
                    row.value = startTimeZone
                }
                }.onCellSelection({ _,_ in
                    self.openTimeZoneFinder(startOrEndTimeZone: "startTimeZone")
                }).cellUpdate { cell, row in
                    cell.accessoryType = .disclosureIndicator
                    cell.backgroundColor = .secondarySystemGroupedBackground
                    cell.textLabel?.textColor = .label
                    cell.textLabel?.textAlignment = .left
                }
            
            <<< DateTimeInlineRow("Ends") {
                $0.cell.backgroundColor = .secondarySystemGroupedBackground
                $0.cell.textLabel?.textColor = .label
                $0.cell.detailTextLabel?.textColor = .secondaryLabel
                $0.title = $0.tag
                $0.minuteInterval = 5
                $0.dateFormatter?.dateStyle = .medium
                $0.dateFormatter?.timeStyle = .short
                if let schedule = schedule {
                    if let timeZone = schedule.endTimeZone {
                        $0.dateFormatter?.timeZone = TimeZone(identifier: timeZone)
                    }
                    $0.value = Date(timeIntervalSince1970: schedule.endDateTime as! TimeInterval)
                    if self.schedule.allDay == true {
                        $0.dateFormatter?.timeStyle = .none
                    }
                    else {
                        $0.dateFormatter?.timeStyle = .short
                    }
                    $0.updateCell()
                } else {
                    let original = Date()
                    let rounded = Date(timeIntervalSinceReferenceDate:
                    (original.timeIntervalSinceReferenceDate / 300.0).rounded(.toNearestOrEven) * 300.0)
                    $0.value = rounded
                    self.schedule.endDateTime = NSNumber(value: Int(($0.value!).timeIntervalSince1970))
                }
                }.onChange { [weak self] row in
                    let startRow: DateTimeInlineRow! = self?.form.rowBy(tag: "Starts")
                    if row.value?.compare(startRow.value!) == .orderedAscending {
                        startRow.value = Date(timeInterval: 0, since: row.value!)
                        startRow.updateCell()
                    }
                    self!.schedule.endDateTime = NSNumber(value: Int((row.value!).timeIntervalSince1970))
                }.onExpandInlineRow { [weak self] cell, row, inlineRow in
                inlineRow.cellUpdate { (cell, row) in
                    row.cell.backgroundColor = .secondarySystemGroupedBackground
                    row.cell.tintColor = .secondarySystemGroupedBackground
                    if let endTimeZone = self?.schedule.endTimeZone {
                        cell.datePicker.timeZone = TimeZone(identifier: endTimeZone)
                    }
                    if #available(iOS 14.0, *) {
                        cell.datePicker.preferredDatePickerStyle = .inline
                        cell.datePicker.tintColor = .systemBlue
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
                    cell.detailTextLabel?.textColor = .secondaryLabel
                    if let timeZoneRow: LabelRow = self.form.rowBy(tag: "endTimeZone") {
                        timeZoneRow.hidden = true
                        timeZoneRow.evaluateHidden()
                    }
                }.cellUpdate { cell, row in
                    cell.backgroundColor = .secondarySystemGroupedBackground
                    cell.textLabel?.textColor = .label
                    
                }
            
            <<< LabelRow("endTimeZone") { row in
                row.cell.backgroundColor = .secondarySystemGroupedBackground
                row.cell.textLabel?.textColor = .label
                row.cell.detailTextLabel?.textColor = .secondaryLabel
                row.cell.accessoryType = .disclosureIndicator
                row.cell.textLabel?.textAlignment = .left
                row.cell.selectionStyle = .default
                row.title = "Time Zone"
                row.hidden = true
                if let schedule = schedule, let endTimeZone = schedule.endTimeZone {
                    row.value = endTimeZone
                }
                }.onCellSelection({ _,_ in
                    self.openTimeZoneFinder(startOrEndTimeZone: "endTimeZone")
                }).cellUpdate { cell, row in
                    cell.accessoryType = .disclosureIndicator
                    cell.backgroundColor = .secondarySystemGroupedBackground
                    cell.textLabel?.textColor = .label
                    cell.textLabel?.textAlignment = .left
                }
        
            <<< PushRow<EventAlert>("Reminder") { row in
                row.cell.backgroundColor = .secondarySystemGroupedBackground
                row.cell.textLabel?.textColor = .label
                row.cell.detailTextLabel?.textColor = .secondaryLabel
                row.title = row.tag
                if let schedule = schedule, let value = schedule.reminder {
                    row.value = EventAlert(rawValue: value)
                } else {
                    row.value = EventAlert.None
                    if let reminder = row.value?.description {
                        self.schedule.reminder = reminder
                    }
                }
                row.options = EventAlert.allCases
            }.onPresent { from, to in
                to.title = "Reminder"
                to.extendedLayoutIncludesOpaqueBars = true
                to.tableViewStyle = .insetGrouped
                to.selectableRowCellUpdate = { cell, row in
                    to.navigationController?.navigationBar.backgroundColor = .systemGroupedBackground
                    to.tableView.backgroundColor = .systemGroupedBackground
                    to.tableView.separatorStyle = .none
                    cell.backgroundColor = .secondarySystemGroupedBackground
                    cell.textLabel?.textColor = .label
                    cell.detailTextLabel?.textColor = .secondaryLabel
                }
            }.cellUpdate { cell, row in
                cell.backgroundColor = .secondarySystemGroupedBackground
                cell.textLabel?.textColor = .label
                cell.detailTextLabel?.textColor = .secondaryLabel
            }.onChange() { [unowned self] row in
                if let reminder = row.value?.description {
                    self.schedule.reminder = reminder
                    if self.active {
                        self.scheduleReminder()
                    }
                }
            }
        
        
            <<< LabelRow("Category") { row in
                row.cell.backgroundColor = .secondarySystemGroupedBackground
                row.cell.textLabel?.textColor = .label
                row.cell.detailTextLabel?.textColor = .secondaryLabel
                row.cell.accessoryType = .disclosureIndicator
                row.cell.selectionStyle = .default
                row.title = row.tag
                if let schedule = schedule, schedule.category != nil {
                    row.value = schedule.category
                } else {
                    row.value = "Uncategorized"
                }
            }.onCellSelection({ _, row in
                self.openLevel(value: row.value ?? "Uncategorized", level: "Category")
            }).cellUpdate { cell, row in
                cell.accessoryType = .disclosureIndicator
                cell.backgroundColor = .secondarySystemGroupedBackground
                cell.textLabel?.textColor = .label
                cell.detailTextLabel?.textColor = .secondaryLabel
                cell.textLabel?.textAlignment = .left
            }

        
        form +++
            MultivaluedSection(multivaluedOptions: [.Insert, .Delete, .Reorder],
                               header: "Checklist",
                               footer: "Add a checklist item") {
                                $0.tag = "checklistfields"
                                $0.addButtonProvider = { section in
                                    return ButtonRow(){
                                        $0.cell.backgroundColor = .secondarySystemGroupedBackground
                                        $0.title = "Add New Item"
                                        }.cellUpdate { cell, row in
                                            cell.backgroundColor = .secondarySystemGroupedBackground
                                            cell.textLabel?.textAlignment = .left
                                            
                                    }
                                }
                                $0.multivaluedRowToInsertAt = { index in
                                    return SplitRow<TextRow, CheckRow>(){
                                        $0.rowLeftPercentage = 0.75
                                        $0.rowLeft = TextRow(){
                                            $0.cell.backgroundColor = .secondarySystemGroupedBackground
                                            $0.cell.textField?.textColor = .label
                                            $0.placeholderColor = .secondaryLabel
                                            $0.placeholder = "Item"
                                            }.cellUpdate { cell, row in
                                                cell.backgroundColor = .secondarySystemGroupedBackground
                                                cell.textField?.textColor = .label
                                                row.placeholderColor = .secondaryLabel
                                        }
                                        
                                        $0.rowRight = CheckRow() {
                                            $0.cell.backgroundColor = .secondarySystemGroupedBackground
                                            $0.cell.tintColor = FalconPalette.defaultBlue
                                            $0.value = false
                                            $0.cell.accessoryType = .checkmark
                                            $0.cell.tintAdjustmentMode = .dimmed
                                            }.cellUpdate { cell, row in
                                                cell.backgroundColor = .secondarySystemGroupedBackground
                                                cell.tintColor = FalconPalette.defaultBlue
                                                cell.accessoryType = .checkmark
                                                if row.value == false {
                                                    cell.tintAdjustmentMode = .dimmed
                                                } else {
                                                    cell.tintAdjustmentMode = .automatic
                                                }
                                        }
                                        }.cellUpdate { cell, row in
                                            cell.backgroundColor = .secondarySystemGroupedBackground
                                    }
                                    
                                }
                                
        }
    }
    
    @objc fileprivate func rightBarButtonTapped() {
        let mvs = (form.values()["checklistfields"] as! [Any?]).compactMap { $0 }
        if !mvs.isEmpty {
            var checklistDict = [String : Bool]()
            for element in mvs {
                if let value = element as? SplitRowValue<Swift.String, Swift.Bool>, let text = value.left, let state = value.right {
                    let newText = text.removeCharacters()
                    checklistDict[newText] = state
                }
            }
            
            if schedule.checklistIDs == nil, let currentUserID = Auth.auth().currentUser?.uid {
                let ID = Database.database().reference().child(userChecklistsEntity).child(currentUserID).childByAutoId().key ?? ""
                checklist = Checklist(dictionary: ["ID": ID as AnyObject])
                checklist.name = "CheckList"
                checklist.createdDate = Date()
                checklist.activityID = schedule.activityID
                checklist.items = checklistDict
                schedule.checklistIDs = [checklist.ID ?? ""]
                
                let createChecklist = ChecklistActions(checklist: checklist, active: true, selectedFalconUsers: [])
                createChecklist.createNewChecklist()
            } else {
                checklist.items = checklistDict
                let createChecklist = ChecklistActions(checklist: checklist, active: true, selectedFalconUsers: [])
                createChecklist.createNewChecklist()
            }
        } else {
            schedule.checklistIDs = []
        }
        
        let valuesDictionary = form.values()
        
        schedule.activityID = scheduleID

        schedule.name = valuesDictionary["Name"] as? String

        if let value = valuesDictionary["Type"] as? String {
            schedule.activityType = value
        }
        
        if let value = valuesDictionary["Description"] as? String {
            schedule.activityDescription = value
        }

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
        
        let createActivity = ActivityActions(activity: schedule, active: false, selectedFalconUsers: [])
        createActivity.createSubActivity()
        
        movingBackwards = false
        delegate?.updateActivity(activity: schedule)
        
        if navigationItem.leftBarButtonItem != nil {
            self.dismiss(animated: true, completion: nil)
        } else {
            self.navigationController?.popViewController(animated: true)
        }
    }
    
    func setupLists() {
        let dispatchGroup = DispatchGroup()
        if schedule.checklistIDs != nil {
            for checklistID in schedule.checklistIDs! {
                dispatchGroup.enter()
                let checklistDataReference = Database.database().reference().child(checklistsEntity).child(checklistID)
                checklistDataReference.observeSingleEvent(of: .value, with: { (snapshot) in
                    if snapshot.exists(), let checklistSnapshotValue = snapshot.value {
                        if let checklist = try? FirebaseDecoder().decode(Checklist.self, from: checklistSnapshotValue) {
                            self.checklist = checklist
                        }
                    }
                    dispatchGroup.leave()
                })
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            self.listRow()
        }
    }
    
    func listRow() {
        if let checklist = checklist, let items = checklist.items  {
            let sortedItems = items.sorted { item1, item2 in
                if item1.value == item2.value {
                    return item1.key < item2.key
                }
                return item1.value && !item2.value
            }
            for item in sortedItems {
                var mvs = (form.sectionBy(tag: "checklistfields") as! MultivaluedSection)
                mvs.insert(SplitRow<TextRow, CheckRow>() {
                    $0.rowLeftPercentage = 0.75
                    $0.rowLeft = TextRow(){
                        $0.cell.backgroundColor = .secondarySystemGroupedBackground
                        $0.cell.textField?.textColor = .label
                        $0.placeholderColor = .secondaryLabel
                        $0.value = item.key
                        }.cellUpdate { cell, row in
                            cell.backgroundColor = .secondarySystemGroupedBackground
                            cell.textField?.textColor = .label
                            row.placeholderColor = .secondaryLabel
                    }
                    $0.rowRight = CheckRow() {
                        $0.cell.backgroundColor = .secondarySystemGroupedBackground
                        $0.cell.tintColor = FalconPalette.defaultBlue
                        $0.value = item.value
                        $0.cell.accessoryType = .checkmark
                        if item.value {
                            $0.cell.tintAdjustmentMode = .automatic
                        } else {
                            $0.cell.tintAdjustmentMode = .dimmed
                        }
                        }.cellUpdate { cell, row in
                            cell.backgroundColor = .secondarySystemGroupedBackground
                            cell.tintColor = FalconPalette.defaultBlue
                            cell.accessoryType = .checkmark
                            if row.value == false {
                                cell.tintAdjustmentMode = .dimmed
                            } else {
                                cell.tintAdjustmentMode = .automatic
                            }
                    }
                    }.cellUpdate { cell, row in
                        cell.backgroundColor = .secondarySystemGroupedBackground
                }, at: mvs.count - 1)
                
            }
        }
    }
    
    func scheduleReminder() {
        guard let schedule = schedule, let scheduleReminder = schedule.reminder, let startDate = schedule.startDate, let endDate = schedule.endDate, let allDay = schedule.allDay else {
            return
        }
        let center = UNUserNotificationCenter.current()
        guard scheduleReminder != "None" else {
            center.removePendingNotificationRequests(withIdentifiers: ["\(scheduleID)_Reminder"])
            return
        }
        let content = UNMutableNotificationContent()
        content.title = "\(String(describing: schedule.name!)) Reminder"
        content.sound = UNNotificationSound.default
        var formattedDate: (String, String) = ("", "")
        formattedDate = timestampOfEvent(startDate: startDate, endDate: endDate, allDay: allDay, startTimeZone: schedule.startTimeZone, endTimeZone: schedule.endTimeZone)
        content.subtitle = formattedDate.0
        if let reminder = EventAlert(rawValue: scheduleReminder) {
            let reminderDate = startDate.addingTimeInterval(reminder.timeInterval)
            var calendar = Calendar.current
            if let timeZone = schedule.startTimeZone {
                calendar.timeZone = TimeZone(identifier: timeZone)!
            }
            let triggerDate = calendar.dateComponents([.year,.month,.day,.hour,.minute,.second,], from: reminderDate)
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
    }
    
    @objc fileprivate func openLocationFinder() {
        guard currentReachabilityStatus != .notReachable else {
            basicErrorAlertWithClose(title: basicErrorTitleForAlert, message: noInternetError, controller: self)
            return
        }
        let destination = LocationFinderTableViewController()
        destination.delegate = self
        self.navigationController?.pushViewController(destination, animated: true)
        
        //        present(destination, animated: true, completion: nil)
    }
    
    fileprivate func openTimeZoneFinder(startOrEndTimeZone: String) {
        guard currentReachabilityStatus != .notReachable else {
            basicErrorAlertWithClose(title: basicErrorTitleForAlert, message: noInternetError, controller: self)
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
        destination.ownerID = schedule.admin
        destination.users = uniqueUsers
        destination.filteredUsers = uniqueUsers
        if !selectedFalconUsers.isEmpty {
            destination.priorSelectedUsers = selectedFalconUsers
        }
        destination.delegate = self
        self.navigationController?.pushViewController(destination, animated: true)
    }
    
    func openLevel(value: String, level: String) {
        let destination = ActivityLevelViewController()
        destination.delegate = self
        destination.value = value
        destination.level = level
        self.navigationController?.pushViewController(destination, animated: true)
    }
    
    @objc func goToExtras() {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            
        if let name = schedule.name, let locationName = schedule.locationName, locationName != "locationName", let locationAddress = schedule.locationAddress, let longlat = locationAddress[locationName] {
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
        destination.locations = [.event:  [schedule]]
        navigationController?.pushViewController(destination, animated: true)
        
    }
    
    func fetchMembersIDs() -> ([String], [String:AnyObject]) {
        var membersIDs = [String]()
        var membersIDsDictionary = [String:AnyObject]()
        
        guard let currentUserID = Auth.auth().currentUser?.uid else { return (membersIDs.sorted(), membersIDsDictionary) }
        
        membersIDsDictionary.updateValue(currentUserID as AnyObject, forKey: currentUserID)
        membersIDs.append(currentUserID)
        
        for selectedUser in selectedFalconUsers {
            guard let id = selectedUser.id else { continue }
            membersIDsDictionary.updateValue(id as AnyObject, forKey: id)
            membersIDs.append(id)
        }
        
        return (membersIDs.sorted(), membersIDsDictionary)
    }
    
    @objc(tableView:accessoryButtonTappedForRowWithIndexPath:) func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
        guard let row: LabelRow = form.rowBy(tag: "Location"), indexPath == row.indexPath, let name = schedule.name, let locationName = schedule.locationName, let locationAddress = schedule.locationAddress, let longlat = locationAddress[locationName] else {
            return
        }
        let latitude = longlat[0]
        let longitude = longlat[1]
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
            
            let alertController = UIAlertController(title: locationName, message: addressString, preferredStyle: .alert)
            let routeAddress = UIAlertAction(title: "Route Address", style: .default) { (action:UIAlertAction) in
                OpenMapDirections.present(in: self, name: name, latitude: latitude, longitude: longitude)
            }
            let mapAddress = UIAlertAction(title: "Map Address", style: .default) { (action:UIAlertAction) in
                self.goToMap()
            }
            let changeAddress = UIAlertAction(title: "Change Address", style: .default) { (action:UIAlertAction) in
                self.openLocationFinder()
            }
            let removeAddress = UIAlertAction(title: "Remove Address", style: .default) { (action:UIAlertAction) in
                if let locationRow: LabelRow = self.form.rowBy(tag: "Location") {
                    self.schedule.locationAddress = nil
                    self.schedule.locationName = nil
                    locationRow.title = "Location"
                    locationRow.updateCell()
                }
            }
            let cancelAlert = UIAlertAction(title: "Cancel", style: .cancel) { (action:UIAlertAction) in
                
            }
            alertController.addAction(routeAddress)
            alertController.addAction(mapAddress)
            alertController.addAction(changeAddress)
            alertController.addAction(removeAddress)
            alertController.addAction(cancelAlert)
            self.present(alertController, animated: true, completion: nil)
        }
        
    }


}

extension ScheduleViewController: UpdateLocationDelegate {
    func updateLocation(locationName: String, locationAddress: [String : [Double]], zipcode: String, city: String, state: String, country: String) {
        if let locationRow: LabelRow = form.rowBy(tag: "Location") {
            schedule.locationName = nil
            schedule.locationAddress = nil
            for (key, _) in locationAddress {
                let newLocationName = key.removeCharacters()
                locationRow.title = newLocationName
                locationRow.updateCell()
                
                schedule.locationName = newLocationName
                schedule.locationAddress = locationAddress
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
        if let inviteesRow: LabelRow = form.rowBy(tag: "Participants") {
            self.selectedFalconUsers = selectedFalconUsers
            inviteesRow.value = String(self.selectedFalconUsers.count + 1)
            inviteesRow.updateCell()
        }
    }
}

extension ScheduleViewController: UpdateActivityLevelDelegate {
    func update(value: String, level: String) {
        if let row: LabelRow = form.rowBy(tag: level) {
            row.value = value
            row.updateCell()
            if level == "Category" {
                self.schedule.category = value
            } else if level == "Subcategory" {
                self.schedule.activityType = value
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
