//
//  FinanceHoldingViewController.swift
//  Plot
//
//  Created by Cory McHattie on 2/15/21.
//  Copyright © 2021 Immature Creations. All rights reserved.
//

import UIKit
import Eureka
import Firebase
import CodableFirebase

protocol UpdateHoldingDelegate: AnyObject {
    func updateHolding(holding: MXHolding)
}

class FinanceHoldingViewController: FormViewController {
    var holding: MXHolding!
    
    var accounts: [MXAccount] {
        return networkController.financeService.accounts
    }
    lazy var users: [User] = networkController.userService.users
    lazy var filteredUsers: [User] = networkController.userService.users
    lazy var activities: [Activity] = networkController.activityService.activities
    
    var selectedFalconUsers = [User]()
    
    var userNames : [String] = []
    var userNamesString: String = ""
    
    var active: Bool = false
    
    //added for EventViewController
    var movingBackwards: Bool = false
    
    weak var delegate : UpdateHoldingDelegate?
    weak var updateDiscoverDelegate : UpdateDiscover?
    
    var status = false
    
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
        dateFormatterPrint.dateFormat = "E, MMM d, yyyy"
        setupVariables()
        configureTableView()
        initializeForm()
                
        if !(holding.user_created ?? false) {
            for row in form.rows {
                if row.tag != "Should Link" && row.tag != "Tags" && row.tag != "Participants" && row.tag != "Description" {
                    row.baseCell.isUserInteractionEnabled = false
                }
            }
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        if movingBackwards {
            self.delegate?.updateHolding(holding: holding)
        }
    }
    
    fileprivate func setupVariables() {
        if let _ = holding {
            title = "Investment"
            active = true
            numberFormatter.currencyCode = holding.currency_code
            
            var participantCount = self.selectedFalconUsers.count
            // If user is creating this activity (admin)
            if holding.admin == nil || holding.admin == Auth.auth().currentUser?.uid {
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
        } else if let currentUser = Auth.auth().currentUser?.uid {
            title = "New Investment"
            let ID = Database.database().reference().child(userFinancialHoldingsEntity).child(currentUser).childByAutoId().key ?? ""
            let date = isodateFormatter.string(from: Date())
            holding = MXHolding(description: "Holding Name", market_value: 0, created_at: date, guid: ID, user_guid: currentUser, holding_type: .unknownType, user_created: true, admin: currentUser)
            numberFormatter.currencyCode = "USD"
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
        
        if active {
            let addBarButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(create))
            navigationItem.rightBarButtonItem = addBarButton
        } else {
            let addBarButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(create))
            navigationItem.rightBarButtonItem = addBarButton
            if navigationItem.leftBarButtonItem != nil {
                navigationItem.leftBarButtonItem?.action = #selector(cancel)
            }
        }
        
    }
    
    @IBAction func cancel(_ sender: AnyObject) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func create(_ sender: AnyObject) {
        movingBackwards = false
        if holding.user_created ?? false {
            self.showActivityIndicator()
            let createHolding = HoldingActions(holding: self.holding, active: self.active, selectedFalconUsers: self.selectedFalconUsers)
            createHolding.createNewHolding()
            self.hideActivityIndicator()
        }
        self.delegate?.updateHolding(holding: holding)
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
                $0.cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                $0.cell.textField?.textColor = ThemeManager.currentTheme().generalTitleColor
                $0.placeholderColor = ThemeManager.currentTheme().generalSubtitleColor
                $0.placeholder = $0.tag
                if active {
                    self.navigationItem.rightBarButtonItem?.isEnabled = true
                    $0.value = holding.description
                } else {
                    self.navigationItem.rightBarButtonItem?.isEnabled = false
                    $0.cell.textField.becomeFirstResponder()
                }
            }.cellUpdate { cell, row in
                cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                cell.textField?.textColor = ThemeManager.currentTheme().generalTitleColor
                row.placeholderColor = ThemeManager.currentTheme().generalSubtitleColor
            }.onChange { row in
                if let value = row.value {
                    self.holding.description = value
                    if let currentUser = Auth.auth().currentUser?.uid, self.active {
                        let reference = Database.database().reference().child(userFinancialHoldingsEntity).child(currentUser).child(self.holding.guid).child("description")
                        reference.setValue(value)
                    }
                }
                if row.value == nil {
                    self.navigationItem.rightBarButtonItem?.isEnabled = false
                } else {
                    self.navigationItem.rightBarButtonItem?.isEnabled = true
                }
            }
            
        if let symbol = holding.symbol, symbol != holding.description {
            form.last!
            <<< TextRow("Symbol") {
                $0.cell.isUserInteractionEnabled = false
                $0.cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                $0.cell.textField?.textColor = ThemeManager.currentTheme().generalSubtitleColor
                $0.title = $0.tag
                $0.value = symbol
            }.cellUpdate { cell, row in
                cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                cell.textField?.textColor = ThemeManager.currentTheme().generalSubtitleColor
            }
        }
        
