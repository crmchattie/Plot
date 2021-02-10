//
//  BaseContainerCell.swift
//  Plot
//
//  Created by Cory McHattie on 12/22/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import UIKit

class BaseContainerCollectionViewCell: UICollectionViewCell {
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupViews() {
        self.backgroundView = UIView()
        addSubview(self.backgroundView!)
        self.backgroundView?.fillSuperview()
        self.backgroundView?.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
        self.backgroundView?.layer.cornerRadius = 10
        self.backgroundView?.layer.masksToBounds = true
        self.backgroundView?.layer.shadowOpacity = 0.1
        self.backgroundView?.layer.shadowRadius = 10
        self.backgroundView?.layer.shadowOffset = .init(width: 0, height: 10)
        self.backgroundView?.layer.shouldRasterize = true
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        self.backgroundView?.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
    }
    
}

class BaseContainerTableViewCell: UITableViewCell {
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .default, reuseIdentifier: reuseIdentifier)
        setupViews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupViews() {
        self.backgroundView = UIView()
        addSubview(self.backgroundView!)
        self.backgroundView?.fillSuperview()
        self.backgroundView?.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
        self.backgroundView?.layer.cornerRadius = 10
        self.backgroundView?.layer.masksToBounds = true
        self.backgroundView?.layer.shadowOpacity = 0.1
        self.backgroundView?.layer.shadowRadius = 10
        self.backgroundView?.layer.shadowOffset = .init(width: 0, height: 10)
        self.backgroundView?.layer.shouldRasterize = true
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        self.backgroundView?.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
    }
}
