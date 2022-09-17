//
//  ActivityHeaderCell.swift
//  Plot
//
//  Created by Cory McHattie on 1/28/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import UIKit

class ActivityHeaderCell: UICollectionViewCell {
    
    var colors : [UIColor] = [FalconPalette.defaultBlue, FalconPalette.defaultRed, FalconPalette.defaultOrange, FalconPalette.defaultGreen, FalconPalette.defaultDarkBlue]
    var intColor: Int = 0
    
    var activityType: CustomType! {
        didSet {
            nameLabel.textColor = .label
            nameLabel.text = activityType.name
            logoImageView.image = UIImage(named: activityType.image)!.withRenderingMode(.alwaysTemplate)
            logoImageView.tintColor = colors[intColor]
            logoImageView.contentMode = .scaleAspectFit
            setupViews()
        }
    }
    
    let nameLabel: UILabel = {
        let label = UILabel()
        label.textColor = .label
        label.font = UIFont.title3.with(weight: .bold)
        label.adjustsFontForContentSizeCategory = true
        return label
    }()
    
    let logoImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.layer.masksToBounds = true
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
        
        logoImageView.constrainWidth(40)
        logoImageView.constrainHeight(40)
        
        arrowView.constrainWidth(20)
        arrowView.constrainHeight(20)
        
        let arrowStackView = UIStackView(arrangedSubviews: [arrowView])
        arrowStackView.layoutMargins = UIEdgeInsets(top: 10, left: 0, bottom: 10, right: 0)
        arrowStackView.isLayoutMarginsRelativeArrangement = true
        let nameLabelStackView = UIStackView(arrangedSubviews: [nameLabel])
        nameLabelStackView.layoutMargins = UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 0)
        nameLabelStackView.isLayoutMarginsRelativeArrangement = true
        let stackView = UIStackView(arrangedSubviews: [logoImageView, nameLabelStackView, arrowStackView])
        addSubview(stackView)
        stackView.fillSuperview(padding: .init(top: 10, left: 10, bottom: 10, right: 10))
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        firstPosition = false
        lastPosition = false
        
    }
    
}
