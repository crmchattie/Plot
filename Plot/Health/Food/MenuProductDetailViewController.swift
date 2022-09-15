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
        
        configureTableView()

        initializeForm()
        
        for row in form.rows {
            if row.tag != "Amount" {
                row.baseCell.isUserInteractionEnabled = false
            }
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
        return .default
    }

    fileprivate func configureTableView() {
        tableView.allowsMultipleSelectionDuringEditing = false
        view.backgroundColor = .systemGroupedBackground
        tableView.indicatorStyle = .default
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
            $0.cell.backgroundColor = .secondarySystemGroupedBackground
            $0.cell.textLabel?.textColor = .label
            $0.cell.detailTextLabel?.textColor = .secondaryLabel
            $0.title = $0.tag
            if let product = product {
                $0.value = product.title.capitalized
            }
            }.cellUpdate { cell, _ in
                cell.backgroundColor = .secondarySystemGroupedBackground
                cell.textLabel?.textColor = .label
            }
        
        if let restaurantChain = product.restaurantChain, restaurantChain != "" {
            form.last!
            <<< LabelRow("Restaurant") {
                $0.cell.backgroundColor = .secondarySystemGroupedBackground
                $0.cell.textLabel?.textColor = .label
                $0.cell.detailTextLabel?.textColor = .secondaryLabel
                $0.title = $0.tag
                $0.value = restaurantChain.capitalized
                }.cellUpdate { cell, _ in
                    cell.backgroundColor = .secondarySystemGroupedBackground
                    cell.textLabel?.textColor = .label
                }
        }
        
        form.last!
        <<< DecimalRow("Amount") {
            $0.cell.backgroundColor = .secondarySystemGroupedBackground
            $0.cell.textField?.textColor = .secondaryLabel
            $0.title = $0.tag
            $0.formatter = numberFormatter
            if let product = product {
                $0.value = product.amount
            }
        }.cellUpdate { cell, row in
            cell.backgroundColor = .secondarySystemGroupedBackground
            cell.textField?.textColor = .secondaryLabel
        }.onChange { row in
            self.product.amount = row.value
            self.timer?.invalidate()
            
            self.timer = Timer.scheduledTimer(withTimeInterval: 2, repeats: false, block: { (_) in
                self.calcNutrition()
            })
        }
        
        if let product = product, let servingSize = product.servingSize {
            form.last!
            <<< LabelRow("Servings") {
                $0.cell.backgroundColor = .secondarySystemGroupedBackground
                $0.cell.textLabel?.textColor = .label
                $0.cell.detailTextLabel?.textColor = .secondaryLabel
                $0.title = $0.tag
                $0.value = "\(servingSize)"
                }.cellUpdate { cell, _ in
                    cell.backgroundColor = .secondarySystemGroupedBackground
                    cell.textLabel?.textColor = .label
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
            let nutrients = nutrition.nutrients!.sorted(by: { $0.name!.compare($1.name!, options: .caseInsensitive) == .orderedAscending })
            for nutrient in nutrients {
                if let title = nutrient.name, let amount = nutrient.amount, let unit = nutrient.unit, String(format: "%.0f", amount) != "0" {
                    section!.insert(LabelRow() {
                    $0.cell.backgroundColor = .secondarySystemGroupedBackground
                    $0.cell.textLabel?.textColor = .label
                    $0.cell.detailTextLabel?.textColor = .secondaryLabel
                    $0.title = "\(title.capitalized)"
                    $0.value = "\(String(format: "%.0f", amount)) \(unit.capitalized)"
                    }.cellUpdate { cell, _ in
                        cell.backgroundColor = .secondarySystemGroupedBackground
                        cell.textLabel?.textColor = .label
                    }, at: section!.count)
                }
            }
        }
    }
}
