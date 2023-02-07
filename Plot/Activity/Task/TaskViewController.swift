//
//  TaskViewController.swift
//  Plot
//
//  Created by Cory McHattie on 8/2/22.
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

class TaskViewController: FormViewController, ObjectDetailShowing {
    var task: Activity!
    var taskOld: Activity!
    var invitation: Invitation?
    var chatLogController: ChatLogController? = nil
    var messagesFetcher: MessagesFetcher? = nil
    
    weak var delegate : UpdateTaskDelegate?
    
    var networkController: NetworkController
    
    init(networkController: NetworkController) {
        self.networkController = networkController
        super.init(style: .insetGrouped)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    lazy var users: [User] = networkController.userService.users
    lazy var filteredUsers: [User] = networkController.userService.users
    lazy var tasks: [Activity] = networkController.activityService.tasks
    lazy var events: [Activity] = networkController.activityService.events
    lazy var lists: [String: [ListType]] = networkController.activityService.lists
    lazy var transactions: [Transaction] = networkController.financeService.transactions
    
    var selectedFalconUsers = [User]()
    var purchaseUsers = [User]()
    var participants = [String : [User]]()
    var userInvitationStatus: [String: Status] = [:]
    let avatarOpener = AvatarOpener()
    var subtaskList = [Activity]()
    var container: Container!
    var purchaseList = [Transaction]()
    var purchaseDict = [User: Double]()
    var listList = [ListContainer]()
    var healthList = [HealthContainer]()
    var list: ListType?
    var purchaseIndex: Int = 0
    var listIndex: Int = 0
    var healthIndex: Int = 0
    var eventList = [Activity]()
    var eventIndex: Int = 0
    var startDateTime: Date?
    var endDateTime: Date?
    
    var grocerylistIndex: Int = -1
    var thumbnailImage: String = ""
    var segmentRowValue: String = "Health"
    var activityID = String()
    let informationMessageSender = InformationMessageSender()
    // Participants with accepted invites
    var weather: [DailyWeatherElement]!
    
    var transaction: Transaction!
    var workout: Workout!
    var mindfulness: Mindfulness!
    var event: Activity!
    var template: Template!
    
    var active = false
    var sectionChanged: Bool = false
    var isGoal: Bool = false
    
    weak var updateDiscoverDelegate : UpdateDiscover?
    
    typealias CompletionHandler = (_ success: Bool) -> Void
    
    var activityAvatarURL = String() {
        didSet {
            let viewRow: ViewRow<UIImageView> = form.rowBy(tag: "Task Image")!
            viewRow.cell.view!.showActivityIndicator()
            viewRow.cell.view!.sd_setImage(with: URL(string:activityAvatarURL), placeholderImage: nil, options: [.continueInBackground, .scaleDownLargeImages], completed: { (image, error, cacheType, url) in
                viewRow.cell.view!.hideActivityIndicator()
            })
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupMainView()
        
        if task != nil {
            print(isGoal)
            title = !isGoal ? "Task":"Goal"
            active = true
            taskOld = task.copy() as? Activity
            if task.activityID != nil {
                activityID = task.activityID!
                print(activityID)
                print(task.instanceID as Any)
            }
            if task.admin == nil, let currentUserID = Auth.auth().currentUser?.uid {
                task.admin = currentUserID
            }
            setupLists()
            resetBadgeForSelf()
        } else {
            title = !isGoal ? "New Task":"New Goal"
            if let currentUserID = Auth.auth().currentUser?.uid {
                if let transaction = transaction, let task = TaskBuilder.createActivity(from: transaction), let activityID = task.activityID {
                    self.activityID = activityID
                    self.task = task
                } else if let workout = workout, let task = TaskBuilder.createActivity(from: workout), let activityID = task.activityID {
                    self.activityID = activityID
                    self.task = task
                } else if let mindfulness = mindfulness, let task = TaskBuilder.createActivity(from: mindfulness), let activityID = task.activityID {
                    self.activityID = activityID
                    self.task = task
                } else if let event = event, let task = TaskBuilder.createActivity(event: event), let activityID = task.activityID {
                    self.activityID = activityID
                    self.task = task
                    if let list = lists[ListSourceOptions.plot.name]?.first(where: { $0.defaultList ?? false }) {
                        self.task.listID = list.id
                        self.task.listName = list.name
                        self.task.listSource = list.source
                        self.task.listColor = list.color
                    }
                } else if let template = template, let taskList = TaskBuilder.createActivity(template: template), let task = taskList.0, let activityID = task.activityID {
                    self.activityID = activityID
                    self.task = task
                    subtaskList = taskList.1 ?? []
                    if !subtaskList.isEmpty {
                        sortSubtasks()
                        updateLists(type: "subtasks")
                    }
                    if let list = lists[ListSourceOptions.plot.name]?.first(where: { $0.defaultList ?? false }) {
                        self.task.listID = list.id
                        self.task.listName = list.name
                        self.task.listSource = list.source
                        self.task.listColor = list.color
                    }
                } else {
                    //create new activityID for auto updating items (schedule, purchases, checklist)
                    activityID = Database.database().reference().child(userActivitiesEntity).child(currentUserID).childByAutoId().key ?? ""
                    if let list = list {
                        task = Activity(activityID: activityID, admin: currentUserID, listID: list.id ?? "", listName: list.name ?? "", listColor: list.color ?? CIColor(color: ChartColors.palette()[5]).stringRepresentation, listSource: list.source ?? "", isCompleted: false, createdDate: NSNumber(value: Int((Date()).timeIntervalSince1970)))
                    } else {
                        list = lists[ListSourceOptions.plot.name]?.first(where: { $0.defaultList ?? false })
                        task = Activity(activityID: activityID, admin: currentUserID, listID: list?.id ?? "", listName: list?.name ?? "", listColor: list?.color ?? CIColor(color: ChartColors.palette()[5]).stringRepresentation, listSource: list?.source ?? "", isCompleted: false, createdDate: NSNumber(value: Int((Date()).timeIntervalSince1970)))
                        task.category = list?.category
                        if let endDateTime = endDateTime {
                            task.endDateTime = NSNumber(value: Int((endDateTime).timeIntervalSince1970))
                        }
                    }
                    if let container = container {
                        task.containerID = container.id
                    }
                    task.isGoal = isGoal
                }
            }
        }
        
        setupRightBarButton()
        initializeForm()
        updateRightBarButton()
        
        if isGoal, let goal = task.goal, let _ = goal.metric {
            self.updateNumberRows()
            if let _ = goal.metricSecond {
                self.updateNumberRowsSecond()
                self.updateSecondTargetRow()
            }
        }
        
        purchaseUsers = self.selectedFalconUsers
        
        if let currentUserID = Auth.auth().currentUser?.uid, self.task.admin == currentUserID {
            let participantReference = Database.database().reference().child("users").child(currentUserID)
            participantReference.observeSingleEvent(of: .value, with: { (snapshot) in
                if snapshot.exists(), var dictionary = snapshot.value as? [String: AnyObject] {
                    dictionary.updateValue(snapshot.key as AnyObject, forKey: "id")
                    let user = User(dictionary: dictionary)
                    self.purchaseUsers.append(user)
                    for user in self.purchaseUsers {
                        self.purchaseDict[user] = 0.00
                    }
                }
            })
        } else {
            for user in self.purchaseUsers {
                self.purchaseDict[user] = 0.00
            }
        }
        
        if active, let currentUser = Auth.auth().currentUser?.uid, let participantsIDs = task?.participantsIDs, !participantsIDs.contains(currentUser) {
            navigationItem.rightBarButtonItems = []
            for row in form.rows {
                row.baseCell.isUserInteractionEnabled = false
            }
        }
    }
    
    fileprivate func setupMainView() {
        navigationController?.isNavigationBarHidden = false
        navigationController?.navigationBar.isHidden = false
        navigationItem.largeTitleDisplayMode = .never
        extendedLayoutIncludesOpaqueBars = true
        view.backgroundColor = .systemGroupedBackground
        tableView.indicatorStyle = .default
        tableView.sectionIndexBackgroundColor = .systemGroupedBackground
        tableView.backgroundColor = .systemGroupedBackground
        tableView.separatorStyle = UITableViewCell.SeparatorStyle.none
        navigationOptions = .Disabled
    }
    
    func setupRightBarButton() {
        if !active {
            let plusBarButton =  UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(createNewActivity))
            navigationItem.rightBarButtonItem = plusBarButton
        } else if delegate != nil {
            let plusBarButton =  UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(createNewActivity))
            navigationItem.rightBarButtonItem = plusBarButton
        } else {
            let dotsImage = UIImage(named: "dots")
            let plusBarButton =  UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(createNewActivity))
            let dotsBarButton = UIBarButtonItem(image: dotsImage, style: .plain, target: self, action: #selector(goToExtras))
            navigationItem.rightBarButtonItems = [plusBarButton, dotsBarButton]
        }
        if navigationItem.leftBarButtonItem != nil {
            navigationItem.leftBarButtonItem?.action = #selector(cancel)
        }
        
    }
    
