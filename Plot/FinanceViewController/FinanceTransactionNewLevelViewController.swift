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

protocol UpdateTransactionLevelDelegate: class {
    func update(category: String?, topLevelCategory: String?, group: String?)
}

class FinanceTransactionNewLevelViewController: FormViewController {
    var category: String?
    var topLevelCategory: String?
    var group: String?
    
    var name: String? = nil
    
    weak var delegate : UpdateTransactionLevelDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let name = self.category {
            self.name = name
        } else if let name = self.topLevelCategory {
            self.name = name
        } else if let name = self.group {
            self.name = name
        }
        
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
        if let _ = name {
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
        if let row: TextRow = self.form.rowBy(tag: "Name"), let value = row.value, let currentUser = Auth.auth().currentUser?.uid {
            if let _ = self.category {
                let reference = Database.database().reference().child(userFinancialTransactionsCategoriesEntity).child(currentUser)
                reference.observeSingleEvent(of: .value, with: { snapshot in
                    if snapshot.exists(), let values = snapshot.value as? [String: String] {
                        var array = Array(values.values)
                        array.append(value)
                        reference.setValue(array)
                    } else {
                        reference.setValue([value])
                    }
                })
            } else if let _ = self.topLevelCategory {
                let reference = Database.database().reference().child(userFinancialTransactionsTopLevelCategoriesEntity).child(currentUser)
                reference.observeSingleEvent(of: .value, with: { snapshot in
                    if snapshot.exists(), let values = snapshot.value as? [String: String] {
                        var array = Array(values.values)
                        array.append(value)
                        reference.setValue(array)
                    } else {
                        reference.setValue([value])
                    }
                })
            } else if let _ = self.group {
                let reference = Database.database().reference().child(userFinancialTransactionsGroupsEntity).child(currentUser)
                reference.observeSingleEvent(of: .value, with: { snapshot in
                    if snapshot.exists(), let values = snapshot.value as? [String: String] {
                        var array = Array(values.values)
                        array.append(value)
                        reference.setValue(array)
                    } else {
                        reference.setValue([value])
                    }
                })
            }
        }
        self.delegate?.update(category: category, topLevelCategory: topLevelCategory, group: group)
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
