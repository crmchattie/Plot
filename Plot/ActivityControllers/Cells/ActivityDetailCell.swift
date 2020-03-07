//
//  ActivityDetailCell.swift
//  Plot
//
//  Created by Cory McHattie on 2/8/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import UIKit

class ActivityDetailCell: UICollectionViewCell {
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
        
        let heartImage: UIImageView = {
            let imageView = UIImageView()
            imageView.translatesAutoresizingMaskIntoConstraints = false
            imageView.layer.masksToBounds = true
            imageView.image = UIImage(named: "heart")!.withRenderingMode(.alwaysTemplate)
            imageView.tintColor = ThemeManager.currentTheme().generalTitleColor
            return imageView
        }()
        
        let shareImage: UIImageView = {
            let imageView = UIImageView()
            imageView.translatesAutoresizingMaskIntoConstraints = false
            imageView.layer.masksToBounds = true
            imageView.image = UIImage(named: "share")!.withRenderingMode(.alwaysTemplate)
            imageView.tintColor = ThemeManager.currentTheme().generalTitleColor
            return imageView
        }()
        
        let plusImage: UIImageView = {
            let imageView = UIImageView()
            imageView.translatesAutoresizingMaskIntoConstraints = false
            imageView.layer.masksToBounds = true
            imageView.image = UIImage(named: "plus")!.withRenderingMode(.alwaysTemplate)
            imageView.tintColor = ThemeManager.currentTheme().generalTitleColor
            return imageView
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
        
        let imageView = UIImageView(cornerRadius: 0)
        

        func setupViews() {
            
            buttonView.constrainHeight(constant: 40)
    //        borderView.constrainWidth(constant: 80)
    //        borderView.constrainHeight(constant: 40)
            
            heartImage.constrainWidth(constant: 40)
            heartImage.constrainHeight(constant: 40)
            
            shareImage.constrainWidth(constant: 40)
            shareImage.constrainHeight(constant: 40)
            
            plusImage.constrainWidth(constant: 40)
            plusImage.constrainHeight(constant: 40)

            imageView.constrainHeight(constant: 231)
            
            buttonView.addSubview(heartImage)
            buttonView.addSubview(shareImage)
            buttonView.addSubview(plusImage)
            labelView.addSubview(nameLabel)
            labelView.addSubview(categoryLabel)
            labelView.addSubview(subcategoryLabel)

            
            heartImage.anchor(top: buttonView.topAnchor, leading: buttonView.leadingAnchor, bottom: buttonView.bottomAnchor, trailing: nil, padding: .init(top: 0, left: 0, bottom: 0, right: 0))
            shareImage.anchor(top: buttonView.topAnchor, leading: heartImage.trailingAnchor, bottom: buttonView.bottomAnchor, trailing: nil, padding: .init(top: 0, left: 0, bottom: 0, right: 0))
            plusImage.anchor(top: buttonView.topAnchor, leading: shareImage.trailingAnchor, bottom: buttonView.bottomAnchor, trailing: nil, padding: .init(top: 0, left: 0, bottom: 0, right: 0))
            
            nameLabel.anchor(top: labelView.topAnchor, leading: labelView.leadingAnchor, bottom: nil, trailing: labelView.trailingAnchor, padding: .init(top: 0, left: 10, bottom: 0, right: 0))
            categoryLabel.anchor(top: nameLabel.bottomAnchor, leading: labelView.leadingAnchor, bottom: nil, trailing: labelView.trailingAnchor, padding: .init(top: 0, left: 10, bottom: 0, right: 0))
            subcategoryLabel.anchor(top: categoryLabel.bottomAnchor, leading: labelView.leadingAnchor, bottom: nil, trailing: labelView.trailingAnchor, padding: .init(top: 0, left: 10, bottom: 0, right: 0))
            
            let stackView = VerticalStackView(arrangedSubviews: [
                imageView,
                buttonView,
                labelView
                ], spacing: 5)
            addSubview(stackView)
            stackView.fillSuperview(padding: .init(top: 0, left: 0, bottom: 0, right: 0))
            

        }

}
