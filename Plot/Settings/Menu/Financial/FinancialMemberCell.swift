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
        label.textColor = .label
        label.font = UIFont.preferredFont(forTextStyle: .body)
        label.numberOfLines = 1
        label.adjustsFontForContentSizeCategory = true
        return label
    }()
    
    let infoLabel: UILabel = {
        let label = UILabel()
        label.textColor = .secondaryLabel
        label.font = UIFont.preferredFont(forTextStyle: .callout)
        label.numberOfLines = 1
        label.adjustsFontForContentSizeCategory = true
        return label
    }()
    
    let companyImageView = UIImageView(cornerRadius: 8)
    let statusImageView = UIImageView(cornerRadius: 8)
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .default, reuseIdentifier: reuseIdentifier)
        statusImageView.constrainWidth(30)
        statusImageView.constrainHeight(30)
        
        let labelStack = VerticalStackView(arrangedSubviews: [nameLabel, infoLabel], spacing: 2)
        
        let stackView = UIStackView(arrangedSubviews: [labelStack, UIView(), statusImageView])
        stackView.spacing = 10
        stackView.alignment = .center
        addSubview(stackView)
        stackView.fillSuperview(padding: .init(top: 10, left: 15, bottom: 10, right: 15))

    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
    }
 
}
