//
//  ActivityHeader.swift
//  Plot
//
//  Created by Cory McHattie on 1/28/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import UIKit

class ActivityHeader: UICollectionReusableView {
    
    let activityHeaderHorizontalController = ActivityHeaderHorizontalController()
    
    let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Build Your Own"
        label.textColor = ThemeManager.currentTheme().generalTitleColor
        label.font = .boldSystemFont(ofSize: 30)
        label.isUserInteractionEnabled = true
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubview(titleLabel)
        addSubview(activityHeaderHorizontalController.view)
        titleLabel.anchor(top: topAnchor, leading: leadingAnchor, bottom: nil, trailing: trailingAnchor, padding: .init(top: 0, left: 16, bottom: 0, right: 0))
        activityHeaderHorizontalController.view.anchor(top: titleLabel.bottomAnchor, leading: leadingAnchor, bottom: bottomAnchor, trailing: trailingAnchor)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
