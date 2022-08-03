//
//  ScheduleRow.swift
//  Pigeon-project
//
//  Created by Cory McHattie on 5/31/19.
//  Copyright © 2019 Immature Creations. All rights reserved.
//

import Eureka

final class ScheduleCell: Cell<Activity>, CellType {
    
    var formattedDate: (String, String) = ("", "")
    var allDay: Bool = false
    
    lazy var nameLabel: UILabel = {
        let label = UILabel()
        label.textColor = ThemeManager.currentTheme().generalTitleColor
        label.font = UIFont.preferredFont(forTextStyle: .callout)
        label.adjustsFontForContentSizeCategory = true
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        return label
    }()
    
    //activity type label (e.g. drinks, trip)
    lazy var locationNameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.preferredFont(forTextStyle: .subheadline)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = ThemeManager.currentTheme().generalSubtitleColor
        label.numberOfLines = 1
        label.translatesAutoresizingMaskIntoConstraints = false
        
        return label
    }()
    
    lazy var dateTimeLabel: UILabel = {
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
        contentView.addSubview(dateTimeLabel)
        contentView.addSubview(locationNameLabel)
        contentView.addSubview(activityTypeButton)
        
        nameLabel.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 15).isActive = true
        nameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10).isActive = true
        nameLabel.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -15).isActive = true
        
        dateTimeLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 2).isActive = true
        dateTimeLabel.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 15).isActive = true
        dateTimeLabel.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -15).isActive = true
                        
        locationNameLabel.topAnchor.constraint(equalTo: dateTimeLabel.bottomAnchor, constant: 2).isActive = true
        locationNameLabel.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 15).isActive = true
        locationNameLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10).isActive = true
        locationNameLabel.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -15).isActive = true
        
        activityTypeButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor).isActive = true
        activityTypeButton.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -10).isActive = true
        activityTypeButton.widthAnchor.constraint(equalToConstant: 30).isActive = true
        activityTypeButton.heightAnchor.constraint(equalToConstant: 30).isActive = true
                
    }
    
    override func update() {
        // we do not want to show the default UITableViewCell's textLabel
        textLabel?.text = nil

        guard let schedule = row.value else { return }
                
        if let startDate = schedule.startDateTime as? TimeInterval, let endDate = schedule.endDateTime as? TimeInterval, let allDay = schedule.allDay {
            let startTimeZone = schedule.startTimeZone ?? "UTC"
            let endTimeZone = schedule.endTimeZone ?? "UTC"
            let startDate = Date(timeIntervalSince1970: startDate)
            let endDate = Date(timeIntervalSince1970: endDate)
            formattedDate = timestampOfActivity(startDate: startDate, endDate: endDate, allDay: allDay, startTimeZone: startTimeZone, endTimeZone: endTimeZone)
        }
        // set the texts to the labels
        nameLabel.text = schedule.name
        dateTimeLabel.text = formattedDate.0 + formattedDate.1
        if schedule.locationName != "locationName" {
            locationNameLabel.text = schedule.locationName
        }
        
        switch schedule.activityType?.lowercased() {
        case "recipe":
            activityTypeButton.setImage(UIImage(named: "recipe"), for: .normal)
        case "workout":
            activityTypeButton.setImage(UIImage(named: "workout"), for: .normal)
        case "event":
            activityTypeButton.setImage(UIImage(named: "event"), for: .normal)
        case "sleep":
            activityTypeButton.setImage(UIImage(named: "sleep"), for: .normal)
        case "work":
            activityTypeButton.setImage(UIImage(named: "work"), for: .normal)
        case "food":
            activityTypeButton.setImage(UIImage(named: "food"), for: .normal)
        case "meal":
            activityTypeButton.setImage(UIImage(named: "food"), for: .normal)
        case "nightlife":
            activityTypeButton.setImage(UIImage(named: "nightlife"), for: .normal)
        case "recreation":
            activityTypeButton.setImage(UIImage(named: "recreation"), for: .normal)
        case "shopping":
            activityTypeButton.setImage(UIImage(named: "shopping"), for: .normal)
        case "sightseeing":
            activityTypeButton.setImage(UIImage(named: "sightseeing"), for: .normal)
        case "mindfulness":
            activityTypeButton.setImage(UIImage(named: "sightseeing"), for: .normal)
        default:
            activityTypeButton.setImage(UIImage(named: "activity"), for: .normal)
        }
        
    }
}

final class ScheduleRow: Row<ScheduleCell>, RowType {
        required init(tag: String?) {
            super.init(tag: tag)
    }
}
