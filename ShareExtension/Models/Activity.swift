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
    var activityDescription: String?
    var locationName: String?
    var locationAddress: [String : [Double]]?
    var participantsIDs: [String]?
    var transportation: String?
    var activityOriginalPhotoURL: String?
    var activityThumbnailPhotoURL: String?
    var activityPhotos: [String]?
    var allDay: Bool?
    var startDateTime: NSNumber?
    var endDateTime: NSNumber?
    var reminder: String?
    var notes: String?
    var schedule: [AnyObject]?
    var purchases: [AnyObject]?
    var checklist: [String : [String : Bool]]?
    var isGroupActivity: Bool?
    var admin: String?
    var badge: Int?
    var pinned: Bool?
    var muted: Bool?
    var conversationID: String?
    var calendarExport: Bool?
    
    init(dictionary: [String: AnyObject]?){
        super.init()
        
        activityID = dictionary?["activityID"] as? String
        name = dictionary?["name"] as? String
        activityType = dictionary?["activityType"] as? String
        activityDescription = dictionary?["activityDescription"] as? String
        locationName = dictionary?["locationName"] as? String
        locationAddress = dictionary?["locationAddress"] as? [String : [Double]]
        participantsIDs = dictionary?["participantsIDs"] as? [String]
        transportation = dictionary?["transportation"] as? String
        activityOriginalPhotoURL = dictionary?["activityOriginalPhotoURL"] as? String
        activityThumbnailPhotoURL = dictionary?["activityThumbnailPhotoURL"] as? String
        activityPhotos = dictionary?["activityPhotos"] as? [String]
        allDay = dictionary?["allDay"] as? Bool
        startDateTime = dictionary?["startDateTime"] as? NSNumber
        endDateTime = dictionary?["endDateTime"] as? NSNumber
        reminder = dictionary?["reminder"] as? String
        notes = dictionary?["notes"] as? String
        schedule = dictionary?["schedule"] as? [AnyObject]
        purchases = dictionary?["purchases"] as? [AnyObject]
        checklist = dictionary?["checklist"] as? [String: [String : Bool]]
        isGroupActivity = dictionary?["isGroupActivity"] as? Bool
        admin = dictionary?["admin"] as? String
        badge = dictionary?["badge"] as? Int
        pinned = dictionary?["pinned"] as? Bool
        muted = dictionary?["muted"] as? Bool
        conversationID = dictionary?["conversationID"] as? String
        calendarExport = dictionary?["calendarExport"] as? Bool
        
    }
    
    func toAnyObject() -> [String: AnyObject] {
        var activityDict = [String: AnyObject]()
        
        activityDict["activityID"] = self.activityID as AnyObject
        
        activityDict["name"] = self.name as AnyObject
        
        if let value = self.activityType as AnyObject? {
            activityDict["activityType"] = value
        } else {
            activityDict["activityType"] = "nothing" as AnyObject
        }
        
        if let value = self.activityDescription as AnyObject? {
            activityDict["activityDescription"] = value
        } else {
            activityDict["activityDescription"] = "nothing" as AnyObject
        }
        
        if let value = self.locationName as AnyObject? {
            activityDict["locationName"] = value
        }
        
        if let value = self.locationAddress as AnyObject? {
            activityDict["locationAddress"] = value
        }
        
        activityDict["participantsIDs"] = self.participantsIDs as AnyObject
        
        if let value = self.transportation as AnyObject? {
            activityDict["transportation"] = value
        } else {
            activityDict["transportation"] = "nothing" as AnyObject
        }
        
        if let value = self.activityOriginalPhotoURL as AnyObject? {
            activityDict["activityOriginalPhotoURL"] = value
        }
        
        if let value = self.activityThumbnailPhotoURL as AnyObject? {
            activityDict["activityThumbnailPhotoURL"] = value
        }
        
        if let value = self.activityPhotos as AnyObject? {
            activityDict["activityPhotos"] = value
        }
        
        activityDict["allDay"] = self.allDay as AnyObject
        activityDict["startDateTime"] = self.startDateTime as AnyObject
        activityDict["endDateTime"] = self.endDateTime as AnyObject
        
        //        if let value = self.reminder as AnyObject? {
        //            activityDict["reminder"] = value
        //        }
        
        if let value = self.notes as AnyObject? {
            activityDict["notes"] = value
        } else {
            activityDict["notes"] = "nothing" as AnyObject
        }
        
        if let value = self.schedule as AnyObject? {
            activityDict["schedule"] = value
        }
        
        if let value = self.purchases as AnyObject? {
            activityDict["purchases"] = value
        }
        
        if let value = self.checklist as AnyObject? {
            activityDict["checklist"] = value
        }
        
        if let value = self.conversationID as AnyObject? {
            activityDict["conversationID"] = value
        }
        
        return activityDict
    }
}


