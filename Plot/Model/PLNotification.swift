//
//  PLNotification.swift
//  Plot
//
//  Created by Cory McHattie on 6/2/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import Foundation

class PLNotification: NSObject, Codable, NSCoding {
    let chatID: String?
    let activityID: String?
    let checklistID: String?
    let grocerylistID: String?
    let activitylistID: String?
    let mealID: String?
    let workoutID: String?
    let mindfulnessID: String?
    let transactionID: String?
    let accountID: String?
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
        case activitylistID
        case mealID
        case workoutID
        case mindfulnessID
        case transactionID
        case accountID
    }
    
    init(chatID: String?, activityID: String?, checklistID: String?, grocerylistID: String?, activitylistID: String?, mealID: String?, workoutID: String?, mindfulnessID: String?, transactionID: String?, accountID: String?, googleCAE: String?, gcmMessageID: String?, aps: Aps) {
        self.chatID = chatID
        self.activityID = activityID
        self.checklistID = checklistID
        self.grocerylistID = grocerylistID
        self.activitylistID = activitylistID
        self.mealID = mealID
        self.workoutID = workoutID
        self.mindfulnessID = mindfulnessID
        self.transactionID = transactionID
        self.accountID = accountID
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
        let activitylistID = decoder.decodeObject(forKey: CodingKeys.activitylistID.rawValue) as? String
        let mealID = decoder.decodeObject(forKey: CodingKeys.mealID.rawValue) as? String
        let workoutID = decoder.decodeObject(forKey: CodingKeys.workoutID.rawValue) as? String
        let mindfulnessID = decoder.decodeObject(forKey: CodingKeys.mindfulnessID.rawValue) as? String
        let transactionID = decoder.decodeObject(forKey: CodingKeys.transactionID.rawValue) as? String
        let accountID = decoder.decodeObject(forKey: CodingKeys.accountID.rawValue) as? String
        let googleCAE = decoder.decodeObject(forKey: CodingKeys.googleCAE.rawValue) as? String
        let gcmMessageID = decoder.decodeObject(forKey: CodingKeys.gcmMessageID.rawValue) as? String
        
        self.init(
            chatID: chatID,
            activityID: activityID,
            checklistID: checklistID,
            grocerylistID: grocerylistID,
            activitylistID: activitylistID,
            mealID: mealID,
            workoutID: workoutID,
            mindfulnessID: mindfulnessID,
            transactionID: transactionID,
            accountID: accountID,
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
        coder.encode(self.activitylistID, forKey: CodingKeys.activitylistID.rawValue)
        coder.encode(self.mealID, forKey: CodingKeys.mealID.rawValue)
        coder.encode(self.workoutID, forKey: CodingKeys.workoutID.rawValue)
        coder.encode(self.mindfulnessID, forKey: CodingKeys.mindfulnessID.rawValue)
        coder.encode(self.transactionID, forKey: CodingKeys.transactionID.rawValue)
        coder.encode(self.accountID, forKey: CodingKeys.accountID.rawValue)
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
        } else if aps.category == "ACTIVITYLIST_CATEGORY" {
            if let subtitle = self.aps.alert.subtitle, let body = self.aps.alert.body {
                let newSubtitle = subtitle.trimmingCharacters(in: .whitespaces)
                let newBody = body.replacingOccurrences(of: "The activity list", with: "The \(newSubtitle) activity list")
                return "\(newBody) by \(self.aps.alert.title)"
            }
        } else if aps.category == "MEAL_CATEGORY" {
            if let subtitle = self.aps.alert.subtitle, let body = self.aps.alert.body {
                let newSubtitle = subtitle.trimmingCharacters(in: .whitespaces)
                let newBody = body.replacingOccurrences(of: "The meal", with: "The \(newSubtitle) meal")
                return "\(newBody) by \(self.aps.alert.title)"
            }
        } else if aps.category == "WORKOUT_CATEGORY" {
            if let subtitle = self.aps.alert.subtitle, let body = self.aps.alert.body {
                let newSubtitle = subtitle.trimmingCharacters(in: .whitespaces)
                let newBody = body.replacingOccurrences(of: "The workout", with: "The \(newSubtitle) workout")
                return "\(newBody) by \(self.aps.alert.title)"
            }
        } else if aps.category == "MINDFULNESS_CATEGORY" {
            if let subtitle = self.aps.alert.subtitle, let body = self.aps.alert.body {
                let newSubtitle = subtitle.trimmingCharacters(in: .whitespaces)
                let newBody = body.replacingOccurrences(of: "The mindfulness", with: "The \(newSubtitle) mindfulness")
                return "\(newBody) by \(self.aps.alert.title)"
            }
        } else if aps.category == "TRANSACTION_CATEGORY" {
            if let subtitle = self.aps.alert.subtitle, let body = self.aps.alert.body {
                let newSubtitle = subtitle.trimmingCharacters(in: .whitespaces)
                let newBody = body.replacingOccurrences(of: "The transaction", with: "The \(newSubtitle) transaction")
                return "\(newBody) by \(self.aps.alert.title)"
            }
        } else if aps.category == "ACCOUNT_CATEGORY" {
            if let subtitle = self.aps.alert.subtitle, let body = self.aps.alert.body {
                let newSubtitle = subtitle.trimmingCharacters(in: .whitespaces)
                let newBody = body.replacingOccurrences(of: "The financial account", with: "The \(newSubtitle) financial account")
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
