//
//  FinanceCollectionViewComparisonCell.swift
//  Plot
//
//  Created by Cory McHattie on 10/11/22.
//  Copyright © 2022 Immature Creations. All rights reserved.
//

import Foundation
import UIKit

class FinanceCollectionViewComparisonCell: UICollectionViewCell {
        
    var transactionDetails: TransactionDetails! {
        didSet {
            if let transactionDetails = transactionDetails {
                accountDetails = nil
                holding = nil
                
                numberFormatter.currencyCode = transactionDetails.currencyCode ?? "USD"
                
                middleLeftLabel.isHidden = true
                bottomLeftLabel.isHidden = true
                
                nameLeftLabel.text = transactionDetails.name

                if transactionDetails.group == "Income", let amount = numberFormatter.string(from: transactionDetails.amount as NSNumber) {
                    nameRightLabel.text = amount
                    if let balance = transactionDetails.lastPeriodAmount, let amount = numberFormatter.string(from: balance as NSNumber), let difference = numberFormatter.string(from: transactionDetails.amount - balance as NSNumber) {
                        middleLeftLabel.isHidden = false
                        bottomLeftLabel.isHidden = false
                        middleRightLabel.isHidden = false
                        bottomRightLabel.isHidden = false
                        
                        switch selectedIndex {
                        case .day:
                            middleLeftLabel.text = "Yesterday"
                        case .week:
                            middleLeftLabel.text = "Last Week"
                        case .month:
                            middleLeftLabel.text = "Last Month"
                        case .year:
                            middleLeftLabel.text = "Last Year"
                        }
                        bottomLeftLabel.text = "Difference"
                        
                        middleRightLabel.text = amount
                        bottomRightLabel.text = difference
                    }
                } else if let amount = numberFormatter.string(from: transactionDetails.amount * -1 as NSNumber) {
                    nameRightLabel.text = amount
                    if let balance = transactionDetails.lastPeriodAmount, let lastPeriodAmount = numberFormatter.string(from: balance * -1 as NSNumber), let difference = numberFormatter.string(from: balance - transactionDetails.amount as NSNumber) {
                        middleLeftLabel.isHidden = false
                        bottomLeftLabel.isHidden = false
                        middleRightLabel.isHidden = false
                        bottomRightLabel.isHidden = false
                        
                        switch selectedIndex {
                        case .day:
                            middleLeftLabel.text = "Yesterday"
                        case .week:
                            middleLeftLabel.text = "Last Week"
                        case .month:
                            middleLeftLabel.text = "Last Month"
                        case .year:
                            middleLeftLabel.text = "Last Year"
                        }
                        bottomLeftLabel.text = "Difference"
                        
                        middleRightLabel.text = lastPeriodAmount
                        bottomRightLabel.text = difference
                    }
                } else {
                    middleLeftLabel.isHidden = true
                    bottomLeftLabel.isHidden = true
                    middleRightLabel.isHidden = true
                    bottomRightLabel.isHidden = true
                }
                setupViews()
            }
        }
    }
    
