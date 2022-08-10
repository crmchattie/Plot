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

protocol UpdateTransactionLevelDelegate: AnyObject {
    func update(value: String, level: String)
}

class FinanceTransactionLevelViewController: FormViewController {
    weak var delegate : UpdateTransactionLevelDelegate?
    
    var levels = [String: [String]]()
    var oldValue = String()
    var value = String()
    var otherValue: String? = nil
    var level = String()
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
        title = level
        configureTableView()
        oldValue = value
        updateLevels()
    }
    
    fileprivate func updateLevels() {
        form.removeAll()
        if let otherValue = otherValue {
            if level == "Subcategory" {
                if let subcategories = networkController.financeService.transactionTopLevelCategoriesDictionary[otherValue] {
                    self.levels["Current Category's Subcategories"] = subcategories
                    self.levels["Other Subcategories"] = networkController.financeService.transactionCategories.filter({ !subcategories.contains($0) })
                }
            } else if level == "Category" {
                if let category = networkController.financeService.transactionCategoriesDictionary[otherValue] {
                    self.levels["Current Subcategory's Category"] = [category]
                    self.levels["Other Categories"] = networkController.financeService.transactionTopLevelCategories.filter({ $0 != category })
                }
            }
        } else {
            levels[level] = networkController.financeService.transactionGroups
        }
        
        self.initializeForm()
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
//        let newLevelBarButton = UIBarButtonItem(title: "New \(level)", style: .plain, target: self, action: #selector(newLevel))
//        navigationItem.rightBarButtonItem = newLevelBarButton
    }
    
    @objc func newLevel(_ item:UIBarButtonItem) {
        let destination = FinanceTransactionNewLevelViewController(networkController: networkController)
        destination.level = level
        destination.delegate = self
        self.navigationController?.pushViewController(destination, animated: true)
    }
    
    fileprivate func initializeForm() {
        for section in levels.keys.sorted() {
            form +++ SelectableSection<ListCheckRow<String>>(section, selectionType: .singleSelection(enableDeselection: false))
            for level in levels[section]?.sorted() ?? [] {
                form.last!
                    <<< ListCheckRow<String>() {
                        $0.cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                        $0.cell.tintColor = FalconPalette.defaultBlue
                        $0.cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                        $0.cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                        $0.title = level
                        $0.selectableValue = level
                        if level == self.value {
                            $0.value = self.value
                        }
                    }.cellSetup { cell, row in
                        cell.accessoryType = .checkmark
                        cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                        cell.tintColor = FalconPalette.defaultBlue
                        cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                        cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                    }.onChange({ (row) in
                        if let value = row.value {
                            self.delegate?.update(value: value, level: self.level)
                            self.navigationController?.popViewController(animated: true)
                        }
                    })
            }
        }
    }
    
}

extension FinanceTransactionLevelViewController: UpdateTransactionNewLevelDelegate {
    func update(level: String, value: String, otherValue: String?) {
        form.removeAll()
        if level == "Subcategory", let otherValue = otherValue {
            if otherValue == otherValue {
                self.levels["Current Category's Subcategories", default: []].append(value)
            } else {
                self.levels["Other Subcategories", default: []].append(value)
            }
        } else if level == "Category", let otherValue = otherValue {
            if otherValue == otherValue {
                self.levels["Current Subcategory's Category", default: []].append(value)
            } else {
                self.levels["Other Categories", default: []].append(value)
            }
        } else {
            levels[level]?.append(value)
        }
        initializeForm()
        networkController.financeService.grabTransactionAttributes()
    }
}
