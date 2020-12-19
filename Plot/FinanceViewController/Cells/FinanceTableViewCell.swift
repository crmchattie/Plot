//
//  FinanceTableViewCell.swift
//  Plot
//
//  Created by Cory McHattie on 9/26/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import Foundation

class FinanceTableViewCell: UITableViewCell {
    
    var transaction: Transaction! {
        didSet {
            if let transaction = transaction {
                let numberFormatter = NumberFormatter()
                numberFormatter.currencyCode = "USD"
                numberFormatter.numberStyle = .currency
                
                let isodateFormatter = ISO8601DateFormatter()
                let dateFormatterPrint = DateFormatter()
                dateFormatterPrint.dateFormat = "E, MMM d, yyyy"
                
                categoryLabel.isHidden = true
                
                nameLabel.text = transaction.description
                if let amount = numberFormatter.string(from: transaction.amount as NSNumber) {
                    middleLabel.text = "Amount: \(amount)"
                }
                if let date = isodateFormatter.date(from: transaction.transacted_at) {
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
                let numberFormatter = NumberFormatter()
                numberFormatter.currencyCode = "USD"
                numberFormatter.numberStyle = .currency
                
                let isodateFormatter = ISO8601DateFormatter()
                let dateFormatterPrint = DateFormatter()
                dateFormatterPrint.dateFormat = "MMM dd, yyyy"
                
                categoryLabel.isHidden = true
                
                nameLabel.text = account.name
                
                let currentBalance = account.available_balance ?? account.balance
                if let balance = numberFormatter.string(from: currentBalance as NSNumber) {
                    middleLabel.text = "Balance: \(balance)"
                }
                if let date = isodateFormatter.date(from: account.updated_at) {
                    bottomLabel.text = "Last Updated On: \(dateFormatterPrint.string(from: date))"
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
        label.textAlignment = .left
        return label
    }()
    
    let bottomLabel: UILabel = {
        let label = UILabel()
        label.textColor = ThemeManager.currentTheme().generalSubtitleColor
        label.font = UIFont.preferredFont(forTextStyle: .body)
        label.numberOfLines = 0
        label.textAlignment = .left
        return label
    }()
    
    let IV = UIImageView(cornerRadius: 8)
    
    func setupViews() {
        backgroundColor = .clear
        let labelStackView = VerticalStackView(arrangedSubviews: [nameLabel, middleLabel, bottomLabel], spacing: 2)
        labelStackView.spacing = 2
        
        let stackView = UIStackView(arrangedSubviews: [labelStackView, UIView(), IV, categoryLabel])
        stackView.spacing = 2
        stackView.alignment = .center
        stackView.distribution = .fill
        
        addSubview(stackView)
        stackView.fillSuperview(padding: .init(top: 0, left: 16, bottom: 20, right: 16))
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
        IV.isHidden = false
    }
    
}