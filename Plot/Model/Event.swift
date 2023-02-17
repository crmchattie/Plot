//
//  Event.swift
//  Plot
//
//  Created by Cory McHattie on 8/18/22.
//  Copyright © 2022 Immature Creations. All rights reserved.
//

import UIKit
import Firebase
import CodableFirebase

let eventsEntity = "events"
let userEventsEntity = "user-events"

//class Event: NSObject {
//    var calendarID: String?
//    var calendarName: String?
//    var calendarColor: String?
//    var calendarSource: String?
//    var locationName: String?
//    var locationAddress: [String : [Double]]?
//    var allDay: Bool?
//    var startDateTime: NSNumber?
//    var startTimeZone: String?
//    var endDateTime: NSNumber?
//    var endTimeZone: String?
//    var isSchedule: Bool?
//    var userCompleted: Bool?
//    var userCompletedDate: NSNumber?
//    var scheduleIDs: [String]?
//
//    enum CodingKeys: String, CodingKey {
//        case activityID
//        case externalActivityID
//        case name
//        case calendarID
//        case calendarName
//        case calendarColor
//        case calendarSource
//        case activityType
//        case category
//        case allDay
//        case startTimeZone
//        case endTimeZone
//        case activityDescription
//        case isGroupActivity
//        case locationName
//        case locationAddress
//        case transportation
//        case activityOriginalPhotoURL
//        case activityThumbnailPhotoURL
//        case reminder
//        case recurrences
//        case notes
//        case checklistIDs
//        case activitylistIDs
//        case packinglistIDs
//        case grocerylistID
//        case containerID
//        case calendarExport
//        case showExtras
//        case isCompleted
//        case userCompleted
//        case isTask
//        case isEvent
//        case isSchedule
//        case scheduleIDs
//    }
//
//    init(activityID: String, admin: String, calendarID: String, calendarName: String, calendarColor: String, calendarSource: String, allDay: Bool, startDateTime: NSNumber, startTimeZone: String, endDateTime: NSNumber, endTimeZone: String, isEvent: Bool) {
//        self.activityID = activityID
//        self.admin = admin
//        self.calendarID = calendarID
//        self.calendarName = calendarName
//        self.calendarColor = calendarColor
//        self.calendarSource = calendarSource
//        self.allDay = allDay
//        self.startDateTime = startDateTime
//        self.startTimeZone = startTimeZone
//        self.endDateTime = endDateTime
//        self.endTimeZone = endTimeZone
//        self.isEvent = isEvent
//    }
//
//    init(activityID: String, admin: String, isTask: Bool, isCompleted: Bool) {
//        self.activityID = activityID
//        self.admin = admin
//        self.isTask = isTask
//        self.isCompleted = isCompleted
//    }
//
//    init(dictionary: [String: AnyObject]?) {
//        super.init()
//
//        activityID = dictionary?["activityID"] as? String
//        externalActivityID = dictionary?["externalActivityID"] as? String
//        name = dictionary?["name"] as? String
//        calendarID = dictionary?["calendarID"] as? String
//        calendarName = dictionary?["calendarName"] as? String
//        calendarColor = dictionary?["calendarColor"] as? String
//        calendarSource = dictionary?["calendarSource"] as? String
//        activityType = dictionary?["activityType"] as? String
//        category = dictionary?["category"] as? String
//        activityDescription = dictionary?["activityDescription"] as? String
//        locationName = dictionary?["locationName"] as? String
//        locationAddress = dictionary?["locationAddress"] as? [String : [Double]]
//
//        if let participantsIDsDict = dictionary?["participantsIDs"] as? [String: String] {
//            participantsIDs = Array(participantsIDsDict.keys)
//        } else if let participantsIDsArray = dictionary?["participantsIDs"] as? [String] {
//            participantsIDs = participantsIDsArray
//        } else {
//            participantsIDs = []
//        }
//
//        transportation = dictionary?["transportation"] as? String
//        activityOriginalPhotoURL = dictionary?["activityOriginalPhotoURL"] as? String
//        activityThumbnailPhotoURL = dictionary?["activityThumbnailPhotoURL"] as? String
//        activityPhotos = dictionary?["activityPhotos"] as? [String]
//        activityFiles = dictionary?["activityFiles"] as? [String]
//        allDay = dictionary?["allDay"] as? Bool
//        startDateTime = dictionary?["startDateTime"] as? NSNumber
//        startTimeZone = dictionary?["startTimeZone"] as? String
//        endDateTime = dictionary?["endDateTime"] as? NSNumber
//        endTimeZone = dictionary?["endTimeZone"] as? String
//        recurrences = dictionary?["recurrences"] as? [String]
//        reminder = dictionary?["reminder"] as? String
//        notes = dictionary?["notes"] as? String
//        isGroupActivity = dictionary?["isGroupActivity"] as? Bool
//        admin = dictionary?["admin"] as? String
//        badge = dictionary?["badge"] as? Int
//        pinned = dictionary?["pinned"] as? Bool
//        muted = dictionary?["muted"] as? Bool
//        conversationID = dictionary?["conversationID"] as? String
//        grocerylistID = dictionary?["grocerylistID"] as? String
//        checklistIDs = dictionary?["checklistIDs"] as? [String]
//        activitylistIDs = dictionary?["activitylistIDs"] as? [String]
//        packinglistIDs = dictionary?["packinglistIDs"] as? [String]
//        calendarExport = dictionary?["calendarExport"] as? Bool
//        containerID = dictionary?["containerID"] as? String
//        showExtras = dictionary?["showExtras"] as? Bool
//        isCompleted = dictionary?["isCompleted"] as? Bool
//        completedDate = dictionary?["completedDate"] as? NSNumber
//        userCompleted = dictionary?["userCompleted"] as? Bool
//        userCompletedDate = dictionary?["userCompletedDate"] as? NSNumber
//        isTask = dictionary?["isTask"] as? Bool
//        isEvent = dictionary?["isEvent"] as? Bool
//        isSchedule = dictionary?["isSchedule"] as? Bool
//        scheduleIDs = dictionary?["scheduleIDs"] as? [String]
//    }
//
//    func copy(with zone: NSZone? = nil) -> Any {
//        let copy = Event(dictionary: self.toAnyObject())
//        return copy
//    }
//
//    func toAnyObject() -> [String: AnyObject] {
//        var dictionary = [String: AnyObject]()
//        if let value = self.activityID as AnyObject? {
//            dictionary["activityID"] = value
//        }
//
//        if let value = self.externalActivityID as AnyObject? {
//            dictionary["externalActivityID"] = value
//        }
//
//        if let value = self.name as AnyObject? {
//            dictionary["name"] = value
//        }
//
//        if let value = self.admin as AnyObject? {
//            dictionary["admin"] = value
//        }
//
//        if let value = self.calendarID as AnyObject? {
//            dictionary["calendarID"] = value
//        }
//
//        if let value = self.calendarName as AnyObject? {
//            dictionary["calendarName"] = value
//        }
//
//        if let value = self.calendarColor as AnyObject? {
//            dictionary["calendarColor"] = value
//        }
//
//        if let value = self.calendarSource as AnyObject? {
//            dictionary["calendarSource"] = value
//        }
//
//        if let value = self.activityType as AnyObject? {
//            dictionary["activityType"] = value
//        }
//
//        if let value = self.category as AnyObject? {
//            dictionary["category"] = value
//        }
//
//        if let value = self.activityDescription as AnyObject? {
//            dictionary["activityDescription"] = value
//        }
//
//        if let value = self.locationName as AnyObject? {
//            dictionary["locationName"] = value
//        }
//
//        if let value = self.locationAddress as AnyObject? {
//            dictionary["locationAddress"] = value
//        }
//
//        if let value = self.participantsIDs as AnyObject? {
//            dictionary["participantsIDs"] = value
//        }
//
//        if let value = self.transportation as AnyObject? {
//            dictionary["transportation"] = value
//        }
//
//        if let value = self.activityOriginalPhotoURL as AnyObject? {
//            dictionary["activityOriginalPhotoURL"] = value
//        }
//
//        if let value = self.activityThumbnailPhotoURL as AnyObject? {
//            dictionary["activityThumbnailPhotoURL"] = value
//        }
//
//        if let value = self.activityPhotos as AnyObject? {
//            dictionary["activityPhotos"] = value
//        }
//
//        if let value = self.activityFiles as AnyObject? {
//            dictionary["activityFiles"] = value
//        }
//
//        if let value = self.allDay as AnyObject? {
//            dictionary["allDay"] = value
//        }
//
//        if let value = self.startDateTime as AnyObject? {
//            dictionary["startDateTime"] = value
//        }
//
//        if let value = self.startTimeZone as AnyObject? {
//            dictionary["startTimeZone"] = value
//        }
//
//        if let value = self.endDateTime as AnyObject? {
//            dictionary["endDateTime"] = value
//        }
//
//        if let value = self.recurrences as AnyObject? {
//            dictionary["recurrences"] = value
//        }
//
//        if let value = self.endTimeZone as AnyObject? {
//            dictionary["endTimeZone"] = value
//        }
//
//        if let value = self.notes as AnyObject? {
//            dictionary["notes"] = value
//        }
//
//        if let value = self.conversationID as AnyObject? {
//            dictionary["conversationID"] = value
//        }
//
//        if let value = self.grocerylistID as AnyObject? {
//            dictionary["grocerylistID"] = value
//        }
//
//        if let value = self.checklistIDs as AnyObject? {
//            dictionary["checklistIDs"] = value
//        }
//
//        if let value = self.activitylistIDs as AnyObject? {
//            dictionary["activitylistIDs"] = value
//        }
//
//        if let value = self.packinglistIDs as AnyObject? {
//            dictionary["packinglistIDs"] = value
//        }
//
//        if let value = self.containerID as AnyObject? {
//            dictionary["containerID"] = value
//        }
//
//        if let value = self.showExtras as AnyObject? {
//            dictionary["showExtras"] = value
//        }
//
//        if let value = self.isCompleted as AnyObject? {
//            dictionary["isCompleted"] = value
//        }
//
//        if let value = self.completedDate as AnyObject? {
//            dictionary["completedDate"] = value
//        }
//
//        if let value = self.userCompleted as AnyObject? {
//            dictionary["isCompleted"] = value
//        }
//
//        if let value = self.userCompletedDate as AnyObject? {
//            dictionary["completedDate"] = value
//        }
//
//        if let value = self.isTask as AnyObject? {
//            dictionary["isTask"] = value
//        }
//
//        if let value = self.isEvent as AnyObject? {
//            dictionary["isEvent"] = value
//        }
//
//        if let value = self.isSchedule as AnyObject? {
//            dictionary["isSchedule"] = value
//        }
//
//        if let value = self.scheduleIDs as AnyObject? {
//            dictionary["scheduleIDs"] = value
//        }
//
//        return dictionary
//    }
//
//    static func == (lhs: Event, rhs: Event) -> Bool {
//        return lhs.activityID == rhs.activityID
//    }
//}
