//
//  Invitation.swift
//  Plot
//
//  Created by Hafiz Usama on 10/23/19.
//  Copyright © 2019 Immature Creations. All rights reserved.
//

import Foundation

enum Status: Int, Codable {
    case pending, accepted, declined, uninvited
    
    var description: String {
      get {
        switch self {
          case .pending:
            return "Pending"
          case .accepted:
            return "Accepted"
          case .declined:
            return "Declined"
          case .uninvited:
            return "Invite"
        }
      }
    }
}

let invitationsEntity = "invitations"
let userInvitationsEntity = "user-invitations"

struct Invitation: Codable, Equatable {
    let invitationID: String
    let activityID: String
    let participantID: String
    let dateInvited: Date
    var dateAccepted: Date?
    var status: Status
}

func ==(lhs: Invitation, rhs: Invitation) -> Bool {
    return lhs.activityID == rhs.activityID && lhs.participantID == rhs.participantID
}

class PLNotification: NSObject, Codable, NSCoding {
    let chatID: String?
    let activityID: String?
    let checklistID: String?
    let grocerylistID: String?
    let googleCAE: String?
    let gcmMessageID: String?
    let aps: Aps

    enum CodingKeys: String, CodingKey {
        case googleCAE = "google.c.a.e"
        case chatID
        case gcmMessageID = "gcm.message_id"
        case aps
        case activityID
        case checklistID
        case grocerylistID
    }
    
    init(chatID: String?, activityID: String?, checklistID: String?, grocerylistID: String?, googleCAE: String?, gcmMessageID: String?, aps: Aps) {
        self.chatID = chatID
        self.activityID = activityID
        self.checklistID = checklistID
        self.grocerylistID = grocerylistID
        self.googleCAE = googleCAE
        self.gcmMessageID = gcmMessageID
        self.aps = aps
    }
    
    required convenience init?(coder decoder: NSCoder) {
        guard let aps = decoder.decodeObject(forKey: CodingKeys.aps.rawValue) as? Aps else {
            return nil
        }
        
        let chatID = decoder.decodeObject(forKey: CodingKeys.chatID.rawValue) as? String
        let activityID = decoder.decodeObject(forKey: CodingKeys.activityID.rawValue) as? String
        let checklistID = decoder.decodeObject(forKey: CodingKeys.checklistID.rawValue) as? String
        let grocerylistID = decoder.decodeObject(forKey: CodingKeys.grocerylistID.rawValue) as? String
        let googleCAE = decoder.decodeObject(forKey: CodingKeys.googleCAE.rawValue) as? String
        let gcmMessageID = decoder.decodeObject(forKey: CodingKeys.gcmMessageID.rawValue) as? String
        
        self.init(
            chatID: chatID,
            activityID: activityID,
            checklistID: checklistID,
            grocerylistID: grocerylistID,
            googleCAE: googleCAE,
            gcmMessageID: gcmMessageID,
            aps: aps
        )
    }
    
    func encode(with coder: NSCoder) {
        coder.encode(self.chatID, forKey: CodingKeys.chatID.rawValue)
        coder.encode(self.activityID, forKey: CodingKeys.activityID.rawValue)
        coder.encode(self.checklistID, forKey: CodingKeys.checklistID.rawValue)
        coder.encode(self.grocerylistID, forKey: CodingKeys.grocerylistID.rawValue)
        coder.encode(self.googleCAE, forKey: CodingKeys.googleCAE.rawValue)
        coder.encode(self.gcmMessageID, forKey: CodingKeys.gcmMessageID.rawValue)
        coder.encode(self.aps, forKey: CodingKeys.aps.rawValue)
    }
    
    override var description: String {
        if aps.category == "CHAT_CATEGORY" {
            return "\(self.aps.alert.title) sent you a message"
        }
        else if aps.category == "ACTIVITY_CATEGORY" {
            if let subtitle = self.aps.alert.subtitle, let body = self.aps.alert.body {
                let newSubtitle = subtitle.trimmingCharacters(in: .whitespaces)
                let newBody = body.replacingOccurrences(of: "The activity", with: "The \(newSubtitle) activity")
                return "\(newBody) by \(self.aps.alert.title)"
            } else {
                return "\(self.aps.alert.title) invited you to a new activity"
            }
        } else if aps.category == "CHECKLIST_CATEGORY" {
            if let subtitle = self.aps.alert.subtitle, let body = self.aps.alert.body {
                let newSubtitle = subtitle.trimmingCharacters(in: .whitespaces)
                let newBody = body.replacingOccurrences(of: "The checklist", with: "The \(newSubtitle) checklist")
                return "\(newBody) by \(self.aps.alert.title)"
            }
        } else if aps.category == "GROCERYLIST_CATEGORY" {
            if let subtitle = self.aps.alert.subtitle, let body = self.aps.alert.body {
                let newSubtitle = subtitle.trimmingCharacters(in: .whitespaces)
                let newBody = body.replacingOccurrences(of: "The grocery list", with: "The \(newSubtitle) grocery list")
                return "\(newBody) by \(self.aps.alert.title)"
            }
        }
        
        return ""
    }
}

// MARK: - Aps
class Aps: NSObject, Codable, NSCoding {
    let alert: Alert
    let badge: Int?
    let category: String
    
    enum CodingKeys: String, CodingKey {
        case alert
        case badge
        case category
    }
    
    required convenience init?(coder decoder: NSCoder) {
        guard let alert = decoder.decodeObject(forKey: CodingKeys.alert.rawValue) as? Alert,
        let category = decoder.decodeObject(forKey: CodingKeys.category.rawValue) as? String else {
            return nil
        }
        
        let badge = decoder.decodeObject(forKey: CodingKeys.badge.rawValue) as? Int
        
        self.init(
            alert: alert,
            badge: badge,
            category: category
        )
    }
    
    init(alert: Alert, badge: Int?, category: String) {
        self.alert = alert
        self.badge = badge
        self.category = category
    }
    
    func encode(with coder: NSCoder) {
        coder.encode(self.alert, forKey: CodingKeys.alert.rawValue)
        coder.encode(self.badge, forKey: CodingKeys.badge.rawValue)
        coder.encode(self.category, forKey: CodingKeys.category.rawValue)
    }
}

// MARK: - Alert
class Alert: NSObject, Codable, NSCoding {
    let title: String
    let body: String?
    let subtitle: String?
    
    enum CodingKeys: String, CodingKey {
        case title
        case body
        case subtitle
    }
    
    init(title: String, body: String, subtitle: String?) {
        self.title = title
        self.body = body
        self.subtitle = subtitle
    }
    
    required convenience init?(coder decoder: NSCoder) {
        guard let title = decoder.decodeObject(forKey: CodingKeys.title.rawValue) as? String,
        let body = decoder.decodeObject(forKey: CodingKeys.body.rawValue) as? String else {
            return nil
        }
        
        let subtitle = decoder.decodeObject(forKey: CodingKeys.subtitle.rawValue) as? String
        
        self.init(
            title: title,
            body: body,
            subtitle: subtitle
        )
    }
    
    func encode(with coder: NSCoder) {
        coder.encode(self.title, forKey: CodingKeys.title.rawValue)
        coder.encode(self.body, forKey: CodingKeys.body.rawValue)
        coder.encode(self.subtitle, forKey: CodingKeys.subtitle.rawValue)
    }
}
