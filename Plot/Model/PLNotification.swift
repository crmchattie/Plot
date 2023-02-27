//
//  PLNotification.swift
//  Plot
//
//  Created by Cory McHattie on 6/2/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import Foundation

class PLNotification: NSObject, Codable, NSCoding {
    let objectID: String?
    let googleCAE: String?
    let gcmMessageID: String?
    let aps: Aps

    enum CodingKeys: String, CodingKey {
        case googleCAE = "google.c.a.e"
        case objectID
        case gcmMessageID = "gcm.message_id"
        case aps
    }
    
    init(objectID: String?, googleCAE: String?, gcmMessageID: String?, aps: Aps) {
        self.objectID = objectID
        self.googleCAE = googleCAE
        self.gcmMessageID = gcmMessageID
        self.aps = aps
    }
    
    required convenience init?(coder decoder: NSCoder) {
        guard let aps = decoder.decodeObject(forKey: CodingKeys.aps.rawValue) as? Aps else {
            return nil
        }
        
        let objectID = decoder.decodeObject(forKey: CodingKeys.objectID.rawValue) as? String
        let googleCAE = decoder.decodeObject(forKey: CodingKeys.googleCAE.rawValue) as? String
        let gcmMessageID = decoder.decodeObject(forKey: CodingKeys.gcmMessageID.rawValue) as? String
        
        self.init(
            objectID: objectID,
            googleCAE: googleCAE,
            gcmMessageID: gcmMessageID,
            aps: aps
        )
    }
    
    func encode(with coder: NSCoder) {
        coder.encode(self.objectID, forKey: CodingKeys.objectID.rawValue)
        coder.encode(self.googleCAE, forKey: CodingKeys.googleCAE.rawValue)
        coder.encode(self.gcmMessageID, forKey: CodingKeys.gcmMessageID.rawValue)
        coder.encode(self.aps, forKey: CodingKeys.aps.rawValue)
    }
    
