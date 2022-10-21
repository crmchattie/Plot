//
//  Activity.swift
//  Pigeon-project
//
//  Created by Cory McHattie on 4/27/19.
//  Copyright © 2019 Immature Creations. All rights reserved.
//

import UIKit
import Firebase
import CodableFirebase

let activitiesEntity = "activities"
let userActivitiesEntity = "user-activities"
let userFavActivitiesEntity = "user-fav-activities"

class Activity: NSObject, NSCopying, Codable {
    var activityID: String?
    var externalActivityID: String?
    var name: String?
    var calendarID: String?
    var calendarName: String?
    var calendarColor: String?
    var calendarSource: String?
    var listID: String?
    var listName: String?
    var listColor: String?
    var listSource: String?
    var activityType: String?
    var category: String?
    var subcategory: String?
    var activityDescription: String?
    var locationName: String?
    var locationAddress: [String : [Double]]?
    var participantsIDs: [String]?
    var transportation: String?
    var activityOriginalPhotoURL: String?
    var activityThumbnailPhotoURL: String?
    var activityPhotos: [String]?
    var activityFiles: [String]?
    var allDay: Bool?
    var startDateTime: NSNumber?
    var startTimeZone: String?
    var endDateTime: NSNumber?
    var endTimeZone: String?
    // A list of RFC-5545 (iCal) expressions.
    // https://tools.ietf.org/html/rfc5545
    //
    // Both Google and iCloud events are transfomed into this expression.
    var recurrences: [String]?
    var recurrenceStartDateTime: NSNumber?
    var reminder: String?
    var notes: String?
    var checklistIDs: [String]?
    var activitylistIDs: [String]?
    var packinglistIDs: [String]?
    var grocerylistID: String?
    var isGroupActivity: Bool?
    var admin: String?
    var badge: Int?
    var badgeDate: [String: Int]?
    var pinned: Bool?
    var muted: Bool?
    //instance or recurring variable
    var containerID: String?
    var conversationID: String?
    var calendarExport: Bool?
    var showExtras: Bool?
    var isEvent: Bool?
    //task will key off of isTask and isCompleted
    var isTask: Bool?
    
    //instance variable
    var isCompleted: Bool?
    //instance variable
    var completedDate: NSNumber?
    var userIsCompleted: Bool?
    var userCompletedDate: NSNumber?
    var scheduleIDs: [String]?
    var isSchedule: Bool?
    var subtaskIDs: [String]?
    var isSubtask: Bool?
    var hasStartTime: Bool?
    var hasDeadlineTime: Bool?
    var flagged: Bool?
    var tags: [String]?
    var priority: String?
    var lastModifiedDate: NSNumber?
    var createdDate: NSNumber?
    //instance variables
    var recurringEventID: String?
    var instanceOriginalStartDateTime: NSNumber?
    var instanceOriginalAllDay: Bool?
    var instanceOriginalStartTimeZone: String?
    var instanceIDs: [String]?
    var instanceID: String?
    
    enum CodingKeys: String, CodingKey {
        case activityID
        case externalActivityID
        case name
        case calendarID
        case calendarName
        case calendarColor
        case calendarSource
        case activityType
        case category
        case subcategory
        case allDay
        case startTimeZone
        case endTimeZone
        case activityDescription
        case isGroupActivity
        case locationName
        case locationAddress
        case transportation
        case activityOriginalPhotoURL
        case activityThumbnailPhotoURL
        case reminder
        case recurrences
        case notes
        case checklistIDs
        case activitylistIDs
        case packinglistIDs
        case grocerylistID
        case containerID
        case calendarExport
        case showExtras
        case isCompleted
        case userIsCompleted
        case isTask
        case isEvent
        case isSchedule
        case scheduleIDs
        case listID
        case listName
        case listColor
        case listSource
        case subtaskIDs
        case isSubtask
        case hasStartTime
        case hasDeadlineTime
        case flagged
        case tags
        case priority
        case recurringEventID
        case instanceIDs
        case instanceID
    }
    
    init(activityID: String, admin: String, calendarID: String, calendarName: String, calendarColor: String, calendarSource: String, allDay: Bool, startDateTime: NSNumber, startTimeZone: String, endDateTime: NSNumber, endTimeZone: String, isEvent: Bool, createdDate: NSNumber) {
        self.activityID = activityID
        self.admin = admin
        self.calendarID = calendarID
        self.calendarName = calendarName
        self.calendarColor = calendarColor
        self.calendarSource = calendarSource
        self.allDay = allDay
        self.startDateTime = startDateTime
        self.startTimeZone = startTimeZone
        self.endDateTime = endDateTime
        self.endTimeZone = endTimeZone
        self.isEvent = isEvent
        self.createdDate = createdDate
        self.lastModifiedDate = createdDate
    }
    
    init(activityID: String, admin: String, listID: String, listName: String, listColor: String, listSource: String, isTask: Bool, isCompleted: Bool, createdDate: NSNumber) {
        self.activityID = activityID
        self.admin = admin
        self.isTask = isTask
        self.isCompleted = isCompleted
        self.listID = listID
        self.listName = listName
        self.listColor = listColor
        self.listSource = listSource
        self.createdDate = createdDate
        self.lastModifiedDate = createdDate
    }
    
