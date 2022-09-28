//
//  SubLibraryCell.swift
//  Plot
//
//  Created by Cory McHattie on 9/27/22.
//  Copyright © 2022 Immature Creations. All rights reserved.
//

import UIKit

class SubLibraryCell: UICollectionViewCell {
    
    var colors : [UIColor] = [FalconPalette.defaultBlue, FalconPalette.defaultRed, FalconPalette.defaultOrange, FalconPalette.defaultGreen, FalconPalette.defaultDarkBlue]
    var intColor: Int = 0
    
    var template: Template! {
        didSet {
            if let template = template {
                nameLabel.text = template.name
                subLabel.text = template.object.rawValue
                imageView.image = template.subcategory.icon.withRenderingMode(.alwaysTemplate)
                imageView.tintColor = colors[intColor].withAlphaComponent(1)
                imageView.contentMode = .scaleAspectFit
                imageView.backgroundColor = .clear
                containerImageView.backgroundColor = colors[intColor].withAlphaComponent(0.3)
                setupViews()
            }
        }
    }
    
    let nameLabel: UILabel = {
        let label = UILabel()
        label.textColor = .label
        label.font = UIFont.preferredFont(forTextStyle: .headline)
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true
        return label
    }()
    
    let subLabel: UILabel = {
        let label = UILabel()
        label.textColor = .label
        label.font = UIFont.preferredFont(forTextStyle: .subheadline)
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 1
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
    
    var firstPosition: Bool = false
    var lastPosition: Bool = false
    
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
        
        if firstPosition && lastPosition {
            backgroundView?.roundCorners(corners: [.allCorners], radius: 10)
        } else if firstPosition {
            backgroundView?.roundCorners(corners: [.topLeft, .topRight], radius: 10)
        } else if lastPosition {
            backgroundView?.roundCorners(corners: [.bottomLeft, .bottomRight], radius: 10)
        }
                
        containerImageView.constrainWidth(45)
        containerImageView.constrainHeight(45)
        
        containerImageView.layer.masksToBounds = true
        containerImageView.layer.cornerRadius = 45 / 2
        
        imageView.constrainWidth(30)
        imageView.constrainHeight(30)
        
        arrowView.constrainWidth(20)
        arrowView.constrainHeight(20)
        
        containerImageView.addSubview(imageView)
        NSLayoutConstraint.activate([
            imageView.centerXAnchor.constraint(equalTo: containerImageView.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: containerImageView.centerYAnchor)
        ])
    
        let arrowStackView = UIStackView(arrangedSubviews: [arrowView])
        arrowStackView.layoutMargins = UIEdgeInsets(top: 10, left: 0, bottom: 10, right: 0)
        arrowStackView.isLayoutMarginsRelativeArrangement = true
        let nameLabelStackView = VerticalStackView(arrangedSubviews: [nameLabel, subLabel])
        nameLabelStackView.layoutMargins = UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 0)
        nameLabelStackView.isLayoutMarginsRelativeArrangement = true
        let stackView = UIStackView(arrangedSubviews: [containerImageView, nameLabelStackView, arrowStackView])
        addSubview(stackView)
        stackView.fillSuperview(padding: .init(top: 10, left: 10, bottom: 10, right: 10))
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        firstPosition = false
        lastPosition = false
        
        nameLabel.textColor = .label
        subLabel.textColor = .label
        
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if firstPosition && lastPosition {
            backgroundView?.roundCorners(corners: [.allCorners], radius: 10)
        } else if firstPosition {
            backgroundView?.roundCorners(corners: [.topLeft, .topRight], radius: 10)
        } else if lastPosition {
            backgroundView?.roundCorners(corners: [.bottomLeft, .bottomRight], radius: 10)
        }
    }
    
}
