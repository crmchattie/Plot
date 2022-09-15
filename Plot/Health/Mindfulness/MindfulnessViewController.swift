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
import HealthKit

protocol UpdateMindfulnessDelegate: AnyObject {
    func updateMindfulness(mindfulness: Mindfulness)
}

class MindfulnessViewController: FormViewController {
    var mindfulness: Mindfulness!
    var container: Container!
    var eventList = [Activity]()
    var purchaseList = [Transaction]()
    var taskList = [Activity]()
    var eventIndex: Int = 0
    var purchaseIndex: Int = 0
    var taskIndex: Int = 0
        
    fileprivate var productIndex: Int = 0
    
    let numberFormatter = NumberFormatter()
        
    lazy var users: [User] = networkController.userService.users
    lazy var filteredUsers: [User] = networkController.userService.users
    lazy var tasks: [Activity] = networkController.activityService.tasks
    lazy var events: [Activity] = networkController.activityService.events
    lazy var transactions: [Transaction] = networkController.financeService.transactions
    
    var selectedFalconUsers = [User]()
    
    //added for EventViewController
    var movingBackwards: Bool = false
    var active: Bool = false
    var sectionChanged: Bool = false
    
    weak var delegate : UpdateMindfulnessDelegate?
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
        
        if mindfulness == nil {
            title = "New Mindfulness"
            active = false
            if let currentUserID = Auth.auth().currentUser?.uid {
                let ID = Database.database().reference().child(userMindfulnessEntity).child(currentUserID).childByAutoId().key ?? ""
                mindfulness = Mindfulness(id: ID, name: "Name", admin: currentUserID, lastModifiedDate: Date(), createdDate: Date(), startDateTime: nil, endDateTime: nil, user_created: true)
                
                //need to fix; sloppy code that is used to stop an event from being created
                if let container = container {
                    mindfulness.containerID = container.id
                }
            }
        } else {
            active = true
            title = "Mindfulness"
        }
        
        configureTableView()
        setupRightBarButton()
        initializeForm()
        updateLength()
        setupLists()
        
        if active {
            for row in form.allRows {
                if row.tag != "sections" && row.tag != "Tasks" && row.tag != "Events" && row.tag != "Transactions" && row.tag != "taskButton" && row.tag != "scheduleButton" && row.tag != "transactionButton" && row.tag != "Participants" && row.tag != "Name" {
                    row.baseCell.isUserInteractionEnabled = false
                }
            }
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        if movingBackwards {
            self.delegate?.updateMindfulness(mindfulness: mindfulness)
        }
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .default
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
    }
    
