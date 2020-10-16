//
//  FinanceTransactionTypeViewController.swift
//  Plot
//
//  Created by Cory McHattie on 10/13/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import UIKit
import Eureka
import Firebase

protocol UpdateTransactionLevelDelegate: class {
    func update(value: String, level: String)
}

class FinanceTransactionLevelViewController: FormViewController {
    weak var delegate : UpdateTransactionLevelDelegate?
    
    var categories = financialTransactionsCategories.sorted()
    var topLevelCategories = financialTransactionsTopLevelCategories.sorted()
    var groups = financialTransactionsGroups.sorted()
    
    var value = String()
    var level = String()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureTableView()
        initializeForm()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if let currentUser = Auth.auth().currentUser?.uid {
            let dispatchGroup = DispatchGroup()
            var reference = Database.database().reference().child(userFinancialTransactionsCategoriesEntity).child(currentUser)
            if level == "Subcategory" {
                dispatchGroup.enter()
                reference.observeSingleEvent(of: .value, with: { snapshot in
                    if snapshot.exists(), let values = snapshot.value as? [String: String] {
                        let array = Array(values.values)
                        self.categories.append(contentsOf: array)
                    }
                    dispatchGroup.leave()
                })
            } else if level == "Category" {
                dispatchGroup.enter()
                reference = Database.database().reference().child(userFinancialTransactionsTopLevelCategoriesEntity).child(currentUser)
                reference.observeSingleEvent(of: .value, with: { snapshot in
                    if snapshot.exists(), let values = snapshot.value as? [String: String] {
                        let array = Array(values.values)
                        self.topLevelCategories.append(contentsOf: array)
                    }
                    dispatchGroup.leave()
                })
            } else {
                dispatchGroup.enter()
                reference = Database.database().reference().child(userFinancialTransactionsGroupsEntity).child(currentUser)
                reference.observeSingleEvent(of: .value, with: { snapshot in
                    if snapshot.exists(), let values = snapshot.value as? [String: String] {
                        let array = Array(values.values)
                        self.groups.append(contentsOf: array)
                    }
                    dispatchGroup.leave()
                })
            }
            
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
        
        let newLevelBarButton = UIBarButtonItem(title: "New Item", style: .plain, target: self, action: #selector(newLevel))
        navigationItem.leftBarButtonItem = newLevelBarButton
        let updateBarButton = UIBarButtonItem(title: "Update", style: .plain, target: self, action: #selector(update))
        navigationItem.rightBarButtonItem = updateBarButton
    }
    
    @IBAction func update(_ sender: AnyObject) {
        self.delegate?.update(value: value, level: level)
        self.dismiss(animated: true, completion: nil)
    }
    
    @objc func newLevel(_ item:UIBarButtonItem) {
        let destination = FinanceTransactionNewLevelViewController()
        let navigationViewController = UINavigationController(rootViewController: destination)
        self.present(navigationViewController, animated: true, completion: nil)
    }
    
    fileprivate func initializeForm() {
        form +++ SelectableSection<ListCheckRow<String>>(level, selectionType: .singleSelection(enableDeselection: false))
        
        if level == "Subcategory" {
            for title in categories {
                form.last!
                    <<< ListCheckRow<String>(title) {
                        $0.cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                        $0.cell.tintColor = FalconPalette.defaultBlue
                        $0.cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                        $0.cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                        $0.title = title
                        $0.selectableValue = title
                        if title == self.value {
                            $0.value = self.value
                        }
                    }.cellSetup { cell, row in
                        cell.accessoryType = .checkmark
                        cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                        cell.tintColor = FalconPalette.defaultBlue
                        cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                        cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                    }.onChange({ (row) in
                        if let value = row.value {
                            self.value = value
                        }
                    })
            }
        } else if level == "Category" {
            for title in topLevelCategories {
                form.last!
                    <<< ListCheckRow<String>(title) {
                        $0.cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                        $0.cell.tintColor = FalconPalette.defaultBlue
                        $0.cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                        $0.cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                        $0.title = title
                        $0.selectableValue = title
                        if title == self.value {
                            $0.value = self.value
                        }
                    }.cellSetup { cell, row in
                        cell.accessoryType = .checkmark
                        cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                        cell.tintColor = FalconPalette.defaultBlue
                        cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                        cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                    }.onChange({ (row) in
                        if let value = row.value {
                            self.value = value
                        }
                    })
            }
        } else {
            for title in groups {
                form.last!
                    <<< ListCheckRow<String>(title) {
                        $0.cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                        $0.cell.tintColor = FalconPalette.defaultBlue
                        $0.cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                        $0.cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                        $0.title = title
                        $0.selectableValue = title
                        if title == self.value {
                            $0.value = self.value
                        }
                    }.cellSetup { cell, row in
                        cell.accessoryType = .checkmark
                        cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                        cell.tintColor = FalconPalette.defaultBlue
                        cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                        cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                    }.onChange({ (row) in
                        if let value = row.value {
                            self.value = value
                        }
                    })
            }
        }
        
    }
    
}
