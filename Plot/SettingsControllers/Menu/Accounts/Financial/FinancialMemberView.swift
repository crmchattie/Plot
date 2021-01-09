//
//  FinancialMemberCell.swift
//  Plot
//
//  Created by Cory McHattie on 8/22/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import UIKit

class FinancialMemberView: UIView {
    let nameLabel: UILabel = {
        let label = UILabel()
        label.textColor = ThemeManager.currentTheme().generalTitleColor
        label.font = UIFont.preferredFont(forTextStyle: .body)
        label.numberOfLines = 1
        return label
    }()
    
    let infoLabel: UILabel = {
        let label = UILabel()
        label.textColor = ThemeManager.currentTheme().generalSubtitleColor
        label.font = UIFont.preferredFont(forTextStyle: .callout)
        label.numberOfLines = 1
        return label
    }()
    
    let companyImageView = UIImageView(cornerRadius: 8)
    let statusImageView = UIImageView(cornerRadius: 8)
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        companyImageView.constrainWidth(60)
        companyImageView.constrainHeight(60)
        
        statusImageView.constrainWidth(30)
        statusImageView.constrainHeight(30)
        
        let labelStack = VerticalStackView(arrangedSubviews: [nameLabel, infoLabel], spacing: 2)
        
        let stackView = UIStackView(arrangedSubviews: [companyImageView, labelStack, UIView(), statusImageView])
        stackView.spacing = 10
        stackView.alignment = .center
        addSubview(stackView)
        stackView.fillSuperview(padding: .init(top: 10, left: 10, bottom: 10, right: 10))

    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
    }
 
}
