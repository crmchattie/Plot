//
//  GroceryListViewController.swift
//  Plot
//
//  Created by Cory McHattie on 5/7/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import UIKit
import Eureka
import SplitRow

protocol UpdateGrocerylistDelegate: class {
    func updateGrocerylist(grocerylist: Grocerylist)
}

class GrocerylistViewController: FormViewController {
    weak var delegate : UpdateGrocerylistDelegate?
          
    var grocerylist: Grocerylist!

    fileprivate var active: Bool = false
    fileprivate var ingredientIndex: Int = 0
              
    override func viewDidLoad() {
    super.viewDidLoad()
      
      configureTableView()
      
      if grocerylist != nil {
          active = true
          self.navigationItem.rightBarButtonItem?.isEnabled = true
      } else {
          grocerylist = Grocerylist(dictionary: ["name" : "Grocery List" as AnyObject])
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
        navigationItem.title = "Grocery List"
    }

    @objc fileprivate func cancelChecklist() {
      self.navigationController?.popViewController(animated: true)
    }

    @objc fileprivate func closeChecklist() {
      delegate?.updateGrocerylist(grocerylist: grocerylist)
      self.navigationController?.popViewController(animated: true)
      
    }

    func initializeForm() {
        form +++
        Section()
            
        <<< TextRow("Grocery List") {
            $0.cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
            $0.cell.textField?.textColor = ThemeManager.currentTheme().generalTitleColor
            $0.placeholderColor = ThemeManager.currentTheme().generalSubtitleColor
            $0.placeholder = $0.tag
            if active, let grocerylist = grocerylist {
                $0.value = grocerylist.name
                self.navigationItem.title = $0.value
            } else {
                $0.cell.textField.becomeFirstResponder()
            }
            }.onChange() { [unowned self] row in
                if let rowValue = row.value {
                    self.grocerylist.name = rowValue
                }
                if row.value == nil {
                    self.navigationItem.rightBarButtonItem?.isEnabled = false
                } else {
                    self.navigationItem.title = row.value
                    self.navigationItem.rightBarButtonItem?.isEnabled = true
                }
            }.cellUpdate { cell, row in
                cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                cell.textField?.textColor = ThemeManager.currentTheme().generalTitleColor
                row.placeholderColor = ThemeManager.currentTheme().generalSubtitleColor
            }
        
        form +++
            MultivaluedSection(multivaluedOptions: [.Insert, .Delete, .Reorder]) {
                $0.tag = "grocerylistfields"
                $0.addButtonProvider = { section in
                    return ButtonRow(){
                        $0.cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                        $0.title = "Add New Ingredient"
                        }.cellUpdate { cell, row in
                            cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                            cell.textLabel?.textAlignment = .left
                            
                    }
                }
                $0.multivaluedRowToInsertAt = { index in
                    return SplitRow<ButtonRow, CheckRow>(){
                        $0.rowLeftPercentage = 0.75
                        $0.rowLeft = ButtonRow(){ row in
                            row.cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                            row.cell.textLabel?.textAlignment = .left
                            row.cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                            }.onCellSelection({ _,_ in
                                self.ingredientIndex = index
                                self.openIngredient()
                            }).cellUpdate { cell, row in
                                cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                                cell.textLabel?.textAlignment = .left
                            }
                        
                        $0.rowRight = CheckRow() {
                            $0.cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                            $0.cell.tintColor = FalconPalette.defaultBlue
                            $0.value = false
                            $0.cell.accessoryType = .checkmark
                            $0.cell.tintAdjustmentMode = .dimmed
                            }.cellUpdate { cell, row in
                                cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                                cell.tintColor = FalconPalette.defaultBlue
                                if row.value == false {
                                    cell.accessoryType = .checkmark
                                    cell.tintAdjustmentMode = .dimmed
                                } else {
                                    cell.tintAdjustmentMode = .automatic
                                }
                                self.grocerylist.ingredients![row.indexPath!.row].bool = row.value
                        }
                        }.cellUpdate { cell, row in
                            cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                        }
                    
                }
                
            }
            
            if let items = self.grocerylist.ingredients {
                for item in items {
                    var mvs = (form.sectionBy(tag: "checklistfields") as! MultivaluedSection)
                    mvs.insert(SplitRow<ButtonRow, CheckRow>(){
                    $0.rowLeftPercentage = 0.75
                    $0.rowLeft = ButtonRow(){ row in
                        row.cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                        row.cell.textLabel?.textAlignment = .left
                        row.cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                        row.title = "\(item.measures?.us?.amount ?? 0.0) \(item.measures?.us?.unitShort ?? "") of \(item.name?.capitalized ?? "")"
                        }.onCellSelection({ cell, row in
                            self.ingredientIndex = row.indexPath!.row
                            self.openIngredient()
                        }).cellUpdate { cell, row in
                            cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                            cell.textLabel?.textAlignment = .left
                        }
                    
                    $0.rowRight = CheckRow() {
                        $0.cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                        $0.cell.tintColor = FalconPalette.defaultBlue
                        $0.value = item.bool
                        $0.value = false
                        $0.cell.accessoryType = .checkmark
                        $0.cell.tintAdjustmentMode = .dimmed
                        }.cellUpdate { cell, row in
                            cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                            cell.tintColor = FalconPalette.defaultBlue
                            if row.value == false {
                                cell.accessoryType = .checkmark
                                cell.tintAdjustmentMode = .dimmed
                            } else {
                                cell.tintAdjustmentMode = .automatic
                            }
                            self.grocerylist.ingredients![row.indexPath!.row].bool = row.value
                        }
                        }.cellUpdate { cell, row in
                            cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                        } , at: mvs.count - 1)
                }
            }
        }
    
    fileprivate func openIngredient() {
        if let items = self.grocerylist.ingredients, items.indices.contains(ingredientIndex) {
            let ingredient = items[ingredientIndex]
            let destination = IngredientDetailViewController()
            destination.ingredient = ingredient
            self.navigationController?.pushViewController(destination, animated: true)
        } else {
            let destination = IngredientDetailViewController()
            self.navigationController?.pushViewController(destination, animated: true)
        }
    }
        
    override func rowsHaveBeenRemoved(_ rows: [BaseRow], at indexes: [IndexPath]) {
        super.rowsHaveBeenRemoved(rows, at: indexes)
        let rowNumber : Int = indexes.first!.row
        
        DispatchQueue.main.async { [weak self] in
            self!.grocerylist.ingredients!.remove(at: rowNumber)
        }
    }
}
