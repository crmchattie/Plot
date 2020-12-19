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

protocol UpdateAccountDelegate: class {
    func updateAccount(account: MXAccount)
}

class FinanceAccountViewController: FormViewController {
    var account: MXAccount!
    
    var users = [User]()
    var filteredUsers = [User]()
    var selectedFalconUsers = [User]()
    
    var userNames : [String] = []
    var userNamesString: String = ""
    
    var active: Bool = false
    
    weak var delegate : UpdateAccountDelegate?
    
    let numberFormatter = NumberFormatter()
    
    // create dateFormatter with UTC time format
    let isodateFormatter = ISO8601DateFormatter()
    let dateFormatterPrint = DateFormatter()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        numberFormatter.numberStyle = .currency
        dateFormatterPrint.dateFormat = "MMM dd, yyyy"
        
        if let _ = account {
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
            let ID = Database.database().reference().child(userFinancialAccountsEntity).child(currentUser).childByAutoId().key ?? ""
            let date = isodateFormatter.string(from: Date())
            account = MXAccount(name: "Account Name", balance: 0.0, created_at: date, guid: ID, user_guid: currentUser, type: .any, subtype: .any, user_created: true, admin: currentUser)
            numberFormatter.currencyCode = "USD"
        }
        
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
        navigationItem.title = "Account"
        
