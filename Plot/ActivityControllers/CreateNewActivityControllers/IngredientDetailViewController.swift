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

protocol UpdateIngredientDelegate: class {
    func updateIngredient(ingredient: ExtendedIngredient)
}

class IngredientDetailViewController: FormViewController {
    weak var delegate : UpdateIngredientDelegate?
          
    var ingredient: ExtendedIngredient!

    var active: Bool = false
    fileprivate var movingBackwards: Bool = true
              
    override func viewDidLoad() {
        super.viewDidLoad()

        configureTableView()

        if ingredient != nil {
            active = true
            self.navigationItem.rightBarButtonItem?.isEnabled = true
        } else {
            
        }

        initializeForm()
      
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if self.movingBackwards {
            delegate?.updateIngredient(ingredient: ingredient)
        }
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
        navigationItem.title = "Ingredient"
    }

    @objc fileprivate func close() {
        movingBackwards = false
        delegate?.updateIngredient(ingredient: ingredient)
        self.navigationController?.popViewController(animated: true)
      
    }

    func initializeForm() {
        form +++
        Section()
            
//        <<< ViewRow<UIImageView>("Ingredient Image")
//            .cellSetup { (cell, row) in
//                cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
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
        
        <<< DecimalRow("Total Amount") {
            $0.cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
            $0.cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
            $0.cell.textField.textColor = ThemeManager.currentTheme().generalSubtitleColor
            $0.formatter = DecimalFormatter()
            $0.useFormatterDuringInput = true
            $0.title = $0.tag
            if active, let ingredient = ingredient {
                $0.value = ingredient.measures?.us?.amount ?? 0.0
            }
            }.cellSetup { cell, _  in
                cell.textField.keyboardType = .numberPad
            }.cellUpdate { cell, _ in
                cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                cell.textField.textColor = ThemeManager.currentTheme().generalSubtitleColor
            }.onChange() { [unowned self] row in
                self.ingredient.amount = row.value
            }
        
        <<< LabelRow("Unit") {
            $0.cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
            $0.cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
            $0.cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
            $0.title = $0.tag
            if active, let ingredient = ingredient {
                $0.value = "\(ingredient.measures?.us?.unitShort ?? "")"
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
        
        //add in recipe & recipe's amount
        if active, let recipe = ingredient.recipe {
            for (recipe, amount) in recipe {
                Section("Recipes")
                <<< LabelRow() {
                    $0.cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                    $0.cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                    $0.cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
                    $0.title = recipe.capitalized
                    $0.value = "\(amount)"
                    }.cellUpdate { cell, _ in
                        cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                        cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                    }
            }
        }
        
    }
    
    fileprivate func searchIngredients() {
        
    }
}
