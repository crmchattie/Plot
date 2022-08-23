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
        let tableView = UITableView(frame: .zero, style: .insetGrouped)
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

class EventCell: UITableViewCell {
    
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
    
    let activityTypeLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.preferredFont(forTextStyle: .subheadline)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = .systemGray
        label.numberOfLines = 1
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    var invitationSegmentHeightConstraint: NSLayoutConstraint!
    var invitationSegmentedControlTopAnchor: NSLayoutConstraint!
    let invitationSegmentedControlTopAnchorRegular: CGFloat = 0
    let invitationSegmentHeightConstant: CGFloat = 0
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .default, reuseIdentifier: reuseIdentifier)
                
        contentView.addSubview(activityImageView)
        activityImageView.addSubview(nameLabel)
        activityImageView.addSubview(startLabel)
        activityImageView.addSubview(activityTypeLabel)
        activityImageView.addSubview(badgeLabel)
        activityImageView.addSubview(activityTypeButton)
        activityImageView.addSubview(muteIndicator)
        activityImageView.addSubview(invitationSegmentedControl)
        
        activityImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 5).isActive = true
        activityImageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -5).isActive = true
        activityImageView.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 0).isActive = true
        activityImageView.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: 0).isActive = true
        
        nameLabel.topAnchor.constraint(equalTo: activityImageView.topAnchor, constant: 10).isActive = true
        nameLabel.leftAnchor.constraint(equalTo: activityImageView.leftAnchor, constant: 10).isActive = true
        nameLabel.rightAnchor.constraint(equalTo: activityTypeButton.leftAnchor, constant: -5).isActive = true
        
        startLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 2).isActive = true
        startLabel.leftAnchor.constraint(equalTo: activityImageView.leftAnchor, constant: 10).isActive = true
        startLabel.rightAnchor.constraint(equalTo: activityTypeButton.leftAnchor, constant: -5).isActive = true
