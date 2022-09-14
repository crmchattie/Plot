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
    
    var container: Container!
    var eventList = [Activity]()
    var eventIndex: Int = 0
    var healthList = [HealthContainer]()
    var healthIndex: Int = 0
    var taskList = [Activity]()
    var taskIndex: Int = 0
    
    var accounts: [MXAccount] {
        return networkController.financeService.accounts
    }
    lazy var users: [User] = networkController.userService.users
    lazy var filteredUsers: [User] = networkController.userService.users
    lazy var tasks: [Activity] = networkController.activityService.tasks
    lazy var events: [Activity] = networkController.activityService.events
    
    var selectedFalconUsers = [User]()
    
    var active: Bool = false
    var sectionChanged: Bool = false
    
    //added for EventViewController
    var movingBackwards: Bool = false
    
    weak var delegate : UpdateTransactionDelegate?
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
                if row.tag == "Account" || row.tag == "Transacted On" {
                    row.baseCell.isUserInteractionEnabled = false
                }
            }
        }
        if let currentUser = Auth.auth().currentUser?.uid, let participantsIDs = transaction?.participantsIDs, !participantsIDs.contains(currentUser) {
            for row in form.rows {
                row.baseCell.isUserInteractionEnabled = false
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
            print(transaction.guid)
            
            title = "Transaction"
            active = true
            numberFormatter.currencyCode = transaction.currency_code
            
            if transaction.admin == nil, let currentUser = Auth.auth().currentUser?.uid {
                let reference = Database.database().reference().child(financialTransactionsEntity).child(self.transaction.guid).child("admin")
                reference.setValue(currentUser)
                transaction.admin = currentUser
            }
            setupLists()
        } else if let currentUser = Auth.auth().currentUser?.uid {
            title = "New Transaction"
            let ID = Database.database().reference().child(userFinancialTransactionsEntity).child(currentUser).childByAutoId().key ?? ""
            let date = isodateFormatter.string(from: Date())
            transaction = Transaction(description: "Name", amount: 0.0, created_at: date, guid: ID, user_guid: currentUser, type: .debit, status: .posted, category: "Uncategorized", top_level_category: "Uncategorized", user_created: true, admin: currentUser)
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
            self.updateDiscoverDelegate?.itemCreated()
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
//                    self.transaction.transactionDescription = row.value
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
                if let value = row.value {
                    let date = self.isodateFormatter.string(from: value)
                    if let currentUser = Auth.auth().currentUser?.uid {
                        let reference = Database.database().reference().child(userFinancialTransactionsEntity).child(currentUser).child(self.transaction.guid).child("date_for_reports")
                        reference.setValue(date)
                    }
                }
            }
        
        
            <<< PushRow<String>("Type") { row in
                row.cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                row.cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                row.cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
                row.title = row.tag
                if let type = transaction.type {
                    row.value = type.name
                }
                row.options = []
                TransactionType.allCases.forEach {
                    row.options?.append($0.name.capitalized)
                }
            }.onPresent { from, to in
                to.title = "Type"
                to.extendedLayoutIncludesOpaqueBars = true
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
                if let value = row.value {
                    if value == "Income" {
                        self.transaction.type = .credit
                    } else {
                        self.transaction.type = .debit
                    }
                }
            })
            
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
                $0.value = self.transaction.should_link ?? true
                if $0.value ?? false {
                    $0.title = "Included in Financial Profile"
                    $0.cell.tintAdjustmentMode = .automatic
                } else {
                    $0.title = "Not Included in Financial Profile"
                    $0.cell.tintAdjustmentMode = .dimmed
                }
            }.cellUpdate { cell, row in
                cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                cell.tintColor = FalconPalette.defaultBlue
                cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                cell.accessoryType = .checkmark
                row.cell.tintAdjustmentMode = row.value ?? false ? .automatic : .dimmed
            }.onChange { row in
                row.title = row.value ?? false ? "Included in Financial Profile" : "Not Included in Financial Profile"
                row.cell.tintAdjustmentMode = row.value ?? false ? .automatic : .dimmed
                if let currentUser = Auth.auth().currentUser?.uid {
                    let reference = Database.database().reference().child(userFinancialTransactionsEntity).child(currentUser).child(self.transaction.guid).child("should_link")
                    reference.setValue(row.value ?? false)
                }
            }
            
            <<< PushRow<String>("Account") { row in
                row.cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                row.cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                row.cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
                row.title = row.tag
                if let value = transaction.account_name {
                    row.value = value
                } else if transaction.account_name == nil, let value = transaction.account_guid {
                    if let account = accounts.first(where: { $0.guid == value }) {
                        row.value = account.name
                    }
                }
                row.options = []
                accounts.forEach {
                    row.options?.append($0.name.capitalized)
                }
            }.onPresent { from, to in
                to.title = "Accounts"
                to.extendedLayoutIncludesOpaqueBars = true
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
                self.openLevel(level: row.tag!, value: row.value!, otherValue: nil)
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
                row.value = transaction.top_level_category
            }.onCellSelection({ _, row in
                self.openLevel(level: row.tag!, value: row.value!, otherValue: self.transaction.category)
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
                row.value = transaction.category
            }.onCellSelection({ _, row in
                self.openLevel(level: row.tag!, value: row.value!, otherValue: self.transaction.top_level_category)
            }).cellUpdate { cell, row in
                cell.accessoryType = .disclosureIndicator
                cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
                cell.textLabel?.textAlignment = .left
            }
        
            <<< LabelRow("Participants") { row in
                row.cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                row.cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                row.cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
                row.cell.accessoryType = .disclosureIndicator
                row.cell.textLabel?.textAlignment = .left
                row.cell.selectionStyle = .default
                row.title = row.tag
                if transaction.admin == nil || transaction.admin == Auth.auth().currentUser?.uid {
                    row.value = String(self.selectedFalconUsers.count + 1)
                } else {
                    row.value = String(self.selectedFalconUsers.count)
                }
            }.onCellSelection({ _, row in
                self.openParticipantsInviter()
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
                if let tags = self.transaction.tags, !tags.isEmpty {
                    cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                } else {
                    cell.textLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
                }
            }
        
        if delegate == nil && status {
            form.last!
            <<< SegmentedRow<String>("sections"){
                    $0.cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                    if #available(iOS 13.0, *) {
                        $0.cell.segmentedControl.overrideUserInterfaceStyle = ThemeManager.currentTheme().userInterfaceStyle
                    } else {
                        // Fallback on earlier versions
                    }
                    $0.options = ["Tasks", "Events", "Transactions"]
                    $0.value = "Tasks"
                    }.cellUpdate { cell, row in
                        cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                        cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
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
                                            $0.cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                                            $0.title = "Connect Task"
                                            }.cellUpdate { cell, row in
                                                cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
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
                                            $0.cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                                            $0.title = "Connect Event"
                                            }.cellUpdate { cell, row in
                                                cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
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
                                   header: "Health",
                                   footer: "Connect a workout and/or mindfulness session") {
                                    $0.tag = "Health"
                                    $0.hidden = "$sections != 'Health'"
                                    $0.addButtonProvider = { section in
                                        return ButtonRow(){
                                            $0.cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                                            $0.title = "Connect Health"
                                            }.cellUpdate { cell, row in
                                                cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                                                cell.textLabel?.textAlignment = .left
                                                cell.height = { 60 }
                                            }
                                    }
                                    $0.multivaluedRowToInsertAt = { index in
                                        self.healthIndex = index
                                        self.openHealth()
                                        return HealthRow()
                                            .onCellSelection() { cell, row in
                                                self.healthIndex = index
                                                self.openHealth()
                                                cell.cellResignFirstResponder()
                                        }

                                    }

            }
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
        let destination = FinanceTransactionRuleViewController(networkController: networkController)
        destination.transaction = transaction
        self.navigationController?.pushViewController(destination, animated: true)
    }
    
    @objc fileprivate func openLevel(level: String, value: String, otherValue: String?) {
        let destination = FinanceTransactionLevelViewController(networkController: networkController)
        destination.delegate = self
        destination.level = level
        destination.value = value
        destination.otherValue = otherValue
        self.navigationController?.pushViewController(destination, animated: true)
    }
    
    @objc fileprivate func openTags() {
        let destination = TagsViewController()
        destination.delegate = self
        destination.tags = transaction.tags
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
        destination.ownerID = transaction.admin
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
            else if row is HealthRow {
                if self!.healthList.indices.contains(rowNumber) {
                    self!.healthList.remove(at: rowNumber)
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
                if active {
                    Database.database().reference().child(userFinancialTransactionsEntity).child(currentUser).child(self.transaction.guid).child("category").setValue(value)
                }
            } else if level == "Category" {
                transaction.top_level_category = value
                if active {
                    Database.database().reference().child(userFinancialTransactionsEntity).child(currentUser).child(self.transaction.guid).child("top_level_category").setValue(value)
                }
            } else {
                transaction.group = value
                if active {
                    Database.database().reference().child(userFinancialTransactionsEntity).child(currentUser).child(self.transaction.guid).child("group").setValue(value)
                }
            }
        }
    }
}

extension FinanceTransactionViewController: UpdateInvitees {
    func updateInvitees(selectedFalconUsers: [User]) {
        if let inviteesRow: LabelRow = form.rowBy(tag: "Participants") {
            self.selectedFalconUsers = selectedFalconUsers
            if transaction.admin == nil || transaction.admin == Auth.auth().currentUser?.uid {
                inviteesRow.value = String(self.selectedFalconUsers.count + 1)
            } else {
                inviteesRow.value = String(self.selectedFalconUsers.count)
            }
            inviteesRow.updateCell()
            
            if active {
                self.showActivityIndicator()
                let createTransaction = TransactionActions(transaction: self.transaction, active: self.active, selectedFalconUsers: self.selectedFalconUsers)
                createTransaction.updateTransactionParticipants()
                self.hideActivityIndicator()
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
        let reference = Database.database().reference().child(financialTransactionsEntity).child(self.transaction.guid)
        reference.updateChildValues(["tags": tags as AnyObject])
    }
}
