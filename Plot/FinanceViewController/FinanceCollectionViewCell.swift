//
//  FinanceCell.swift
//  Plot
//
//  Created by Cory McHattie on 9/8/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import Foundation

class FinanceCollectionViewCell: UICollectionViewCell {
    
    var transactionDetails: TransactionDetails! {
        didSet {
            if let transactionDetails = transactionDetails {
                let numberFormatter = NumberFormatter()
                numberFormatter.currencyCode = "USD"
                numberFormatter.numberStyle = .currency
                
                middleLabel.isHidden = true
                bottomLabel.isHidden = true
                
                nameLabel.text = transactionDetails.name

                switch transactionDetails.level {
                case .category:
                    nameLabel.font = UIFont.preferredFont(forTextStyle: .subheadline)
                    categoryLabel.font = UIFont.preferredFont(forTextStyle: .subheadline)
                    
                    if transactionDetails.group == .income, let amount = numberFormatter.string(from: transactionDetails.amount as NSNumber) {
                        categoryLabel.text = "\(amount)"
                    } else if let amount = numberFormatter.string(from: transactionDetails.amount * -1 as NSNumber) {
                        categoryLabel.text = "\(amount)"
                    }
                case .top:
                    nameLabel.font = UIFont.preferredFont(forTextStyle: .body)
                    categoryLabel.font = UIFont.preferredFont(forTextStyle: .body)
                    
                    if transactionDetails.group == .income, let amount = numberFormatter.string(from: transactionDetails.amount as NSNumber) {
                        categoryLabel.text = "\(amount)"
                    } else if let amount = numberFormatter.string(from: transactionDetails.amount * -1 as NSNumber) {
                        categoryLabel.text = "\(amount)"
                    }
                case .group:
                    nameLabel.font = UIFont.preferredFont(forTextStyle: .title3)
                    categoryLabel.font = UIFont.preferredFont(forTextStyle: .title3)
                    
                    if (transactionDetails.group == .income || transactionDetails.group == .difference), let amount = numberFormatter.string(from: transactionDetails.amount as NSNumber) {
                        categoryLabel.text = "\(amount)"
                    } else if let amount = numberFormatter.string(from: transactionDetails.amount * -1 as NSNumber) {
                        categoryLabel.text = "\(amount)"
                    }
                }
                setupViews()
            }
        }
    }
    
    var accountDetails: AccountDetails! {
        didSet {
            if let accountDetails = accountDetails {
                let numberFormatter = NumberFormatter()
                numberFormatter.currencyCode = "USD"
                numberFormatter.numberStyle = .currency
                
                middleLabel.isHidden = true
                bottomLabel.isHidden = true
                
                nameLabel.text = accountDetails.name

                switch accountDetails.level {
                case .account:
                    nameLabel.font = UIFont.preferredFont(forTextStyle: .subheadline)
                    categoryLabel.font = UIFont.preferredFont(forTextStyle: .subheadline)
                    
                    if let amount = numberFormatter.string(from: accountDetails.balance as NSNumber) {
                        categoryLabel.text = "\(amount)"
                    }
                case .subtype:
                    nameLabel.font = UIFont.preferredFont(forTextStyle: .subheadline)
                    categoryLabel.font = UIFont.preferredFont(forTextStyle: .subheadline)
                    
                    if let amount = numberFormatter.string(from: accountDetails.balance as NSNumber) {
                        categoryLabel.text = "\(amount)"
                    }
                case .type:
                    nameLabel.font = UIFont.preferredFont(forTextStyle: .body)
                    categoryLabel.font = UIFont.preferredFont(forTextStyle: .body)
                    
                    if let amount = numberFormatter.string(from: accountDetails.balance as NSNumber) {
                        categoryLabel.text = "\(amount)"
                    }
                case .bs_type:
                    nameLabel.font = UIFont.preferredFont(forTextStyle: .title3)
                    categoryLabel.font = UIFont.preferredFont(forTextStyle: .title3)
                    
                    if let amount = numberFormatter.string(from: accountDetails.balance as NSNumber) {
                        categoryLabel.text = "\(amount)"
                    }
                }
                setupViews()
            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    let nameLabel: UILabel = {
        let label = UILabel()
        label.textColor = ThemeManager.currentTheme().generalTitleColor
        label.font = UIFont.preferredFont(forTextStyle: .body)
        label.numberOfLines = 0
        label.textAlignment = .left
        return label
    }()

    let categoryLabel: UILabel = {
        let label = UILabel()
        label.textColor = ThemeManager.currentTheme().generalTitleColor
        label.font = UIFont.preferredFont(forTextStyle: .body)
        label.numberOfLines = 0
        label.textAlignment = .right
        return label
    }()
    
    let middleLabel: UILabel = {
        let label = UILabel()
        label.textColor = ThemeManager.currentTheme().generalSubtitleColor
        label.font = UIFont.preferredFont(forTextStyle: .body)
        label.numberOfLines = 0
        return label
    }()
    
    let bottomLabel: UILabel = {
        let label = UILabel()
        label.textColor = ThemeManager.currentTheme().generalSubtitleColor
        label.font = UIFont.preferredFont(forTextStyle: .body)
        label.numberOfLines = 0
        return label
    }()
    
    let imageView = UIImageView(cornerRadius: 8)
        
    func setupViews() {
        let labelStackView = VerticalStackView(arrangedSubviews: [nameLabel, middleLabel, bottomLabel], spacing: 2)
        labelStackView.spacing = 2

        let stackView = UIStackView(arrangedSubviews: [labelStackView, UIView(), categoryLabel])
        stackView.spacing = 2
        stackView.alignment = .center
        stackView.distribution = .fill

        addSubview(stackView)
        stackView.fillSuperview()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        nameLabel.textColor = ThemeManager.currentTheme().generalTitleColor
        categoryLabel.textColor = ThemeManager.currentTheme().generalTitleColor
        middleLabel.textColor = ThemeManager.currentTheme().generalSubtitleColor
        bottomLabel.textColor = ThemeManager.currentTheme().generalSubtitleColor
    }
    
}
