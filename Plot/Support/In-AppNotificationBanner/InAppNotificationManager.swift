//
//  InAppNotificationManager.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 8/22/18.
//  Copyright © 2018 Roman Mizin. All rights reserved.
//

import UIKit
import Firebase
import AudioToolbox
import SafariServices
import CropViewController

class InAppNotificationManager: NSObject {
  
    fileprivate var notificationReference: DatabaseReference!
    fileprivate var notificationChatHandle = [(handle: DatabaseHandle, chatID: String)]()
    fileprivate var conversations = [Conversation]()
    fileprivate var notificationActivityHandle = [(handle: DatabaseHandle, activityID: String)]()
    fileprivate var activities = [Activity]()
  
    func updateConversations(to conversations: [Conversation]) {
        self.conversations = conversations
    }
    
    func updateActivities(to activities: [Activity]) {
        self.activities = activities
    }
  
    func removeAllObserversMessages() {
        guard let currentUserID = Auth.auth().currentUser?.uid, notificationReference != nil else { return }
        let reference = Database.database().reference()
        for handle in notificationChatHandle {
            notificationReference = reference.child("user-messages").child(currentUserID).child(handle.chatID).child(messageMetaDataFirebaseFolder)
            notificationReference.removeObserver(withHandle: handle.handle)
        }
        notificationChatHandle.removeAll()
    }
  
    func observersForNotificationsConversations(conversations: [Conversation]) {
        removeAllObserversMessages()
        updateConversations(to: conversations)
        for conversation in self.conversations {
            guard let currentUserID = Auth.auth().currentUser?.uid, let chatID = conversation.chatID else { continue }
            let handle = DatabaseHandle()
            let element = (handle: handle, chatID: chatID)
            notificationChatHandle.insert(element, at: 0)

            notificationReference = Database.database().reference().child("user-messages").child(currentUserID).child(chatID).child(messageMetaDataFirebaseFolder)
            notificationChatHandle[0].handle = notificationReference.observe(.childChanged, with: { (snapshot) in
                guard snapshot.key == "lastMessageID" else { return }
                guard let messageID = snapshot.value as? String else { return }
                
                let lastMessageReference = Database.database().reference().child("messages").child(messageID)
                lastMessageReference.observeSingleEvent(of: .value, with: { (snapshot) in

                    guard var dictionary = snapshot.value as? [String: AnyObject] else { return }
                    dictionary.updateValue(messageID as AnyObject, forKey: "messageUID")

                    let message = Message(dictionary: dictionary)
                    guard let uid = Auth.auth().currentUser?.uid, message.fromId != uid else { return }
                    self.handleInAppSoundPlayingForMessage(message: message, conversation: conversation, conversations: self.conversations)
                })
            })
        }
    }
  
  func handleInAppSoundPlayingForMessage(message: Message, conversation: Conversation, conversations: [Conversation]) {
    
    if UIApplication.topViewController() is SFSafariViewController ||
      UIApplication.topViewController() is CropViewController ||
      UIApplication.topViewController() is ChatLogController ||
      UIApplication.topViewController() is INSPhotosViewController { return }
    
		if let index = conversations.firstIndex(where: { (conv) -> Bool in
      return conv.chatID == conversation.chatID
    }) {
     // let isGroupChat = conversations[index].isGroupChat ?? false
      if let muted = conversations[index].muted, !muted, let chatName = conversations[index].chatName {
        self.playNotificationSound()
        if userDefaults.currentBoolObjectState(for: userDefaults.inAppNotifications) {
          self.showInAppNotification(title: chatName, subtitle: self.subtitleForMessage(message: message))
        }
      } else if let chatName = conversations[index].chatName, conversations[index].muted == nil   {
        self.playNotificationSound()
        if userDefaults.currentBoolObjectState(for: userDefaults.inAppNotifications) {
          self.showInAppNotification(title: chatName, subtitle: self.subtitleForMessage(message: message))
        }
      }
    }
  }
    
    fileprivate func subtitleForMessage(message: Message) -> String {
        if (message.imageUrl != nil || message.localImage != nil) && message.videoUrl == nil {
            return MessageSubtitle.image
        } else if (message.imageUrl != nil || message.localImage != nil) && message.videoUrl != nil {
            return MessageSubtitle.video
        } else if message.voiceEncodedString != nil {
            return MessageSubtitle.audio
        } else {
            return message.text ?? ""
        }
    }
    
    fileprivate func conversationAvatar(resource: String?, isGroupChat: Bool) -> Any {
        let placeHolderImage = isGroupChat ? UIImage(named: "GroupIcon") : UIImage(named: "UserpicIcon")
        guard let imageURL = resource, imageURL != "" else { return placeHolderImage! }
        return URL(string: imageURL)!
    }
    
