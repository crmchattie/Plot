//
//  FinanceTableViewCell.swift
//  Plot
//
//  Created by Cory McHattie on 9/26/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import Foundation

private let dateFormatterPrint: DateFormatter = {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "E, MMM d, yyyy"
    return dateFormatter
}()

private let numberFormatter: NumberFormatter = {
    let numberFormatter = NumberFormatter()
    numberFormatter.numberStyle = .currency
    numberFormatter.maximumFractionDigits = 0
    return numberFormatter
}()

class FinanceTableViewCell: UITableViewCell {
    
    var transaction: Transaction! {
        didSet {
            if let transaction = transaction {
                numberFormatter.currencyCode = transaction.currency_code ?? "USD"
                                
                nameLabel.text = transaction.description
                if let amount = numberFormatter.string(from: transaction.amount as NSNumber) {
                    middleLabel.text = "Amount: \(amount)"
                }
                if let date = transaction.transactionDate {
                    bottomLabel.text = "Transacted On: \(dateFormatterPrint.string(from: date))"
                }
                IV.isHidden = !(transaction.should_link ?? true)
                IV.image = UIImage(systemName: "checkmark")
                IV.preferredSymbolConfiguration = UIImage.SymbolConfiguration(weight: .bold)
                setupViews()
            }
        }
    }
    
    var account: MXAccount! {
        didSet {
            if let account = account {
                numberFormatter.currencyCode = account.currency_code ?? "USD"
                                
                nameLabel.text = account.name
                
                let currentBalance = account.finalBalance
                if let balance = numberFormatter.string(from: currentBalance as NSNumber) {
                    middleLabel.text = "Balance: \(balance)"
                }
                if let date = isodateFormatter.date(from: account.updated_at) {
                    bottomLabel.text = "Last Updated: \(dateFormatterPrint.string(from: date))"
                }
                IV.isHidden = !(account.should_link ?? true)
                IV.image = UIImage(systemName: "checkmark")
                IV.preferredSymbolConfiguration = UIImage.SymbolConfiguration(weight: .bold)
                setupViews()
            }
        }
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .default, reuseIdentifier: reuseIdentifier)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    let nameLabel: UILabel = {
        let label = UILabel()
        label.textColor = .label
        label.font = UIFont.preferredFont(forTextStyle: .headline)
        label.numberOfLines = 0
        label.textAlignment = .left
        label.adjustsFontForContentSizeCategory = true
        return label
    }()
    
    let middleLabel: UILabel = {
        let label = UILabel()
        label.textColor = .label
        label.font = UIFont.preferredFont(forTextStyle: .subheadline)
        label.numberOfLines = 0
        label.textAlignment = .left
        label.adjustsFontForContentSizeCategory = true
        return label
    }()
    
    let bottomLabel: UILabel = {
        let label = UILabel()
        label.textColor = .secondaryLabel
        label.font = UIFont.preferredFont(forTextStyle: .subheadline)
        label.numberOfLines = 0
        label.textAlignment = .left
        label.adjustsFontForContentSizeCategory = true
        return label
    }()
    
    let IV: UIImageView = {
        let imageView = UIImageView(cornerRadius: 8)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    func setupViews() {
        let labelStackView = VerticalStackView(arrangedSubviews: [nameLabel, middleLabel, bottomLabel], spacing: 2)
        labelStackView.spacing = 2
        
        IV.constrainWidth(20)
        IV.constrainHeight(20)
        
        let stackView = UIStackView(arrangedSubviews: [labelStackView, IV])
        stackView.spacing = 2
        stackView.alignment = .center
        stackView.distribution = .fill
        
        addSubview(stackView)
        stackView.fillSuperview(padding: .init(top: 10, left: 10, bottom: 10, right: 10))
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        nameLabel.textColor = .label
        middleLabel.textColor = .label
        bottomLabel.textColor = .secondaryLabel
        
        nameLabel.font = UIFont.preferredFont(forTextStyle: .headline)
        middleLabel.font = UIFont.preferredFont(forTextStyle: .subheadline)
        bottomLabel.font = UIFont.preferredFont(forTextStyle: .subheadline)
        IV.isHidden = false
    }
}
