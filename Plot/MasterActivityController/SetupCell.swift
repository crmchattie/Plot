//
//  SetupCollectionCell.swift
//  Plot
//
//  Created by Cory McHattie on 12/29/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import Foundation

class SetupCell: BaseContainerCell {    
    var colors : [UIColor] = [FalconPalette.defaultBlue, FalconPalette.defaultRed, FalconPalette.defaultOrange, FalconPalette.defaultGreen, FalconPalette.defaultDarkBlue]
    var intColor: Int = 0
    
    var sectionType: SectionType! {
        didSet {
            imageView.image = UIImage(named: sectionType.image)!.withRenderingMode(.alwaysTemplate)
            imageView.tintColor = colors[intColor]
            imageView.contentMode = .scaleAspectFit
            imageView.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
            containerImageView.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
            typeLabel.text = sectionType.type
            descriptionLabel.text = sectionType.subType
            setupViews()
        }
    }
    
    let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    let containerImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.layer.masksToBounds = true
        imageView.layer.cornerRadius = 100 / 2
        return imageView
    }()
    
    let typeLabel: UILabel = {
        let label = UILabel()
        label.textColor = ThemeManager.currentTheme().generalTitleColor
        label.font = UIFont.boldSystemFont(ofSize: 22)
        label.numberOfLines = 1
        label.textAlignment = .left
        return label
    }()
    
    let descriptionLabel: UILabel = {
        let label = UILabel()
        label.textColor = ThemeManager.currentTheme().generalTitleColor
        label.font = UIFont.preferredFont(forTextStyle: .body)
        label.numberOfLines = 0
        label.textAlignment = .left
        return label
    }()
    
    let button: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = .systemBlue
        button.setTitle("Get Started", for: .normal)
        button.titleLabel?.font = .boldSystemFont(ofSize: 15)
        button.setTitleColor(.white, for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.clipsToBounds = true
        button.layer.cornerRadius = 8
        return button
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        layer.cornerRadius = 16
        
        containerImageView.constrainWidth(100)
        containerImageView.constrainHeight(100)
        
        containerImageView.layer.masksToBounds = true
        containerImageView.layer.cornerRadius = 100 / 2
        
        imageView.constrainWidth(50)
        imageView.constrainHeight(50)
        
        button.constrainWidth(contentView.frame.width - 32)
        button.constrainHeight(45)
        
        button.clipsToBounds = true
        button.layer.cornerRadius = 8
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    override func setupViews() {
        super.setupViews()
                
        containerImageView.constrainWidth(100)
        containerImageView.constrainHeight(100)
        
        containerImageView.layer.masksToBounds = true
        containerImageView.layer.cornerRadius = 100 / 2
        
        imageView.constrainWidth(50)
        imageView.constrainHeight(50)
        
        button.constrainWidth(contentView.frame.width - 32)
        button.constrainHeight(45)
        
        button.clipsToBounds = true
        button.layer.cornerRadius = 8
        
        containerImageView.addSubview(imageView)
        NSLayoutConstraint.activate([
            imageView.centerXAnchor.constraint(equalTo: containerImageView.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: containerImageView.centerYAnchor)
        ])
        
        let stackView = VerticalStackView(arrangedSubviews: [containerImageView, typeLabel, descriptionLabel, button], spacing: 10)
        
        stackView.alignment = .center
        
        addSubview(stackView)
        stackView.fillSuperview(padding: .init(top: 16, left: 16, bottom: 16, right: 16))
        
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        typeLabel.textColor = ThemeManager.currentTheme().generalTitleColor
        descriptionLabel.textColor = ThemeManager.currentTheme().generalTitleColor
        
    }
}
