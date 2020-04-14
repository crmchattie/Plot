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
    
    func configureCell(for indexPath: IndexPath, activity: Activity, withInvitation invitation: Invitation?) {
        
        backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
        contentView.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
        activityImageView.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
        
        self.invitation = invitation
        self.activity = activity
        
        let isActivityMuted = activity.muted != nil && activity.muted!
        let activityName = activity.name

        nameLabel.text = activityName
        muteIndicator.isHidden = !isActivityMuted
        
        if activity.activityType != "nothing" && activity.activityType != nil {
            activityTypeLabel.text = activity.activityType
        } else {
            activityTypeLabel.text = ""
        }
        
        if activity.locationName != "locationName" && activity.locationName != nil {
            activityAddressLabel.text = activity.locationName
        } else {
            activityAddressLabel.text = ""
        }
        
        let dateTimeValueArray = dateTimeValue(forActivity: activity)
        startLabel.numberOfLines = dateTimeValueArray.0
        startLabel.text = dateTimeValueArray.1
        
        
        if let invitation = invitation {
            invitationSegmentedControl.isHidden = false
            invitationSegmentHeightConstraint.constant = invitationSegmentHeightConstant
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
            invitationSegmentedControl.isHidden = true
            invitationSegmentHeightConstraint.constant = 0
        }
        
        if activity.recipeID != nil {
            activityTypeButton.setImage(UIImage(named: "meal"), for: .normal)
        } else if activity.workoutID != nil {
            activityTypeButton.setImage(UIImage(named: "workout"), for: .normal)
        } else if activity.eventID != nil {
            activityTypeButton.setImage(UIImage(named: "event"), for: .normal)
        }
        
        let badgeString = activity.badge?.toString()
        let badgeInt = activity.badge ?? 0
        
        if badgeInt > 0 {
            badgeLabel.text = badgeString
            badgeLabel.isHidden = false
            newActivityIndicator.isHidden = true
        } else {
            newActivityIndicator.isHidden = true
            badgeLabel.isHidden = true
        }
        
        let topAnchor = invitationSegmentedControlTopAnchorShowAvatar
        invitationSegmentedControlTopAnchor.constant = topAnchor
        
        loadParticipantsThumbnail(activity: activity)
        
        if activity.locationAddress == nil {
            mapButton.tintColor = ThemeManager.currentTheme().generalSubtitleColor
            mapButton.isUserInteractionEnabled = false
        } else {
            mapButton.tintColor = .systemBlue
            mapButton.isUserInteractionEnabled = true
        }

        if activity.participantsIDs!.count == 1 {
            chatButton.tintColor = ThemeManager.currentTheme().generalSubtitleColor
            chatButton.isUserInteractionEnabled = false
        } else {
            chatButton.tintColor = .systemBlue
            chatButton.isUserInteractionEnabled = true
        }
    }
    
    func updateParticipantsThumbnail(activity: Activity, acceptedParticipants: [User]) {
        let participants = acceptedParticipants.filter({$0.id != Auth.auth().currentUser?.uid})
        
        let participantsCount = participants.count
        for i in 0..<thumbnails.count {
            if i < participantsCount {
                thumbnails[i].isHidden = false
                thumbnails[i].image = UIImage(named: "UserpicIcon")
            } else {
                thumbnails[i].isHidden = true
            }
        }
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
}
