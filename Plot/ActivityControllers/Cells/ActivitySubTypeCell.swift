//
//  ActivitySubTypeCell.swift
//  Plot
//
//  Created by Cory McHattie on 1/4/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import UIKit

protocol ActivitySubTypeCellDelegate: class {
    func plusButtonTapped()
    func shareButtonTapped()
    func heartButtonTapped()
}

class ActivitySubTypeCell: UICollectionViewCell {
    
    weak var delegate: ActivitySubTypeCellDelegate?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    let buttonView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    let labelView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    let borderView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.masksToBounds = true
        view.layer.cornerRadius = 8
        view.layer.borderWidth = 2
        view.layer.borderColor = FalconPalette.defaultBlue.cgColor
        return view
    }()
    
    let heartButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(named: "heart"), for: .normal)
        button.tintColor = ThemeManager.currentTheme().generalTitleColor
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    let shareButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(named: "share"), for: .normal)
        button.tintColor = ThemeManager.currentTheme().generalTitleColor
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    let plusButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(named: "plus"), for: .normal)
        button.tintColor = ThemeManager.currentTheme().generalTitleColor
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    let nameLabel: UILabel = {
        let label = UILabel()
        label.textColor = ThemeManager.currentTheme().generalTitleColor
        label.text = "Cheesy Chicken Enchilada Quinoa Casserole"
        label.font = UIFont.systemFont(ofSize: 18)
        label.numberOfLines = 0
        return label
    }()

    let categoryLabel: UILabel = {
        let label = UILabel()
        label.textColor = ThemeManager.currentTheme().generalSubtitleColor
        label.text = "Preparation time: 30 mins"
        label.font = UIFont.systemFont(ofSize: 13)
        label.numberOfLines = 0
        return label
    }()

    let subcategoryLabel: UILabel = {
        let label = UILabel()
        label.textColor = ThemeManager.currentTheme().generalSubtitleColor
        label.text = "Servings: 4"
        label.font = UIFont.systemFont(ofSize: 13)
        label.numberOfLines = 0
        return label
    }()
    
    let imageView = UIImageView(cornerRadius: 8)
    

    func setupViews() {
        
        buttonView.constrainHeight(constant: 40)
//        borderView.constrainWidth(constant: 80)
//        borderView.constrainHeight(constant: 40)
        
        heartButton.constrainWidth(constant: 40)
        heartButton.constrainHeight(constant: 40)
        
        shareButton.constrainWidth(constant: 40)
        shareButton.constrainHeight(constant: 40)
        
        plusButton.constrainWidth(constant: 40)
        plusButton.constrainHeight(constant: 40)

        imageView.constrainHeight(constant: 231)
        
        buttonView.addSubview(plusButton)
        buttonView.addSubview(shareButton)
        buttonView.addSubview(heartButton)
        labelView.addSubview(nameLabel)
        labelView.addSubview(categoryLabel)
        labelView.addSubview(subcategoryLabel)

        
        plusButton.anchor(top: buttonView.topAnchor, leading: buttonView.leadingAnchor, bottom: buttonView.bottomAnchor, trailing: nil, padding: .init(top: 0, left: 0, bottom: 0, right: 0))
        shareButton.anchor(top: buttonView.topAnchor, leading: plusButton.trailingAnchor, bottom: buttonView.bottomAnchor, trailing: nil, padding: .init(top: 0, left: 0, bottom: 0, right: 0))
        heartButton.anchor(top: buttonView.topAnchor, leading: shareButton.trailingAnchor, bottom: buttonView.bottomAnchor, trailing: nil, padding: .init(top: 0, left: 0, bottom: 0, right: 0))
        nameLabel.anchor(top: labelView.topAnchor, leading: labelView.leadingAnchor, bottom: nil, trailing: labelView.trailingAnchor, padding: .init(top: 0, left: 0, bottom: 0, right: 0))
        categoryLabel.anchor(top: nameLabel.bottomAnchor, leading: labelView.leadingAnchor, bottom: nil, trailing: labelView.trailingAnchor, padding: .init(top: 0, left: 0, bottom: 0, right: 0))
        subcategoryLabel.anchor(top: categoryLabel.bottomAnchor, leading: labelView.leadingAnchor, bottom: nil, trailing: labelView.trailingAnchor, padding: .init(top: 0, left: 0, bottom: 0, right: 0))
        
        let stackView = VerticalStackView(arrangedSubviews: [
            imageView,
            buttonView,
            labelView
            ], spacing: 5)
        addSubview(stackView)
        stackView.fillSuperview(padding: .init(top: 10, left: 0, bottom: 0, right: 0))
        
        plusButton.addTarget(self, action: #selector(plusButtonTapped), for: .touchUpInside)
        shareButton.addTarget(self, action: #selector(shareButtonTapped), for: .touchUpInside)
        heartButton.addTarget(self, action: #selector(heartButtonTapped), for: .touchUpInside)
        

    }
    
    @objc func plusButtonTapped() {
        self.delegate?.plusButtonTapped()
    }
    
    @objc func shareButtonTapped() {
        self.delegate?.shareButtonTapped()
    }

    @objc func heartButtonTapped() {
        self.delegate?.heartButtonTapped()
    }
}

