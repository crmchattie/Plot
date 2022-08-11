//
//  FinanceAccountViewController.swift
//  Plot
//
//  Created by Cory McHattie on 9/1/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import UIKit
import Eureka
import Firebase

protocol UpdateAccountDelegate: AnyObject {
    func updateAccount(account: MXAccount)
}

class FinanceAccountViewController: FormViewController {
    var account: MXAccount!
    var holdings = [MXHolding]()
    
    lazy var users: [User] = networkController.userService.users
    lazy var filteredUsers: [User] = networkController.userService.users
    lazy var activities: [Activity] = networkController.activityService.activities
    
    var selectedFalconUsers = [User]()
    
    var userNames : [String] = []
    var userNamesString: String = ""
    
    var active: Bool = false
    
    weak var delegate : UpdateAccountDelegate?
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
        
        if !(account.user_created ?? false) {
            for row in form.rows {
                if row.tag != "Should Link" && row.tag != "Tags" && row.tag != "Participants" && row.tag != "Description" {
                    row.baseCell.isUserInteractionEnabled = false
                }
            }
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
    
    func setupVariables() {
        if let _ = account {
            title = "Account"
            active = true
            numberFormatter.currencyCode = account.currency_code
            
            var participantCount = self.selectedFalconUsers.count
            // If user is creating this activity (admin)
            if account.admin == nil || account.admin == Auth.auth().currentUser?.uid {
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
            title = "New Account"
            let ID = Database.database().reference().child(userFinancialAccountsEntity).child(currentUser).childByAutoId().key ?? ""
            let date = isodateFormatter.string(from: Date())
            account = MXAccount(name: "Account Name", balance: 0.0, created_at: date, guid: ID, user_guid: currentUser, type: .any, subtype: .any, user_created: true, admin: currentUser)
            numberFormatter.currencyCode = "USD"
        }
        
        if account.type == .investment {
            self.holdings = networkController.financeService.holdings.filter({$0.account_guid == self.account.guid})
            self.holdings.sort(by: {$0.market_value ?? 0 > $1.market_value ?? 0})
            self.addHoldingsSection()
        }
    
    }
    
    func addHoldingsSection() {
        if !self.holdings.isEmpty {
            self.form.insert(Section("Positions"), at: 1)
            for holding in holdings {
                form.last!
                    <<< DecimalRow() {
                        $0.cell.isUserInteractionEnabled = false
                        $0.cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                        $0.cell.textField?.textColor = ThemeManager.currentTheme().generalSubtitleColor
                        $0.title = holding.symbol ?? holding.description
                        $0.formatter = numberFormatter
                        $0.value = holding.market_value
                    }.cellUpdate { cell, row in
                        cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                        cell.textField?.textColor = ThemeManager.currentTheme().generalSubtitleColor
                    }
            }
        }
    }
    
    @IBAction func cancel(_ sender: AnyObject) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func create(_ sender: AnyObject) {
        if account.user_created ?? false {
            self.showActivityIndicator()
            let createAccount = AccountActions(account: self.account, active: self.active, selectedFalconUsers: self.selectedFalconUsers)
            createAccount.createNewAccount()
            self.hideActivityIndicator()
            
        }
        if active {
            self.delegate?.updateAccount(account: account)
        }
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
                    $0.value = account.name.capitalized
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
                    self.account.name = value
                    if let currentUser = Auth.auth().currentUser?.uid, self.active {
                        let reference = Database.database().reference().child(userFinancialAccountsEntity).child(currentUser).child(self.account.guid).child("name")
                        reference.setValue(value)
                    }
                }
                if row.value == nil {
                    self.navigationItem.rightBarButtonItem?.isEnabled = false
                } else {
                    self.navigationItem.rightBarButtonItem?.isEnabled = true
                }
            }
            
//            <<< TextAreaRow("Description") {
//                $0.cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
//                $0.cell.textView?.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
//                $0.cell.textView?.textColor = ThemeManager.currentTheme().generalTitleColor
//                $0.cell.placeholderLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
//                $0.placeholder = $0.tag
//                $0.value = account.description
//                }.cellUpdate({ (cell, row) in
//                    cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
//                    cell.textView?.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
//                    cell.textView?.textColor = ThemeManager.currentTheme().generalTitleColor
//                    cell.placeholderLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
//                }).onChange { row in
//                    let reference = Database.database().reference().child(financialAccountsEntity).child(self.account.guid).child("description")
//                    reference.setValue(row.value)
//                    self.account.description = row.value
//                }
            
            <<< PushRow<String>("Type") { row in
                row.cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                row.cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                row.cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
                row.title = row.tag
                row.value = account.type.name
                row.options = []
                MXAccountType.allCases.forEach {
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
                if !(self.account?.user_created ?? false) {
                    row.cell.accessoryType = .none
                }
            }.onChange { row in
                if let value = row.value, let type = MXAccountType(rawValue: value) {
                    self.account.type = type
//                    let reference = Database.database().reference().child(financialAccountsEntity).child(self.account.guid).child("type")
//                    reference.setValue(value)
                }
            }
        
        if (account.subtype ?? .none != .none) || (account.user_created ?? false) {
            form.last!
                <<< PushRow<String>("Subtype") { row in
                    row.cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                    row.cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                    row.cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
                    row.title = row.tag
                    row.value = account.subtype?.name
                    row.options = []
                    MXAccountSubType.allCases.forEach {
                        row.options?.append($0.name)
                    }
                }.onPresent { from, to in
                    to.title = "Subtype"
                    to.tableViewStyle = .insetGrouped
                    to.dismissOnSelection = true
                    to.dismissOnChange = true
                    to.enableDeselection = false
                    to.selectableRowCellUpdate = { cell, row in
                        to.tableView.separatorStyle = .none
                        to.navigationController?.navigationBar.backgroundColor = ThemeManager.currentTheme().barBackgroundColor
                        to.tableView.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                        cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                        cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                        cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
                    }
                }.cellUpdate { cell, row in
                    cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                    cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                    cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
                    if !(self.account?.user_created ?? false) {
                        row.cell.accessoryType = .none
                    }
                }.onChange { row in
                    if let value = row.value, let subtype = MXAccountSubType(rawValue: value) {
                        self.account.subtype = subtype
//                        let reference = Database.database().reference().child(financialAccountsEntity).child(self.account.guid).child("subtype")
//                        reference.setValue(value)
                    }
                }
        }
        
        form.last!
            <<< LabelRow("Last Updated") {
                $0.cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                $0.cell.textLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
                $0.cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
                $0.title = $0.tag
                if let date = isodateFormatter.date(from: account.updated_at) {
                    $0.value = dateFormatterPrint.string(from: date)
                }
            }.cellUpdate { cell, row in
                cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
            }
            
            <<< CheckRow("Should Link") {
                $0.cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                $0.cell.tintColor = FalconPalette.defaultBlue
                $0.cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                $0.cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                $0.cell.accessoryType = .checkmark
                if self.account.should_link ?? true {
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
                self.account.should_link = row.value
                if let currentUser = Auth.auth().currentUser?.uid, self.active {
                    let reference = Database.database().reference().child(userFinancialAccountsEntity).child(currentUser).child(self.account.guid).child("should_link")
                    reference.setValue(row.value!)
                }
            }
            
            <<< DecimalRow("Balance") {
                $0.cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                $0.cell.textField?.textColor = ThemeManager.currentTheme().generalSubtitleColor
                $0.title = $0.tag
                $0.value = account.balance
                $0.formatter = numberFormatter
            }.cellUpdate { cell, row in
                cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                cell.textField?.textColor = ThemeManager.currentTheme().generalSubtitleColor
            }.onChange { row in
                if let value = row.value {
                    self.updateTheDate()
                    self.account.balance = value
                    if self.account.balances != nil {
                        if !self.account.balances!.values.contains(self.account.balance) {
                            self.account.balances![self.isodateFormatter.string(from: Date())] = self.account.balance
                        }
                    } else {
                        self.account.balances = [self.isodateFormatter.string(from: Date()): self.account.balance]
                    }
//                    let reference = Database.database().reference().child(financialAccountsEntity).child(self.account.guid)
//                    reference.child("balance").setValue(self.account.balance)
//                    reference.child("balances").setValue(self.account.balances)
                }
            }
        
        if let availableBalance = account.available_balance {
            form.last!
                <<< DecimalRow("Available Balance") {
                    $0.cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                    $0.cell.textField?.textColor = ThemeManager.currentTheme().generalSubtitleColor
                    $0.title = $0.tag
                    $0.formatter = numberFormatter
                    $0.value = availableBalance
                }.cellUpdate { cell, row in
                    cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                    cell.textField?.textColor = ThemeManager.currentTheme().generalSubtitleColor
                }.onChange { row in
                    if let value = row.value {
                        self.updateTheDate()
                        self.account.available_balance = value
//                        Database.database().reference().child(financialAccountsEntity).child(self.account.guid).child("available_balance").setValue(value)
                    }
                }
        }
        
        if (account.payment_due_at != nil) || (account.user_created ?? false) {
            form.last!
                <<< DateInlineRow("Payment Due Date") {
                    $0.cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                    $0.cell.textLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
                    $0.cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
                    $0.title = $0.tag
                    $0.dateFormatter?.dateFormat = dateFormatterPrint.dateFormat
                    if let paymentDueDate = account.payment_due_at, let date = isodateFormatter.date(from: paymentDueDate) {
                        $0.value = date
                    }
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
                }.onChange { row in
                    if let value = row.value {
                        self.updateTheDate()
                        let date = self.isodateFormatter.string(from: value)
                        self.account.payment_due_at = date
//                        let reference = Database.database().reference().child(financialAccountsEntity).child(self.account.guid).child("payment_due_at")
//                        reference.setValue(date)
                    }
                }
        }
        
        if (account.minimum_payment != nil) || (account.user_created ?? false) {
            form.last!
                <<< DecimalRow("Minimum Payment Due") {
                    $0.cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                    $0.cell.textField?.textColor = ThemeManager.currentTheme().generalSubtitleColor
                    $0.title = $0.tag
                    $0.formatter = numberFormatter
                    $0.value = account.minimum_payment
                }.cellUpdate { cell, row in
                    cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                    cell.textField?.textColor = ThemeManager.currentTheme().generalSubtitleColor
                }.onChange { row in
                    if let value = row.value {
                        self.updateTheDate()
                        self.account.minimum_payment = value
//                        Database.database().reference().child(financialAccountsEntity).child(self.account.guid).child("minimum_payment").setValue(value)
                    }
                }
        }
        
        form.last!
            <<< LabelRow("Tags") { row in
                row.cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                row.cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                row.cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                row.cell.accessoryType = .disclosureIndicator
                row.cell.selectionStyle = .default
                row.cell.textLabel?.textAlignment = .left
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
            self.account.updated_at = date
//            Database.database().reference().child(financialAccountsEntity).child(self.account.guid).child("updated_at").setValue(date)
        }
    }
    
    @objc fileprivate func openTags() {
        let destination = FinanceTagsViewController()
        destination.delegate = self
        destination.tags = account.tags
        destination.ID = account.guid
        destination.type = "account"
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
    
    func getSelectedFalconUsers(forAccount account: MXAccount, completion: @escaping ([User])->()) {
        guard let participantsIDs = account.participantsIDs, let currentUserID = Auth.auth().currentUser?.uid else {
            return
        }
        var selectedFalconUsers = [User]()
        let group = DispatchGroup()
        for id in participantsIDs {
            // Only if the current user is created this activity
            if account.admin == currentUserID && id == currentUserID {
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

extension FinanceAccountViewController: UpdateInvitees {
    func updateInvitees(selectedFalconUsers: [User]) {
        if let inviteesRow: ButtonRow = form.rowBy(tag: "Participants") {
            if !selectedFalconUsers.isEmpty {
                self.selectedFalconUsers = selectedFalconUsers
                
                var participantCount = self.selectedFalconUsers.count
                // If user is creating this activity (admin)
                if account.admin == nil || account.admin == Auth.auth().currentUser?.uid {
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
                let createAccount = AccountActions(account: self.account, active: self.active, selectedFalconUsers: self.selectedFalconUsers)
                createAccount.updateAccountParticipants()
                self.hideActivityIndicator()
                
            }
            
        }
    }
}

extension FinanceAccountViewController: UpdateTagsDelegate {
    func updateTags(tags: [String]?) {
        account.tags = tags
    }
}

extension FinanceAccountViewController: UITextViewDelegate {
    
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