    init(dictionary: [String: AnyObject]?) {
        super.init()
        
        activityID = dictionary?["activityID"] as? String
        externalActivityID = dictionary?["externalActivityID"] as? String
        name = dictionary?["name"] as? String
        calendarID = dictionary?["calendarID"] as? String
        calendarName = dictionary?["calendarName"] as? String
        calendarColor = dictionary?["calendarColor"] as? String
        calendarSource = dictionary?["calendarSource"] as? String
        activityType = dictionary?["activityType"] as? String
        category = dictionary?["category"] as? String
        subcategory = dictionary?["subcategory"] as? String
        activityDescription = dictionary?["activityDescription"] as? String
        locationName = dictionary?["locationName"] as? String
        locationAddress = dictionary?["locationAddress"] as? [String : [Double]]
        
        if let participantsIDsDict = dictionary?["participantsIDs"] as? [String: String] {
            participantsIDs = Array(participantsIDsDict.keys)
        } else if let participantsIDsArray = dictionary?["participantsIDs"] as? [String] {
            participantsIDs = participantsIDsArray
        } else {
            participantsIDs = []
        }
        
        transportation = dictionary?["transportation"] as? String
        activityOriginalPhotoURL = dictionary?["activityOriginalPhotoURL"] as? String
        activityThumbnailPhotoURL = dictionary?["activityThumbnailPhotoURL"] as? String
        activityPhotos = dictionary?["activityPhotos"] as? [String]
        activityFiles = dictionary?["activityFiles"] as? [String]
        allDay = dictionary?["allDay"] as? Bool
        startDateTime = dictionary?["startDateTime"] as? NSNumber
        startTimeZone = dictionary?["startTimeZone"] as? String
        endDateTime = dictionary?["endDateTime"] as? NSNumber
        endTimeZone = dictionary?["endTimeZone"] as? String
        recurrences = dictionary?["recurrences"] as? [String]
        recurrenceStartDateTime = dictionary?["recurrenceStartDateTime"] as? NSNumber
        reminder = dictionary?["reminder"] as? String
        notes = dictionary?["notes"] as? String
        isGroupActivity = dictionary?["isGroupActivity"] as? Bool
        admin = dictionary?["admin"] as? String
        badge = dictionary?["badge"] as? Int
        badgeDate = dictionary?["badgeDate"] as? [String: Int]
        pinned = dictionary?["pinned"] as? Bool
        muted = dictionary?["muted"] as? Bool
        conversationID = dictionary?["conversationID"] as? String
        grocerylistID = dictionary?["grocerylistID"] as? String
        checklistIDs = dictionary?["checklistIDs"] as? [String]
        activitylistIDs = dictionary?["activitylistIDs"] as? [String]
        packinglistIDs = dictionary?["packinglistIDs"] as? [String]
        calendarExport = dictionary?["calendarExport"] as? Bool
        containerID = dictionary?["containerID"] as? String
        showExtras = dictionary?["showExtras"] as? Bool
        isCompleted = dictionary?["isCompleted"] as? Bool
        completedDate = dictionary?["completedDate"] as? NSNumber
        userIsCompleted = dictionary?["userIsCompleted"] as? Bool
        userCompletedDate = dictionary?["userCompletedDate"] as? NSNumber
        isTask = dictionary?["isTask"] as? Bool
        isEvent = dictionary?["isEvent"] as? Bool
        isSchedule = dictionary?["isSchedule"] as? Bool
        scheduleIDs = dictionary?["scheduleIDs"] as? [String]
        listID = dictionary?["listID"] as? String
        listName = dictionary?["listName"] as? String
        listColor = dictionary?["listColor"] as? String
        listSource = dictionary?["listSource"] as? String
        subtaskIDs = dictionary?["subtaskIDs"] as? [String]
        isSubtask = dictionary?["isSubtask"] as? Bool
        hasStartTime = dictionary?["hasStartTime"] as? Bool
        hasDeadlineTime = dictionary?["hasDeadlineTime"] as? Bool
        flagged = dictionary?["flagged"] as? Bool
        tags = dictionary?["tags"] as? [String]
        priority = dictionary?["priority"] as? String
        createdDate = dictionary?["createdDate"] as? NSNumber
        lastModifiedDate = dictionary?["lastModifiedDate"] as? NSNumber
        recurringEventID = dictionary?["recurringEventID"] as? String
        instanceOriginalStartDateTime = dictionary?["instanceOriginalStartDateTime"] as? NSNumber
        instanceOriginalAllDay = dictionary?["instanceOriginalAllDay"] as? Bool
        instanceOriginalStartTimeZone = dictionary?["instanceOriginalStartTimeZone"] as? String
        instanceIDs = dictionary?["instanceIDs"] as? [String]
        instanceID = dictionary?["instanceID"] as? String
    }
    
    func copy(with zone: NSZone? = nil) -> Any {
        let copy = Activity(dictionary: self.toAnyObject())
        return copy
    }
    
