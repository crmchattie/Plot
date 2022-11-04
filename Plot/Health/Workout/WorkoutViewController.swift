//
//  WorkoutViewController.swift
//  Plot
//
//  Created by Cory McHattie on 11/9/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import UIKit
import Eureka
import SplitRow
import Firebase
import CodableFirebase
import HealthKit

protocol UpdateWorkoutDelegate: AnyObject {
    func updateWorkout(workout: Workout)
}

class WorkoutViewController: FormViewController, ObjectDetailShowing {    
    var workout: Workout!
    var container: Container!
    var eventList = [Activity]()
    var purchaseList = [Transaction]()
    var taskList = [Activity]()
    var eventIndex: Int = 0
    var purchaseIndex: Int = 0
    var taskIndex: Int = 0
    
    lazy var users: [User] = networkController.userService.users
    lazy var filteredUsers: [User] = networkController.userService.users
    lazy var tasks: [Activity] = networkController.activityService.tasks
    lazy var events: [Activity] = networkController.activityService.events
    lazy var transactions: [Transaction] = networkController.financeService.transactions
    
    var selectedFalconUsers = [User]()
    var participants = [String : [User]]()
    
    let numberFormatter = NumberFormatter()
    
    var template: Template!
    
    //added for WorkoutViewController
    var movingBackwards: Bool = false
    var active: Bool = false
    var sectionChanged: Bool = false
    
    weak var delegate : UpdateWorkoutDelegate?
    weak var updateDiscoverDelegate : UpdateDiscover?
    
    var networkController: NetworkController
    
