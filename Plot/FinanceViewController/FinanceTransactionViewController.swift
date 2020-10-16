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
    var user: MXUser!
    var accounts: [MXAccount]!
    
    var users = [User]()
    var filteredUsers = [User]()
    var selectedFalconUsers = [User]()
    
    var userNames : [String] = []
    var userNamesString: String = ""
    
    var active: Bool = false
    
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
                if ((row as? CheckRow) == nil) {
                    row.baseCell.isUserInteractionEnabled = false
                }
            }
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
        } else if let currentUser = Auth.auth().currentUser?.uid {
            let ID = Database.database().reference().child(userFinancialTransactionsEntity).child(currentUser).childByAutoId().key ?? ""
            let date = isodateFormatter.string(from: Date())
            transaction = Transaction(description: "Transaction Name", amount: 0.0, created_at: date, guid: ID, user_guid: user.guid, status: .posted, category: "Uncategorized", top_level_category: "Uncategorized", user_created: true, admin: currentUser)
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
        
        if active {
            let barButton = UIBarButtonItem(title: "Update", style: .plain, target: self, action: #selector(create))
            navigationItem.rightBarButtonItem = barButton
            let ruleBarButton = UIBarButtonItem(title: "New Rule", style: .plain, target: self, action: #selector(createRule))
            navigationItem.leftBarButtonItem = ruleBarButton
        } else {
            let barButton = UIBarButtonItem(title: "Create", style: .plain, target: self, action: #selector(create))
            navigationItem.rightBarButtonItem = barButton
            let cancelBarButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancel))
            navigationItem.leftBarButtonItem = cancelBarButton
        }
        
    }
    
    @IBAction func create(_ sender: AnyObject) {
        if transaction.user_created ?? false, !active {
            self.showActivityIndicator()
            let createTransaction = TransactionActions(transaction: self.transaction, active: self.active, selectedFalconUsers: self.selectedFalconUsers)
            createTransaction.createNewTransaction()
            self.hideActivityIndicator()
        }
        self.delegate?.updateTransaction(transaction: transaction)
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func cancel(_ sender: AnyObject) {
        self.dismiss(animated: true, completion: nil)
    }
    
    fileprivate func initializeForm() {
        form +++
            Section()
            
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
//            <<< IntRow("Split amount between") {
//                $0.cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
//                $0.cell.textField?.textColor = ThemeManager.currentTheme().generalTitleColor
//                $0.title = $0.tag
//                $0.value = transaction.splitNumber ?? transaction.participantsIDs?.count ?? 0
//            }.cellUpdate { cell, row in
//                cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
//                cell.textField?.textColor = ThemeManager.currentTheme().generalTitleColor
//            }.onChange { row in
//                let reference = Database.database().reference().child(financialTransactionsEntity).child(self.transaction.guid).child("splitNumber")
//                if let value = row.value {
//                    self.transaction.splitNumber = value
//                    reference.setValue(value)
//                } else {
//                    self.transaction.splitNumber = nil
//                    reference.removeValue()
//                }
//            }
            
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
            
            <<< CheckRow() {
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
        
            
            
        form +++
            Section()
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
        
        form +++
            MultivaluedSection(multivaluedOptions: [.Insert, .Delete],
                               header: "Tags",
                               footer: """
                               If status is posted, the Name, Financial Profile Date, Group, Category, Subcategory and Tag values can be changed
                               If status is pending, values cannot be changed
                               """) {
                                $0.tag = "tagsfields"
                                $0.addButtonProvider = { section in
                                    return ButtonRow(){
                                        $0.cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                                        $0.title = "Add New Tag"
                                    }.cellUpdate { cell, row in
                                        cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                                        cell.textLabel?.textAlignment = .left
                                        
                                    }
                                }
                                $0.multivaluedRowToInsertAt = { index in
                                    return TextRow() {
                                        $0.cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                                        $0.cell.textField?.textColor = ThemeManager.currentTheme().generalTitleColor
                                        $0.placeholderColor = ThemeManager.currentTheme().generalSubtitleColor
                                        $0.placeholder = "Tag"
                                    }.cellUpdate { cell, row in
                                        cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                                        cell.textField?.textColor = ThemeManager.currentTheme().generalTitleColor
                                        row.placeholderColor = ThemeManager.currentTheme().generalSubtitleColor
                                    }.onChange() { _ in
                                        self.updateTags()
                                    }
                                }
        }
        
        if let items = self.transaction.tags {
            for item in items {
                var mvs = (form.sectionBy(tag: "tagsfields") as! MultivaluedSection)
                mvs.insert(TextRow(){
                    $0.cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                    $0.cell.textField?.textColor = ThemeManager.currentTheme().generalTitleColor
                    $0.placeholderColor = ThemeManager.currentTheme().generalSubtitleColor
                    $0.value = item
                }.cellUpdate { cell, row in
                    cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                    cell.textField?.textColor = ThemeManager.currentTheme().generalTitleColor
                    row.placeholderColor = ThemeManager.currentTheme().generalSubtitleColor
                }.onChange() { _ in
                    self.updateTags()
                } , at: mvs.count - 1)
            }
        }
    }
    
    fileprivate func updateTags() {
        if let mvs = (form.values()["tagsfields"] as? [Any?])?.compactMap({ $0 as? String }) {
            if !mvs.isEmpty {
                var tagsArray = [String]()
                for value in mvs {
                    tagsArray.append(value)
                }
                self.transaction.tags = tagsArray
            } else {
                self.transaction.tags = nil
            }
            if let currentUser = Auth.auth().currentUser?.uid {
                let updatedTags = ["tags": self.transaction.tags as AnyObject]
                Database.database().reference().child(userFinancialTransactionsEntity).child(currentUser).child(self.transaction.guid).updateChildValues(updatedTags)
            }
        }
    }
    
    @objc func createRule(_ item:UIBarButtonItem) {
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
        let navigationViewController = UINavigationController(rootViewController: destination)
        self.present(navigationViewController, animated: true, completion: nil)
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
        if let inviteesRow: ButtonRow = form.rowBy(tag: "Participants") {
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
        }
    }
}
