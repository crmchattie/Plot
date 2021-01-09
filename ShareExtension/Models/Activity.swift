//
//  Activity.swift
//  Pigeon-project
//
//  Created by Cory McHattie on 4/27/19.
//  Copyright © 2019 Immature Creations. All rights reserved.
//

import UIKit

class Activity: NSObject {
    
    var activityID: String?
    var name: String?
    var activityType: String?
    var category: String?
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
    var reminder: String?
    var notes: String?
    var checklistIDs: [String]?
    var activitylistIDs: [String]?
    var packinglistIDs: [String]?
    var transactionIDs: [String]?
    var grocerylistID: String?
    var isGroupActivity: Bool?
    var admin: String?
    var badge: Int?
    var pinned: Bool?
    var muted: Bool?
    var conversationID: String?
    var calendarExport: Bool?
    var recipeID: String?
    var servings: Int?
    var workoutID: String?
    var eventID: String?
    var placeID: String?
    var attractionID: String?
    var showExtras: Bool?
    var hkSampleID: String?
    
    enum CodingKeys: String, CodingKey {
        case name
        case activityType
        case category
        case activityDescription
        case isGroupActivity
        case locationName
        case locationAddress
        case transportation
        case activityOriginalPhotoURL
        case activityThumbnailPhotoURL
        case reminder
        case notes
        case schedule
        case purchases
        case checklist
        case packinglist
        case grocerylist
        case checklistIDs
        case activitylistIDs
        case packinglistIDs
        case grocerylistID
        case transactionIDs
        case calendarExport
        case recipeID
        case servings
        case workoutID
        case eventID
        case attractionID
        case placeID
        case showExtras
    }
    
    init(dictionary: [String: AnyObject]?) {
        super.init()
        
        activityID = dictionary?["activityID"] as? String
        name = dictionary?["name"] as? String
        activityType = dictionary?["activityType"] as? String
        category = dictionary?["category"] as? String
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
        reminder = dictionary?["reminder"] as? String
        notes = dictionary?["notes"] as? String
        isGroupActivity = dictionary?["isGroupActivity"] as? Bool
        admin = dictionary?["admin"] as? String
        badge = dictionary?["badge"] as? Int
        pinned = dictionary?["pinned"] as? Bool
        muted = dictionary?["muted"] as? Bool
        conversationID = dictionary?["conversationID"] as? String
        grocerylistID = dictionary?["grocerylistID"] as? String
        checklistIDs = dictionary?["checklistIDs"] as? [String]
        activitylistIDs = dictionary?["activitylistIDs"] as? [String]
        packinglistIDs = dictionary?["packinglistIDs"] as? [String]
        transactionIDs = dictionary?["transactionIDs"] as? [String]
        calendarExport = dictionary?["calendarExport"] as? Bool
        recipeID = dictionary?["recipeID"] as? String
        servings = dictionary?["servings"] as? Int
        workoutID = dictionary?["workoutID"] as? String
        eventID = dictionary?["eventID"] as? String
        attractionID = dictionary?["attractionID"] as? String
        placeID = dictionary?["placeID"] as? String
        showExtras = dictionary?["showExtras"] as? Bool
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
        
        if let value = self.name as AnyObject? {
            dictionary["name"] = value
        }
        
        if let value = self.admin as AnyObject? {
            dictionary["admin"] = value
        }
        
        if let value = self.activityType as AnyObject? {
            dictionary["activityType"] = value
        }
        
        if let value = self.category as AnyObject? {
            dictionary["category"] = value
        }
        
        if let value = self.activityDescription as AnyObject? {
            dictionary["activityDescription"] = value
        }
        
        if let value = self.locationName as AnyObject? {
            dictionary["locationName"] = value
        }
        
        if let value = self.locationAddress as AnyObject? {
            dictionary["locationAddress"] = value
        }
        
        if let value = self.participantsIDs as AnyObject? {
            dictionary["participantsIDs"] = value
        }
        
        if let value = self.transportation as AnyObject? {
            dictionary["transportation"] = value
        }
        
        if let value = self.activityOriginalPhotoURL as AnyObject? {
            dictionary["activityOriginalPhotoURL"] = value
        }
        
        if let value = self.activityThumbnailPhotoURL as AnyObject? {
            dictionary["activityThumbnailPhotoURL"] = value
        }
        
        if let value = self.activityPhotos as AnyObject? {
            dictionary["activityPhotos"] = value
        }
        
        if let value = self.activityFiles as AnyObject? {
            dictionary["activityFiles"] = value
        }
        
        if let value = self.allDay as AnyObject? {
            dictionary["allDay"] = value
        }
        
        if let value = self.startDateTime as AnyObject? {
            dictionary["startDateTime"] = value
        }
        
        if let value = self.startTimeZone as AnyObject? {
            dictionary["startTimeZone"] = value
        }
        
        if let value = self.endDateTime as AnyObject? {
            dictionary["endDateTime"] = value
        }
        
        if let value = self.endTimeZone as AnyObject? {
            dictionary["endTimeZone"] = value
        }
        
        if let value = self.notes as AnyObject? {
            dictionary["notes"] = value
        }
        
        if let value = self.conversationID as AnyObject? {
            dictionary["conversationID"] = value
        }
        
        if let value = self.grocerylistID as AnyObject? {
            dictionary["grocerylistID"] = value
        }
        
        if let value = self.checklistIDs as AnyObject? {
            dictionary["checklistIDs"] = value
        }
        
        if let value = self.activitylistIDs as AnyObject? {
            dictionary["activitylistIDs"] = value
        }
        
        if let value = self.packinglistIDs as AnyObject? {
            dictionary["packinglistIDs"] = value
        }
        
        if let value = self.transactionIDs as AnyObject? {
            dictionary["transactionIDs"] = value
        }
        
        if let value = self.recipeID as AnyObject? {
            dictionary["recipeID"] = value
        }
        
        if let value = self.servings as AnyObject? {
            dictionary["servings"] = value
        }
        
        if let value = self.workoutID as AnyObject? {
            dictionary["workoutID"] = value
        }
        
        if let value = self.eventID as AnyObject? {
            dictionary["eventID"] = value
        }
        
        if let value = self.attractionID as AnyObject? {
            dictionary["attractionID"] = value
        }
        
        if let value = self.placeID as AnyObject? {
            dictionary["placeID"] = value
        }
        
        return dictionary
    }
}


