//
//  SelectedActivityImageCell.swift
//  Plot
//
//  Created by Cory McHattie on 8/19/19.
//  Copyright © 2019 Immature Creations. All rights reserved.
//

import UIKit

class SelectedActivityImageCell: UICollectionViewCell {
    
    let photoImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.backgroundColor = .clear
        return iv
    }()
    
    let selectedImageCheck: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.layer.masksToBounds = true
        imageView.contentMode = .scaleAspectFill
        imageView.isHidden = true
        imageView.image = UIImage(named: "checkNav")
        
        return imageView
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(photoImageView)
        photoImageView.addSubview(selectedImageCheck)
        photoImageView.anchor(top: topAnchor, left: leftAnchor, bottom: bottomAnchor, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        selectedImageCheck.rightAnchor.constraint(equalTo: photoImageView.leftAnchor, constant: 11).isActive = true
        selectedImageCheck.centerYAnchor.constraint(equalTo: photoImageView.centerYAnchor).isActive = true
        selectedImageCheck.widthAnchor.constraint(equalToConstant: 10).isActive = true
        selectedImageCheck.heightAnchor.constraint(equalToConstant: 10).isActive = true
        selectedImageCheck.isHidden = true
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
