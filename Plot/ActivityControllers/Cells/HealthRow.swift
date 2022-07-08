//
//  HealthRow.swift
//  Plot
//
//  Created by Cory McHattie on 7/5/22.
//  Copyright © 2022 Immature Creations. All rights reserved.
//

import Eureka

final class HealthCell: Cell<HealthContainer>, CellType {
        
    lazy var nameLabel: UILabel = {
        let label = UILabel()
        label.textColor = ThemeManager.currentTheme().generalTitleColor
        label.font = UIFont.preferredFont(forTextStyle: .callout)
        label.adjustsFontForContentSizeCategory = true
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        return label
    }()
    
    lazy var subLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.preferredFont(forTextStyle: .subheadline)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = ThemeManager.currentTheme().generalSubtitleColor
        label.numberOfLines = 1
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isUserInteractionEnabled = true
        
        return label
    }()

    //blue dot on the left of cell
    let activityTypeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(named: "activity"), for: .normal)
        button.isUserInteractionEnabled = false
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    override func setup() {
        // we do not want to show the default UITableViewCell's textLabel
        textLabel?.text = nil
        textLabel?.textColor = .clear
        
        backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
        contentView.addSubview(nameLabel)
        contentView.addSubview(subLabel)
        contentView.addSubview(activityTypeButton)
        
        nameLabel.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 15).isActive = true
        nameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10).isActive = true
        nameLabel.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -15).isActive = true
        
        subLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 2).isActive = true
        subLabel.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 15).isActive = true
        subLabel.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -15).isActive = true
        
        activityTypeButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor).isActive = true
        activityTypeButton.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -10).isActive = true
        activityTypeButton.widthAnchor.constraint(equalToConstant: 30).isActive = true
        activityTypeButton.heightAnchor.constraint(equalToConstant: 30).isActive = true
                
    }
    
    override func update() {
        // we do not want to show the default UITableViewCell's textLabel
        textLabel?.text = nil

        guard let healthMetric = row.value else { return }
        
        nameLabel.text = healthMetric.name

        
//        switch schedule.activityType?.lowercased() {
//        case "recipe":
//            activityTypeButton.setImage(UIImage(named: "recipe"), for: .normal)
//        case "workout":
//            activityTypeButton.setImage(UIImage(named: "workout"), for: .normal)
//        case "event":
//            activityTypeButton.setImage(UIImage(named: "event"), for: .normal)
//        case "sleep":
//            activityTypeButton.setImage(UIImage(named: "sleep"), for: .normal)
//        case "work":
//            activityTypeButton.setImage(UIImage(named: "work"), for: .normal)
//        case "food":
//            activityTypeButton.setImage(UIImage(named: "food"), for: .normal)
//        case "meal":
//            activityTypeButton.setImage(UIImage(named: "food"), for: .normal)
//        case "nightlife":
//            activityTypeButton.setImage(UIImage(named: "nightlife"), for: .normal)
//        case "recreation":
//            activityTypeButton.setImage(UIImage(named: "recreation"), for: .normal)
//        case "shopping":
//            activityTypeButton.setImage(UIImage(named: "shopping"), for: .normal)
//        case "sightseeing":
//            activityTypeButton.setImage(UIImage(named: "sightseeing"), for: .normal)
//        case "mindfulness":
//            activityTypeButton.setImage(UIImage(named: "sightseeing"), for: .normal)
//        default:
//            activityTypeButton.setImage(UIImage(named: "activity"), for: .normal)
//        }
        
    }
}

final class HealthRow: Row<HealthCell>, RowType {
        required init(tag: String?) {
            super.init(tag: tag)
    }
}
