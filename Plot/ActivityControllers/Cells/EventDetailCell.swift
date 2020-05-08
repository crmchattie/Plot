//
//  EventDetailCell.swift
//  Plot
//
//  Created by Cory McHattie on 3/7/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import UIKit

protocol EventDetailCellDelegate: class {
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
        label.textColor = ThemeManager.currentTheme().generalTitleColor
        label.font = UIFont.preferredFont(forTextStyle: .body)
        label.attributedText = NSAttributedString(string: "Go to Ticketmaster", attributes:
        [.underlineStyle: NSUnderlineStyle.single.rawValue])
        label.numberOfLines = 1
        return label
    }()
    
    let clickArrowView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.layer.masksToBounds = true
        imageView.contentMode = .scaleAspectFit
        imageView.image = UIImage(named: "chevronRightBlack")!.withRenderingMode(.alwaysTemplate)
        imageView.tintColor = ThemeManager.currentTheme().generalSubtitleColor
        return imageView
    }()
   
    func setupViews() {
        
        clickView.constrainHeight(constant: 17)
        clickArrowView.constrainWidth(constant: 16)
        clickArrowView.constrainHeight(constant: 16)
        
        clickView.addSubview(getTixLabel)
        clickView.addSubview(clickArrowView)
        getTixLabel.anchor(top: clickView.topAnchor, leading: clickView.leadingAnchor, bottom: nil, trailing: clickView.trailingAnchor, padding: .init(top: 2, left: 15, bottom: 0, right: 15))
        clickArrowView.anchor(top: nil, leading: nil, bottom: nil, trailing: clickView.trailingAnchor, padding: .init(top: 0, left: 0, bottom: 0, right: 15))
        clickArrowView.centerYAnchor.constraint(equalTo: getTixLabel.centerYAnchor).isActive = true
        
        let stackView = VerticalStackView(arrangedSubviews:
            [clickView
            ], spacing: 0)
        addSubview(stackView)
        stackView.fillSuperview(padding: .init(top: 0, left: 0, bottom: 20, right: 0))
       
        let viewGesture = UITapGestureRecognizer(target: self, action: #selector(viewTapped(_:)))
        clickView.addGestureRecognizer(viewGesture)
            
    }
        
    @objc func viewTapped(_ sender: UITapGestureRecognizer) {
        self.delegate?.viewTapped()
    }
}
