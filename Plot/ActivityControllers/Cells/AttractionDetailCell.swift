//
//  AttractionDetailCell.swift
//  Plot
//
//  Created by Cory McHattie on 4/8/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import UIKit

protocol AttractionDetailCellDelegate: class {
    func labelTapped(event: Event)
}

class AttractionDetailCell: UICollectionViewCell {
    
    weak var delegate: AttractionDetailCellDelegate?
    
    var count: Int = 0
    
    var event: Event! {
        didSet {
            nameLabel.text = "\(event.name)"
            if let startDateTime = event.dates?.start?.dateTime, let date = startDateTime.toDate() {
                let newDate = date.startDateTimeString()
                categoryLabel.text = "\(newDate) @ \(event.embedded?.venues?[0].name ?? "")"
            }
            if let minPrice = event.priceRanges?[0].min, let maxPrice = event.priceRanges?[0].max {
                let formatter = CurrencyFormatter()
                formatter.locale = .current
                formatter.numberStyle = .currency
                let minPriceString = formatter.string(for: minPrice)!
                let maxPriceString = formatter.string(for: maxPrice)!
                subcategoryLabel.text = "Price range: \(minPriceString) to \(maxPriceString)"
            } else {
                subcategoryLabel.text = ""
            }
        }
    }
        
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
   
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
   
    let nameLabel: UILabel = {
        let label = UILabel()
        label.textColor = ThemeManager.currentTheme().generalTitleColor
        label.font = UIFont.preferredFont(forTextStyle: .body)
        label.numberOfLines = 0
        label.isUserInteractionEnabled = true
        return label
    }()

    let categoryLabel: UILabel = {
        let label = UILabel()
        label.textColor = ThemeManager.currentTheme().generalSubtitleColor
        label.font = UIFont.preferredFont(forTextStyle: .subheadline)
        label.numberOfLines = 0
        return label
    }()

    let subcategoryLabel: UILabel = {
        let label = UILabel()
        label.textColor = ThemeManager.currentTheme().generalSubtitleColor
        label.font = UIFont.preferredFont(forTextStyle: .subheadline)
        label.numberOfLines = 0
        return label
    }()
   
    func setupViews() {
                
        let nameDetailStackView = VerticalStackView(arrangedSubviews: [nameLabel, categoryLabel, subcategoryLabel], spacing: 2)
        nameDetailStackView.layoutMargins = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        nameDetailStackView.isLayoutMarginsRelativeArrangement = true
        
        
        addSubview(nameDetailStackView)
        nameDetailStackView.fillSuperview(padding: .init(top: 0, left: 25, bottom: 15, right: 15))
        
        let eventGesture = UITapGestureRecognizer(target: self, action: #selector(labelTapped(_:)))
        nameDetailStackView.addGestureRecognizer(eventGesture)
       
            
    }
    
    @objc func labelTapped(_ sender: UITapGestureRecognizer) {
        if let event = event {
            self.delegate?.labelTapped(event: event)
        }
    }
        
}
