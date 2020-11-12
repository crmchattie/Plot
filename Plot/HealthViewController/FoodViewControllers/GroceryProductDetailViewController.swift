//
//  GroceryProductDetailViewController.swift
//  Plot
//
//  Created by Cory McHattie on 10/26/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import UIKit
import Eureka

class GroceryProductDetailViewController: FormViewController {
    weak var delegate : UpdateFoodProductContainerDelegate?
    
    var product: GroceryProduct!
    
    var timer: Timer?
    
    var active: Bool = false
    fileprivate var movingBackwards: Bool = true
    
    var searchController = ""
    
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
            let foodProductContainer = FoodProductContainer(groceryProduct: product, menuProduct: nil, recipeProduct: nil, complexIngredient: nil, basicIngredient: nil)
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
        navigationItem.title = "Grocery Item"
    }

    @objc fileprivate func close() {
        movingBackwards = false
        if active {
            let foodProductContainer = FoodProductContainer(groceryProduct: product, menuProduct: nil, recipeProduct: nil, complexIngredient: nil, basicIngredient: nil)
            delegate?.updateFoodProductContainer(foodProductContainer: foodProductContainer, close: false)
            self.navigationController?.popViewController(animated: true)
        } else if searchController == "MealSearch" {
            let foodProductContainer = FoodProductContainer(groceryProduct: product, menuProduct: nil, recipeProduct: nil, complexIngredient: nil, basicIngredient: nil)
            delegate?.updateFoodProductContainer(foodProductContainer: foodProductContainer, close: false)
            self.navigationController?.backToViewController(viewController: MealViewController.self)
        } else if searchController == "GroceryListSearch" {
            let foodProductContainer = FoodProductContainer(groceryProduct: product, menuProduct: nil, recipeProduct: nil, complexIngredient: nil, basicIngredient: nil)
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
                if let title = nutrient.title, let amount = nutrient.amount, let unit = nutrient.unit, String(format: "%.0f", amount) != "0" {
                    section!.insert(LabelRow() {
                    $0.cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                    $0.cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                    $0.cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
                    $0.title = "\(title.capitalized)"
                        $0.value = "\(String(format: "%.0f", amount)) \(unit.capitalized)"
                    }.cellUpdate { cell, _ in
                        cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                        cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                    }, at: section!.count)
                }
            }
        }
    }
}

