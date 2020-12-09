//
//  MindfulnessViewController.swift
//  Plot
//
//  Created by Cory McHattie on 12/8/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import UIKit
import Eureka
import SplitRow
import Firebase
import CodableFirebase

class MindfulnessViewController: FormViewController {
    var mindfulness: Mindfulness!
    
    fileprivate var active: Bool = true
    fileprivate var movingBackwards: Bool = true
    
    fileprivate var productIndex: Int = 0
    
    let numberFormatter = NumberFormatter()
        
    var users = [User]()
    var filteredUsers = [User]()
    var selectedFalconUsers = [User]()
    
    var userNames : [String] = []
    var userNamesString: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        numberFormatter.numberStyle = .decimal
        
        if mindfulness == nil {
            active = false
            if let currentUserID = Auth.auth().currentUser?.uid {
                let ID = Database.database().reference().child(userMindfulnessEntity).child(currentUserID).childByAutoId().key ?? ""
                mindfulness = Mindfulness(id: ID, name: nil, startDateTime: nil, endDateTime: nil, lastModifiedDate: Date(), createdDate: Date())
            }
        } else {
            var participantCount = self.selectedFalconUsers.count
            
            // If user is creating this activity (admin)
            if mindfulness.admin == nil || mindfulness.admin == Auth.auth().currentUser?.uid {
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
        }
        configureTableView()
        setupRightBarButton()
        initializeForm()
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return ThemeManager.currentTheme().statusBarStyle
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
        navigationItem.title = "Mindfulness"
    }
    
