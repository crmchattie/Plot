//
//  ScheduleRow.swift
//  Pigeon-project
//
//  Created by Cory McHattie on 5/31/19.
//  Copyright © 2019 Immature Creations. All rights reserved.
//

import Eureka

final class PurchaseCell: Cell<Transaction>, CellType {
        
    lazy var nameLabel: UILabel = {
        let label = UILabel()
        label.textColor = ThemeManager.currentTheme().generalTitleColor
        label.font = UIFont.preferredFont(forTextStyle: .callout)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    //activity type label (e.g. drinks, trip)
    lazy var participantsLabal: UILabel = {
        let label = UILabel()
        label.font = UIFont.preferredFont(forTextStyle: .subheadline)
        label.textColor = ThemeManager.currentTheme().generalSubtitleColor
        label.numberOfLines = 1
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    lazy var costLabel: UILabel = {
        let label = UILabel()
        label.textColor = ThemeManager.currentTheme().generalTitleColor
        label.font = UIFont.preferredFont(forTextStyle: .callout)
        label.numberOfLines = 1
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    
    override func setup() {
        height = { 60 }
        // we do not want to show the default UITableViewCell's textLabel
        textLabel?.text = nil
        textLabel?.textColor = .clear
        
        backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
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
        
        guard let transaction = row.value else { return }
        
        // set the texts to the labels
        nameLabel.text = transaction.description
        costLabel.text = String(format: "$%.02f", transaction.amount)
//        if let purchaseRowCount = transaction.splitNumber {
//            participantsLabal.text = "Purchase split among \(purchaseRowCount) participants"
//        } else if let participants = transaction.participantsIDs, participants.count > 1 {
//            participantsLabal.text = "Purchase split among \(participants.count) participants"
//        } else {
//            participantsLabal.text = "Purchase not split"
//        }
        
    }
}

final class PurchaseRow: Row<PurchaseCell>, RowType {
    required init(tag: String?) {
        super.init(tag: tag)
    }
}
