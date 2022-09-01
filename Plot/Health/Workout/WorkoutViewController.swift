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

class WorkoutViewController: FormViewController {    
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
    
    var userNames : [String] = []
    var userNamesString: String = ""
    
    fileprivate var productIndex: Int = 0
    
    let numberFormatter = NumberFormatter()
    
    var timer: Timer?
    var workoutActions: WorkoutActions?
    
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
        
        if workout != nil {
            title = "Workout"
            
            active = true
            
            var participantCount = self.selectedFalconUsers.count
            
            // If user is creating this activity (admin)
            if workout.admin == nil || workout.admin == Auth.auth().currentUser?.uid {
                participantCount += 1
            }
            
            if participantCount > 1 {
                self.userNamesString = "\(participantCount) participants"
            } else {
                self.userNamesString = "1 participant"
            }
            
            if let inviteesRow: ButtonRow = self.form.rowBy(tag: "Participants") {
                inviteesRow.title = self.userNamesString
                inviteesRow.updateCell()
            }
        } else {
            title = "New Workout"
            if let currentUserID = Auth.auth().currentUser?.uid {
                let ID = Database.database().reference().child(userWorkoutsEntity).child(currentUserID).childByAutoId().key ?? ""
                workout = Workout(id: ID, name: "Name", admin: currentUserID, lastModifiedDate: Date(), createdDate: Date(), type: nil, startDateTime: nil, endDateTime: nil, length: nil, totalEnergyBurned: nil)
            }
        }
        configureTableView()
        setupRightBarButton()
        initializeForm()
        updateLength()
        setupLists()
        
        if active {
            for row in form.allRows {
                if row.tag != "sections" && row.tag != "Tasks" && row.tag != "Events" && row.tag != "Transactions" && row.tag != "taskButton" && row.tag != "scheduleButton" && row.tag != "transactionButton" {
                    row.baseCell.isUserInteractionEnabled = false
                }
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
        view.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
        tableView.indicatorStyle = ThemeManager.currentTheme().scrollBarStyle
        tableView.backgroundColor = view.backgroundColor
        extendedLayoutIncludesOpaqueBars = true
        edgesForExtendedLayout = UIRectEdge.top
        tableView.separatorStyle = .none
        definesPresentationContext = true
    }
    
    func setupRightBarButton() {
        if !active {
            let addBarButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(create))
            navigationItem.rightBarButtonItem = addBarButton
        }
        if navigationItem.leftBarButtonItem != nil {
            navigationItem.leftBarButtonItem?.action = #selector(cancel)
        }
    }
    
    @IBAction func cancel(_ sender: AnyObject) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @objc fileprivate func create() {
        if active {
            let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            
            alert.addAction(UIAlertAction(title: "Update Workout", style: .default, handler: { (_) in
                print("User click Approve button")
                
                // update
                self.showActivityIndicator()
                self.updateLists()
                let createWorkout = WorkoutActions(workout: self.workout, active: self.active, selectedFalconUsers: self.selectedFalconUsers)
                createWorkout.createNewWorkout()
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
                    basicErrorAlertWith(title: basicErrorTitleForAlert, message: noInternetError, controller: self)
                    return
                }
                
                if let currentUserID = Auth.auth().currentUser?.uid {
                    self.showActivityIndicator()
                    self.updateLists()
                    let createWorkout = WorkoutActions(workout: self.workout, active: self.active, selectedFalconUsers: self.selectedFalconUsers)
                    createWorkout.createNewWorkout()
                    
                    //duplicate workout
                    let newWorkoutID = Database.database().reference().child(userWorkoutsEntity).child(currentUserID).childByAutoId().key ?? ""
                    var newWorkout = self.workout!
                    newWorkout.id = newWorkoutID
                    newWorkout.admin = currentUserID
                    newWorkout.participantsIDs = nil
                    
                    let createNewWorkout = WorkoutActions(workout: newWorkout, active: false, selectedFalconUsers: [])
                    createNewWorkout.createNewWorkout()
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
        } else {
            showActivityIndicator()
            createHealthKit() { hkSampleID in
                self.workout.hkSampleID = hkSampleID
                let createNewWorkout = WorkoutActions(workout: self.workout, active: self.active, selectedFalconUsers: self.selectedFalconUsers)
                createNewWorkout.createNewWorkout()
                self.delegate?.updateWorkout(workout: self.workout)
                DispatchQueue.main.async {
                    self.hideActivityIndicator()
                    if self.navigationItem.leftBarButtonItem != nil {
                        self.dismiss(animated: true, completion: nil)
                    } else {
                        self.navigationController?.popViewController(animated: true)
                        self.updateDiscoverDelegate?.itemCreated()
                    }
                }
            }
        }
        
    }
    
    func createHealthKit(completion: @escaping (String?) -> Void) {
        var hkSampleID: String?
        if let hkWorkout = HealthKitSampleBuilder.createHKWorkout(from: workout) {
            hkSampleID = hkWorkout.uuid.uuidString
            HealthKitService.storeSample(sample: hkWorkout) { (_, _) in
                if let hkSampleID = hkSampleID, self.delegate == nil {
                    self.createActivity(hkSampleID: hkSampleID) {
                        completion(hkSampleID)
                    }
                } else {
                    completion(hkSampleID)
                }
            }
        }
    }
    
    func createActivity(hkSampleID: String, completion: @escaping () -> Void) {
        if let activity = ActivityBuilder.createActivity(from: self.workout), let activityID = activity.activityID {
            let activityActions = ActivityActions(activity: activity, active: false, selectedFalconUsers: [])
            activityActions.createNewActivity()
            
            //will update activity.containerID and workout.containerID
            let containerID = Database.database().reference().child(containerEntity).childByAutoId().key ?? ""
            let container = Container(id: containerID, activityIDs: [activityID], taskIDs: nil, workoutIDs: [hkSampleID], mindfulnessIDs: nil, mealIDs: nil, transactionIDs: nil)
            ContainerFunctions.updateContainerAndStuffInside(container: container)
            completion()
        }
    }
    
    @objc func goToExtras() {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        
        
        //        alert.addAction(UIAlertAction(title: "Share Grocery List", style: .default, handler: { (_) in
        //            print("User click Edit button")
        //            self.share()
        //        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (_) in
            print("User click Dismiss button")
        }))
        
        self.present(alert, animated: true, completion: {
            print("completion block")
        })
        print("shareButtonTapped")
        
    }
    