        if (holding.holding_type != nil) || (holding.user_created != nil && holding.user_created ?? false) {
            form.last!
            <<< PushRow<String>("Type") { row in
                row.cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                row.cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                row.cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
                row.title = row.tag
                row.value = holding.holding_type?.name
                row.options = []
                MXHoldingType.allCases.forEach {
                    row.options?.append($0.name)
                }
            }.onPresent { from, to in
                to.title = "Type"
                to.tableViewStyle = .insetGrouped
                to.dismissOnSelection = true
                to.dismissOnChange = true
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
                cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
                if !(self.holding?.user_created ?? false) {
                    row.cell.accessoryType = .none
                }
            }.onChange { row in
                if let value = row.value, let type = MXHoldingType(rawValue: value) {
                    self.holding.holding_type = type
//                    let reference = Database.database().reference().child(financialAccountsEntity).child(self.holding.guid).child("holding_type")
//                    reference.setValue(value)
                }
            }
        }
                
//            <<< TextAreaRow("Description") {
//                $0.cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
//                $0.cell.textView?.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
//                $0.cell.textView?.textColor = ThemeManager.currentTheme().generalTitleColor
//                $0.cell.placeholderLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
//                $0.placeholder = $0.tag
//                $0.value = holding.holdingDescription
//                }.cellUpdate({ (cell, row) in
//                    cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
//                    cell.textView?.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
//                    cell.textView?.textColor = ThemeManager.currentTheme().generalTitleColor
//                    cell.placeholderLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
//                }).onChange { row in
//                    let reference = Database.database().reference().child(financialHoldingsEntity).child(self.holding.guid).child("holdingDescription")
//                    self.holding.holdingDescription = row.value
//                    reference.setValue(row.value)
//                }
            
        form.last!
            <<< LabelRow("Last Updated") {
                $0.cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                $0.cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                $0.cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
                $0.title = $0.tag
                if let date = isodateFormatter.date(from: holding.updated_at) {
                    $0.value = dateFormatterPrint.string(from: date)
                }
            }.cellUpdate { cell, row in
                cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
            }
            
        if (holding.cost_basis != nil) || (holding.user_created != nil && holding.user_created ?? false) {
            form.last!
            <<< DecimalRow("Cost Basis") {
                $0.cell.isUserInteractionEnabled = holding.user_created ?? false
                $0.cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                $0.cell.textField?.textColor = ThemeManager.currentTheme().generalSubtitleColor
                $0.title = $0.tag
                $0.formatter = numberFormatter
                $0.value = holding.cost_basis ?? 0
            }.cellUpdate { cell, row in
                cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                cell.textField?.textColor = ThemeManager.currentTheme().generalSubtitleColor
            }.onChange { row in
                if let value = row.value {
                    self.updateTheDate()
                    self.holding.cost_basis = value
//                    let reference = Database.database().reference().child(financialHoldingsEntity).child(self.holding.guid).child("cost_basis")
//                    reference.setValue(value)
                }
            }
        }
            
        form.last!
            <<< DecimalRow("Market Value") {
                $0.cell.isUserInteractionEnabled = holding.user_created ?? false
                $0.cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                $0.cell.textField?.textColor = ThemeManager.currentTheme().generalSubtitleColor
                $0.title = $0.tag
                $0.formatter = numberFormatter
                $0.value = holding.market_value
            }.cellUpdate { cell, row in
                cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                cell.textField?.textColor = ThemeManager.currentTheme().generalSubtitleColor
            }.onChange { row in
                if let value = row.value {
                    self.updateTheDate()
                    self.holding.market_value = value
//                    let reference = Database.database().reference().child(financialHoldingsEntity).child(self.holding.guid).child("market_value")
//                    reference.setValue(value)
                }
            }
            
        if let marketValue = holding.market_value, let costBasis = holding.cost_basis, costBasis != 0 {
            form.last!
                <<< DecimalRow("Total Return") {
                    let percentFormatter = NumberFormatter()
                    percentFormatter.numberStyle = .percent
                    percentFormatter.positivePrefix = percentFormatter.plusSign
                    percentFormatter.maximumFractionDigits = 0
                    percentFormatter.minimumFractionDigits = 0
                    $0.cell.isUserInteractionEnabled = holding.user_created ?? false
                    $0.cell.textField?.textColor = ThemeManager.currentTheme().generalSubtitleColor
                    $0.title = $0.tag
                    $0.formatter = percentFormatter
                    $0.value = marketValue / costBasis - 1
                }.cellUpdate { cell, row in
                    cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                    if marketValue / costBasis - 1 < 0 {
                        cell.textField?.textColor = .systemRed
                    } else {
                        cell.textField?.textColor = .systemGreen
                    }
                }
        }
            
        form.last!
            <<< CheckRow("Should Link") {
                $0.cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                $0.cell.tintColor = FalconPalette.defaultBlue
                $0.cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                $0.cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                $0.cell.accessoryType = .checkmark
                if self.holding.should_link ?? true {
                    $0.title = "Included in Financial Profile"
                    $0.value = true
                } else {
                    $0.title = "Not Included in Financial Profile"
                    $0.value = false
                }
            }.cellUpdate { cell, row in
                cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                cell.tintColor = FalconPalette.defaultBlue
                cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
            }.onChange { row in
                row.title = row.value! ? "Included in Financial Profile" : "Not Included in Financial Profile"
                row.updateCell()
                self.holding.should_link = row.value
                if let currentUser = Auth.auth().currentUser?.uid, self.active {
                    let reference = Database.database().reference().child(userFinancialHoldingsEntity).child(currentUser).child(self.holding.guid).child("should_link")
                    reference.setValue(row.value!)
                }
            }
            
