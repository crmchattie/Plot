//
//  ChatsTableViewController+ConfigureCell.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 3/14/18.
//  Copyright © 2018 Roman Mizin. All rights reserved.
//

import UIKit
import Firebase
import SDWebImage

extension UserCell {
  
  func configureCell(for indexPath: IndexPath, conversations: [Conversation]) {
    self.conversation = conversations[indexPath.row]
    
    let isPersonalStorage = conversations[indexPath.row].chatID == Auth.auth().currentUser?.uid
    let isConversationMuted = conversations[indexPath.row].muted != nil && conversations[indexPath.row].muted!
    let chatName = isPersonalStorage ? NameConstants.personalStorage : conversations[indexPath.row].chatName
    let isGroupChat = conversations[indexPath.row].isGroupChat ?? false
    
    var placeHolderImage = isGroupChat ? UIImage(named: "chatImage") : UIImage(named: "UserpicIcon")
    placeHolderImage = isPersonalStorage ? UIImage(named: "PersonalStorage") : placeHolderImage
            
    nameLabel.text = chatName
    muteIndicator.isHidden = !isConversationMuted
    messageLabel.text = conversations[indexPath.row].messageText()
    
    if let lastMessage = conversations[indexPath.row].lastMessage, let lastStamp = lastMessage.timestamp as? TimeInterval {
      let date = Date(timeIntervalSince1970: lastStamp)
        timeLabel.text = date.formatRelativeString()
    }

    let badgeString = conversations[indexPath.row].badge?.toString()
    let badgeInt = conversations[indexPath.row].badge ?? 0
    
    if badgeInt > 0, conversations[indexPath.row].lastMessage?.fromId != Auth.auth().currentUser?.uid {
        badgeLabel.text = badgeString
        badgeLabel.isHidden = false
        newMessageIndicator.isHidden = true
    } else {
      newMessageIndicator.isHidden = true
      badgeLabel.isHidden = true
    }
    
    if conversations[indexPath.row].activities != nil {
        activityButton.tintColor = .systemBlue
    } else {
        activityButton.tintColor = .secondaryLabel
    }
    
    updateParticipantsThumbnail(conversation: conversations[indexPath.row])
  }
    
    func updateParticipantsThumbnail(conversation: Conversation) {
        let participantsIDs = conversation.chatParticipantsIDs ?? []
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
        
        loadParticipantsThumbnail(conversation: conversation)
    }
    
    func loadParticipantsThumbnail(conversation: Conversation) {
        
    }
}
