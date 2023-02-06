//
//  NewTaskCell.swift
//  Plot
//
//  Created by Cory McHattie on 8/29/22.
//  Copyright © 2022 Immature Creations. All rights reserved.
//

import UIKit

class NewTaskCell: UITableViewCell {
    let activityImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.layer.cornerRadius = 10
        imageView.layer.masksToBounds = true
        imageView.contentMode = .scaleAspectFill
        imageView.isUserInteractionEnabled = true
        return imageView
    }()
    
    let nameLabel: UILabel = {
        let label = UILabel()
        label.textColor = .label
        label.text = "New Item"
        label.font = UIFont.preferredFont(forTextStyle: .headline)
        label.adjustsFontForContentSizeCategory = true
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 1
        return label
    }()
    
    let plusView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    let plusImage: UIImageView = {
        let view = UIImageView()
        view.tintColor = .secondaryLabel
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    let plusConfiguration = UIImage.SymbolConfiguration(weight: .medium)

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .default, reuseIdentifier: reuseIdentifier)
        selectionStyle = .default
        contentView.backgroundColor = .systemGroupedBackground
        
        contentView.heightAnchor.constraint(greaterThanOrEqualToConstant: 73).isActive = true

        contentView.addSubview(activityImageView)
        contentView.addSubview(nameLabel)
        activityImageView.addSubview(plusView)
        plusView.addSubview(plusImage)

        activityImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 5).isActive = true
        activityImageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -5).isActive = true
        activityImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor).isActive = true
        activityImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor).isActive = true
        
        plusView.topAnchor.constraint(equalTo: activityImageView.topAnchor, constant: 0).isActive = true
        plusView.leftAnchor.constraint(equalTo: activityImageView.leftAnchor, constant: 0).isActive = true
        plusView.bottomAnchor.constraint(equalTo: activityImageView.bottomAnchor, constant: 0).isActive = true
        plusView.widthAnchor.constraint(equalToConstant: 40).isActive = true

        plusImage.centerYAnchor.constraint(equalTo: plusView.centerYAnchor, constant: 0).isActive = true
        plusImage.leadingAnchor.constraint(equalTo: plusView.leadingAnchor, constant: 10).isActive = true
        plusImage.widthAnchor.constraint(equalToConstant: 30).isActive = true
        plusImage.heightAnchor.constraint(equalToConstant: 30).isActive = true
        
        nameLabel.centerYAnchor.constraint(equalTo: activityImageView.centerYAnchor, constant: 0).isActive = true
        nameLabel.leftAnchor.constraint(equalTo: plusView.rightAnchor, constant: 10).isActive = true
        
        plusImage.image = UIImage(systemName: "plus.circle", withConfiguration: plusConfiguration)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        contentView.backgroundColor = .systemGroupedBackground
    }
    
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        activityImageView.backgroundColor = .secondarySystemGroupedBackground.withAlphaComponent(highlighted ? 0.7 : 1)
    }
    
}
