//
//  MealExpandedDetailViewController.swift
//  Plot
//
//  Created by Cory McHattie on 3/7/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import UIKit

class MealExpandedDetailViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout {
    
    private let kMealDetailViewCell = "MealDetailViewCell"
    
    var recipe: Recipe? {
        didSet {
            fetchData()
        }
    }
    var segment: Int = 0
    
    var ingredients = [ExtendedIngredient]()
    var instructions = String()
    var equipment = [String]()
    
    init() {
        super.init(collectionViewLayout: UICollectionViewFlowLayout())
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
        collectionView.indicatorStyle = ThemeManager.currentTheme().scrollBarStyle
        collectionView.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
        
        collectionView.register(MealDetailViewCell.self, forCellWithReuseIdentifier: kMealDetailViewCell)
                                                
    }
    
    func fetchData() {
        if let recipe = recipe {
            if let extendedIngredients = recipe.extendedIngredients {
                self.ingredients = extendedIngredients
            }
            if let analyzedInstructions = recipe.analyzedInstructions {
                for instruction in analyzedInstructions {
                    for step in instruction.steps! {
                        for equipment in step.equipment! {
                            if !self.equipment.contains(equipment.name ?? "") {
                                self.equipment.append(equipment.name ?? "")
                            }
                        }
                    }
                }
            }
            if let recipeInstructions = recipe.instructions {
                instructions = recipeInstructions
                instructions = instructions.replacingOccurrences(of: "<ol>", with: "")
                instructions = instructions.replacingOccurrences(of: "</ol>", with: "")
                instructions = instructions.replacingOccurrences(of: "<li>", with: "")
                instructions = instructions.replacingOccurrences(of: "</li>", with: "")
                instructions = instructions.replacingOccurrences(of: ".", with: ". ")
            }
            collectionView.reloadData()
        }
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return ThemeManager.currentTheme().statusBarStyle
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if segment == 0 {
            return ingredients.count
        } else if segment == 1 {
            return equipment.count
        } else {
            return 1
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: kMealDetailViewCell, for: indexPath) as! MealDetailViewCell
        if segment == 0 {
            cell.titleLabel.text = ingredients[indexPath.item].name!.capitalized
            cell.instructionsLabel.text = nil
        } else if segment == 1 {
            cell.titleLabel.text = equipment[indexPath.item].capitalized
            cell.instructionsLabel.text = nil
        } else {
            cell.instructionsLabel.text = instructions
            cell.titleLabel.text = nil
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return .init(top: 0, left: 0, bottom: 0, right: 0)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
            return CGSize(width: view.frame.width, height: 30)
    }

}