    fileprivate func conversationPlaceholder(isGroupChat: Bool) -> Data? {
        let placeHolderImage = isGroupChat ? UIImage(named: "GroupIcon") : UIImage(named: "UserpicIcon")
        guard let data = placeHolderImage?.asJPEGData else {
            return nil
        }
        return data
    }
    
    func removeAllObserversActivities() {
        guard let currentUserID = Auth.auth().currentUser?.uid, notificationReference != nil else { return }
        let reference = Database.database().reference()
        for handle in notificationActivityHandle {
            notificationReference = reference.child("user-activities").child(currentUserID).child(handle.activityID).child(messageMetaDataFirebaseFolder)
            notificationReference.removeObserver(withHandle: handle.handle)
        }
        notificationChatHandle.removeAll()
    }
    
    func observersForNotificationsActivities(activities: [Activity]) {
        removeAllObserversActivities()
        updateActivities(to: activities)
        for activity in self.activities {
            guard let activityID = activity.activityID else { continue }
            let handle = DatabaseHandle()
            let element = (handle: handle, activityID: activityID)
            notificationActivityHandle.insert(element, at: 0)
            
            notificationReference = Database.database().reference().child("activities").child(activityID).child(messageMetaDataFirebaseFolder)
            notificationActivityHandle[0].handle = notificationReference.observe(.childChanged, with: { (snapshot) in
                self.handleInAppSoundPlayingForActivity(childchanged: snapshot.key, activity: activity, activities: self.activities)
            })
        }
    }
    
    func handleInAppSoundPlayingForActivity(childchanged: String, activity: Activity, activities: [Activity]) {
        
        if UIApplication.topViewController() is SFSafariViewController ||
            UIApplication.topViewController() is CropViewController ||
            UIApplication.topViewController() is ChatLogController ||
            UIApplication.topViewController() is INSPhotosViewController ||
            UIApplication.topViewController() is CreateActivityViewController
        { return }
        
        var message = String()
        
        switch childchanged {
        case "name":
            message = "The activity name was updated."
        case "activityType":
            message = "The activity type was updated."
        case "activityDescription":
            message = "The activity description was updated."
        case "locationName":
            message = "The activity location was updated."
        case "participantsIDs":
            message = "The activity invitees were updated."
        case "transportation":
            message = "The activity transportation was updated."
        case "activityOriginalPhotoURL":
            message = "The activity photo was updated."
        case "startDateTime":
            message = "The activity start time was updated."
        case "endDateTime":
            message = "The activity end time was updated."
        case "reminder":
            message = "The activity reminder was updated."
        case "notes":
            message = "The activity notes were updated."
        case "schedule":
            message = "The activity schedule was updated."
        case "purchases":
            message = "The activity purchases were updated."
        case "checklist":
            message = "The activity checklist was updated."
        case "conversation":
            message = "The activity conversation was updated."
        default:
            message = "The activity was updated."
        }
        
//        print(message)
        
        if let index = activities.firstIndex(where: { (act) -> Bool in
            return act.activityID == activity.activityID
        }) {
            if let muted = activities[index].muted, !muted, let activityName = activities[index].name {
                self.playNotificationSound()
                if userDefaults.currentBoolObjectState(for: userDefaults.inAppNotifications) {
                    self.showInAppNotification(title: activityName, subtitle: message)
                }
            } else if let activityName = activities[index].name, activities[index].muted == nil   {
                self.playNotificationSound()
                if userDefaults.currentBoolObjectState(for: userDefaults.inAppNotifications) {
                    self.showInAppNotification(title: activityName, subtitle: message)
                }
            }
        }
    }
  
  fileprivate func showInAppNotification(title: String, subtitle: String/*, user: User*/) {
    let announcement = Announcement(title: title, subtitle: subtitle, image: nil, duration: 3,
                                    backgroundColor: ThemeManager.currentTheme().inputTextViewColor,
                                    textColor: ThemeManager.currentTheme().generalTitleColor,
                                    dragIndicatordColor: ThemeManager.currentTheme().generalTitleColor) {}
    guard let rc = UIApplication.shared.keyWindow?.rootViewController else { return }
    Plot.show(shout: announcement, to: rc)
  }
  
  fileprivate func playNotificationSound() {
    if userDefaults.currentBoolObjectState(for: userDefaults.inAppSounds) {
      SystemSoundID.playFileNamed(fileName: "notification", withExtenstion: "caf")
    }
    if userDefaults.currentBoolObjectState(for: userDefaults.inAppVibration) {
      AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
    }
  }
}
