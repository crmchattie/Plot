//
//  InstructionsDetailCell.swift
//  Plot
//
//  Created by Cory McHattie on 5/6/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import UIKit

class InstructionsDetailCell: UICollectionViewCell {

    let numberLabel: UILabel = {
        let label = UILabel()
        label.textColor = ThemeManager.currentTheme().generalTitleColor
        label.font = UIFont.preferredFont(forTextStyle: .callout)
        label.numberOfLines = 0
        return label
    }()

    let instructionsLabel: UILabel = {
        let label = UILabel()
        label.text = "Activity Type"
        label.textColor = ThemeManager.currentTheme().generalTitleColor
        label.numberOfLines = 0
        label.font = UIFont.preferredFont(forTextStyle: .callout)
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
        
        numberLabel.constrainWidth(25)
        
        let labelStackView = VerticalStackView(arrangedSubviews: [instructionsLabel], spacing: 2)
        labelStackView.layoutMargins = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        labelStackView.isLayoutMarginsRelativeArrangement = true
        
        let stackView = UIStackView(arrangedSubviews: [numberLabel, labelStackView])
        stackView.spacing = 2
        addSubview(stackView)
        stackView.fillSuperview(padding: .init(top: 0, left: 15, bottom: 0, right: 15))
     
    }
 
}