    func toAnyObject() -> [String: AnyObject] {
        var dictionary = [String: AnyObject]()
        if let value = self.activityID as AnyObject? {
            dictionary["activityID"] = value
        }
        
        if let value = self.externalActivityID as AnyObject? {
            dictionary["externalActivityID"] = value
        }
        
        if let value = self.calendarExport as AnyObject? {
            dictionary["calendarExport"] = value
        }
        
        if let value = self.name as AnyObject? {
            dictionary["name"] = value
        }
        
        if let value = self.admin as AnyObject? {
            dictionary["admin"] = value
        }
        
        if let value = self.activityType as AnyObject? {
            dictionary["activityType"] = value
        } else {
            dictionary["activityType"] = NSNull()
        }
        
        if let value = self.category as AnyObject? {
            dictionary["category"] = value
        }
        
        if let value = self.subcategory as AnyObject? {
            dictionary["subcategory"] = value
        }
        
        if let value = self.activityDescription as AnyObject? {
            dictionary["activityDescription"] = value
        } else {
            dictionary["activityDescription"] = NSNull()
        }
        
        if let value = self.locationName as AnyObject? {
            dictionary["locationName"] = value
        } else {
            dictionary["locationName"] = NSNull()
        }
        
        if let value = self.locationAddress as AnyObject? {
            dictionary["locationAddress"] = value
        } else {
            dictionary["locationAddress"] = NSNull()
        }
        
        if let value = self.participantsIDs as AnyObject? {
            dictionary["participantsIDs"] = value
        }
        
        if let value = self.transportation as AnyObject? {
            dictionary["transportation"] = value
        } else {
            dictionary["transportation"] = NSNull()
        }
        
        if let value = self.activityOriginalPhotoURL as AnyObject? {
            dictionary["activityOriginalPhotoURL"] = value
        } else {
            dictionary["activityOriginalPhotoURL"] = NSNull()
        }
        
        if let value = self.activityThumbnailPhotoURL as AnyObject? {
            dictionary["activityThumbnailPhotoURL"] = value
        } else {
            dictionary["activityThumbnailPhotoURL"] = NSNull()
        }
        
        if let value = self.activityPhotos as AnyObject? {
            dictionary["activityPhotos"] = value
        } else {
            dictionary["activityPhotos"] = NSNull()
        }
        
        if let value = self.activityFiles as AnyObject? {
            dictionary["activityFiles"] = value
        } else {
            dictionary["activityFiles"] = NSNull()
        }
        
        if let value = self.allDay as AnyObject? {
            dictionary["allDay"] = value
        }
        
        if let value = self.startDateTime as AnyObject? {
            dictionary["startDateTime"] = value
        } else {
            dictionary["startDateTime"] = NSNull()
        }
        
        if let value = self.startTimeZone as AnyObject? {
            dictionary["startTimeZone"] = value
        } else {
            dictionary["startTimeZone"] = NSNull()
        }
        
        if let value = self.endDateTime as AnyObject? {
            dictionary["endDateTime"] = value
        } else {
            dictionary["endDateTime"] = NSNull()
        }
        
        if let value = self.endTimeZone as AnyObject? {
            dictionary["endTimeZone"] = value
        } else {
            dictionary["endTimeZone"] = NSNull()
        }
        
        if let value = self.recurrences as AnyObject? {
            dictionary["recurrences"] = value
        }
        
        if let value = self.recurrenceStartDateTime as AnyObject? {
            dictionary["recurrenceStartDateTime"] = value
        }
        
        if let value = self.notes as AnyObject? {
            dictionary["notes"] = value
        } else {
            dictionary["notes"] = NSNull()
        }
        
        if let value = self.conversationID as AnyObject? {
            dictionary["conversationID"] = value
        } else {
            dictionary["conversationID"] = NSNull()
        }
        
        if let value = self.grocerylistID as AnyObject? {
            dictionary["grocerylistID"] = value
        } else {
            dictionary["grocerylistID"] = NSNull()
        }
        
        if let value = self.checklistIDs as AnyObject? {
            dictionary["checklistIDs"] = value
        } else {
            dictionary["checklistIDs"] = NSNull()
        }
        
        if let value = self.activitylistIDs as AnyObject? {
            dictionary["activitylistIDs"] = value
        } else {
            dictionary["activitylistIDs"] = NSNull()
        }
        
        if let value = self.packinglistIDs as AnyObject? {
            dictionary["packinglistIDs"] = value
        } else {
            dictionary["packinglistIDs"] = NSNull()
        }
        
        if let value = self.containerID as AnyObject? {
            dictionary["containerID"] = value
        } else {
            dictionary["containerID"] = NSNull()
        }
        
        if let value = self.showExtras as AnyObject? {
            dictionary["showExtras"] = value
        }
        
        if let value = self.isCompleted as AnyObject? {
            dictionary["isCompleted"] = value
        }
        
        if let value = self.completedDate as AnyObject? {
            dictionary["completedDate"] = value
        } else {
            dictionary["completedDate"] = NSNull()
        }
        
        if let value = self.userIsCompleted as AnyObject? {
            dictionary["userIsCompleted"] = value
        }
        
        if let value = self.userCompletedDate as AnyObject? {
            dictionary["userCompletedDate"] = value
        } else {
            dictionary["userCompletedDate"] = NSNull()
        }
        
        if let value = self.isTask as AnyObject? {
            dictionary["isTask"] = value
        }
        
        if let value = self.isEvent as AnyObject? {
            dictionary["isEvent"] = value
        }
        
        if let value = self.isSchedule as AnyObject? {
            dictionary["isSchedule"] = value
        }
        
        if let value = self.scheduleIDs as AnyObject? {
            dictionary["scheduleIDs"] = value
        } else {
            dictionary["scheduleIDs"] = NSNull()
        }
        
        if let value = self.createdDate as AnyObject? {
            dictionary["createdDate"] = value
        }
        
        if let value = self.lastModifiedDate as AnyObject? {
            dictionary["lastModifiedDate"] = value
        }
        
        if let value = self.listID as AnyObject? {
            dictionary["listID"] = value
        }

        if let value = self.listName as AnyObject? {
            dictionary["listName"] = value
        }

        if let value = self.listColor as AnyObject? {
            dictionary["listColor"] = value
        }

        if let value = self.listSource as AnyObject? {
            dictionary["listSource"] = value
        }
        
        if let value = self.calendarID as AnyObject? {
            dictionary["calendarID"] = value
        }

        if let value = self.calendarName as AnyObject? {
            dictionary["calendarName"] = value
        }

        if let value = self.calendarColor as AnyObject? {
            dictionary["calendarColor"] = value
        }

        if let value = self.calendarSource as AnyObject? {
            dictionary["calendarSource"] = value
        }
        
        if let value = self.subtaskIDs as AnyObject? {
            dictionary["subtaskIDs"] = value
        } else {
            dictionary["subtaskIDs"] = NSNull()
        }
        
        if let value = self.isSubtask as AnyObject? {
            dictionary["isSubtask"] = value
        }
        
        if let value = self.hasStartTime as AnyObject? {
            dictionary["hasStartTime"] = value
        }
        
        if let value = self.hasDeadlineTime as AnyObject? {
            dictionary["hasDeadlineTime"] = value
        }
        
        if let value = self.flagged as AnyObject? {
            dictionary["flagged"] = value
        }
        
        if let value = self.tags as AnyObject? {
            dictionary["tags"] = value
        } else {
            dictionary["tags"] = NSNull()
        }
        
        if let value = self.priority as AnyObject? {
            dictionary["priority"] = value
        }
        
        if let value = self.instanceIDs as AnyObject? {
            dictionary["instanceIDs"] = value
        }
        
        if let value = self.badge as AnyObject? {
            dictionary["badge"] = value
        }
        
        if let value = self.badgeDate as AnyObject? {
            dictionary["badgeDate"] = value
        }
        
        if let value = self.muted as AnyObject? {
            dictionary["muted"] = value
        }
        
        return dictionary
    }
    
