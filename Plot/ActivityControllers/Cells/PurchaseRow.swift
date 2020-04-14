//
//  ScheduleRow.swift
//  Pigeon-project
//
//  Created by Cory McHattie on 5/31/19.
//  Copyright © 2019 Immature Creations. All rights reserved.
//

import Eureka

final class PurchaseCell: Cell<Purchase>, CellType {
        
    lazy var nameLabel: UILabel = {
        let label = UILabel()
        label.textColor = ThemeManager.currentTheme().generalTitleColor
        label.font = UIFont.preferredFont(forTextStyle: .callout)
        label.adjustsFontForContentSizeCategory = true
        label.translatesAutoresizingMaskIntoConstraints = false
        label.sizeToFit()
        
        return label
    }()
    
    //activity type label (e.g. drinks, trip)
    lazy var participantsLabal: UILabel = {
        let label = UILabel()
        label.font = UIFont.preferredFont(forTextStyle: .subheadline)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = ThemeManager.currentTheme().generalSubtitleColor
        label.numberOfLines = 1
        label.translatesAutoresizingMaskIntoConstraints = false
        label.sizeToFit()
        
        return label
    }()
    
    lazy var costLabel: UILabel = {
        let label = UILabel()
        label.textColor = ThemeManager.currentTheme().generalTitleColor
        label.font = UIFont.preferredFont(forTextStyle: .callout)
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 1
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isUserInteractionEnabled = true
        label.sizeToFit()
        
        return label
    }()
    
    
    override func setup() {
        height = { 60 }
        // we do not want to show the default UITableViewCell's textLabel
        textLabel?.text = nil
        textLabel?.textColor = .clear
        selectionStyle = .none
        
        backgroundColor = .clear
        contentView.addSubview(nameLabel)
        contentView.addSubview(participantsLabal)
        contentView.addSubview(costLabel)
        
        nameLabel.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 15).isActive = true
        nameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10).isActive = true
        
        costLabel.centerYAnchor.constraint(equalTo: nameLabel.centerYAnchor).isActive = true
        costLabel.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -15).isActive = true
        
        participantsLabal.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 2).isActive = true
        participantsLabal.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 15).isActive = true
        participantsLabal.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10).isActive = true
        
    }
    
    override func update() {
        
        // we do not want to show the default UITableViewCell's textLabel
        textLabel?.text = nil
        
        guard let purchase = row.value else { return }
        

        // set the texts to the labels
        nameLabel.text = purchase.name
        costLabel.text = String(format: "$%.02f", purchase.cost!)
        if purchase.participantsIDs!.count > 1 {
            participantsLabal.text = "Purchase split among \(String(describing: purchase.participantsIDs!.count)) participants"
        } else {
            participantsLabal.text = "Purchase not split"
        }
        
    }
}

final class PurchaseRow: Row<PurchaseCell>, RowType {
    required init(tag: String?) {
        super.init(tag: tag)
    }
}