    func initializeForm() {
        print("initializing form")
        form +++
        Section()
        //"Calories burned is based on estimates and subject to error as a result"
        
        <<< TextRow("Name") {
            $0.cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
            $0.cell.textField?.textColor = ThemeManager.currentTheme().generalTitleColor
            $0.placeholderColor = ThemeManager.currentTheme().generalSubtitleColor
            $0.placeholder = $0.tag
            if active, let workout = workout {
                self.navigationItem.rightBarButtonItem?.isEnabled = true
                $0.value = workout.name
            } else {
                self.navigationItem.rightBarButtonItem?.isEnabled = false
                $0.cell.textField.becomeFirstResponder()
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
            cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
            cell.textField?.textColor = ThemeManager.currentTheme().generalTitleColor
            row.placeholderColor = ThemeManager.currentTheme().generalSubtitleColor
        }
        
        <<< IntRow("Body Weight") { row in
            row.cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
            row.cell.titleLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
            row.cell.textField?.textColor = ThemeManager.currentTheme().generalSubtitleColor
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
            cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
            cell.titleLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
            cell.textField?.textColor = ThemeManager.currentTheme().generalSubtitleColor
        }.onChange({ row in
            self.updateCalories()
            if let currentUser = Auth.auth().currentUser?.uid, let value = row.value {
                Database.database().reference().child("users").child(currentUser).child("weight").setValue(value)
            }
        })
        
        <<< PushRow<String>("Type") { row in
            row.cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
            row.cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
            row.cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
            row.title = row.tag
            row.value = workout.type?.capitalized
            row.options = []
            if #available(iOS 14.0, *) {
                HKWorkoutActivityType.allCases.forEach {
                    row.options?.append($0.name)
                }
            } else {
                HKWorkoutActivityType.oldAllCases.forEach {
                    row.options?.append($0.name)
                }
            }
        }.onPresent { from, to in
            to.title = "Type"
            to.extendedLayoutIncludesOpaqueBars = true
            to.tableViewStyle = .insetGrouped
            to.enableDeselection = false
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
        }.onChange({ row in
            self.workout.type = row.value
            self.updateCalories()
            if row.value == nil {
                self.navigationItem.rightBarButtonItem?.isEnabled = false
            } else if self.workout.name != "WorkoutName" {
                self.navigationItem.rightBarButtonItem?.isEnabled = true
            }
        })
        
        <<< DecimalRow("Calories Burned") {
            $0.cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
            $0.cell.textField?.textColor = ThemeManager.currentTheme().generalSubtitleColor
            $0.title = $0.tag
            $0.formatter = numberFormatter
            if let calories = workout.totalEnergyBurned {
                $0.value = calories
            }
        }.cellUpdate { cell, row in
            cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
            cell.textField?.textColor = ThemeManager.currentTheme().generalSubtitleColor
        }
        
        <<< DateTimeInlineRow("Starts") {
            $0.cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
            $0.cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
            $0.cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
            $0.title = $0.tag
            $0.dateFormatter?.dateStyle = .medium
            $0.dateFormatter?.timeStyle = .short
            if self.active {
                $0.value = self.workout!.startDateTime
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
                row.cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                row.cell.tintColor = ThemeManager.currentTheme().cellBackgroundColor
                cell.datePicker.datePickerMode = .dateAndTime
                if #available(iOS 13.4, *) {
                    cell.datePicker.preferredDatePickerStyle = .wheels
                }
            }
            let color = cell.detailTextLabel?.textColor
            row.onCollapseInlineRow { cell, _, _ in
                cell.detailTextLabel?.textColor = color
            }
            cell.detailTextLabel?.textColor = cell.tintColor
        }.cellUpdate { cell, row in
            cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
            cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
            cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
            
        }
        
