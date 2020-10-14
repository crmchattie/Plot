//
//  FinanceTransactionRuleViewController.swift
//  Plot
//
//  Created by Cory McHattie on 10/10/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import UIKit
import Eureka
import Firebase
import CodableFirebase

protocol UpdateTransactionRuleDelegate: class {
    
}

class FinanceTransactionRuleViewController: FormViewController {
    var transactionRule: TransactionRule!
    var transaction: Transaction!
    
    var active: Bool = true
    
    var categories = TransactionCategory.allCases
    var topLevelCategories = TransactionTopLevelCategory.allCases
    var groups = TransactionGroup.allCases.filter({ $0 != .difference || $0 != .expense })
    
    weak var delegate : UpdateTransactionRuleDelegate?
    
    let numberFormatter = NumberFormatter()
    //        numberFormatter.currencyCode = account.currency_code
    
    // create dateFormatter with UTC time format
    let isodateFormatter = ISO8601DateFormatter()
    let dateFormatterPrint = DateFormatter()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        dateFormatterPrint.dateFormat = "MMM dd, yyyy"
        setupVariables()
        configureTableView()
        initializeForm()
    }
    
    fileprivate func setupVariables() {
        if transactionRule == nil, let currentUser = Auth.auth().currentUser?.uid {
            active = false
            let ID = Database.database().reference().child(userFinancialTransactionRulesEntity).child(currentUser).childByAutoId().key ?? ""
            let date = isodateFormatter.string(from: Date())
            transactionRule = TransactionRule(created_at: date, guid: ID, match_description: "", description: nil, updated_at: date, user_guid: transaction.user_guid, category: nil, top_level_category: nil, group: nil, amount: nil)
        }
        
        if let currentUser = Auth.auth().currentUser?.uid {
            let dispatchGroup = DispatchGroup()
            dispatchGroup.enter()
            var reference = Database.database().reference().child(userFinancialTransactionsCategoriesEntity).child(currentUser)
            reference.observeSingleEvent(of: .value, with: { snapshot in
                if snapshot.exists(), let values = snapshot.value as? [String: String] {
                    do {
                        let array = Array(values.values)
                        let object = try FirebaseDecoder().decode([TransactionCategory].self, from: array)
                        self.categories.append(contentsOf: object)
                    } catch {
                        print(error.localizedDescription)
                    }
                }
                dispatchGroup.leave()
            })
            
            dispatchGroup.enter()
            reference = Database.database().reference().child(userFinancialTransactionsTopLevelCategoriesEntity).child(currentUser)
            reference.observeSingleEvent(of: .value, with: { snapshot in
                if snapshot.exists(), let values = snapshot.value as? [String: String] {
                    do {
                        let array = Array(values.values)
                        let object = try FirebaseDecoder().decode([TransactionTopLevelCategory].self, from: array)
                        self.topLevelCategories.append(contentsOf: object)
                    } catch {
                        print(error.localizedDescription)
                    }
                }
                dispatchGroup.leave()
            })
            
            dispatchGroup.enter()
            reference = Database.database().reference().child(userFinancialTransactionsGroupsEntity).child(currentUser)
            reference.observeSingleEvent(of: .value, with: { snapshot in
                if snapshot.exists(), let values = snapshot.value as? [String: String] {
                    do {
                        let array = Array(values.values)
                        let object = try FirebaseDecoder().decode([TransactionGroup].self, from: array)
                        self.groups.append(contentsOf: object)
                    } catch {
                        print(error.localizedDescription)
                    }
                }
                dispatchGroup.leave()
            })
            
            dispatchGroup.notify(queue: .main) {
                self.tableView.reloadData()
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
        navigationItem.title = "Transaction Rule"
        
        let cancelBarButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancel))
        navigationItem.leftBarButtonItem = cancelBarButton
        if active {
            let barButton = UIBarButtonItem(title: "Update", style: .plain, target: self, action: #selector(create))
            navigationItem.rightBarButtonItem = barButton
        } else {
            let barButton = UIBarButtonItem(title: "Create", style: .plain, target: self, action: #selector(create))
            navigationItem.rightBarButtonItem = barButton
        }
    }
    
    @IBAction func cancel(_ sender: AnyObject) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func create(_ sender: AnyObject) {
        if let currentUser = Auth.auth().currentUser?.uid {
            let guid = transactionRule.guid
            do {
                let value = try FirebaseEncoder().encode(transactionRule)
                Database.database().reference().child(userFinancialTransactionRulesEntity).child(currentUser).child(guid).setValue(value)
            } catch let error {
                print(error)
            }
        }
        self.dismiss(animated: true, completion: nil)
    }
    
    fileprivate func initializeForm() {
        form +++
            Section(header: "", footer: "Set-up a rule to automatically categorize transactions that contain a certain description and/or meet a certain amount")
            
            <<< TextRow("Transaction name contains") {
                $0.cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                $0.cell.textField?.textColor = ThemeManager.currentTheme().generalTitleColor
                $0.title = $0.tag
                if transactionRule.match_description != "" {
                    $0.value = transactionRule.match_description
                    self.navigationItem.rightBarButtonItem?.isEnabled = true
                } else if let transaction = transaction {
                    $0.value = transaction.description
                    self.navigationItem.rightBarButtonItem?.isEnabled = true
                } else {
                    self.navigationItem.rightBarButtonItem?.isEnabled = false
                    $0.cell.textField.becomeFirstResponder()
                }
            }.cellUpdate { cell, row in
                cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                cell.textField?.textColor = ThemeManager.currentTheme().generalTitleColor
            }.onChange() { [unowned self] row in
                if row.value == nil {
                    self.navigationItem.rightBarButtonItem?.isEnabled = false
                } else {
                    self.transactionRule.match_description = row.value!
                    self.navigationItem.rightBarButtonItem?.isEnabled = true
                }
            }
            
            <<< TextRow("Update transaction name to") {
                $0.cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                $0.cell.textField?.textColor = ThemeManager.currentTheme().generalTitleColor
                $0.title = $0.tag
                if let description = transactionRule.description {
                    $0.value = description
                }
            }.cellUpdate { cell, row in
                cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                cell.textField?.textColor = ThemeManager.currentTheme().generalTitleColor
            }.onChange() { [unowned self] row in
                if row.value != nil {
                    self.transactionRule.description = row.value!
                }
            }
            
            <<< DecimalRow("Transaction amount equals") {
                $0.cell.isUserInteractionEnabled = false
                $0.cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                $0.cell.textField?.textColor = ThemeManager.currentTheme().generalTitleColor
                $0.title = $0.tag
                if let amount = transactionRule.amount {
                    $0.value = amount
                } else if let transaction = transaction {
                    $0.value = transaction.amount
                }
            }.cellUpdate { cell, row in
                cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                cell.textField?.textColor = ThemeManager.currentTheme().generalTitleColor
            }.onChange() { [unowned self] row in
                if row.value != nil {
                    self.transactionRule.amount = row.value!
                }
            }
            
            <<< PushRow<String>("Group") { row in
                row.cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                row.cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                row.cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                row.title = row.tag
                if let string = transactionRule.group {
                    row.value = string.rawValue.capitalized
                } else if let transaction = transaction {
                    row.value = transaction.group.rawValue.capitalized
                }
                row.options = []
                groups.forEach {
                    row.options?.append($0.rawValue.capitalized)
                }
            }.onPresent { from, to in
                to.dismissOnSelection = false
                to.dismissOnChange = false
                to.selectableRowCellUpdate = { cell, row in
                    to.title = "Group"
                    to.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "New Item", style: .plain, target: from, action: #selector(FinanceTransactionViewController.newLevel(_:)))
                    to.tableView.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                    to.tableView.separatorStyle = .none
                    cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                    cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                    cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                }
            }.cellUpdate { cell, row in
                cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
            }.onChange() { [unowned self] row in
                if let value = row.value, let group = TransactionGroup(rawValue: value) {
                    self.transactionRule.group = group
                }
            }
            
            <<< PushRow<String>("Category") { row in
                row.cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                row.cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                row.cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                row.title = row.tag
                if let string = transactionRule.top_level_category {
                    row.value = string.rawValue.capitalized
                } else if let transaction = transaction {
                    row.value = transaction.top_level_category.rawValue.capitalized
                }
                row.options = []
                topLevelCategories.forEach {
                    row.options?.append($0.rawValue.capitalized)
                }
            }.onPresent { from, to in
                to.dismissOnSelection = false
                to.dismissOnChange = false
                to.selectableRowCellUpdate = { cell, row in
                    to.title = "Category"
                    to.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "New Item", style: .plain, target: from, action: #selector(FinanceTransactionViewController.newLevel(_:)))
                    to.tableView.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                    to.tableView.separatorStyle = .none
                    cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                    cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                    cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                }
            }.cellUpdate { cell, row in
                cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
            }.onChange() { [unowned self] row in
                if let value = row.value, let top = TransactionTopLevelCategory(rawValue: value) {
                    self.transactionRule.top_level_category = top
                }
            }
            
            <<< PushRow<String>("Subcategory") { row in
                row.cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                row.cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                row.cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                row.title = row.tag
                if let string = transactionRule.category {
                    row.value = string.rawValue.capitalized
                } else if let transaction = transaction {
                    row.value = transaction.category.rawValue.capitalized
                }
                row.options = []
                categories.forEach {
                    row.options?.append($0.rawValue.capitalized)
                }
                row.options?.sort()
            }.onPresent { from, to in
                to.dismissOnSelection = false
                to.dismissOnChange = false
                to.selectableRowCellUpdate = { cell, row in
                    to.title = "Subcategory"
                    to.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "New Item", style: .plain, target: from, action: #selector(FinanceTransactionViewController.newLevel(_:)))
                    to.tableView.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                    to.tableView.separatorStyle = .none
                    
                    cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                    cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                    cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                }
            }.cellUpdate { cell, row in
                cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
            }.onChange() { [unowned self] row in
                if let value = row.value, let cat = TransactionCategory(rawValue: value) {
                    self.transactionRule.category = cat
                }
            }
    }
    
    
}
