//
//  FinanceCollectionViewMemberCell.swift
//  Plot
//
//  Created by Cory McHattie on 10/5/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import UIKit

class FinanceCollectionViewMemberCell: UICollectionViewCell {
    
    var member: MXMember! {
        didSet {
            nameLabel.text = member.name
            if let imageURL = imageURL {
                companyImageView.sd_setImage(with: URL(string: imageURL))
            }
            let status = member.connection_status
            if status == .connected {
                statusImageView.image =  UIImage(named: "success")
                infoLabel.text = "Information is up-to-date"
            } else if status == .created || status == .updated || status == .delayed || status == .resumed || status == .pending {
                statusImageView.image =  UIImage(named: "updating")
                infoLabel.text = "Information is updating"
            } else {
                statusImageView.image =  UIImage(named: "failure")
                infoLabel.text = "Please click to fix connection"
            }
            setupViews()
        }
    }
    
    var imageURL: String!
    
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
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupViews() {
        backgroundColor = .clear
        backgroundView = UIView()
        addSubview(backgroundView!)
        backgroundView?.fillSuperview()
        backgroundView?.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor

        backgroundView?.roundCorners(corners: [.allCorners], radius: 10)
        backgroundView?.layer.shadowOpacity = 0.1
        backgroundView?.layer.shadowRadius = 10
        backgroundView?.layer.shadowOffset = .init(width: 0, height: 10)
        
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
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
    }
 
}
