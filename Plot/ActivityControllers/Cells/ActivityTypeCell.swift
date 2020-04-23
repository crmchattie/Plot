//
//  ActivityTypeCell.swift
//  Plot
//
//  Created by Hafiz Usama on 2019-11-11.
//  Copyright © 2019 Immature Creations. All rights reserved.
//

import UIKit

protocol ActivityTypeCellDelegate: class {
    func viewTapped(labelText: String)
}

class ActivityTypeCell: UICollectionViewCell {
    
    weak var delegate: ActivityTypeCellDelegate?
    
    let view: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Activity Type"
        label.textColor = ThemeManager.currentTheme().generalTitleColor
        label.font = .boldSystemFont(ofSize: 30)
        label.isUserInteractionEnabled = true
        return label
    }()
    
    let arrowView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.layer.masksToBounds = true
        imageView.contentMode = .scaleAspectFit
        imageView.image = UIImage(named: "chevronRightBlack")!.withRenderingMode(.alwaysTemplate)
        imageView.tintColor = ThemeManager.currentTheme().generalTitleColor
        return imageView
    }()
        
    let horizontalController = HorizontalController()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupViews() {
        
        view.constrainHeight(constant: 30)
        arrowView.constrainWidth(constant: 30)
        arrowView.constrainHeight(constant: 30)
        
        addSubview(view)
        view.addSubview(titleLabel)
        view.addSubview(arrowView)
        addSubview(horizontalController.view)
        
        view.anchor(top: topAnchor, leading: leadingAnchor, bottom: nil, trailing: trailingAnchor, padding: .init(top: 0, left: 0, bottom: 0, right: 0))
        titleLabel.anchor(top: view.topAnchor, leading: view.leadingAnchor, bottom: view.bottomAnchor, trailing: nil, padding: .init(top: 0, left: 16, bottom: 0, right: 0))
        arrowView.anchor(top: view.topAnchor, leading: titleLabel.trailingAnchor, bottom: view.bottomAnchor, trailing: nil, padding: .init(top: 0, left: 5, bottom: 0, right: 0))
        horizontalController.view.anchor(top: view.bottomAnchor, leading: leadingAnchor, bottom: bottomAnchor, trailing: trailingAnchor)
        let viewTap = UITapGestureRecognizer(target: self, action: #selector(ActivityTypeCell.viewTapped(_:)))
        view.addGestureRecognizer(viewTap)
                
        
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        titleLabel.textColor = ThemeManager.currentTheme().generalTitleColor
        arrowView.tintColor = ThemeManager.currentTheme().generalTitleColor

    }
    
    @objc func viewTapped(_ sender: UITapGestureRecognizer) {
        guard let labelText = titleLabel.text else {
            return
        }
        self.delegate?.viewTapped(labelText: labelText)
    }
}
