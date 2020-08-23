//
//  FinancialMemberCell.swift
//  Plot
//
//  Created by Cory McHattie on 8/22/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import UIKit

class FinancialMemberCell: UITableViewCell {
    let nameLabel: UILabel = {
        let label = UILabel()
        label.textColor = ThemeManager.currentTheme().generalTitleColor
        label.font = UIFont.preferredFont(forTextStyle: .body)
        label.numberOfLines = 1
        return label
    }()
    
    let companyImageView = UIImageView(cornerRadius: 8)
    let statusImageView = UIImageView(cornerRadius: 8)
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .default, reuseIdentifier: reuseIdentifier)
        companyImageView.constrainWidth(60)
        companyImageView.constrainHeight(60)
        
        statusImageView.constrainWidth(20)
        statusImageView.constrainHeight(20)
        
        let stackView = UIStackView(arrangedSubviews: [companyImageView, nameLabel, UIView(), statusImageView])
        stackView.spacing = 10
        stackView.alignment = .center
        addSubview(stackView)
        stackView.fillSuperview(padding: .init(top: 10, left: 20, bottom: 10, right: 20))

    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        nameLabel.text = nil
        companyImageView.image = nil
        companyImageView.sd_cancelCurrentImageLoad()
        statusImageView.image = nil
        statusImageView.sd_cancelCurrentImageLoad()
        
    }
}
