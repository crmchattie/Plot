//
//  MealDetailCell.swift
//  Plot
//
//  Created by Cory McHattie on 3/7/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import UIKit

class MealDetailCell: UICollectionViewCell {
        
    var segmentedControl: UISegmentedControl!
    
    let ingredientsText = NSLocalizedString("Ingredients", comment: "")
    let equipmentText = NSLocalizedString("Equipment", comment: "")
    let instructionsText = NSLocalizedString("Instructions", comment: "")
        
    let mealExpandedDetailViewController = MealExpandedDetailViewController()
        
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupViews() {
        
        let segmentTextContent = [
            ingredientsText,
            equipmentText,
            instructionsText
        ]
        
        segmentedControl = UISegmentedControl(items: segmentTextContent)
        if #available(iOS 13.0, *) {
            segmentedControl.overrideUserInterfaceStyle = ThemeManager.currentTheme().userInterfaceStyle
        } else {
            // Fallback on earlier versions
        }
        
        segmentedControl.selectedSegmentIndex = 0
        segmentedControl.autoresizingMask = .flexibleWidth
        segmentedControl.addTarget(self, action: #selector(action(_:)), for: .valueChanged)
        
        segmentedControl.constrainHeight(constant: 30)
        
        addSubview(segmentedControl)
        addSubview(mealExpandedDetailViewController.view)
        
        segmentedControl.anchor(top: topAnchor, leading: leadingAnchor, bottom: nil, trailing: trailingAnchor)
        mealExpandedDetailViewController.view.anchor(top: segmentedControl.bottomAnchor, leading: leadingAnchor, bottom: bottomAnchor, trailing: trailingAnchor, padding: .init(top: 10, left: 0, bottom: 0, right: 0))
        
        
    }
    
    @IBAction func action(_ sender: UISegmentedControl) {
        if sender.selectedSegmentIndex == 0 {
            mealExpandedDetailViewController.segment = 0
        } else if sender.selectedSegmentIndex == 1 {
            mealExpandedDetailViewController.segment = 1
        } else {
            mealExpandedDetailViewController.segment = 2
        }
        mealExpandedDetailViewController.collectionView.reloadData()
    }
}
