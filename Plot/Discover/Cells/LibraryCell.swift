//
//  LibraryCell.swift
//  Plot
//
//  Created by Cory McHattie on 9/27/22.
//  Copyright © 2022 Immature Creations. All rights reserved.
//

import UIKit

class LibraryCell: UICollectionViewCell {
    
    var colors : [UIColor] = [FalconPalette.defaultBlue, FalconPalette.defaultRed, FalconPalette.defaultOrange, FalconPalette.defaultGreen, FalconPalette.defaultDarkBlue]
    var intColor: Int = 0
    
    var template: Template! {
        didSet {
            if let template = template {
                customType = nil
                nameLabel.textColor = .label
                nameLabel.text = template.name
                imageView.image = template.category.icon.withRenderingMode(.alwaysTemplate)
                imageView.tintColor = colors[intColor].withAlphaComponent(1)
                imageView.contentMode = .scaleAspectFit
                imageView.backgroundColor = .clear
                containerImageView.backgroundColor = colors[intColor].withAlphaComponent(0.2)
                setupViews()
            }
        }
    }
    
    var customType: CustomType! {
        didSet {
            if let customType = customType {
                template = nil
                nameLabel.textColor = .label
                nameLabel.text = customType.name
                imageView.image = UIImage(named: customType.image)!.withRenderingMode(.alwaysTemplate)
                imageView.tintColor = colors[intColor].withAlphaComponent(1)
                imageView.contentMode = .scaleAspectFit
                imageView.backgroundColor = .clear
                containerImageView.backgroundColor = colors[intColor].withAlphaComponent(0.2)
                setupViews()
            }
        }
    }
    
    let nameLabel: UILabel = {
        let label = UILabel()
        label.textColor = .label
        label.font = UIFont.body.with(weight: .bold)
        label.adjustsFontForContentSizeCategory = true
        return label
    }()
    
    let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    let containerImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.layer.masksToBounds = true
        imageView.layer.cornerRadius = 45 / 2
        return imageView
    }()
    
    let arrowView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.layer.masksToBounds = true
        imageView.contentMode = .scaleAspectFit
        imageView.image = UIImage(named: "chevronRightBlack")!.withRenderingMode(.alwaysTemplate)
        imageView.tintColor = .secondaryLabel
        return imageView
    }()
    
    override var isHighlighted: Bool {
        didSet {
            self.backgroundView?.backgroundColor = .secondarySystemGroupedBackground.withAlphaComponent(isHighlighted ? 0.7 : 1)
        }
    }
    
    func setupViews() {
        backgroundColor = .clear
        backgroundView = UIView()
        addSubview(backgroundView!)
        backgroundView?.fillSuperview()
        backgroundView?.backgroundColor = .secondarySystemGroupedBackground
        backgroundView?.roundCorners(corners: [.allCorners], radius: 10)
        
        containerImageView.constrainWidth(45)
        containerImageView.constrainHeight(45)
        
        containerImageView.layer.masksToBounds = true
        containerImageView.layer.cornerRadius = 45 / 2
        
        imageView.constrainWidth(30)
        imageView.constrainHeight(30)
        
        containerImageView.addSubview(imageView)
        NSLayoutConstraint.activate([
            imageView.centerXAnchor.constraint(equalTo: containerImageView.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: containerImageView.centerYAnchor)
        ])
        
        let imageVerticalView = VerticalStackView(arrangedSubviews: [UIView(), containerImageView, UIView()])
        imageVerticalView.alignment = .center
        
        let verticalView = VerticalStackView(arrangedSubviews: [nameLabel, imageVerticalView], spacing: 15)
        addSubview(verticalView)
        verticalView.fillSuperview(padding: .init(top: 10, left: 10, bottom: 10, right: 10))
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        nameLabel.textColor = .label
        
    }
    
}
