//
//  ScheduleRow.swift
//  Pigeon-project
//
//  Created by Cory McHattie on 5/31/19.
//  Copyright © 2019 Immature Creations. All rights reserved.
//

import Eureka

final class ScheduleCell: Cell<Schedule>, CellType {
    
    var formattedDate: (String, String) = ("", "")
    var allDay: Bool = false
    
    lazy var nameLabel: UILabel = {
        let label = UILabel()
        label.textColor = ThemeManager.currentTheme().generalTitleColor
        //        label.font = UIFont.systemFont(ofSize: 15, weight: UIFont.Weight.semibold)
        label.font = UIFont.preferredFont(forTextStyle: .headline)
        label.adjustsFontForContentSizeCategory = true
        label.minimumScaleFactor = 0.1
        label.adjustsFontSizeToFitWidth = true
        label.translatesAutoresizingMaskIntoConstraints = false
        label.sizeToFit()
        
        return label
    }()
    
    //activity type label (e.g. drinks, trip)
    lazy var locationNameLabel: UILabel = {
        let label = UILabel()
        //        label.font = UIFont.systemFont(ofSize: 13)
        label.font = UIFont.preferredFont(forTextStyle: .subheadline)
        label.adjustsFontForContentSizeCategory = true
        label.minimumScaleFactor = 0.1
        label.adjustsFontSizeToFitWidth = true
        label.textColor = ThemeManager.currentTheme().generalSubtitleColor
        label.numberOfLines = 1
        label.translatesAutoresizingMaskIntoConstraints = false
        label.sizeToFit()
        
        return label
    }()
    
    
    lazy var startTimeLabel: UILabel = {
        let label = UILabel()
        //        label.font = UIFont.systemFont(ofSize: 13)
        label.font = UIFont.preferredFont(forTextStyle: .subheadline)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = ThemeManager.currentTheme().generalSubtitleColor
        label.numberOfLines = 1
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isUserInteractionEnabled = true
        label.sizeToFit()
        
        return label
    }()
    
    lazy var endTimeLabel: UILabel = {
        let label = UILabel()
        //        label.font = UIFont.systemFont(ofSize: 13)
        label.font = UIFont.preferredFont(forTextStyle: .subheadline)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = ThemeManager.currentTheme().generalSubtitleColor
        label.numberOfLines = 1
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isUserInteractionEnabled = true
        label.sizeToFit()
        
        return label
    }()
    
    //blue dot on the left of cell
    let newScheduleIndicator: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.layer.masksToBounds = true
        imageView.contentMode = .scaleAspectFill
        imageView.isHidden = true
        imageView.image = UIImage(named: "Oval")
        
        return imageView
    }()
    
    override func setup() {
        height = { 60 }
        // we do not want to show the default UITableViewCell's textLabel
        textLabel?.text = nil
        textLabel?.textColor = .clear
        selectionStyle = .none
        
        backgroundColor = .clear
        contentView.addSubview(nameLabel)
        contentView.addSubview(locationNameLabel)
        contentView.addSubview(startTimeLabel)
        contentView.addSubview(endTimeLabel)
        contentView.addSubview(newScheduleIndicator)
        
        nameLabel.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 15).isActive = true
        nameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10).isActive = true
//        nameLabel.widthAnchor.constraint(equalToConstant: 60).isActive = true
//        nameLabel.heightAnchor.constraint(equalToConstant: 60).isActive = true
        
        locationNameLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 2).isActive = true
        locationNameLabel.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 15).isActive = true
        locationNameLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10).isActive = true
        
        newScheduleIndicator.rightAnchor.constraint(equalTo: nameLabel.leftAnchor, constant: -7).isActive = true
        newScheduleIndicator.centerYAnchor.constraint(equalTo: contentView.centerYAnchor).isActive = true
        newScheduleIndicator.widthAnchor.constraint(equalToConstant: 12).isActive = true
        newScheduleIndicator.heightAnchor.constraint(equalToConstant: 12).isActive = true
        
        startTimeLabel.centerYAnchor.constraint(equalTo: nameLabel.centerYAnchor).isActive = true
        startTimeLabel.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -15).isActive = true
        
        endTimeLabel.centerYAnchor.constraint(equalTo: locationNameLabel.centerYAnchor).isActive = true
        endTimeLabel.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -15).isActive = true
    }
    
    override func update() {
        
        // we do not want to show the default UITableViewCell's textLabel
        textLabel?.text = nil

        guard let schedule = row.value else { return }

        
        if let startDate = schedule.startDateTime as? TimeInterval, let endDate = schedule.endDateTime as? TimeInterval, let allDay = schedule.allDay {
            let startDate = Date(timeIntervalSince1970: startDate)
            let endDate = Date(timeIntervalSince1970: endDate)
            formattedDate = timestampOfActivity(startDate: startDate, endDate: endDate, allDay: allDay)
        }

        
        // set the texts to the labels
        nameLabel.text = schedule.name
        if schedule.locationName != "locationName" {
            locationNameLabel.text = schedule.locationName
        } else {
            locationNameLabel.text = " "
        }
        startTimeLabel.text = formattedDate.0
        endTimeLabel.text = formattedDate.1
        
    }
}

final class ScheduleRow: Row<ScheduleCell>, RowType {
        required init(tag: String?) {
            super.init(tag: tag)
    }
}
