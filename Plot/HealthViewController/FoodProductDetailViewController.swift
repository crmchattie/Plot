//
//  FoodProductDetailViewController.swift
//  Plot
//
//  Created by Cory McHattie on 11/1/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import UIKit
import Eureka

protocol UpdateFoodProductDelegate: class {
    func updateFoodProduct(foodProduct: NutrientSearch, close: Bool?)
}

class FoodProductDetailViewController: FormViewController {
    weak var delegate : UpdateFoodProductDelegate?
    
    var product: NutrientSearch!
    var food: Food!
    
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
        navigationItem.title = "Food Item"
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
            if let food = food {
                $0.value = food.label?.capitalized
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
            
        
//        if let number_of_servings = product.number_of_servings, let serving_size = product.serving_size {
//            form.last!
//            <<< LabelRow("Servings") {
//                $0.cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
//                $0.cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
//                $0.cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
//                $0.title = $0.tag
//                $0.value = "\(number_of_servings) servings per \(serving_size)"
//                }.cellUpdate { cell, _ in
//                    cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
//                    cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
//                }
//        }
        
        if let nutrition = product.totalNutrients {
            print("nutrition")
            var values = Array(nutrition.values)
            print("values \(values)")
            values = values.sorted(by: { $0.label?.compare($1.label ?? "", options: .caseInsensitive) == .orderedAscending })
            for value in values {
                print("value \(value.label)")
                if let label = value.label, let quantity = value.quantity, let unit = value.unit, quantity > 0 {
                    form.last!
                    <<< LabelRow("\(label.capitalized)") {
                        $0.cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                        $0.cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                        $0.cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
                        $0.title = "\(label.capitalized)"
                        $0.value = "\(quantity) \(unit)"
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
