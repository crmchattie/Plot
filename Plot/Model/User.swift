//
//  User.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 8/6/17.
//  Copyright © 2017 Roman Mizin. All rights reserved.
//

import UIKit

let userCalendarEventsEntity = "user-calendar-events"
let calendarEventsKey = "calendar-events"

let userReminderTasksEntity = "user-reminders-tasks"
let reminderTasksKey = "reminders-tasks"

class User: NSObject {
    
    var id: String?
    @objc var name: String?
    var bio: String?
    var photoURL: String?
    var thumbnailPhotoURL: String?
    var phoneNumber: String?
    var fcmToken: String?
    var badge: Int?
    var onlineStatus: AnyObject?
    var weight: Int?
    var height: Int?
    var contacted: Bool? // used for reaching out to users
    var contactedDate: String? // used for reaching out to users
    var isSelected: Bool! = false // local only
    var survey: [String : [String]]?

    init(dictionary: [String: AnyObject]) {
        id = dictionary["id"] as? String
        name = dictionary["name"] as? String
        bio = dictionary["bio"] as? String
        photoURL = dictionary["photoURL"] as? String
        thumbnailPhotoURL = dictionary["thumbnailPhotoURL"] as? String
        phoneNumber = dictionary["phoneNumber"] as? String
        fcmToken = dictionary["fcmToken"] as? String
        badge = dictionary["badge"] as? Int
        contacted = dictionary["contacted"] as? Bool
        contactedDate = dictionary["contactedDate"] as? String
        survey = dictionary["survey"] as? [String : [String]]
        onlineStatus = dictionary["OnlineStatus"]// as? AnyObject
    }
    
    static func == (lhs: User, rhs: User) -> Bool {
        return lhs.id == rhs.id &&
            lhs.name == rhs.name &&
            lhs.bio == rhs.bio &&
            lhs.photoURL == rhs.photoURL &&
            lhs.thumbnailPhotoURL == rhs.thumbnailPhotoURL &&
            lhs.phoneNumber == rhs.phoneNumber &&
            lhs.fcmToken == rhs.fcmToken &&
            lhs.badge == rhs.badge
    }
}

extension User { // local only
    var titleFirstLetter: String {
        if name != "" && name != nil {
            return String(name![name!.startIndex]).uppercased()
        } else {
            return ""
        }
    }
}
