//
//  OnboardingCollectionViewCell.swift
//  Plot
//
//  Created by Cory McHattie on 10/11/22.
//  Copyright © 2022 Immature Creations. All rights reserved.
//

import Foundation
import UIKit

class OnboardingCollectionViewCell: UICollectionViewCell {
    var colors : [UIColor] = [FalconPalette.defaultRed, FalconPalette.defaultBlue, FalconPalette.defaultOrange, FalconPalette.defaultDarkBlue, FalconPalette.defaultGreen]
    var intColor: Int = 0
    
    var customType: CustomType! {
        didSet {
            imageView.image = UIImage(named: customType.image)!.withRenderingMode(.alwaysTemplate)
            imageView.tintColor = colors[intColor]
            imageView.contentMode = .scaleAspectFit
            imageView.backgroundColor = .secondarySystemGroupedBackground
            containerImageView.backgroundColor = .secondarySystemGroupedBackground
            typeLabel.text = customType.categoryText
            descriptionLabel.text = customType.subcategoryText
            setupViews()
        }
    }
    
    let containerView: UIView = {
        let imageView = UIView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    let typeLabel: UILabel = {
        let label = UILabel()
        label.textColor = .label
        label.font = UIFont.title2.with(weight: .bold)
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
    
    let containerImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.layer.masksToBounds = true
        imageView.layer.cornerRadius = 100 / 2
        return imageView
    }()
    
    let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        layer.cornerRadius = 16
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    func setupViews() {
                
        addSubview(containerView)
        containerView.fillSuperview(padding: .init(top: 0, left: 20, bottom: 0, right: 20))

        containerView.backgroundColor = .secondarySystemGroupedBackground
        containerView.layer.cornerRadius = 10
        containerView.layer.masksToBounds = true

        containerImageView.constrainWidth(100)
        containerImageView.constrainHeight(100)
        
        containerImageView.layer.masksToBounds = true
        containerImageView.layer.cornerRadius = 100 / 2
        
        imageView.constrainWidth(50)
        imageView.constrainHeight(50)
        
        containerImageView.addSubview(imageView)
        NSLayoutConstraint.activate([
            imageView.centerXAnchor.constraint(equalTo: containerImageView.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: containerImageView.centerYAnchor)
        ])
        
        let stackView = VerticalStackView(arrangedSubviews: [typeLabel, descriptionLabel, containerImageView], spacing: 10)
        stackView.alignment = .center
        
        containerView.addSubview(stackView)
        stackView.fillSuperview()
        
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        typeLabel.textColor = .label
        descriptionLabel.textColor = .label
        
    }
}
