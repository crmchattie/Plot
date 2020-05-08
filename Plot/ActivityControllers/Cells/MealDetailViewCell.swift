//
//  MealDetailViewCell.swift
//  Plot
//
//  Created by Cory McHattie on 3/7/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import UIKit

class MealDetailViewCell: UICollectionViewCell {

    let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Activity Type"
        label.textColor = ThemeManager.currentTheme().generalTitleColor
        label.numberOfLines = 0
        label.font = UIFont.preferredFont(forTextStyle: .body)
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupViews() {
        
        addSubview(titleLabel)
        
        titleLabel.anchor(top: topAnchor, leading: leadingAnchor, bottom: nil, trailing: trailingAnchor, padding: .init(top: 2, left: 15, bottom: 0, right: 15))
     
    }
 
}
