//
//  IngredientDetailViewController.swift
//  Plot
//
//  Created by Cory McHattie on 5/8/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import UIKit
import Eureka
import ViewRow

class IngredientDetailViewController: FormViewController {
    weak var delegate : UpdateFoodProductContainerDelegate?
          
    var ingredient: ExtendedIngredient!
    
    var searchController = ""
    
    var timer: Timer?

    var active: Bool = false
    fileprivate var movingBackwards: Bool = true
    
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
        calcNutrition()
      
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if self.movingBackwards && active {
            let foodProductContainer = FoodProductContainer(groceryProduct: nil, menuProduct: nil, recipeProduct: nil, complexIngredient: ingredient, basicIngredient: nil)
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
        navigationItem.title = "Ingredient"
        navigationOptions = .Disabled
    }

    @objc fileprivate func close() {
        movingBackwards = false
        if active {
            let foodProductContainer = FoodProductContainer(groceryProduct: nil, menuProduct: nil, recipeProduct: nil, complexIngredient: ingredient, basicIngredient: nil)
            delegate?.updateFoodProductContainer(foodProductContainer: foodProductContainer, close: true)
            self.navigationController?.popViewController(animated: true)
        } else if searchController == "MealSearch" {
            if ingredient.recipe == nil {
                ingredient.recipe = ["No Recipe": ingredient.amount ?? 0.0]
            }
            let foodProductContainer = FoodProductContainer(groceryProduct: nil, menuProduct: nil, recipeProduct: nil, complexIngredient: ingredient, basicIngredient: nil)
            delegate?.updateFoodProductContainer(foodProductContainer: foodProductContainer, close: true)
            self.navigationController?.backToViewController(viewController: MealViewController.self)
        } else if searchController == "GroceryListSearch" {
            if ingredient.recipe == nil {
                ingredient.recipe = ["No Recipe": ingredient.amount ?? 0.0]
            }
            let foodProductContainer = FoodProductContainer(groceryProduct: nil, menuProduct: nil, recipeProduct: nil, complexIngredient: ingredient, basicIngredient: nil)
            delegate?.updateFoodProductContainer(foodProductContainer: foodProductContainer, close: true)
            self.navigationController?.backToViewController(viewController: GrocerylistViewController.self)
        }
    }

