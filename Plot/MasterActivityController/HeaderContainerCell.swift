//
//  HeaderContainerCell.swift
//  Plot
//
//  Created by Cory McHattie on 12/22/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

class HeaderContainerCell: UICollectionReusableView {
    var titleLabel: UILabel = {
        let label: UILabel = UILabel()
        label.textColor = ThemeManager.currentTheme().generalTitleColor
        label.font = .boldSystemFont(ofSize: 30)
        label.sizeToFit()
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubview(titleLabel)
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        titleLabel.leftAnchor.constraint(equalTo: self.leftAnchor, constant: 25).isActive = true
        titleLabel.rightAnchor.constraint(equalTo: self.rightAnchor).isActive = true
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        titleLabel.textColor = ThemeManager.currentTheme().generalTitleColor
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
