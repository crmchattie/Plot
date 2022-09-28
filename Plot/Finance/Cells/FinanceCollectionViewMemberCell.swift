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
        label.textColor = .label
        label.font = UIFont.preferredFont(forTextStyle: .headline)
        label.numberOfLines = 1
        label.adjustsFontForContentSizeCategory = true
        return label
    }()
    
    let infoLabel: UILabel = {
        let label = UILabel()
        label.textColor = .secondaryLabel
        label.font = UIFont.preferredFont(forTextStyle: .subheadline)
        label.numberOfLines = 1
        label.adjustsFontForContentSizeCategory = true
        return label
    }()
    
    let companyImageView: UIImageView = {
        let imageView = UIImageView(cornerRadius: 8)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    let statusImageView: UIImageView = {
        let imageView = UIImageView(cornerRadius: 8)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
        
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var isHighlighted: Bool {
        didSet {
            self.backgroundView?.backgroundColor = .secondarySystemGroupedBackground.withAlphaComponent(isHighlighted ? 0.7 : 1)
        }
    }
    
    func setupViews() {
        backgroundColor = .clear
        backgroundView = UIView()
        addSubview(backgroundView!)
        backgroundView?.fillSuperview()
        backgroundView?.backgroundColor = .secondarySystemGroupedBackground

        backgroundView?.roundCorners(corners: [.allCorners], radius: 10)
        
        statusImageView.constrainWidth(30)
        statusImageView.constrainHeight(30)
        
        let labelStack = VerticalStackView(arrangedSubviews: [nameLabel, infoLabel], spacing: 2)
        
        let stackView = UIStackView(arrangedSubviews: [labelStack, UIView(), statusImageView])
        stackView.spacing = 10
        stackView.alignment = .center
        addSubview(stackView)
        stackView.fillSuperview(padding: .init(top: 10, left: 10, bottom: 10, right: 10))

    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        nameLabel.textColor = .label
    }
 
}