//
        activityTypeLabel.topAnchor.constraint(equalTo: startLabel.bottomAnchor, constant: 2).isActive = true
        activityTypeLabel.leftAnchor.constraint(equalTo: activityImageView.leftAnchor, constant: 10).isActive = true
        activityTypeLabel.rightAnchor.constraint(equalTo: activityTypeButton.leftAnchor, constant: -5).isActive = true
        
        activityTypeButton.topAnchor.constraint(equalTo: activityImageView.topAnchor, constant: 10).isActive = true
        activityTypeButton.rightAnchor.constraint(equalTo: activityImageView.rightAnchor, constant: -10).isActive = true
        activityTypeButton.widthAnchor.constraint(equalToConstant: 30).isActive = true
        activityTypeButton.heightAnchor.constraint(equalToConstant: 30).isActive = true
        
        invitationSegmentedControlTopAnchor = invitationSegmentedControl.topAnchor.constraint(equalTo: activityTypeLabel.bottomAnchor, constant: invitationSegmentedControlTopAnchorRegular)
        invitationSegmentedControlTopAnchor.isActive = true
        invitationSegmentedControl.leftAnchor.constraint(equalTo: activityImageView.leftAnchor, constant: 5).isActive = true
        invitationSegmentedControl.rightAnchor.constraint(equalTo: activityImageView.rightAnchor, constant: -5).isActive = true
        invitationSegmentedControl.bottomAnchor.constraint(equalTo: activityImageView.bottomAnchor, constant: -10).isActive = true
        invitationSegmentHeightConstraint = invitationSegmentedControl.heightAnchor.constraint(equalToConstant: invitationSegmentHeightConstant)
        invitationSegmentHeightConstraint.isActive = true
        
        muteIndicator.leftAnchor.constraint(equalTo: nameLabel.rightAnchor, constant: 1).isActive = true
        muteIndicator.centerYAnchor.constraint(equalTo: nameLabel.centerYAnchor, constant: 1).isActive = true
        muteIndicator.widthAnchor.constraint(equalToConstant: 15).isActive = true
        muteIndicator.heightAnchor.constraint(equalToConstant: 15).isActive = true
        
        badgeLabel.topAnchor.constraint(equalTo: activityTypeButton.bottomAnchor, constant: 10).isActive = true
        badgeLabel.rightAnchor.constraint(equalTo: activityImageView.rightAnchor, constant: -10).isActive = true
        badgeLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 25).isActive = true
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        nameLabel.text = nil
        startLabel.text = nil
        activityTypeLabel.text = nil
        badgeLabel.isHidden = true
        muteIndicator.isHidden = true
        nameLabel.textColor = .black
        activityTypeButton.setImage(UIImage(named: "activity"), for: .normal)
    }
            
    func dateTimeValue(forActivity activity: Activity) -> (Int, String) {
        var value = ""
        var numberOfLines = 1
        if let startDate = activity.startDateTime as? TimeInterval, let endDate = activity.endDateTime as? TimeInterval, let allDay = activity.allDay {
            let startDate = Date(timeIntervalSince1970: startDate)
            let endDate = Date(timeIntervalSince1970: endDate)
            let startDateFormatter = DateFormatter()
            let endDateFormatter = DateFormatter()
            startDateFormatter.dateFormat = "d"
            endDateFormatter.dateFormat = "d"
            if let startTimeZone = activity.startTimeZone {
                startDateFormatter.timeZone = TimeZone(identifier: startTimeZone)
            } else {
                startDateFormatter.timeZone = TimeZone(identifier: "UTC")
            }
            if let endTimeZone = activity.endTimeZone {
                endDateFormatter.timeZone = TimeZone(identifier: endTimeZone)
            } else {
                endDateFormatter.timeZone = TimeZone(identifier: "UTC")
            }
        
            let numberFormatter = NumberFormatter()
            numberFormatter.numberStyle = .ordinal
            
            var startDay = ""
            var day = startDateFormatter.string(from: startDate)
            if let integer = Int(day) {
                let number = NSNumber(value: integer)
                startDay = numberFormatter.string(from: number) ?? ""
            }
            
            var endDay = ""
            day = endDateFormatter.string(from: endDate)
            if let integer = Int(day) {
                let number = NSNumber(value: integer)
                endDay = numberFormatter.string(from: number) ?? ""
            }
            
            startDateFormatter.dateFormat = "EEEE, MMM"
            value += "\(startDateFormatter.string(from: startDate)) \(startDay)"
            
            if allDay {
                value += " All Day"
            } else {
                startDateFormatter.dateFormat = "h:mm a"
                value += " \(startDateFormatter.string(from: startDate))"
            }
            
            if startDate.stripTime().compare(endDate.stripTime()) != .orderedSame {
                value += "\n"
                numberOfLines = 2
                
                endDateFormatter.dateFormat = "EEEE, MMM"
                value += "\(endDateFormatter.string(from: endDate)) \(endDay) "
                
                if allDay {
                    value += "All Day"
                }
            }

            if !allDay {
                if numberOfLines == 1 {
                    value += "\n"
                    numberOfLines = 2
                }
                
                endDateFormatter.dateFormat = "h:mm a"
                value += "\(endDateFormatter.string(from: endDate))"
                
            }
        }
        
        return (numberOfLines, value)
    }
    
    func configureCell(for indexPath: IndexPath, activity: Activity) {
        
        backgroundColor = #colorLiteral(red: 0.9489266276, green: 0.9490858912, blue: 0.9747040868, alpha: 1)
        contentView.backgroundColor = #colorLiteral(red: 0.9489266276, green: 0.9490858912, blue: 0.9747040868, alpha: 1)
        activityImageView.backgroundColor = .white
        
        self.activity = activity
        
        let isActivityMuted = activity.muted != nil && activity.muted!
        let activityName = activity.name
        
        nameLabel.text = activityName
        muteIndicator.isHidden = !isActivityMuted
                
        let dateTimeValueArray = dateTimeValue(forActivity: activity)
        startLabel.numberOfLines = dateTimeValueArray.0
        startLabel.text = dateTimeValueArray.1
        
        if activity.category != nil {
            activityTypeLabel.text = activity.category
        } else {
            activityTypeLabel.text = "Uncategorized"
        }
                
//        if activity.activityType != "nothing" && activity.activityType != nil {
//            activityTypeLabel.text = activity.activityType?.capitalized
//        } else {
//            activityTypeLabel.text = ""
//        }
//
//        if activity.locationName != "locationName" && activity.locationName != "Location" && activity.locationName != nil {
//            activityAddressLabel.text = activity.locationName
//        } else {
//            activityAddressLabel.text = ""
//        }
        
        invitationSegmentedControl.isHidden = true
        invitationSegmentHeightConstraint.constant = 0
        
        switch activity.category?.lowercased() {
        case "sleep":
            activityTypeButton.setImage(UIImage(named: "sleep"), for: .normal)
        case "meal":
            activityTypeButton.setImage(UIImage(named: "food"), for: .normal)
        case "work":
            activityTypeButton.setImage(UIImage(named: "work"), for: .normal)
        case "social":
            activityTypeButton.setImage(UIImage(named: "nightlife"), for: .normal)
        case "leisure":
            activityTypeButton.setImage(UIImage(named: "leisure"), for: .normal)
        case "exercise":
            activityTypeButton.setImage(UIImage(named: "workout"), for: .normal)
        case "family":
            activityTypeButton.setImage(UIImage(named: "family"), for: .normal)
        case "personal":
            activityTypeButton.setImage(UIImage(named: "personal"), for: .normal)
        default:
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
