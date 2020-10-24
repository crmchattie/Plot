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
    
    var categories = [String]()
    var topLevelCategories = [String]()
    var groups = [String]()
    
    var value = String()
    var level = String()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureTableView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        print("viewDidAppear")
        updateLevels()
    }
    
    fileprivate func updateLevels() {
        form.removeAll()
        if let currentUser = Auth.auth().currentUser?.uid {
            let dispatchGroup = DispatchGroup()
            let reference = Database.database().reference()
            if level == "Subcategory" {
                categories = financialTransactionsCategories.sorted()
                dispatchGroup.enter()
                reference.child(userFinancialTransactionsCategoriesEntity).child(currentUser).observeSingleEvent(of: .value, with: { snapshot in
                    if snapshot.exists(), let values = snapshot.value as? [String: String] {
                        let array = Array(values.values)
                        self.categories.append(contentsOf: array)
                        self.categories = self.categories.sorted()
                    }
                    dispatchGroup.leave()
                })
            } else if level == "Category" {
                topLevelCategories = financialTransactionsTopLevelCategories.sorted()
                dispatchGroup.enter()
                reference.child(userFinancialTransactionsTopLevelCategoriesEntity).child(currentUser).observeSingleEvent(of: .value, with: { snapshot in
                    if snapshot.exists(), let values = snapshot.value as? [String: String] {
                        let array = Array(values.values)
                        self.topLevelCategories.append(contentsOf: array)
                        self.topLevelCategories = self.topLevelCategories.sorted()
                    }
                    dispatchGroup.leave()
                })
            } else {
                groups = financialTransactionsGroups.sorted()
                dispatchGroup.enter()
                reference.child(userFinancialTransactionsGroupsEntity).child(currentUser).observeSingleEvent(of: .value, with: { snapshot in
                    if snapshot.exists(), let values = snapshot.value as? [String: String] {
                        let array = Array(values.values)
                        self.groups.append(contentsOf: array)
                        self.groups = self.groups.sorted()
                    }
                    dispatchGroup.leave()
                })
            }
            
            dispatchGroup.notify(queue: .main) {
                self.initializeForm()
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
        let addBarButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(create))
        navigationItem.rightBarButtonItems = [addBarButton, newLevelBarButton]
    }
    
    @IBAction func create(_ sender: AnyObject) {
        self.delegate?.update(value: value, level: level)
        self.navigationController?.popViewController(animated: true)
    }
    
    @objc func newLevel(_ item:UIBarButtonItem) {
        let destination = FinanceTransactionNewLevelViewController()
        destination.level = level
        let navigationViewController = UINavigationController(rootViewController: destination)
        navigationViewController.modalPresentationStyle = .fullScreen
        self.present(navigationViewController, animated: true, completion: nil)
    }
    
    fileprivate func initializeForm() {
        form +++ SelectableSection<ListCheckRow<String>>(level, selectionType: .singleSelection(enableDeselection: false))
        
        if level == "Subcategory" {
            for title in categories {
                form.last!
                    <<< ListCheckRow<String>() {
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
                print("title \(title)")
                form.last!
                    <<< ListCheckRow<String>() {
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
                    <<< ListCheckRow<String>() {
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
