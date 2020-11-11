//
//  MenuProductDetailViewController.swift
//  Plot
//
//  Created by Cory McHattie on 10/26/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import UIKit
import Eureka

class MenuProductDetailViewController: FormViewController {
    weak var delegate : UpdateFoodProductContainerDelegate?
    
    var product: MenuProduct!
    
    var timer: Timer?
    
    var searchController = ""
    
    var active: Bool = false
    fileprivate var movingBackwards: Bool = true
    
    let numberFormatter = NumberFormatter()
              
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
            let foodProductContainer = FoodProductContainer(groceryProduct: nil, menuProduct: product, recipeProduct: nil, complexIngredient: nil, basicIngredient: nil)
            delegate?.updateFoodProductContainer(foodProductContainer: foodProductContainer, close: false)
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

        let plusBarButton =  UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(close))
        navigationItem.rightBarButtonItem = plusBarButton
        extendedLayoutIncludesOpaqueBars = true
        edgesForExtendedLayout = UIRectEdge.top
        tableView.separatorStyle = .none
        definesPresentationContext = true
        navigationItem.title = "Restaurant Item"
    }

    @objc fileprivate func close() {
        movingBackwards = false
        if active {
            let foodProductContainer = FoodProductContainer(groceryProduct: nil, menuProduct: product, recipeProduct: nil, complexIngredient: nil, basicIngredient: nil)
            delegate?.updateFoodProductContainer(foodProductContainer: foodProductContainer, close: false)
            self.navigationController?.popViewController(animated: true)
        } else if searchController == "MealSearch" {
            let foodProductContainer = FoodProductContainer(groceryProduct: nil, menuProduct: product, recipeProduct: nil, complexIngredient: nil, basicIngredient: nil)
            delegate?.updateFoodProductContainer(foodProductContainer: foodProductContainer, close: false)
            self.navigationController?.backToViewController(viewController: MealViewController.self)
        } else if searchController == "GroceryListSearch" {
            let foodProductContainer = FoodProductContainer(groceryProduct: nil, menuProduct: product, recipeProduct: nil, complexIngredient: nil, basicIngredient: nil)
            delegate?.updateFoodProductContainer(foodProductContainer: foodProductContainer, close: false)
            self.navigationController?.backToViewController(viewController: GrocerylistViewController.self)
        }
    }

    func initializeForm() {
        form +++
        Section()
            
        <<< LabelRow("Name") {
            $0.cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
            $0.cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
            $0.cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
            $0.title = $0.tag
            $0.value = product.title.capitalized
            }.cellUpdate { cell, _ in
                cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
            }
        
        if let restaurantChain = product.restaurantChain, restaurantChain != "" {
            form.last!
            <<< LabelRow("Restaurant") {
                $0.cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                $0.cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                $0.cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
                $0.title = $0.tag
                $0.value = restaurantChain.capitalized
                }.cellUpdate { cell, _ in
                    cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                    cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                }
        }
        
        form.last!
        <<< DecimalRow("Amount") {
            $0.cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
            $0.cell.textField?.textColor = ThemeManager.currentTheme().generalTitleColor
            $0.title = $0.tag
            $0.formatter = numberFormatter
            $0.value = product.amount
        }.cellUpdate { cell, row in
            cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
            cell.textField?.textColor = ThemeManager.currentTheme().generalTitleColor
        }.onChange { _ in
            self.timer?.invalidate()
            
            self.timer = Timer.scheduledTimer(withTimeInterval: 2, repeats: false, block: { (_) in
                self.calcNutrition()
            })
        }
        
        if let servingSize = product.servingSize {
            form.last!
            <<< LabelRow("Servings") {
                $0.cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                $0.cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                $0.cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
                $0.title = $0.tag
                $0.value = "\(servingSize)"
                }.cellUpdate { cell, _ in
                    cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                    cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                }
        }
    }
    
    fileprivate func calcNutrition() {
        if let nutrition = product.nutrition, let nutrients = nutrition.nutrients, !nutrients.isEmpty, let amount = product.amount, amount != 1 {
            for index in 0...nutrients.count - 1 {
                product.nutrition!.nutrients![index].amount! += nutrients[index].amount! * amount
                product.nutrition!.nutrients![index].percentOfDailyNeeds! += nutrients[index].percentOfDailyNeeds! * amount
            }
        }
        
        if let section = self.form.sectionBy(tag: "Nutrition") {
            if form.allSections.count > 1 {
                for _ in 0...form.allSections.count - 2 - section.index! {
                    form.remove(at: section.index!)
                }
            }
        }

        if let nutrition = product.nutrition, nutrition.nutrients != nil {
            form +++
            Section(header: "Nutrition", footer: nil) {
                $0.tag = "Nutrition"
            }
            
            var section = self.form.sectionBy(tag: "Nutrition")
            let nutrients = nutrition.nutrients!.sorted(by: { $0.title!.compare($1.title!, options: .caseInsensitive) == .orderedAscending })
            for nutrient in nutrients {
                if let title = nutrient.title, let amount = nutrient.amount, let unit = nutrient.unit, amount > 0 {
                    section!.insert(LabelRow() {
                    $0.cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                    $0.cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                    $0.cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
                    $0.title = "\(title.capitalized)"
                    $0.value = "\(String(format: "%.2f", amount)) \(unit.capitalized)"
                    }.cellUpdate { cell, _ in
                        cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                        cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                    }, at: section!.count)
                }
            }
        }
    }
}
