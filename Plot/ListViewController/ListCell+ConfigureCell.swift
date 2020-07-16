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
    
    func configureCell(for indexPath: IndexPath, grocerylist: Grocerylist?, checklist: Checklist?, packinglist: Packinglist?, activitylist: Activitylist?) {
        
        backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
        contentView.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
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
        } else if let activitylist = activitylist {
            self.activitylist = activitylist
            nameLabel.text = activitylist.name
            listTypeLabel.text = "Activitylist"
            if let date = activitylist.lastModifiedDate {
                timeLabel.text = date.formatRelativeString()
            }
            muteIndicator.isHidden = !(activitylist.muted ?? false)
            
            let badgeString = activitylist.badge?.toString()
            let badgeInt = activitylist.badge ?? 0
                                    
            if badgeInt > 0  {
                badgeLabel.text = badgeString
                badgeLabel.isHidden = false
                newMessageIndicator.isHidden = true
            
            } else {
                newMessageIndicator.isHidden = true
                badgeLabel.isHidden = true
            }
            
            if activitylist.activityID == nil {
                activityButton.tintColor = ThemeManager.currentTheme().generalSubtitleColor
            } else {
                activityButton.tintColor = .systemBlue
            }
            
            if activitylist.conversationID == nil {
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
        } else if let activitylist = activitylist {
            updateParticipantsThumbnailAL(activitylist: activitylist)
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
        self.listViewControllerDataStore?.getParticipants(grocerylist: grocerylist, checklist: nil, activitylist: nil, packinglist: nil, completion: { [weak self] (users) in
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
        self.listViewControllerDataStore?.getParticipants(grocerylist: nil, checklist: checklist, activitylist: nil, packinglist: nil, completion: { [weak self] (users) in
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
    
    func updateParticipantsThumbnailAL(activitylist: Activitylist) {
        let participantsIDs = activitylist.participantsIDs ?? []
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
        
        loadParticipantsThumbnailAL(activitylist: activitylist)
    }
    
    func loadParticipantsThumbnailAL(activitylist: Activitylist) {
        self.listViewControllerDataStore?.getParticipants(grocerylist: nil, checklist: nil, activitylist: activitylist, packinglist: nil, completion: { [weak self] (users) in
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
        self.listViewControllerDataStore?.getParticipants(grocerylist: nil, checklist: nil, activitylist: nil, packinglist: packinglist, completion: { [weak self] (users) in
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
