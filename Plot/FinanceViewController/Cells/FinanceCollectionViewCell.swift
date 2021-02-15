//
//  FinanceCell.swift
//  Plot
//
//  Created by Cory McHattie on 9/8/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import Foundation

class FinanceCollectionViewCell: UICollectionViewCell {
    
    var mode: Mode = .fullscreen
    
    var transactionDetails: TransactionDetails! {
        didSet {
            if let transactionDetails = transactionDetails {
                accountDetails = nil
                transaction = nil
                account = nil
                holding = nil
                
                let numberFormatter = NumberFormatter()
                numberFormatter.currencyCode = transactionDetails.currencyCode ?? "USD"
                numberFormatter.numberStyle = .currency
                numberFormatter.maximumFractionDigits = 0
                
                subcategoryLabel.isHidden = true
                middleLabel.isHidden = true
                bottomLabel.isHidden = true
                imageView.isHidden = true
                
                nameLabel.text = transactionDetails.name

                switch transactionDetails.level {
                case .category:
                    topHeightConstraint = 5
                    nameLabel.font = UIFont.preferredFont(forTextStyle: .subheadline)
                    nameLabel.textColor = ThemeManager.currentTheme().generalSubtitleColor
                    categoryLabel.font = UIFont.preferredFont(forTextStyle: .subheadline)
                    categoryLabel.textColor = ThemeManager.currentTheme().generalSubtitleColor
                    
                    if transactionDetails.group == "Income", let amount = numberFormatter.string(from: transactionDetails.amount as NSNumber) {
                        categoryLabel.text = "\(amount)"
                    } else if let amount = numberFormatter.string(from: transactionDetails.amount * -1 as NSNumber) {
                        categoryLabel.text = "\(amount)"
                    }
                case .top:
                    nameLabel.font = UIFont.preferredFont(forTextStyle: .callout)
                    categoryLabel.font = UIFont.preferredFont(forTextStyle: .callout)
                    
                    if transactionDetails.group == "Income", let amount = numberFormatter.string(from: transactionDetails.amount as NSNumber) {
                        categoryLabel.text = "\(amount)"
                        topHeightConstraint = 20

                    } else if let amount = numberFormatter.string(from: transactionDetails.amount * -1 as NSNumber) {
                        categoryLabel.text = "\(amount)"
                        topHeightConstraint = 5

                    }
                case .group:
                    if mode == .fullscreen {
                        topHeightConstraint = 20
                    } else {
                        topHeightConstraint = 5
                    }
                    
                    if (transactionDetails.group == "Income" || transactionDetails.group == "Expense" || transactionDetails.group == "Difference") {
                        nameLabel.font = UIFont.preferredFont(forTextStyle: .headline)
                        categoryLabel.font = UIFont.preferredFont(forTextStyle: .headline)
                    } else {
                        nameLabel.font = UIFont.preferredFont(forTextStyle: .body)
                        categoryLabel.font = UIFont.preferredFont(forTextStyle: .body)
                    }
                    
                    if (transactionDetails.group == "Income" || transactionDetails.group == "Difference"), let amount = numberFormatter.string(from: transactionDetails.amount as NSNumber) {
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
                transactionDetails = nil
                transaction = nil
                account = nil
                holding = nil
                
                let numberFormatter = NumberFormatter()
                numberFormatter.currencyCode = accountDetails.currencyCode ?? "USD"
                numberFormatter.numberStyle = .currency
                numberFormatter.maximumFractionDigits = 0
                
                subcategoryLabel.isHidden = true
                middleLabel.isHidden = true
                bottomLabel.isHidden = true
                imageView.isHidden = true
                
                nameLabel.text = accountDetails.name
                
                switch accountDetails.level {
                case .account:
                    topHeightConstraint = 5
                    nameLabel.font = UIFont.preferredFont(forTextStyle: .subheadline)
                    nameLabel.textColor = ThemeManager.currentTheme().generalSubtitleColor
                    categoryLabel.font = UIFont.preferredFont(forTextStyle: .subheadline)
                    categoryLabel.textColor = ThemeManager.currentTheme().generalSubtitleColor
                    
                    if let amount = numberFormatter.string(from: accountDetails.balance as NSNumber) {
                        categoryLabel.text = "\(amount)"
                    }
                case .subtype:
                    topHeightConstraint = 5
                    nameLabel.font = UIFont.preferredFont(forTextStyle: .callout)
                    categoryLabel.font = UIFont.preferredFont(forTextStyle: .callout)
                    
                    if let amount = numberFormatter.string(from: accountDetails.balance as NSNumber) {
                        categoryLabel.text = "\(amount)"
                    }
                case .type:
                    topHeightConstraint = 20
                    nameLabel.font = UIFont.preferredFont(forTextStyle: .body)
                    categoryLabel.font = UIFont.preferredFont(forTextStyle: .body)
                    
                    if let amount = numberFormatter.string(from: accountDetails.balance as NSNumber) {
                        categoryLabel.text = "\(amount)"
                    }
                case .bs_type:
                    if mode == .fullscreen {
                        topHeightConstraint = 20
                    } else {
                        topHeightConstraint = 5
                    }
                    
                    nameLabel.font = UIFont.preferredFont(forTextStyle: .headline)
                    categoryLabel.font = UIFont.preferredFont(forTextStyle: .headline)
                    
                    if let amount = numberFormatter.string(from: accountDetails.balance as NSNumber) {
                        categoryLabel.text = "\(amount)"
                    }
                }
                setupViews()
            }
        }
    }
    
    var holding: MXHolding! {
        didSet {
            if let holding = holding {
                transactionDetails = nil
                accountDetails = nil
                transaction = nil
                account = nil
                
                let numberFormatter = NumberFormatter()
                numberFormatter.currencyCode = holding.currency_code ?? "USD"
                numberFormatter.numberStyle = .currency
                numberFormatter.maximumFractionDigits = 0
                
                nameLabel.text = holding.symbol ?? holding.description
                                      
                if mode == .small {
                    subcategoryLabel.isHidden = true
                    middleLabel.isHidden = true
                    bottomLabel.isHidden = true
                    imageView.isHidden = true

                    nameLabel.font = UIFont.preferredFont(forTextStyle: .headline)
                    categoryLabel.font = UIFont.preferredFont(forTextStyle: .headline)

                    topHeightConstraint = 5
                                                    
                    if let marketValue = holding.market_value, let amount = numberFormatter.string(from: marketValue as NSNumber) {
                        categoryLabel.text = "\(amount)"
                    }
                    
//                    if let marketValue = holding.market_value, let costBasis = holding.cost_basis, costBasis != 0 {
//                        let percentFormatter = NumberFormatter()
//                        percentFormatter.numberStyle = .percent
//                        percentFormatter.positivePrefix = percentFormatter.plusSign
//                        percentFormatter.maximumFractionDigits = 0
//                        percentFormatter.minimumFractionDigits = 0
//
//                        let percent = marketValue / costBasis - 1
//                        if percent < 0 {
//                            subcategoryLabel.textColor = .systemRed
//                        } else {
//                            subcategoryLabel.textColor = .systemGreen
//                        }
//                        if let percentText = percentFormatter.string(from: NSNumber(value: percent)) {
//                            subcategoryLabel.isHidden = false
//                            subcategoryLabel.text = percentText
//                        }
//                    }
                } else {
                    let isodateFormatter = ISO8601DateFormatter()
                    let dateFormatterPrint = DateFormatter()
                    dateFormatterPrint.dateFormat = "E, MMM d, yyyy"
                    
                    categoryLabel.isHidden = true
                    subcategoryLabel.isHidden = true
                    topHeightConstraint = 10
                    
                    if let marketValue = holding.market_value, let amount = numberFormatter.string(from: marketValue as NSNumber), let costBasis = holding.cost_basis, costBasis != 0 {
                        let percentFormatter = NumberFormatter()
                        percentFormatter.numberStyle = .percent
                        percentFormatter.positivePrefix = percentFormatter.plusSign
                        percentFormatter.maximumFractionDigits = 0
                        percentFormatter.minimumFractionDigits = 0
                        
                        let percent = marketValue / costBasis - 1
                        if let percentText = percentFormatter.string(from: NSNumber(value: percent)) {
                            let fullText = "Market Value: \(amount) (\(percentText))"
                            if percent < 0 {
                                let attributedText = fullText.setColor(.systemRed, ofSubstring: "(\(percentText))")
                                middleLabel.attributedText = attributedText
                            } else {
                                let attributedText = fullText.setColor(.systemGreen, ofSubstring: "(\(percentText))")
                                middleLabel.attributedText = attributedText
                            }
                        }
                    } else if let marketValue = holding.market_value, let amount = numberFormatter.string(from: marketValue as NSNumber) {
                        middleLabel.text = "Market Value: \(amount)"
                    }
                    if let date = isodateFormatter.date(from: holding.updated_at) {
                        bottomLabel.text = "Last Updated: \(dateFormatterPrint.string(from: date))"
                    }
                    imageView.isHidden = !(holding.should_link ?? true)
                    imageView.image = UIImage(systemName: "checkmark")
                    imageView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(weight: .bold)
                }
                
                setupViews()
            }
        }
    }
    
    var transaction: Transaction! {
        didSet {
            if let transaction = transaction {
                transactionDetails = nil
                accountDetails = nil
                account = nil
                holding = nil
                
                let numberFormatter = NumberFormatter()
                numberFormatter.currencyCode = transaction.currency_code
                numberFormatter.numberStyle = .currency
                numberFormatter.maximumFractionDigits = 0
                
                let isodateFormatter = ISO8601DateFormatter()
                let dateFormatterPrint = DateFormatter()
                dateFormatterPrint.dateFormat = "E, MMM d, yyyy"
                
                categoryLabel.isHidden = true
                subcategoryLabel.isHidden = true
                topHeightConstraint = 10
                                
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
                transactionDetails = nil
                accountDetails = nil
                transaction = nil
                
                let numberFormatter = NumberFormatter()
                numberFormatter.currencyCode = account.currency_code
                numberFormatter.numberStyle = .currency
                numberFormatter.maximumFractionDigits = 0
                
                let isodateFormatter = ISO8601DateFormatter()
                let dateFormatterPrint = DateFormatter()
                dateFormatterPrint.dateFormat = "E, MMM d, yyyy"
                
                categoryLabel.isHidden = true
                subcategoryLabel.isHidden = true
                topHeightConstraint = 10
                                
                nameLabel.text = account.name
                let currentBalance = account.available_balance ?? account.balance
                if let balance = numberFormatter.string(from: currentBalance as NSNumber) {
                    middleLabel.text = "Balance: \(balance)"
                }
                if let date = isodateFormatter.date(from: account.updated_at) {
                    bottomLabel.text = "Last Updated: \(dateFormatterPrint.string(from: date))"
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
    
    let subcategoryLabel: UILabel = {
        let label = UILabel()
        label.textColor = ThemeManager.currentTheme().generalSubtitleColor
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
    
    var topHeightConstraint = CGFloat()
    var bottomHeightConstraint: CGFloat = 0
    var firstPosition: Bool = false
    var lastPosition: Bool = false
        
    func setupViews() {
        backgroundColor = .clear
        backgroundView = UIView()
        addSubview(backgroundView!)
        backgroundView?.fillSuperview()
        backgroundView?.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor

        if firstPosition && lastPosition {
            topHeightConstraint = 10
            bottomHeightConstraint = 10
            backgroundView?.roundCorners(corners: [.allCorners], radius: 10)
            backgroundView?.layer.shadowOpacity = 0.1
            backgroundView?.layer.shadowRadius = 10
            backgroundView?.layer.shadowOffset = .init(width: 0, height: 10)
        } else if firstPosition {
            topHeightConstraint = 10
            backgroundView?.roundCorners(corners: [.topLeft, .topRight], radius: 10)
        } else if lastPosition {
            bottomHeightConstraint = 10
            backgroundView?.roundCorners(corners: [.bottomLeft, .bottomRight], radius: 10)
            backgroundView?.layer.shadowOpacity = 0.1
            backgroundView?.layer.shadowRadius = 10
            backgroundView?.layer.shadowOffset = .init(width: 0, height: 10)
        }
        
        let verticalStackView = VerticalStackView(arrangedSubviews: [nameLabel, middleLabel, bottomLabel], spacing: 2)

        let stackView = UIStackView(arrangedSubviews: [verticalStackView, UIView(), imageView, subcategoryLabel, categoryLabel])
        stackView.spacing = 2
        stackView.alignment = .center
        stackView.distribution = .fill

        addSubview(stackView)
        stackView.fillSuperview(padding: .init(top: topHeightConstraint, left: 10, bottom: bottomHeightConstraint, right: 10))
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        topHeightConstraint = CGFloat()
        bottomHeightConstraint = 0
        firstPosition = false
        lastPosition = false
        
        nameLabel.text = nil
        categoryLabel.text = nil
        subcategoryLabel.text = nil
        middleLabel.text = nil
        bottomLabel.text = nil
                
        nameLabel.textColor = ThemeManager.currentTheme().generalTitleColor
        categoryLabel.textColor = ThemeManager.currentTheme().generalTitleColor
        subcategoryLabel.textColor = ThemeManager.currentTheme().generalSubtitleColor
        middleLabel.textColor = ThemeManager.currentTheme().generalSubtitleColor
        bottomLabel.textColor = ThemeManager.currentTheme().generalSubtitleColor
        
        nameLabel.font = UIFont.preferredFont(forTextStyle: .body)
        categoryLabel.font = UIFont.preferredFont(forTextStyle: .body)
        subcategoryLabel.font = UIFont.preferredFont(forTextStyle: .subheadline)
        middleLabel.font = UIFont.preferredFont(forTextStyle: .body)
        bottomLabel.font = UIFont.preferredFont(forTextStyle: .body)
        
        categoryLabel.isHidden = false
        subcategoryLabel.isHidden = false
        middleLabel.isHidden = false
        bottomLabel.isHidden = false
        imageView.isHidden = false
        
    }
    
}
