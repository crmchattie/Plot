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
    
    override var isHighlighted: Bool {
        didSet {
            self.backgroundView?.backgroundColor = .secondarySystemGroupedBackground.withAlphaComponent(isHighlighted ? 0.7 : 1)
        }
    }
        
    func setupViews() {
        self.backgroundView = UIView()
        addSubview(self.backgroundView!)
        self.backgroundView?.fillSuperview()
        self.backgroundView?.backgroundColor = .secondarySystemGroupedBackground
        self.backgroundView?.layer.cornerRadius = 10
        self.backgroundView?.layer.masksToBounds = true
    }
            
    override func prepareForReuse() {
        super.prepareForReuse()
        self.backgroundView?.backgroundColor = .secondarySystemGroupedBackground
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
        self.backgroundView?.backgroundColor = .secondarySystemGroupedBackground
        self.backgroundView?.layer.cornerRadius = 10
        self.backgroundView?.layer.masksToBounds = true
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        self.backgroundView?.backgroundColor = .secondarySystemGroupedBackground
    }
    
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        self.backgroundView?.backgroundColor = .secondarySystemGroupedBackground.withAlphaComponent(highlighted ? 0.7 : 1)
    }
}
