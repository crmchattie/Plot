//
//  FinancialAccountCell.swift
//  Plot
//
//  Created by Cory McHattie on 9/1/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import UIKit

class FinancialAccountCell: UITableViewCell {
    let nameLabel: UILabel = {
        let label = UILabel()
        label.textColor = .label
        label.font = UIFont.preferredFont(forTextStyle: .body)
        label.numberOfLines = 1
        label.adjustsFontForContentSizeCategory = true
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
        stackView.fillSuperview(padding: .init(top: 10, left: 10, bottom: 10, right: 10))

    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        nameLabel.text = nil
        
    }
 
}
