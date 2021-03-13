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

protocol UpdateActivityCategoryDelegate: class {
    func update(value: String)
}

class ActivityCategoryViewController: FormViewController {
    weak var delegate : UpdateActivityCategoryDelegate?
    
    var categories = [String]()
    
    var oldValue = String()
    var value = String()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(activityIndicatorView)
        activityIndicatorView.centerInSuperview()
        activityIndicatorView.startAnimating()
        configureTableView()
        oldValue = value
    }
    
    override func viewDidAppear(_ animated: Bool) {
        updateCategories()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        if value != oldValue {
            self.delegate?.update(value: value)
        }
    }
    
    fileprivate func updateCategories() {
        form.removeAll()
        if let currentUser = Auth.auth().currentUser?.uid {
            categories = activityCategories.sorted()
            Database.database().reference().child(userActivityCategoriesEntity).child(currentUser).observeSingleEvent(of: .value, with: { snapshot in
                if snapshot.exists(), let values = snapshot.value as? [String: String] {
                    let array = Array(values.values)
                    self.categories.append(contentsOf: array)
                    self.categories = self.categories.sorted()
                }
                DispatchQueue.main.async {
                    activityIndicatorView.stopAnimating()
                    self.initializeForm()
                }
            })
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
        
        let barButton = UIBarButtonItem(title: "New Category", style: .plain, target: self, action: #selector(newCategory))
        navigationItem.rightBarButtonItem = barButton
    }
    
    @objc func newCategory(_ item:UIBarButtonItem) {
        let destination = NewActivityCategoryViewController()
        let navigationViewController = UINavigationController(rootViewController: destination)
        navigationViewController.modalPresentationStyle = .fullScreen
        self.present(navigationViewController, animated: true, completion: nil)
    }
    
    fileprivate func initializeForm() {
        form +++ SelectableSection<ListCheckRow<String>>("Category", selectionType: .singleSelection(enableDeselection: false))
        
        for title in categories {
            form.last!
                <<< ListCheckRow<String>() {
                    $0.cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
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
                    cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
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
