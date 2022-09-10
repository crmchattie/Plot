//
//  CalendarAccountView.swift
//  Plot
//
//  Created by Cory McHattie on 2/9/21.
//  Copyright © 2021 Immature Creations. All rights reserved.
//

import UIKit

class CalendarAccountView: UIView {
    let nameLabel: UILabel = {
        let label = UILabel()
        label.textColor = ThemeManager.currentTheme().generalTitleColor
        label.font = UIFont.preferredFont(forTextStyle: .body)
        label.numberOfLines = 1
        label.adjustsFontForContentSizeCategory = true
        return label
    }()
    
//    let infoLabel: UILabel = {
//        let label = UILabel()
//        label.textColor = ThemeManager.currentTheme().generalSubtitleColor
//        label.font = UIFont.preferredFont(forTextStyle: .callout)
//        label.numberOfLines = 1
//        label.adjustsFontForContentSizeCategory = true
//        return label
//    }()
    
    let accountImageView = UIImageView(cornerRadius: 8)
    let statusImageView = UIImageView(cornerRadius: 8)
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
//        let backgroundView = UIView()
//        addSubview(backgroundView)
//        backgroundView.fillSuperview()
//        backgroundView.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
//
//        backgroundView.roundCorners(corners: [.topLeft, .topRight], radius: 10)
        
        accountImageView.constrainWidth(40)
        accountImageView.constrainHeight(40)
        
        statusImageView.constrainWidth(25)
        statusImageView.constrainHeight(25)
        
//        let labelStack = VerticalStackView(arrangedSubviews: [nameLabel], spacing: 0)
        
        let stackView = UIStackView(arrangedSubviews: [accountImageView, nameLabel, UIView(), statusImageView])
        stackView.spacing = 10
        stackView.alignment = .center
        addSubview(stackView)
        stackView.fillSuperview(padding: .init(top: 5, left: 10, bottom: 5, right: 10))

    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
    }
 
}
