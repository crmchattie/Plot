//
//  EventDetailCell.swift
//  Plot
//
//  Created by Cory McHattie on 3/7/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import UIKit

protocol EventDetailCellDelegate: AnyObject {
    func viewTapped()
}

class EventDetailCell: UICollectionViewCell {
    
    weak var delegate: EventDetailCellDelegate?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
   
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    let clickView: UIView = {
        let view = UIView()
        view.isUserInteractionEnabled = true
        return view
    }()
   
    let getTixLabel: UILabel = {
        let label = UILabel()
//        label.textColor = FalconPalette.ticketmaster
        label.textColor = .label
        label.font = UIFont.preferredFont(forTextStyle: .body)
        label.attributedText = NSAttributedString(string: "Go to Ticketmaster", attributes:
        [.underlineStyle: NSUnderlineStyle.single.rawValue])
        label.numberOfLines = 1
        label.adjustsFontForContentSizeCategory = true
        return label
    }()
    
    let clickArrowView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.layer.masksToBounds = true
        imageView.contentMode = .scaleAspectFit
        imageView.image = UIImage(named: "chevronRightBlack")!.withRenderingMode(.alwaysTemplate)
        imageView.tintColor = .secondaryLabel
        return imageView
    }()
    
    let extraLabel: UILabel = {
        let label = UILabel()
        label.textColor = .label
        label.font = UIFont.preferredFont(forTextStyle: .body)
        label.numberOfLines = 1
        label.text = "Other Dates:"
        label.adjustsFontForContentSizeCategory = true
        return label
    }()
   
    func setupViews() {
        
        clickView.constrainHeight(20)
        clickArrowView.constrainWidth(20)
        clickArrowView.constrainHeight(20)
        
        clickView.addSubview(getTixLabel)
        clickView.addSubview(clickArrowView)
        getTixLabel.anchor(top: clickView.topAnchor, leading: clickView.leadingAnchor, bottom: nil, trailing: clickView.trailingAnchor, padding: .init(top: 2, left: 15, bottom: 0, right: 15))
        clickArrowView.anchor(top: nil, leading: nil, bottom: nil, trailing: clickView.trailingAnchor, padding: .init(top: 0, left: 0, bottom: 0, right: 15))
        clickArrowView.centerYAnchor.constraint(equalTo: getTixLabel.centerYAnchor).isActive = true
        
        let extraLabelStackView = UIStackView(arrangedSubviews: [extraLabel])
        extraLabelStackView.layoutMargins = UIEdgeInsets(top: 20, left: 15, bottom: 0, right: 0)
        extraLabelStackView.isLayoutMarginsRelativeArrangement = true
        
        let stackView = VerticalStackView(arrangedSubviews:
            [clickView,
             extraLabelStackView
            ], spacing: 0)
        addSubview(stackView)
        stackView.fillSuperview(padding: .init(top: 0, left: 0, bottom: 0, right: 0))
       
        let viewGesture = UITapGestureRecognizer(target: self, action: #selector(viewTapped(_:)))
        clickView.addGestureRecognizer(viewGesture)
            
    }
        
    @objc func viewTapped(_ sender: UITapGestureRecognizer) {
        self.delegate?.viewTapped()
    }
}
