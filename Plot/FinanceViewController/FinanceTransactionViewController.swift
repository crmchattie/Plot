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

protocol UpdateTransactionDelegate: class {
    func updateTransaction(transaction: Transaction)
}

class FinanceTransactionViewController: FormViewController {
    var transaction: Transaction!
    
    weak var delegate : UpdateTransactionDelegate?
    
    var status = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        status = transaction.status == .posted
        
        configureTableView()
        initializeForm()
        
        if !status {
            for row in form.rows {
                row.baseCell.isUserInteractionEnabled = false
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
        navigationItem.title = "Transaction"
        let doneBarButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(done))
        navigationItem.rightBarButtonItem = doneBarButton
        
    }
    
    @IBAction func done(_ sender: AnyObject) {
        updateTags()
        self.delegate?.updateTransaction(transaction: transaction)
        self.dismiss(animated: true, completion: nil)
    }
    
    fileprivate func initializeForm() {
        let numberFormatter = NumberFormatter()
        numberFormatter.currencyCode = transaction.currency_code
        numberFormatter.numberStyle = .currency
        
        // create dateFormatter with UTC time format
        let isodateFormatter = ISO8601DateFormatter()
        let dateFormatterPrint = DateFormatter()
        dateFormatterPrint.dateFormat = "E, MMM d, yyyy"
        
        
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
                    self.transaction.description = value
                    if let currentUser = Auth.auth().currentUser?.uid {
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
                
            }
            .onChange { row in
                if let currentUser = Auth.auth().currentUser?.uid, let value = row.value {
                    let date = isodateFormatter.string(from: value)
                    let reference = Database.database().reference().child(userFinancialTransactionsEntity).child(currentUser).child(self.transaction.guid).child("date_for_reports")
                    reference.setValue(date)
                }
            }
            
            <<< TextRow("Amount") {
                $0.cell.isUserInteractionEnabled = false
                $0.cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                $0.cell.textField?.textColor = ThemeManager.currentTheme().generalTitleColor
                $0.title = $0.tag
                if let balance = numberFormatter.string(from: transaction.amount as NSNumber) {
                    $0.value = "\(balance)"
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
                self.transaction.should_link = row.value
                if let currentUser = Auth.auth().currentUser?.uid {
                    let reference = Database.database().reference().child(userFinancialTransactionsEntity).child(currentUser).child(self.transaction.guid).child("should_link")
                    reference.setValue(row.value!)
                }
            }
            
            //            <<< PickerInputRow<String>("Group") { row in
            //            row.cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
            //            row.cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
            //            row.cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
            //            row.title = row.tag
            //            row.value = transaction.group.rawValue.capitalized
            //            TransactionGroup.allCases.forEach {
            //                if $0 != .expense && $0 != .difference {
            //                    row.options.append($0.rawValue.capitalized)
            //                }
            //            }
            //            }.cellUpdate { cell, row in
            //                cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
            //                cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
            //                cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
            //            }.onChange { row in
            //                if let value = row.value, let group = TransactionGroup(rawValue: value) {
            //                    self.transaction.group = group
            //                    if let currentUser = Auth.auth().currentUser?.uid {
            //                        let reference = Database.database().reference().child(userFinancialTransactionsEntity).child(currentUser).child(self.transaction.guid).child("group")
            //                        reference.setValue(value)
            //                    }
            //                }
            //            }
            
            <<< PushRow<String>("Group") { row in
                row.cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                row.cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                row.cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                row.title = row.tag
                row.value = transaction.group.rawValue.capitalized
                row.options = []
                TransactionGroup.allCases.forEach {
                    if $0 != .expense && $0 != .difference {
                        row.options?.append($0.rawValue.capitalized)
                    }
                }
            }.onPresent { from, to in
                to.dismissOnSelection = false
                to.dismissOnChange = false
                to.selectableRowCellUpdate = { cell, row in
                    to.title = "Group"
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
            }.onChange { row in
                if let value = row.value, let group = TransactionGroup(rawValue: value) {
                    self.transaction.group = group
                    if let currentUser = Auth.auth().currentUser?.uid {
                        let reference = Database.database().reference().child(userFinancialTransactionsEntity).child(currentUser).child(self.transaction.guid).child("group")
                        reference.setValue(value)
                    }
                }
            }
            
            <<< PushRow<String>("Category") { row in
                row.cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                row.cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                row.cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                row.title = row.tag
                row.value = transaction.top_level_category.rawValue.capitalized
                row.options = []
                TransactionTopLevelCategory.allCases.forEach {
                    row.options?.append($0.rawValue.capitalized)
                }
            }.onPresent { from, to in
                to.dismissOnSelection = false
                to.dismissOnChange = false
                to.selectableRowCellUpdate = { cell, row in
                    to.title = "Category"
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
            }.onChange { row in
                if let value = row.value, let top = TransactionTopLevelCategory(rawValue: value) {
                    self.transaction.top_level_category = top
                    if let currentUser = Auth.auth().currentUser?.uid {
                        let reference = Database.database().reference().child(userFinancialTransactionsEntity).child(currentUser).child(self.transaction.guid).child("top_level_category")
                        reference.setValue(value)
                    }
                }
            }
            
            <<< PushRow<String>("Subcategory") { row in
                row.cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                row.cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                row.cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                row.title = row.tag
                row.value = transaction.category.rawValue.capitalized
                row.options = []
                TransactionCategory.allCases.forEach {
                    row.options?.append($0.rawValue.capitalized)
                }
                row.options?.sort()
            }.onPresent { from, to in
                to.dismissOnSelection = false
                to.dismissOnChange = false
                to.selectableRowCellUpdate = { cell, row in
                    to.title = "Subcategory"
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
            }.onChange { row in
                if let value = row.value, let cat = TransactionCategory(rawValue: value) {
                    self.transaction.category = cat
                    if let currentUser = Auth.auth().currentUser?.uid {
                        let reference = Database.database().reference().child(userFinancialTransactionsEntity).child(currentUser).child(self.transaction.guid).child("category")
                        reference.setValue(value)
                    }
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
                } , at: mvs.count - 1)
            }
        }
    }
    
    fileprivate func updateTags() {
        if let mvs = (form.values()["tagsfields"] as? [Any?])?.compactMap({ $0 as? String }) {
            if !mvs.isEmpty {
                print("mvs \(mvs)")
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
    
}