            <<< PushRow<String>("Account") { row in
                row.cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                row.cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                row.cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
                row.title = row.tag
                if let value = holding.account_name {
                    row.value = value
                } else if holding.account_name == nil, let value = holding.account_guid {
                    if let account = self.accounts.first(where: { $0.guid == value }) {
                        row.value = account.name
                    }
                }
                row.options = []
                accounts.forEach {
                    row.options?.append($0.name.capitalized)
                }
            }.onPresent { from, to in
                to.title = "Accounts"
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
                if !(self.holding?.user_created ?? false) {
                    row.cell.accessoryType = .none
                }
            }.onChange({ row in
                self.holding.account_name = row.value
//                let reference = Database.database().reference().child(financialHoldingsEntity).child(self.holding.guid).child("account_name")
//                reference.setValue(row.value)
            })
        
            <<< LabelRow("Tags") { row in
                row.cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                row.cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                row.cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                row.cell.accessoryType = .disclosureIndicator
                row.cell.textLabel?.textAlignment = .left
                row.cell.selectionStyle = .default
                row.title = row.tag
            }.onCellSelection({ _, row in
                self.openTags()
            }).cellUpdate { cell, row in
                cell.accessoryType = .disclosureIndicator
                cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                cell.textLabel?.textAlignment = .left
            }
        
            
            
//        form +++
//            Section()
//            <<< ButtonRow("Participants") { row in
//                row.cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
//                row.cell.textLabel?.textAlignment = .left
//                row.cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
//                row.cell.accessoryType = .disclosureIndicator
//                row.title = row.tag
//                if active {
//                    row.title = self.userNamesString
//                }
//                }.onCellSelection({ _,_ in
//                    self.openParticipantsInviter()
//                }).cellUpdate { cell, row in
//                    cell.accessoryType = .disclosureIndicator
//                    cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
//                    cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
//                    cell.textLabel?.textAlignment = .left
//                }
        
    }
    
    fileprivate func updateTheDate() {
        if let row: TextRow = form.rowBy(tag: "Last Updated") {
            let date = self.isodateFormatter.string(from: Date())
            row.value = date
            row.updateCell()
            self.holding.updated_at = date
//            Database.database().reference().child(financialHoldingsEntity).child(self.holding.guid).child("updated_at").setValue(date)
        }
    }
    
    @objc fileprivate func openTags() {
        print("openTags")
        let destination = FinanceTagsViewController()
        destination.delegate = self
        destination.tags = holding.tags
        destination.ID = holding.guid
        destination.type = "holding"
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
        destination.users = uniqueUsers
        destination.filteredUsers = uniqueUsers
        if !selectedFalconUsers.isEmpty {
            destination.priorSelectedUsers = selectedFalconUsers
        }
        destination.delegate = self
        self.navigationController?.pushViewController(destination, animated: true)
    }
    
    func getSelectedFalconUsers(forHolding holding: MXHolding, completion: @escaping ([User])->()) {
        guard let participantsIDs = holding.participantsIDs, let currentUserID = Auth.auth().currentUser?.uid else {
            return
        }
        var selectedFalconUsers = [User]()
        let group = DispatchGroup()
        for id in participantsIDs {
            // Only if the current user is created this activity
            if holding.admin == currentUserID && id == currentUserID {
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

extension FinanceHoldingViewController: UpdateInvitees {
    func updateInvitees(selectedFalconUsers: [User]) {
        if let inviteesRow: ButtonRow = form.rowBy(tag: "Participants"), let currentUser = Auth.auth().currentUser?.uid {
            if !selectedFalconUsers.isEmpty {
                self.selectedFalconUsers = selectedFalconUsers
                var participantCount = self.selectedFalconUsers.count
                // If user is creating this activity (admin)
                if holding.admin == nil || holding.admin == Auth.auth().currentUser?.uid {
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
                self.showActivityIndicator()
                let createHolding = HoldingActions(holding: self.holding, active: self.active, selectedFalconUsers: self.selectedFalconUsers)
                createHolding.updateHoldingParticipants()
                self.hideActivityIndicator()
            }
            
            holding.participantsIDs = []
            if holding.admin == currentUser {
                holding.participantsIDs!.append(currentUser)
            }
            for selectedUser in selectedFalconUsers {
                guard let id = selectedUser.id else { continue }
                holding.participantsIDs!.append(id)
            }
        }
    }
}

extension FinanceHoldingViewController: UITextViewDelegate {
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.textColor == FalconPalette.defaultBlue {
            textView.text = nil
            textView.textColor = ThemeManager.currentTheme().generalTitleColor
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

extension FinanceHoldingViewController: UpdateTagsDelegate {
    func updateTags(tags: [String]?) {
        holding.tags = tags
    }
}