        let addBarButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(create))
        navigationItem.rightBarButtonItem = addBarButton
        
    }
    
    @IBAction func create(_ sender: AnyObject) {
        if account.user_created ?? false {
            self.showActivityIndicator()
            let createAccount = AccountActions(account: self.account, active: self.active, selectedFalconUsers: self.selectedFalconUsers)
            createAccount.createNewAccount()
            self.hideActivityIndicator()
            
            if active {
                self.delegate?.updateAccount(account: account)
                self.navigationController?.popViewController(animated: true)
            } else {
                let nav = self.tabBarController!.viewControllers![1] as! UINavigationController
                if nav.topViewController is MasterActivityContainerController {
                    let homeTab = nav.topViewController as! MasterActivityContainerController
                    homeTab.customSegmented.setIndex(index: 3)
                    homeTab.changeToIndex(index: 3)
                }
                self.tabBarController?.selectedIndex = 1
                if #available(iOS 13.0, *) {
                    self.navigationController?.backToViewController(viewController: DiscoverViewController.self)
                } else {
                    // Fallback on earlier versions
                }
            }
        } else {
            self.delegate?.updateAccount(account: account)
            self.navigationController?.popViewController(animated: true)
        }
    }
    
    fileprivate func initializeForm() {
        form +++
            Section()
            
            <<< TextRow("Name") {
                $0.cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                $0.cell.textField?.textColor = ThemeManager.currentTheme().generalTitleColor
                $0.placeholderColor = ThemeManager.currentTheme().generalSubtitleColor
                $0.placeholder = $0.tag
                if active {
                    $0.value = account.name.capitalized
                } else {
                    $0.cell.textField.becomeFirstResponder()
                }
            }.cellUpdate { cell, row in
                cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                cell.textField?.textColor = ThemeManager.currentTheme().generalTitleColor
                row.placeholderColor = ThemeManager.currentTheme().generalSubtitleColor
            }.onChange { row in
                if let value = row.value {
                    if let currentUser = Auth.auth().currentUser?.uid {
                        self.account.name = value
                        let reference = Database.database().reference().child(userFinancialAccountsEntity).child(currentUser).child(self.account.guid).child("name")
                        reference.setValue(value)
                    }
                }
            }
            
            <<< PushRow<String>("Type") { row in
                row.cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                row.cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                row.cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
                row.title = row.tag
                row.value = account.type.name
                row.options = []
                MXAccountType.allCases.forEach {
                    row.options?.append($0.name)
                }
            }.onPresent { from, to in
                to.dismissOnSelection = false
                to.dismissOnChange = false
                to.enableDeselection = false
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
                cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
            }.onChange { row in
                if let value = row.value, let type = MXAccountType(rawValue: value) {
                    self.account.type = type
                    let reference = Database.database().reference().child(financialAccountsEntity).child(self.account.guid).child("type")
                    reference.setValue(value)
                }
            }
        
        if account.subtype != .none {
            form.last!
            <<< PushRow<String>("Subtype") { row in
                row.cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                row.cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                row.cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
                row.title = row.tag
                row.value = account.subtype.name
                row.options = []
                MXAccountSubType.allCases.forEach {
                    row.options?.append($0.name)
                }
            }.onPresent { from, to in
                to.dismissOnSelection = false
                to.dismissOnChange = false
                to.enableDeselection = false
                to.selectableRowCellUpdate = { cell, row in
                    to.title = "Subtype"
                    to.tableView.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                    to.tableView.separatorStyle = .none
                    cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                    cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                    cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
                }
            }.cellUpdate { cell, row in
                cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
            }.onChange { row in
                if let value = row.value, let subtype = MXAccountSubType(rawValue: value) {
                    self.account.subtype = subtype
                    let reference = Database.database().reference().child(financialAccountsEntity).child(self.account.guid).child("subtype")
                    reference.setValue(value)
                }
            }
        }
        
        form.last!
            <<< TextRow("Last Updated On") {
                $0.cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                $0.cell.textField?.textColor = ThemeManager.currentTheme().generalSubtitleColor
                $0.title = $0.tag
                if let date = isodateFormatter.date(from: account.updated_at) {
                    $0.value = dateFormatterPrint.string(from: date)
                }
            }.cellUpdate { cell, row in
                cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                cell.textField?.textColor = ThemeManager.currentTheme().generalSubtitleColor
            }
            
            <<< CheckRow("Should Link") {
                $0.cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
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
                cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                cell.tintColor = FalconPalette.defaultBlue
                cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
            }.onChange { row in
                row.title = row.value! ? "Included in Financial Profile" : "Not Included in Financial Profile"
                row.updateCell()
                if let currentUser = Auth.auth().currentUser?.uid {
                    self.account.should_link = row.value
                    let reference = Database.database().reference().child(userFinancialAccountsEntity).child(currentUser).child(self.account.guid).child("should_link")
                    reference.setValue(row.value!)
                }
            }
            
            <<< DecimalRow("Balance") {
                $0.cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                $0.cell.textField?.textColor = ThemeManager.currentTheme().generalSubtitleColor
                $0.title = $0.tag
                $0.value = account.balance
                $0.formatter = numberFormatter
            }.cellUpdate { cell, row in
                cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                cell.textField?.textColor = ThemeManager.currentTheme().generalSubtitleColor
            }.onChange { row in
                if let value = row.value {
                    self.updateTheDate()
                    self.account.balance = value
                    if self.account.balances != nil {
                        self.account.balances![self.isodateFormatter.string(from: Date())] = self.account.balance
                    } else {
                        self.account.balances = [self.isodateFormatter.string(from: Date()): self.account.balance]
                    }
                    let reference = Database.database().reference().child(financialAccountsEntity).child(self.account.guid)
                    reference.child("balance").setValue(self.account.balance)
                    reference.child("balances").setValue(self.account.balances)
                }
            }
        
        if let availableBalance = account.available_balance {
            form.last!
                <<< DecimalRow("Available Balance") {
                    $0.cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                    $0.cell.textField?.textColor = ThemeManager.currentTheme().generalSubtitleColor
                    $0.title = $0.tag
                    $0.formatter = numberFormatter
                    $0.value = availableBalance
                }.cellUpdate { cell, row in
                    cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                    cell.textField?.textColor = ThemeManager.currentTheme().generalSubtitleColor
            }.onChange { row in
                if let value = row.value {
                    self.updateTheDate()
                    self.account.available_balance = value
                    Database.database().reference().child(financialAccountsEntity).child(self.account.guid).child("available_balance").setValue(value)
                }
            }
        }
        
        if let paymentDueDate = account.payment_due_at {
            form.last!
            <<< DateInlineRow("Payment Due Date") {
                $0.cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                $0.cell.textLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
                $0.cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
                $0.title = $0.tag
                $0.dateFormatter?.dateFormat = dateFormatterPrint.dateFormat
                if let date = isodateFormatter.date(from: paymentDueDate) {
                    $0.value = date
                }
            }.onChange { row in
                if let value = row.value {
                    self.updateTheDate()
                    let date = self.isodateFormatter.string(from: value)
                    self.account.payment_due_at = date
                    let reference = Database.database().reference().child(financialAccountsEntity).child(self.account.guid).child("payment_due_at")
                    reference.setValue(date)
                }
            }
        }
        
        if let minimum = account.minimum_payment {
            form.last!
            <<< DecimalRow("Minimum Payment Due") {
                    $0.cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                    $0.cell.textField?.textColor = ThemeManager.currentTheme().generalSubtitleColor
                    $0.title = $0.tag
                    $0.formatter = numberFormatter
                    $0.value = minimum
                }.cellUpdate { cell, row in
                    cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                    cell.textField?.textColor = ThemeManager.currentTheme().generalSubtitleColor
            }.onChange { row in
                if let value = row.value {
                    self.updateTheDate()
                    self.account.minimum_payment = value
                    Database.database().reference().child(financialAccountsEntity).child(self.account.guid).child("minimum_payment").setValue(value)
                }
            }
        }
        
        form.last!
            <<< LabelRow("Tags") { row in
                row.cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                row.cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                row.cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                row.cell.accessoryType = .disclosureIndicator
                row.title = row.tag
            }.onCellSelection({ _, row in
                self.openTags()
            }).cellUpdate { cell, row in
                cell.accessoryType = .disclosureIndicator
                cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
            }
        
        form +++
            Section()
            <<< ButtonRow("Participants") { row in
                row.cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                row.cell.textLabel?.textAlignment = .left
                row.cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                row.cell.accessoryType = .disclosureIndicator
                row.title = row.tag
                if active {
                    row.title = self.userNamesString
                }
                }.onCellSelection({ _,_ in
                    self.openParticipantsInviter()
                }).cellUpdate { cell, row in
                    cell.accessoryType = .disclosureIndicator
                    cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                    cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                    cell.textLabel?.textAlignment = .left
                }
        
            <<< TextAreaRow("Description") {
                $0.cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                $0.cell.textView?.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                $0.cell.textView?.textColor = ThemeManager.currentTheme().generalTitleColor
                $0.cell.placeholderLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
                $0.placeholder = $0.tag
                $0.value = account.description
                }.cellUpdate({ (cell, row) in
                    cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                    cell.textView?.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                    cell.textView?.textColor = ThemeManager.currentTheme().generalTitleColor
                    cell.placeholderLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
                }).onChange { row in
                    let reference = Database.database().reference().child(financialAccountsEntity).child(self.account.guid).child("description")
                    reference.setValue(row.value)
                    self.account.description = row.value
                }
    }
    
    fileprivate func updateTheDate() {
        if let row: TextRow = form.rowBy(tag: "Last Updated On") {
            let date = self.isodateFormatter.string(from: Date())
            row.value = date
            row.updateCell()
            self.account.updated_at = date
            Database.database().reference().child(financialAccountsEntity).child(self.account.guid).child("updated_at").setValue(date)
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