    func updateActivityWActivity(updatingActivity: Activity) -> Activity {
        let newActivity = self.copy() as! Activity
        
        if let value = updatingActivity.activityID {
            newActivity.activityID = value
        }
        
        if let value = updatingActivity.externalActivityID {
            newActivity.externalActivityID = value
        }
        
        if let value = updatingActivity.calendarExport {
            newActivity.calendarExport = value
        }
        
        if let value = updatingActivity.name {
            newActivity.name = value
        }
        
        if let value = updatingActivity.admin {
            newActivity.admin = value
        }
        
        if let value = updatingActivity.activityType {
            newActivity.activityType = value
        }
        
        if let value = updatingActivity.category {
            newActivity.category = value
        }
        
        if let value = updatingActivity.subcategory {
            newActivity.subcategory = value
        }
        
        if let value = updatingActivity.activityDescription {
            newActivity.activityDescription = value
        }
        
        if let value = updatingActivity.locationName {
            newActivity.locationName = value
        }
        
        if let value = updatingActivity.locationAddress {
            newActivity.locationAddress = value
        }
        
        if let value = updatingActivity.participantsIDs {
            newActivity.participantsIDs = value
        }
        
        if let value = updatingActivity.transportation {
            newActivity.transportation = value
        }
        
        if let value = updatingActivity.activityOriginalPhotoURL {
            newActivity.activityOriginalPhotoURL = value
        }
        
        if let value = updatingActivity.activityThumbnailPhotoURL {
            newActivity.activityThumbnailPhotoURL = value
        }
        
        if let value = updatingActivity.activityPhotos {
            newActivity.activityPhotos = value
        }
        
        if let value = updatingActivity.activityFiles {
            newActivity.activityFiles = value
        }
        
        if let value = updatingActivity.allDay {
            newActivity.allDay = value
        }
        
        if let value = updatingActivity.startDateTime {
            newActivity.startDateTime = value
        }
        
        if let value = updatingActivity.startTimeZone {
            newActivity.startTimeZone = value
        }
        
        if let value = updatingActivity.endDateTime {
            newActivity.endDateTime = value
        }
        
        if let value = updatingActivity.endTimeZone {
            newActivity.endTimeZone = value
        }
        
        if let value = updatingActivity.recurrences {
            newActivity.recurrences = value
        }
        
        if let value = updatingActivity.recurrenceStartDateTime {
            newActivity.recurrenceStartDateTime = value
        }
        
        if let value = updatingActivity.notes {
            newActivity.notes = value
        }
        
        if let value = updatingActivity.conversationID {
            newActivity.conversationID = value
        }
        
        if let value = updatingActivity.grocerylistID {
            newActivity.grocerylistID = value
        }
        
        if let value = updatingActivity.checklistIDs {
            newActivity.checklistIDs = value
        }
        
        if let value = updatingActivity.activitylistIDs {
            newActivity.activitylistIDs = value
        }
        
        if let value = updatingActivity.packinglistIDs {
            newActivity.packinglistIDs = value
        }
        
        if let value = updatingActivity.containerID {
            newActivity.containerID = value
        }
        
        if let value = updatingActivity.showExtras {
            newActivity.showExtras = value
        }
        
        if let value = updatingActivity.isCompleted {
            newActivity.isCompleted = value
        }
        
        if let value = updatingActivity.completedDate {
            newActivity.completedDate = value
        }
        
        if let value = updatingActivity.userIsCompleted {
            newActivity.userIsCompleted = value
        }
        
        if let value = updatingActivity.userCompletedDate {
            newActivity.userCompletedDate = value
        }
        
        if let value = updatingActivity.isTask {
            newActivity.isTask = value
        }
        
        if let value = updatingActivity.isEvent {
            newActivity.isEvent = value
        }
        
        if let value = updatingActivity.isSchedule {
            newActivity.isSchedule = value
        }
        
        if let value = updatingActivity.scheduleIDs {
            newActivity.scheduleIDs = value
        }
        
        if let value = updatingActivity.createdDate {
            newActivity.createdDate = value
        }
        
        if let value = updatingActivity.lastModifiedDate {
            newActivity.lastModifiedDate = value
        }
        
        //list is activity attribute vs. user attribute unlike calendar
        if let value = updatingActivity.listID {
            newActivity.listID = value
        }

        if let value = updatingActivity.listName {
            newActivity.listName = value
        }

        if let value = updatingActivity.listColor {
            newActivity.listColor = value
        }

        if let value = updatingActivity.listSource {
            newActivity.listSource = value
        }
        
        if let value = updatingActivity.subtaskIDs {
            newActivity.subtaskIDs = value
        }
        
        if let value = updatingActivity.isSubtask {
            newActivity.isSubtask = value
        }
        
        if let value = updatingActivity.hasStartTime {
            newActivity.hasStartTime = value
        }
        
        if let value = updatingActivity.hasDeadlineTime {
            newActivity.hasDeadlineTime = value
        }
        
        if let value = updatingActivity.flagged {
            newActivity.flagged = value
        }
        
        if let value = updatingActivity.tags {
            newActivity.tags = value
        }
        
        if let value = updatingActivity.priority {
            newActivity.priority = value
        }
        
        if let value = updatingActivity.instanceIDs {
            newActivity.instanceIDs = value
        }
        
        if let value = updatingActivity.instanceID {
            newActivity.instanceID = value
        }
        
        if let value = updatingActivity.recurringEventID {
            newActivity.recurringEventID = value
        }
        
        if let value = updatingActivity.instanceOriginalStartDateTime {
            newActivity.instanceOriginalStartDateTime = value
        }
        
        if let value = updatingActivity.instanceOriginalAllDay {
            newActivity.instanceOriginalAllDay = value
        }
        
        if let value = updatingActivity.instanceOriginalStartTimeZone {
            newActivity.instanceOriginalStartTimeZone = value
        }
        
        return newActivity
    }
    