    func setupRightBarButton() {
        let plusBarButton =  UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(close))
        navigationItem.rightBarButtonItem = plusBarButton
    }
    
    @objc fileprivate func close() {
        
    }
    
    func initializeForm() {
        form +++
            Section()
            
            <<< TextRow("Name") {
                $0.cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                $0.cell.textField?.textColor = ThemeManager.currentTheme().generalTitleColor
                $0.placeholderColor = ThemeManager.currentTheme().generalSubtitleColor
                $0.placeholder = $0.tag
                if active, let mindfulness = mindfulness {
                    self.navigationItem.rightBarButtonItem?.isEnabled = true
                    $0.value = mindfulness.name
                } else {
                    self.navigationItem.rightBarButtonItem?.isEnabled = false
                    $0.cell.textField.becomeFirstResponder()
                }
            }.onChange() { [unowned self] row in
                if let rowValue = row.value {
                    self.mindfulness.name = rowValue
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
            
            <<< TextRow("Duration") {
                $0.cell.isUserInteractionEnabled = false
                $0.cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                $0.cell.textField?.textColor = ThemeManager.currentTheme().generalSubtitleColor
                $0.title = $0.tag
                if let startRow: DateTimeInlineRow = self.form.rowBy(tag: "Starts"), let endRow: DateTimeInlineRow = self.form.rowBy(tag: "Ends") {
                    let dateComponents = Calendar.current.dateComponents([.hour, .minute], from: startRow.value!, to: endRow.value!)
                    let hour = dateComponents.hour
                    let minutes = dateComponents.minute
                    if let minutes = minutes, let hour = hour {
                        $0.value = "\(hour) hours \(minutes) minutes"
                    } else if let minutes = minutes {
                        $0.value = "\(minutes) minutes"
                    }
                } else {
                    $0.value = "30 minutes"
                }
            }.cellUpdate { cell, row in
                cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                cell.textField?.textColor = ThemeManager.currentTheme().generalSubtitleColor
            }
            
            <<< DateTimeInlineRow("Starts") {
                $0.cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                $0.cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                $0.cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
                $0.title = $0.tag
                $0.dateFormatter?.timeZone = NSTimeZone(name: "UTC") as TimeZone?
                $0.dateFormatter?.dateStyle = .medium
                $0.dateFormatter?.timeStyle = .short
                if self.active {
                    $0.value = self.mindfulness!.startDateTime
                } else {
                    let original = Date()
                    let rounded = Date(timeIntervalSinceReferenceDate:
                                        (original.timeIntervalSinceReferenceDate / 300.0).rounded(.toNearestOrEven) * 300.0)
                    let timezone = TimeZone.current
                    let seconds = TimeInterval(timezone.secondsFromGMT(for: Date()))
                    $0.value = rounded.addingTimeInterval(seconds)
                    self.mindfulness.startDateTime = $0.value
                }
            }.onChange { [weak self] row in
                let endRow: DateTimeInlineRow! = self?.form.rowBy(tag: "Ends")
                if row.value?.compare(endRow.value!) == .orderedDescending {
                    endRow.value = Date(timeInterval: 0, since: row.value!)
                    endRow.updateCell()
                }
                if let durationRow : TextRow = self?.form.rowBy(tag: "Duration") {
                    let dateComponents = Calendar.current.dateComponents([.hour, .minute], from: row.value!, to: endRow.value!)
                    let hour = dateComponents.hour
                    let minutes = dateComponents.minute
                    if let minutes = minutes, let hour = hour {
                        durationRow.value = "\(hour) hours \(minutes) minutes"
                    } else if let minutes = minutes {
                        durationRow.value = "\(minutes) minutes"
                    }
                    durationRow.updateCell()
                }
                self!.mindfulness.startDateTime = row.value
            }.onExpandInlineRow { cell, row, inlineRow in
                inlineRow.cellUpdate() { cell, row in
                    row.cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                    row.cell.tintColor = ThemeManager.currentTheme().generalBackgroundColor
                    cell.datePicker.datePickerMode = .dateAndTime
                    cell.datePicker.timeZone = NSTimeZone(name: "UTC") as TimeZone?
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
                    $0.value = self.mindfulness!.endDateTime
                } else {
                    let original = Date()
                    let rounded = Date(timeIntervalSinceReferenceDate:
                                        (original.timeIntervalSinceReferenceDate / 300.0).rounded(.toNearestOrEven) * 300.0)
                    let timezone = TimeZone.current
                    let seconds = TimeInterval(timezone.secondsFromGMT(for: Date()))
                    $0.value = rounded.addingTimeInterval(seconds + 1800)
                    self.mindfulness.endDateTime = $0.value
                }
            }.onChange { [weak self] row in
                let startRow: DateTimeInlineRow! = self?.form.rowBy(tag: "Starts")
                if row.value?.compare(startRow.value!) == .orderedAscending {
                    startRow.value = Date(timeInterval: 0, since: row.value!)
                    startRow.updateCell()
                }
                if let durationRow : TextRow = self?.form.rowBy(tag: "Duration") {
                    let dateComponents = Calendar.current.dateComponents([.hour, .minute], from: startRow.value!, to: row.value!)
                    let hour = dateComponents.hour
                    let minutes = dateComponents.minute
                    if let minutes = minutes, let hour = hour {
                        durationRow.value = "\(hour) hours \(minutes) minutes"
                    } else if let minutes = minutes {
                        durationRow.value = "\(minutes) minutes"
                    }
                    durationRow.updateCell()
                }
                self!.mindfulness.endDateTime = row.value
            }.onExpandInlineRow { cell, row, inlineRow in
                inlineRow.cellUpdate() { cell, row in
                    row.cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                    row.cell.tintColor = ThemeManager.currentTheme().generalBackgroundColor
                    cell.datePicker.datePickerMode = .dateAndTime
                    cell.datePicker.timeZone = NSTimeZone(name: "UTC") as TimeZone?
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
    
    func getSelectedFalconUsers(forWorkout mindfulness: Workout, completion: @escaping ([User])->()) {
        guard let participantsIDs = mindfulness.participantsIDs, let currentUserID = Auth.auth().currentUser?.uid else {
            return
        }
        var selectedFalconUsers = [User]()
        let group = DispatchGroup()
        for id in participantsIDs {
            // Only if the current user is created this activity
            if mindfulness.admin == currentUserID && id == currentUserID {
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
    
    fileprivate func resetBadgeForSelf() {
        guard let currentUserID = Auth.auth().currentUser?.uid else { return }
        let badgeRef = Database.database().reference().child(userWorkoutsEntity).child(currentUserID).child(mindfulness.id).child("badge")
        badgeRef.runTransactionBlock({ (mutableData) -> TransactionResult in
            var value = mutableData.value as? Int
            value = 0
            mutableData.value = value!
            return TransactionResult.success(withValue: mutableData)
        })
    }
}

extension MindfulnessViewController: UpdateInvitees {
    func updateInvitees(selectedFalconUsers: [User]) {
        if let inviteesRow: ButtonRow = form.rowBy(tag: "Participants") {
            if !selectedFalconUsers.isEmpty {
                self.selectedFalconUsers = selectedFalconUsers
                var participantCount = self.selectedFalconUsers.count
                // If user is creating this activity (admin)
                if mindfulness.admin == nil || mindfulness.admin == Auth.auth().currentUser?.uid {
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
//                let createWorkout = MindfulnessActions(mindfulness: mindfulness, active: active, selectedFalconUsers: selectedFalconUsers)
//                createWorkout.updateMindfulnessParticipants()
                hideActivityIndicator()
            }
            
        }
    }
}
