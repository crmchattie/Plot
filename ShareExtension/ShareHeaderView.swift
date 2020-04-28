//
//  UserProfileContainerView.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 8/4/17.
//  Copyright © 2017 Roman Mizin. All rights reserved.
//

import UIKit


class ShareHeaderView: UIView {
    
    let navBar: UINavigationBar = {
        let navBar = UINavigationBar()
        navBar.translatesAutoresizingMaskIntoConstraints = false
        navBar.backgroundColor = UIColor(red: 245.0/255.0, green: 245.0/255.0, blue: 245.0/255.0, alpha: 1.0)
        return navBar
    }()
        
    let tableView: UITableView = {
        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        tableView.backgroundColor = UIColor(red: 245.0/255.0, green: 245.0/255.0, blue: 245.0/255.0, alpha: 1.0)
        return tableView
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubview(navBar)
        addSubview(tableView)
        
        NSLayoutConstraint.activate([
            navBar.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            navBar.leftAnchor.constraint(equalTo: leftAnchor),
            navBar.rightAnchor.constraint(equalTo: rightAnchor),
            
            tableView.topAnchor.constraint(equalTo: navBar.bottomAnchor),
            tableView.leftAnchor.constraint(equalTo: leftAnchor),
            tableView.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor),
            tableView.rightAnchor.constraint(equalTo: rightAnchor),
         ])
        
        if #available(iOS 11.0, *) {
            NSLayoutConstraint.activate([
                navBar.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor),
                navBar.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor),
                tableView.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor),
                tableView.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor),
                ])
        } else {
            NSLayoutConstraint.activate([
                navBar.leadingAnchor.constraint(equalTo: leadingAnchor),
                navBar.trailingAnchor.constraint(equalTo: trailingAnchor),
                tableView.leadingAnchor.constraint(equalTo: leadingAnchor),
                tableView.trailingAnchor.constraint(equalTo: trailingAnchor),
                ])
        }
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
    }
}

class ActivityCell: UITableViewCell {
    
    var activity: Activity?
    
    //name of activity
    let nameLabel: UILabel = {
        let label = UILabel()
        label.textColor = .black
        label.font = UIFont.preferredFont(forTextStyle: .headline)
        label.adjustsFontForContentSizeCategory = true
        label.translatesAutoresizingMaskIntoConstraints = false
        label.sizeToFit()
        label.numberOfLines = 0
        return label
    }()
    
    let activityImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.layer.cornerRadius = 4
        imageView.layer.masksToBounds = true
        imageView.contentMode = .scaleAspectFill
        imageView.isUserInteractionEnabled = true
        