    func getDifferenceBetweenActivities(otherActivity: Activity) -> Activity {
        let newActivity = Activity(dictionary: ["activityID": self.activityID as AnyObject])
        if self.externalActivityID != otherActivity.externalActivityID {
            newActivity.externalActivityID = self.externalActivityID
        }
        
        if self.calendarExport != otherActivity.calendarExport {
            newActivity.calendarExport = self.calendarExport
        }
        
        if self.name != otherActivity.name {
            newActivity.name = self.name
        }
        
        if self.admin != otherActivity.admin {
            newActivity.admin = self.admin
        }
        
        if self.activityType != otherActivity.activityType {
            newActivity.activityType = self.activityType
        }
        
        if self.category != otherActivity.category {
            newActivity.category = self.category
        }
        
        if self.subcategory != otherActivity.subcategory {
            newActivity.subcategory = self.subcategory
        }
        
        if self.activityDescription != otherActivity.activityDescription {
            newActivity.activityDescription = self.activityDescription
        }
        
        if self.locationName != otherActivity.locationName {
            newActivity.locationName = self.locationName
        }
        
        if self.locationAddress != otherActivity.locationAddress {
            newActivity.locationAddress = self.locationAddress
        }
        
        if self.participantsIDs != otherActivity.participantsIDs {
            newActivity.participantsIDs = self.participantsIDs
        }
        
        if self.transportation != otherActivity.transportation {
            newActivity.transportation = self.transportation
        }
        
        if self.activityOriginalPhotoURL != otherActivity.activityOriginalPhotoURL {
            newActivity.activityOriginalPhotoURL = self.activityOriginalPhotoURL
        }
        
        if self.activityThumbnailPhotoURL != otherActivity.activityThumbnailPhotoURL {
            newActivity.activityThumbnailPhotoURL = self.activityThumbnailPhotoURL
        }
        
        if self.activityPhotos != otherActivity.activityPhotos {
            newActivity.activityPhotos = self.activityPhotos
        }
        
        if self.activityFiles != otherActivity.activityFiles {
            newActivity.activityFiles = self.activityFiles
        }
        
        if self.allDay != otherActivity.allDay {
            newActivity.allDay = self.allDay
        }
        
        if self.startDateTime != otherActivity.startDateTime {
            newActivity.startDateTime = self.startDateTime
        }
        
        if self.startTimeZone != otherActivity.startTimeZone {
            newActivity.startTimeZone = self.startTimeZone
        }
        
        if self.endDateTime != otherActivity.endDateTime {
            newActivity.endDateTime = self.endDateTime
        }
        
        if self.endTimeZone != otherActivity.endTimeZone {
            newActivity.endTimeZone = self.endTimeZone
        }
        
        if self.recurrences != otherActivity.recurrences {
            newActivity.recurrences = self.recurrences
        }
        
        if self.notes != otherActivity.notes {
            newActivity.notes = self.notes
        }
        
        if self.conversationID != otherActivity.conversationID {
            newActivity.conversationID = self.conversationID
        }
        
        if self.grocerylistID != otherActivity.grocerylistID {
            newActivity.grocerylistID = self.grocerylistID
        }
        
        if self.checklistIDs != otherActivity.checklistIDs {
            newActivity.checklistIDs = self.checklistIDs
        }
        
        if self.activitylistIDs != otherActivity.activitylistIDs {
            newActivity.activitylistIDs = self.activitylistIDs
        }
        
        if self.packinglistIDs != otherActivity.packinglistIDs {
            newActivity.packinglistIDs = self.packinglistIDs
        }
        
        if self.containerID != otherActivity.containerID {
            newActivity.containerID = self.containerID
        }
        
        if self.showExtras != otherActivity.showExtras {
            newActivity.showExtras = self.showExtras
        }
        
        if self.isCompleted != otherActivity.isCompleted {
            newActivity.isCompleted = self.isCompleted
        }
        
        if self.completedDate != otherActivity.completedDate {
            newActivity.completedDate = self.completedDate
        }
        
        if self.userIsCompleted != otherActivity.userIsCompleted {
            newActivity.userIsCompleted = self.userIsCompleted
        }
        
        if self.userCompletedDate != otherActivity.userCompletedDate {
            newActivity.userCompletedDate = self.userCompletedDate
        }
        
        if self.isTask != otherActivity.isTask {
            newActivity.isTask = self.isTask
        }
        
        if self.isEvent != otherActivity.isEvent {
            newActivity.isEvent = self.isEvent
        }
        
        if self.isSchedule != otherActivity.isSchedule {
            newActivity.isSchedule = self.isSchedule
        }
        
        if self.scheduleIDs != otherActivity.scheduleIDs {
            newActivity.scheduleIDs = self.scheduleIDs
        }
        
        if self.createdDate != otherActivity.createdDate {
            newActivity.createdDate = self.createdDate
        }
        
        if self.lastModifiedDate != otherActivity.lastModifiedDate {
            newActivity.lastModifiedDate = self.lastModifiedDate
        }
        
        //list is activity attribute vs. user attribute unlike calendar
        if self.listID != otherActivity.listID {
            newActivity.listID = self.listID
        }

        if self.listName != otherActivity.listName {
            newActivity.listName = self.listName
        }

        if self.listColor != otherActivity.listColor {
            newActivity.listColor = self.listColor
        }

        if self.listSource != otherActivity.listSource {
            newActivity.listSource = self.listSource
        }
        
        if self.subtaskIDs != otherActivity.subtaskIDs {
            newActivity.subtaskIDs = self.subtaskIDs
        }
        
        if self.isSubtask != otherActivity.isSubtask {
            newActivity.isSubtask = self.isSubtask
        }
        
        if self.hasStartTime != otherActivity.hasStartTime {
            newActivity.hasStartTime = self.hasStartTime
        }
        
        if self.hasDeadlineTime != otherActivity.hasDeadlineTime {
            newActivity.hasDeadlineTime = self.hasDeadlineTime
        }
        
        if self.flagged != otherActivity.flagged {
            newActivity.flagged = self.flagged
        }
        
        if self.tags != otherActivity.tags {
            newActivity.tags = self.tags
        }
        
        if self.priority != otherActivity.priority {
            newActivity.priority = self.priority
        }
        
        if self.instanceIDs != otherActivity.instanceIDs {
            newActivity.instanceIDs = self.instanceIDs
        }
        
        if self.instanceID != otherActivity.instanceID {
            newActivity.instanceID = self.instanceID
        }
        
        if self.recurringEventID != otherActivity.recurringEventID {
            newActivity.recurringEventID = self.recurringEventID
        }
        
        if self.instanceOriginalStartDateTime != otherActivity.instanceOriginalStartDateTime {
            newActivity.instanceOriginalStartDateTime = self.instanceOriginalStartDateTime
        }
        
        if self.instanceOriginalAllDay != otherActivity.instanceOriginalAllDay {
            newActivity.instanceOriginalAllDay = self.instanceOriginalAllDay
        }
        
        if self.instanceOriginalStartTimeZone != otherActivity.instanceOriginalStartTimeZone {
            newActivity.instanceOriginalStartTimeZone = self.instanceOriginalStartTimeZone
        }
        
        return newActivity
    }
    
