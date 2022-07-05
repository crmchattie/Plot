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

class FinanceTransactionRuleViewController: FormViewController {
    var transactionRule: TransactionRule!
    var transaction: Transaction!
    
    var active: Bool = true
    
    let numberFormatter = NumberFormatter()
    //        numberFormatter.currencyCode = account.currency_code
    
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
        
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for:.default)
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.navigationBar.layoutIfNeeded()
        
        dateFormatterPrint.dateFormat = "MMM dd, yyyy"
        setupVariables()
        configureTableView()
        initializeForm()
    }
    
    fileprivate func setupVariables() {
        if transactionRule == nil, let currentUser = Auth.auth().currentUser?.uid {
            title = "New Transaction Rule"
            active = false
            let ID = Database.database().reference().child(userFinancialTransactionRulesEntity).child(currentUser).childByAutoId().key ?? ""
            let date = isodateFormatter.string(from: Date())
            transactionRule = TransactionRule(created_at: date, guid: ID, match_description: "", description: nil, updated_at: date, user_guid: nil, category: "Uncategorized", top_level_category: "Uncategorized", group: "Uncategorized", amount: nil, should_link: true)
        } else {
            title = "Transaction Rule"
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
        if let currentUser = Auth.auth().currentUser?.uid {
            let guid = transactionRule.guid
            do {
                let value = try FirebaseEncoder().encode(transactionRule)
                Database.database().reference().child(userFinancialTransactionRulesEntity).child(currentUser).child(guid).setValue(value)
            } catch let error {
                print(error)
            }
            if navigationItem.leftBarButtonItem != nil {
                self.dismiss(animated: true, completion: nil)
            } else {
                self.navigationController?.popViewController(animated: true)
            }
        }
    }
    
    fileprivate func initializeForm() {
        form +++
            Section(header: nil, footer: "Set-up a rule to automatically rename, categorize and/or ignore certain transactions based on the name and/or amount")
            
            <<< TextRow("Transaction name contains") {
                $0.cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                $0.cell.textField?.textColor = ThemeManager.currentTheme().generalSubtitleColor
                $0.title = $0.tag
                if transactionRule.match_description != "" {
                    $0.value = transactionRule.match_description
                    self.navigationItem.rightBarButtonItem?.isEnabled = true
                } else if let transaction = transaction {
                    $0.value = transaction.description
                    transactionRule.match_description = transaction.description
                    self.navigationItem.rightBarButtonItem?.isEnabled = true
                } else {
                    self.navigationItem.rightBarButtonItem?.isEnabled = false
                    $0.cell.textField.becomeFirstResponder()
                }
            }.cellUpdate { cell, row in
                cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                cell.textField?.textColor = ThemeManager.currentTheme().generalSubtitleColor
            }.onChange() { [unowned self] row in
                if row.value == nil {
                    self.navigationItem.rightBarButtonItem?.isEnabled = false
                } else {
                    self.transactionRule.match_description = row.value!
                    self.navigationItem.rightBarButtonItem?.isEnabled = true
                }
            }
            
            <<< TextRow("Update transaction name to") {
                $0.cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                $0.cell.textField?.textColor = ThemeManager.currentTheme().generalSubtitleColor
                $0.title = $0.tag
                if let description = transactionRule.description {
                    $0.value = description
                }
            }.cellUpdate { cell, row in
                cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                cell.textField?.textColor = ThemeManager.currentTheme().generalSubtitleColor
            }.onChange() { [unowned self] row in
                self.transactionRule.description = row.value
            }
            
            <<< DecimalRow("Transaction amount equals") {
                $0.cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                $0.cell.textField?.textColor = ThemeManager.currentTheme().generalSubtitleColor
                $0.title = $0.tag
                if let amount = transactionRule.amount {
                    $0.value = amount
                } else if let transaction = transaction {
                    $0.value = transaction.amount
                    transactionRule.amount = transaction.amount
                }
            }.cellUpdate { cell, row in
                cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                cell.textField?.textColor = ThemeManager.currentTheme().generalSubtitleColor
            }.onChange() { [unowned self] row in
                self.transactionRule.amount = row.value
            }
            
            <<< CheckRow() {
                $0.cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                $0.cell.tintColor = FalconPalette.defaultBlue
                $0.cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                $0.cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
                $0.cell.accessoryType = .checkmark
                if let should_link = transactionRule.should_link {
                    $0.title = "Included in Financial Profile"
                    $0.value = should_link
                } else if let should_link = transaction.should_link {
                    $0.title = "Included in Financial Profile"
                    $0.value = should_link
                    transactionRule.should_link = should_link
                } else {
                    $0.title = "Not Included in Financial Profile"
                    $0.value = true
                    transactionRule.should_link = true
                }
            }.cellUpdate { cell, row in
                cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                cell.tintColor = FalconPalette.defaultBlue
                cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
            }.onChange { row in
                row.title = row.value! ? "Included in Financial Profile" : "Not Included in Financial Profile"
                row.updateCell()
                self.transactionRule.should_link = row.value!
            }
            
            <<< LabelRow("Group") { row in
                row.cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                row.cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                row.cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
                row.cell.accessoryType = .disclosureIndicator
                row.title = row.tag
                if let string = transactionRule.group {
                    row.value = string
                } else if let transaction = transaction {
                    row.value = transaction.group
                    transactionRule.group = transaction.group
                }
            }.onCellSelection({ _, row in
                self.openLevel(level: row.tag!, value: row.value!)
            }).cellUpdate { cell, row in
                cell.accessoryType = .disclosureIndicator
                cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
            }
        
            <<< LabelRow("Category") { row in
                row.cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                row.cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                row.cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
                row.cell.accessoryType = .disclosureIndicator
                row.title = row.tag
                if let string = transactionRule.top_level_category {
                    row.value = string
                } else if let transaction = transaction {
                    row.value = transaction.top_level_category
                    transactionRule.top_level_category = transaction.top_level_category
                }
            }.onCellSelection({ _, row in
                self.openLevel(level: row.tag!, value: row.value!)
            }).cellUpdate { cell, row in
                cell.accessoryType = .disclosureIndicator
                cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
            }
        
            <<< LabelRow("Subcategory") { row in
                row.cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                row.cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                row.cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
                row.cell.accessoryType = .disclosureIndicator
                row.title = row.tag
                if let string = transactionRule.top_level_category {
                    row.value = string
                } else if let transaction = transaction {
                    row.value = transaction.top_level_category
                    transactionRule.category = transaction.category
                }
            }.onCellSelection({ _, row in
                self.openLevel(level: row.tag!, value: row.value!)
            }).cellUpdate { cell, row in
                cell.accessoryType = .disclosureIndicator
                cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
            }
    }
    
    @objc fileprivate func openLevel(level: String, value: String) {
        let destination = FinanceTransactionLevelViewController()
        destination.delegate = self
        destination.level = level
        destination.value = value
        self.navigationController?.pushViewController(destination, animated: true)
    }
    
}

extension FinanceTransactionRuleViewController: UpdateTransactionLevelDelegate {
    func update(value: String, level: String) {
        if let row: LabelRow = form.rowBy(tag: level), let _ = Auth.auth().currentUser?.uid {
            row.value = value
            row.updateCell()
            if level == "Subcategory" {
                transactionRule.category = value
            } else if level == "Category" {
                transactionRule.top_level_category = value
            } else {
                transactionRule.group = value
            }
        }
    }
}