        return imageView
    }()
    
    //blue dot on the left of cell
    let newActivityIndicator: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.layer.masksToBounds = true
        imageView.contentMode = .scaleAspectFill
        imageView.isHidden = true
        imageView.image = UIImage(named: "Oval")
        
        return imageView
    }()
    
    let muteIndicator: UIImageView = {
        let muteIndicator = UIImageView()
        muteIndicator.translatesAutoresizingMaskIntoConstraints = false
        muteIndicator.layer.masksToBounds = true
        muteIndicator.contentMode = .scaleAspectFit
        muteIndicator.isHidden = true
        muteIndicator.image = UIImage(named: "mute")
        
        return muteIndicator
    }()
    
    //date/time of activity
    let startLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.preferredFont(forTextStyle: .subheadline)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = .systemGray
        label.translatesAutoresizingMaskIntoConstraints = false
        label.sizeToFit()
        label.textAlignment = .left
        
        return label
    }()
    
    //activity type label (e.g. drinks, trip)
    let activityTypeLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.preferredFont(forTextStyle: .subheadline)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = .systemGray
        label.numberOfLines = 1
        label.translatesAutoresizingMaskIntoConstraints = false
        label.sizeToFit()
        
        return label
    }()
    
    //activity participants label (e.g. whoever is invited to activity)
    let activityParticipantsLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.preferredFont(forTextStyle: .subheadline)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = .systemGray
        label.numberOfLines = 1
        label.translatesAutoresizingMaskIntoConstraints = false
        label.sizeToFit()
        
        return label
    }()
    
    //activity address label (e.g. address of restaurant, initial lodgings with trip)
    let activityAddressLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.preferredFont(forTextStyle: .subheadline)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = .systemGray
        label.numberOfLines = 1
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isUserInteractionEnabled = true
        label.sizeToFit()
        
        return label
    }()
    
    let badgeLabel: UILabel = {
        let badgeLabel = UILabel()
        badgeLabel.translatesAutoresizingMaskIntoConstraints = false
        badgeLabel.backgroundColor = .systemBlue
        badgeLabel.layer.cornerRadius = 10
        badgeLabel.text = "1"
        badgeLabel.isHidden = true
        badgeLabel.textColor = .white
        badgeLabel.textAlignment = .center
        badgeLabel.layer.masksToBounds = true
        badgeLabel.font = UIFont.preferredFont(forTextStyle: .subheadline)
        badgeLabel.adjustsFontForContentSizeCategory = true
        badgeLabel.minimumScaleFactor = 0.1
        badgeLabel.adjustsFontSizeToFitWidth = true
        return badgeLabel
    }()
    
    let activityTypeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(named: "activity"), for: .normal)
        button.isUserInteractionEnabled = false
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    let chatButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(named: "chat"), for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    let mapButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(named: "map"), for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    let invitationSegmentedControl: UISegmentedControl = {
        let items = ["Accept" , "Decline"]
        let segmentedControl = UISegmentedControl(items: items)
        segmentedControl.translatesAutoresizingMaskIntoConstraints = false
        
        return segmentedControl
    }()
    
    var invitationSegmentHeightConstraint: NSLayoutConstraint!
    var invitationSegmentedControlTopAnchor: NSLayoutConstraint!
    let invitationSegmentedControlTopAnchorShowAvatar: CGFloat = 46
    let invitationSegmentedControlTopAnchorRegular: CGFloat = 8
    let invitationSegmentHeightConstant: CGFloat = 0
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .default, reuseIdentifier: reuseIdentifier)
        
        backgroundColor = .white
        contentView.backgroundColor = .white
        
        contentView.addSubview(activityImageView)
        activityImageView.addSubview(nameLabel)
        activityImageView.addSubview(activityTypeLabel)
        activityImageView.addSubview(activityParticipantsLabel)
        activityImageView.addSubview(activityAddressLabel)
        activityImageView.addSubview(startLabel)
        activityImageView.addSubview(muteIndicator)
        activityImageView.addSubview(newActivityIndicator)
        activityImageView.addSubview(invitationSegmentedControl)
        activityImageView.addSubview(badgeLabel)
        activityImageView.addSubview(activityTypeButton)
        activityImageView.addSubview(chatButton)
        activityImageView.addSubview(mapButton)
        
        activityImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4).isActive = true
        activityImageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4).isActive = true
        activityImageView.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 10).isActive = true
        activityImageView.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -10).isActive = true
        
        newActivityIndicator.leftAnchor.constraint(equalTo: activityImageView.leftAnchor, constant: 5).isActive = true
        newActivityIndicator.centerYAnchor.constraint(equalTo: chatButton.centerYAnchor).isActive = true
        newActivityIndicator.widthAnchor.constraint(equalToConstant: 12).isActive = true
        newActivityIndicator.heightAnchor.constraint(equalToConstant: 12).isActive = true
        
        nameLabel.topAnchor.constraint(equalTo: activityImageView.topAnchor, constant: 10).isActive = true
        nameLabel.leftAnchor.constraint(equalTo: activityImageView.leftAnchor, constant: 10).isActive = true
        nameLabel.rightAnchor.constraint(equalTo: activityImageView.rightAnchor, constant: -10).isActive = true
        
        activityTypeButton.topAnchor.constraint(equalTo: activityImageView.topAnchor, constant: 10).isActive = true
        activityTypeButton.rightAnchor.constraint(equalTo: activityImageView.rightAnchor, constant: -5).isActive = true
        activityTypeButton.widthAnchor.constraint(equalToConstant: 30).isActive = true
        activityTypeButton.heightAnchor.constraint(equalToConstant: 30).isActive = true
        
        chatButton.topAnchor.constraint(equalTo: activityTypeButton.bottomAnchor, constant: 10).isActive = true
        chatButton.rightAnchor.constraint(equalTo: activityImageView.rightAnchor, constant: -5).isActive = true
        chatButton.widthAnchor.constraint(equalToConstant: 30).isActive = true
        chatButton.heightAnchor.constraint(equalToConstant: 30).isActive = true
        
        mapButton.topAnchor.constraint(equalTo: chatButton.bottomAnchor, constant: 10).isActive = true
        mapButton.bottomAnchor.constraint(lessThanOrEqualTo: invitationSegmentedControl.topAnchor, constant: -5).isActive = true
        mapButton.rightAnchor.constraint(equalTo: activityImageView.rightAnchor, constant: -5).isActive = true
        mapButton.widthAnchor.constraint(equalToConstant: 30).isActive = true
        mapButton.heightAnchor.constraint(equalToConstant: 30).isActive = true

        startLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 2).isActive = true
        startLabel.leftAnchor.constraint(equalTo: activityImageView.leftAnchor, constant: 10).isActive = true
        startLabel.rightAnchor.constraint(equalTo: activityImageView.rightAnchor, constant: -5).isActive = true
        
        activityTypeLabel.topAnchor.constraint(equalTo: startLabel.bottomAnchor, constant: 2).isActive = true
        activityTypeLabel.leftAnchor.constraint(equalTo: activityImageView.leftAnchor, constant: 10).isActive = true
        activityTypeLabel.rightAnchor.constraint(equalTo: activityImageView.rightAnchor, constant: -5).isActive = true
        
        activityAddressLabel.topAnchor.constraint(equalTo: activityTypeLabel.bottomAnchor, constant: 2).isActive = true
        activityAddressLabel.leftAnchor.constraint(equalTo: activityImageView.leftAnchor, constant: 10).isActive = true
        activityAddressLabel.rightAnchor.constraint(equalTo: activityImageView.rightAnchor, constant: -5).isActive = true
                        
        muteIndicator.leftAnchor.constraint(equalTo: nameLabel.rightAnchor, constant: 3).isActive = true
        muteIndicator.centerYAnchor.constraint(equalTo: nameLabel.centerYAnchor, constant: 1).isActive = true
        muteIndicator.widthAnchor.constraint(equalToConstant: 15).isActive = true
        muteIndicator.heightAnchor.constraint(equalToConstant: 15).isActive = true
        
        badgeLabel.rightAnchor.constraint(equalTo: activityImageView.rightAnchor, constant: -50).isActive = true
        badgeLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 25).isActive = true
        badgeLabel.centerYAnchor.constraint(equalTo: chatButton.centerYAnchor).isActive = true
        
        invitationSegmentedControlTopAnchor = invitationSegmentedControl.topAnchor.constraint(equalTo: activityAddressLabel.bottomAnchor, constant: invitationSegmentedControlTopAnchorRegular)
        invitationSegmentedControlTopAnchor.isActive = true
        invitationSegmentedControl.leftAnchor.constraint(equalTo: activityImageView.leftAnchor, constant: 0).isActive = true
        invitationSegmentedControl.rightAnchor.constraint(equalTo: activityImageView.rightAnchor, constant: 0).isActive = true
        invitationSegmentedControl.bottomAnchor.constraint(equalTo: activityImageView.bottomAnchor, constant: -5).isActive = true
        invitationSegmentHeightConstraint = invitationSegmentedControl.heightAnchor.constraint(equalToConstant: invitationSegmentHeightConstant)
        invitationSegmentHeightConstraint.isActive = true
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        activityImageView.image = nil
        nameLabel.text = ""
        activityTypeLabel.text = nil
        activityParticipantsLabel.text = nil
        activityAddressLabel.text = nil
        startLabel.text = nil
        badgeLabel.isHidden = true
        muteIndicator.isHidden = true
        newActivityIndicator.isHidden = true
        nameLabel.textColor = .black
        activityTypeButton.setImage(UIImage(named: "activity"), for: .normal)
    }
            
    func dateTimeValue(forActivity activity: Activity) -> (Int, String) {
        var value = ""
        var numberOfLines = 1
        if let startDate = activity.startDateTime as? TimeInterval, let endDate = activity.endDateTime as? TimeInterval, let allDay = activity.allDay {
            let startDate = Date(timeIntervalSince1970: startDate)
            let endDate = Date(timeIntervalSince1970: endDate)
            let formatter = DateFormatter()
            formatter.dateFormat = "d"
            formatter.timeZone = TimeZone(identifier: "UTC")
        
            let numberFormatter = NumberFormatter()
            numberFormatter.numberStyle = .ordinal
            
            var startDay = ""
            var day = formatter.string(from: startDate)
            if let integer = Int(day) {
                let number = NSNumber(value: integer)
                startDay = numberFormatter.string(from: number) ?? ""
            }
            
            var endDay = ""
            day = formatter.string(from: endDate)
            if let integer = Int(day) {
                let number = NSNumber(value: integer)
                endDay = numberFormatter.string(from: number) ?? ""
            }
            
            formatter.dateFormat = "EEEE, MMM"
            value += "\(formatter.string(from: startDate)) \(startDay)"
            
            if allDay {
                value += " All Day"
            } else {
                formatter.dateFormat = "h:mm a"
                value += " \(formatter.string(from: startDate))"
            }
            
            if startDate.stripTime().compare(endDate.stripTime()) != .orderedSame {
                value += "\n"
                numberOfLines = 2
                
                formatter.dateFormat = "EEEE, MMM"
                value += "\(formatter.string(from: endDate)) \(endDay) "
                
                if allDay {
                    value += "All Day"
                }
            }

            if !allDay {
                if numberOfLines == 1 {
                    value += "\n"
                    numberOfLines = 2
                }
                
                formatter.dateFormat = "h:mm a"
                value += "\(formatter.string(from: endDate))"
                
            }
        }
        
        return (numberOfLines, value)
    }
    
    func configureCell(for indexPath: IndexPath, activity: Activity) {
        
        backgroundColor = .white
        contentView.backgroundColor = .white
        activityImageView.backgroundColor = .white
        
        self.activity = activity
        
        let isActivityMuted = activity.muted != nil && activity.muted!
        let activityName = activity.name

        nameLabel.text = activityName
        muteIndicator.isHidden = !isActivityMuted
        
        if activity.activityType != "nothing" && activity.activityType != nil {
            activityTypeLabel.text = activity.activityType?.capitalized
        } else {
            activityTypeLabel.text = ""
        }
        
        if activity.locationName != "locationName" && activity.locationName != "Location" && activity.locationName != nil {
            activityAddressLabel.text = activity.locationName
        } else {
            activityAddressLabel.text = ""
        }
        
        let dateTimeValueArray = dateTimeValue(forActivity: activity)
        startLabel.numberOfLines = dateTimeValueArray.0
        startLabel.text = dateTimeValueArray.1
        
        invitationSegmentedControl.isHidden = true
        invitationSegmentHeightConstraint.constant = 0
        
        let topAnchor = invitationSegmentedControlTopAnchorShowAvatar
        invitationSegmentedControlTopAnchor.constant = topAnchor
        
                
        if activity.recipeID != nil {
            activityTypeButton.setImage(UIImage(named: "meal"), for: .normal)
        } else if activity.workoutID != nil {
            activityTypeButton.setImage(UIImage(named: "workout"), for: .normal)
        } else if activity.eventID != nil {
            activityTypeButton.setImage(UIImage(named: "event"), for: .normal)
        } else {
            activityTypeButton.setImage(UIImage(named: "activity"), for: .normal)
        }
                
        newActivityIndicator.isHidden = true
        badgeLabel.isHidden = true
                
        if activity.locationAddress == nil {
            mapButton.tintColor = .systemGray
        } else {
            mapButton.tintColor = .systemBlue
        }

        if activity.conversationID == nil {
            chatButton.tintColor = .systemGray
        } else {
            chatButton.tintColor = .systemBlue
        }
    }

}

