//
//  ScheduleRow.swift
//  Pigeon-project
//
//  Created by Cory McHattie on 5/31/19.
//  Copyright © 2019 Immature Creations. All rights reserved.
//

import Eureka

class ChatActivitiesTableViewCell: UITableViewCell {
    
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
    
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
        // we do not want to show the default UITableViewCell's textLabel
        
        backgroundColor = .clear
        contentView.addSubview(nameLabel)
        contentView.addSubview(locationNameLabel)
        contentView.addSubview(startTimeLabel)
        contentView.addSubview(endTimeLabel)
        
        nameLabel.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 15).isActive = true
        nameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10).isActive = true
        
        locationNameLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 2).isActive = true
        locationNameLabel.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 15).isActive = true
        locationNameLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10).isActive = true
        
        startTimeLabel.centerYAnchor.constraint(equalTo: nameLabel.centerYAnchor).isActive = true
        startTimeLabel.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -15).isActive = true
        
        endTimeLabel.centerYAnchor.constraint(equalTo: locationNameLabel.centerYAnchor).isActive = true
        endTimeLabel.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -15).isActive = true
    }
    
    required init?(coder aDecoder: NSCoder) {
      fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
      super.prepareForReuse()
    
      nameLabel.text = ""
      locationNameLabel.text = ""
      startTimeLabel.text = ""
      endTimeLabel.text = ""
      nameLabel.textColor = ThemeManager.currentTheme().generalTitleColor
      locationNameLabel.textColor = ThemeManager.currentTheme().generalSubtitleColor
      startTimeLabel.textColor = ThemeManager.currentTheme().generalSubtitleColor
      endTimeLabel.textColor = ThemeManager.currentTheme().generalSubtitleColor
    }
    
    func configureCell(for activity: Activity) {
        if let startDate = activity.startDateTime as? TimeInterval, let endDate = activity.endDateTime as? TimeInterval, let allDay = activity.allDay {
          let startDate = Date(timeIntervalSince1970: startDate)
          let endDate = Date(timeIntervalSince1970: endDate)
          formattedDate = timestampOfActivity(startDate: startDate, endDate: endDate, allDay: allDay)
        }

          
          // set the texts to the labels
        nameLabel.text = activity.name
        if activity.locationName != "locationName" {
            locationNameLabel.text = activity.locationName
        } else {
            locationNameLabel.text = " "
        }
        startTimeLabel.text = formattedDate.0
        endTimeLabel.text = formattedDate.1
    }
}
