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
                imageView.isHidden = true
                
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
                imageView.isHidden = true
                
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
    
    var transaction: Transaction! {
        didSet {
            if let transaction = transaction {
                let numberFormatter = NumberFormatter()
                numberFormatter.currencyCode = "USD"
                numberFormatter.numberStyle = .currency
                
                let isodateFormatter = ISO8601DateFormatter()
                let dateFormatterPrint = DateFormatter()
                dateFormatterPrint.dateFormat = "EEEE, MMM d, yyyy"
                
                categoryLabel.isHidden = true
                
                nameLabel.text = transaction.description
                if let amount = numberFormatter.string(from: transaction.amount as NSNumber) {
                    middleLabel.text = "Amount: \(amount)"
                }
                if let date = isodateFormatter.date(from: transaction.transacted_at) {
                    bottomLabel.text = "Transacted On: \(dateFormatterPrint.string(from: date))"
                }
                imageView.isHidden = !(transaction.should_link ?? true)
                imageView.image = UIImage(systemName: "checkmark")
                imageView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(weight: .bold)
                setupViews()
            }
        }
    }
    
    var account: MXAccount! {
        didSet {
            if let account = account {
                let numberFormatter = NumberFormatter()
                numberFormatter.currencyCode = "USD"
                numberFormatter.numberStyle = .currency
                
                let isodateFormatter = ISO8601DateFormatter()
                let dateFormatterPrint = DateFormatter()
                dateFormatterPrint.dateFormat = "MMM dd, yyyy"
                
                categoryLabel.isHidden = true
                
                nameLabel.text = account.name
                if let balance = numberFormatter.string(from: account.balance as NSNumber) {
                    middleLabel.text = "Balance: \(balance)"
                }
                if let date = isodateFormatter.date(from: account.updated_at) {
                    bottomLabel.text = "Last Updated On: \(dateFormatterPrint.string(from: date))"
                }
                imageView.isHidden = !(account.should_link ?? true)
                imageView.image = UIImage(systemName: "checkmark")
                imageView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(weight: .bold)
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

        let stackView = UIStackView(arrangedSubviews: [labelStackView, UIView(), imageView, categoryLabel])
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
        
        nameLabel.font = UIFont.preferredFont(forTextStyle: .body)
        categoryLabel.font = UIFont.preferredFont(forTextStyle: .body)
        middleLabel.font = UIFont.preferredFont(forTextStyle: .body)
        bottomLabel.font = UIFont.preferredFont(forTextStyle: .body)
        
        categoryLabel.isHidden = false
        middleLabel.isHidden = false
        bottomLabel.isHidden = false
        imageView.isHidden = false
    }
    
}