        <<< DateTimeInlineRow("Ends"){
            $0.cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
            $0.cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
            $0.cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
            $0.title = $0.tag
            $0.dateFormatter?.dateStyle = .medium
            $0.dateFormatter?.timeStyle = .short
            if self.active {
                $0.value = self.workout!.endDateTime
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
                row.cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                row.cell.tintColor = ThemeManager.currentTheme().cellBackgroundColor
                cell.datePicker.datePickerMode = .dateAndTime
                if #available(iOS 13.4, *) {
                    cell.datePicker.preferredDatePickerStyle = .wheels
                }
            }
            let color = cell.detailTextLabel?.textColor
            row.onCollapseInlineRow { cell, _, _ in
                cell.detailTextLabel?.textColor = color
            }
            cell.detailTextLabel?.textColor = cell.tintColor
        }.cellUpdate { cell, row in
            cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
            cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
            cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
            
        }
        
        <<< TextRow("Length") {
            $0.cell.isUserInteractionEnabled = false
            $0.cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
            $0.cell.textField?.textColor = ThemeManager.currentTheme().generalSubtitleColor
            $0.title = $0.tag
        }.cellUpdate { cell, row in
            cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
            cell.textField?.textColor = ThemeManager.currentTheme().generalSubtitleColor
        }.onChange({ _ in
            self.updateCalories()
        })
        
//            <<< ButtonRow("Participants") { row in
//                row.cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
//                row.cell.textLabel?.textAlignment = .left
//                row.cell.textLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
//                row.cell.accessoryType = .disclosureIndicator
//                row.title = row.tag
//                if active {
//                    row.cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
//                    row.title = self.userNamesString
//                }
//            }.onCellSelection({ _,_ in
//                self.openParticipantsInviter()
//            }).cellUpdate { cell, row in
//                cell.accessoryType = .disclosureIndicator
//                cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
//                cell.textLabel?.textAlignment = .left
//                if row.title == "Participants" {
//                    cell.textLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
//                } else {
//                    cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
//                }
//            }
        
        if delegate == nil && active {
            form.last!
            <<< SegmentedRow<String>("sections"){
                    $0.cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                    if #available(iOS 13.0, *) {
                        $0.cell.segmentedControl.overrideUserInterfaceStyle = ThemeManager.currentTheme().userInterfaceStyle
                    } else {
                        // Fallback on earlier versions
                    }
                    $0.options = ["Tasks", "Events", "Transactions"]
                    $0.value = "Tasks"
                    }.cellUpdate { cell, row in
                        cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                        cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
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
                                            $0.cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                                            $0.title = "Connect Task"
                                            }.cellUpdate { cell, row in
                                                cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
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
                                            $0.cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                                            $0.title = "Connect Event"
                                            }.cellUpdate { cell, row in
                                                cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
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
                                            $0.cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                                            $0.title = "Connect Transaction"
                                            }.cellUpdate { cell, row in
                                                cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                                                cell.textLabel?.textAlignment = .left
                                                cell.height = { 60 }
                                        }
                                    }
                                    $0.multivaluedRowToInsertAt = { index in
                                        self.purchaseIndex = index
                                        self.openTransaction()
                                        return PurchaseRow()
                                            .onCellSelection() { cell, row in
                                                self.purchaseIndex = index
                                                self.openTransaction()
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
            self.workout.totalEnergyBurned = Double(length / 60) * workoutType.calories * Double(weightValue)
            caloriesRow.value = self.workout.totalEnergyBurned
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
                    self!.eventList.remove(at: rowNumber)
                    self!.updateLists()
                }
            }
            else if row is PurchaseRow {
                if self!.purchaseList.indices.contains(rowNumber) {
                    self!.purchaseList.remove(at: rowNumber)
                    self!.updateLists()
                }
            }
            else if row is SubtaskRow {
                if self!.taskList.indices.contains(rowNumber) {
                    self!.taskList.remove(at: rowNumber)
                    self!.updateLists()
                }
            }
        }
    }
        
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
}

extension WorkoutViewController: UpdateInvitees {
    func updateInvitees(selectedFalconUsers: [User]) {
        if let inviteesRow: ButtonRow = form.rowBy(tag: "Participants") {
            if !selectedFalconUsers.isEmpty {
                self.selectedFalconUsers = selectedFalconUsers
                var participantCount = self.selectedFalconUsers.count
                // If user is creating this activity (admin)
                if workout.admin == nil || workout.admin == Auth.auth().currentUser?.uid {
                    participantCount += 1
                }
                if participantCount > 1 {
                    self.userNamesString = "\(participantCount) participants"
                } else {
                    self.userNamesString = "1 participant"
                }
                
                inviteesRow.title = self.userNamesString
                inviteesRow.updateCell()
                
            } else {
                self.selectedFalconUsers = selectedFalconUsers
                inviteesRow.title = "1 participant"
                inviteesRow.updateCell()
            }
            
            if active {
                showActivityIndicator()
                let createWorkout = WorkoutActions(workout: workout, active: active, selectedFalconUsers: selectedFalconUsers)
                createWorkout.updateWorkoutParticipants()
                hideActivityIndicator()
            }
            
        }
    }
}
