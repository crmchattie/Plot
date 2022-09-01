//
//  SubtaskViewController.swift
//  Plot
//
//  Created by Cory McHattie on 8/20/22.
//  Copyright © 2022 Immature Creations. All rights reserved.
//

import UIKit
import Eureka
import SplitRow
import Firebase
import Contacts
import EventKit
import CodableFirebase

protocol UpdateTaskDelegate: AnyObject {
    func updateTask(task: Activity)
}

class SubtaskViewController: FormViewController {
    
    weak var delegate : UpdateTaskDelegate?
    
    var subtask: Activity!
    
    var users = [User]()
    var filteredUsers = [User]()
    var selectedFalconUsers = [User]()
    var checklist: Checklist!
    var userNames : [String] = []
    var userNamesString: String = ""
    var startDateTime: Date?
    var endDateTime: Date?
    
    var subtaskID = String()
    
    fileprivate var active: Bool = false
    
    var movingBackwards: Bool = true
    
    init() {
        super.init(style: .insetGrouped)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
        
    override func viewDidLoad() {
        super.viewDidLoad()
        if subtask != nil {
            title = "Sub-Task"
            active = true
            if subtask.activityID != nil {
                subtaskID = subtask.activityID!
            } else {
                subtask.activityID = UUID().uuidString
            }
            userNamesString = "Participants"
            if let participants = subtask.participantsIDs {
                for ID in participants {
                    // users equals ACTIVITY selected falcon users
                    if let user = users.first(where: {$0.id == ID}) {
                        selectedFalconUsers.append(user)
                    }
                }
            }
            setupLists()
            subtask.isSubtask = true
        } else {
            title = "New Sub-Task"
            subtaskID = UUID().uuidString
            subtask = Activity(dictionary: ["activityID": subtaskID as AnyObject])
            subtask.isSubtask = true
            subtask.admin = Auth.auth().currentUser?.uid
        }
        
        setupMainView()
        initializeForm()
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if movingBackwards && navigationController?.visibleViewController is SubtaskListViewController {
            delegate?.updateTask(task: subtask)
        }
    }

    
    fileprivate func setupMainView() {
        
        view.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
        tableView.indicatorStyle = ThemeManager.currentTheme().scrollBarStyle
        tableView.sectionIndexBackgroundColor = view.backgroundColor
        tableView.backgroundColor = view.backgroundColor
        tableView.separatorStyle = UITableViewCell.SeparatorStyle.none
        
        extendedLayoutIncludesOpaqueBars = true
                
        if !active {
            let plusBarButton =  UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(rightBarButtonTapped))
            navigationItem.rightBarButtonItem = plusBarButton
            if navigationItem.leftBarButtonItem != nil {
                navigationItem.leftBarButtonItem?.action = #selector(cancel)
            }
        } else {
            let plusBarButton =  UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(rightBarButtonTapped))
            navigationItem.rightBarButtonItem = plusBarButton
            navigationItem.rightBarButtonItem?.isEnabled = true
        }
        
    }
    
    @IBAction func cancel(_ sender: AnyObject) {
        self.dismiss(animated: true, completion: nil)
    }
    
    fileprivate func initializeForm() {
        
        form +++
            Section()
        
            <<< TextRow("Name") {
                $0.cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                $0.cell.textField?.textColor = ThemeManager.currentTheme().generalTitleColor
                $0.placeholderColor = ThemeManager.currentTheme().generalSubtitleColor
                $0.placeholder = $0.tag
                if self.active {
                    $0.value = self.subtask.name
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
                    cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                    cell.textField?.textColor = ThemeManager.currentTheme().generalTitleColor
                    row.placeholderColor = ThemeManager.currentTheme().generalSubtitleColor
            }
            
//            <<< TextRow("Type") {
//                $0.cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
//                $0.cell.textField?.textColor = ThemeManager.currentTheme().generalTitleColor
//                $0.placeholderColor = ThemeManager.currentTheme().generalSubtitleColor
//                $0.placeholder = $0.tag
//                if self.active && self.subtask.activityType != nil && self.subtask.activityType != "nothing" {
//                    $0.value = self.subtask.activityType
//                }
//                }.cellUpdate { cell, row in
//                    cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
//                    cell.textField?.textColor = ThemeManager.currentTheme().generalTitleColor
//                    row.placeholderColor = ThemeManager.currentTheme().generalSubtitleColor
//            }
            
            <<< TextAreaRow("Description") {
                $0.cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                $0.cell.textView?.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                $0.cell.textView?.textColor = ThemeManager.currentTheme().generalTitleColor
                $0.cell.placeholderLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
                $0.placeholder = $0.tag
                if self.active && self.subtask.activityDescription != nil && self.subtask.activityDescription != "nothing" {
                    $0.value = self.subtask.activityDescription
                }
                }.cellUpdate({ (cell, row) in
                    cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                    cell.textView?.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                    cell.textView?.textColor = ThemeManager.currentTheme().generalTitleColor
                    cell.placeholderLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
                })
            
//            <<< ButtonRow("Participants") { row in
//                row.cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
//                row.cell.textLabel?.textAlignment = .left
//                row.cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
//                row.cell.accessoryType = .disclosureIndicator
//                row.title = row.tag
//                }.onCellSelection({ _,_ in
//                    self.openParticipantsInviter()
//                }).cellUpdate { cell, row in
//                    cell.accessoryType = .disclosureIndicator
//                    cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
//                    cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
//                    cell.textLabel?.textAlignment = .left
//            }
        
            <<< CheckRow("Completed") {
                $0.cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                $0.cell.tintColor = FalconPalette.defaultBlue
                $0.cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                $0.cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
                $0.cell.accessoryType = .checkmark
                $0.title = $0.tag
                $0.value = subtask.isCompleted ?? false
                if $0.value ?? false {
                    $0.cell.tintAdjustmentMode = .automatic
                } else {
                    $0.cell.tintAdjustmentMode = .dimmed
                }
            }.cellUpdate { cell, row in
                cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                cell.tintColor = FalconPalette.defaultBlue
                cell.accessoryType = .checkmark
                if row.value == false {
                    cell.tintAdjustmentMode = .dimmed
                } else {
                    cell.tintAdjustmentMode = .automatic
                }
            }.onChange { row in
                self.subtask.isCompleted = row.value
                if row.value ?? false, let completedRow: DateTimeInlineRow = self.form.rowBy(tag: "Completed On") {
                    row.cell.tintAdjustmentMode = .automatic
                    
                    let original = Date()
                    let updateDate = Date(timeIntervalSinceReferenceDate:
                                        (original.timeIntervalSinceReferenceDate / 300.0).rounded(.toNearestOrEven) * 300.0)
                    
                    completedRow.value = updateDate
                    completedRow.updateCell()
                    completedRow.hidden = false
                    completedRow.evaluateHidden()
                    self.subtask.completedDate = NSNumber(value: Int((updateDate).timeIntervalSince1970))
                } else if let completedRow: DateTimeInlineRow = self.form.rowBy(tag: "Completed On") {
                    row.cell.tintAdjustmentMode = .dimmed
                    completedRow.value = nil
                    completedRow.updateCell()
                    completedRow.hidden = true
                    completedRow.evaluateHidden()
                    self.subtask.completedDate = nil
                }
            }
            
            <<< DateTimeInlineRow("Completed On") {
                $0.cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                $0.cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                $0.cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
                $0.title = $0.tag
                $0.minuteInterval = 5
                $0.dateFormatter?.dateStyle = .medium
                $0.dateFormatter?.timeStyle = .short
                if self.active, subtask.isCompleted ?? false, let date = subtask.completedDate {
                    $0.value = Date(timeIntervalSince1970: date as! TimeInterval)
                    $0.updateCell()
                } else {
                    $0.hidden = true
                }
            }.onChange { [weak self] row in
                if let value = row.value {
                    self?.subtask.completedDate = NSNumber(value: Int((value).timeIntervalSince1970))
                }
            }.onExpandInlineRow { cell, row, inlineRow in
                inlineRow.cellUpdate { (cell, row) in
                    row.cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                    row.cell.tintColor = ThemeManager.currentTheme().cellBackgroundColor
                    if #available(iOS 13.4, *) {
                        cell.datePicker.preferredDatePickerStyle = .wheels
                    }
                    else {
                        cell.datePicker.datePickerMode = .dateAndTime
                    }
                }
                cell.detailTextLabel?.textColor = cell.tintColor
            }.onCollapseInlineRow { cell, _, _ in
                cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
            }.cellUpdate { cell, row in
                cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
            }
            
//                <<< SwitchRow("Start Date") {
//                    $0.cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
//                    $0.cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
//                    $0.cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
//                    $0.title = $0.tag
//                    if self.active, let subtask = subtask, let startDate = subtask.startDate {
//                        $0.value = true
//                        $0.cell.detailTextLabel?.text = startDate.getMonthAndDateAndYear()
//                    } else {
//                        $0.value = false
//                    }
//                }.onChange { [weak self] row in
//                    if let value = row.value, let startDateRow: DatePickerRow = self?.form.rowBy(tag: "StartDate") {
//                        if value, let startTime = self?.form.rowBy(tag: "StartTime") {
//                            if let subtask = self?.subtask, let startDate = subtask.startDate {
//                                row.cell.detailTextLabel?.text = startDate.getMonthAndDateAndYear()
//                                startDateRow.value = startDate
//                            } else {
//                                let startDateTime = Date()
//                                startDateRow.value = startDateTime
//                                row.cell.detailTextLabel?.text = startDateTime.getMonthAndDateAndYear()
//        
//                            }
//                            startTime.hidden = true
//                            startTime.evaluateHidden()
//                        } else if let startDateSwitchRow: SwitchRow = self?.form.rowBy(tag: "Start Time") {
//                            row.cell.detailTextLabel?.text = nil
//                            startDateSwitchRow.updateCell()
//                            startDateSwitchRow.cell.detailTextLabel?.text = nil
//                        }
//                        self!.updateStartDate()
//                        let condition: Condition = value ? false : true
//                        row.disabled = condition
//                        startDateRow.hidden = condition
//                        startDateRow.evaluateHidden()
//                    }
//                }.onCellSelection({ [weak self] _, row in
//                    if row.value ?? false {
//                        if let startDate = self?.form.rowBy(tag: "StartDate"), let startTime = self?.form.rowBy(tag: "StartTime") {
//                            startDate.hidden = startDate.isHidden ? false : true
//                            startDate.evaluateHidden()
//                            if !startDate.isHidden {
//                                startTime.hidden = true
//                                startTime.evaluateHidden()
//                            }
//                        }
//                    }
//                }).cellUpdate { cell, row in
//                    cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
//                    cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
//                    cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
//                    if let subtask = self.subtask, let startDate = subtask.startDate {
//                        cell.detailTextLabel?.text = startDate.getMonthAndDateAndYear()
//                    }
//                }
//        
//                <<< DatePickerRow("StartDate") {
//                    $0.cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
//                    $0.cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
//                    $0.cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
//                    $0.cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
//                    $0.cell.tintColor = ThemeManager.currentTheme().cellBackgroundColor
//                    $0.hidden = true
//                    $0.minuteInterval = 5
//                    if #available(iOS 13.4, *) {
//                        $0.cell.datePicker.preferredDatePickerStyle = .wheels
//                    }
//                    else {
//                        $0.cell.datePicker.datePickerMode = .date
//                    }
//                    if self.active, let subtask = subtask, let startDate = subtask.startDate {
//                        $0.value = startDate
//                        $0.updateCell()
//                    }
//                }.onChange { [weak self] row in
//                    if let value = row.value, let switchDateRow: SwitchRow = self?.form.rowBy(tag: "Start Date") {
//                        switchDateRow.cell.detailTextLabel?.text = value.getMonthAndDateAndYear()
//                    }
//                    self!.updateStartDate()
//                }.cellUpdate { cell, row in
//                    cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
//                    cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
//                }
//        
//                <<< SwitchRow("Start Time") {
//                    $0.cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
//                    $0.cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
//                    $0.cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
//                    $0.title = $0.tag
//                    if self.active, let subtask = subtask, subtask.hasStartTime ?? false, let startDate = subtask.startDate {
//                        $0.value = true
//                        $0.cell.detailTextLabel?.text = startDate.getTimeString()
//                    } else {
//                        $0.value = false
//                    }
//                }.onChange { [weak self] row in
//                    if let value = row.value, let startTimeRow: TimePickerRow = self?.form.rowBy(tag: "StartTime") {
//                        if value, let startDateDateRow = self?.form.rowBy(tag: "StartDate"), let startDateSwitchRow: SwitchRow = self?.form.rowBy(tag: "Start Date") {
//                            if let subtask = self?.subtask, subtask.hasStartTime ?? false, let startDate = subtask.startDate {
//                                row.cell.detailTextLabel?.text = startDate.getTimeString()
//                                startTimeRow.value = startDate
//                                if !(startDateSwitchRow.value ?? false) {
//                                    startDateSwitchRow.value = value
//                                    startDateSwitchRow.updateCell()
//                                    startDateSwitchRow.cell.detailTextLabel?.text = startDate.getMonthAndDateAndYear()
//                                }
//                            } else {
//                                let original = Date()
//                                let startDate = Date(timeIntervalSinceReferenceDate:
//                                                    (original.timeIntervalSinceReferenceDate / 300.0).rounded(.toNearestOrEven) * 300.0)
//                                startTimeRow.value = startDate
//                                row.cell.detailTextLabel?.text = startDate.getTimeString()
//                                if !(startDateSwitchRow.value ?? false) {
//                                    startDateSwitchRow.value = value
//                                    startDateSwitchRow.updateCell()
//                                    startDateSwitchRow.cell.detailTextLabel?.text = startDate.getMonthAndDateAndYear()
//                                }
//                            }
//                            startDateDateRow.hidden = true
//                            startDateDateRow.evaluateHidden()
//                        } else {
//                            row.cell.detailTextLabel?.text = nil
//                        }
//                        self!.updateStartDate()
//                        let condition: Condition = value ? false : true
//                        row.disabled = condition
//                        startTimeRow.hidden = condition
//                        startTimeRow.evaluateHidden()
//                    }
//                }.onCellSelection({ [weak self] _, row in
//                    if row.value ?? false {
//                        if let startTime = self?.form.rowBy(tag: "StartTime"), let startDate = self?.form.rowBy(tag: "StartDate") {
//                            startTime.hidden = startTime.isHidden ? false : true
//                            startTime.evaluateHidden()
//                            if !startTime.isHidden {
//                                startDate.hidden = true
//                                startDate.evaluateHidden()
//                            }
//                        }
//                    }
//                }).cellUpdate { cell, row in
//                    cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
//                    cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
//                    cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
//                    if let subtask = self.subtask, let startDate = subtask.startDate {
//                        cell.detailTextLabel?.text = startDate.getTimeString()
//                    }
//                }
//        
//                <<< TimePickerRow("StartTime") {
//                    $0.cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
//                    $0.cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
//                    $0.cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
//                    $0.cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
//                    $0.cell.tintColor = ThemeManager.currentTheme().cellBackgroundColor
//                    $0.hidden = true
//                    $0.minuteInterval = 5
//                    if #available(iOS 13.4, *) {
//                        $0.cell.datePicker.preferredDatePickerStyle = .wheels
//                    }
//                    else {
//                        $0.cell.datePicker.datePickerMode = .time
//                    }
//                    if self.active, let subtask = subtask, subtask.hasStartTime ?? false, let startDate = subtask.startDate {
//                        $0.value = startDate
//                        $0.updateCell()
//                    }
//                }.onChange { [weak self] row in
//                    if let value = row.value, let switchDateRow: SwitchRow = self?.form.rowBy(tag: "Start Time") {
//                        self?.subtask.startDateTime = NSNumber(value: Int((value).timeIntervalSince1970))
//                        switchDateRow.cell.detailTextLabel?.text = value.getTimeString()
//                    }
//        
//                    self!.updateStartDate()
//                }.cellUpdate { cell, row in
//                    cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
//                    cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
//                }

                <<< SwitchRow("deadlineDateSwitch") {
                    $0.cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                    $0.cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                    $0.cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
                    $0.title = "Deadline Date"
                    if self.active, let subtask = subtask, let endDate = subtask.endDate {
                        $0.value = true
                        $0.cell.detailTextLabel?.text = endDate.getMonthAndDateAndYear()
                    } else {
                        $0.value = false
                    }
                }.onChange { [weak self] row in
                    if let value = row.value, let endDateRow: DatePickerRow = self?.form.rowBy(tag: "DeadlineDate") {
                        if value, let endTime = self?.form.rowBy(tag: "DeadlineTime") {
                            if let subtask = self?.subtask, let endDate = subtask.endDate {
                                row.cell.detailTextLabel?.text = endDate.getMonthAndDateAndYear()
                                endDateRow.value = endDate
                            } else {
                                let endDateTime = Date()
                                endDateRow.value = endDateTime
                                row.cell.detailTextLabel?.text = endDateTime.getMonthAndDateAndYear()

                            }
                            endTime.hidden = true
                            endTime.evaluateHidden()
                        } else if let endDateSwitchRow: SwitchRow = self?.form.rowBy(tag: "deadlineTimeSwitch") {
                            row.cell.detailTextLabel?.text = nil
                            endDateSwitchRow.updateCell()
                            endDateSwitchRow.cell.detailTextLabel?.text = nil
                        }
                        self!.updateDeadlineDate()

                        let condition: Condition = value ? false : true
                        row.disabled = condition
                        endDateRow.hidden = condition
                        endDateRow.evaluateHidden()
                        
                    }
                }.onCellSelection({ [weak self] _, row in
                    if row.value ?? false {
                        if let endDate = self?.form.rowBy(tag: "DeadlineDate"), let endTime = self?.form.rowBy(tag: "DeadlineTime") {
                            endDate.hidden = endDate.isHidden ? false : true
                            endDate.evaluateHidden()
                            if !endDate.isHidden {
                                endTime.hidden = true
                                endTime.evaluateHidden()
                            }
                        }
                    }
                }).cellUpdate { cell, row in
                    cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                    cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                    cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
                    if let subtask = self.subtask, let endDate = subtask.endDate {
                        cell.detailTextLabel?.text = endDate.getMonthAndDateAndYear()
                    }
                }

                <<< DatePickerRow("DeadlineDate") {
                    $0.cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                    $0.cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                    $0.cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
                    $0.cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                    $0.cell.tintColor = ThemeManager.currentTheme().cellBackgroundColor
                    $0.hidden = true
                    $0.minuteInterval = 5
                    if #available(iOS 13.4, *) {
                        $0.cell.datePicker.preferredDatePickerStyle = .wheels
                    }
                    else {
                        $0.cell.datePicker.datePickerMode = .date
                    }
                    if self.active, let subtask = subtask, let endDate = subtask.endDate {
                        $0.value = endDate
                        $0.updateCell()
                    }
                }.onChange { [weak self] row in
                    if let value = row.value, let switchDateRow: SwitchRow = self?.form.rowBy(tag: "deadlineDateSwitch") {
                        switchDateRow.cell.detailTextLabel?.text = value.getMonthAndDateAndYear()
                    }
                    self!.updateDeadlineDate()
                }.cellUpdate { cell, row in
                    cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                    cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                }

                <<< SwitchRow("deadlineTimeSwitch") {
                    $0.cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                    $0.cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                    $0.cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
                    $0.title = "Deadline Time"
                    if self.active, let subtask = subtask, subtask.hasDeadlineTime ?? false, let endDate = subtask.endDate {
                        print("if")
                        $0.value = true
                        $0.cell.detailTextLabel?.text = endDate.getTimeString()
                    } else {
                        print("else")
                        $0.value = false
                        $0.cell.detailTextLabel?.text = nil
                    }
                }.onChange { [weak self] row in
                    if let value = row.value, let endTimeRow: TimePickerRow = self?.form.rowBy(tag: "DeadlineTime") {
                        if value, let endDateDateRow = self?.form.rowBy(tag: "DeadlineDate"), let endDateSwitchRow: SwitchRow = self?.form.rowBy(tag: "deadlineDateSwitch") {
                            if let subtask = self?.subtask, subtask.hasDeadlineTime ?? false, let endDate = subtask.endDate {
                                row.cell.detailTextLabel?.text = endDate.getTimeString()
                                endTimeRow.value = endDate
                                if !(endDateSwitchRow.value ?? false) {
                                    endDateSwitchRow.value = value
                                    endDateSwitchRow.updateCell()
                                    endDateSwitchRow.cell.detailTextLabel?.text = endDate.getMonthAndDateAndYear()
                                }
                            } else {
                                let original = Date()
                                let endDate = Date(timeIntervalSinceReferenceDate:
                                                    (original.timeIntervalSinceReferenceDate / 300.0).rounded(.toNearestOrEven) * 300.0)
                                endTimeRow.value = endDate
                                row.cell.detailTextLabel?.text = endDate.getTimeString()
                                if !(endDateSwitchRow.value ?? false) {
                                    endDateSwitchRow.value = value
                                    endDateSwitchRow.updateCell()
                                    endDateSwitchRow.cell.detailTextLabel?.text = endDate.getMonthAndDateAndYear()
                                }
                            }
                            endDateDateRow.hidden = true
                            endDateDateRow.evaluateHidden()
                        } else {
                            row.cell.detailTextLabel?.text = nil
                        }
                        self!.updateDeadlineDate()

                        let condition: Condition = value ? false : true
                        row.disabled = condition
                        endTimeRow.hidden = condition
                        endTimeRow.evaluateHidden()
                        
                    }
                }.onCellSelection({ [weak self] _, row in
                    if row.value ?? false {
                        if let endTime = self?.form.rowBy(tag: "DeadlineTime"), let endDate = self?.form.rowBy(tag: "DeadlineDate") {
                            endTime.hidden = endTime.isHidden ? false : true
                            endTime.evaluateHidden()
                            if !endTime.isHidden {
                                endDate.hidden = true
                                endDate.evaluateHidden()
                            }
                        }
                    }
                }).cellUpdate { cell, row in
                    cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                    cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                    cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
                    if let subtask = self.subtask, subtask.hasDeadlineTime ?? false, let endDate = subtask.endDate {
                        cell.detailTextLabel?.text = endDate.getTimeString()
                    }
                }

                <<< TimePickerRow("DeadlineTime") {
                    $0.cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                    $0.cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                    $0.cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
                    $0.cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                    $0.cell.tintColor = ThemeManager.currentTheme().cellBackgroundColor
                    $0.hidden = true
                    $0.minuteInterval = 5
                    if #available(iOS 13.4, *) {
                        $0.cell.datePicker.preferredDatePickerStyle = .wheels
                    }
                    else {
                        $0.cell.datePicker.datePickerMode = .time
                    }
                    if self.active, let subtask = subtask, subtask.hasDeadlineTime ?? false, let endDate = subtask.endDate {
                        $0.value = endDate
                        $0.updateCell()
                    }
                }.onChange { [weak self] row in
                    print("onchange deadlinetime")
                    if let value = row.value, let switchDateRow: SwitchRow = self?.form.rowBy(tag: "deadlineTimeSwitch") {
                        self?.subtask.endDateTime = NSNumber(value: Int((value).timeIntervalSince1970))
                        switchDateRow.cell.detailTextLabel?.text = value.getTimeString()
                    }
                    self!.updateDeadlineDate()
                }.cellUpdate { cell, row in
                    cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                    cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                }
        
        <<< PushRow<EventAlert>("Reminder") { row in
            row.cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
            row.cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
            row.cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
            row.title = row.tag
            row.hidden = "$deadlineDateSwitch == false"
            if self.active, let value = self.subtask.reminder {
                row.value = EventAlert(rawValue: value)
            } else {
                row.value = EventAlert.None
                if let reminder = row.value?.description {
                    self.subtask.reminder = reminder
                }
            }
            row.options = EventAlert.allCases
        }.onPresent { from, to in
            to.title = "Reminder"
            to.extendedLayoutIncludesOpaqueBars = true
            to.tableViewStyle = .insetGrouped
            to.selectableRowCellUpdate = { cell, row in
                to.navigationController?.navigationBar.backgroundColor = ThemeManager.currentTheme().barBackgroundColor
                to.tableView.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                to.tableView.separatorStyle = .none
                cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
            }
        }.cellUpdate { cell, row in
            cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
            cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
            cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
        }.onChange() { [unowned self] row in
            if let reminder = row.value?.description {
                self.subtask.reminder = reminder
                if self.active {
                    self.subtaskReminder()
                }
            }
        }
        
            <<< LabelRow("Category") { row in
                row.cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                row.cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                row.cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
                row.cell.accessoryType = .disclosureIndicator
                row.cell.selectionStyle = .default
                row.title = row.tag
                if self.active && self.subtask.category != nil {
                    row.value = self.subtask.category
                } else {
                    row.value = "Uncategorized"
                }
            }.onCellSelection({ _, row in
                self.openLevel(value: row.value ?? "Uncategorized", level: "Category")
            }).cellUpdate { cell, row in
                cell.accessoryType = .disclosureIndicator
                cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
                cell.textLabel?.textAlignment = .left
            }

        
        form +++
            MultivaluedSection(multivaluedOptions: [.Insert, .Delete, .Reorder],
                               header: "Checklist",
                               footer: "Add a checklist item") {
                                $0.tag = "checklistfields"
                                $0.addButtonProvider = { section in
                                    return ButtonRow(){
                                        $0.cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                                        $0.title = "Add New Item"
                                        }.cellUpdate { cell, row in
                                            cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                                            cell.textLabel?.textAlignment = .left
                                            
                                    }
                                }
                                $0.multivaluedRowToInsertAt = { index in
                                    return SplitRow<TextRow, CheckRow>(){
                                        $0.rowLeftPercentage = 0.75
                                        $0.rowLeft = TextRow(){
                                            $0.cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                                            $0.cell.textField?.textColor = ThemeManager.currentTheme().generalTitleColor
                                            $0.placeholderColor = ThemeManager.currentTheme().generalSubtitleColor
                                            $0.placeholder = "Item"
                                            }.cellUpdate { cell, row in
                                                cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                                                cell.textField?.textColor = ThemeManager.currentTheme().generalTitleColor
                                                row.placeholderColor = ThemeManager.currentTheme().generalSubtitleColor
                                        }
                                        
                                        $0.rowRight = CheckRow() {
                                            $0.cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                                            $0.cell.tintColor = FalconPalette.defaultBlue
                                            $0.value = false
                                            $0.cell.accessoryType = .checkmark
                                            $0.cell.tintAdjustmentMode = .dimmed
                                            }.cellUpdate { cell, row in
                                                cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                                                cell.tintColor = FalconPalette.defaultBlue
                                                cell.accessoryType = .checkmark
                                                if row.value == false {
                                                    cell.tintAdjustmentMode = .dimmed
                                                } else {
                                                    cell.tintAdjustmentMode = .automatic
                                                }
                                        }
                                        }.cellUpdate { cell, row in
                                            cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
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
            
            if subtask.checklistIDs == nil, let currentUserID = Auth.auth().currentUser?.uid {
                let ID = Database.database().reference().child(userChecklistsEntity).child(currentUserID).childByAutoId().key ?? ""
                checklist = Checklist(dictionary: ["ID": ID as AnyObject])
                checklist.name = "CheckList"
                checklist.createdDate = Date()
                checklist.activityID = subtask.activityID
                checklist.items = checklistDict
                subtask.checklistIDs = [checklist.ID ?? ""]
                
                let createChecklist = ChecklistActions(checklist: checklist, active: true, selectedFalconUsers: [])
                createChecklist.createNewChecklist()
            } else {
                checklist.items = checklistDict
                let createChecklist = ChecklistActions(checklist: checklist, active: true, selectedFalconUsers: [])
                createChecklist.createNewChecklist()
            }
        } else {
            subtask.checklistIDs = []
        }
        
        let valuesDictionary = form.values()
        
        subtask.activityID = subtaskID

        subtask.name = valuesDictionary["Name"] as? String

        if let value = valuesDictionary["Type"] as? String {
            subtask.activityType = value
        }
        
        if let value = valuesDictionary["Description"] as? String {
            subtask.activityDescription = value
        }

        if let value = valuesDictionary["Transportation"] as? String {
            subtask.transportation = value
        }
        
        if let value = valuesDictionary["Reminder"] as? String {
            subtask.reminder = value
        }
        
        let membersIDs = fetchMembersIDs()

        subtask.participantsIDs = membersIDs.0
        
        let createActivity = ActivityActions(activity: subtask, active: false, selectedFalconUsers: [])
        createActivity.createSubActivity()
        
        movingBackwards = false
        delegate?.updateTask(task: subtask)
        
        if navigationItem.leftBarButtonItem != nil {
            self.dismiss(animated: true, completion: nil)
        } else {
            self.navigationController?.popViewController(animated: true)
        }
    }
    
    func setupLists() {
        let dispatchGroup = DispatchGroup()
        if subtask.checklistIDs != nil {
            for checklistID in subtask.checklistIDs! {
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
                        $0.cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                        $0.cell.textField?.textColor = ThemeManager.currentTheme().generalTitleColor
                        $0.placeholderColor = ThemeManager.currentTheme().generalSubtitleColor
                        $0.value = item.key
                        }.cellUpdate { cell, row in
                            cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                            cell.textField?.textColor = ThemeManager.currentTheme().generalTitleColor
                            row.placeholderColor = ThemeManager.currentTheme().generalSubtitleColor
                    }
                    $0.rowRight = CheckRow() {
                        $0.cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                        $0.cell.tintColor = FalconPalette.defaultBlue
                        $0.value = item.value
                        $0.cell.accessoryType = .checkmark
                        if item.value {
                            $0.cell.tintAdjustmentMode = .automatic
                        } else {
                            $0.cell.tintAdjustmentMode = .dimmed
                        }
                        }.cellUpdate { cell, row in
                            cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                            cell.tintColor = FalconPalette.defaultBlue
                            cell.accessoryType = .checkmark
                            if row.value == false {
                                cell.tintAdjustmentMode = .dimmed
                            } else {
                                cell.tintAdjustmentMode = .automatic
                            }
                    }
                    }.cellUpdate { cell, row in
                        cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                }, at: mvs.count - 1)
                
            }
        }
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
                self.subtask.startDateTime = NSNumber(value: Int((date)?.timeIntervalSince1970 ?? 0))
                self.subtask.hasStartTime = true
            } else if dateSwitchRowValue, let dateRowValue = dateRow.value {
                print(dateRowValue.yearNumber())
                var dateComponents = DateComponents()
                dateComponents.year = dateRowValue.yearNumber()
                dateComponents.month = dateRowValue.monthNumber()
                dateComponents.day = dateRowValue.dayNumber()
                let date = Calendar.current.date(from: dateComponents)
                self.subtask.startDateTime = NSNumber(value: Int((date)?.timeIntervalSince1970 ?? 0))
                self.subtask.hasStartTime = false
            } else {
                self.subtask.startDateTime = nil
                self.subtask.hasStartTime = false
            }
            self.subtaskReminder()
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
                self.subtask.endDateTime = NSNumber(value: Int((date)?.timeIntervalSince1970 ?? 0))
                self.subtask.hasDeadlineTime = true
            } else if dateSwitchRowValue, let dateRowValue = dateRow.value {
                var dateComponents = DateComponents()
                dateComponents.year = dateRowValue.yearNumber()
                dateComponents.month = dateRowValue.monthNumber()
                dateComponents.day = dateRowValue.dayNumber()
                let date = Calendar.current.date(from: dateComponents)
                self.subtask.endDateTime = NSNumber(value: Int((date)?.timeIntervalSince1970 ?? 0))
                self.subtask.hasDeadlineTime = false
            } else {
                self.subtask.endDateTime = nil
                self.subtask.hasDeadlineTime = false
            }
            self.subtaskReminder()
        }
    }
    
    func subtaskReminder() {
        guard let subtask = subtask, let activityReminder = subtask.reminder, let endDate = subtask.endDate else {
            return
        }
        let center = UNUserNotificationCenter.current()
        guard activityReminder != "None" else {
            center.removePendingNotificationRequests(withIdentifiers: ["\(subtaskID)_Reminder"])
            return
        }
        let content = UNMutableNotificationContent()
        content.title = "\(String(describing: subtask.name!)) Reminder"
        content.sound = UNNotificationSound.default
        var formattedDate: (String, String) = ("", "")
        formattedDate = timestampOfTask(endDate: endDate, hasDeadlineTime: subtask.hasDeadlineTime ?? false, startDate: subtask.startDate, hasStartTime: subtask.hasStartTime)
        content.subtitle = formattedDate.0
        if let reminder = EventAlert(rawValue: activityReminder) {
            let reminderDate = endDate.addingTimeInterval(reminder.timeInterval)
            let calendar = Calendar.current
            let triggerDate = calendar.dateComponents([.year,.month,.day,.hour,.minute,.second], from: reminderDate)
            let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate,
                                                        repeats: false)
            let identifier = "\(subtaskID)_Reminder"
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
            center.add(request, withCompletionHandler: { (error) in
                if let error = error {
                    print(error)
                }
            })
        }
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
    
    func openLevel(value: String, level: String) {
        let destination = ActivityLevelViewController()
        destination.delegate = self
        destination.value = value
        destination.level = level
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
        destination.sections = [.event]
        destination.locations = [.event: subtask]
        navigationController?.pushViewController(destination, animated: true)
        
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

}

extension SubtaskViewController: UpdateInvitees {
    func updateInvitees(selectedFalconUsers: [User]) {
//        if let inviteesRow: ButtonRow = form.rowBy(tag: "Participants") {
//            if !selectedFalconUsers.isEmpty {
//                self.userNamesString = "\(self.selectedFalconUsers.count + 1) participants"
//                inviteesRow.title = self.userNamesString
//                inviteesRow.updateCell()
//            } else {
//                inviteesRow.title = "Participants"
//                inviteesRow.updateCell()
//            }
//            self.selectedFalconUsers = selectedFalconUsers
//        }
    }
}

extension SubtaskViewController: UpdateActivityLevelDelegate {
    func update(value: String, level: String) {
        if let row: LabelRow = form.rowBy(tag: level) {
            row.value = value
            row.updateCell()
            if level == "Category" {
                self.subtask.category = value
            } else if level == "Subcategory" {
                self.subtask.activityType = value
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

