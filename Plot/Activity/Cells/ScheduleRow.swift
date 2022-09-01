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
        height = { 60 }
        // we do not want to show the default UITableViewCell's textLabel
        textLabel?.text = nil

        guard let schedule = row.value else { return }

        nameLabel.text = schedule.name

        if let startDate = schedule.startDate, let endDate = schedule.endDate, let allDay = schedule.allDay {
            let startTimeZone = schedule.startTimeZone ?? "UTC"
            let endTimeZone = schedule.endTimeZone ?? "UTC"
            formattedDate = timestampOfEvent(startDate: startDate, endDate: endDate, allDay: allDay, startTimeZone: startTimeZone, endTimeZone: endTimeZone)
        }
        // set the texts to the labels
        dateTimeLabel.text = formattedDate.0 + formattedDate.1
        if schedule.locationName != "locationName" {
            locationNameLabel.text = schedule.locationName
        }
        
        
        if let categoryValue = schedule.category, let category = ActivityCategory(rawValue: categoryValue) {
            activityTypeButton.setImage(category.icon, for: .normal)
            if category == .uncategorized {
                activityTypeButton.setImage(UIImage(named: "event"), for: .normal)
            }
        } else {
            activityTypeButton.setImage(UIImage(named: "event"), for: .normal)
        }
        
        activityTypeButton.tintColor = .systemBlue
        if let color = schedule.calendarColor {
            activityTypeButton.tintColor = UIColor(ciColor: CIColor(string: color))
        }
    }
}

final class ScheduleRow: Row<ScheduleCell>, RowType {
        required init(tag: String?) {
            super.init(tag: tag)
    }
}