    fileprivate func initializeForm() {
        form +++
        Section()
        
        <<< TextRow("Name") {
            $0.cell.backgroundColor = .secondarySystemGroupedBackground
            $0.cell.textField?.textColor = .label
            $0.placeholderColor = .secondaryLabel
            $0.placeholder = $0.tag
            if let task = task, let name = task.name {
                $0.value = name
            }
        }.onChange() { [unowned self] row in
            self.task.name = row.value
            self.updateRightBarButton()
        }.cellUpdate { cell, row in
            cell.backgroundColor = .secondarySystemGroupedBackground
            cell.textField?.textColor = .label
        }
        
        if !(task.isGoal ?? false) {
            form.last!
            
            <<< TextAreaRow("Description") {
                $0.cell.backgroundColor = .secondarySystemGroupedBackground
                $0.cell.textView?.backgroundColor = .secondarySystemGroupedBackground
                $0.cell.textView?.textColor = .label
                $0.cell.placeholderLabel?.textColor = .secondaryLabel
                $0.placeholder = $0.tag
                if let task = task, task.activityDescription != "nothing" {
                    $0.value = self.task.activityDescription
                }
            }.cellUpdate({ (cell, row) in
                cell.backgroundColor = .secondarySystemGroupedBackground
                cell.textView?.backgroundColor = .secondarySystemGroupedBackground
                cell.textView?.textColor = .label
            }).onChange() { [unowned self] row in
                self.task.activityDescription = row.value
            }
            
            <<< CheckRow("Completed") {
                $0.cell.backgroundColor = .secondarySystemGroupedBackground
                $0.cell.tintColor = FalconPalette.defaultBlue
                $0.cell.textLabel?.textColor = .label
                $0.cell.detailTextLabel?.textColor = .secondaryLabel
                $0.cell.accessoryType = .checkmark
                $0.cell.isUserInteractionEnabled = !(self.task.isGoal ?? false)
                $0.title = $0.tag
                $0.value = task.isCompleted ?? false
                if $0.value ?? false {
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
            }.onChange { row in
                self.task.isCompleted = row.value
                if row.value ?? false, let completedRow: DateTimeInlineRow = self.form.rowBy(tag: "Completed On") {
                    row.cell.tintAdjustmentMode = .automatic
                    
                    let original = Date()
                    let updateDate = Date(timeIntervalSinceReferenceDate:
                                            (original.timeIntervalSinceReferenceDate / 300.0).rounded(.toNearestOrEven) * 300.0)
                    completedRow.value = updateDate
                    completedRow.updateCell()
                    completedRow.hidden = false
                    completedRow.evaluateHidden()
                    self.task.completedDate = NSNumber(value: Int((updateDate).timeIntervalSince1970))
                    let updateTask = ActivityActions(activity: self.task, active: self.active, selectedFalconUsers: self.selectedFalconUsers)
                    updateTask.updateCompletion(isComplete: self.task.isCompleted ?? false)
                } else if let completedRow: DateTimeInlineRow = self.form.rowBy(tag: "Completed On") {
                    row.cell.tintAdjustmentMode = .dimmed
                    completedRow.value = nil
                    completedRow.updateCell()
                    completedRow.hidden = true
                    completedRow.evaluateHidden()
                    self.task.completedDate = nil
                    let updateTask = ActivityActions(activity: self.task, active: self.active, selectedFalconUsers: self.selectedFalconUsers)
                    updateTask.updateCompletion(isComplete: self.task.isCompleted ?? false)
                }
            }
            
            <<< DateTimeInlineRow("Completed On") {
                $0.cell.backgroundColor = .secondarySystemGroupedBackground
                $0.cell.textLabel?.textColor = .label
                $0.cell.detailTextLabel?.textColor = .secondaryLabel
                $0.title = $0.tag
                $0.minuteInterval = 5
                $0.dateFormatter?.dateStyle = .medium
                $0.dateFormatter?.timeStyle = .short
                if let task = task, task.isCompleted ?? false, let date = task.completedDate {
                    $0.value = Date(timeIntervalSince1970: date as! TimeInterval)
                    $0.updateCell()
                } else {
                    $0.hidden = true
                }
            }.onChange { [weak self] row in
                if let value = row.value {
                    self?.task.completedDate = NSNumber(value: Int((value).timeIntervalSince1970))
                    let updateTask = ActivityActions(activity: self!.task, active: self!.active, selectedFalconUsers: self!.selectedFalconUsers)
                    updateTask.updateCompletion(isComplete: self!.task.isCompleted ?? false)
                }
            }.onExpandInlineRow { cell, row, inlineRow in
                inlineRow.cellUpdate { (cell, row) in
                    row.cell.backgroundColor = .secondarySystemGroupedBackground
                    row.cell.tintColor = .secondarySystemGroupedBackground
                    if #available(iOS 14.0, *) {
                        cell.datePicker.preferredDatePickerStyle = .inline
                        cell.datePicker.tintColor = .systemBlue
                    }
                    else {
                        cell.datePicker.datePickerMode = .dateAndTime
                    }
                }
                cell.detailTextLabel?.textColor = cell.tintColor
            }.onCollapseInlineRow { cell, _, _ in
                cell.detailTextLabel?.textColor = .secondaryLabel
            }.cellUpdate { cell, row in
                cell.backgroundColor = .secondarySystemGroupedBackground
                cell.textLabel?.textColor = .label
            }
            
            //        <<< SwitchRow("startDateSwitch") {
            //            $0.cell.backgroundColor = .secondarySystemGroupedBackground
            //            $0.cell.textLabel?.textColor = .label
            //            $0.cell.detailTextLabel?.textColor = .secondaryLabel
            //            $0.title = "Start Date"
            //            if let task = task, let startDate = task.startDate {
            //                $0.value = true
            //                $0.cell.detailTextLabel?.text = startDate.getMonthAndDateAndYear()
            //            } else {
            //                $0.value = false
            //                $0.cell.detailTextLabel?.text = nil
            //            }
            //        }.onChange { [weak self] row in
            //            if let value = row.value, let startDateRow: DatePickerRow = self?.form.rowBy(tag: "StartDate") {
            //                if value, let startTime = self?.form.rowBy(tag: "StartTime") {
            //                    if let task = self?.task, let startDate = task.startDate {
            //                        row.cell.detailTextLabel?.text = startDate.getMonthAndDateAndYear()
            //                        startDateRow.value = startDate
            //                    } else {
            //                        let startDateTime = Date()
            //                        startDateRow.value = startDateTime
            //                        row.cell.detailTextLabel?.text = startDateTime.getMonthAndDateAndYear()
            //
            //                    }
            //                    startTime.hidden = true
            //                    startTime.evaluateHidden()
            //                } else if let startDateSwitchRow: SwitchRow = self?.form.rowBy(tag: "startTimeSwitch") {
            //                    row.cell.detailTextLabel?.text = nil
            //                    startDateSwitchRow.updateCell()
            //                    startDateSwitchRow.cell.detailTextLabel?.text = nil
            //                }
            //                self!.updateStartDate()
            //                let condition: Condition = value ? false : true
            //                row.disabled = condition
            //                startDateRow.hidden = condition
            //                startDateRow.evaluateHidden()
            //            }
            //        }.onCellSelection({ [weak self] _, row in
            //            if row.value ?? false {
            //                if let startDate = self?.form.rowBy(tag: "StartDate"), let startTime = self?.form.rowBy(tag: "StartTime") {
            //                    startDate.hidden = startDate.isHidden ? false : true
            //                    startDate.evaluateHidden()
            //                    if !startDate.isHidden {
            //                        startTime.hidden = true
            //                        startTime.evaluateHidden()
            //                    }
            //                }
            //            }
            //        }).cellUpdate { cell, row in
            //            cell.backgroundColor = .secondarySystemGroupedBackground
            //            cell.textLabel?.textColor = .label
            //            cell.detailTextLabel?.textColor = .secondaryLabel
            //            if let task = self.task, let startDate = task.startDate {
            //                cell.detailTextLabel?.text = startDate.getMonthAndDateAndYear()
            //            }
            //        }
            //
            //        <<< DatePickerRow("StartDate") {
            //            $0.cell.backgroundColor = .secondarySystemGroupedBackground
            //            $0.cell.textLabel?.textColor = .label
            //            $0.cell.detailTextLabel?.textColor = .secondaryLabel
            //            $0.cell.backgroundColor = .secondarySystemGroupedBackground
            //            $0.cell.tintColor = .secondarySystemGroupedBackground
            //            $0.hidden = true
            //            $0.minuteInterval = 5
            //            if #available(iOS 14.0, *) {
            //                $0.cell.datePicker.preferredDatePickerStyle = .inline
            //                $0.cell.datePicker.tintColor = .systemBlue
            //            }
            //            else {
            //                $0.cell.datePicker.datePickerMode = .date
            //            }
            //            if let task = task, let startDate = task.startDate {
            //                $0.value = startDate
            //                $0.updateCell()
            //            }
            //        }.onChange { [weak self] row in
            //            if let value = row.value, let switchDateRow: SwitchRow = self?.form.rowBy(tag: "startDateSwitch") {
            //                switchDateRow.cell.detailTextLabel?.text = value.getMonthAndDateAndYear()
            //            }
            //            self!.updateStartDate()
            //        }.cellUpdate { cell, row in
            //            cell.backgroundColor = .secondarySystemGroupedBackground
            //            cell.textLabel?.textColor = .label
            //        }
            //
            //        <<< SwitchRow("startTimeSwitch") {
            //            $0.cell.backgroundColor = .secondarySystemGroupedBackground
            //            $0.cell.textLabel?.textColor = .label
            //            $0.cell.detailTextLabel?.textColor = .secondaryLabel
            //            $0.title = "Start Time"
            //            if let task = task, task.hasStartTime ?? false, let startDate = task.startDate {
            //                $0.value = true
            //                $0.cell.detailTextLabel?.text = startDate.getTimeString()
            //            } else {
            //                $0.value = false
            //                $0.cell.detailTextLabel?.text = nil
            //            }
            //        }.onChange { [weak self] row in
            //            if let value = row.value, let startTimeRow: TimePickerRow = self?.form.rowBy(tag: "StartTime") {
            //                if value, let startDateDateRow = self?.form.rowBy(tag: "StartDate"), let startDateSwitchRow: SwitchRow = self?.form.rowBy(tag: "startDateSwitch") {
            //                    if let task = self?.task, task.hasStartTime ?? false, let startDate = task.startDate {
            //                        row.cell.detailTextLabel?.text = startDate.getTimeString()
            //                        startTimeRow.value = startDate
            //                        if !(startDateSwitchRow.value ?? false) {
            //                            startDateSwitchRow.value = value
            //                            startDateSwitchRow.updateCell()
            //                            startDateSwitchRow.cell.detailTextLabel?.text = startDate.getMonthAndDateAndYear()
            //                        }
            //                    } else {
            //                        let original = Date()
            //                        let startDate = Date(timeIntervalSinceReferenceDate:
            //                                            (original.timeIntervalSinceReferenceDate / 300.0).rounded(.toNearestOrEven) * 300.0)
            //                        startTimeRow.value = startDate
            //                        row.cell.detailTextLabel?.text = startDate.getTimeString()
            //                        if !(startDateSwitchRow.value ?? false) {
            //                            startDateSwitchRow.value = value
            //                            startDateSwitchRow.updateCell()
            //                            startDateSwitchRow.cell.detailTextLabel?.text = startDate.getMonthAndDateAndYear()
            //                        }
            //                    }
            //                    startDateDateRow.hidden = true
            //                    startDateDateRow.evaluateHidden()
            //                } else {
            //                    row.cell.detailTextLabel?.text = nil
            //                }
            //                self!.updateStartDate()
            //                let condition: Condition = value ? false : true
            //                row.disabled = condition
            //                startTimeRow.hidden = condition
            //                startTimeRow.evaluateHidden()
            //            }
            //        }.onCellSelection({ [weak self] _, row in
            //            if row.value ?? false {
            //                if let startTime = self?.form.rowBy(tag: "StartTime"), let startDate = self?.form.rowBy(tag: "StartDate") {
            //                    startTime.hidden = startTime.isHidden ? false : true
            //                    startTime.evaluateHidden()
            //                    if !startTime.isHidden {
            //                        startDate.hidden = true
            //                        startDate.evaluateHidden()
            //                    }
            //                }
            //            }
            //        }).cellUpdate { cell, row in
            //            cell.backgroundColor = .secondarySystemGroupedBackground
            //            cell.textLabel?.textColor = .label
            //            cell.detailTextLabel?.textColor = .secondaryLabel
            //            if let task = self.task, task.hasStartTime ?? false, let startDate = task.startDate {
            //                cell.detailTextLabel?.text = startDate.getTimeString()
            //            }
            //        }
            //
            //        <<< TimePickerRow("StartTime") {
            //            $0.cell.backgroundColor = .secondarySystemGroupedBackground
            //            $0.cell.textLabel?.textColor = .label
            //            $0.cell.detailTextLabel?.textColor = .secondaryLabel
            //            $0.cell.backgroundColor = .secondarySystemGroupedBackground
            //            $0.cell.tintColor = .secondarySystemGroupedBackground
            //            $0.hidden = true
            //            $0.minuteInterval = 5
            //            if #available(iOS 13.4, *) {
            //                $0.cell.datePicker.preferredDatePickerStyle = .wheels
            //            }
            //            else {
            //                $0.cell.datePicker.datePickerMode = .time
            //            }
            //            if let task = task, task.hasStartTime ?? false, let startDate = task.startDate {
            //                $0.value = startDate
            //                $0.updateCell()
            //            }
            //        }.onChange { [weak self] row in
            //            if let value = row.value, let switchDateRow: SwitchRow = self?.form.rowBy(tag: "startTimeSwitch") {
            //                self?.task.startDateTime = NSNumber(value: Int((value).timeIntervalSince1970))
            //                switchDateRow.cell.detailTextLabel?.text = value.getTimeString()
            //            }
            //            self!.updateStartDate()
            //        }.cellUpdate { cell, row in
            //            cell.backgroundColor = .secondarySystemGroupedBackground
            //            cell.textLabel?.textColor = .label
            //        }
                    
            <<< SwitchRow("deadlineDateSwitch") {
                $0.cell.backgroundColor = .secondarySystemGroupedBackground
                $0.cell.textLabel?.textColor = .label
                $0.cell.detailTextLabel?.textColor = .secondaryLabel
                $0.title = "Deadline Date"
                if self.task.isGoal ?? false {
                    $0.hidden = Condition(booleanLiteral: self.task.recurrences != nil)
                }
                if let task = task, let endDate = task.endDate {
                    $0.value = true
                    $0.cell.detailTextLabel?.text = endDate.getMonthAndDateAndYear()
                } else {
                    $0.value = false
                    $0.cell.detailTextLabel?.text = nil
                }
            }.onChange { [weak self] row in
                if let value = row.value, let endDateRow: DatePickerRow = self?.form.rowBy(tag: "DeadlineDate"), let endTimeSwitchRow: SwitchRow = self?.form.rowBy(tag: "deadlineTimeSwitch") {
                    if value, let endTime: TimePickerRow = self?.form.rowBy(tag: "DeadlineTime") {
                        row.cell.detailTextLabel?.textColor = .systemBlue
                        if let task = self?.task, let endDate = task.endDate {
                            row.cell.detailTextLabel?.text = endDate.getMonthAndDateAndYear()
                            endDateRow.value = endDate
                        } else {
                            let endDateTime = Date()
                            endDateRow.value = endDateTime
                            row.cell.detailTextLabel?.text = endDateTime.getMonthAndDateAndYear()
                            
                        }
                        endTimeSwitchRow.cell.detailTextLabel?.textColor = .secondaryLabel
                        endTimeSwitchRow.updateCell()
                        endTime.hidden = true
                        endTime.evaluateHidden()
                    } else {
                        row.cell.detailTextLabel?.text = nil
                        endTimeSwitchRow.cell.detailTextLabel?.text = nil
                        endTimeSwitchRow.value = false
                        endTimeSwitchRow.updateCell()
                    }
                    self!.updateDeadlineDate()
                    
                    let condition: Condition = value ? false : true
                    row.disabled = condition
                    endDateRow.hidden = condition
                    endDateRow.evaluateHidden()
                    
                }
            }.onCellSelection({ [weak self] _, row in
                if row.value ?? false {
                    if let endDate: DatePickerRow = self?.form.rowBy(tag: "DeadlineDate"), let endTime: TimePickerRow = self?.form.rowBy(tag: "DeadlineTime"), let endTimeSwitchRow: SwitchRow = self?.form.rowBy(tag: "deadlineTimeSwitch") {
                        endDate.hidden = endDate.isHidden ? false : true
                        endDate.evaluateHidden()
                        if !endDate.isHidden {
                            row.cell.detailTextLabel?.textColor = .systemBlue
                            endTimeSwitchRow.cell.detailTextLabel?.textColor = .secondaryLabel
                            endTimeSwitchRow.updateCell()
                            endTime.hidden = true
                            endTime.evaluateHidden()
                        } else {
                            row.cell.detailTextLabel?.textColor = .secondaryLabel
                        }
                    }
                }
            }).cellUpdate { cell, row in
                cell.backgroundColor = .secondarySystemGroupedBackground
                cell.textLabel?.textColor = .label
                cell.detailTextLabel?.textColor = .secondaryLabel
                if let task = self.task, let endDate = task.endDate {
                    cell.detailTextLabel?.text = endDate.getMonthAndDateAndYear()
                } else {
                    cell.detailTextLabel?.text = nil
                }
                if self.task.isGoal ?? false {
                    row.hidden = "$Repeat != 'Never'"
                }
            }
            
            <<< DatePickerRow("DeadlineDate") {
                $0.cell.backgroundColor = .secondarySystemGroupedBackground
                $0.cell.textLabel?.textColor = .label
                $0.cell.detailTextLabel?.textColor = .secondaryLabel
                $0.cell.backgroundColor = .secondarySystemGroupedBackground
                $0.cell.tintColor = .secondarySystemGroupedBackground
                $0.hidden = true
                $0.minuteInterval = 5
                if #available(iOS 14.0, *) {
                    $0.cell.datePicker.preferredDatePickerStyle = .inline
                    $0.cell.datePicker.tintColor = .systemBlue
                }
                else {
                    $0.cell.datePicker.datePickerMode = .date
                }
                if let task = task, let endDate = task.endDate {
                    $0.value = endDate
                    $0.updateCell()
                }
            }.onChange { [weak self] row in
                if let value = row.value, let switchDateRow: SwitchRow = self?.form.rowBy(tag: "deadlineDateSwitch") {
                    switchDateRow.cell.detailTextLabel?.text = value.getMonthAndDateAndYear()
                }
                self!.updateDeadlineDate()
            }.cellUpdate { cell, row in
                cell.backgroundColor = .secondarySystemGroupedBackground
                cell.textLabel?.textColor = .label
            }
            
            <<< SwitchRow("deadlineTimeSwitch") {
                $0.cell.backgroundColor = .secondarySystemGroupedBackground
                $0.cell.textLabel?.textColor = .label
                $0.cell.detailTextLabel?.textColor = .secondaryLabel
                $0.title = "Deadline Time"
                if let task = task, task.hasDeadlineTime ?? false, let endDate = task.endDate {
                    $0.value = true
                    $0.cell.detailTextLabel?.text = endDate.getTimeString()
                } else {
                    $0.value = false
                    $0.cell.detailTextLabel?.text = nil
                }
                if self.task.isGoal ?? false {
                    $0.hidden = Condition(booleanLiteral: self.task.recurrences != nil)
                }
            }.onChange { [weak self] row in
                if let value = row.value, let endTimeRow: TimePickerRow = self?.form.rowBy(tag: "DeadlineTime") {
                    if value, let endDateDateRow: DatePickerRow = self?.form.rowBy(tag: "DeadlineDate"), let endDateSwitchRow: SwitchRow = self?.form.rowBy(tag: "deadlineDateSwitch") {
                        row.cell.detailTextLabel?.textColor = .systemBlue
                        if let task = self?.task, task.hasDeadlineTime ?? false, let endDate = task.endDate {
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
                        endDateSwitchRow.cell.detailTextLabel?.textColor = .secondaryLabel
                        endDateSwitchRow.updateCell()
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
                    if let endTime: TimePickerRow = self?.form.rowBy(tag: "DeadlineTime"), let endDate: DatePickerRow = self?.form.rowBy(tag: "DeadlineDate"), let endDateSwitchRow: SwitchRow = self?.form.rowBy(tag: "deadlineDateSwitch") {
                        endTime.hidden = endTime.isHidden ? false : true
                        endTime.evaluateHidden()
                        if !endTime.isHidden {
                            row.cell.detailTextLabel?.textColor = .systemBlue
                            endDateSwitchRow.cell.detailTextLabel?.textColor = .secondaryLabel
                            endDateSwitchRow.updateCell()
                            endDate.hidden = true
                            endDate.evaluateHidden()
                        } else {
                            row.cell.detailTextLabel?.textColor = .secondaryLabel
                        }
                    }
                }
            }).cellUpdate { cell, row in
                cell.backgroundColor = .secondarySystemGroupedBackground
                cell.textLabel?.textColor = .label
                cell.detailTextLabel?.textColor = .secondaryLabel
                if let task = self.task, task.hasDeadlineTime ?? false, let endDate = task.endDate {
                    cell.detailTextLabel?.text = endDate.getTimeString()
                } else {
                    cell.detailTextLabel?.text = nil
                }
                if self.task.isGoal ?? false {
                    row.hidden = "$Repeat != 'Never'"
                }
            }
            
            <<< TimePickerRow("DeadlineTime") {
                $0.cell.backgroundColor = .secondarySystemGroupedBackground
                $0.cell.textLabel?.textColor = .label
                $0.cell.detailTextLabel?.textColor = .secondaryLabel
                $0.cell.backgroundColor = .secondarySystemGroupedBackground
                $0.cell.tintColor = .secondarySystemGroupedBackground
                $0.hidden = true
                $0.minuteInterval = 5
                if #available(iOS 13.4, *) {
                    $0.cell.datePicker.preferredDatePickerStyle = .wheels
                }
                else {
                    $0.cell.datePicker.datePickerMode = .time
                }
                if let task = task, task.hasDeadlineTime ?? false, let endDate = task.endDate {
                    $0.value = endDate
                    $0.updateCell()
                }
            }.onChange { [weak self] row in
                if let value = row.value, let switchDateRow: SwitchRow = self?.form.rowBy(tag: "deadlineTimeSwitch") {
                    switchDateRow.cell.detailTextLabel?.text = value.getTimeString()
                }
                self!.updateDeadlineDate()
            }.cellUpdate { cell, row in
                cell.backgroundColor = .secondarySystemGroupedBackground
                cell.textLabel?.textColor = .label
            }
            
            if !(task.isGoal ?? false) {
                form.last!
                <<< SwitchRow("Flag") { row in
                    row.cell.backgroundColor = .secondarySystemGroupedBackground
                    row.cell.textLabel?.textColor = .label
                    row.title = row.tag
                    if let flagged = task.flagged {
                        row.value = flagged
                    } else {
                        row.value = false
                        self.task.flagged = false
                    }
                }.onChange { [weak self] row in
                    self?.task.flagged = row.value
                }.cellUpdate { cell, row in
                    cell.backgroundColor = .secondarySystemGroupedBackground
                    cell.textLabel?.textColor = .label
                }
                
                <<< PushRow<TaskPriority>("Priority") { row in
                    row.cell.backgroundColor = .secondarySystemGroupedBackground
                    row.cell.textLabel?.textColor = .label
                    row.cell.detailTextLabel?.textColor = .secondaryLabel
                    row.title = row.tag
                    if let task = task, let value = task.priority {
                        row.value = TaskPriority(rawValue: value)
                    } else {
                        row.value = TaskPriority.None
                        if let priority = row.value?.rawValue {
                            self.task.priority = priority
                        }
                    }
                    row.options = TaskPriority.allCases
                }.onPresent { from, to in
                    to.extendedLayoutIncludesOpaqueBars = true
                    to.title = "Priority"
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
                    if let priority = row.value?.rawValue {
                        self.task.priority = priority
                    }
                }
            }
            
            form.last!
            
            <<< LabelRow("Repeat") { row in
                row.cell.backgroundColor = .secondarySystemGroupedBackground
                row.cell.textLabel?.textColor = .label
                row.cell.detailTextLabel?.textColor = .secondaryLabel
                row.cell.accessoryType = .disclosureIndicator
                row.cell.selectionStyle = .default
                row.title = row.tag
                if self.task.isGoal ?? false {
                    row.hidden = "$deadlineDateSwitch == true"
                } else {
                    row.hidden = "$deadlineDateSwitch == false"
                }
                if let task = task, let recurrences = task.recurrences, let recurrenceRule = RecurrenceRule(rruleString: recurrences[0]) {
                    if let endDate = self.task.instanceOriginalStartDate {
                        row.value = recurrenceRule.typeOfRecurrence(language: .english, occurrence: endDate)
                    } else if let endDate = self.task.endDate {
                        row.value = recurrenceRule.typeOfRecurrence(language: .english, occurrence: endDate)
                    }
                } else {
                    row.value = "Never"
                }
            }.onCellSelection({ _, row in
                self.openRepeat()
            }).cellUpdate { cell, row in
                cell.textLabel?.textAlignment = .left
                cell.backgroundColor = .secondarySystemGroupedBackground
                cell.textLabel?.textColor = .label
                cell.detailTextLabel?.textColor = .secondaryLabel
                cell.accessoryType = .disclosureIndicator
            }
        } else {
            form.last!
            
            <<< CheckRow("Completed") {
                $0.cell.backgroundColor = .secondarySystemGroupedBackground
                $0.cell.tintColor = FalconPalette.defaultBlue
                $0.cell.textLabel?.textColor = .label
                $0.cell.detailTextLabel?.textColor = .secondaryLabel
                $0.cell.accessoryType = .checkmark
                $0.cell.isUserInteractionEnabled = !(self.task.isGoal ?? false)
                $0.title = $0.tag
                $0.value = task.isCompleted ?? false
                if $0.value ?? false {
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
            }.onChange { row in
                self.task.isCompleted = row.value
                if row.value ?? false, let completedRow: DateTimeInlineRow = self.form.rowBy(tag: "Completed On") {
                    row.cell.tintAdjustmentMode = .automatic
                    
                    let original = Date()
                    let updateDate = Date(timeIntervalSinceReferenceDate:
                                            (original.timeIntervalSinceReferenceDate / 300.0).rounded(.toNearestOrEven) * 300.0)
                    completedRow.value = updateDate
                    completedRow.updateCell()
                    completedRow.hidden = false
                    completedRow.evaluateHidden()
                    self.task.completedDate = NSNumber(value: Int((updateDate).timeIntervalSince1970))
                    let updateTask = ActivityActions(activity: self.task, active: self.active, selectedFalconUsers: self.selectedFalconUsers)
                    updateTask.updateCompletion(isComplete: self.task.isCompleted ?? false)
                } else if let completedRow: DateTimeInlineRow = self.form.rowBy(tag: "Completed On") {
                    row.cell.tintAdjustmentMode = .dimmed
                    completedRow.value = nil
                    completedRow.updateCell()
                    completedRow.hidden = true
                    completedRow.evaluateHidden()
                    self.task.completedDate = nil
                    let updateTask = ActivityActions(activity: self.task, active: self.active, selectedFalconUsers: self.selectedFalconUsers)
                    updateTask.updateCompletion(isComplete: self.task.isCompleted ?? false)
                }
            }
            
            <<< DateTimeInlineRow("Completed On") {
                $0.cell.backgroundColor = .secondarySystemGroupedBackground
                $0.cell.textLabel?.textColor = .label
                $0.cell.detailTextLabel?.textColor = .secondaryLabel
                $0.title = $0.tag
                $0.minuteInterval = 5
                $0.dateFormatter?.dateStyle = .medium
                $0.dateFormatter?.timeStyle = .short
                if let task = task, task.isCompleted ?? false, let date = task.completedDate {
                    $0.value = Date(timeIntervalSince1970: date as! TimeInterval)
                    $0.updateCell()
                } else {
                    $0.hidden = true
                }
            }.onChange { [weak self] row in
                if let value = row.value {
                    self?.task.completedDate = NSNumber(value: Int((value).timeIntervalSince1970))
                    let updateTask = ActivityActions(activity: self!.task, active: self!.active, selectedFalconUsers: self!.selectedFalconUsers)
                    updateTask.updateCompletion(isComplete: self!.task.isCompleted ?? false)
                }
            }.onExpandInlineRow { cell, row, inlineRow in
                inlineRow.cellUpdate { (cell, row) in
                    row.cell.backgroundColor = .secondarySystemGroupedBackground
                    row.cell.tintColor = .secondarySystemGroupedBackground
                    if #available(iOS 14.0, *) {
                        cell.datePicker.preferredDatePickerStyle = .inline
                        cell.datePicker.tintColor = .systemBlue
                    }
                    else {
                        cell.datePicker.datePickerMode = .dateAndTime
                    }
                }
                cell.detailTextLabel?.textColor = cell.tintColor
            }.onCollapseInlineRow { cell, _, _ in
                cell.detailTextLabel?.textColor = .secondaryLabel
            }.cellUpdate { cell, row in
                cell.backgroundColor = .secondarySystemGroupedBackground
                cell.textLabel?.textColor = .label
            }
            
            <<< LabelRow("Description") { row in
                row.cell.backgroundColor = .secondarySystemGroupedBackground
                row.cell.textLabel?.textColor = .label
                row.cell.detailTextLabel?.textColor = .secondaryLabel
                row.cell.accessoryType = .none
                row.cell.selectionStyle = .none
                row.cell.textLabel?.numberOfLines = 0
                if let task = task, let goal = task.goal, let description = goal.description {
                    row.title = description
                    row.hidden = false
                } else {
                    row.hidden = true
                }
            }.cellUpdate { cell, row in
                cell.textLabel?.textAlignment = .left
                cell.backgroundColor = .secondarySystemGroupedBackground
                cell.textLabel?.textColor = .label
                cell.detailTextLabel?.textColor = .secondaryLabel
                cell.accessoryType = .none
            }
            
            <<< PushRow<String>("Metric") { row in
                row.cell.backgroundColor = .secondarySystemGroupedBackground
                row.cell.textLabel?.textColor = .label
                row.cell.detailTextLabel?.textColor = .secondaryLabel
                row.title = row.tag
                row.options = GoalMetric.allValues
                if let task = task, let goal = task.goal, let value = goal.metric {
                    row.value = value.rawValue
                }
//                else {
//                    row.value = GoalMetric.allValues[0]
//                    self.task.goal = Goal(name: nil, metric: GoalMetric(rawValue: GoalMetric.allValues[0]), submetric: nil, option: nil, unit: nil, targetNumber: nil, currentNumber: nil)
//                }
            }.onPresent { from, to in
                to.title = "Metrics"
                to.extendedLayoutIncludesOpaqueBars = true
                to.tableViewStyle = .insetGrouped
                to.dismissOnSelection = true
                to.dismissOnChange = true
                to.enableDeselection = false
                to.selectableRowCellUpdate = { cell, row in
                    to.tableView.separatorStyle = .none
                    to.navigationController?.navigationBar.backgroundColor = .systemGroupedBackground
                    to.tableView.backgroundColor = .systemGroupedBackground
                    cell.backgroundColor = .secondarySystemGroupedBackground
                    cell.textLabel?.textColor = .label
                    cell.detailTextLabel?.textColor = .secondaryLabel
                }
            }.cellUpdate { cell, row in
                cell.backgroundColor = .secondarySystemGroupedBackground
                cell.textLabel?.textColor = .label
                cell.detailTextLabel?.textColor = .secondaryLabel
            }.onChange { row in
                self.updateGoal(selectedGoalProperty: .metric, value: row.value)
            }
            
            <<< PushRow<String>("Submetric") { row in
                row.cell.backgroundColor = .secondarySystemGroupedBackground
                row.cell.textLabel?.textColor = .label
                row.cell.detailTextLabel?.textColor = .secondaryLabel
                row.title = row.tag
                row.options = []
                if let task = task, let goal = task.goal {
                    if let value = goal.submetric, let metric = goal.metric, metric.allValuesSubmetrics.count > 0 {
                        row.value = value.rawValue
                        row.options = metric.allValuesSubmetrics
                    } else {
                        row.hidden = true
                    }
                }
            }.onPresent { from, to in
                to.title = "Submetrics"
                to.extendedLayoutIncludesOpaqueBars = true
                to.tableViewStyle = .insetGrouped
                to.dismissOnSelection = true
                to.dismissOnChange = true
                to.enableDeselection = false
                to.selectableRowCellUpdate = { cell, row in
                    to.tableView.separatorStyle = .none
                    to.navigationController?.navigationBar.backgroundColor = .systemGroupedBackground
                    to.tableView.backgroundColor = .systemGroupedBackground
                    cell.backgroundColor = .secondarySystemGroupedBackground
                    cell.textLabel?.textColor = .label
                    cell.detailTextLabel?.textColor = .secondaryLabel
                }
            }.cellUpdate { cell, row in
                cell.backgroundColor = .secondarySystemGroupedBackground
                cell.textLabel?.textColor = .label
                cell.detailTextLabel?.textColor = .secondaryLabel
                if let options = row.options, !options.isEmpty {
                    cell.isUserInteractionEnabled = true
                } else {
                    cell.isUserInteractionEnabled = false
                }
            }.onChange { row in
                self.updateGoal(selectedGoalProperty: .submetric, value: row.value)
            }
            
            <<< MultipleSelectorRow<String>("Option") { row in
                row.cell.backgroundColor = .secondarySystemGroupedBackground
                row.cell.textLabel?.textColor = .label
                row.cell.detailTextLabel?.textColor = .secondaryLabel
                row.title = row.tag
                row.options = []
                if let task = task, let goal = task.goal, let _ = goal.metric, let options = goal.options() {
                    row.options = options
                    if let value = goal.option {
                        row.value = Set(value)
                    }
                } else {
                    row.hidden = true
                }
            }.onPresent { from, to in
                to.title = "Options"
                to.extendedLayoutIncludesOpaqueBars = true
                to.tableViewStyle = .insetGrouped
                to.selectableRowCellUpdate = { cell, row in
                    to.tableView.separatorStyle = .none
                    to.navigationController?.navigationBar.backgroundColor = .systemGroupedBackground
                    to.tableView.backgroundColor = .systemGroupedBackground
                    cell.backgroundColor = .secondarySystemGroupedBackground
                    cell.textLabel?.textColor = .label
                    cell.detailTextLabel?.textColor = .secondaryLabel
                }
            }.cellUpdate { cell, row in
                cell.backgroundColor = .secondarySystemGroupedBackground
                cell.textLabel?.textColor = .label
                cell.detailTextLabel?.textColor = .secondaryLabel
                if let options = row.options, !options.isEmpty {
                    cell.isUserInteractionEnabled = true
                } else {
                    cell.isUserInteractionEnabled = false
                }
            }.onChange { row in
                if let value = row.value, value.isEmpty, let options = row.options {
                    row.value = Set(arrayLiteral: options[0])
                } else if let value = row.value {
                    if let _ = self.task.goal {
                        self.task.goal!.option = Array(value)
                    } else {
                        self.task.goal = Goal(name: nil, metric: nil, submetric: nil, option: Array(value), unit: nil, targetNumber: nil, currentNumber: nil, frequency: nil, metricSecond: nil, submetricSecond: nil, optionSecond: nil, unitSecond: nil, targetNumberSecond: nil, currentNumberSecond: nil, metricsRelationshipType: nil)
                    }
                    self.updateDescriptionRow()
                    self.updateCategorySubCategoryRows()
                }
            }
            
            <<< PushRow<String>("Unit") { row in
                row.cell.backgroundColor = .secondarySystemGroupedBackground
                row.cell.textLabel?.textColor = .label
                row.cell.detailTextLabel?.textColor = .secondaryLabel
                row.title = row.tag
                row.options = []
                if let task = task, let goal = task.goal, let metric = goal.metric {
                    row.options = metric.allValuesUnits
                    if let value = goal.unit {
                        row.value = value.rawValue
                    } else if metric.allValuesUnits.count > 0 {
                        self.task.goal!.unit = GoalUnit(rawValue: metric.allValuesUnits[0])
                        row.value = metric.allValuesUnits[0]
                    }
                }
            }.onPresent { from, to in
                to.title = "Units"
                to.extendedLayoutIncludesOpaqueBars = true
                to.tableViewStyle = .insetGrouped
                to.dismissOnSelection = true
                to.dismissOnChange = true
                to.enableDeselection = false
                to.selectableRowCellUpdate = { cell, row in
                    to.tableView.separatorStyle = .none
                    to.navigationController?.navigationBar.backgroundColor = .systemGroupedBackground
                    to.tableView.backgroundColor = .systemGroupedBackground
                    cell.backgroundColor = .secondarySystemGroupedBackground
                    cell.textLabel?.textColor = .label
                    cell.detailTextLabel?.textColor = .secondaryLabel
                }
            }.cellUpdate { cell, row in
                cell.backgroundColor = .secondarySystemGroupedBackground
                cell.textLabel?.textColor = .label
                cell.detailTextLabel?.textColor = .secondaryLabel
                if let options = row.options, !options.isEmpty {
                    cell.isUserInteractionEnabled = true
                } else {
                    cell.isUserInteractionEnabled = false
                }
            }.onChange { row in
                if let value = row.value, let updatedValue = GoalUnit(rawValue: value) {
                    if let _ = self.task.goal {
                        if updatedValue == .percent, let number = self.task.goal!.targetNumber {
                            self.task.goal!.targetNumber = number / 100
                        }
                        self.task.goal!.unit = updatedValue
                    } else {
                        self.task.goal = Goal(name: nil, metric: nil, submetric: nil, option: nil, unit: updatedValue, targetNumber: nil, currentNumber: nil, frequency: nil, metricSecond: nil, submetricSecond: nil, optionSecond: nil, unitSecond: nil, targetNumberSecond: nil, currentNumberSecond: nil, metricsRelationshipType: nil)
                    }
                    self.updateNumberRows()
                    self.updateDescriptionRow()
                }
            }
            
            <<< DecimalRow("Target") {
                $0.cell.backgroundColor = .secondarySystemGroupedBackground
                $0.cell.textField?.textColor = .secondaryLabel
                $0.title = $0.tag
                if let task = task, let goal = task.goal, let number = goal.targetNumber {
                    $0.value = number
                }
            }.cellUpdate { cell, row in
                cell.backgroundColor = .secondarySystemGroupedBackground
                cell.textField?.textColor = .secondaryLabel
            }.onChange { row in
                if let _ = self.task.goal {
                    self.task.goal!.targetNumber = row.value
                } else {
                    self.task.goal = Goal(name: nil, metric: nil, submetric: nil, option: nil, unit: nil, targetNumber: row.value, currentNumber: nil, frequency: nil, metricSecond: nil, submetricSecond: nil, optionSecond: nil, unitSecond: nil, targetNumberSecond: nil, currentNumberSecond: nil, metricsRelationshipType: nil)
                }
                self.updateSecondTargetRow()
            }
            
            if active {
                form.last!
                <<< DecimalRow("Current") { row in
                    row.cell.backgroundColor = .secondarySystemGroupedBackground
                    row.cell.textLabel?.textColor = .label
                    row.cell.detailTextLabel?.textColor = .secondaryLabel
                    row.cell.accessoryType = .none
                    row.cell.selectionStyle = .none
                    row.cell.textLabel?.numberOfLines = 0
                    row.cell.isUserInteractionEnabled = false
                    row.title = row.tag
                    if let task = task, let goal = task.goal, let number = goal.currentNumber {
                        row.value = number
                    }
                }.cellUpdate { cell, row in
                    cell.textLabel?.textAlignment = .left
                    cell.backgroundColor = .secondarySystemGroupedBackground
                    cell.textLabel?.textColor = .label
                    cell.detailTextLabel?.textColor = .secondaryLabel
                    cell.accessoryType = .none
                }
            }
            
            form.last!
            
            <<< SwitchRow("addSecondMetric") { row in
                row.cell.backgroundColor = .secondarySystemGroupedBackground
                row.cell.textLabel?.textColor = .label
                row.title = "Add Second Metric"
                if let task = task, let goal = task.goal, let _ = goal.metricSecond {
                    row.value = true
                } else {
                    row.value = false
                }
                row.hidden = "$Metric == nil"
            }.cellUpdate { cell, row in
                cell.backgroundColor = .secondarySystemGroupedBackground
                cell.textLabel?.textColor = .label
            }.onChange({ row in
                if !(row.value ?? false), let secondMetricRow : PushRow<String> = self.form.rowBy(tag: "secondMetric"), let metricsRelationshipRow : PushRow<String> = self.form.rowBy(tag: "metricsRelationship") {
                    if self.task.goal != nil {
                        self.task.goal!.metricsRelationshipType = nil
                        self.task.goal!.metricSecond = nil
                        self.task.goal!.submetricSecond = nil
                        self.task.goal!.unitSecond = nil
                        self.task.goal!.optionSecond = nil
                        self.task.goal!.targetNumberSecond = nil
                    }
                    secondMetricRow.value = nil
                    metricsRelationshipRow.value = nil
                }
            })
            
            <<< PushRow<String>("secondMetric") { row in
                row.cell.backgroundColor = .secondarySystemGroupedBackground
                row.cell.textLabel?.textColor = .label
                row.cell.detailTextLabel?.textColor = .secondaryLabel
                row.title = "Second Metric"
                row.options = GoalMetric.allValues
                if let task = task, let goal = task.goal, let value = goal.metricSecond {
                    row.value = value.rawValue
                }
                row.hidden = "$addSecondMetric == false"
            }.onPresent { from, to in
                to.title = "Metrics"
                to.extendedLayoutIncludesOpaqueBars = true
                to.tableViewStyle = .insetGrouped
                to.dismissOnSelection = true
                to.dismissOnChange = true
                to.enableDeselection = false
                to.selectableRowCellUpdate = { cell, row in
                    to.tableView.separatorStyle = .none
                    to.navigationController?.navigationBar.backgroundColor = .systemGroupedBackground
                    to.tableView.backgroundColor = .systemGroupedBackground
                    cell.backgroundColor = .secondarySystemGroupedBackground
                    cell.textLabel?.textColor = .label
                    cell.detailTextLabel?.textColor = .secondaryLabel
                }
            }.cellUpdate { cell, row in
                cell.backgroundColor = .secondarySystemGroupedBackground
                cell.textLabel?.textColor = .label
                cell.detailTextLabel?.textColor = .secondaryLabel
            }.onChange { row in
                self.updateGoalSecondary(selectedGoalProperty: .metric, value: row.value)
            }
            
            <<< PushRow<String>("Second Submetric") { row in
                row.cell.backgroundColor = .secondarySystemGroupedBackground
                row.cell.textLabel?.textColor = .label
                row.cell.detailTextLabel?.textColor = .secondaryLabel
                row.title = row.tag
                row.options = []
                if let task = task, let goal = task.goal {
                    if let value = goal.submetricSecond, let metric = goal.metricSecond, metric.allValuesSubmetrics.count > 0 {
                        row.value = value.rawValue
                        row.options = metric.allValuesSubmetrics
                    } else {
                        row.hidden = true
                    }
                }
            }.onPresent { from, to in
                to.title = "Submetrics"
                to.extendedLayoutIncludesOpaqueBars = true
                to.tableViewStyle = .insetGrouped
                to.dismissOnSelection = true
                to.dismissOnChange = true
                to.enableDeselection = false
                to.selectableRowCellUpdate = { cell, row in
                    to.tableView.separatorStyle = .none
                    to.navigationController?.navigationBar.backgroundColor = .systemGroupedBackground
                    to.tableView.backgroundColor = .systemGroupedBackground
                    cell.backgroundColor = .secondarySystemGroupedBackground
                    cell.textLabel?.textColor = .label
                    cell.detailTextLabel?.textColor = .secondaryLabel
                }
            }.cellUpdate { cell, row in
                cell.backgroundColor = .secondarySystemGroupedBackground
                cell.textLabel?.textColor = .label
                cell.detailTextLabel?.textColor = .secondaryLabel
                if let options = row.options, !options.isEmpty {
                    cell.isUserInteractionEnabled = true
                } else {
                    cell.isUserInteractionEnabled = false
                }
            }.onChange { row in
                self.updateGoalSecondary(selectedGoalProperty: .submetric, value: row.value)
            }
            
            <<< MultipleSelectorRow<String>("Second Option") { row in
                row.cell.backgroundColor = .secondarySystemGroupedBackground
                row.cell.textLabel?.textColor = .label
                row.cell.detailTextLabel?.textColor = .secondaryLabel
                row.title = row.tag
                row.options = []
                if let task = task, let goal = task.goal, let _ = goal.metricSecond, let options = goal.optionsSecond() {
                    row.options = options
                    if let value = goal.optionSecond {
                        row.value = Set(value)
                    }
                } else {
                    row.hidden = true
                }
            }.onPresent { from, to in
                to.title = "Options"
                to.extendedLayoutIncludesOpaqueBars = true
                to.tableViewStyle = .insetGrouped
                to.selectableRowCellUpdate = { cell, row in
                    to.tableView.separatorStyle = .none
                    to.navigationController?.navigationBar.backgroundColor = .systemGroupedBackground
                    to.tableView.backgroundColor = .systemGroupedBackground
                    cell.backgroundColor = .secondarySystemGroupedBackground
                    cell.textLabel?.textColor = .label
                    cell.detailTextLabel?.textColor = .secondaryLabel
                }
            }.cellUpdate { cell, row in
                cell.backgroundColor = .secondarySystemGroupedBackground
                cell.textLabel?.textColor = .label
                cell.detailTextLabel?.textColor = .secondaryLabel
                if let options = row.options, !options.isEmpty {
                    cell.isUserInteractionEnabled = true
                } else {
                    cell.isUserInteractionEnabled = false
                }
            }.onChange { row in
                if let value = row.value, value.isEmpty, let options = row.options {
                    row.value = Set(arrayLiteral: options[0])
                } else if let value = row.value {
                    if let _ = self.task.goal {
                        self.task.goal!.optionSecond = Array(value)
                    }
                    self.updateDescriptionRow()
                }
            }
            
            <<< PushRow<String>("secondUnit") { row in
                row.cell.backgroundColor = .secondarySystemGroupedBackground
                row.cell.textLabel?.textColor = .label
                row.cell.detailTextLabel?.textColor = .secondaryLabel
                row.title = "Second Unit"
                row.options = []
                if let task = task, let goal = task.goal, let metric = goal.metricSecond {
                    row.options = metric.allValuesUnits
                    if let value = goal.unitSecond {
                        row.value = value.rawValue
                    } else if metric.allValuesUnits.count > 0 {
                        self.task.goal!.unitSecond = GoalUnit(rawValue: metric.allValuesUnits[0])
                        row.value = metric.allValuesUnits[0]
                    }
                }
                row.hidden = "$addSecondMetric == false"
            }.onPresent { from, to in
                to.title = "Units"
                to.extendedLayoutIncludesOpaqueBars = true
                to.tableViewStyle = .insetGrouped
                to.dismissOnSelection = true
                to.dismissOnChange = true
                to.enableDeselection = false
                to.selectableRowCellUpdate = { cell, row in
                    to.tableView.separatorStyle = .none
                    to.navigationController?.navigationBar.backgroundColor = .systemGroupedBackground
                    to.tableView.backgroundColor = .systemGroupedBackground
                    cell.backgroundColor = .secondarySystemGroupedBackground
                    cell.textLabel?.textColor = .label
                    cell.detailTextLabel?.textColor = .secondaryLabel
                }
            }.cellUpdate { cell, row in
                cell.backgroundColor = .secondarySystemGroupedBackground
                cell.textLabel?.textColor = .label
                cell.detailTextLabel?.textColor = .secondaryLabel
                if let options = row.options, !options.isEmpty {
                    cell.isUserInteractionEnabled = true
                } else {
                    cell.isUserInteractionEnabled = false
                }
            }.onChange { row in
                if let value = row.value, let updatedValue = GoalUnit(rawValue: value) {
                    if let _ = self.task.goal {
                        if updatedValue == .percent, let number = self.task.goal!.targetNumberSecond {
                            self.task.goal!.targetNumberSecond = number / 100
                        }
                        self.task.goal!.unitSecond = updatedValue
                    }
                }
                self.updateNumberRowsSecond()
                self.updateDescriptionRow()
            }
            
            <<< DecimalRow("Second Target") {
                $0.cell.backgroundColor = .secondarySystemGroupedBackground
                $0.cell.textField?.textColor = .secondaryLabel
                $0.title = $0.tag
                if let task = task, let goal = task.goal, let number = goal.targetNumberSecond {
                    $0.value = number
                }
                $0.hidden = "$addSecondMetric == false"
            }.cellUpdate { cell, row in
                cell.backgroundColor = .secondarySystemGroupedBackground
                cell.textField?.textColor = .secondaryLabel
            }.onChange { row in
                if let _ = self.task.goal {
                    self.task.goal!.targetNumberSecond = row.value
                }
                self.updateSecondTargetRow()
            }
            
            if active {
                form.last!
                <<< DecimalRow("Second Current") { row in
                    row.cell.backgroundColor = .secondarySystemGroupedBackground
                    row.cell.textLabel?.textColor = .label
                    row.cell.detailTextLabel?.textColor = .secondaryLabel
                    row.cell.accessoryType = .none
                    row.cell.selectionStyle = .none
                    row.cell.textLabel?.numberOfLines = 0
                    row.cell.isUserInteractionEnabled = false
                    row.title = row.tag
                    if let task = task, let goal = task.goal, let number = goal.currentNumberSecond {
                        row.value = number
                    }
                    row.hidden = "$addSecondMetric == false"
                }.cellUpdate { cell, row in
                    cell.textLabel?.textAlignment = .left
                    cell.backgroundColor = .secondarySystemGroupedBackground
                    cell.textLabel?.textColor = .label
                    cell.detailTextLabel?.textColor = .secondaryLabel
                    cell.accessoryType = .none
                }
            }
            
            form.last!
            
            <<< PushRow<String>("metricsRelationship") { row in
                row.cell.backgroundColor = .secondarySystemGroupedBackground
                row.cell.textLabel?.textColor = .label
                row.cell.detailTextLabel?.textColor = .secondaryLabel
                row.title = "Metrics Relationship"
                row.hidden = "!($addSecondMetric != false && $secondUnit != nil && $Unit != nil)"
                if let task = self.task, let goal = task.goal {
                    if let value = goal.metricsRelationshipType {
                        row.value = value.rawValue
                    }
                }
            }.onPresent { from, to in
                to.title = "Metrics Relationship"
                to.extendedLayoutIncludesOpaqueBars = true
                to.tableViewStyle = .insetGrouped
                to.dismissOnSelection = true
                to.dismissOnChange = true
                to.enableDeselection = false
                to.selectableRowCellUpdate = { cell, row in
                    to.tableView.separatorStyle = .none
                    to.navigationController?.navigationBar.backgroundColor = .systemGroupedBackground
                    to.tableView.backgroundColor = .systemGroupedBackground
                    cell.backgroundColor = .secondarySystemGroupedBackground
                    cell.textLabel?.textColor = .label
                    cell.detailTextLabel?.textColor = .secondaryLabel
                    if let task = self.task, let goal = task.goal {
                        if goal.metricsRelationshipTypes.count > 3 {
                            to.form.last?.footer = HeaderFooterView(title: MetricRelationshipFooterAll)
                        } else {
                            to.form.last?.footer = HeaderFooterView(title: MetricRelationshipFooterCertain)
                        }
                    }
                }
            }.cellUpdate { cell, row in
                cell.backgroundColor = .secondarySystemGroupedBackground
                cell.textLabel?.textColor = .label
                cell.detailTextLabel?.textColor = .secondaryLabel
                if let task = self.task, let goal = task.goal {
                    row.options = goal.metricsRelationshipTypes
                }
            }.onChange { row in
                if let value = row.value, let type = MetricsRelationshipType(rawValue: value), let _ = self.task.goal {
                    self.task.goal?.metricsRelationshipType = type
                    self.updateSecondTargetRow()
                }
            }
            
            <<< LabelRow("Repeat") { row in
                row.cell.backgroundColor = .secondarySystemGroupedBackground
                row.cell.textLabel?.textColor = .label
                row.cell.detailTextLabel?.textColor = .secondaryLabel
                row.cell.accessoryType = .disclosureIndicator
                row.cell.selectionStyle = .default
                row.title = row.tag
                if let task = task, let recurrences = task.recurrences, let recurrence = recurrences.first(where: { $0.starts(with: "RRULE") }), let recurrenceRule = RecurrenceRule(rruleString: recurrence) {
                    if let endDate = self.task.instanceOriginalStartDate {
                        row.value = recurrenceRule.typeOfRecurrence(language: .english, occurrence: endDate)
                    } else if let endDate = self.task.endDate {
                        row.value = recurrenceRule.typeOfRecurrence(language: .english, occurrence: endDate)
                    }
                } else {
                    row.value = "Never"
                }
            }.onCellSelection({ _, row in
                self.openRepeat()
            }).cellUpdate { cell, row in
                cell.textLabel?.textAlignment = .left
                cell.backgroundColor = .secondarySystemGroupedBackground
                cell.textLabel?.textColor = .label
                cell.detailTextLabel?.textColor = .secondaryLabel
                cell.accessoryType = .disclosureIndicator
                row.hidden = "$deadlineDateSwitch == true || $startDateSwitch == true"
            }
            
            <<< SwitchRow("startDateSwitch") {
                $0.cell.backgroundColor = .secondarySystemGroupedBackground
                $0.cell.textLabel?.textColor = .label
                $0.cell.detailTextLabel?.textColor = .secondaryLabel
                $0.title = "Start Date"
                if let task = task, let startDate = task.startDate {
                    $0.value = true
                    $0.cell.detailTextLabel?.text = startDate.getMonthAndDateAndYear()
                } else {
                    $0.value = false
                    $0.cell.detailTextLabel?.text = nil
                }
                $0.hidden = Condition(booleanLiteral: self.task.recurrences != nil)
            }.onChange { [weak self] row in
                if let value = row.value, let startDateRow: DatePickerRow = self?.form.rowBy(tag: "StartDate") {
                    if value, let startTime = self?.form.rowBy(tag: "StartTime") {
                        if let task = self?.task, let startDate = task.startDate {
                            row.cell.detailTextLabel?.text = startDate.getMonthAndDateAndYear()
                            startDateRow.value = startDate
                        } else {
                            let startDateTime = Date()
                            startDateRow.value = startDateTime
                            row.cell.detailTextLabel?.text = startDateTime.getMonthAndDateAndYear()
    
                        }
                        startTime.hidden = true
                        startTime.evaluateHidden()
                    } else if let startDateSwitchRow: SwitchRow = self?.form.rowBy(tag: "startTimeSwitch") {
                        row.cell.detailTextLabel?.text = nil
                        startDateSwitchRow.updateCell()
                        startDateSwitchRow.cell.detailTextLabel?.text = nil
                    }
                    self!.updateStartDate()
                    let condition: Condition = value ? false : true
                    row.disabled = condition
                    startDateRow.hidden = condition
                    startDateRow.evaluateHidden()
                }
            }.onCellSelection({ [weak self] _, row in
                if row.value ?? false {
                    if let startDate = self?.form.rowBy(tag: "StartDate"), let startTime = self?.form.rowBy(tag: "StartTime") {
                        startDate.hidden = startDate.isHidden ? false : true
                        startDate.evaluateHidden()
                        if !startDate.isHidden {
                            startTime.hidden = true
                            startTime.evaluateHidden()
                        }
                    }
                }
            }).cellUpdate { cell, row in
                cell.backgroundColor = .secondarySystemGroupedBackground
                cell.textLabel?.textColor = .label
                cell.detailTextLabel?.textColor = .secondaryLabel
                if let task = self.task, let startDate = task.startDate {
                    cell.detailTextLabel?.text = startDate.getMonthAndDateAndYear()
                }
                row.hidden = "$Repeat != 'Never'"
            }
    
            <<< DatePickerRow("StartDate") {
                $0.cell.backgroundColor = .secondarySystemGroupedBackground
                $0.cell.textLabel?.textColor = .label
                $0.cell.detailTextLabel?.textColor = .secondaryLabel
                $0.cell.backgroundColor = .secondarySystemGroupedBackground
                $0.cell.tintColor = .secondarySystemGroupedBackground
                $0.hidden = true
                $0.minuteInterval = 5
                if #available(iOS 14.0, *) {
                    $0.cell.datePicker.preferredDatePickerStyle = .inline
                    $0.cell.datePicker.tintColor = .systemBlue
                }
                else {
                    $0.cell.datePicker.datePickerMode = .date
                }
                if let task = task, let startDate = task.startDate {
                    $0.value = startDate
                    $0.updateCell()
                }
            }.onChange { [weak self] row in
                if let value = row.value, let switchDateRow: SwitchRow = self?.form.rowBy(tag: "startDateSwitch") {
                    switchDateRow.cell.detailTextLabel?.text = value.getMonthAndDateAndYear()
                }
                self!.updateStartDate()
            }.cellUpdate { cell, row in
                cell.backgroundColor = .secondarySystemGroupedBackground
                cell.textLabel?.textColor = .label
            }
    
