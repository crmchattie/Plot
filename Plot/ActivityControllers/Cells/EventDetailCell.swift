//
//  EventDetailCell.swift
//  Plot
//
//  Created by Cory McHattie on 3/7/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import UIKit

protocol EventDetailCellDelegate: class {
    func labelTapped()
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
   
    let getTixLabel: UILabel = {
        let label = UILabel()
        label.textColor = ThemeManager.currentTheme().generalSubtitleColor
        label.text = "Get Tickets"
        label.font = UIFont.systemFont(ofSize: 13)
        label.numberOfLines = 1
        label.isUserInteractionEnabled = true
        return label
    }()
   
    func setupViews() {
        addSubview(getTixLabel)

        getTixLabel.anchor(top: topAnchor, leading: leadingAnchor, bottom: nil, trailing: trailingAnchor, padding: .init(top: 0, left: 5, bottom: 0, right: 0))
       
        let labelGesture = UITapGestureRecognizer(target: self, action: #selector(labelTapped(_:)))
        getTixLabel.addGestureRecognizer(labelGesture)
            
    }
        
    @objc func labelTapped(_ sender: UITapGestureRecognizer) {
        self.delegate?.labelTapped()
    }
}
