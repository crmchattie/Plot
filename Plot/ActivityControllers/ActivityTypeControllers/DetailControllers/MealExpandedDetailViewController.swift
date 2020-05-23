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
    private let kInstructionsDetailCell = "InstructionsDetailCell"
    
    var segment: Int = 0
    
    var ingredients: [ExtendedIngredient]?
    var instructions: [String]?
    var equipment: [String]?
    
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
        collectionView.register(InstructionsDetailCell.self, forCellWithReuseIdentifier: kInstructionsDetailCell)
        
        view.addSubview(activityIndicatorView)
        activityIndicatorView.centerInSuperview()
                                                
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return ThemeManager.currentTheme().statusBarStyle
    }
    
    let activityIndicatorView: UIActivityIndicatorView = {
        let aiv = UIActivityIndicatorView(style: .whiteLarge)
        aiv.color = .darkGray
        aiv.startAnimating()
        aiv.hidesWhenStopped = true
        return aiv
    }()
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if segment == 0, let ingredients = ingredients {
            return ingredients.count
        } else if segment == 1, let equipment = equipment {
            return equipment.count
        } else if segment == 2, let instructions = instructions {
            return instructions.count
        } else {
            return 1
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if segment == 0, let ingredients = ingredients {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: kMealDetailViewCell, for: indexPath) as! MealDetailViewCell
            self.activityIndicatorView.stopAnimating()
            cell.titleLabel.text = "\(ingredients[indexPath.item].measures?.us?.amount ?? 0.0) \(ingredients[indexPath.item].measures?.us?.unitShort ?? "") of \(ingredients[indexPath.item].name?.capitalized ?? "")"
            return cell
        } else if segment == 1, let equipment = equipment {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: kMealDetailViewCell, for: indexPath) as! MealDetailViewCell
            self.activityIndicatorView.stopAnimating()
            cell.titleLabel.text = equipment[indexPath.item].capitalized
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: kInstructionsDetailCell, for: indexPath) as! InstructionsDetailCell
            if let instructions = instructions {
                self.activityIndicatorView.stopAnimating()
                cell.instructionsLabel.text = instructions[indexPath.item]
                cell.numberLabel.text = "\(indexPath.item + 1)"
            }
            return cell
        }
        
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return .init(top: 5, left: 0, bottom: 5, right: 0)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        var height: CGFloat = 30
        if segment == 0, let ingredients = ingredients {
            let ingredient = "\(ingredients[indexPath.item].measures?.us?.amount ?? 0.0) \(ingredients[indexPath.item].measures?.us?.unitShort ?? "") of \(ingredients[indexPath.item].name?.capitalized ?? "")"
            height = estimateFrameForText(width: view.frame.width - 30, text: ingredient, font: UIFont.preferredFont(forTextStyle: .body)).height
        } else if segment == 1, let equipment = equipment {
            height = estimateFrameForText(width: view.frame.width - 30, text: equipment[indexPath.item].capitalized, font: UIFont.preferredFont(forTextStyle: .body)).height
        } else if let instructions = instructions {
            height = estimateFrameForText(width: view.frame.width - 57, text: instructions[indexPath.item], font: UIFont.preferredFont(forTextStyle: .callout)).height
            print("height \(height)")
        }
        return CGSize(width: view.frame.width, height: height)
    }
    
    func estimateFrameForText(width: CGFloat, text: String, font: UIFont) -> CGRect {
        let size = CGSize(width: width, height: 10000)
        let options = NSStringDrawingOptions.usesFontLeading.union(.usesLineFragmentOrigin)
        let attributes = [NSAttributedString.Key.font: font]
        return text.boundingRect(with: size, options: options, attributes: attributes, context: nil).integral
    }

}
