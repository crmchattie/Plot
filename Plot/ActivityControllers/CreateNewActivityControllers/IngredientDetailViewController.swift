//
//  IngredientDetailViewController.swift
//  Plot
//
//  Created by Cory McHattie on 5/8/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import UIKit
import Eureka

protocol UpdateIngredientDelegate: class {
    func updateIngredient(ingredient: ExtendedIngredient)
}

class IngredientDetailViewController: FormViewController {
    weak var delegate : UpdateIngredientDelegate?
          
    var ingredient: ExtendedIngredient!

    fileprivate var active: Bool = false
              
    override func viewDidLoad() {
    super.viewDidLoad()
      
      configureTableView()
      
      if ingredient != nil {
          active = true
          self.navigationItem.rightBarButtonItem?.isEnabled = true
      }
      
      initializeForm()
      
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return ThemeManager.currentTheme().statusBarStyle
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        guard tableView.isEditing else { return }
        tableView.endEditing(true)
        tableView.reloadData()
    }

    fileprivate func configureTableView() {
        tableView.allowsMultipleSelectionDuringEditing = false
        view.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
        tableView.indicatorStyle = ThemeManager.currentTheme().scrollBarStyle
        tableView.backgroundColor = view.backgroundColor
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelChecklist))

        let rightBarButton = UIButton(type: .system)
        rightBarButton.setTitle("Update", for: .normal)
        rightBarButton.titleLabel?.font = UIFont.preferredFont(forTextStyle: .body)
        rightBarButton.titleLabel?.adjustsFontForContentSizeCategory = true
        rightBarButton.addTarget(self, action: #selector(closeChecklist), for: .touchUpInside)

        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: rightBarButton)
        extendedLayoutIncludesOpaqueBars = true
        edgesForExtendedLayout = UIRectEdge.top
        tableView.separatorStyle = .none
        definesPresentationContext = true
        navigationItem.title = "Ingredient"
    }

    @objc fileprivate func cancelChecklist() {
      self.navigationController?.popViewController(animated: true)
    }

    @objc fileprivate func closeChecklist() {
      delegate?.updateIngredient(ingredient: ingredient)
      self.navigationController?.popViewController(animated: true)
      
    }

    func initializeForm() {
        form +++
        Section()
            
        <<< LabelRow("Name") {
            $0.cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
            $0.cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
            $0.cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
            $0.title = $0.tag
            if active, let ingredient = ingredient {
                $0.value = ingredient.name?.capitalized
                self.navigationItem.title = $0.value
            }
            }.onChange() { [unowned self] row in
                if row.value == nil {
                    self.navigationItem.rightBarButtonItem?.isEnabled = false
                } else {
                    self.navigationItem.title = row.value
                    self.navigationItem.rightBarButtonItem?.isEnabled = true
                }
            }.cellUpdate { cell, _ in
                cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
            }.onCellSelection { _, _ in
                if !self.active {
                    self.searchIngredients()
                }
            }
        
        <<< LabelRow("Amount") {
            $0.cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
            $0.cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
            $0.cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
            $0.title = $0.tag
            if active, let ingredient = ingredient {
                $0.value = "\(ingredient.measures?.us?.amount ?? 0.0) \(ingredient.measures?.us?.unitShort ?? "")"
            }
            }.cellUpdate { cell, _ in
                cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
            }
        
        <<< LabelRow("Aisle") {
            $0.cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
            $0.cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
            $0.cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
            $0.title = $0.tag
            if active, let ingredient = ingredient {
                $0.value = "\(ingredient.aisle ?? "")"
            }
            }.cellUpdate { cell, _ in
                cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
            }
        
    }
    
    fileprivate func searchIngredients() {
        
    }
}
