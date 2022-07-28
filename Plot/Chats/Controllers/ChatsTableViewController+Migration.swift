//
//  ChatsTableViewController+Migration.swift
//  Plot
//
//  Created by Cory McHattie on 6/7/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import Foundation
import Firebase
import CodableFirebase

extension ChatsTableViewController {
    func sendMessage(forConversations: [Conversation]) {
        let dispatchGroup = DispatchGroup()
        let plotUser = "acdmpzhmDWaBdcEo17DRMt8gwCh1"
        if let currentUserID = Auth.auth().currentUser?.uid, currentUserID != plotUser {
            for conversation in conversations {
                if let participants = conversation.chatParticipantsIDs, participants.contains(plotUser) {
                    return
                }
            }
            let chatID = Database.database().reference().child("user-messages").child(currentUserID).childByAutoId().key ?? ""
            let groupChatsReference = Database.database().reference().child("groupChats").child(chatID).child(messageMetaDataFirebaseFolder)
            let memberIDs = [currentUserID: currentUserID, plotUser: plotUser]
            let childValues: [String: AnyObject] = ["chatID": chatID as AnyObject, "chatName": "Plot" as AnyObject, "chatParticipantsIDs": memberIDs as AnyObject, "admin": currentUserID as AnyObject, "adminNeeded": false as AnyObject, "isGroupChat": true as AnyObject]
            
            dispatchGroup.enter()
            groupChatsReference.updateChildValues(childValues)
            dispatchGroup.leave()
            
            for (key, _) in memberIDs {
                dispatchGroup.enter()
                let userReference = Database.database().reference().child("user-messages").child(key).child(chatID).child(messageMetaDataFirebaseFolder)
                let values:[String : Any] = ["isGroupChat": true]
                userReference.updateChildValues(values)
                dispatchGroup.leave()
            }
            
            let text = "Thank you for using Plot! If you have any questions, thoughts and/or concerns, just send us a message here! Enjoy Plotting"
            let messageReference = Database.database().reference().child("messages").childByAutoId()
            guard let messageUID = messageReference.key else { return }
            let messageStatus = messageStatusDelivered
            let timestamp = NSNumber(value: Int(Date().timeIntervalSince1970))
            let defaultData: [String: AnyObject] = ["messageUID": messageUID as AnyObject,
                                                    "toId": chatID as AnyObject,
                                                    "status": messageStatus as AnyObject,
                                                    "seen": false as AnyObject,
                                                    "fromId": plotUser as AnyObject,
                                                    "timestamp": timestamp,
                                                    "text": text as AnyObject]
            dispatchGroup.enter()
            messageReference.updateChildValues(defaultData)
            dispatchGroup.leave()
            
            for (key, _) in memberIDs {
                dispatchGroup.enter()
                let userReference = Database.database().reference().child("user-messages").child(key).child(chatID).child(userMessagesFirebaseFolder)
                userReference.updateChildValues([messageUID: 1])
                
                let ref = Database.database().reference().child("user-messages").child(key).child(chatID).child(messageMetaDataFirebaseFolder)
                ref.updateChildValues(["lastMessageID": messageUID])
                dispatchGroup.leave()
            }
        }
    }
    
    func checkForDataMigration(forConversations conversations: [Conversation]) {
        let defaults = UserDefaults.standard
        guard let currentAppVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String else {
            return
        }
        let previousVersion = defaults.string(forKey: kAppVersionKey)
        let minVersion = "1.0.1"
        let maxVersion = "1.0.13"
        
        //current app version is greater than min version and lesser than max version
        let firstCondition = (previousVersion == nil && currentAppVersion.compare(minVersion, options: .numeric) == .orderedDescending && currentAppVersion.compare(maxVersion, options: .numeric) == .orderedAscending)
        
        //current app version is greater than previous version and lesser than max version
        let secondCondition = (previousVersion != nil && currentAppVersion.compare(previousVersion!, options: .numeric) == .orderedDescending && currentAppVersion.compare(maxVersion, options: .numeric) == .orderedAscending)
        if firstCondition || secondCondition {
            // first launch
            sendMessage(forConversations: conversations)
            defaults.setValue(currentAppVersion, forKey: kAppVersionKey)
        }
        else if currentAppVersion == previousVersion {
            // same version
        }
        else {
            // other version
            defaults.setValue(currentAppVersion, forKey: kAppVersionKey)
        }
    }
}

