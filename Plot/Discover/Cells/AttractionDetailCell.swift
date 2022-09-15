//
//  AttractionDetailCell.swift
//  Plot
//
//  Created by Cory McHattie on 4/8/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import UIKit

protocol AttractionDetailCellDelegate: AnyObject {
    func viewTapped(event: TicketMasterEvent)
}

class AttractionDetailCell: UICollectionViewCell {
    
    weak var delegate: AttractionDetailCellDelegate?
    
    var count: Int = 0
    
    var event: TicketMasterEvent! {
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
        label.textColor = .label
        label.font = UIFont.preferredFont(forTextStyle: .body)
        label.numberOfLines = 0
        label.isUserInteractionEnabled = true
        label.adjustsFontForContentSizeCategory = true
        return label
    }()

    let categoryLabel: UILabel = {
        let label = UILabel()
        label.textColor = .secondaryLabel
        label.font = UIFont.preferredFont(forTextStyle: .subheadline)
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true
        return label
    }()

    let subcategoryLabel: UILabel = {
        let label = UILabel()
        label.textColor = .secondaryLabel
        label.font = UIFont.preferredFont(forTextStyle: .subheadline)
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true
        return label
    }()
    
    let arrowView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.layer.masksToBounds = true
        imageView.contentMode = .scaleAspectFit
        imageView.image = UIImage(named: "chevronRightBlack")!.withRenderingMode(.alwaysTemplate)
        imageView.tintColor = .secondaryLabel
        return imageView
    }()
   
    func setupViews() {
        
        arrowView.constrainWidth(20)
        arrowView.constrainHeight(20)
                
        let nameDetailStackView = VerticalStackView(arrangedSubviews: [nameLabel, categoryLabel, subcategoryLabel], spacing: 2)
        nameDetailStackView.layoutMargins = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        nameDetailStackView.isLayoutMarginsRelativeArrangement = true
        
        let arrowStackView = VerticalStackView(arrangedSubviews: [UIView(), arrowView, UIView()], spacing: 2)
        arrowStackView.distribution = .equalCentering
        
        let stackView = UIStackView(arrangedSubviews: [nameDetailStackView, arrowStackView])
        stackView.spacing = 2
        addSubview(stackView)
        
        stackView.fillSuperview(padding: .init(top: 0, left: 25, bottom: 15, right: 15))
        
        let eventGesture = UITapGestureRecognizer(target: self, action: #selector(viewTapped(_:)))
        nameDetailStackView.addGestureRecognizer(eventGesture)
       
            
    }
    
    @objc func viewTapped(_ sender: UITapGestureRecognizer) {
        if let event = event {
            self.delegate?.viewTapped(event: event)
        }
    }
        
}
