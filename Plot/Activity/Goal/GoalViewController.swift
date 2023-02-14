//
//  GoalViewController.swift
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

class GoalViewController: FormViewController, ObjectDetailShowing {
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
            title = "Goal"
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
            title = "New Goal"
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
                }
            }
        }
        
        setupRightBarButton()
        initializeForm()
        updateRightBarButton()
        
        if let goal = task.goal, let _ = goal.metric {
            self.updateDescriptionRow()
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
        
        if active {
            
            form.last!
            
            <<< CheckRow("Completed") {
                $0.cell.backgroundColor = .secondarySystemGroupedBackground
                $0.cell.tintColor = FalconPalette.defaultBlue
                $0.cell.textLabel?.textColor = .label
                $0.cell.detailTextLabel?.textColor = .secondaryLabel
                $0.cell.accessoryType = .checkmark
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
                if row.value ?? false, let completedRow: DateTimeInlineRow = self.form.rowBy(tag: "Completed On"), let goal = self.task.goal {
                    row.cell.tintAdjustmentMode = .automatic
                    
                    let original = Date()
                    let updateDate = Date(timeIntervalSinceReferenceDate:
                                            (original.timeIntervalSinceReferenceDate / 300.0).rounded(.toNearestOrEven) * 300.0)
                    completedRow.value = updateDate
                    completedRow.updateCell()
                    completedRow.hidden = false
                    completedRow.evaluateHidden()
                    self.task.completedDate = NSNumber(value: Int((updateDate).timeIntervalSince1970))
                    let goalCurrentNumber = goal.currentNumber ?? 0 > goal.targetNumber ?? 0 ? goal.currentNumber ?? 0 : goal.targetNumber ?? 0
                    let goalCurrentNumberSecond = goal.currentNumberSecond ?? 0 > goal.targetNumberSecond ?? 0 ? goal.currentNumberSecond ?? 0 : goal.targetNumberSecond ?? 0
                    let updateTask = ActivityActions(activity: self.task, active: self.active, selectedFalconUsers: self.selectedFalconUsers)
                    updateTask.updateCompletion(isComplete: self.task.isCompleted ?? false, goalCurrentNumber: goalCurrentNumber as NSNumber, goalCurrentNumberSecond: goalCurrentNumberSecond as NSNumber)
                } else if let completedRow: DateTimeInlineRow = self.form.rowBy(tag: "Completed On") {
                    row.cell.tintAdjustmentMode = .dimmed
                    completedRow.value = nil
                    completedRow.updateCell()
                    completedRow.hidden = true
                    completedRow.evaluateHidden()
                    self.task.completedDate = nil
                    let updateTask = ActivityActions(activity: self.task, active: self.active, selectedFalconUsers: self.selectedFalconUsers)
                    updateTask.updateCompletion(isComplete: self.task.isCompleted ?? false, goalCurrentNumber: nil, goalCurrentNumberSecond: nil)
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
            
            
            
        }
        
        form.last!
        
        <<< LabelRow("Description") { row in
            row.cell.backgroundColor = .secondarySystemGroupedBackground
            row.cell.textLabel?.textColor = .label
            row.cell.detailTextLabel?.textColor = .secondaryLabel
            row.cell.accessoryType = .none
            row.cell.selectionStyle = .none
            row.cell.textLabel?.numberOfLines = 0
            if let task = task, let goal = task.goal, let _ = goal.description {
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
                self.task.goal = Goal(name: nil, metric: nil, submetric: nil, option: nil, unit: nil, period: nil, targetNumber: row.value, currentNumber: nil, frequency: nil, metricSecond: nil, submetricSecond: nil, optionSecond: nil, unitSecond: nil, periodSecond: nil, targetNumberSecond: nil, currentNumberSecond: nil, metricsRelationshipType: nil)
            }
            self.updateSecondTargetRow()
        }
        
        if active {
            form.last!
            <<< DecimalRow("Current") { row in
                row.cell.backgroundColor = .secondarySystemGroupedBackground
                row.cell.textField?.textColor = .secondaryLabel
                row.cell.selectionStyle = .none
                row.cell.isUserInteractionEnabled = false
                row.title = row.tag
                if let task = task, let goal = task.goal, let number = goal.currentNumber {
                    row.value = number
                }
            }.cellUpdate { cell, row in
                cell.backgroundColor = .secondarySystemGroupedBackground
                cell.textField?.textColor = .secondaryLabel
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
                    self.task.goal!.periodSecond = nil
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
        
//            <<< PushRow<String>("Second Period") { row in
//                row.cell.backgroundColor = .secondarySystemGroupedBackground
//                row.cell.textLabel?.textColor = .label
//                row.cell.detailTextLabel?.textColor = .secondaryLabel
//                row.title = row.tag
//                row.options = GoalPeriod.allValues
//                if let task = task, let goal = task.goal, let metric = goal.metricSecond, metric != .financialAccounts, let value = goal.periodSecond {
//                    row.value = value.rawValue
//                } else {
//                    row.hidden = true
//                }
//            }.onPresent { from, to in
//                to.title = "Period"
//                to.extendedLayoutIncludesOpaqueBars = true
//                to.tableViewStyle = .insetGrouped
//                to.dismissOnSelection = true
//                to.dismissOnChange = true
//                to.enableDeselection = false
//                to.selectableRowCellUpdate = { cell, row in
//                    to.tableView.separatorStyle = .none
//                    to.navigationController?.navigationBar.backgroundColor = .systemGroupedBackground
//                    to.tableView.backgroundColor = .systemGroupedBackground
//                    cell.backgroundColor = .secondarySystemGroupedBackground
//                    cell.textLabel?.textColor = .label
//                    cell.detailTextLabel?.textColor = .secondaryLabel
//                }
//            }.cellUpdate { cell, row in
//                cell.backgroundColor = .secondarySystemGroupedBackground
//                cell.textLabel?.textColor = .label
//                cell.detailTextLabel?.textColor = .secondaryLabel
//                if let options = row.options, !options.isEmpty {
//                    cell.isUserInteractionEnabled = true
//                } else {
//                    cell.isUserInteractionEnabled = false
//                }
//            }.onChange { row in
//                if let value = row.value, let updatedValue = GoalPeriod(rawValue: value) {
//                    if let _ = self.task.goal {
//                        self.task.goal!.periodSecond = updatedValue
//                    }
//                    self.updateDescriptionRow()
//                }
//            }
        
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
                row.cell.textField?.textColor = .secondaryLabel
                row.cell.selectionStyle = .none
                row.cell.isUserInteractionEnabled = false
                row.title = row.tag
                if let task = task, let goal = task.goal, let number = goal.currentNumberSecond {
                    row.value = number
                }
                row.hidden = "$addSecondMetric == false"
            }.cellUpdate { cell, row in
                cell.backgroundColor = .secondarySystemGroupedBackground
                cell.textField?.textColor = .secondaryLabel
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
            }
            self.updateSecondTargetRow()
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
        
//            <<< PushRow<String>("Period") { row in
//                row.cell.backgroundColor = .secondarySystemGroupedBackground
//                row.cell.textLabel?.textColor = .label
//                row.cell.detailTextLabel?.textColor = .secondaryLabel
//                row.title = "Measurement Period"
//                row.options = GoalPeriod.allValues
//                if let task = task, let goal = task.goal, let value = goal.period {
//                    row.value = value.rawValue
//                } else {
//                    row.value = "None"
//                }
//                row.hidden = Condition(booleanLiteral: !(self.task.recurrences == nil && self.task.startDate == nil))
//            }.onPresent { from, to in
//                to.title = "Measurement Period"
//                to.extendedLayoutIncludesOpaqueBars = true
//                to.tableViewStyle = .insetGrouped
//                to.dismissOnSelection = true
//                to.dismissOnChange = true
//                to.enableDeselection = false
//                to.selectableRowCellUpdate = { cell, row in
//                    to.tableView.separatorStyle = .none
//                    to.navigationController?.navigationBar.backgroundColor = .systemGroupedBackground
//                    to.tableView.backgroundColor = .systemGroupedBackground
//                    cell.backgroundColor = .secondarySystemGroupedBackground
//                    cell.textLabel?.textColor = .label
//                    cell.detailTextLabel?.textColor = .secondaryLabel
//                }
//            }.cellUpdate { cell, row in
//                cell.backgroundColor = .secondarySystemGroupedBackground
//                cell.textLabel?.textColor = .label
//                cell.detailTextLabel?.textColor = .secondaryLabel
//                if let options = row.options, !options.isEmpty {
//                    cell.isUserInteractionEnabled = true
//                } else {
//                    cell.isUserInteractionEnabled = false
//                }
//                row.hidden = "!($Repeat == 'Never' && $startDateSwitch == false)"
//            }.onChange { row in
//                if let value = row.value, let updatedValue = GoalPeriod(rawValue: value), updatedValue != .none {
//                    if let _ = self.task.goal {
//                        self.task.goal!.period = updatedValue
//                    }
//                    self.updateDescriptionRow()
//                } else {
//                    self.task.goal!.period = nil
//                    row.value = "None"
//                }
//            }
        
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
            $0.hidden = Condition(booleanLiteral: !(self.task.recurrences == nil && (self.task.goal?.metric != .financialAccounts || (self.task.goal?.metricSecond != nil && self.task.goal?.metricSecond != .financialAccounts))))
//                && !(self.task.goal?.metric != .financialAccounts || self.task.goal?.metricSecond != .financialAccounts)
//                !(self.task.recurrences == nil)
        }.onChange { [weak self] row in
            if let value = row.value, let startDateRow: DatePickerRow = self?.form.rowBy(tag: "StartDate") {
                if value {
                    row.cell.detailTextLabel?.textColor = .systemBlue
                    if let task = self?.task, let startDate = task.startDate {
                        row.cell.detailTextLabel?.text = startDate.getMonthAndDateAndYear()
                        startDateRow.value = startDate
                    } else {
                        let startDateTime = Date()
                        startDateRow.value = startDateTime
                        row.cell.detailTextLabel?.text = startDateTime.getMonthAndDateAndYear()

                    }
                } else {
                    row.cell.detailTextLabel?.text = nil
                }
                self!.updateStartDateGoal()

                let condition: Condition = value ? false : true
                row.disabled = condition
                startDateRow.hidden = condition
                startDateRow.evaluateHidden()

            }
        }.onCellSelection({ [weak self] _, row in
            if row.value ?? false {
                if let startDate: DatePickerRow = self?.form.rowBy(tag: "StartDate") {
                    startDate.hidden = startDate.isHidden ? false : true
                    startDate.evaluateHidden()
                    if !startDate.isHidden {
                        row.cell.detailTextLabel?.textColor = .systemBlue
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
            row.hidden = "!($Repeat == 'Never' && ($Metric != 'Financial Accounts' || ($secondMetric != nil && $secondMetric != 'Financial Accounts')))"
//                 && !($Metric != 'Financial Accounts' || $secondMetric != 'Financial Accounts')
//                !($Repeat == 'Never')
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
            self!.updateStartDateGoal()
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
            if let value = row.value, let endDateRow: DatePickerRow = self?.form.rowBy(tag: "DeadlineDate") {
                if value {
                    row.cell.detailTextLabel?.textColor = .systemBlue
                    if let task = self?.task, let endDate = task.endDate {
                        row.cell.detailTextLabel?.text = endDate.getMonthAndDateAndYear()
                        endDateRow.value = endDate
                    } else {
                        let endDateTime = Date()
                        endDateRow.value = endDateTime
                        row.cell.detailTextLabel?.text = endDateTime.getMonthAndDateAndYear()

                    }
                } else {
                    row.cell.detailTextLabel?.text = nil
                }
                self!.updateDeadlineDateGoal()

                let condition: Condition = value ? false : true
                row.disabled = condition
                endDateRow.hidden = condition
                endDateRow.evaluateHidden()

            }
        }.onCellSelection({ [weak self] _, row in
            if row.value ?? false {
                if let endDate: DatePickerRow = self?.form.rowBy(tag: "DeadlineDate") {
                    endDate.hidden = endDate.isHidden ? false : true
                    endDate.evaluateHidden()
                    if !endDate.isHidden {
                        row.cell.detailTextLabel?.textColor = .systemBlue
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
            self!.updateDeadlineDateGoal()
        }.cellUpdate { cell, row in
            cell.backgroundColor = .secondarySystemGroupedBackground
            cell.textLabel?.textColor = .label
        }
            
        
//        if delegate == nil && !(task.isGoal ?? false) {
//            form.last!
//            <<< PushRow<EventAlert>("Reminder") { row in
//                row.cell.backgroundColor = .secondarySystemGroupedBackground
//                row.cell.textLabel?.textColor = .label
//                row.cell.detailTextLabel?.textColor = .secondaryLabel
//                row.title = row.tag
//                row.hidden = "$deadlineDateSwitch == false"
//                if let task = task, let value = task.reminder {
//                    row.value = EventAlert(rawValue: value)
//                } else {
//                    row.value = EventAlert.None
//                    if let reminder = row.value?.description {
//                        self.task.reminder = reminder
//                    }
//                }
//                row.options = EventAlert.allCases
//            }.onPresent { from, to in
//                to.title = "Reminder"
//                to.extendedLayoutIncludesOpaqueBars = true
//                to.tableViewStyle = .insetGrouped
//                to.selectableRowCellUpdate = { cell, row in
//                    to.navigationController?.navigationBar.backgroundColor = .systemGroupedBackground
//                    to.tableView.backgroundColor = .systemGroupedBackground
//                    to.tableView.separatorStyle = .none
//                    cell.backgroundColor = .secondarySystemGroupedBackground
//                    cell.textLabel?.textColor = .label
//                    cell.detailTextLabel?.textColor = .secondaryLabel
//                }
//            }.cellUpdate { cell, row in
//                cell.backgroundColor = .secondarySystemGroupedBackground
//                cell.textLabel?.textColor = .label
//                cell.detailTextLabel?.textColor = .secondaryLabel
//            }.onChange() { [unowned self] row in
//                if let reminder = row.value?.description {
//                    self.task.reminder = reminder
//                    if self.active {
//                        self.scheduleReminder()
//                    }
//                }
//            }
//
//            <<< LabelRow("Participants") { row in
//                row.cell.backgroundColor = .secondarySystemGroupedBackground
//                row.cell.textLabel?.textColor = .label
//                row.cell.detailTextLabel?.textColor = .secondaryLabel
//                row.cell.accessoryType = .disclosureIndicator
//                row.cell.textLabel?.textAlignment = .left
//                row.cell.selectionStyle = .default
//                row.title = row.tag
//                row.value = String(selectedFalconUsers.count + 1)
//            }.onCellSelection({ _, row in
//                self.openParticipantsInviter()
//            }).cellUpdate { cell, row in
//                cell.accessoryType = .disclosureIndicator
//                cell.backgroundColor = .secondarySystemGroupedBackground
//                cell.textLabel?.textColor = .label
//                cell.detailTextLabel?.textColor = .secondaryLabel
//                cell.textLabel?.textAlignment = .left
//            }
//        }
        
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
            } else if let task = task, let goal = task.goal {
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
            } else if let task = task, let goal = task.goal {
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
        
//        if delegate == nil && (!active || ((task?.participantsIDs?.contains(Auth.auth().currentUser?.uid ?? "") ?? false || task?.admin == Auth.auth().currentUser?.uid))) {
//            form.last!
//            <<< SegmentedRow<String>("sections"){
//                $0.cell.backgroundColor = .secondarySystemGroupedBackground
//                $0.hidden = "$showExtras == false"
//                $0.options = ["Events", "Health", "Transactions"]
//                if !(task.showExtras ?? true) {
//                    $0.value = "Hidden"
//                } else {
//                    $0.value = "Events"
//                }
//            }.cellUpdate { cell, row in
//                cell.backgroundColor = .secondarySystemGroupedBackground
//                cell.textLabel?.textColor = .label
//            }.onChange({ _ in
//                self.sectionChanged = true
//            })
//
//            form +++
//            MultivaluedSection(multivaluedOptions: [.Insert, .Delete],
//                               header: "Events",
//                               footer: "Connect an event") {
//                $0.tag = "Events"
//                $0.hidden = "!$sections == 'Events'"
//                $0.addButtonProvider = { section in
//                    return ButtonRow("scheduleButton"){
//                        $0.cell.backgroundColor = .secondarySystemGroupedBackground
//                        $0.title = "Connect Event"
//                    }.cellUpdate { cell, row in
//                        cell.backgroundColor = .secondarySystemGroupedBackground
//                        cell.textLabel?.textAlignment = .left
//                        cell.height = { 60 }
//                    }
//                }
//                $0.multivaluedRowToInsertAt = { index in
//                    self.eventIndex = index
//                    self.openEvent()
//                    return ScheduleRow("label"){ _ in
//
//                    }
//                }
//
//            }
//
//            form +++
//            MultivaluedSection(multivaluedOptions: [.Insert, .Delete],
//                               header: "Health",
//                               footer: "Connect a workout and/or mindfulness session") {
//                $0.tag = "Health"
//                $0.hidden = "$sections != 'Health'"
//                $0.addButtonProvider = { section in
//                    return ButtonRow(){
//                        $0.cell.backgroundColor = .secondarySystemGroupedBackground
//                        $0.title = "Connect Health"
//                    }.cellUpdate { cell, row in
//                        cell.backgroundColor = .secondarySystemGroupedBackground
//                        cell.textLabel?.textAlignment = .left
//                        cell.height = { 60 }
//                    }
//                }
//                $0.multivaluedRowToInsertAt = { index in
//                    self.healthIndex = index
//                    self.openHealth()
//                    return HealthRow()
//                        .onCellSelection() { cell, row in
//                            self.healthIndex = index
//                            self.openHealth()
//                            cell.cellResignFirstResponder()
//                        }
//
//                }
//
//            }
//
//            form +++
//            MultivaluedSection(multivaluedOptions: [.Insert, .Delete],
//                               header: "Transactions",
//                               footer: "Connect a transaction") {
//                $0.tag = "Transactions"
//                $0.hidden = "$sections != 'Transactions'"
//                $0.addButtonProvider = { section in
//                    return ButtonRow(){
//                        $0.cell.backgroundColor = .secondarySystemGroupedBackground
//                        $0.title = "Connect Transaction"
//                    }.cellUpdate { cell, row in
//                        cell.backgroundColor = .secondarySystemGroupedBackground
//                        cell.textLabel?.textAlignment = .left
//                        cell.height = { 60 }
//                    }
//                }
//                $0.multivaluedRowToInsertAt = { index in
//                    self.purchaseIndex = index
//                    self.openPurchases()
//                    return PurchaseRow()
//                        .onCellSelection() { cell, row in
//                            self.purchaseIndex = index
//                            self.openPurchases()
//                            cell.cellResignFirstResponder()
//                        }
//
//                }
//            }
//        }
        
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
