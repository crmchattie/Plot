//
//  CreateActivityView.swift
//  Pigeon-project
//
//  Created by Cory McHattie on 4/28/19.
//  Copyright © 2019 Immature Creations. All rights reserved.
//

import UIKit

class CreateActivityView: UIView {
    
    lazy var activityImageView: UIImageView = {
        let view = UIImageView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.contentMode = .scaleAspectFill
        view.isUserInteractionEnabled = true
        
        return view
    }()
    
    let addPhotoLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Add Photo"
        label.font = UIFont.preferredFont(forTextStyle: .body)
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 1
        label.textColor = FalconPalette.defaultBlue
        label.textAlignment = .center
        
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
        addSubview(activityImageView)
        activityImageView.addSubview(addPhotoLabel)

        NSLayoutConstraint.activate([
            activityImageView.topAnchor.constraint(equalTo: topAnchor, constant: 10),
            activityImageView.widthAnchor.constraint(equalTo: widthAnchor),
            activityImageView.heightAnchor.constraint(equalToConstant: 200),
            
            addPhotoLabel.topAnchor.constraint(equalTo: activityImageView.topAnchor),
            addPhotoLabel.widthAnchor.constraint(equalTo: activityImageView.widthAnchor),
            addPhotoLabel.heightAnchor.constraint(equalTo: activityImageView.heightAnchor),
            ])
        
        if #available(iOS 11.0, *) {
            NSLayoutConstraint.activate([
//                activityImageView.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: 10),
//                activityImageView.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: -10),
//                addPhotoLabel.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: 10),
//                addPhotoLabel.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: -10),
                ])
        } else {
            NSLayoutConstraint.activate([
//                activityImageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
//                activityImageView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
//                addPhotoLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
//                addPhotoLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
                ])
        }
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
    }
}