    func setupRightBarButton() {
        if !active {
            let plusBarButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(create))
            navigationItem.rightBarButtonItem = plusBarButton
            if navigationItem.leftBarButtonItem != nil {
                navigationItem.leftBarButtonItem?.action = #selector(cancel)
            }
        } else {
            let plusBarButton =  UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(create))
            navigationItem.rightBarButtonItem = plusBarButton
            navigationItem.rightBarButtonItem?.isEnabled = true
        }
    }
    
    @IBAction func cancel(_ sender: AnyObject) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @objc fileprivate func create() {
        showActivityIndicator()
        let createMindfulness = MindfulnessActions(mindfulness: self.mindfulness, active: self.active, selectedFalconUsers: self.selectedFalconUsers)
        createMindfulness.createNewMindfulness()
        self.delegate?.updateMindfulness(mindfulness: self.mindfulness)
        self.updateDiscoverDelegate?.itemCreated()
        self.hideActivityIndicator()
        
        if self.navigationItem.leftBarButtonItem != nil {
            self.dismiss(animated: true, completion: nil)
        } else {
            self.navigationController?.popViewController(animated: true)
        }
        
        if active && false {
            let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            
            alert.addAction(UIAlertAction(title: "Update Mindfulness", style: .default, handler: { (_) in
                print("User click Approve button")
                
                // update
                self.showActivityIndicator()
                self.updateLists()
                let createMindfulness = MindfulnessActions(mindfulness: self.mindfulness, active: self.active, selectedFalconUsers: self.selectedFalconUsers)
                createMindfulness.createNewMindfulness()
                self.hideActivityIndicator()
                if self.navigationItem.leftBarButtonItem != nil {
                    self.dismiss(animated: true, completion: nil)
                } else {
                    self.navigationController?.popViewController(animated: true)
                }
                
            }))
            
            alert.addAction(UIAlertAction(title: "Duplicate Mindfulness", style: .default, handler: { (_) in
                print("User click Approve button")
                // create new mindfulness with updated time
                guard self.currentReachabilityStatus != .notReachable else {
                    basicErrorAlertWith(title: basicErrorTitleForAlert, message: noInternetError, controller: self)
                    return
                }
                
                if let currentUserID = Auth.auth().currentUser?.uid {
                    self.showActivityIndicator()
                    self.updateLists()
                    let createMindfulness = MindfulnessActions(mindfulness: self.mindfulness, active: self.active, selectedFalconUsers: self.selectedFalconUsers)
                    createMindfulness.createNewMindfulness()
                    
                    //duplicate mindfulness
                    let newMindfulnessID = Database.database().reference().child(userMindfulnessEntity).child(currentUserID).childByAutoId().key ?? ""
                    var newMindfulness = self.mindfulness!
                    newMindfulness.id = newMindfulnessID
                    newMindfulness.admin = currentUserID
                    newMindfulness.participantsIDs = nil
                    
                    let createNewMindfulness = MindfulnessActions(mindfulness: newMindfulness, active: false, selectedFalconUsers: [])
                    createNewMindfulness.createNewMindfulness()
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
    
    func initializeForm() {
        form +++
            Section()
            
            <<< TextRow("Name") {
                $0.cell.backgroundColor = .secondarySystemGroupedBackground
                $0.cell.textField?.textColor = .label
                $0.placeholderColor = .secondaryLabel
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
                cell.backgroundColor = .secondarySystemGroupedBackground
                cell.textField?.textColor = .label
                row.placeholderColor = .secondaryLabel
            }
            
            <<< DateTimeInlineRow("Starts") {
                $0.cell.backgroundColor = .secondarySystemGroupedBackground
                $0.cell.textLabel?.textColor = .label
                $0.cell.detailTextLabel?.textColor = .secondaryLabel
                $0.title = $0.tag
                $0.dateFormatter?.dateStyle = .medium
                $0.dateFormatter?.timeStyle = .short
                if self.active {
                    $0.value = self.mindfulness!.startDateTime
                } else {
                    let original = Date()
                    let rounded = Date(timeIntervalSinceReferenceDate:
                                        (original.timeIntervalSinceReferenceDate / 300.0).rounded(.toNearestOrEven) * 300.0)
                    $0.value = rounded
                    self.mindfulness.startDateTime = $0.value
                }
            }.onChange { [weak self] row in
                let endRow: DateTimeInlineRow! = self?.form.rowBy(tag: "Ends")
                if row.value?.compare(endRow.value!) == .orderedDescending {
                    endRow.value = Date(timeInterval: 0, since: row.value!)
                    endRow.updateCell()
                }
                self!.updateLength()
                self!.mindfulness.startDateTime = row.value
            }.onExpandInlineRow { cell, row, inlineRow in
                inlineRow.cellUpdate() { cell, row in
                    row.cell.backgroundColor = .secondarySystemGroupedBackground
                    row.cell.tintColor = .secondarySystemGroupedBackground
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
                if self.active {
                    $0.value = self.mindfulness!.endDateTime
                } else {
                    let original = Date()
                    let rounded = Date(timeIntervalSinceReferenceDate:
                                        (original.timeIntervalSinceReferenceDate / 300.0).rounded(.toNearestOrEven) * 300.0)
                    $0.value = rounded
                    self.mindfulness.endDateTime = $0.value
                }
            }.onChange { [weak self] row in
                let startRow: DateTimeInlineRow! = self?.form.rowBy(tag: "Starts")
                if row.value?.compare(startRow.value!) == .orderedAscending {
                    startRow.value = Date(timeInterval: 0, since: row.value!)
                    startRow.updateCell()
                }
                self!.updateLength()
                self!.mindfulness.endDateTime = row.value
            }.onExpandInlineRow { cell, row, inlineRow in
                inlineRow.cellUpdate() { cell, row in
                    row.cell.backgroundColor = .secondarySystemGroupedBackground
                    row.cell.tintColor = .secondarySystemGroupedBackground
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
            }
        
        
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
                if mindfulness.admin == nil || mindfulness.admin == Auth.auth().currentUser?.uid {
                    row.value = String(self.selectedFalconUsers.count + 1)
                } else {
                    row.value = String(self.selectedFalconUsers.count)
                }
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
        
        if delegate == nil, active, (mindfulness?.participantsIDs?.contains(Auth.auth().currentUser?.uid ?? "") ?? false) {
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
            mindfulness.length = Double(length)
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
        destination.ownerID = mindfulness.admin
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
    
    func getSelectedFalconUsers(forMindfulness mindfulness: Mindfulness, completion: @escaping ([User])->()) {
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
        let badgeRef = Database.database().reference().child(userMindfulnessEntity).child(currentUserID).child(mindfulness.id).child("badge")
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
        if let inviteesRow: LabelRow = form.rowBy(tag: "Participants") {
            self.selectedFalconUsers = selectedFalconUsers
            if mindfulness.admin == nil || mindfulness.admin == Auth.auth().currentUser?.uid {
                inviteesRow.value = String(self.selectedFalconUsers.count + 1)
            } else {
                inviteesRow.value = String(self.selectedFalconUsers.count)
            }
            inviteesRow.updateCell()
            
            if active {
                self.showActivityIndicator()
                if let container = container {
                    ContainerFunctions.updateParticipants(containerID: container.id, selectedFalconUsers: selectedFalconUsers)
                } else {
                    let createMindfulness = MindfulnessActions(mindfulness: self.mindfulness, active: self.active, selectedFalconUsers: self.selectedFalconUsers)
                    createMindfulness.createNewMindfulness()
                }
                self.hideActivityIndicator()
            }
            
        }
    }
}
