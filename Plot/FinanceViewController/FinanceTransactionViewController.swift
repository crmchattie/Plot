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

protocol UpdateTransactionDelegate: class {
    func updateTransaction(transaction: Transaction)
}

class FinanceTransactionViewController: FormViewController {
    var transaction: Transaction!
    
    var users = [User]()
    var filteredUsers = [User]()
    var selectedFalconUsers = [User]()
    
    var userNames : [String] = []
    var userNamesString: String = ""
    
    var active: Bool = false
    
    //added for CreateActivityViewController
    var movingBackwards: Bool = false
    
    weak var delegate : UpdateTransactionDelegate?
    
    var status = false
    
    let numberFormatter = NumberFormatter()
    
    // create dateFormatter with UTC time format
    let isodateFormatter = ISO8601DateFormatter()
    let dateFormatterPrint = DateFormatter()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        numberFormatter.numberStyle = .currency
        dateFormatterPrint.dateFormat = "MMM dd, yyyy"
        setupVariables()
        configureTableView()
        initializeForm()
                
        if !status {
            for row in form.rows {
                if row.tag != "Should Link" {
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
            let ID = Database.database().reference().child(userFinancialTransactionsEntity).child(currentUser).childByAutoId().key ?? ""
            let date = isodateFormatter.string(from: Date())
            transaction = Transaction(description: "Transaction Name", amount: 0.0, created_at: date, guid: ID, user_guid: currentUser, status: .posted, category: "Uncategorized", top_level_category: "Uncategorized", user_created: true, admin: currentUser)
            numberFormatter.currencyCode = "USD"
        }
        
        status = transaction.status == .posted
        
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
        navigationItem.title = "Transaction"
        
        if !active {
            let addBarButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(create))
            navigationItem.rightBarButtonItem = addBarButton
        } else {
            let addBarButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(create))
            let dotsBarButton = UIBarButtonItem(image: UIImage(named: "dots"), style: .plain, target: self, action: #selector(goToExtras))
            navigationItem.rightBarButtonItems = [addBarButton, dotsBarButton]
        }
        
    }
    
    @IBAction func create(_ sender: AnyObject) {
        movingBackwards = false
        if transaction.user_created ?? false, !active {
            self.showActivityIndicator()
            let createTransaction = TransactionActions(transaction: self.transaction, active: self.active, selectedFalconUsers: self.selectedFalconUsers)
            createTransaction.createNewTransaction()
            self.hideActivityIndicator()
        }
        self.delegate?.updateTransaction(transaction: transaction)
        self.navigationController?.popViewController(animated: true)
    }
    
