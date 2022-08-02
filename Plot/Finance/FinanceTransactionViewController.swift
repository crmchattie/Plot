//
//  FinanceTransactionViewController.swift
//  Plot
//
//  Created by Cory McHattie on 9/16/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import UIKit
import Eureka
import Firebase
import CodableFirebase

protocol UpdateTransactionDelegate: AnyObject {
    func updateTransaction(transaction: Transaction)
}

class FinanceTransactionViewController: FormViewController {
    var transaction: Transaction!
    var accounts = [MXAccount]()
    var accountFetcher = FinancialAccountFetcher()
    
    var users = [User]()
    var filteredUsers = [User]()
    var selectedFalconUsers = [User]()
    
    var userNames : [String] = []
    var userNamesString: String = ""
    
    var active: Bool = false
    
    //added for EventViewController
    var movingBackwards: Bool = false
    
    weak var delegate : UpdateTransactionDelegate?
    
    var status = false
    
    let numberFormatter = NumberFormatter()
    
    // create dateFormatter with UTC time format
    let isodateFormatter = ISO8601DateFormatter()
    let dateFormatterPrint = DateFormatter()
    
    init() {
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
        dateFormatterPrint.dateFormat = "E, MMM dd, yyyy"
        setupVariables()
        configureTableView()
        initializeForm()
                
        if !status {
            for row in form.rows {
                if row.tag != "Should Link" {
                    row.baseCell.isUserInteractionEnabled = false
                }
            }
        } else if !(transaction?.user_created ?? false) {
            for row in form.rows {
                if row.tag == "Account" || row.tag == "Transacted On" || row.tag == "Name" {
                    row.baseCell.isUserInteractionEnabled = false
                }
            }
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        if movingBackwards {
            self.delegate?.updateTransaction(transaction: transaction)
        }
    }
    
    fileprivate func setupVariables() {
        if let _ = transaction {
            title = "Transaction"
            active = true
            numberFormatter.currencyCode = transaction.currency_code
            
            var participantCount = self.selectedFalconUsers.count
            // If user is creating this activity (admin)
            if transaction.admin == nil || transaction.admin == Auth.auth().currentUser?.uid {
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
            
            if transaction.admin == nil, let currentUser = Auth.auth().currentUser?.uid {
                let reference = Database.database().reference().child(financialTransactionsEntity).child(self.transaction.guid).child("admin")
                reference.setValue(currentUser)
                transaction.admin = currentUser
            }
        } else if let currentUser = Auth.auth().currentUser?.uid {
            title = "New Transaction"
            let ID = Database.database().reference().child(userFinancialTransactionsEntity).child(currentUser).childByAutoId().key ?? ""
            let date = isodateFormatter.string(from: Date())
            transaction = Transaction(description: "Name", amount: 0.0, created_at: date, guid: ID, user_guid: currentUser, status: .posted, category: "Uncategorized", top_level_category: "Uncategorized", user_created: true, admin: currentUser)
            numberFormatter.currencyCode = "USD"
        }
        
        status = transaction.status == .posted
        
        accountFetcher.fetchAccounts { (firebaseAccounts) in
            self.accounts = firebaseAccounts
            self.accounts.sort { (account1, account2) -> Bool in
                return account1.name < account2.name
            }
            if let row: PushRow<String> = self.form.rowBy(tag: "Account") {
                self.accounts.forEach {
                    row.options?.append($0.name.capitalized)
                }
                if self.transaction.account_name == nil, let value = self.transaction.account_guid {
                    if let account = self.accounts.first(where: { $0.guid == value }) {
                        row.value = account.name
                    }
                }
                row.updateCell()
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
            let dotsBarButton = UIBarButtonItem(image: UIImage(named: "dots"), style: .plain, target: self, action: #selector(goToExtras))
            navigationItem.rightBarButtonItems = [addBarButton, dotsBarButton]
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
        if transaction.user_created ?? false {
            self.showActivityIndicator()
            let createTransaction = TransactionActions(transaction: self.transaction, active: self.active, selectedFalconUsers: self.selectedFalconUsers)
            createTransaction.createNewTransaction()
            self.hideActivityIndicator()
        }
        self.delegate?.updateTransaction(transaction: transaction)
        if navigationItem.leftBarButtonItem != nil {
            self.dismiss(animated: true, completion: nil)
        } else {
            self.navigationController?.popViewController(animated: true)
        }
    }
    
    fileprivate func initializeForm() {
        form +++
            Section(footer: "If status is pending, values cannot be changed")
            
            <<< TextRow("Name") {
                $0.cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                $0.cell.textField?.textColor = ThemeManager.currentTheme().generalTitleColor
                $0.placeholderColor = ThemeManager.currentTheme().generalSubtitleColor
                $0.placeholder = $0.tag
                if active {
                    self.navigationItem.rightBarButtonItem?.isEnabled = true
                    $0.value = transaction.description
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
                    if let currentUser = Auth.auth().currentUser?.uid {
                        self.transaction.description = value
                        let reference = Database.database().reference().child(userFinancialTransactionsEntity).child(currentUser).child(self.transaction.guid).child("description")
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
//                $0.value = transaction.transactionDescription
//                }.cellUpdate({ (cell, row) in
//                    cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
//                    cell.textView?.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
//                    cell.textView?.textColor = ThemeManager.currentTheme().generalTitleColor
//                    cell.placeholderLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
//                }).onChange { row in
//                    let reference = Database.database().reference().child(financialTransactionsEntity).child(self.transaction.guid).child("transactionDescription")
//                    self.transaction.transactionDescription = row.value
//                    reference.setValue(row.value)
//                }
            
            <<< DateInlineRow("Transacted On") {
                $0.cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                $0.cell.textLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
                $0.cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
                $0.dateFormatter?.dateFormat = dateFormatterPrint.dateFormat
                $0.title = $0.tag
                if let date = isodateFormatter.date(from: transaction.transacted_at) {
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
                    let date = self.isodateFormatter.string(from: value)
                    self.transaction.transacted_at = date
//                    let reference = Database.database().reference().child(financialTransactionsEntity).child(self.transaction.guid).child("transacted_at")
//                    reference.setValue(date)
                }
            }
            
            <<< DateInlineRow("Financial Profile Date") {
                $0.cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                $0.cell.textLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
                $0.cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
                $0.title = $0.tag
                $0.dateFormatter?.dateFormat = dateFormatterPrint.dateFormat
                if let reportDate = transaction.date_for_reports, reportDate != "", let date = isodateFormatter.date(from: reportDate) {
                    $0.value = date
                } else if let date = isodateFormatter.date(from: transaction.transacted_at) {
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
                if let currentUser = Auth.auth().currentUser?.uid, let value = row.value {
                    let date = self.isodateFormatter.string(from: value)
                    self.transaction.date_for_reports = date
                    let reference = Database.database().reference().child(userFinancialTransactionsEntity).child(currentUser).child(self.transaction.guid).child("date_for_reports")
                    reference.setValue(date)
                }
            }
            
            <<< DecimalRow("Amount") {
                $0.cell.isUserInteractionEnabled = transaction.user_created ?? false
                $0.cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                $0.cell.textField?.textColor = ThemeManager.currentTheme().generalSubtitleColor
                $0.title = $0.tag
                $0.formatter = numberFormatter
                $0.value = transaction.amount
            }.cellUpdate { cell, row in
                cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                cell.textField?.textColor = ThemeManager.currentTheme().generalSubtitleColor
            }.onChange { row in
                if let value = row.value {
                    self.transaction.amount = value
//                    let reference = Database.database().reference().child(financialTransactionsEntity).child(self.transaction.guid).child("amount")
//                    reference.setValue(value)
                }
            }
            
            //need to add change to amount or amount per rows
            <<< IntRow("splitNumber") {
                $0.cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                $0.cell.textField?.textColor = ThemeManager.currentTheme().generalSubtitleColor
                $0.title = "Split amount by"
                $0.value = transaction.splitNumber
            }.cellUpdate { cell, row in
                cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                cell.textField?.textColor = ThemeManager.currentTheme().generalSubtitleColor
            }.onChange { row in
                let reference = Database.database().reference().child(financialTransactionsEntity).child(self.transaction.guid).child("splitNumber")
                if let value = row.value {
                    self.transaction.splitNumber = value
                    reference.setValue(value)
                    if let row: DecimalRow = self.form.rowBy(tag: "Per Person Amount"), self.transaction.amount != 0, value != 0 {
                        row.value = self.transaction.amount / Double(value)
                        row.updateCell()
                    }
                } else {
                    self.transaction.splitNumber = nil
                    reference.removeValue()
                }
            }
            
            <<< DecimalRow("Per Person Amount") {
                $0.cell.isUserInteractionEnabled = transaction.user_created ?? false
                $0.cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                $0.cell.textField?.textColor = ThemeManager.currentTheme().generalSubtitleColor
                $0.title = $0.tag
                $0.formatter = numberFormatter
                $0.hidden = "$splitNumber == nil || $splitNumber == 0"
                if let splitNumber = transaction.splitNumber, splitNumber != 0 {
                    $0.value = transaction.amount / Double(splitNumber)
                }
            }.cellUpdate { cell, row in
                cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                cell.textField?.textColor = ThemeManager.currentTheme().generalSubtitleColor
            }
            
            <<< TextRow("Status") {
                $0.cell.isUserInteractionEnabled = false
                $0.cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                $0.cell.textField?.textColor = ThemeManager.currentTheme().generalSubtitleColor
                $0.title = $0.tag
                $0.value = transaction.status.name
            }.cellUpdate { cell, row in
                cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                cell.textField?.textColor = ThemeManager.currentTheme().generalSubtitleColor
            }
            
            <<< CheckRow("Should Link") {
                $0.cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                $0.cell.tintColor = FalconPalette.defaultBlue
                $0.cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                $0.cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                $0.cell.accessoryType = .checkmark
                if self.transaction.should_link ?? true {
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
                if let currentUser = Auth.auth().currentUser?.uid {
                    self.transaction.should_link = row.value
                    let reference = Database.database().reference().child(userFinancialTransactionsEntity).child(currentUser).child(self.transaction.guid).child("should_link")
                    reference.setValue(row.value!)
                }
            }
            
            <<< PushRow<String>("Account") { row in
                row.cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                row.cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                row.cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
                row.title = row.tag
                if let value = transaction.account_name {
                    row.value = value
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
                if !(self.transaction?.user_created ?? false) {
                    row.cell.accessoryType = .none
                }
            }.onChange({ row in
                self.transaction.account_name = row.value
//                let reference = Database.database().reference().child(financialTransactionsEntity).child(self.transaction.guid).child("account_name")
//                reference.setValue(row.value)
            })
            
            <<< LabelRow("Group") { row in
                row.cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                row.cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                row.cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
                row.cell.accessoryType = .disclosureIndicator
                row.cell.textLabel?.textAlignment = .left
                row.cell.selectionStyle = .default
                row.title = row.tag
                row.value = transaction.group
            }.onCellSelection({ _, row in
                self.openLevel(level: row.tag!, value: row.value!)
            }).cellUpdate { cell, row in
                cell.accessoryType = .disclosureIndicator
                cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
                cell.textLabel?.textAlignment = .left
            }
        
            <<< LabelRow("Category") { row in
                row.cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                row.cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                row.cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
                row.cell.accessoryType = .disclosureIndicator
                row.cell.textLabel?.textAlignment = .left
                row.cell.selectionStyle = .default
                row.title = row.tag
                row.value = transaction.group
            }.onCellSelection({ _, row in
                self.openLevel(level: row.tag!, value: row.value!)
            }).cellUpdate { cell, row in
                cell.accessoryType = .disclosureIndicator
                cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
                cell.textLabel?.textAlignment = .left
            }
        
            <<< LabelRow("Subcategory") { row in
                row.cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                row.cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                row.cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
                row.cell.accessoryType = .disclosureIndicator
                row.cell.textLabel?.textAlignment = .left
                row.cell.selectionStyle = .default
                row.title = row.tag
                row.value = transaction.group
            }.onCellSelection({ _, row in
                self.openLevel(level: row.tag!, value: row.value!)
            }).cellUpdate { cell, row in
                cell.accessoryType = .disclosureIndicator
                cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
                cell.textLabel?.textAlignment = .left
            }
        
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
    
    @objc func goToExtras() {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "Create Transaction Rule", style: .default, handler: { (_) in
            self.createRule()
        }))

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (_) in
        }))

        self.present(alert, animated: true)
        
    }
    
    func createRule() {
        let destination = FinanceTransactionRuleViewController()
        destination.transaction = transaction
        self.navigationController?.pushViewController(destination, animated: true)
    }
    
    @objc fileprivate func openLevel(level: String, value: String) {
        let destination = FinanceTransactionLevelViewController()
        destination.delegate = self
        destination.level = level
        destination.value = value
        self.navigationController?.pushViewController(destination, animated: true)
    }
    
    @objc fileprivate func openTags() {
        let destination = FinanceTagsViewController()
        destination.delegate = self
        destination.tags = transaction.tags
        destination.ID = transaction.guid
        destination.type = "transaction"
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
    
    func getSelectedFalconUsers(forTransaction transaction: Transaction, completion: @escaping ([User])->()) {
        guard let participantsIDs = transaction.participantsIDs, let currentUserID = Auth.auth().currentUser?.uid else {
            return
        }
        var selectedFalconUsers = [User]()
        let group = DispatchGroup()
        for id in participantsIDs {
            // Only if the current user is created this activity
            if transaction.admin == currentUserID && id == currentUserID {
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

extension FinanceTransactionViewController: UpdateTransactionLevelDelegate {
    func update(value: String, level: String) {
        if let row: LabelRow = form.rowBy(tag: level), let currentUser = Auth.auth().currentUser?.uid {
            row.value = value
            row.updateCell()
            if level == "Subcategory" {
                transaction.category = value
                Database.database().reference().child(userFinancialTransactionsEntity).child(currentUser).child(self.transaction.guid).child("category").setValue(value)
            } else if level == "Category" {
                transaction.top_level_category = value
                Database.database().reference().child(userFinancialTransactionsEntity).child(currentUser).child(self.transaction.guid).child("top_level_category").setValue(value)
            } else {
                transaction.group = value
                Database.database().reference().child(userFinancialTransactionsEntity).child(currentUser).child(self.transaction.guid).child("group").setValue(value)
            }
        }
    }
}

extension FinanceTransactionViewController: UpdateInvitees {
    func updateInvitees(selectedFalconUsers: [User]) {
        if let inviteesRow: ButtonRow = form.rowBy(tag: "Participants"), let currentUser = Auth.auth().currentUser?.uid {
            if !selectedFalconUsers.isEmpty {
                self.selectedFalconUsers = selectedFalconUsers
                var participantCount = self.selectedFalconUsers.count
                // If user is creating this activity (admin)
                if transaction.admin == nil || transaction.admin == Auth.auth().currentUser?.uid {
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
                let createTransaction = TransactionActions(transaction: self.transaction, active: self.active, selectedFalconUsers: self.selectedFalconUsers)
                createTransaction.updateTransactionParticipants()
                self.hideActivityIndicator()
            }
            
            transaction.participantsIDs = []
            if transaction.admin == currentUser {
                transaction.participantsIDs!.append(currentUser)
            }
            
            for selectedUser in selectedFalconUsers {
                guard let id = selectedUser.id else { continue }
                transaction.participantsIDs!.append(id)
            }
        }
    }
}

extension FinanceTransactionViewController: UITextViewDelegate {
    
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

extension FinanceTransactionViewController: UpdateTagsDelegate {
    func updateTags(tags: [String]?) {
        transaction.tags = tags
    }
}
