//
//  ActivityHeaderCell.swift
//  Plot
//
//  Created by Cory McHattie on 1/28/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import UIKit

class ActivityHeaderCell: UICollectionViewCell {
    
    let nameLabel: UILabel = {
        let label = UILabel()
        label.textColor = ThemeManager.currentTheme().generalTitleColor
        label.text = "Standard"
        label.font = UIFont.systemFont(ofSize: 18)
        return label
    }()
    
    let imageView = UIImageView(cornerRadius: 8)
    
    override init(frame: CGRect) {
        super.init(frame: frame)
                
        let stackView = VerticalStackView(arrangedSubviews: [
            imageView
            ], spacing: 5)
        addSubview(stackView)
        stackView.fillSuperview(padding: .init(top: 16, left: 0, bottom: 0, right: 0))
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
}
