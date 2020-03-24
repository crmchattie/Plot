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
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
   
    let getTixLabel: UILabel = {
        let label = UILabel()
//        label.textColor = FalconPalette.ticketmaster
        label.textColor = ThemeManager.currentTheme().generalTitleColor
        label.font = UIFont.systemFont(ofSize: 18)
        label.text = "Go to Ticketmaster"
        label.numberOfLines = 1
        label.isUserInteractionEnabled = true
        return label
    }()
   
    func setupViews() {
        
        clickView.constrainHeight(constant: 20)
        addSubview(clickView)
        clickView.addSubview(getTixLabel)

        clickView.anchor(top: topAnchor, leading: leadingAnchor, bottom: nil, trailing: trailingAnchor, padding: .init(top: 0, left: 0, bottom: 0, right: 0))
        getTixLabel.anchor(top: clickView.topAnchor, leading: leadingAnchor, bottom: nil, trailing: trailingAnchor, padding: .init(top: 0, left: 5, bottom: 0, right: 0))
       
        let viewGesture = UITapGestureRecognizer(target: self, action: #selector(viewTapped(_:)))
        clickView.addGestureRecognizer(viewGesture)
            
    }
        
    @objc func viewTapped(_ sender: UITapGestureRecognizer) {
        self.delegate?.viewTapped()
    }
}
