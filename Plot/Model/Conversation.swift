//
//  Conversation.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 12/2/17.
//  Copyright © 2017 Roman Mizin. All rights reserved.
//

import UIKit

class Conversation: NSObject {
    
    var chatID: String?
    var chatName: String?
    var chatPhotoURL: String?
    var chatThumbnailPhotoURL: String?
    var lastMessageID: String?
    var lastMessage: Message?
    var isGroupChat: Bool?
    var chatParticipantsIDs: [String]?
    var admin: String?
    var adminNeeded: Bool?
    var badge: Int?
    var pinned: Bool?
    var muted: Bool?
    var activities: [String]?
    var checklists: [String]?
    var activitylists: [String]?
    var grocerylists: [String]?
    var packinglists: [String]?
    
    func messageText() -> String {
                
        let isActivityMessage = lastMessage?.activityType != nil || lastMessage?.activityID != nil
        let isImageMessage = (lastMessage?.imageUrl != nil || lastMessage?.localImage != nil) && lastMessage?.videoUrl == nil
        let isVideoMessage = (lastMessage?.imageUrl != nil || lastMessage?.localImage != nil) && lastMessage?.videoUrl != nil
        let isVoiceMessage = lastMessage?.voiceEncodedString != nil
        let isTextMessage = lastMessage?.text != nil
        
        guard !isActivityMessage else { return  MessageSubtitle.activity }
        guard !isImageMessage else { return  MessageSubtitle.image }
        guard !isVideoMessage else { return MessageSubtitle.video }
        guard !isVoiceMessage else { return MessageSubtitle.audio }
        guard !isTextMessage else { return lastMessage?.text ?? "" }
        
        return MessageSubtitle.empty
    }
    
    init(dictionary: [String: AnyObject]?) {
        super.init()
        
        chatID = dictionary?["chatID"] as? String
        chatName = dictionary?["chatName"] as? String
        chatPhotoURL = dictionary?["chatOriginalPhotoURL"] as? String
        chatThumbnailPhotoURL = dictionary?["chatThumbnailPhotoURL"] as? String
        lastMessageID = dictionary?["lastMessageID"] as? String
        lastMessage = dictionary?["lastMessage"] as? Message
        isGroupChat = dictionary?["isGroupChat"] as? Bool
        chatParticipantsIDs = dictionary?["chatParticipantsIDs"] as? [String]
        admin = dictionary?["admin"] as? String
        adminNeeded = dictionary?["adminNeeded"] as? Bool
        badge = dictionary?["badge"] as? Int
        pinned = dictionary?["pinned"] as? Bool
        muted = dictionary?["muted"] as? Bool
        activities = dictionary?[activitiesEntity] as? [String]
        checklists = dictionary?["checklists"] as? [String]
        activitylists = dictionary?["activitylists"] as? [String]
        grocerylists = dictionary?["grocerylists"] as? [String]
        packinglists = dictionary?["packinglists"] as? [String]
    }
    
    func toAnyObject() -> [String: AnyObject] {
        var conversationDict = [String: AnyObject]()
        
        if let value = self.chatID as AnyObject? {
            conversationDict["chatID"] = value
        }
        
        if let value = self.chatName as AnyObject? {
            conversationDict["chatName"] = value
        }
        
        if let value = self.chatPhotoURL as AnyObject? {
            conversationDict["chatOriginalPhotoURL"] = value
        }
        
        if let value = self.chatThumbnailPhotoURL as AnyObject? {
            conversationDict["chatThumbnailPhotoURL"] = value
        }
        
        if let value = self.isGroupChat as AnyObject? {
            conversationDict["isGroupChat"] = value
        }
        
        if let value = self.chatParticipantsIDs as AnyObject? {
            conversationDict["chatParticipantsIDs"] = value
        }
        
        if let value = self.admin as AnyObject? {
            conversationDict["admin"] = value
        }
        
        if let value = self.activities as AnyObject? {
            conversationDict[activitiesEntity] = value
        }
        
        if let value = self.checklists as AnyObject? {
            conversationDict["checklists"] = value
        }
        
        if let value = self.activitylists as AnyObject? {
            conversationDict["activitylists"] = value
        }
        
        if let value = self.grocerylists as AnyObject? {
            conversationDict["grocerylists"] = value
        }
        
        if let value = self.packinglists as AnyObject? {
            conversationDict["packinglists"] = value
        }
        
        return conversationDict
    }
}
