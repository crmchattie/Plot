//
//  ChatListTableViewCell.swift
//  Plot
//
//  Created by Cory McHattie on 5/25/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import UIKit

class ChatListTableViewCell: UITableViewCell {
    
    lazy var nameLabel: UILabel = {
        let label = UILabel()
        label.textColor = .label
        label.font = UIFont.preferredFont(forTextStyle: .headline)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.adjustsFontForContentSizeCategory = true
        return label
    }()
    
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
        // we do not want to show the default UITableViewCell's textLabel
        
        backgroundColor = .clear
        contentView.addSubview(nameLabel)
        
        nameLabel.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 15).isActive = true
        nameLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor).isActive = true
        nameLabel.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -15).isActive = true
        
    }
    
    required init?(coder aDecoder: NSCoder) {
      fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
      super.prepareForReuse()
      nameLabel.text = ""
      nameLabel.textColor = .label
    }
    
    func configureCell(checklist: Checklist?, grocerylist: Grocerylist?, packinglist: Packinglist?, activitylist: Activitylist?) {
        if let grocerylist = grocerylist {
            nameLabel.text = grocerylist.name
        } else if let checklist = checklist {
            nameLabel.text = checklist.name
        } else if let activitylist = activitylist {
            nameLabel.text = activitylist.name
        } else if let packinglist = packinglist {
            nameLabel.text = packinglist.name
        }
    }
}
