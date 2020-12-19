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
            nameLabel.textColor = ThemeManager.currentTheme().generalTitleColor
            nameLabel.text = activityType.name
            logoImageView.image = UIImage(named: activityType.image)!.withRenderingMode(.alwaysTemplate)
            logoImageView.tintColor = colors[intColor]
            logoImageView.contentMode = .scaleAspectFit
            setupViews()
        }
    }
    
    let nameLabel: UILabel = {
        let label = UILabel()
        label.textColor = ThemeManager.currentTheme().generalTitleColor
        label.font = UIFont.boldSystemFont(ofSize: 20)
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
        imageView.tintColor = ThemeManager.currentTheme().generalSubtitleColor
        return imageView
    }()
    
    func setupViews() {
        logoImageView.constrainWidth(40)
        logoImageView.constrainHeight(40)
        
        arrowView.constrainWidth(20)
        arrowView.constrainHeight(20)
        
        let nameLabelStackView = UIStackView(arrangedSubviews: [nameLabel])
        nameLabelStackView.layoutMargins = UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 0)
        nameLabelStackView.isLayoutMarginsRelativeArrangement = true
        let stackView = UIStackView(arrangedSubviews: [logoImageView, nameLabelStackView, arrowView])
        addSubview(stackView)
        stackView.fillSuperview(padding: .init(top: 0, left: 0, bottom: 0, right: 0))
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
}
