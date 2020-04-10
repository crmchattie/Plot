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
    
    var segment: Int = 0
    
    var ingredients: [ExtendedIngredient]?
    var instructions: String?
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
        } else {
            return 1
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: kMealDetailViewCell, for: indexPath) as! MealDetailViewCell
        if segment == 0, let ingredients = ingredients {
            self.activityIndicatorView.stopAnimating()
            cell.titleLabel.text = ingredients[indexPath.item].original!.capitalized
            cell.instructionsLabel.text = nil
        } else if segment == 1, let equipment = equipment {
            self.activityIndicatorView.stopAnimating()
            cell.titleLabel.text = equipment[indexPath.item].capitalized
            cell.instructionsLabel.text = nil
        } else if let instructions = instructions {
            self.activityIndicatorView.stopAnimating()
            cell.instructionsLabel.text = instructions
            cell.titleLabel.text = nil
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return .init(top: 5, left: 0, bottom: 5, right: 0)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        var height: CGFloat = 30
        if segment == 0, let ingredients = ingredients {
            height = estimateFrameForText(width: view.frame.width - 30, text: ingredients[indexPath.item].original!.capitalized, font: UIFont.preferredFont(forTextStyle: .body)).height
        } else if segment == 1, let equipment = equipment {
            height = estimateFrameForText(width: view.frame.width - 30, text: equipment[indexPath.item].capitalized, font: UIFont.preferredFont(forTextStyle: .body)).height
        } else if let instructions = instructions {
            height = estimateFrameForText(width: view.frame.width - 30, text: instructions, font: UIFont.preferredFont(forTextStyle: .callout)).height
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
