//
//  GroceryProductDetailViewController.swift
//  Plot
//
//  Created by Cory McHattie on 10/26/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import UIKit
import Eureka

protocol UpdateGroceryProductDelegate: class {
    func updateGroceryProduct(groceryProduct: GroceryProduct, close: Bool?)
}

class GroceryProductDetailViewController: FormViewController {
    weak var delegate : UpdateGroceryProductDelegate?
    
    var product: GroceryProduct!
    
    var active: Bool = false
    fileprivate var movingBackwards: Bool = true
              
    override func viewDidLoad() {
        super.viewDidLoad()

        configureTableView()

        initializeForm()
        
        for row in form.rows {
            row.baseCell.isUserInteractionEnabled = false
        }
      
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if self.movingBackwards && active {
            
        }
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return ThemeManager.currentTheme().statusBarStyle
    }

    fileprivate func configureTableView() {
        tableView.allowsMultipleSelectionDuringEditing = false
        view.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
        tableView.indicatorStyle = ThemeManager.currentTheme().scrollBarStyle
        tableView.backgroundColor = view.backgroundColor

        let rightBarButton = UIButton(type: .system)
        if active {
            rightBarButton.setTitle("Update", for: .normal)
        } else {
            rightBarButton.setTitle("Add", for: .normal)
        }
        rightBarButton.titleLabel?.font = UIFont.preferredFont(forTextStyle: .body)
        rightBarButton.titleLabel?.adjustsFontForContentSizeCategory = true
        rightBarButton.addTarget(self, action: #selector(close), for: .touchUpInside)

        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: rightBarButton)
        extendedLayoutIncludesOpaqueBars = true
        edgesForExtendedLayout = UIRectEdge.top
        tableView.separatorStyle = .none
        definesPresentationContext = true
        navigationItem.title = "Grocery Item"
    }

    @objc fileprivate func close() {
        movingBackwards = false
        
    }

    func initializeForm() {
        form +++
        Section()
            
        <<< LabelRow("Name") {
            $0.cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
            $0.cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
            $0.cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
            $0.title = $0.tag
            if let product = product {
                $0.value = product.title.capitalized
            }
            }.onChange() { [unowned self] row in
                if row.value == nil {
                    self.navigationItem.rightBarButtonItem?.isEnabled = false
                } else {
                    self.navigationItem.rightBarButtonItem?.isEnabled = true
                }
            }.cellUpdate { cell, _ in
                cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
            }
            
        
        if let number_of_servings = product.number_of_servings, let serving_size = product.serving_size {
            form.last!
            <<< LabelRow("Servings") {
                $0.cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                $0.cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                $0.cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
                $0.title = $0.tag
                $0.value = "\(number_of_servings) servings per \(serving_size)"
                }.cellUpdate { cell, _ in
                    cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                    cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                }
        }
        
        if let nutrition = product.nutrition, nutrition.nutrients != nil {
            let nutrients = nutrition.nutrients!.sorted(by: { $0.title!.compare($1.title!, options: .caseInsensitive) == .orderedAscending })
            for value in nutrients {
                if let title = value.title, let amount = value.amount, let unit = value.unit, amount > 0 {
                    form.last!
                    <<< LabelRow("\(title.capitalized)") {
                        $0.cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                        $0.cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                        $0.cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
                        $0.title = "\(title.capitalized)"
                        $0.value = "\(amount) \(unit)"
                        }.onChange() { [unowned self] row in
                            if row.value == nil {
                                self.navigationItem.rightBarButtonItem?.isEnabled = false
                            } else {
                                self.navigationItem.rightBarButtonItem?.isEnabled = true
                            }
                        }.cellUpdate { cell, _ in
                            cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                            cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                        }
                }
            }
            
        }
    }
    
}