    static func == (lhs: Activity, rhs: Activity) -> Bool {
        return lhs.activityID == rhs.activityID
    }
}

func categorizeActivities(activities: [Activity], start: Date, end: Date, completion: @escaping ([String: Double], [String: [Activity]]) -> ()) {
    var categoryDict = [String: Double]()
    var activitiesDict = [String: [Activity]]()
    var totalValue: Double = end.timeIntervalSince(start)
    // create dateFormatter with UTC time format
    for activity in activities {
        guard let activityStartDate = activity.startDateTime.map({ Date(timeIntervalSince1970: $0.doubleValue) }),
              let activityEndDate = activity.endDateTime.map({ Date(timeIntervalSince1970: $0.doubleValue) }) else { return }
        
        // Skipping activities that are outside of the interest range.
        if activityStartDate > end || activityEndDate <= start {
            continue
        }
        
        let duration = activityEndDate.timeIntervalSince1970 - activityStartDate.timeIntervalSince1970
        if let type = activity.category {
            guard type != "Not Applicable" else { continue }
            totalValue -= duration
            if categoryDict[type] == nil {
                categoryDict[type] = duration
                activitiesDict[type] = [activity]
            } else {
                let double = categoryDict[type]
                categoryDict[type] = double! + duration
                
                var activities = activitiesDict[type]
                activities!.append(activity)
                activitiesDict[type] = activities
            }
        } else {
            totalValue -= duration
            let type = "No Category"
            if categoryDict[type] == nil {
                categoryDict[type] = duration
                activitiesDict[type] = [activity]
            } else {
                let double = categoryDict[type]
                categoryDict[type] = double! + duration
                
                var activities = activitiesDict[type]
                activities!.append(activity)
                activitiesDict[type] = activities
            }
        }
    }
    categoryDict["No Activities"] = totalValue
    
    completion(categoryDict, activitiesDict)
}