extension Date {
    func stripTime() -> Date {
        let timeZone = TimeZone.current
        let timeIntervalWithTimeZone = self.timeIntervalSinceReferenceDate + Double(timeZone.secondsFromGMT())
        let timeInterval = floor(timeIntervalWithTimeZone / 86399) * 86400
        return Date(timeIntervalSinceReferenceDate: timeInterval)
    }
    
    func formatRelativeString() -> String {
         let dateFormatter = DateFormatter()
         let calendar = Calendar(identifier: .gregorian)
         dateFormatter.doesRelativeDateFormatting = true

         if calendar.isDateInToday(self) {
             dateFormatter.timeStyle = .short
             dateFormatter.dateStyle = .none
         } else if calendar.isDateInYesterday(self){
             dateFormatter.timeStyle = .none
             dateFormatter.dateStyle = .medium
         } else if calendar.compare(Date(), to: self, toGranularity: .weekOfYear) == .orderedSame {
             let weekday = calendar.dateComponents([.weekday], from: self).weekday ?? 0
             return dateFormatter.weekdaySymbols[weekday-1]
         } else {
             dateFormatter.timeStyle = .none
             dateFormatter.dateStyle = .short
         }

         return dateFormatter.string(from: self)
     }
    
    func startDateTimeString() -> String {
        var value = ""
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
    
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .ordinal
        
        var startDay = ""
        let day = formatter.string(from: self)
        if let integer = Int(day) {
            let number = NSNumber(value: integer)
            startDay = numberFormatter.string(from: number) ?? ""
        }
        
        formatter.dateFormat = "EEEE, MMM"
        value += "\(formatter.string(from: self)) \(startDay)"
        
        formatter.dateFormat = "h:mm a"
        if " \(formatter.string(from: self))" != "12:00 AM" {
            value += " \(formatter.string(from: self))"
        }
            
        return (value)
    
    }
    
    func toString(dateFormat format: String ) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = format
        return dateFormatter.string(from: self)
    }

}
