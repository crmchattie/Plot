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

class WorkoutViewController: FormViewController {    
    var workout: Workout!
    
    var users = [User]()
    var filteredUsers = [User]()
    var selectedFalconUsers = [User]()
    
    var userNames : [String] = []
    var userNamesString: String = ""
    
    fileprivate var active: Bool = false
    
    fileprivate var productIndex: Int = 0
    
    let numberFormatter = NumberFormatter()
    
    var timer: Timer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        numberFormatter.numberStyle = .decimal
        
        if workout != nil {
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
            if let currentUserID = Auth.auth().currentUser?.uid {
                let ID = Database.database().reference().child(userWorkoutsEntity).child(currentUserID).childByAutoId().key ?? ""
                workout = Workout(id: ID, name: "WorkoutName", admin: currentUserID)
            }
        }
        configureTableView()
        setupRightBarButton()
        initializeForm()
        
        updateLength()
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
        navigationItem.title = "Workout"
    }
    
    func setupRightBarButton() {
        let plusBarButton =  UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(close))
        navigationItem.rightBarButtonItem = plusBarButton
    }
    
    @objc fileprivate func close() {
        if active {
            let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

            alert.addAction(UIAlertAction(title: "Update Workout", style: .default, handler: { (_) in
                print("User click Approve button")
                
                // update
                self.showActivityIndicator()
                let createWorkout = WorkoutActions(workout: self.workout, active: self.active, selectedFalconUsers: self.selectedFalconUsers)
                createWorkout.createNewWorkout()
                self.hideActivityIndicator()
                self.navigationController?.popViewController(animated: true)
                
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
                    
                    self.navigationController?.popViewController(animated: true)
                }
                
                
            }))
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (_) in
                print("User click Dismiss button")
            }))
            
            self.present(alert, animated: true, completion: {
                print("completion block")
            })
            
        } else {
            self.showActivityIndicator()
            let createWorkout = WorkoutActions(workout: self.workout, active: self.active, selectedFalconUsers: self.selectedFalconUsers)
            createWorkout.createNewWorkout()
            self.hideActivityIndicator()
            
            let nav = self.tabBarController!.viewControllers![1] as! UINavigationController
            if nav.topViewController is MasterActivityContainerController {
                let homeTab = nav.topViewController as! MasterActivityContainerController
                homeTab.customSegmented.setIndex(index: 2)
                homeTab.changeToIndex(index: 2)
            }
            self.tabBarController?.selectedIndex = 1
            if #available(iOS 13.0, *) {
                self.navigationController?.backToViewController(viewController: DiscoverViewController.self)
            } else {
                // Fallback on earlier versions
            }
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
            Section(header: nil, footer: "Calories burned is based on estimates and subject to error as a result")
            
            <<< TextRow("Name") {
                $0.cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
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
                } else {
                    self.navigationItem.rightBarButtonItem?.isEnabled = true
                }
            }.cellUpdate { cell, row in
                cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                cell.textField?.textColor = ThemeManager.currentTheme().generalTitleColor
                row.placeholderColor = ThemeManager.currentTheme().generalSubtitleColor
            }
            
            <<< IntRow("Weight") { row in
                row.cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
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
                cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                cell.titleLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                cell.textField?.textColor = ThemeManager.currentTheme().generalSubtitleColor
            }.onChange({ row in
                self.updateCalories()
                if let currentUser = Auth.auth().currentUser?.uid, let value = row.value {
                    Database.database().reference().child("users").child(currentUser).child("weight").setValue(value)
                }
            })
            
            <<< PushRow<String>("Type") { row in
                row.cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                row.cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                row.cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
                row.title = row.tag
                row.value = workout.type?.capitalized
                row.options = []
                WorkoutTypes.allCases.sorted().forEach {
                    row.options?.append($0.rawValue.capitalized)
                }
            }.onPresent { from, to in
                to.selectableRowCellUpdate = { cell, row in
                    to.title = "Type"
                    to.tableView.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                    to.tableView.separatorStyle = .none
                    cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                    cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                    cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
                }
            }.cellUpdate { cell, row in
                cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
            }.onChange({ row in
                self.workout.type = row.value
                self.updateCalories()
            })
            
            <<< DecimalRow("Calories Burned") {
                $0.cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                $0.cell.textField?.textColor = ThemeManager.currentTheme().generalSubtitleColor
                $0.title = $0.tag
                $0.formatter = numberFormatter
            }.cellUpdate { cell, row in
                cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                cell.textField?.textColor = ThemeManager.currentTheme().generalSubtitleColor
            }
            
            <<< TextRow("Length") {
                $0.cell.isUserInteractionEnabled = false
                $0.cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                $0.cell.textField?.textColor = ThemeManager.currentTheme().generalSubtitleColor
                $0.title = $0.tag
            }.cellUpdate { cell, row in
                cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                cell.textField?.textColor = ThemeManager.currentTheme().generalSubtitleColor
            }.onChange({ _ in
                self.updateCalories()
            })
            
            <<< DateTimeInlineRow("Starts") {
                $0.cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                $0.cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                $0.cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
                $0.title = $0.tag
                $0.dateFormatter?.timeZone = NSTimeZone(name: "UTC") as TimeZone?
                $0.dateFormatter?.dateStyle = .medium
                $0.dateFormatter?.timeStyle = .short
                if self.active {
                    $0.value = self.workout!.startDateTime
                } else {
                    let original = Date()
                    let rounded = Date(timeIntervalSinceReferenceDate:
                                        (original.timeIntervalSinceReferenceDate / 300.0).rounded(.toNearestOrEven) * 300.0)
                    let timezone = TimeZone.current
                    let seconds = TimeInterval(timezone.secondsFromGMT(for: Date()))
                    $0.value = rounded.addingTimeInterval(seconds)
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
                    row.cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                    row.cell.tintColor = ThemeManager.currentTheme().generalBackgroundColor
                    cell.datePicker.datePickerMode = .dateAndTime
                    cell.datePicker.timeZone = NSTimeZone(name: "UTC") as TimeZone?
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
                cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
                
            }
            
            <<< DateTimeInlineRow("Ends"){
                $0.cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                $0.cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                $0.cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
                $0.title = $0.tag
                $0.dateFormatter?.timeZone = NSTimeZone(name: "UTC") as TimeZone?
                $0.dateFormatter?.dateStyle = .medium
                $0.dateFormatter?.timeStyle = .short
                if self.active {
                    $0.value = self.workout!.endDateTime
                } else {
                    let original = Date()
                    let rounded = Date(timeIntervalSinceReferenceDate:
                                        (original.timeIntervalSinceReferenceDate / 300.0).rounded(.toNearestOrEven) * 300.0)
                    let timezone = TimeZone.current
                    let seconds = TimeInterval(timezone.secondsFromGMT(for: Date()))
                    $0.value = rounded.addingTimeInterval(seconds + 1800)
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
                    row.cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                    row.cell.tintColor = ThemeManager.currentTheme().generalBackgroundColor
                    cell.datePicker.datePickerMode = .dateAndTime
                    cell.datePicker.timeZone = NSTimeZone(name: "UTC") as TimeZone?
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
                cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
                
            }
            
            <<< ButtonRow("Participants") { row in
                row.cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                row.cell.textLabel?.textAlignment = .left
                row.cell.textLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
                row.cell.accessoryType = .disclosureIndicator
                row.title = row.tag
                if active {
                    row.cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                    row.title = self.userNamesString
                }
            }.onCellSelection({ _,_ in
                self.openParticipantsInviter()
            }).cellUpdate { cell, row in
                cell.accessoryType = .disclosureIndicator
                cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                cell.textLabel?.textAlignment = .left
                if row.title == "Participants" {
                    cell.textLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
                } else {
                    cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                }
            }
    }
    
    fileprivate func updateLength() {
        if let lengthRow : TextRow = form.rowBy(tag: "Length"), let startRow: DateTimeInlineRow = form.rowBy(tag: "Starts"), let startValue = startRow.value, let endRow: DateTimeInlineRow = form.rowBy(tag: "Ends"), let endValue = endRow.value {
            let length = Calendar.current.dateComponents([.second], from: startValue, to: endValue).second ?? 0
            workout.length = length
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
        if let caloriesRow : DecimalRow = self.form.rowBy(tag: "Calories Burned"), let weightRow : IntRow = self.form.rowBy(tag: "Weight"), let weightValue = weightRow.value, let workoutType = WorkoutTypes(rawValue: self.workout.type ?? ""), let length = workout.length {
            caloriesRow.value = Double(length / 60) * workoutType.caloriesBurned * Double(weightValue)
            caloriesRow.updateCell()
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