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

class FinanceTransactionNewLevelViewController: FormViewController {
    var level = String()
    var name: String? = nil
        
    override func viewDidLoad() {
        super.viewDidLoad()
        configureTableView()
        initializeForm()
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
        let cancelBarButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancel))
        navigationItem.leftBarButtonItem = cancelBarButton
        let addBarButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(create))
        navigationItem.rightBarButtonItem = addBarButton
    }
    
    @IBAction func cancel(_ sender: AnyObject) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func create(_ sender: AnyObject) {
        if let row: TextRow = self.form.rowBy(tag: "Name"), let value = row.value, let currentUser = Auth.auth().currentUser?.uid {
            if level == "Subcategory" {
                Database.database().reference().child(userFinancialTransactionsCategoriesEntity).child(currentUser).child(value).setValue(value)
            } else if level == "Category" {
                Database.database().reference().child(userFinancialTransactionsTopLevelCategoriesEntity).child(currentUser).child(value).setValue(value)
            } else if level == "Group" {
                Database.database().reference().child(userFinancialTransactionsGroupsEntity).child(currentUser).child(value).setValue(value)
            }
        }
        self.dismiss(animated: true, completion: nil)
    }
    
    fileprivate func initializeForm() {
        form +++
            Section()
            <<< TextRow("Name") {
                $0.cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                $0.cell.textField?.textColor = ThemeManager.currentTheme().generalTitleColor
                $0.title = $0.tag
                if let name = name {
                    $0.value = name
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
                    self.navigationItem.rightBarButtonItem?.isEnabled = true
                }
            }
    }
        
    
}