            <<< SwitchRow("startTimeSwitch") {
                $0.cell.backgroundColor = .secondarySystemGroupedBackground
                $0.cell.textLabel?.textColor = .label
                $0.cell.detailTextLabel?.textColor = .secondaryLabel
                $0.title = "Start Time"
                $0.hidden = Condition(booleanLiteral: self.task.recurrences != nil)
                if let task = task, task.hasStartTime ?? false, let startDate = task.startDate {
                    $0.value = true
                    $0.cell.detailTextLabel?.text = startDate.getTimeString()
                } else {
                    $0.value = false
                    $0.cell.detailTextLabel?.text = nil
                }
            }.onChange { [weak self] row in
                if let value = row.value, let startTimeRow: TimePickerRow = self?.form.rowBy(tag: "StartTime") {
                    if value, let startDateDateRow = self?.form.rowBy(tag: "StartDate"), let startDateSwitchRow: SwitchRow = self?.form.rowBy(tag: "startDateSwitch") {
                        if let task = self?.task, task.hasStartTime ?? false, let startDate = task.startDate {
                            row.cell.detailTextLabel?.text = startDate.getTimeString()
                            startTimeRow.value = startDate
                            if !(startDateSwitchRow.value ?? false) {
                                startDateSwitchRow.value = value
                                startDateSwitchRow.updateCell()
                                startDateSwitchRow.cell.detailTextLabel?.text = startDate.getMonthAndDateAndYear()
                            }
                        } else {
                            let original = Date()
                            let startDate = Date(timeIntervalSinceReferenceDate:
                                                (original.timeIntervalSinceReferenceDate / 300.0).rounded(.toNearestOrEven) * 300.0)
                            startTimeRow.value = startDate
                            row.cell.detailTextLabel?.text = startDate.getTimeString()
                            if !(startDateSwitchRow.value ?? false) {
                                startDateSwitchRow.value = value
                                startDateSwitchRow.updateCell()
                                startDateSwitchRow.cell.detailTextLabel?.text = startDate.getMonthAndDateAndYear()
                            }
                        }
                        startDateDateRow.hidden = true
                        startDateDateRow.evaluateHidden()
                    } else {
                        row.cell.detailTextLabel?.text = nil
                    }
                    self!.updateStartDate()
                    let condition: Condition = value ? false : true
                    row.disabled = condition
                    startTimeRow.hidden = condition
                    startTimeRow.evaluateHidden()
                }
            }.onCellSelection({ [weak self] _, row in
                if row.value ?? false {
                    if let startTime = self?.form.rowBy(tag: "StartTime"), let startDate = self?.form.rowBy(tag: "StartDate") {
                        startTime.hidden = startTime.isHidden ? false : true
                        startTime.evaluateHidden()
                        if !startTime.isHidden {
                            startDate.hidden = true
                            startDate.evaluateHidden()
                        }
                    }
                }
            }).cellUpdate { cell, row in
                cell.backgroundColor = .secondarySystemGroupedBackground
                cell.textLabel?.textColor = .label
                cell.detailTextLabel?.textColor = .secondaryLabel
                if let task = self.task, task.hasStartTime ?? false, let startDate = task.startDate {
                    cell.detailTextLabel?.text = startDate.getTimeString()
                }
                row.hidden = "$Repeat != 'Never'"
            }
    
