//
//  ListCell+ConfigureCell.swift
//  Plot
//
//  Created by Cory McHattie on 5/20/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import UIKit
import Firebase
import SDWebImage

extension ListCell {
    
    func configureCell(for indexPath: IndexPath, list: ListType) {
        self.list = list
                
        let isMuted = list.muted != nil && list.muted!
        let name = list.name
                        
        nameLabel.text = name
        muteIndicator.isHidden = !isMuted
        
        activityTypeButton.setImage(ActivityCategory.todo.icon, for: .normal)
        activityTypeButton.tintColor = ActivityCategory.todo.color
        activityTypeLabel.text = ActivityCategory.todo.rawValue
        
        let badgeString = list.badge?.toString()
        let badgeInt = list.badge ?? 0
        
        if badgeInt > 0 {
            badgeLabel.text = badgeString
            badgeLabel.isHidden = false
        } else {
            badgeLabel.isHidden = true
        }
    }
    
    func loadParticipantsThumbnail(list: ListType) {
        self.listDataStore?.getParticipants(forList: list, completion: { [weak self] (participants) in
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
