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
    
    func configureCell(for indexPath: IndexPath, grocerylist: Grocerylist?, checklist: Checklist?, packinglist: Packinglist?) {
        
        backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
        contentView.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
        listImageView.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
        
        if let grocerylist = grocerylist {
            self.grocerylist = grocerylist
            nameLabel.text = grocerylist.name
            listTypeLabel.text = "Grocery List"
            if let date = grocerylist.lastModifiedDate {
                timeLabel.text = date.formatRelativeString()
            }
            muteIndicator.isHidden = !(grocerylist.muted ?? false)
            
            let badgeString = grocerylist.badge?.toString()
            let badgeInt = grocerylist.badge ?? 0
            
            if badgeInt > 0  {
                badgeLabel.text = badgeString
                badgeLabel.isHidden = false
                newMessageIndicator.isHidden = true
            } else {
                newMessageIndicator.isHidden = true
                badgeLabel.isHidden = true
            }
            
            if grocerylist.activityID == nil {
                activityButton.tintColor = ThemeManager.currentTheme().generalSubtitleColor
            } else {
                activityButton.tintColor = .systemBlue
            }
            
            if grocerylist.conversationID == nil {
                chatButton.tintColor = ThemeManager.currentTheme().generalSubtitleColor
            } else {
                chatButton.tintColor = .systemBlue
            }
        } else if let checklist = checklist {
            self.checklist = checklist
            nameLabel.text = checklist.name
            listTypeLabel.text = "Checklist"
            if let date = checklist.lastModifiedDate {
                timeLabel.text = date.formatRelativeString()
            }
            muteIndicator.isHidden = !(checklist.muted ?? false)
            
            let badgeString = checklist.badge?.toString()
            let badgeInt = checklist.badge ?? 0
                                    
            if badgeInt > 0  {

                badgeLabel.text = badgeString
                badgeLabel.isHidden = false
                newMessageIndicator.isHidden = true
            
            } else {
                newMessageIndicator.isHidden = true
                badgeLabel.isHidden = true
                
            }
            
            if checklist.activityID == nil {
                activityButton.tintColor = ThemeManager.currentTheme().generalSubtitleColor
            } else {
                activityButton.tintColor = .systemBlue
            }
            
            if checklist.conversationID == nil {
                chatButton.tintColor = ThemeManager.currentTheme().generalSubtitleColor
            } else {
                chatButton.tintColor = .systemBlue
            }
        } else if let packinglist = packinglist {
            self.packinglist = packinglist
            nameLabel.text = packinglist.name
            listTypeLabel.text = "Packing List"
            if let date = packinglist.lastModifiedDate {
                timeLabel.text = date.formatRelativeString()
            }
            muteIndicator.isHidden = !(packinglist.muted ?? false)
            
            let badgeString = packinglist.badge?.toString()
            let badgeInt = packinglist.badge ?? 0
            
            if badgeInt > 0  {
                badgeLabel.text = badgeString
                badgeLabel.isHidden = false
                newMessageIndicator.isHidden = true
            } else {
                newMessageIndicator.isHidden = true
                badgeLabel.isHidden = true
            }
            
            if packinglist.activityID == nil {
                activityButton.tintColor = ThemeManager.currentTheme().generalSubtitleColor
            } else {
                activityButton.tintColor = .systemBlue
            }
            
            if packinglist.conversationID == nil {
                chatButton.tintColor = ThemeManager.currentTheme().generalSubtitleColor
            } else {
                chatButton.tintColor = .systemBlue
            }
        }
        
        if let grocerylist = grocerylist {
            updateParticipantsThumbnailGL(grocerylist: grocerylist)
        } else if let checklist = checklist {
            updateParticipantsThumbnailCL(checklist: checklist)
        } else if let packinglist = packinglist {
            updateParticipantsThumbnailPL(packinglist: packinglist)
        }
        
    }
    
    func updateParticipantsThumbnailGL(grocerylist: Grocerylist) {
        let participantsIDs = grocerylist.participantsIDs ?? []
        var participantsCount = 0
        if participantsIDs.count > 1 {
            // minus current user
            participantsCount = participantsIDs.count - 1
        }
        for i in 0..<thumbnails.count {
            if i < participantsCount {
                thumbnails[i].isHidden = false
                thumbnails[i].image = UIImage(named: "UserpicIcon")
            } else {
                thumbnails[i].isHidden = true
            }
        }
        
        loadParticipantsThumbnailGL(grocerylist: grocerylist)
    }
    
    func loadParticipantsThumbnailGL(grocerylist: Grocerylist) {
        self.listViewControllerDataStore?.getParticipants(grocerylist: grocerylist, checklist: nil, packinglist: nil, completion: { [weak self] (users) in
            for i in 0..<users.count {
                let user = users[i]
                if Auth.auth().currentUser?.uid == user.id {
                    continue
                }
                
                if i > 8 {
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
    
    func updateParticipantsThumbnailCL(checklist: Checklist) {
        let participantsIDs = checklist.participantsIDs ?? []
        var participantsCount = 0
        if participantsIDs.count > 1 {
            // minus current user
            participantsCount = participantsIDs.count - 1
        }
        for i in 0..<thumbnails.count {
            if i < participantsCount {
                thumbnails[i].isHidden = false
                thumbnails[i].image = UIImage(named: "UserpicIcon")
            } else {
                thumbnails[i].isHidden = true
            }
        }
        
        loadParticipantsThumbnailCL(checklist: checklist)
    }
    
    func loadParticipantsThumbnailCL(checklist: Checklist) {
        self.listViewControllerDataStore?.getParticipants(grocerylist: nil, checklist: checklist, packinglist: nil, completion: { [weak self] (users) in
            for i in 0..<users.count {
                let user = users[i]
                if Auth.auth().currentUser?.uid == user.id {
                    continue
                }
                
                if i > 8 {
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
    
    func updateParticipantsThumbnailPL(packinglist: Packinglist) {
        let participantsIDs = packinglist.participantsIDs ?? []
        var participantsCount = 0
        if participantsIDs.count > 1 {
            // minus current user
            participantsCount = participantsIDs.count - 1
        }
        for i in 0..<thumbnails.count {
            if i < participantsCount {
                thumbnails[i].isHidden = false
                thumbnails[i].image = UIImage(named: "UserpicIcon")
            } else {
                thumbnails[i].isHidden = true
            }
        }
        
        loadParticipantsThumbnailPL(packinglist: packinglist)
    }
    
    func loadParticipantsThumbnailPL(packinglist: Packinglist) {
        self.listViewControllerDataStore?.getParticipants(grocerylist: nil, checklist: nil, packinglist: packinglist, completion: { [weak self] (users) in
            for i in 0..<users.count {
                let user = users[i]
                if Auth.auth().currentUser?.uid == user.id {
                    continue
                }
                
                if i > 8 {
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
}
