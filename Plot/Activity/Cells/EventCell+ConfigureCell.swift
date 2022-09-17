//
//  EventCell+ConfigureCell.swift
//  Pigeon-project
//
//  Created by Cory McHattie on 4/28/19.
//  Copyright © 2019 Immature Creations. All rights reserved.
//

import UIKit
import Firebase
import SDWebImage

extension EventCell {
    
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
        } else {
            invitationSegmentedControlTopAnchor.constant = 0
            invitationSegmentHeightConstraint.constant = 0
            invitationSegmentedControl.isHidden = true
        }
        
        if let categoryValue = activity.category, let category = ActivityCategory(rawValue: categoryValue) {
            activityTypeButton.setImage(category.icon, for: .normal)
            if category == .uncategorized {
                activityTypeButton.setImage(UIImage(named: "event"), for: .normal)
            }
            activityTypeLabel.text = category.rawValue
        } else {
            activityTypeButton.setImage(UIImage(named: "event"), for: .normal)
            activityTypeLabel.text = ActivityCategory.uncategorized.rawValue
        }
        
        activityTypeButton.tintColor = .systemBlue
        if let color = activity.calendarColor {
            activityTypeButton.tintColor = UIColor(ciColor: CIColor(string: color))
        }
        
        let badgeString = activity.badge?.toString()
        let badgeInt = activity.badge ?? 0
        
        if badgeInt > 0 {
            badgeLabel.text = badgeString
            badgeLabel.isHidden = false
        } else {
            badgeLabel.isHidden = true
        }
        
    }
    
    func loadParticipantsThumbnail(activity: Activity) {
        ParticipantsFetcher.getParticipants(forActivity: activity, completion: { [weak self] (participants) in
            ParticipantsFetcher.getAcceptedParticipant(forActivity: activity, allParticipants: participants) { acceptedParticipant in
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

extension EventCollectionCell {
    
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
        } else {
            invitationSegmentedControlTopAnchor.constant = 0
            invitationSegmentHeightConstraint.constant = 0
            invitationSegmentedControl.isHidden = true
        }
        
        if let categoryValue = activity.category, let category = ActivityCategory(rawValue: categoryValue) {
            activityTypeButton.setImage(category.icon, for: .normal)
            if category == .uncategorized {
                activityTypeButton.setImage(UIImage(named: "event"), for: .normal)
            }
            activityTypeLabel.text = category.rawValue
        } else {
            activityTypeButton.setImage(UIImage(named: "event"), for: .normal)
            activityTypeLabel.text = ActivityCategory.uncategorized.rawValue
        }
        
        activityTypeButton.tintColor = .systemBlue
        if let color = activity.calendarColor {
            activityTypeButton.tintColor = UIColor(ciColor: CIColor(string: color))
        }
        
        let badgeString = activity.badge?.toString()
        let badgeInt = activity.badge ?? 0
        
        if badgeInt > 0 {
            badgeLabel.text = badgeString
            badgeLabel.isHidden = false
        } else {
            badgeLabel.isHidden = true
        }
        
    }
    
    func loadParticipantsThumbnail(activity: Activity) {
        ParticipantsFetcher.getParticipants(forActivity: activity, completion: { [weak self] (participants) in
            ParticipantsFetcher.getAcceptedParticipant(forActivity: activity, allParticipants: participants) { acceptedParticipant in
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
