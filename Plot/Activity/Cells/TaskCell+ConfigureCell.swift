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
    
    func configureCell(for indexPath: IndexPath, task: Activity) {
        self.task = task
                
        let isActivityMuted = task.muted != nil && task.muted!
        let activityName = task.name
                        
        nameLabel.text = activityName
        muteIndicator.isHidden = !isActivityMuted
                
        let dateTimeValueArray = dateTimeValue(forTask: task)
        endLabel.numberOfLines = dateTimeValueArray.0
        endLabel.text = dateTimeValueArray.1
        
        if let subcategoryValue = task.subcategory, let subcategory = ActivitySubcategory(rawValue: subcategoryValue), subcategory != .uncategorized {
            activityTypeButton.setImage(subcategory.icon, for: .normal)
            if let goal = task.goal, let description = goal.cellDescription {
                activityTypeLabel.text = description
            } else {
                activityTypeLabel.text = subcategory.rawValue
            }
        } else if let categoryValue = task.category, let category = ActivityCategory(rawValue: categoryValue) {
            activityTypeButton.setImage(category.icon, for: .normal)
            if category == .uncategorized {
                activityTypeButton.setImage(UIImage(named: "task"), for: .normal)
            }
            if let goal = task.goal, let description = goal.cellDescription {
                activityTypeLabel.text = description
            } else {
                activityTypeLabel.text = category.rawValue
            }
        } else {
            activityTypeButton.setImage(UIImage(named: "task"), for: .normal)
            if let goal = task.goal, let description = goal.cellDescription {
                activityTypeLabel.text = description
            } else {
                activityTypeLabel.text = ActivityCategory.uncategorized.rawValue
            }
        }

        
        var image = task.isCompleted ?? false ? "checkmark.circle" : "circle"
        if task.isGoal ?? false, !(task.isCompleted ?? false), let endDate = task.endDate, endDate < Date() {
            image = "x.circle"
        }
        checkImage.image = UIImage(systemName: image, withConfiguration: checkConfiguration)
        
        if let badgeDate = task.badgeDate, let finalDateTime = task.finalDateTime, let badge = badgeDate[String(describing: Int(truncating: finalDateTime))], badge > 0 {
            badgeLabel.text = String(badge)
            badgeLabel.isHidden = false
        } else if let badge = task.badge, badge > 0 {
            badgeLabel.text = String(badge)
            badgeLabel.isHidden = false
        } else {
            badgeLabel.isHidden = true
        }
        
    }
    
    func loadParticipantsThumbnail(activity: Activity) {
        ParticipantsFetcher.getParticipants(forActivity: activity, completion: { [weak self] (participants) in
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

extension TaskCollectionCell {
    
    func configureCell(for indexPath: IndexPath, task: Activity) {
        self.task = task
                
        let isActivityMuted = task.muted != nil && task.muted!
        let activityName = task.name
                        
        nameLabel.text = activityName
        muteIndicator.isHidden = !isActivityMuted
                
        let dateTimeValueArray = dateTimeValue(forTask: task)
        endLabel.numberOfLines = dateTimeValueArray.0
        endLabel.text = dateTimeValueArray.1
        
        if let subcategoryValue = task.subcategory, let subcategory = ActivitySubcategory(rawValue: subcategoryValue), subcategory != .uncategorized {
            activityTypeButton.setImage(subcategory.icon, for: .normal)
            if let goal = task.goal, let description = goal.cellDescription {
                activityTypeLabel.text = description
            } else {
                activityTypeLabel.text = subcategory.rawValue
            }
        } else if let categoryValue = task.category, let category = ActivityCategory(rawValue: categoryValue) {
            activityTypeButton.setImage(category.icon, for: .normal)
            if category == .uncategorized {
                activityTypeButton.setImage(UIImage(named: "task"), for: .normal)
            }
            if let goal = task.goal, let description = goal.cellDescription {
                activityTypeLabel.text = description
            } else {
                activityTypeLabel.text = category.rawValue
            }
        } else {
            activityTypeButton.setImage(UIImage(named: "task"), for: .normal)
            if let goal = task.goal, let description = goal.cellDescription {
                activityTypeLabel.text = description
            } else {
                activityTypeLabel.text = ActivityCategory.uncategorized.rawValue
            }
        }
                
        var image = task.isCompleted ?? false ? "checkmark.circle" : "circle"
        if task.isGoal ?? false, !(task.isCompleted ?? false), let endDate = task.endDate, endDate < Date() {
            image = "x.circle"
        }
        checkImage.image = UIImage(systemName: image, withConfiguration: checkConfiguration)
        
        if let badgeDate = task.badgeDate, let finalDateTime = task.finalDateTime, let badge = badgeDate[String(describing: Int(truncating: finalDateTime))], badge > 0 {
            badgeLabel.text = String(badge)
            badgeLabel.isHidden = false
        } else if let badge = task.badge, badge > 0 {
            badgeLabel.text = String(badge)
            badgeLabel.isHidden = false
        } else {
            badgeLabel.isHidden = true
        }
    }
    
    func loadParticipantsThumbnail(activity: Activity) {
        ParticipantsFetcher.getParticipants(forActivity: activity, completion: { [weak self] (participants) in
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
