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
    
    var levels = [String]()
    
    var oldValue = String()
    var value = String()
    var level = String()
    
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
        title = level
        view.addSubview(activityIndicatorView)
        activityIndicatorView.centerInSuperview()
        activityIndicatorView.startAnimating()
        configureTableView()
        oldValue = value
        updateLevels()
    }
    
    fileprivate func updateLevels() {
        form.removeAll()
        if let currentUser = Auth.auth().currentUser?.uid {
            let dispatchGroup = DispatchGroup()
            let reference = Database.database().reference()
            if level == "Subcategory" {
                levels = financialTransactionsCategories.sorted()
                dispatchGroup.enter()
                reference.child(userFinancialTransactionsCategoriesEntity).child(currentUser).observeSingleEvent(of: .value, with: { snapshot in
                    if snapshot.exists(), let values = snapshot.value as? [String: String] {
                        let array = Array(values.values)
                        self.levels.append(contentsOf: array)
                        self.levels = self.levels.sorted()
                    }
                    dispatchGroup.leave()
                })
            } else if level == "Category" {
                levels = financialTransactionsTopLevelCategories.sorted()
                dispatchGroup.enter()
                reference.child(userFinancialTransactionsTopLevelCategoriesEntity).child(currentUser).observeSingleEvent(of: .value, with: { snapshot in
                    if snapshot.exists(), let values = snapshot.value as? [String: String] {
                        let array = Array(values.values)
                        self.levels.append(contentsOf: array)
                        self.levels = self.levels.sorted()
                    }
                    dispatchGroup.leave()
                })
            } else if level == "Group" {
                levels = financialTransactionsGroups.sorted()
                dispatchGroup.enter()
                reference.child(userFinancialTransactionsGroupsEntity).child(currentUser).observeSingleEvent(of: .value, with: { snapshot in
                    if snapshot.exists(), let values = snapshot.value as? [String: String] {
                        let array = Array(values.values)
                        self.levels.append(contentsOf: array)
                        self.levels = self.levels.sorted()
                    }
                    dispatchGroup.leave()
                })
            }
            
            dispatchGroup.notify(queue: .main) {
                activityIndicatorView.stopAnimating()
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
        let newLevelBarButton = UIBarButtonItem(title: "New \(level)", style: .plain, target: self, action: #selector(newLevel))
        navigationItem.rightBarButtonItem = newLevelBarButton
    }
    
    @objc func newLevel(_ item:UIBarButtonItem) {
        let destination = FinanceTransactionNewLevelViewController()
        destination.level = level
        destination.delegate = self
        let navigationViewController = UINavigationController(rootViewController: destination)
        self.present(navigationViewController, animated: true, completion: nil)
    }
    
    fileprivate func initializeForm() {
        form +++ SelectableSection<ListCheckRow<String>>(level, selectionType: .singleSelection(enableDeselection: false))
        
        for level in levels {
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

extension FinanceTransactionLevelViewController: UpdateTransactionNewLevelDelegate {
    func update() {
        updateLevels()
    }
}