    func initializeForm() {
        form +++
        Section()
            
//        <<< ViewRow<UIImageView>("Ingredient Image")
//            .cellSetup { (cell, row) in
//                cell.backgroundColor = .secondarySystemGroupedBackground
//
//                //  Make the image view occupy the entire row:
//                cell.viewRightMargin = 0.0
//                cell.viewLeftMargin = 0.0
//                cell.viewTopMargin = 0.0
//                cell.viewBottomMargin = 0.0
//
//                cell.height = { return CGFloat(100) }
//
////                    //  Construct the view for the cell
//                cell.view = UIImageView()
//                cell.view!.contentMode = .scaleAspectFit
//                cell.view!.clipsToBounds = true
//                cell.contentView.addSubview(cell.view!)
//
//                if let ingredientImage = self.ingredient.image {
//                    cell.view!.sd_setImage(with: URL(string: "https://spoonacular.com/cdn/ingredients_250x250/\(ingredientImage)"))
//                }
//            }
            
        <<< LabelRow("Name") {
            $0.cell.backgroundColor = .secondarySystemGroupedBackground
            $0.cell.textLabel?.textColor = .label
            $0.cell.detailTextLabel?.textColor = .secondaryLabel
            $0.title = $0.tag
            if let ingredient = ingredient {
                $0.value = ingredient.name?.capitalized
            }
            }.onChange() { [unowned self] row in
                if row.value == nil {
                    self.navigationItem.rightBarButtonItem?.isEnabled = false
                } else {
                    self.navigationItem.rightBarButtonItem?.isEnabled = true
                }
            }.cellUpdate { cell, _ in
                cell.backgroundColor = .secondarySystemGroupedBackground
                cell.textLabel?.textColor = .label
            }
        
        <<< DecimalRow("Amount") {
            $0.cell.backgroundColor = .secondarySystemGroupedBackground
            $0.cell.textLabel?.textColor = .label
            $0.cell.textField.textColor = .secondaryLabel
            $0.formatter = DecimalFormatter()
            $0.useFormatterDuringInput = true
            $0.title = $0.tag
            if let ingredient = ingredient {
                $0.value = ingredient.amount ?? 0.0
            }
            }.cellSetup { cell, _  in
                cell.textField.keyboardType = .numberPad
            }.cellUpdate { cell, _ in
                cell.backgroundColor = .secondarySystemGroupedBackground
                cell.textLabel?.textColor = .label
                cell.textField.textColor = .secondaryLabel
            }.onChange() { [unowned self] row in
                if self.ingredient.recipe == nil {
                    self.ingredient.recipe = ["No Recipe": self.ingredient.amount ?? 0.0]
                } else if self.ingredient.recipe!.count == 1, self.ingredient.recipe!["No Recipe"] != nil {
                    self.ingredient.recipe!["No Recipe"] = row.value
                } else if (row.value ?? 0.0) - (self.ingredient.amount ?? 0.0) > 0 {
                    var values: Double = 0.0
                    for (key, value) in self.ingredient.recipe! {
                        if key != "No recipe" {
                            values += value
                        }
                    }
                    if (row.value ?? 0.0) - values > 0 {
                        self.ingredient.recipe!["No Recipe"] = (row.value ?? 0.0) - values
                    } else {
                        self.ingredient.recipe!["No Recipe"] = nil
                    }
                }
                self.ingredient.amount = row.value
                
                self.fetchProductInfo(ingredientID: self.ingredient.id!, amount: self.ingredient.amount, unit: self.ingredient.unit)
                
//                timer?.invalidate()
//
//                timer = Timer.scheduledTimer(withTimeInterval: 2, repeats: false, block: { (_) in
//
//                })
            }
        
        if active, let ingredient = ingredient, let recipe = self.ingredient.recipe, recipe["No Recipe"] == nil {
            form.last!
            <<< LabelRow("Unit") {
                $0.cell.backgroundColor = .secondarySystemGroupedBackground
                $0.cell.textLabel?.textColor = .label
                $0.cell.detailTextLabel?.textColor = .secondaryLabel
                $0.title = $0.tag
                $0.value = "\(ingredient.unit?.capitalized ?? "G")"
                }.cellUpdate { cell, _ in
                    cell.backgroundColor = .secondarySystemGroupedBackground
                    cell.textLabel?.textColor = .label
                }
        } else {
            form.last!
            <<< ActionSheetRow<String>("Unit") { row in
                row.cell.backgroundColor = .secondarySystemGroupedBackground
                row.cell.textLabel?.textColor = .label
                row.cell.detailTextLabel?.textColor = .secondaryLabel
                row.title = row.tag
                row.selectorTitle = "Choose Ingredient Units"
                row.value = "\(ingredient.unit ?? "g")"
                row.options = []
                ingredient.possibleUnits?.sorted().forEach {
                    row.options?.append($0.capitalized)
                }
                }.onPresent { from, to in
                    to.popoverPresentationController?.permittedArrowDirections = .up
                }.onChange() { [unowned self] row in
                    row.updateCell()
                    self.ingredient.unit = row.value
                    if let id = self.ingredient.id {
                        self.fetchProductInfo(ingredientID: id, amount: self.ingredient.amount, unit: self.ingredient.unit)
                    }
//                    timer?.invalidate()
//                    timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: false, block: { (_) in
//
//                    })
                }
        }
        
        form.last!
        <<< LabelRow("Aisle") {
            $0.cell.backgroundColor = .secondarySystemGroupedBackground
            $0.cell.textLabel?.textColor = .label
            $0.cell.detailTextLabel?.textColor = .secondaryLabel
            $0.title = $0.tag
            if let ingredient = ingredient {
                $0.value = "\(ingredient.aisle ?? "")"
            }
            }.cellUpdate { cell, _ in
                cell.backgroundColor = .secondarySystemGroupedBackground
                cell.textLabel?.textColor = .label
            }
        
        form +++
        Section("Recipes"){
            if self.active, let _ = self.ingredient.recipe {
                $0.hidden = false
            } else {
                $0.hidden = true
            }
        }
        
        //add in recipe & recipe's amount
        if active, let recipe = ingredient.recipe {
            for (recipe, amount) in recipe {
                form.last!
                <<< LabelRow() {
                    $0.cell.backgroundColor = .secondarySystemGroupedBackground
                    $0.cell.textLabel?.textColor = .label
                    $0.cell.detailTextLabel?.textColor = .secondaryLabel
                    $0.title = recipe.capitalized
                    $0.value = "\(amount) \(ingredient.unit ?? "")"
                    }.cellUpdate { cell, _ in
                        cell.backgroundColor = .secondarySystemGroupedBackground
                        cell.textLabel?.textColor = .label
                    }
            }
        }
    }
    
    fileprivate func calcNutrition() {
        if let section = self.form.sectionBy(tag: "Nutrition") {
            if form.allSections.count > 1 {
                for _ in 0...form.allSections.count - 2 - section.index! {
                    form.remove(at: section.index!)
                }
            }
        }
        
        if let nutrition = ingredient.nutrition, nutrition.nutrients != nil {
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
    
    func fetchProductInfo(ingredientID: Int, amount: Double?, unit: String?) {
        Service.shared.fetchIngredientInfo(id: ingredientID, amount: amount, unit: unit) { (search, err) in
            self.ingredient = search
            DispatchQueue.main.async { [weak self] in
                self!.calcNutrition()
            }
        }
    }
}
