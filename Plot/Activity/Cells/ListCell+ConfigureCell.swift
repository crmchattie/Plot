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
        listImageView.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
        
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
            listTypeLabel.text = "Activity List"
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
    }
}
