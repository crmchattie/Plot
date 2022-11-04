//
//  FinanceTransactionNewLevelViewController.swift
//  Plot
//
//  Created by Cory McHattie on 10/10/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import UIKit
import Eureka
import Firebase

protocol UpdateTransactionNewLevelDelegate: AnyObject {
    func update(level: String, value: String, otherValue: String?)
}

class FinanceTransactionNewLevelViewController: FormViewController {
    var level = String()
    var name: String? = nil
    var otherValue: String? = nil
    var levels = [String]()
    
    weak var delegate : UpdateTransactionNewLevelDelegate?
    
    var networkController = NetworkController()
    
    init(networkController: NetworkController) {
        super.init(style: .insetGrouped)
        self.networkController = networkController
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
        
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.isNavigationBarHidden = false
        navigationController?.navigationBar.isHidden = false
        navigationItem.largeTitleDisplayMode = .never
        
        title = "New \(level)"
        
        configureTableView()
        initializeForm()
    }
    
    fileprivate func configureTableView() {
        definesPresentationContext = true
        extendedLayoutIncludesOpaqueBars = true
        edgesForExtendedLayout = UIRectEdge.top

        view.backgroundColor = .systemGroupedBackground
        tableView.allowsMultipleSelectionDuringEditing = false
        tableView.indicatorStyle = .default
        tableView.backgroundColor = view.backgroundColor
        tableView.separatorStyle = .none
        navigationOptions = .Disabled
//        let cancelBarButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancel))
//        navigationItem.leftBarButtonItem = cancelBarButton
        let addBarButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(create))
        navigationItem.rightBarButtonItem = addBarButton
    }
    
//    @IBAction func cancel(_ sender: AnyObject) {
//        self.navigationController?.popViewController(animated: true)
//    }
    
    @IBAction func create(_ sender: AnyObject) {
        if let row: TextRow = self.form.rowBy(tag: "Name"), let value = row.value, let currentUser = Auth.auth().currentUser?.uid {
            let newValue = value.removeCharacters()
            if level == "Subcategory", let otherValue = otherValue {
                Database.database().reference().child(userFinancialTransactionsCategoriesEntity).child(currentUser).child(newValue).setValue(otherValue)
                Database.database().reference().child(userFinancialTransactionsTopLevelCategoriesEntity).child(currentUser).child(otherValue).observeSingleEvent(of: .value, with: { snapshot in
                    if snapshot.exists(), let values = snapshot.value as? [String] {
                        var newValues = values
                        newValues.append(newValue)
                        Database.database().reference().child(userFinancialTransactionsTopLevelCategoriesEntity).child(currentUser).child(otherValue).setValue(newValues)
                    } else {
                        Database.database().reference().child(userFinancialTransactionsTopLevelCategoriesEntity).child(currentUser).child(otherValue).setValue([newValue])
                    }
                })
            } else if level == "Category", let otherValue = otherValue {
                Database.database().reference().child(userFinancialTransactionsCategoriesEntity).child(currentUser).child(otherValue).setValue(newValue)
                Database.database().reference().child(userFinancialTransactionsTopLevelCategoriesEntity).child(currentUser).child(newValue).observeSingleEvent(of: .value, with: { snapshot in
                    if snapshot.exists(), let values = snapshot.value as? [String] {
                        var newValues = values
                        newValues.append(otherValue)
                        Database.database().reference().child(userFinancialTransactionsTopLevelCategoriesEntity).child(currentUser).child(newValue).setValue(newValues)
                    } else {
                        Database.database().reference().child(userFinancialTransactionsTopLevelCategoriesEntity).child(currentUser).child(newValue).setValue([otherValue])
                    }
                })
            } else if level == "Group" {
                Database.database().reference().child(userFinancialTransactionsGroupsEntity).child(currentUser).child(newValue).setValue(newValue)
            }
            self.delegate?.update(level: level, value: newValue, otherValue: otherValue)
            self.navigationController?.popViewController(animated: true)

        }
    }
    
    fileprivate func initializeForm() {
        form +++
            Section()
            <<< TextRow("Name") {
                $0.cell.backgroundColor = .secondarySystemGroupedBackground
                $0.cell.textField?.textColor = .label
                $0.placeholderColor = .secondaryLabel
                $0.placeholder = $0.tag
                if let name = name {
                    $0.value = name
                    self.navigationItem.rightBarButtonItem?.isEnabled = true
                } else {
                    self.navigationItem.rightBarButtonItem?.isEnabled = false
//                    $0.cell.textField.becomeFirstResponder()
                }
            }.cellUpdate { cell, row in
                cell.backgroundColor = .secondarySystemGroupedBackground
                cell.textField?.textColor = .label
                row.placeholderColor = .secondaryLabel
            }.onChange() { [unowned self] row in
                if row.value == nil {
                    self.navigationItem.rightBarButtonItem?.isEnabled = false
                } else {
                    self.navigationItem.rightBarButtonItem?.isEnabled = true
                }
            }
        
        if level == "Subcategory" || level == "Category" {
            form.last!
            <<< PushRow<String>("Levels") { row in
                row.cell.backgroundColor = .secondarySystemGroupedBackground
                row.cell.textLabel?.textColor = .label
                row.cell.detailTextLabel?.textColor = .secondaryLabel
                row.options = []
                if self.level == "Subcategory" {
                    row.title = "Associated Category"
                    self.networkController.financeService.transactionTopLevelCategories.sorted().forEach {
                        row.options?.append($0)
                    }
                } else {
                    row.title = "Associated Subcategory"
                    self.networkController.financeService.transactionCategories.sorted().forEach {
                        row.options?.append($0)
                    }
                }
                if let value = otherValue {
                    row.value = value
                } else {
                    row.value = "Uncategorized"
                    otherValue = row.value
                }
            }.onPresent { from, to in
                if self.level == "Subcategory" {
                    to.title = "Categories"
                } else {
                    to.title = "Subcategories"
                }
                to.extendedLayoutIncludesOpaqueBars = true
                to.tableViewStyle = .insetGrouped
                to.selectableRowCellUpdate = { cell, row in
                    to.navigationController?.navigationBar.backgroundColor = .systemGroupedBackground
                    to.tableView.backgroundColor = .systemGroupedBackground
                    to.tableView.separatorStyle = .none
                    cell.backgroundColor = .secondarySystemGroupedBackground
                    cell.textLabel?.textColor = .label
                    cell.detailTextLabel?.textColor = .secondaryLabel
                }
            }.cellUpdate { cell, row in
                cell.backgroundColor = .secondarySystemGroupedBackground
                cell.textLabel?.textColor = .label
                cell.detailTextLabel?.textColor = .secondaryLabel
            }.onChange({ row in
                self.otherValue = row.value
            })
        }
    }
}
