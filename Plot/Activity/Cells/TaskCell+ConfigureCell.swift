//
//  TaskCell+ConfigureCell.swift
//  Plot
//
//  Created by Cory McHattie on 8/22/22.
//  Copyright © 2022 Immature Creations. All rights reserved.
//

import UIKit
import Firebase
import SDWebImage

extension TaskCell {
    
    func dateTimeValue(forTask task: Activity) -> (Int, String) {
        var value = ""
        var numberOfLines = 1
        if let startDate = task.startDate, let endDate = task.endDate {
            let allDay = task.allDay ?? false
            let startDateFormatter = DateFormatter()
            let endDateFormatter = DateFormatter()
            startDateFormatter.dateFormat = "d"
            endDateFormatter.dateFormat = "d"
            if let startTimeZone = task.startTimeZone {
                startDateFormatter.timeZone = TimeZone(identifier: startTimeZone)
            } else {
                startDateFormatter.timeZone = TimeZone(identifier: "UTC")
            }
            if let endTimeZone = task.endTimeZone {
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
            
            if endDate.timeIntervalSince(startDate) > 86399 {
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
    
    func configureCell(for indexPath: IndexPath, task: Activity) {
        self.task = task
                
        let isActivityMuted = task.muted != nil && task.muted!
        let activityName = task.name
                        
        nameLabel.text = activityName
        muteIndicator.isHidden = !isActivityMuted
                
        let dateTimeValueArray = dateTimeValue(forTask: task)
        startLabel.numberOfLines = dateTimeValueArray.0
        startLabel.text = dateTimeValueArray.1
        
        invitationSegmentedControlTopAnchor.constant = 0
        invitationSegmentHeightConstraint.constant = 0
        invitationSegmentedControl.isHidden = true
        
        if let categoryValue = task.category, let category = ActivityCategory(rawValue: categoryValue) {
            activityTypeButton.setImage(category.icon, for: .normal)
            activityTypeButton.tintColor = category.color
            activityTypeLabel.text = category.rawValue
        } else {
            activityTypeButton.setImage(ActivityCategory.uncategorized.icon, for: .normal)
            activityTypeButton.tintColor = ActivityCategory.uncategorized.color
            activityTypeLabel.text = ActivityCategory.uncategorized.rawValue
        }
        
        let badgeString = task.badge?.toString()
        let badgeInt = task.badge ?? 0
        
        if badgeInt > 0 {
            badgeLabel.text = badgeString
            badgeLabel.isHidden = false
        } else {
            badgeLabel.isHidden = true
        }
    }
    
    func loadParticipantsThumbnail(activity: Activity) {
        self.activityDataStore?.getParticipants(forActivity: activity, completion: { [weak self] (participants) in
            
            self?.updateParticipantsThumbnail(activity: activity, acceptedParticipants: participants)
            for i in 0..<participants.count {
                let user = participants[i]
                if Auth.auth().currentUser?.uid == user.id {
                    continue
                }
                
                if i > 7 {
                    return
                }
                
                guard let icon = self?.thumbnails[i], let url = user.thumbnailPhotoURL else {
                    continue
                }
                
                icon.sd_setImage(with: URL(string: url), placeholderImage:  UIImage(named: "UserpicIcon"), options: [.progressiveLoad, .continueInBackground], completed: { (image, error, cacheType, url) in
                    guard image != nil else { return }
                    guard cacheType != SDImageCacheType.memory, cacheType != SDImageCacheType.disk else {
                        return
                    }
                })
            }
        })
    }
    
    func updateParticipantsThumbnail(activity: Activity, acceptedParticipants: [User]) {
        let participants = acceptedParticipants.filter({$0.id != Auth.auth().currentUser?.uid})
        let participantsCount = participants.count
        if participantsCount != 0 {
            iconViewTopAnchor.constant = iconViewTopAnchorRegular
            iconViewHeightConstraint.constant = iconViewHeightConstant
        } else {
            iconViewTopAnchor.constant = 0
            iconViewHeightConstraint.constant = 0
        }
        for i in 0..<thumbnails.count {
            if i < participantsCount {
                thumbnails[i].isHidden = false
                thumbnails[i].image = UIImage(named: "UserpicIcon")
            } else {
                thumbnails[i].isHidden = true
            }
        }
    }
}
