//
//  CalendarDetailViewController.swift
//  Plot
//
//  Created by Cory McHattie on 7/28/22.
//  Copyright © 2022 Immature Creations. All rights reserved.
//

import UIKit
import Eureka
import Firebase

protocol CalendarDetailDelegate: AnyObject {
    func update()
}

class CalendarDetailViewController: FormViewController {
    weak var delegate : CalendarDetailDelegate?
    
    var calendar: CalendarType!
    
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
        
        if calendar.source == CalendarSourceOptions.apple.name || calendar.source == CalendarSourceOptions.google.name {
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
        
        if calendar.source == CalendarSourceOptions.plot.name {
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
        if let _ = calendar {
            title = "Calendar"
            active = true
            
        } else if let currentUser = Auth.auth().currentUser?.uid {
            title = "New Calendar"
            let ID = Database.database().reference().child(userCalendarEntity).child(currentUser).childByAutoId().key ?? ""
            calendar = CalendarType(id: ID, name: nil, color: nil, source: CalendarSourceOptions.plot.name, admin: currentUser)
        }
    }
    
    @IBAction func cancel(_ sender: AnyObject) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func create(_ sender: AnyObject) {
        self.showActivityIndicator()
        let createCalendar = CalendarActions(calendar: calendar, active: active, selectedFalconUsers: selectedFalconUsers)
        createCalendar.createNewCalendar()
        self.hideActivityIndicator()
        
        if navigationItem.leftBarButtonItem != nil {
            self.dismiss(animated: true, completion: nil)
        } else {
            self.navigationController?.popViewController(animated: true)
            self.updateDiscoverDelegate?.itemCreated()
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
                $0.value = self.calendar.name
                self.navigationItem.rightBarButtonItem?.isEnabled = true
            } else {
                $0.cell.textField.becomeFirstResponder()
            }
        }.onChange() { [unowned self] row in
            self.calendar.name = row.value
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
            if self.active, let color = self.calendar.color {
                row.value = UIColor(ciColor: CIColor(string: color))
            }
            if calendar.source != CalendarSourceOptions.plot.name {
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
                calendar.color = CIColor(color: color).stringRepresentation
                guard let currentUserID = Auth.auth().currentUser?.uid, let id = calendar.id else { return }
                let userReference = Database.database().reference().child(userCalendarEntity).child(currentUserID).child(id)
                let values:[String : Any] = ["color": CIColor(color: color).stringRepresentation]
                userReference.updateChildValues(values)
            }
        }
        
        
        if calendar.source == CalendarSourceOptions.plot.name {
            form.last!
            <<< TextAreaRow("Description") {
                $0.cell.backgroundColor = .secondarySystemGroupedBackground
                $0.cell.textView?.backgroundColor = .secondarySystemGroupedBackground
                $0.cell.textView?.textColor = .label
                $0.cell.placeholderLabel?.textColor = .secondaryLabel
                $0.placeholder = $0.tag
                if self.active && self.calendar.description != "nothing" && self.calendar.description != nil {
                    $0.value = self.calendar.description
                }
            }.cellUpdate({ (cell, row) in
                cell.backgroundColor = .secondarySystemGroupedBackground
                cell.textView?.backgroundColor = .secondarySystemGroupedBackground
                cell.textView?.textColor = .label
            }).onChange() { [unowned self] row in
                self.calendar.description = row.value
                if row.value == nil, self.active, let id = calendar.id {
                    let reference = Database.database().reference().child(calendarEntity).child(id).child("description")
                    reference.removeValue()
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
                if calendar.admin == nil || calendar.admin == Auth.auth().currentUser?.uid {
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
        destination.ownerID = calendar.admin
        destination.users = uniqueUsers
        destination.filteredUsers = uniqueUsers
        if !selectedFalconUsers.isEmpty {
            destination.priorSelectedUsers = selectedFalconUsers
        }
        destination.delegate = self
        self.navigationController?.pushViewController(destination, animated: true)
    }
    
    func getSelectedFalconUsers(forCalendar calendar: CalendarType, completion: @escaping ([User])->()) {
        guard let participantsIDs = calendar.participantsIDs, let currentUserID = Auth.auth().currentUser?.uid else {
            return
        }
        var selectedFalconUsers = [User]()
        let group = DispatchGroup()
        for id in participantsIDs {
            // Only if the current user is created this activity
            if calendar.admin == currentUserID && id == currentUserID {
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

extension CalendarDetailViewController: UpdateInvitees {
    func updateInvitees(selectedFalconUsers: [User]) {
        if let inviteesRow: LabelRow = form.rowBy(tag: "Participants") {
            self.selectedFalconUsers = selectedFalconUsers
            if calendar.admin == nil || calendar.admin == Auth.auth().currentUser?.uid {
                inviteesRow.value = String(self.selectedFalconUsers.count + 1)
            } else {
                inviteesRow.value = String(self.selectedFalconUsers.count)
            }
            inviteesRow.updateCell()
            
            if active {
                self.showActivityIndicator()
                let createCalendar = CalendarActions(calendar: self.calendar, active: self.active, selectedFalconUsers: self.selectedFalconUsers)
                createCalendar.updateCalendarParticipants()
                self.hideActivityIndicator()
                
            }
            
        }
    }
}

extension CalendarDetailViewController: UITextViewDelegate {
    
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

