//
//  ActivityCategoryViewController.swift
//  Plot
//
//  Created by Cory McHattie on 12/1/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import UIKit
import Eureka
import Firebase

protocol UpdateActivityLevelDelegate: AnyObject {
    func update(value: String, level: String)
}

class ActivityLevelViewController: FormViewController {
    weak var delegate : UpdateActivityLevelDelegate?
    var oldValue = String()
    var value = String()
    var level = String()
    var levels = [String]()
    
    init() {
        super.init(style: .insetGrouped)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = level
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
            if level == "Category" {
                levels = ActivityCategory.allCases.map({ $0.rawValue }).sorted()
                Database.database().reference().child(userActivityCategoriesEntity).child(currentUser).observeSingleEvent(of: .value, with: { snapshot in
                    if snapshot.exists(), let values = snapshot.value as? [String: String] {
                        let array = Array(values.values)
                        self.levels.append(contentsOf: array)
                        self.levels = self.levels.sorted()
                    }
                    DispatchQueue.main.async {
                        activityIndicatorView.stopAnimating()
                        self.initializeForm()
                    }
                })
            } else if level == "Subcategory" {
                levels = ActivitySubcategory.allCases.map({ $0.rawValue }).sorted()
                Database.database().reference().child(userActivityCategoriesEntity).child(currentUser).observeSingleEvent(of: .value, with: { snapshot in
                    if snapshot.exists(), let values = snapshot.value as? [String: String] {
                        let array = Array(values.values)
                        self.levels.append(contentsOf: array)
                        self.levels = self.levels.sorted()
                    }
                    DispatchQueue.main.async {
                        activityIndicatorView.stopAnimating()
                        self.initializeForm()
                    }
                })
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
        
//        let barButton = UIBarButtonItem(title: "New Category", style: .plain, target: self, action: #selector(newLevel))
//        navigationItem.rightBarButtonItem = barButton
    }
    
    @objc func newLevel(_ item:UIBarButtonItem) {
        let destination = ActivityNewLevelViewController()
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

extension ActivityLevelViewController: ActivityNewLevelDelegate {
    func update() {
        updateLevels()
    }
}
