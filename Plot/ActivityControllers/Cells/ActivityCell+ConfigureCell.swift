//
//  ActivityCell+ConfigureCell.swift
//  Pigeon-project
//
//  Created by Cory McHattie on 4/28/19.
//  Copyright © 2019 Immature Creations. All rights reserved.
//

import UIKit
import Firebase
import SDWebImage

extension ActivityCell {
    
    func dateTimeValue(forActivity activity: Activity) -> (Int, String) {
        var value = ""
        var numberOfLines = 1
        if let startDate = activity.startDateTime as? TimeInterval, let endDate = activity.endDateTime as? TimeInterval {
            let allDay = activity.allDay ?? false
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
    
    func configureCell(for indexPath: IndexPath, activity: Activity, withInvitation invitation: Invitation?) {        
        self.invitation = invitation
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
        
        if let invitation = invitation {
            invitationSegmentedControlTopAnchor.constant = invitationSegmentedControlTopAnchorRegular
            invitationSegmentHeightConstraint.constant = invitationSegmentHeightConstant
            invitationSegmentedControl.isHidden = false
            if invitation.status != .pending {
                let index = invitation.status == .accepted ? 0 : 1
                invitationSegmentedControl.selectedSegmentIndex = index
            } else {
                invitationSegmentedControl.selectedSegmentIndex = -1
            }
            if #available(iOS 13.0, *) {
                invitationSegmentedControl.overrideUserInterfaceStyle = ThemeManager.currentTheme().userInterfaceStyle
            }
        } else {
            invitationSegmentedControlTopAnchor.constant = 0
            invitationSegmentHeightConstraint.constant = 0
            invitationSegmentedControl.isHidden = true
        }
                
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
        
        let badgeString = activity.badge?.toString()
        let badgeInt = activity.badge ?? 0
        
        if badgeInt > 0 {
            badgeLabel.text = badgeString
            badgeLabel.isHidden = false
        } else {
            badgeLabel.isHidden = true
        }
        
//        loadParticipantsThumbnail(activity: activity)
        
        
    }
    
    func loadParticipantsThumbnail(activity: Activity) {
        self.activityViewControllerDataStore?.getParticipants(forActivity: activity, completion: { [weak self] (participants) in
            InvitationsFetcher.getAcceptedParticipant(forActivity: activity, allParticipants: participants) { acceptedParticipant in
                self?.updateParticipantsThumbnail(activity: activity, acceptedParticipants: acceptedParticipant)
                for i in 0..<acceptedParticipant.count {
                    let user = acceptedParticipant[i]
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
