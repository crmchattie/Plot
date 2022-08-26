//
//  SignInAppleGoogleTableViewCell.swift
//  Plot
//
//  Created by Cory McHattie on 8/26/22.
//  Copyright © 2022 Immature Creations. All rights reserved.
//

import UIKit

class SignInAppleGoogleTableViewCell: UITableViewCell {    
    var iconView: UIView = {
        var iconView = UIView()
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.backgroundColor = .white
        return iconView
    }()
    
    var icon: UIImageView = {
        var icon = UIImageView()
        icon.translatesAutoresizingMaskIntoConstraints = false
        icon.contentMode = .scaleAspectFit
        return icon
    }()
    
    var title: UILabel = {
        var title = UILabel()
        title.translatesAutoresizingMaskIntoConstraints = false
        title.adjustsFontForContentSizeCategory = true
        title.textColor = ThemeManager.currentTheme().generalTitleColor
        return title
    }()
    
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
        
        setColor()
        contentView.addSubview(iconView)
        iconView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor, constant: 0).isActive = true
        iconView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 0).isActive = true
        iconView.widthAnchor.constraint(equalToConstant: 62).isActive = true
        iconView.heightAnchor.constraint(equalToConstant: 50).isActive = true

        iconView.addSubview(icon)
        icon.centerYAnchor.constraint(equalTo: iconView.centerYAnchor, constant: 0).isActive = true
        icon.leadingAnchor.constraint(equalTo: iconView.leadingAnchor, constant: 16).isActive = true
        icon.widthAnchor.constraint(equalToConstant: 30).isActive = true
        icon.heightAnchor.constraint(equalToConstant: 30).isActive = true
        
        contentView.addSubview(title)
        title.centerYAnchor.constraint(equalTo: iconView.centerYAnchor, constant: 0).isActive = true
        title.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 24).isActive = true
        title.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -15).isActive = true
        title.heightAnchor.constraint(equalToConstant: 30).isActive = true
        
    }
    
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    fileprivate func setColor() {
        title.textColor = ThemeManager.currentTheme().generalTitleColor
        iconView.backgroundColor = .white
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        setColor()
    }
}