    var accountDetails: AccountDetails! {
        didSet {
            if let accountDetails = accountDetails {
                transactionDetails = nil
                holding = nil
                
                numberFormatter.currencyCode = accountDetails.currencyCode ?? "USD"
                
                nameLeftLabel.text = accountDetails.name
                if let amount = numberFormatter.string(from: accountDetails.balance as NSNumber) {
                    nameRightLabel.text = amount
                    if let balance = accountDetails.lastPeriodBalance, let lastPeriodAmount = numberFormatter.string(from: balance as NSNumber), let difference = numberFormatter.string(from: accountDetails.balance - balance as NSNumber) {
                        middleLeftLabel.isHidden = false
                        bottomLeftLabel.isHidden = false
                        middleRightLabel.isHidden = false
                        bottomRightLabel.isHidden = false
                        
                        switch selectedIndex {
                        case .day:
                            middleLeftLabel.text = "Yesterday"
                        case .week:
                            middleLeftLabel.text = "Last Week"
                        case .month:
                            middleLeftLabel.text = "Last Month"
                        case .year:
                            middleLeftLabel.text = "Last Year"
                        }
                        bottomLeftLabel.text = "Difference"
                        
                        middleRightLabel.text = lastPeriodAmount
                        bottomRightLabel.text = difference
                    }
                } else {
                    middleLeftLabel.isHidden = true
                    bottomLeftLabel.isHidden = true
                    middleRightLabel.isHidden = true
                    bottomRightLabel.isHidden = true
                    
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
                
                numberFormatter.currencyCode = accountDetails.currencyCode ?? "USD"
                
                nameLeftLabel.text = holding.symbol ?? holding.description
                                      
                let isodateFormatter = ISO8601DateFormatter()
                let dateFormatterPrint = DateFormatter()
                dateFormatterPrint.dateFormat = "E, MMM d, yyyy"
                                
                if let marketValue = holding.market_value, let amount = numberFormatter.string(from: marketValue as NSNumber), let costBasis = holding.cost_basis, costBasis != 0 {
                    let percentFormatter = NumberFormatter()
                    percentFormatter.numberStyle = .percent
                    percentFormatter.positivePrefix = percentFormatter.plusSign
                    percentFormatter.maximumFractionDigits = 0
                    percentFormatter.minimumFractionDigits = 0
                    
                    let percent = marketValue / costBasis - 1
                    if let percentText = percentFormatter.string(from: NSNumber(value: percent)) {
                        let fullText = "Market Value \(amount) (\(percentText))"
                        if percent < 0 {
                            let attributedText = fullText.setColor(.systemRed, ofSubstring: "(\(percentText))")
                            middleLeftLabel.attributedText = attributedText
                        } else {
                            let attributedText = fullText.setColor(.systemGreen, ofSubstring: "(\(percentText))")
                            middleLeftLabel.attributedText = attributedText
                        }
                    }
                } else if let marketValue = holding.market_value, let amount = numberFormatter.string(from: marketValue as NSNumber) {
                    middleLeftLabel.text = "Market Value \(amount)"
                }
                if let date = isodateFormatter.date(from: holding.updated_at) {
                    bottomLeftLabel.text = "Last Updated \(dateFormatterPrint.string(from: date))"
                }
                setupViews()
            }
        }
    }
    
    var selectedIndex: TimeSegmentType = .month
    
    let numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        return formatter
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    let nameLeftLabel: UILabel = {
        let label = UILabel()
        label.textColor = .label
        label.font = UIFont.preferredFont(forTextStyle: .headline)
        label.numberOfLines = 0
        label.textAlignment = .left
        label.adjustsFontForContentSizeCategory = true
        return label
    }()
    
    let nameRightLabel: UILabel = {
        let label = UILabel()
        label.textColor = .label
        label.font = UIFont.preferredFont(forTextStyle: .headline)
        label.numberOfLines = 0
        label.textAlignment = .right
        label.adjustsFontForContentSizeCategory = true
        return label
    }()
    
    let middleLeftLabel: UILabel = {
        let label = UILabel()
        label.textColor = .label
        label.font = UIFont.preferredFont(forTextStyle: .subheadline)
        label.numberOfLines = 0
        label.textAlignment = .left
        label.adjustsFontForContentSizeCategory = true
        return label
    }()
    
    let middleRightLabel: UILabel = {
        let label = UILabel()
        label.textColor = .label
        label.font = UIFont.preferredFont(forTextStyle: .subheadline)
        label.numberOfLines = 0
        label.textAlignment = .right
        label.adjustsFontForContentSizeCategory = true
        return label
    }()
    
    let bottomLeftLabel: UILabel = {
        let label = UILabel()
        label.textColor = .secondaryLabel
        label.font = UIFont.preferredFont(forTextStyle: .subheadline)
        label.numberOfLines = 0
        label.textAlignment = .left
        label.adjustsFontForContentSizeCategory = true
        return label
    }()
    
    let bottomRightLabel: UILabel = {
        let label = UILabel()
        label.textColor = .secondaryLabel
        label.font = UIFont.preferredFont(forTextStyle: .subheadline)
        label.numberOfLines = 0
        label.textAlignment = .right
        label.adjustsFontForContentSizeCategory = true
        return label
    }()
    
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
        backgroundView?.layer.shadowOpacity = 0.1
        backgroundView?.layer.shadowRadius = 10
        backgroundView?.layer.shadowOffset = .init(width: 0, height: 10)
        
        let verticalLeftStackView = VerticalStackView(arrangedSubviews: [nameLeftLabel, middleLeftLabel, bottomLeftLabel], spacing: 2)
        
        let verticalRightStackView = VerticalStackView(arrangedSubviews: [nameRightLabel, middleRightLabel, bottomRightLabel], spacing: 2)

        let stackView = UIStackView(arrangedSubviews: [verticalLeftStackView, UIView(), verticalRightStackView])
        stackView.alignment = .center
        stackView.distribution = .fill

        addSubview(stackView)
        stackView.fillSuperview(padding: .init(top: 10, left: 10, bottom: 10, right: 10))
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        nameLeftLabel.text = nil
        middleLeftLabel.text = nil
        bottomLeftLabel.text = nil
                
        middleLeftLabel.isHidden = false
        bottomLeftLabel.isHidden = false
        
        nameRightLabel.text = nil
        middleRightLabel.text = nil
        bottomRightLabel.text = nil
                
        middleRightLabel.isHidden = false
        bottomRightLabel.isHidden = false
        
    }
    
}