            <<< TimePickerRow("StartTime") {
                $0.cell.backgroundColor = .secondarySystemGroupedBackground
                $0.cell.textLabel?.textColor = .label
                $0.cell.detailTextLabel?.textColor = .secondaryLabel
                $0.cell.backgroundColor = .secondarySystemGroupedBackground
                $0.cell.tintColor = .secondarySystemGroupedBackground
                $0.hidden = true
                $0.minuteInterval = 5
                if #available(iOS 13.4, *) {
                    $0.cell.datePicker.preferredDatePickerStyle = .wheels
                }
                else {
                    $0.cell.datePicker.datePickerMode = .time
                }
                if let task = task, task.hasStartTime ?? false, let startDate = task.startDate {
                    $0.value = startDate
                    $0.updateCell()
                }
            }.onChange { [weak self] row in
                if let value = row.value, let switchDateRow: SwitchRow = self?.form.rowBy(tag: "startTimeSwitch") {
                    self?.task.startDateTime = NSNumber(value: Int((value).timeIntervalSince1970))
                    switchDateRow.cell.detailTextLabel?.text = value.getTimeString()
                }
                self!.updateStartDate()
            }.cellUpdate { cell, row in
                cell.backgroundColor = .secondarySystemGroupedBackground
                cell.textLabel?.textColor = .label
            }
                        
            <<< SwitchRow("deadlineDateSwitch") {
                $0.cell.backgroundColor = .secondarySystemGroupedBackground
                $0.cell.textLabel?.textColor = .label
                $0.cell.detailTextLabel?.textColor = .secondaryLabel
                $0.title = "Deadline Date"
                if let task = task, let endDate = task.endDate {
                    $0.value = true
                    $0.cell.detailTextLabel?.text = endDate.getMonthAndDateAndYear()
                } else {
                    $0.value = false
                    $0.cell.detailTextLabel?.text = nil
                }
                $0.hidden = Condition(booleanLiteral: self.task.recurrences != nil)
            }.onChange { [weak self] row in
                if let value = row.value, let endDateRow: DatePickerRow = self?.form.rowBy(tag: "DeadlineDate"), let endTimeSwitchRow: SwitchRow = self?.form.rowBy(tag: "deadlineTimeSwitch") {
                    if value, let endTime: TimePickerRow = self?.form.rowBy(tag: "DeadlineTime") {
                        row.cell.detailTextLabel?.textColor = .systemBlue
                        if let task = self?.task, let endDate = task.endDate {
                            row.cell.detailTextLabel?.text = endDate.getMonthAndDateAndYear()
                            endDateRow.value = endDate
                        } else {
                            let endDateTime = Date()
                            endDateRow.value = endDateTime
                            row.cell.detailTextLabel?.text = endDateTime.getMonthAndDateAndYear()
                            
                        }
                        endTimeSwitchRow.cell.detailTextLabel?.textColor = .secondaryLabel
                        endTimeSwitchRow.updateCell()
                        endTime.hidden = true
                        endTime.evaluateHidden()
                    } else {
                        row.cell.detailTextLabel?.text = nil
                        endTimeSwitchRow.cell.detailTextLabel?.text = nil
                        endTimeSwitchRow.value = false
                        endTimeSwitchRow.updateCell()
                    }
                    self!.updateDeadlineDate()
                    
                    let condition: Condition = value ? false : true
                    row.disabled = condition
                    endDateRow.hidden = condition
                    endDateRow.evaluateHidden()
                    
                }
            }.onCellSelection({ [weak self] _, row in
                if row.value ?? false {
                    if let endDate: DatePickerRow = self?.form.rowBy(tag: "DeadlineDate"), let endTime: TimePickerRow = self?.form.rowBy(tag: "DeadlineTime"), let endTimeSwitchRow: SwitchRow = self?.form.rowBy(tag: "deadlineTimeSwitch") {
                        endDate.hidden = endDate.isHidden ? false : true
                        endDate.evaluateHidden()
                        if !endDate.isHidden {
                            row.cell.detailTextLabel?.textColor = .systemBlue
                            endTimeSwitchRow.cell.detailTextLabel?.textColor = .secondaryLabel
                            endTimeSwitchRow.updateCell()
                            endTime.hidden = true
                            endTime.evaluateHidden()
                        } else {
                            row.cell.detailTextLabel?.textColor = .secondaryLabel
                        }
                    }
                }
            }).cellUpdate { cell, row in
                cell.backgroundColor = .secondarySystemGroupedBackground
                cell.textLabel?.textColor = .label
                cell.detailTextLabel?.textColor = .secondaryLabel
                if let task = self.task, let endDate = task.endDate {
                    cell.detailTextLabel?.text = endDate.getMonthAndDateAndYear()
                } else {
                    cell.detailTextLabel?.text = nil
                }
                row.hidden = "$Repeat != 'Never'"
            }
            
            <<< DatePickerRow("DeadlineDate") {
                $0.cell.backgroundColor = .secondarySystemGroupedBackground
                $0.cell.textLabel?.textColor = .label
                $0.cell.detailTextLabel?.textColor = .secondaryLabel
                $0.cell.backgroundColor = .secondarySystemGroupedBackground
                $0.cell.tintColor = .secondarySystemGroupedBackground
                $0.hidden = true
                $0.minuteInterval = 5
                if #available(iOS 14.0, *) {
                    $0.cell.datePicker.preferredDatePickerStyle = .inline
                    $0.cell.datePicker.tintColor = .systemBlue
                }
                else {
                    $0.cell.datePicker.datePickerMode = .date
                }
                if let task = task, let endDate = task.endDate {
                    $0.value = endDate
                    $0.updateCell()
                }
            }.onChange { [weak self] row in
                if let value = row.value, let switchDateRow: SwitchRow = self?.form.rowBy(tag: "deadlineDateSwitch") {
                    switchDateRow.cell.detailTextLabel?.text = value.getMonthAndDateAndYear()
                }
                self!.updateDeadlineDate()
            }.cellUpdate { cell, row in
                cell.backgroundColor = .secondarySystemGroupedBackground
                cell.textLabel?.textColor = .label
            }
            
            <<< SwitchRow("deadlineTimeSwitch") {
                $0.cell.backgroundColor = .secondarySystemGroupedBackground
                $0.cell.textLabel?.textColor = .label
                $0.cell.detailTextLabel?.textColor = .secondaryLabel
                $0.title = "Deadline Time"
                if let task = task, task.hasDeadlineTime ?? false, let endDate = task.endDate {
                    $0.value = true
                    $0.cell.detailTextLabel?.text = endDate.getTimeString()
                } else {
                    $0.value = false
                    $0.cell.detailTextLabel?.text = nil
                }
                $0.hidden = Condition(booleanLiteral: self.task.recurrences != nil)
            }.onChange { [weak self] row in
                if let value = row.value, let endTimeRow: TimePickerRow = self?.form.rowBy(tag: "DeadlineTime") {
                    if value, let endDateDateRow: DatePickerRow = self?.form.rowBy(tag: "DeadlineDate"), let endDateSwitchRow: SwitchRow = self?.form.rowBy(tag: "deadlineDateSwitch") {
                        row.cell.detailTextLabel?.textColor = .systemBlue
                        if let task = self?.task, task.hasDeadlineTime ?? false, let endDate = task.endDate {
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
                        endDateSwitchRow.cell.detailTextLabel?.textColor = .secondaryLabel
                        endDateSwitchRow.updateCell()
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
                    if let endTime: TimePickerRow = self?.form.rowBy(tag: "DeadlineTime"), let endDate: DatePickerRow = self?.form.rowBy(tag: "DeadlineDate"), let endDateSwitchRow: SwitchRow = self?.form.rowBy(tag: "deadlineDateSwitch") {
                        endTime.hidden = endTime.isHidden ? false : true
                        endTime.evaluateHidden()
                        if !endTime.isHidden {
                            row.cell.detailTextLabel?.textColor = .systemBlue
                            endDateSwitchRow.cell.detailTextLabel?.textColor = .secondaryLabel
                            endDateSwitchRow.updateCell()
                            endDate.hidden = true
                            endDate.evaluateHidden()
                        } else {
                            row.cell.detailTextLabel?.textColor = .secondaryLabel
                        }
                    }
                }
            }).cellUpdate { cell, row in
                cell.backgroundColor = .secondarySystemGroupedBackground
                cell.textLabel?.textColor = .label
                cell.detailTextLabel?.textColor = .secondaryLabel
                if let task = self.task, task.hasDeadlineTime ?? false, let endDate = task.endDate {
                    cell.detailTextLabel?.text = endDate.getTimeString()
                } else {
                    cell.detailTextLabel?.text = nil
                }
                row.hidden = "$Repeat != 'Never'"
            }
            
            <<< TimePickerRow("DeadlineTime") {
                $0.cell.backgroundColor = .secondarySystemGroupedBackground
                $0.cell.textLabel?.textColor = .label
                $0.cell.detailTextLabel?.textColor = .secondaryLabel
                $0.cell.backgroundColor = .secondarySystemGroupedBackground
                $0.cell.tintColor = .secondarySystemGroupedBackground
                $0.hidden = true
                $0.minuteInterval = 5
                if #available(iOS 13.4, *) {
                    $0.cell.datePicker.preferredDatePickerStyle = .wheels
                }
                else {
                    $0.cell.datePicker.datePickerMode = .time
                }
                if let task = task, task.hasDeadlineTime ?? false, let endDate = task.endDate {
                    $0.value = endDate
                    $0.updateCell()
                }
            }.onChange { [weak self] row in
                if let value = row.value, let switchDateRow: SwitchRow = self?.form.rowBy(tag: "deadlineTimeSwitch") {
                    switchDateRow.cell.detailTextLabel?.text = value.getTimeString()
                }
                self!.updateDeadlineDate()
            }.cellUpdate { cell, row in
                cell.backgroundColor = .secondarySystemGroupedBackground
                cell.textLabel?.textColor = .label
            }
        }
        
        if delegate == nil && !(task.isGoal ?? false) {
            form.last!
            <<< PushRow<EventAlert>("Reminder") { row in
                row.cell.backgroundColor = .secondarySystemGroupedBackground
                row.cell.textLabel?.textColor = .label
                row.cell.detailTextLabel?.textColor = .secondaryLabel
                row.title = row.tag
                row.hidden = "$deadlineDateSwitch == false"
                if let task = task, let value = task.reminder {
                    row.value = EventAlert(rawValue: value)
                } else {
                    row.value = EventAlert.None
                    if let reminder = row.value?.description {
                        self.task.reminder = reminder
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
                    self.task.reminder = reminder
                    if self.active {
                        self.scheduleReminder()
                    }
                }
            }
            
            <<< LabelRow("Participants") { row in
                row.cell.backgroundColor = .secondarySystemGroupedBackground
                row.cell.textLabel?.textColor = .label
                row.cell.detailTextLabel?.textColor = .secondaryLabel
                row.cell.accessoryType = .disclosureIndicator
                row.cell.textLabel?.textAlignment = .left
                row.cell.selectionStyle = .default
                row.title = row.tag
                row.value = String(selectedFalconUsers.count + 1)
            }.onCellSelection({ _, row in
                self.openParticipantsInviter()
            }).cellUpdate { cell, row in
                cell.accessoryType = .disclosureIndicator
                cell.backgroundColor = .secondarySystemGroupedBackground
                cell.textLabel?.textColor = .label
                cell.detailTextLabel?.textColor = .secondaryLabel
                cell.textLabel?.textAlignment = .left
            }
        }
        
        form.last!
        <<< LabelRow("List") { row in
            row.cell.backgroundColor = .secondarySystemGroupedBackground
            row.cell.textLabel?.textColor = .label
            row.cell.detailTextLabel?.textColor = .secondaryLabel
            row.cell.accessoryType = .disclosureIndicator
            row.cell.selectionStyle = .default
            row.title = row.tag
            if let task = task, task.listName != nil {
                row.value = self.task.listName
            } else {
                list = lists[ListSourceOptions.plot.name]?.first { $0.defaultList ?? false }
                row.value = list?.name ?? "Default"
            }
        }.onCellSelection({ _, row in
            self.openTaskList()
        }).cellUpdate { cell, row in
            cell.accessoryType = .disclosureIndicator
            cell.backgroundColor = .secondarySystemGroupedBackground
            cell.textLabel?.textColor = .label
            cell.detailTextLabel?.textColor = .secondaryLabel
            cell.textLabel?.textAlignment = .left
        }
        
        <<< LabelRow("Category") { row in
            row.cell.backgroundColor = .secondarySystemGroupedBackground
            row.cell.textLabel?.textColor = .label
            row.cell.detailTextLabel?.textColor = .secondaryLabel
            row.cell.accessoryType = .disclosureIndicator
            row.cell.selectionStyle = .default
            row.title = row.tag
            if let task = task, task.category != nil {
                row.value = task.category
            } else if task.isGoal ?? false,let task = task, let goal = task.goal {
                row.value = goal.category.rawValue
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
        
        <<< LabelRow("Subcategory") { row in
            row.cell.backgroundColor = .secondarySystemGroupedBackground
            row.cell.textLabel?.textColor = .label
            row.cell.detailTextLabel?.textColor = .secondaryLabel
            row.cell.accessoryType = .disclosureIndicator
            row.cell.selectionStyle = .default
            row.title = row.tag
            if let task = task, task.subcategory != nil {
                row.value = task.subcategory
            } else if task.isGoal ?? false,let task = task, let goal = task.goal {
                row.value = goal.subcategory.rawValue
            } else {
                row.value = "Uncategorized"
            }
        }.onCellSelection({ _, row in
            self.openLevel(value: row.value ?? "Uncategorized", level: "Subcategory")
        }).cellUpdate { cell, row in
            cell.accessoryType = .disclosureIndicator
            cell.backgroundColor = .secondarySystemGroupedBackground
            cell.textLabel?.textColor = .label
            cell.detailTextLabel?.textColor = .secondaryLabel
            cell.textLabel?.textAlignment = .left
        }
        
        //        if let _ = task.activityType {
        //            form.last!
        //            <<< LabelRow("Subcategory") { row in
        //                row.cell.backgroundColor = .secondarySystemGroupedBackground
        //                row.cell.textLabel?.textColor = .label
        //                row.cell.detailTextLabel?.textColor = .secondaryLabel
        //                row.cell.accessoryType = .disclosureIndicator
        //                row.cell.selectionStyle = .default
        //                row.title = row.tag
        //                if let task = task, task.activityType != "nothing" && self.task.activityType != nil {
        //                    row.value = self.task.activityType!
        //                } else {
        //                    row.value = "Uncategorized"
        //                }
        //            }.onCellSelection({ _, row in
        //                self.openLevel(value: row.value ?? "Uncategorized", level: "Subcategory")
        //            }).cellUpdate { cell, row in
        //                cell.accessoryType = .disclosureIndicator
        //                cell.backgroundColor = .secondarySystemGroupedBackground
        //                cell.textLabel?.textColor = .label
        //                cell.detailTextLabel?.textColor = .secondaryLabel
        //                cell.textLabel?.textAlignment = .left
        //            }
        //        }
        
        
        if !(task.isGoal ?? false) {
            form.last!
            <<< SwitchRow("showExtras") { row in
                row.cell.backgroundColor = .secondarySystemGroupedBackground
                row.cell.textLabel?.textColor = .label
                row.title = "Show Extras"
                if let showExtras = task.showExtras {
                    row.value = showExtras
                } else {
                    row.value = true
                    self.task.showExtras = true
                }
            }.onChange { [weak self] row in
                if !(row.value ?? false), let segmentRow : SegmentedRow<String> = self!.form.rowBy(tag: "sections") {
                    self?.segmentRowValue = segmentRow.value ?? "Health"
                    segmentRow.value = "Hidden"
                } else if let segmentRow : SegmentedRow<String> = self?.form.rowBy(tag: "sections") {
                    segmentRow.value = self?.segmentRowValue
                }
                self?.task.showExtras = row.value
                guard let currentUserID = Auth.auth().currentUser?.uid else { return }
                let userReference = Database.database().reference().child(userActivitiesEntity).child(currentUserID).child(self!.activityID).child(messageMetaDataFirebaseFolder)
                let values:[String : Any] = ["showExtras": row.value ?? false]
                userReference.updateChildValues(values)
            }.cellUpdate { cell, row in
                cell.backgroundColor = .secondarySystemGroupedBackground
                cell.textLabel?.textColor = .label
            }
            
            <<< LabelRow("Sub-Tasks") { row in
                row.cell.backgroundColor = .secondarySystemGroupedBackground
                row.cell.textLabel?.textColor = .label
                row.cell.detailTextLabel?.textColor = .secondaryLabel
                row.cell.accessoryType = .disclosureIndicator
                row.cell.selectionStyle = .default
                row.title = row.tag
                if let task = task, let subtaskIDs = task.subtaskIDs, subtaskIDs.isEmpty {
                    row.value = "0"
                } else {
                    row.value = String(self.task.subtaskIDs?.count ?? 0)
                }
                row.hidden = "$showExtras == false"
            }.onCellSelection({ _,_ in
                self.openSubtasks()
            }).cellUpdate { cell, row in
                cell.accessoryType = .disclosureIndicator
                cell.backgroundColor = .secondarySystemGroupedBackground
                cell.detailTextLabel?.textColor = .secondaryLabel
                cell.textLabel?.textAlignment = .left
                cell.textLabel?.textColor = .label
                if let task = self.task, let subtaskIDs = task.subtaskIDs, subtaskIDs.isEmpty {
                    row.value = "0"
                } else {
                    row.value = String(self.task.subtaskIDs?.count ?? 0)
                }
            }
            
            <<< LabelRow("Media") { row in
                row.cell.backgroundColor = .secondarySystemGroupedBackground
                row.cell.textLabel?.textColor = .label
                row.cell.detailTextLabel?.textColor = .secondaryLabel
                row.cell.accessoryType = .disclosureIndicator
                row.cell.selectionStyle = .default
                row.title = row.tag
                row.hidden = "$showExtras == false"
                if let task = task, let photos = task.activityPhotos, let files = task.activityFiles, photos.isEmpty, files.isEmpty {
                    row.value = "0"
                } else {
                    row.value = String((self.task.activityPhotos?.count ?? 0) + (self.task.activityFiles?.count ?? 0))
                }
            }.onCellSelection({ _,_ in
                self.openMedia()
            }).cellUpdate { cell, row in
                cell.accessoryType = .disclosureIndicator
                cell.backgroundColor = .secondarySystemGroupedBackground
                cell.detailTextLabel?.textColor = .secondaryLabel
                cell.textLabel?.textAlignment = .left
                cell.textLabel?.textColor = .label
                if let photos = self.task.activityPhotos, let files = self.task.activityFiles, photos.isEmpty, files.isEmpty {
                    row.value = "0"
                } else {
                    row.value = String((self.task.activityPhotos?.count ?? 0) + (self.task.activityFiles?.count ?? 0))
                }
            }
        }
        
        //        <<< LabelRow("Checklists") { row in
        //            row.cell.backgroundColor = .secondarySystemGroupedBackground
        //            row.cell.detailTextLabel?.textColor = .secondaryLabel
        //            row.cell.accessoryType = .disclosureIndicator
        //            row.cell.selectionStyle = .default
        //            row.cell.textLabel?.textColor = .label
        //            row.title = row.tag
        //            if let task = task, let checklistIDs = task.checklistIDs {
        //                row.value = String(checklistIDs.count)
        //            } else {
        //                row.value = "0"
        //            }
        //            row.hidden = "$showExtras == false"
        //        }.onCellSelection({ _,_ in
        //            self.openList()
        //        }).cellUpdate { cell, row in
        //            cell.accessoryType = .disclosureIndicator
        //            cell.backgroundColor = .secondarySystemGroupedBackground
        //            cell.detailTextLabel?.textColor = .secondaryLabel
        //            cell.textLabel?.textAlignment = .left
        //            cell.textLabel?.textColor = .label
        //            if let checklistIDs = self.task.checklistIDs {
        //                row.value = String(checklistIDs.count)
        //            } else {
        //                row.value = "0"
        //            }
        //        }
        
        
        //        <<< LabelRow("Tags") { row in
        //            row.cell.backgroundColor = .secondarySystemGroupedBackground
        //            row.cell.textLabel?.textColor = .label
        //            row.cell.detailTextLabel?.textColor = .secondaryLabel
        //            row.cell.accessoryType = .disclosureIndicator
        //            row.cell.selectionStyle = .default
        //            row.hidden = "$showExtras == false"
        //            row.title = row.tag
        //            if let tags = self.activity.tags, !tags.isEmpty {
        //                row.value = String(tags.count)
        //            } else {
        //                row.value = "0"
        //            }
        //        }.onCellSelection({ _, row in
        //            self.openTags()
        //        }).cellUpdate { cell, row in
        //            cell.accessoryType = .disclosureIndicator
        //            cell.backgroundColor = .secondarySystemGroupedBackground
        //            cell.detailTextLabel?.textColor = .secondaryLabel
        //            cell.textLabel?.textAlignment = .left
        //            cell.textLabel?.textColor = .label
        //            if let tags = self.task.tags, !tags.isEmpty {
        //                row.value = String(tags.count)
        //            } else {
        //                row.value = "0"
        //            }
        //        }
        
        if delegate == nil && (!active || ((task?.participantsIDs?.contains(Auth.auth().currentUser?.uid ?? "") ?? false || task?.admin == Auth.auth().currentUser?.uid))) && !(task?.isGoal ?? false) {
            form.last!
            <<< SegmentedRow<String>("sections"){
                $0.cell.backgroundColor = .secondarySystemGroupedBackground
                $0.hidden = "$showExtras == false"
                $0.options = ["Events", "Health", "Transactions"]
                if !(task.showExtras ?? true) {
                    $0.value = "Hidden"
                } else {
                    $0.value = "Events"
                }
            }.cellUpdate { cell, row in
                cell.backgroundColor = .secondarySystemGroupedBackground
                cell.textLabel?.textColor = .label
            }.onChange({ _ in
                self.sectionChanged = true
            })
            
            form +++
            MultivaluedSection(multivaluedOptions: [.Insert, .Delete],
                               header: "Events",
                               footer: "Connect an event") {
                $0.tag = "Events"
                $0.hidden = "!$sections == 'Events'"
                $0.addButtonProvider = { section in
                    return ButtonRow("scheduleButton"){
                        $0.cell.backgroundColor = .secondarySystemGroupedBackground
                        $0.title = "Connect Event"
                    }.cellUpdate { cell, row in
                        cell.backgroundColor = .secondarySystemGroupedBackground
                        cell.textLabel?.textAlignment = .left
                        cell.height = { 60 }
                    }
                }
                $0.multivaluedRowToInsertAt = { index in
                    self.eventIndex = index
                    self.openEvent()
                    return ScheduleRow("label"){ _ in
                        
                    }
                }
                
            }
            
            form +++
            MultivaluedSection(multivaluedOptions: [.Insert, .Delete],
                               header: "Health",
                               footer: "Connect a workout and/or mindfulness session") {
                $0.tag = "Health"
                $0.hidden = "$sections != 'Health'"
                $0.addButtonProvider = { section in
                    return ButtonRow(){
                        $0.cell.backgroundColor = .secondarySystemGroupedBackground
                        $0.title = "Connect Health"
                    }.cellUpdate { cell, row in
                        cell.backgroundColor = .secondarySystemGroupedBackground
                        cell.textLabel?.textAlignment = .left
                        cell.height = { 60 }
                    }
                }
                $0.multivaluedRowToInsertAt = { index in
                    self.healthIndex = index
                    self.openHealth()
                    return HealthRow()
                        .onCellSelection() { cell, row in
                            self.healthIndex = index
                            self.openHealth()
                            cell.cellResignFirstResponder()
                        }
                    
                }
                
            }
            
            form +++
            MultivaluedSection(multivaluedOptions: [.Insert, .Delete],
                               header: "Transactions",
                               footer: "Connect a transaction") {
                $0.tag = "Transactions"
                $0.hidden = "$sections != 'Transactions'"
                $0.addButtonProvider = { section in
                    return ButtonRow(){
                        $0.cell.backgroundColor = .secondarySystemGroupedBackground
                        $0.title = "Connect Transaction"
                    }.cellUpdate { cell, row in
                        cell.backgroundColor = .secondarySystemGroupedBackground
                        cell.textLabel?.textAlignment = .left
                        cell.height = { 60 }
                    }
                }
                $0.multivaluedRowToInsertAt = { index in
                    self.purchaseIndex = index
                    self.openPurchases()
                    return PurchaseRow()
                        .onCellSelection() { cell, row in
                            self.purchaseIndex = index
                            self.openPurchases()
                            cell.cellResignFirstResponder()
                        }
                    
                }
            }
        }
        
        //                                    form +++
        //                                        Section(header: "Balances",
        //                                                footer: "Positive Balance = Owe; Negative Balance = Owed") {
        //                                                    $0.tag = "Balances"
        //                                                    $0.hidden = "$sections != 'Transactions'"
        //                                    }
    }
    
    override func sectionsHaveBeenAdded(_ sections: [Section], at indexes: IndexSet) {
        super.sectionsHaveBeenAdded(sections, at: indexes)
        if sectionChanged, let section = indexes.first {
            let row = tableView.numberOfRows(inSection: section) - 1
            let indexPath = IndexPath(row: row, section: section)
            DispatchQueue.main.async {
                self.tableView?.scrollToRow(at: indexPath, at: .bottom, animated: false)
            }
            sectionChanged = false
        }
    }
    
    override func rowsHaveBeenRemoved(_ rows: [BaseRow], at indexes: [IndexPath]) {
        super.rowsHaveBeenRemoved(rows, at: indexes)
        let rowNumber : Int = indexes.first!.row
        let row = rows[0].self
        
        DispatchQueue.main.async { [weak self] in
            if row is ScheduleRow {
                if self!.eventList.indices.contains(rowNumber) {
                    let item = self!.eventList[rowNumber]
                    self!.eventList.remove(at: rowNumber)
                    self!.updateLists(type: "container")
                    ContainerFunctions.deleteStuffInside(type: .activity, ID: item.activityID ?? "")
                }
            }
            else if row is PurchaseRow {
                if self!.purchaseList.indices.contains(rowNumber) {
                    let item = self!.purchaseList[rowNumber]
                    self!.purchaseList.remove(at: rowNumber)
                    self!.updateLists(type: "container")
                    //                    self!.purchaseBreakdown()
                    ContainerFunctions.deleteStuffInside(type: .transaction, ID: item.guid)
                }
            }
            else if row is HealthRow {
                if self!.healthList.indices.contains(rowNumber)  {
                    let item = self!.healthList[rowNumber]
                    self!.healthList.remove(at: rowNumber)
                    self!.updateLists(type: "container")
                    ContainerFunctions.deleteStuffInside(type: item.type, ID: item.ID)
                }
            }
        }
    }
}