func activitiesOverTimeChartData(activities: [Activity], activityCategories: [String], start: Date, end: Date, segmentType: TimeSegmentType, completion: @escaping ([String: [Statistic]], [String: [Activity]]) -> ()) {
    var statistics = [String: [Statistic]]()
    var activityDict = [String: [Activity]]()
    let calendar = Calendar.current
    var date = start
    
    let component: Calendar.Component = {
        switch segmentType {
        case .day: return .hour
        case .week: return .day
        case .month: return .day
        case .year: return .month
        }
    }()
    
    var nextDate = calendar.date(byAdding: component, value: 1, to: date)!
    while date < end {
        for activityCategory in activityCategories {
            if activityCategory == "No Activities" {
                continue
            }
            activityListStats(activities: activities, activityCategory: activityCategory, chunkStart: date, chunkEnd: nextDate) { (stats, activities) in
                if statistics[activityCategory] != nil, activityDict[activityCategory] != nil {
                    var acStats = statistics[activityCategory]
                    var acActivityList = activityDict[activityCategory]
                    acStats!.append(contentsOf: stats)
                    acActivityList!.append(contentsOf: activities)
                    statistics[activityCategory] = acStats
                    activityDict[activityCategory] = acActivityList
                } else {
                    statistics[activityCategory] = stats
                    activityDict[activityCategory] = activities
                }
            }
        }
        
        // Advance by one day:
        date = nextDate
        nextDate = calendar.date(byAdding: component, value: 1, to: nextDate)!
    }
    
    completion(statistics, activityDict)
}

/// Categorize a list of activities, filtering down to a specific chunk [chunkStart, chunkEnd]
/// - Parameters:
///   - activities: A list of activities to analize.
///   - activityCategory: no idea what this is.
///   - chunkStart: Start date in which the activities are split and categorized.
///   - chunkEnd: Start date in which the activities are split and categorized.
///   - completion: list of statistical elements and activities.
func activityListStats(
    activities: [Activity],
    activityCategory: String,
    chunkStart: Date,
    chunkEnd: Date,
    completion: @escaping ([Statistic], [Activity]) -> ()
) {
    var statistics = [Statistic]()
    var activityList = [Activity]()
    for activity in activities {
        guard var activityStartDate = activity.startDateTime.map({ Date(timeIntervalSince1970: $0.doubleValue) }),
              var activityEndDate = activity.endDateTime.map({ Date(timeIntervalSince1970: $0.doubleValue) }) else { return }
        
        // Skipping activities that are outside of the interest range.
        if activityStartDate >= chunkEnd || activityEndDate <= chunkStart {
            continue
        }
        
        // Truncate events that out of the [chunkStart, chunkEnd] range.
        // Multi-day events, chunked into single day `Statistic`s are the best example.
        if activityStartDate < chunkStart {
            activityStartDate = chunkStart
        }
        if activityEndDate > chunkEnd {
            activityEndDate = chunkEnd
        }
        
        if let type = activity.category, type == activityCategory {
            var duration: Double = 0
            if activity.allDay ?? false {
                duration = 1440
            } else {
                duration = (activityEndDate.timeIntervalSince1970 - activityStartDate.timeIntervalSince1970) / 60
            }
            if statistics.isEmpty {
                let stat = Statistic(date: chunkStart, value: duration)
                statistics.append(stat)
                activityList.append(activity)
            } else {
                if let index = statistics.firstIndex(where: { $0.date == chunkEnd }) {
                    statistics[index].value += duration
                    activityList.append(activity)
                }
            }
        }
    }
    completion(statistics, activityList)
}


