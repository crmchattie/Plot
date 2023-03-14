//
//  SetupCell.swift
//  Plot
//
//  Created by Cory McHattie on 3/14/23.
//  Copyright © 2023 Immature Creations. All rights reserved.
//

import Foundation

class SetupCell: BaseContainerCollectionViewCell {
    var colors : [UIColor] = [FalconPalette.defaultRed, FalconPalette.defaultBlue, FalconPalette.defaultOrange, FalconPalette.defaultDarkBlue, FalconPalette.defaultGreen]
    
    var customType: CustomType! {
        didSet {
            imageView.image = UIImage(named: customType.image)!.withRenderingMode(.alwaysTemplate)
            imageView.contentMode = .scaleAspectFit
            imageView.backgroundColor = .secondarySystemGroupedBackground
            containerImageView.backgroundColor = .secondarySystemGroupedBackground
            var intColor: Int = 0
            if customType == CustomType.time {
                intColor = 1
            } else if customType == CustomType.health {
                intColor = 0
            } else if customType == CustomType.finances {
                intColor = 4
            }
            imageView.tintColor = colors[intColor]
            typeLabel.text = customType.categoryText
            descriptionLabel.text = customType.subcategoryText
            subDescriptionLabel.text = customType.subSubcategoryText
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
        imageView.layer.cornerRadius = 75 / 2
        return imageView
    }()
    
    let typeLabel: UILabel = {
        let label = UILabel()
        label.textColor = .label
        label.font = UIFont.title3.with(weight: .bold)
        label.numberOfLines = 1
        label.textAlignment = .left
        label.adjustsFontForContentSizeCategory = true
        return label
    }()
    
    let descriptionLabel: UILabel = {
        let label = UILabel()
        label.textColor = .label
        label.font = UIFont.preferredFont(forTextStyle: .body)
        label.numberOfLines = 0
        label.textAlignment = .center
        label.adjustsFontForContentSizeCategory = true
        return label
    }()
    
    let subDescriptionLabel: UILabel = {
        let label = UILabel()
        label.textColor = .label
        label.font = UIFont.preferredFont(forTextStyle: .body)
        label.numberOfLines = 0
        label.textAlignment = .center
        label.adjustsFontForContentSizeCategory = true
        return label
    }()
        
    override init(frame: CGRect) {
        super.init(frame: frame)
        layer.cornerRadius = 16
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    override func setupViews() {
        super.setupViews()
        
        containerImageView.constrainWidth(75)
        containerImageView.constrainHeight(75)
        
        containerImageView.layer.masksToBounds = true
        containerImageView.layer.cornerRadius = 75 / 2
        
        imageView.constrainWidth(50)
        imageView.constrainHeight(50)
                
        containerImageView.addSubview(imageView)
        NSLayoutConstraint.activate([
            imageView.centerXAnchor.constraint(equalTo: containerImageView.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: containerImageView.centerYAnchor)
        ])
        
        let stackView = VerticalStackView(arrangedSubviews: [containerImageView, typeLabel, descriptionLabel, subDescriptionLabel], spacing: 10)
        stackView.backgroundColor = .secondarySystemGroupedBackground
        stackView.alignment = .center
        
        addSubview(stackView)
        stackView.fillSuperview(padding: .init(top: 16, left: 16, bottom: 16, right: 16))

    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        typeLabel.textColor = .label
        descriptionLabel.textColor = .label
        subDescriptionLabel.textColor = .label
        
    }
}