    fileprivate func initializeForm() {
        form +++
            Section(footer: "If status is pending, values cannot be changed")
            
            <<< TextRow("Name") {
                $0.cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                $0.cell.textField?.textColor = ThemeManager.currentTheme().generalTitleColor
                $0.title = $0.tag
                $0.value = transaction.description
            }.cellUpdate { cell, row in
                cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                cell.textField?.textColor = ThemeManager.currentTheme().generalTitleColor
            }.onChange { row in
                if let value = row.value {
                    if let currentUser = Auth.auth().currentUser?.uid {
                        self.transaction.description = value
                        let reference = Database.database().reference().child(userFinancialTransactionsEntity).child(currentUser).child(self.transaction.guid).child("description")
                        reference.setValue(value)
                    }
                }
            }
            
            <<< TextRow("Date") {
                $0.cell.isUserInteractionEnabled = false
                $0.cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                $0.cell.textField?.textColor = ThemeManager.currentTheme().generalTitleColor
                $0.title = $0.tag
                if let date = isodateFormatter.date(from: transaction.transacted_at) {
                    $0.value = dateFormatterPrint.string(from: date)
                }
            }.cellUpdate { cell, row in
                cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                cell.textField?.textColor = ThemeManager.currentTheme().generalTitleColor
            }
            
            <<< DateInlineRow("Financial Profile Date") {
                $0.cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                $0.cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                $0.cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                $0.title = $0.tag
                $0.dateFormatter?.dateFormat = dateFormatterPrint.dateFormat
                if let reportDate = transaction.date_for_reports, reportDate != "", let date = isodateFormatter.date(from: reportDate) {
                    $0.value = date
                } else if let date = isodateFormatter.date(from: transaction.transacted_at) {
                    $0.value = date
                }
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
                $0.cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                $0.cell.textField?.textColor = ThemeManager.currentTheme().generalTitleColor
                $0.title = $0.tag
                $0.formatter = numberFormatter
                $0.value = transaction.amount
            }.cellUpdate { cell, row in
                cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                cell.textField?.textColor = ThemeManager.currentTheme().generalTitleColor
            }.onChange { row in
                if let value = row.value {
                    self.transaction.amount = value
                    let reference = Database.database().reference().child(financialTransactionsEntity).child(self.transaction.guid).child("amount")
                    reference.setValue(value)
                }
            }
            
            //need to add change to amount or amount per rows
            <<< IntRow("splitNumber") {
                $0.cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                $0.cell.textField?.textColor = ThemeManager.currentTheme().generalTitleColor
                $0.title = "Split amount by"
                $0.value = transaction.splitNumber ?? transaction.participantsIDs?.count
            }.cellUpdate { cell, row in
                cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                cell.textField?.textColor = ThemeManager.currentTheme().generalTitleColor
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
                $0.cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                $0.cell.textField?.textColor = ThemeManager.currentTheme().generalTitleColor
                $0.title = $0.tag
                $0.formatter = numberFormatter
                $0.hidden = "$splitNumber == nil || $splitNumber == 0"
                if let splitNumber = transaction.splitNumber, splitNumber != 0 {
                    $0.value = transaction.amount / Double(splitNumber)
                }
            }.cellUpdate { cell, row in
                cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                cell.textField?.textColor = ThemeManager.currentTheme().generalTitleColor
            }
            
            <<< TextRow("Status") {
                $0.cell.isUserInteractionEnabled = false
                $0.cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                $0.cell.textField?.textColor = ThemeManager.currentTheme().generalTitleColor
                $0.title = $0.tag
                $0.value = transaction.status.name
            }.cellUpdate { cell, row in
                cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                cell.textField?.textColor = ThemeManager.currentTheme().generalTitleColor
            }
            
            <<< CheckRow("Should Link") {
                $0.cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
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
                cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
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
            
            <<< LabelRow("Group") { row in
                row.cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                row.cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                row.cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                row.cell.accessoryType = .disclosureIndicator
                row.title = row.tag
                row.value = transaction.group
            }.onCellSelection({ _, row in
                self.openLevel(level: row.tag!, value: row.value!)
            }).cellUpdate { cell, row in
                cell.accessoryType = .disclosureIndicator
                cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
            }
        
            <<< LabelRow("Category") { row in
                row.cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                row.cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                row.cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                row.cell.accessoryType = .disclosureIndicator
                row.title = row.tag
                row.value = transaction.top_level_category
            }.onCellSelection({ _, row in
                self.openLevel(level: row.tag!, value: row.value!)
            }).cellUpdate { cell, row in
                cell.accessoryType = .disclosureIndicator
                cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
            }
        
            <<< LabelRow("Subcategory") { row in
                row.cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                row.cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                row.cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                row.cell.accessoryType = .disclosureIndicator
                row.title = row.tag
                row.value = transaction.category
            }.onCellSelection({ _, row in
                self.openLevel(level: row.tag!, value: row.value!)
            }).cellUpdate { cell, row in
                cell.accessoryType = .disclosureIndicator
                cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
            }
        
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
                $0.value = transaction.transactionDescription
                }.cellUpdate({ (cell, row) in
                    cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                    cell.textView?.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                    cell.textView?.textColor = ThemeManager.currentTheme().generalTitleColor
                    cell.placeholderLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
                }).onChange { row in
                    let reference = Database.database().reference().child(financialTransactionsEntity).child(self.transaction.guid).child("transactionDescription")
                    self.transaction.transactionDescription = row.value
                    reference.setValue(row.value)
                }
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
        let navigationViewController = UINavigationController(rootViewController: destination)
        self.present(navigationViewController, animated: true, completion: nil)
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