    init(networkController: NetworkController) {
        self.networkController = networkController
        super.init(style: .insetGrouped)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.isNavigationBarHidden = false
        navigationController?.navigationBar.isHidden = false
        navigationItem.largeTitleDisplayMode = .never
        
        numberFormatter.numberStyle = .decimal
        numberFormatter.maximumFractionDigits = 1
        
        if workout != nil {
            title = "Workout"
            active = true
            print(workout.id)

            setupLists()
            resetBadgeForSelf()
        } else {
            title = "New Workout"
            if let currentUserID = Auth.auth().currentUser?.uid {
                let ID = Database.database().reference().child(userWorkoutsEntity).child(currentUserID).childByAutoId().key ?? ""
                if let template = template {
                    workout = Workout(fromTemplate: template)
                    workout.id = ID
                } else {
                    workout = Workout(id: ID, name: "Name", admin: currentUserID, lastModifiedDate: Date(), createdDate: Date(), type: nil, startDateTime: nil, endDateTime: nil, length: nil, totalEnergyBurned: nil, user_created: true, directAssociation: true, directAssociationType: .event)
                    //need to fix; sloppy code that is used to stop an event from being created
                    if let container = container {
                        workout.containerID = container.id
                    }
                }
            }
        }
        configureTableView()
        setupRightBarButton()
        initializeForm()
        updateLength()
        
        if active {
            if !(workout.user_created ?? false) {
                for row in form.allRows {
                    if row.tag != "sections" && row.tag != "Tasks" && row.tag != "Events" && row.tag != "Transactions" && row.tag != "taskButton" && row.tag != "scheduleButton" && row.tag != "transactionButton" && row.tag != "Participants" && row.tag != "Body Weight" && row.tag != "Name" {
                        row.baseCell.isUserInteractionEnabled = false
                    }
                    if workout.hkSampleID == nil && row.tag == "Calories Burned"  {
                        row.baseCell.isUserInteractionEnabled = true
                    }
                }
            }
            if workout.hkSampleID == nil, let section = form.first  {
                section.footer?.title = "Hit the done button in the upper right corner to add to the health app if connected"
            }
        } else {
            if delegate == nil, let section = form.first {
                section.footer?.title = "This workout will be added to the health app if connected and will create an associated event as well"
            }
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        if movingBackwards {
            self.delegate?.updateWorkout(workout: workout)
        }
    }
    
    fileprivate func configureTableView() {
        tableView.allowsMultipleSelectionDuringEditing = false
        view.backgroundColor = .systemGroupedBackground
        tableView.indicatorStyle = .default
        tableView.backgroundColor = view.backgroundColor
        extendedLayoutIncludesOpaqueBars = true
        edgesForExtendedLayout = UIRectEdge.top
        tableView.separatorStyle = .none
        definesPresentationContext = true
        navigationOptions = .Disabled
    }
    
    func setupRightBarButton() {
        if !active {
            let plusBarButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(create))
            navigationItem.rightBarButtonItem = plusBarButton
        } else if delegate != nil {
            let plusBarButton =  UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(create))
            navigationItem.rightBarButtonItem = plusBarButton
        } else if workout.user_created ?? false {
            let dotsImage = UIImage(named: "dots")
            let plusBarButton =  UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(create))
            let dotsBarButton = UIBarButtonItem(image: dotsImage, style: .plain, target: self, action: #selector(goToExtras))
            navigationItem.rightBarButtonItems = [plusBarButton, dotsBarButton]
        }
        if navigationItem.leftBarButtonItem != nil {
            navigationItem.leftBarButtonItem?.action = #selector(cancel)
        }

    }
    
    @IBAction func cancel(_ sender: AnyObject) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @objc fileprivate func create() {
        showActivityIndicator()
        self.updateListsFirebase()
        let createNewWorkout = WorkoutActions(workout: self.workout, active: self.active, selectedFalconUsers: self.selectedFalconUsers)
        createNewWorkout.createNewWorkout(updateDirectAssociation: true)
        self.delegate?.updateWorkout(workout: self.workout)
        self.hideActivityIndicator()
        if let updateDiscoverDelegate = self.updateDiscoverDelegate {
            updateDiscoverDelegate.itemCreated(title: workoutCreatedMessage)
            if self.navigationItem.leftBarButtonItem != nil {
                self.dismiss(animated: true, completion: nil)
            } else {
                self.navigationController?.popViewController(animated: true)
            }
        } else {
            if self.navigationItem.leftBarButtonItem != nil {
                self.dismiss(animated: true, completion: nil)
            } else {
                self.navigationController?.popViewController(animated: true)
            }

            if !active {
                basicAlert(title: workoutCreatedMessage, message: nil, controller: self.tabBarController)
            } else {
                basicAlert(title: workoutUpdatedMessage, message: nil, controller: self.tabBarController)
            }
        }
        if active && false {
            let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            
            alert.addAction(UIAlertAction(title: "Update Workout", style: .default, handler: { (_) in
                print("User click Approve button")
                
                // update
                self.showActivityIndicator()
                self.updateLists()
                let createWorkout = WorkoutActions(workout: self.workout, active: self.active, selectedFalconUsers: self.selectedFalconUsers)
                createWorkout.createNewWorkout(updateDirectAssociation: true)
                self.hideActivityIndicator()
                if self.navigationItem.leftBarButtonItem != nil {
                    self.dismiss(animated: true, completion: nil)
                } else {
                    self.navigationController?.popViewController(animated: true)
                }
                
            }))
            
            alert.addAction(UIAlertAction(title: "Duplicate Workout", style: .default, handler: { (_) in
                print("User click Approve button")
                // create new workout with updated time
                guard self.currentReachabilityStatus != .notReachable else {
                    basicErrorAlertWithClose(title: basicErrorTitleForAlert, message: noInternetError, controller: self)
                    return
                }
                
                if let currentUserID = Auth.auth().currentUser?.uid {
                    self.showActivityIndicator()
                    self.updateLists()
                    let createWorkout = WorkoutActions(workout: self.workout, active: self.active, selectedFalconUsers: self.selectedFalconUsers)
                    createWorkout.createNewWorkout(updateDirectAssociation: true)
                    
                    //duplicate workout
                    let newWorkoutID = Database.database().reference().child(userWorkoutsEntity).child(currentUserID).childByAutoId().key ?? ""
                    var newWorkout = self.workout!
                    newWorkout.id = newWorkoutID
                    newWorkout.admin = currentUserID
                    newWorkout.participantsIDs = nil
                    
                    let createNewWorkout = WorkoutActions(workout: newWorkout, active: false, selectedFalconUsers: [])
                    createNewWorkout.createNewWorkout(updateDirectAssociation: false)
                    self.hideActivityIndicator()
                    
                    if self.navigationItem.leftBarButtonItem != nil {
                        self.dismiss(animated: true, completion: nil)
                    } else {
                        self.navigationController?.popViewController(animated: true)
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
    }
    
    @objc func goToExtras() {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "Delete Workout", style: .default, handler: { (_) in
            self.delete()
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (_) in
            print("User click Dismiss button")
        }))
        
        self.present(alert, animated: true, completion: {
            print("completion block")
        })
        print("shareButtonTapped")
        
    }
    
    func delete() {
        let alert = UIAlertController(title: nil, message: "Are you sure?", preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { (_) in
            self.showActivityIndicator()
            let workoutAction = WorkoutActions(workout: self.workout, active: self.active, selectedFalconUsers: self.selectedFalconUsers)
            workoutAction.deleteWorkout(updateDirectAssociation: true)
            self.hideActivityIndicator()
            if self.navigationItem.leftBarButtonItem != nil {
                self.dismiss(animated: true, completion: nil)
            } else {
                self.navigationController?.popViewController(animated: true)
            }
            basicAlert(title: workoutDeletedMessage, message: nil, controller: self.tabBarController)
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (_) in
            print("User click Dismiss button")
        }))
        
        self.present(alert, animated: true, completion: {
            print("completion block")
        })
    }
    
    func initializeForm() {
        print("initializing form")
        form +++
        Section(footer: "")
        //"Calories burned is based on estimates and subject to error as a result"
        
        <<< TextRow("Name") {
            $0.cell.backgroundColor = .secondarySystemGroupedBackground
            $0.cell.textField?.textColor = .label
            $0.placeholderColor = .secondaryLabel
            $0.placeholder = $0.tag
            if let workout = workout, workout.name != "Name" {
                self.navigationItem.rightBarButtonItem?.isEnabled = true
                $0.value = workout.name
            } else {
                self.navigationItem.rightBarButtonItem?.isEnabled = false
//                $0.cell.textField.becomeFirstResponder()
            }
        }.onChange() { [unowned self] row in
            if let rowValue = row.value {
                self.workout.name = rowValue
            }
            if row.value == nil {
                self.navigationItem.rightBarButtonItem?.isEnabled = false
            } else if self.workout.type != nil {
                self.navigationItem.rightBarButtonItem?.isEnabled = true
            }
        }.cellUpdate { cell, row in
            cell.backgroundColor = .secondarySystemGroupedBackground
            cell.textField?.textColor = .label
            row.placeholderColor = .secondaryLabel
        }
        
        <<< IntRow("Body Weight") { row in
            row.cell.backgroundColor = .secondarySystemGroupedBackground
            row.cell.titleLabel?.textColor = .label
            row.cell.textField?.textColor = .secondaryLabel
            row.title = row.tag
            row.formatter = numberFormatter
            if let currentUser = Auth.auth().currentUser?.uid {
                let weightReference = Database.database().reference().child("users").child(currentUser).child("weight")
                weightReference.observe(.value, with: { (snapshot) in
                    if let weight = snapshot.value as? Int {
                        row.value = weight
                        row.updateCell()
                    }
                })
            }
        }.cellUpdate { cell, row in
            cell.backgroundColor = .secondarySystemGroupedBackground
            cell.titleLabel?.textColor = .label
            cell.textField?.textColor = .secondaryLabel
        }.onChange({ row in
//            self.updateCalories()
            if let currentUser = Auth.auth().currentUser?.uid, let value = row.value {
                Database.database().reference().child("users").child(currentUser).child("weight").setValue(value)
            }
        })
        
        <<< PushRow<String>("Type") { row in
            row.cell.backgroundColor = .secondarySystemGroupedBackground
            row.cell.textLabel?.textColor = .label
            row.cell.detailTextLabel?.textColor = .secondaryLabel
            row.title = row.tag
            row.value = workout.type?.capitalized
            row.options = []
            if #available(iOS 16.0, *) {
                HKWorkoutActivityType.allCases.forEach {
                    row.options?.append($0.name)
                }
            } else if #available(iOS 14.0, *) {
                HKWorkoutActivityType.oldAllCases.forEach {
                    row.options?.append($0.name)
                }
            } else {
                HKWorkoutActivityType.oldOldAllCases.forEach {
                    row.options?.append($0.name)
                }
            }
        }.onPresent { from, to in
            to.title = "Type"
            to.extendedLayoutIncludesOpaqueBars = true
            to.tableViewStyle = .insetGrouped
            to.enableDeselection = false
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
        }.onChange({ row in
            self.workout.type = row.value
//            self.updateCalories()
            if row.value == nil {
                self.navigationItem.rightBarButtonItem?.isEnabled = false
            } else if self.workout.name != "Name" {
                self.navigationItem.rightBarButtonItem?.isEnabled = true
            }
        })
        
        <<< DecimalRow("Calories Burned") {
            $0.cell.backgroundColor = .secondarySystemGroupedBackground
            $0.cell.textField?.textColor = .secondaryLabel
            $0.title = $0.tag
            $0.formatter = numberFormatter
            if let workout = workout, let calories = workout.totalEnergyBurned {
                $0.value = calories
            }
        }.cellUpdate { cell, row in
            cell.backgroundColor = .secondarySystemGroupedBackground
            cell.textField?.textColor = .secondaryLabel
        }.onChange({ row in
            if let value = row.value {
                self.workout.totalEnergyBurned = value
                if let currentUser = Auth.auth().currentUser?.uid {
                    let reference = Database.database().reference().child(userWorkoutsEntity).child(currentUser).child(self.workout.id).child("totalEnergyBurned")
                    reference.setValue(value)
                }
            }
        })
        
        <<< DateTimeInlineRow("Starts") {
            $0.cell.backgroundColor = .secondarySystemGroupedBackground
            $0.cell.textLabel?.textColor = .label
            $0.cell.detailTextLabel?.textColor = .secondaryLabel
            $0.title = $0.tag
            $0.dateFormatter?.dateStyle = .medium
            $0.dateFormatter?.timeStyle = .short
            $0.minuteInterval = 5
            if let workout = workout, let startDateTime = workout.startDateTime {
                $0.value = startDateTime
            } else {
                let original = Date()
                let rounded = Date(timeIntervalSinceReferenceDate:
                                    (original.timeIntervalSinceReferenceDate / 300.0).rounded(.toNearestOrEven) * 300.0)
                $0.value = rounded
                self.workout.startDateTime = $0.value
            }
        }.onChange { [weak self] row in
            let endRow: DateTimeInlineRow! = self?.form.rowBy(tag: "Ends")
            if row.value?.compare(endRow.value!) == .orderedDescending {
                endRow.value = Date(timeInterval: 0, since: row.value!)
                endRow.updateCell()
            }
            self!.updateLength()
            self!.workout.startDateTime = row.value
        }.onExpandInlineRow { cell, row, inlineRow in
            inlineRow.cellUpdate() { cell, row in
                row.cell.backgroundColor = .secondarySystemGroupedBackground
                row.cell.tintColor = .secondarySystemGroupedBackground
                cell.datePicker.datePickerMode = .dateAndTime
                if #available(iOS 14.0, *) {
                    cell.datePicker.preferredDatePickerStyle = .inline
                    cell.datePicker.tintColor = .systemBlue
                }
            }
            let color = cell.detailTextLabel?.textColor
            row.onCollapseInlineRow { cell, _, _ in
                cell.detailTextLabel?.textColor = color
            }
            cell.detailTextLabel?.textColor = cell.tintColor
        }.cellUpdate { cell, row in
            cell.backgroundColor = .secondarySystemGroupedBackground
            cell.textLabel?.textColor = .label
            cell.detailTextLabel?.textColor = .secondaryLabel
            
        }
        
        <<< DateTimeInlineRow("Ends"){
            $0.cell.backgroundColor = .secondarySystemGroupedBackground
            $0.cell.textLabel?.textColor = .label
            $0.cell.detailTextLabel?.textColor = .secondaryLabel
            $0.title = $0.tag
            $0.dateFormatter?.dateStyle = .medium
            $0.dateFormatter?.timeStyle = .short
            $0.minuteInterval = 5
            if let workout = workout, let endDateTime = workout.endDateTime {
                $0.value = endDateTime
            } else {
                let original = Date()
                let rounded = Date(timeIntervalSinceReferenceDate:
                                    (original.timeIntervalSinceReferenceDate / 300.0).rounded(.toNearestOrEven) * 300.0)
                $0.value = rounded
                self.workout.endDateTime = $0.value
            }
        }.onChange { [weak self] row in
            let startRow: DateTimeInlineRow! = self?.form.rowBy(tag: "Starts")
            if row.value?.compare(startRow.value!) == .orderedAscending {
                startRow.value = Date(timeInterval: 0, since: row.value!)
                startRow.updateCell()
            }
            self!.updateLength()
            self!.workout.endDateTime = row.value
        }.onExpandInlineRow { cell, row, inlineRow in
            inlineRow.cellUpdate() { cell, row in
                row.cell.backgroundColor = .secondarySystemGroupedBackground
                row.cell.tintColor = .secondarySystemGroupedBackground
                cell.datePicker.datePickerMode = .dateAndTime
                if #available(iOS 14.0, *) {
                    cell.datePicker.preferredDatePickerStyle = .inline
                    cell.datePicker.tintColor = .systemBlue
                }
            }
            let color = cell.detailTextLabel?.textColor
            row.onCollapseInlineRow { cell, _, _ in
                cell.detailTextLabel?.textColor = color
            }
            cell.detailTextLabel?.textColor = cell.tintColor
        }.cellUpdate { cell, row in
            cell.backgroundColor = .secondarySystemGroupedBackground
            cell.textLabel?.textColor = .label
            cell.detailTextLabel?.textColor = .secondaryLabel
            
        }
        
        <<< TextRow("Length") {
            $0.cell.isUserInteractionEnabled = false
            $0.cell.backgroundColor = .secondarySystemGroupedBackground
            $0.cell.textField?.textColor = .secondaryLabel
            $0.title = $0.tag
        }.cellUpdate { cell, row in
            cell.backgroundColor = .secondarySystemGroupedBackground
            cell.textField?.textColor = .secondaryLabel
        }.onChange({ _ in
//            self.updateCalories()
        })
        
        if delegate == nil {
            form.last!
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
        
        if delegate == nil, active, (workout?.participantsIDs?.contains(Auth.auth().currentUser?.uid ?? "") ?? false) {
            form.last!
            <<< SegmentedRow<String>("sections"){
                    $0.cell.backgroundColor = .secondarySystemGroupedBackground
                    $0.options = ["Tasks", "Events", "Transactions"]
                    $0.value = "Tasks"
                    }.cellUpdate { cell, row in
                        cell.backgroundColor = .secondarySystemGroupedBackground
                        cell.textLabel?.textColor = .label
                    }.onChange({ _ in
                        self.sectionChanged = true
                    })
            
            form +++
                MultivaluedSection(multivaluedOptions: [.Insert, .Delete],
                                   header: "Tasks",
                                   footer: "Connect an task") {
                                    $0.tag = "Tasks"
                                    $0.hidden = "!$sections == 'Tasks'"
                                    $0.addButtonProvider = { section in
                                        return ButtonRow("taskButton"){
                                            $0.cell.backgroundColor = .secondarySystemGroupedBackground
                                            $0.title = "Connect Task"
                                            }.cellUpdate { cell, row in
                                                cell.backgroundColor = .secondarySystemGroupedBackground
                                                cell.textLabel?.textAlignment = .left
                                                cell.height = { 60 }
                                            }
                                    }
                                    $0.multivaluedRowToInsertAt = { index in
                                        self.taskIndex = index
                                        self.openTask()
                                        return SubtaskRow("label"){ _ in
                                            
                                        }
                                    }

                                }

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
                                   header: "Transactions",
                                   footer: "Connect a transaction") {
                                    $0.tag = "Transactions"
                                    $0.hidden = "$sections != 'Transactions'"
                                    $0.addButtonProvider = { section in
                                        return ButtonRow("transactionButton"){
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
    }
    
    fileprivate func updateLength() {
        if let lengthRow : TextRow = form.rowBy(tag: "Length"), let startRow: DateTimeInlineRow = form.rowBy(tag: "Starts"), let startValue = startRow.value, let endRow: DateTimeInlineRow = form.rowBy(tag: "Ends"), let endValue = endRow.value {
            let length = Calendar.current.dateComponents([.second], from: startValue, to: endValue).second ?? 0
            workout.length = Double(length)
            let hour = length / 3600
            let minutes = (length % 3600) / 60
            if minutes > 0 && hour > 0 {
                if hour == 1 {
                    lengthRow.value = "\(hour) hour \(minutes) minutes"
                } else {
                    lengthRow.value = "\(hour) hours \(minutes) minutes"
                }
            } else if hour > 0 {
                if hour == 1 {
                    lengthRow.value = "\(hour) hour"
                } else {
                    lengthRow.value = "\(hour) hours"
                }
            } else {
                lengthRow.value = "\(minutes) minutes"
            }
            lengthRow.updateCell()
        }
    }
    
    fileprivate func updateCalories() {
        if let caloriesRow : DecimalRow = self.form.rowBy(tag: "Calories Burned"), let weightRow : IntRow = self.form.rowBy(tag: "Body Weight"), let weightValue = weightRow.value, let length = workout.length {
            let workoutType = workout.hkWorkoutActivityType
            let totalEnergyBurned = Double(length / 60) * workoutType.calories * Double(weightValue)
            caloriesRow.value = totalEnergyBurned
            caloriesRow.updateCell()
        }
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
                    self!.updateLists()
                    ContainerFunctions.deleteStuffInside(type: .activity, ID: item.activityID ?? "")
                }
            }
            else if row is PurchaseRow {
                if self!.purchaseList.indices.contains(rowNumber) {
                    let item = self!.purchaseList[rowNumber]
                    self!.purchaseList.remove(at: rowNumber)
                    self!.updateLists()
//                    self!.purchaseBreakdown()
                    ContainerFunctions.deleteStuffInside(type: .transaction, ID: item.guid)
                }
            }
            else if row is SubtaskRow {
                if self!.taskList.indices.contains(rowNumber) {
                    let item = self!.taskList[rowNumber]
                    self!.taskList.remove(at: rowNumber)
                    self!.updateLists()
                    ContainerFunctions.deleteStuffInside(type: .task, ID: item.activityID ?? "")
                }
            }
        }
    }
        
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
        destination.ownerID = workout.admin
        destination.users = uniqueUsers
        destination.filteredUsers = uniqueUsers
        if !selectedFalconUsers.isEmpty {
            destination.priorSelectedUsers = selectedFalconUsers
        }
        destination.delegate = self
        self.navigationController?.pushViewController(destination, animated: true)
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
    
    func getSelectedFalconUsers(forWorkout workout: Workout, completion: @escaping ([User])->()) {
        guard let participantsIDs = workout.participantsIDs, let currentUserID = Auth.auth().currentUser?.uid else {
            return
        }
        var selectedFalconUsers = [User]()
        let group = DispatchGroup()
        for id in participantsIDs {
            // Only if the current user is created this activity
            if workout.admin == currentUserID && id == currentUserID {
                continue
            }
            
            group.enter()
            let participantReference = Database.database().reference().child("users").child(id)
            participantReference.observeSingleEvent(of: .value, with: { (snapshot) in
                if snapshot.exists(), var dictionary = snapshot.value as? [String: AnyObject] {
                    dictionary.updateValue(snapshot.key as AnyObject, forKey: "id")
                    let user = User(dictionary: dictionary)
                    selectedFalconUsers.append(user)
                }
                group.leave()
            })
        }
        
        group.notify(queue: .main) {
            completion(selectedFalconUsers)
        }
    }
    
    func resetBadgeForSelf() {
        guard let currentUserID = Auth.auth().currentUser?.uid else { return }
        let badgeRef = Database.database().reference().child(userWorkoutsEntity).child(currentUserID).child(workout.id).child("badge")
        badgeRef.runTransactionBlock({ (mutableData) -> TransactionResult in
            var value = mutableData.value as? Int
            value = 0
            mutableData.value = value!
            return TransactionResult.success(withValue: mutableData)
        })
    }
}

extension WorkoutViewController: UpdateInvitees {
    func updateInvitees(selectedFalconUsers: [User]) {
        if let inviteesRow: LabelRow = form.rowBy(tag: "Participants") {
            self.selectedFalconUsers = selectedFalconUsers
            inviteesRow.value = String(selectedFalconUsers.count + 1)
            inviteesRow.updateCell()
            
            if active {
                showActivityIndicator()
                if let container = container {
                    ContainerFunctions.updateParticipants(containerID: container.id, selectedFalconUsers: selectedFalconUsers)
                } else {
                    let createWorkout = WorkoutActions(workout: workout, active: active, selectedFalconUsers: selectedFalconUsers)
                    createWorkout.updateWorkoutParticipants()
                }
                hideActivityIndicator()
            }
            
        }
    }
}
