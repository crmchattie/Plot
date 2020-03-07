//
//  ActivityImageCell.swift
//  Plot
//
//  Created by Cory McHattie on 8/19/19.
//  Copyright © 2019 Immature Creations. All rights reserved.
//

import UIKit

class ActivityImageCell: UICollectionViewCell {
    
    let photoImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.backgroundColor = .clear
        return imageView
    }()
    
    let selectedImageCheck: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.layer.masksToBounds = true
        imageView.contentMode = .scaleAspectFill
        imageView.isHidden = true
        imageView.image = UIImage(named: "checkNav")
        imageView.backgroundColor = .white
        imageView.layer.cornerRadius = 10
        imageView.layer.masksToBounds = true
        
        return imageView
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(photoImageView)
        photoImageView.addSubview(selectedImageCheck)
        photoImageView.anchor(top: topAnchor, left: leftAnchor, bottom: bottomAnchor, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        selectedImageCheck.rightAnchor.constraint(equalTo: photoImageView.rightAnchor, constant: -5).isActive = true
        selectedImageCheck.bottomAnchor.constraint(equalTo: photoImageView.bottomAnchor, constant: -5).isActive = true
        selectedImageCheck.widthAnchor.constraint(equalToConstant: 20).isActive = true
        selectedImageCheck.heightAnchor.constraint(equalToConstant: 20).isActive = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
