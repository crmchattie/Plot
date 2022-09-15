//
//  ListDetailViewController.swift
//  Plot
//
//  Created by Cory McHattie on 8/20/22.
//  Copyright © 2022 Immature Creations. All rights reserved.
//

import UIKit
import Eureka
import Firebase

protocol ListDetailDelegate: AnyObject {
    func update()
}

class ListDetailViewController: FormViewController {
    weak var delegate : ListDetailDelegate?
    
    var list: ListType!
    
    lazy var users: [User] = networkController.userService.users
    lazy var filteredUsers: [User] = networkController.userService.users
    
    var selectedFalconUsers = [User]()
    
    var active: Bool = false
    
    weak var updateDiscoverDelegate : UpdateDiscover?
    
    let numberFormatter = NumberFormatter()
    
    // create dateFormatter with UTC time format
    let isodateFormatter = ISO8601DateFormatter()
    let dateFormatterPrint = DateFormatter()
    
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
                
        
        
        numberFormatter.numberStyle = .currency
        numberFormatter.maximumFractionDigits = 0
        dateFormatterPrint.dateFormat = "E, MMM d, yyyy"
        
        setupVariables()
        configureTableView()
        initializeForm()
        
        if list.source == ListSourceOptions.apple.name || list.source == ListSourceOptions.google.name {
            for row in form.rows {
                row.baseCell.isUserInteractionEnabled = false
            }
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
        
        
        if list.source == ListSourceOptions.plot.name {
            if active {
                let addBarButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(create))
                navigationItem.rightBarButtonItem = addBarButton
                if navigationItem.leftBarButtonItem != nil {
                    navigationItem.leftBarButtonItem?.action = #selector(cancel)
                }
            } else {
                let addBarButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(create))
                navigationItem.rightBarButtonItem = addBarButton
                if navigationItem.leftBarButtonItem != nil {
                    navigationItem.leftBarButtonItem?.action = #selector(cancel)
                }
            }
        }
    }
    
    func setupVariables() {
        if let _ = list {
            title = "List"
            active = true
            
        } else if let currentUser = Auth.auth().currentUser?.uid {
            title = "New List"
            let ID = Database.database().reference().child(userListEntity).child(currentUser).childByAutoId().key ?? ""
            list = ListType(id: ID, name: nil, color: nil, source: ListSourceOptions.plot.name, admin: currentUser)
        }
    }
    
    @IBAction func cancel(_ sender: AnyObject) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func create(_ sender: AnyObject) {
        self.showActivityIndicator()
        let createList = ListActions(list: list, active: active, selectedFalconUsers: selectedFalconUsers)
        createList.createNewList()
        self.hideActivityIndicator()
        self.updateDiscoverDelegate?.itemCreated()
        if navigationItem.leftBarButtonItem != nil {
            self.dismiss(animated: true, completion: nil)
        } else {
            self.navigationController?.popViewController(animated: true)
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
            if self.active {
                $0.value = self.list.name
                self.navigationItem.rightBarButtonItem?.isEnabled = true
            } else {
                $0.cell.textField.becomeFirstResponder()
            }
        }.onChange() { [unowned self] row in
            self.list.name = row.value
            if row.value == nil {
                self.navigationItem.rightBarButtonItem?.isEnabled = false
            } else {
                self.navigationItem.rightBarButtonItem?.isEnabled = true
            }
        }.cellUpdate { cell, row in
            cell.backgroundColor = .secondarySystemGroupedBackground
            cell.textField?.textColor = .label
        }
        
        <<< ColorPushRow<UIColor>("Color") { row in
            row.cell.backgroundColor = .secondarySystemGroupedBackground
            row.cell.textLabel?.textColor = .label
            row.title = row.tag
            row.cell.detailTextLabel?.text = nil
//            row.cell.accessoryType = .disclosureIndicator
            if self.active, let color = self.list.color {
                row.value = UIColor(ciColor: CIColor(string: color))
            }
            if list.source != ListSourceOptions.plot.name {
                row.cell.accessoryType = .none
            }
            row.options = ChartColors.palette()
        }.onPresent { from, to in
            to.title = "Color"
            to.extendedLayoutIncludesOpaqueBars = true
            to.tableViewStyle = .insetGrouped
            to.selectableRowCellUpdate = { cell, row in
                to.navigationController?.navigationBar.backgroundColor = .systemGroupedBackground
                to.tableView.backgroundColor = .systemGroupedBackground
                to.tableView.separatorStyle = .none
                if let index = row.indexPath?.row {
                    cell.selectionStyle = .none
                    cell.backgroundColor = ChartColors.palette()[index]
                    cell.textLabel?.text = nil
                    cell.detailTextLabel?.text = nil
                    cell.accessoryType = .none
                }
            }
        }.cellUpdate { cell, row in
            cell.backgroundColor = .secondarySystemGroupedBackground
            cell.textLabel?.textColor = .label
            cell.detailTextLabel?.text = nil
        }.onChange() { [unowned self] row in
            if let color = row.value {
                list.color = CIColor(color: color).stringRepresentation
                guard let currentUserID = Auth.auth().currentUser?.uid, let id = list.id else { return }
                let userReference = Database.database().reference().child(userListEntity).child(currentUserID).child(id)
                let values:[String : Any] = ["color": CIColor(color: color).stringRepresentation]
                userReference.updateChildValues(values)
            }
        }
        
        if list.source == ListSourceOptions.plot.name {
            form.last!
            <<< TextAreaRow("Description") {
                $0.cell.backgroundColor = .secondarySystemGroupedBackground
                $0.cell.textView?.backgroundColor = .secondarySystemGroupedBackground
                $0.cell.textView?.textColor = .label
                $0.cell.placeholderLabel?.textColor = .secondaryLabel
                $0.placeholder = $0.tag
                if self.active && self.list.description != "nothing" && self.list.description != nil {
                    $0.value = self.list.description
                }
            }.cellUpdate({ (cell, row) in
                cell.backgroundColor = .secondarySystemGroupedBackground
                cell.textView?.backgroundColor = .secondarySystemGroupedBackground
                cell.textView?.textColor = .label
            }).onChange() { [unowned self] row in
                self.list.description = row.value
                if row.value == nil, self.active, let id = list.id {
                    let reference = Database.database().reference().child(listEntity).child(id).child("description")
                    reference.removeValue()
                }
            }
            
//            <<< LabelRow("Category") { row in
//                row.cell.backgroundColor = .secondarySystemGroupedBackground
//                row.cell.textLabel?.textColor = .label
//                row.cell.detailTextLabel?.textColor = .secondaryLabel
//                row.cell.accessoryType = .disclosureIndicator
//                row.cell.selectionStyle = .default
//                row.title = row.tag
//                if self.active && self.list.category != nil {
//                    row.value = self.list.category
//                } else {
//                    row.value = "Uncategorized"
//                }
//            }.onCellSelection({ _, row in
//                self.openLevel(value: row.value ?? "Uncategorized", level: "Category")
//            }).cellUpdate { cell, row in
//                cell.accessoryType = .disclosureIndicator
//                cell.backgroundColor = .secondarySystemGroupedBackground
//                cell.textLabel?.textColor = .label
//                cell.detailTextLabel?.textColor = .secondaryLabel
//                cell.textLabel?.textAlignment = .left
//            }
            
            <<< LabelRow("Participants") { row in
                row.cell.backgroundColor = .secondarySystemGroupedBackground
                row.cell.textLabel?.textColor = .label
                row.cell.detailTextLabel?.textColor = .secondaryLabel
                row.cell.accessoryType = .disclosureIndicator
                row.cell.textLabel?.textAlignment = .left
                row.cell.selectionStyle = .default
                row.title = row.tag
                if list.admin == nil || list.admin == Auth.auth().currentUser?.uid {
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
            
    }
    
    func openLevel(value: String, level: String) {
        let destination = ActivityLevelViewController()
        destination.delegate = self
        destination.value = value
        destination.level = level
        self.navigationController?.pushViewController(destination, animated: true)
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
        destination.ownerID = list.admin
        destination.users = uniqueUsers
        destination.filteredUsers = uniqueUsers
        if !selectedFalconUsers.isEmpty {
            destination.priorSelectedUsers = selectedFalconUsers
        }
        destination.delegate = self
        self.navigationController?.pushViewController(destination, animated: true)
    }
    
    func getSelectedFalconUsers(forList list: ListType, completion: @escaping ([User])->()) {
        guard let participantsIDs = list.participantsIDs, let currentUserID = Auth.auth().currentUser?.uid else {
            return
        }
        var selectedFalconUsers = [User]()
        let group = DispatchGroup()
        for id in participantsIDs {
            // Only if the current user is created this activity
            if list.admin == currentUserID && id == currentUserID {
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
    
    func showActivityIndicator() {
        if let tabController = self.tabBarController {
            self.showSpinner(onView: tabController.view)
        }
        self.navigationController?.view.isUserInteractionEnabled = false
    }
    
    func hideActivityIndicator() {
        self.navigationController?.view.isUserInteractionEnabled = true
        self.removeSpinner()
    }
    
}

extension ListDetailViewController: UpdateActivityLevelDelegate {
    func update(value: String, level: String) {
        if let row: LabelRow = form.rowBy(tag: level) {
            row.value = value
            row.updateCell()
            if level == "Category" {
                self.list.category = value
            }
        }
    }
}

extension ListDetailViewController: UpdateInvitees {
    func updateInvitees(selectedFalconUsers: [User]) {
        if let inviteesRow: LabelRow = form.rowBy(tag: "Participants") {
            self.selectedFalconUsers = selectedFalconUsers
            if list.admin == nil || list.admin == Auth.auth().currentUser?.uid {
                inviteesRow.value = String(self.selectedFalconUsers.count + 1)
            } else {
                inviteesRow.value = String(self.selectedFalconUsers.count)
            }
            inviteesRow.updateCell()
            
            if active {
                self.showActivityIndicator()
                let createList = ListActions(list: self.list, active: self.active, selectedFalconUsers: self.selectedFalconUsers)
                createList.updateListParticipants()
                self.hideActivityIndicator()
                
            }
            
        }
    }
}

extension ListDetailViewController: UITextViewDelegate {
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.textColor == FalconPalette.defaultBlue {
            textView.text = nil
            textView.textColor = .label
        }
        
        
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.isEmpty {
            textView.text = "Description"
        }
    }
    
    func textViewDidChange(_ textView: UITextView) {
        
    }
    
}