    override var description: String {
        if aps.category == Identifiers.eventCategory {
            if let subtitle = self.aps.alert.subtitle, let body = self.aps.alert.body {
                let newSubtitle = subtitle.trimmingCharacters(in: .whitespaces)
                let newBody = body.replacingOccurrences(of: "The event", with: "The \(newSubtitle) event")
                return "\(newBody) by \(self.aps.alert.title)"
            } else {
                return "\(self.aps.alert.title) invited you to a new event"
            }
        } else if aps.category == Identifiers.taskCategory {
            if let subtitle = self.aps.alert.subtitle, let body = self.aps.alert.body {
                let newSubtitle = subtitle.trimmingCharacters(in: .whitespaces)
                let newBody = body.replacingOccurrences(of: "The task", with: "The \(newSubtitle) task")
                return "\(newBody) by \(self.aps.alert.title)"
            } else {
                return "\(self.aps.alert.title) added you to a task"
            }
        } else if aps.category == Identifiers.goalCategory {
            if let subtitle = self.aps.alert.subtitle, let body = self.aps.alert.body {
                let newSubtitle = subtitle.trimmingCharacters(in: .whitespaces)
                let newBody = body.replacingOccurrences(of: "The goal", with: "The \(newSubtitle) goal")
                return "\(newBody) by \(self.aps.alert.title)"
            } else {
                return "\(self.aps.alert.title) added you to a task"
            }
        } else if aps.category == Identifiers.workoutCategory {
            if let subtitle = self.aps.alert.subtitle, let body = self.aps.alert.body {
                let newSubtitle = subtitle.trimmingCharacters(in: .whitespaces)
                let newBody = body.replacingOccurrences(of: "The workout", with: "The \(newSubtitle) workout")
                return "\(newBody) by \(self.aps.alert.title)"
            } else {
                return "\(self.aps.alert.title) added you to a workout"
            }
        } else if aps.category == Identifiers.mindfulnessCategory {
            if let subtitle = self.aps.alert.subtitle, let body = self.aps.alert.body {
                let newSubtitle = subtitle.trimmingCharacters(in: .whitespaces)
                let newBody = body.replacingOccurrences(of: "The mindfulness", with: "The \(newSubtitle) mindfulness")
                return "\(newBody) by \(self.aps.alert.title)"
            } else {
                return "\(self.aps.alert.title) added you to a mindfulness session"
            }
        } else if aps.category == Identifiers.transactionCategory {
            if let subtitle = self.aps.alert.subtitle, let body = self.aps.alert.body {
                let newSubtitle = subtitle.trimmingCharacters(in: .whitespaces)
                let newBody = body.replacingOccurrences(of: "The transaction", with: "The \(newSubtitle) transaction")
                return "\(newBody) by \(self.aps.alert.title)"
            } else {
                return "\(self.aps.alert.title) added you to a transaction"
            }
        } else if aps.category == Identifiers.accountCategory {
            if let subtitle = self.aps.alert.subtitle, let body = self.aps.alert.body {
                let newSubtitle = subtitle.trimmingCharacters(in: .whitespaces)
                let newBody = body.replacingOccurrences(of: "The financial account", with: "The \(newSubtitle) financial account")
                return "\(newBody) by \(self.aps.alert.title)"
            } else {
                return "\(self.aps.alert.title) added you to a financial account"
            }
        } else if aps.category == Identifiers.calendarCategory {
            if let subtitle = self.aps.alert.subtitle, let body = self.aps.alert.body {
                let newSubtitle = subtitle.trimmingCharacters(in: .whitespaces)
                let newBody = body.replacingOccurrences(of: "The calendar", with: "The \(newSubtitle) calendar")
                return "\(newBody) by \(self.aps.alert.title)"
            } else {
                return "\(self.aps.alert.title) added you to a calendar"
            }
        } else if aps.category == Identifiers.listCategory {
            if let subtitle = self.aps.alert.subtitle, let body = self.aps.alert.body {
                let newSubtitle = subtitle.trimmingCharacters(in: .whitespaces)
                let newBody = body.replacingOccurrences(of: "The list", with: "The \(newSubtitle) list")
                return "\(newBody) by \(self.aps.alert.title)"
            } else {
                return "\(self.aps.alert.title) added you to a list"
            }
        }
//        else if aps.category == "CHAT_CATEGORY" {
//            return "\(self.aps.alert.title) sent you a message"
//        }
//        else if aps.category == "CHECKLIST_CATEGORY" {
//            if let subtitle = self.aps.alert.subtitle, let body = self.aps.alert.body {
//                let newSubtitle = subtitle.trimmingCharacters(in: .whitespaces)
//                let newBody = body.replacingOccurrences(of: "The checklist", with: "The \(newSubtitle) checklist")
//                return "\(newBody) by \(self.aps.alert.title)"
//            }
//        } else if aps.category == "GROCERYLIST_CATEGORY" {
//            if let subtitle = self.aps.alert.subtitle, let body = self.aps.alert.body {
//                let newSubtitle = subtitle.trimmingCharacters(in: .whitespaces)
//                let newBody = body.replacingOccurrences(of: "The grocery list", with: "The \(newSubtitle) grocery list")
//                return "\(newBody) by \(self.aps.alert.title)"
//            }
//        } else if aps.category == "ACTIVITYLIST_CATEGORY" {
//            if let subtitle = self.aps.alert.subtitle, let body = self.aps.alert.body {
//                let newSubtitle = subtitle.trimmingCharacters(in: .whitespaces)
//                let newBody = body.replacingOccurrences(of: "The activity list", with: "The \(newSubtitle) activity list")
//                return "\(newBody) by \(self.aps.alert.title)"
//            }
//        }
//        else if aps.category == "MEAL_CATEGORY" {
//            if let subtitle = self.aps.alert.subtitle, let body = self.aps.alert.body {
//                let newSubtitle = subtitle.trimmingCharacters(in: .whitespaces)
//                let newBody = body.replacingOccurrences(of: "The meal", with: "The \(newSubtitle) meal")
//                return "\(newBody) by \(self.aps.alert.title)"
//            }
//        }
        
        return ""
    }
}

// MARK: - Aps
class Aps: NSObject, Codable, NSCoding {
    let alert: Alert
    let badge: Int?
    let category: String
    let date: Int?
    
    enum CodingKeys: String, CodingKey {
        case alert
        case badge
        case category
        case date
    }
    
    required convenience init?(coder decoder: NSCoder) {
        guard let alert = decoder.decodeObject(forKey: CodingKeys.alert.rawValue) as? Alert,
        let category = decoder.decodeObject(forKey: CodingKeys.category.rawValue) as? String else {
            return nil
        }
        
        let badge = decoder.decodeObject(forKey: CodingKeys.badge.rawValue) as? Int
        let date = decoder.decodeObject(forKey: CodingKeys.date.rawValue) as? Int
        
        self.init(
            alert: alert,
            badge: badge,
            category: category,
            date: date
        )
    }
    
    init(alert: Alert, badge: Int?, category: String, date: Int?) {
        self.alert = alert
        self.badge = badge
        self.category = category
        self.date = date
    }
    
    func encode(with coder: NSCoder) {
        coder.encode(self.alert, forKey: CodingKeys.alert.rawValue)
        coder.encode(self.badge, forKey: CodingKeys.badge.rawValue)
        coder.encode(self.category, forKey: CodingKeys.category.rawValue)
        coder.encode(self.date, forKey: CodingKeys.date.rawValue)
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