extension Activity {
    var startDate: Date? {
        if let startDateTime = startDateTime?.doubleValue {
            return Date(timeIntervalSince1970: startDateTime)
        }
        return nil
    }
    
    var endDate: Date? {
        if let endDateTime = endDateTime?.doubleValue {
            return Date(timeIntervalSince1970: endDateTime)
        }
        return nil
    }
    
    var finalDate: Date? {
        if let startDateTime = startDateTime?.doubleValue {
            return Date(timeIntervalSince1970: startDateTime)
            //for tasks where deadline date is more likely to be set than start date
        }
        else if let endDateTime = endDateTime?.doubleValue {
            return Date(timeIntervalSince1970: endDateTime)
        }
        return nil
    }
    var finalDateTime: NSNumber? {
        if self.isTask ?? false {
            return endDateTime
        } else {
            return startDateTime
        }
    }
    var instanceOriginalStartDate: Date? {
        if let instanceOriginalStartDateTime = instanceOriginalStartDateTime?.doubleValue {
            return Date(timeIntervalSince1970: instanceOriginalStartDateTime)
        }
        return nil
    }
    var recurrenceStartDate: Date? {
        if let recurrenceStartDateTime = recurrenceStartDateTime?.doubleValue {
            return Date(timeIntervalSince1970: recurrenceStartDateTime)
        }
        return nil
    }
    var finalTimeZone: String? {
        if self.isTask ?? false {
            return endTimeZone
        } else {
            return startTimeZone
        }
    }
}

extension Activity {
    var startDateWTZ: Date? {
        guard let startDateTime = startDateTime?.doubleValue else {
            return nil
        }
        let timezone = TimeZone(identifier: startTimeZone ?? "UTC")!
        let timezoneOffset =  timezone.secondsFromGMT()
        let epochDate = startDateTime
        let timezoneEpochOffset = (epochDate + Double(timezoneOffset))
        return Date(timeIntervalSince1970: timezoneEpochOffset)
    }
    
    var endDateWTZ: Date? {
        guard let endDateTime = endDateTime?.doubleValue else {
            return nil
        }
        let timezone = TimeZone(identifier: endTimeZone ?? "UTC")!
        let timezoneOffset =  timezone.secondsFromGMT()
        let epochDate = endDateTime
        let timezoneEpochOffset = (epochDate + Double(timezoneOffset))
        return Date(timeIntervalSince1970: timezoneEpochOffset)
    }
    
    var finalDateWTZ: Date? {
        if let startDateTime = startDateTime?.doubleValue {
            let timezone = TimeZone(identifier: startTimeZone ?? "UTC")!
            let timezoneOffset =  timezone.secondsFromGMT()
            let epochDate = startDateTime
            let timezoneEpochOffset = (epochDate + Double(timezoneOffset))
            return Date(timeIntervalSince1970: timezoneEpochOffset)
            //for tasks where deadline date is more likely to be set than start date
        }
        else if let endDateTime = endDateTime?.doubleValue {
            let timezone = TimeZone(identifier: endTimeZone ?? "UTC")!
            let timezoneOffset =  timezone.secondsFromGMT()
            let epochDate = endDateTime
            let timezoneEpochOffset = (epochDate + Double(timezoneOffset))
            return Date(timeIntervalSince1970: timezoneEpochOffset)
        }
        return nil
    }
}

func dateToGLTRDate(date: Date, allDay: Bool, timeZone: TimeZone?) -> GTLRCalendar_EventDateTime? {
    guard let timeZone = timeZone else {
        return nil
    }
    let gDate = GTLRCalendar_EventDateTime()
    if allDay {
        gDate.date = GTLRDateTime(forAllDayWith: date)
        gDate.timeZone = timeZone.identifier
    } else {
        gDate.dateTime = GTLRDateTime(date: date)
        gDate.timeZone = timeZone.identifier
    }
    return gDate
}

extension GTLRCalendar_Event {
    var startDate: Date? {
        guard let start = self.start else {
            return nil
        }
        var date = Date()
        if let startDate = start.dateTime {
            date = startDate.date
        } else if let startDate = start.date {
            date = startDate.date
        }
        return date
    }
    
    var endDate: Date? {
        guard let end = self.end else {
            return nil
        }
        var date = Date()
        if let endDate = end.dateTime {
            date = endDate.date
        } else if let endDate = end.date {
            date = endDate.date
        }
        return date
    }
}

enum TaskPriority: String, CaseIterable, Comparable {
    case None = "None"
    case High = "High"
    case Medium = "Medium"
    case Low = "Low"
    
    private var sortOrder: Int {
        switch self {
        case .None:
            return 0
        case .Low:
            return 1
        case .Medium:
            return 2
        case .High:
            return 3
        }
    }
    
    static func ==(lhs: TaskPriority, rhs: TaskPriority) -> Bool {
        return lhs.sortOrder == rhs.sortOrder
    }
    
    static func <(lhs: TaskPriority, rhs: TaskPriority) -> Bool {
        return lhs.sortOrder < rhs.sortOrder
    }
}
