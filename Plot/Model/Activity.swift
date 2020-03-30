//
//  Activity.swift
//  Pigeon-project
//
//  Created by Cory McHattie on 4/27/19.
//  Copyright © 2019 Immature Creations. All rights reserved.
//

import UIKit
import Firebase

class Activity: NSObject, Codable {
    
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
    var schedule: [Schedule]?
    var purchases: [Purchase]?
    var checklist: [String : [String : Bool]]?
    var isGroupActivity: Bool?
    var admin: String?
    var badge: Int?
    var pinned: Bool?
    var muted: Bool?
    var conversationID: String?
    var calendarExport: Bool?
    var recipe: Recipe?
    var workout: Workout?
    var event: Event?
    
    
    enum CodingKeys: String, CodingKey {
        case name
        case activityType
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
        case calendarExport
        case recipe
        case workout
        case event
    }
    
    init(dictionary: [String: AnyObject]?){
        super.init()
        
        activityID = dictionary?["activityID"] as? String
        name = dictionary?["name"] as? String
        activityType = dictionary?["activityType"] as? String
        activityDescription = dictionary?["activityDescription"] as? String
        locationName = dictionary?["locationName"] as? String
        locationAddress = dictionary?["locationAddress"] as? [String : [Double]]
        if let participantsIDsDict = dictionary?["participantsIDs"] as? [String: String] {
            participantsIDs = Array(participantsIDsDict.keys)
        }
        else if let participantsIDsArray = dictionary?["participantsIDs"] as? [String] {
            participantsIDs = participantsIDsArray
        } else {
            participantsIDs = []
        }
        
        transportation = dictionary?["transportation"] as? String
        activityOriginalPhotoURL = dictionary?["activityOriginalPhotoURL"] as? String
        activityThumbnailPhotoURL = dictionary?["activityThumbnailPhotoURL"] as? String
        activityPhotos = dictionary?["activityPhotos"] as? [String]
        allDay = dictionary?["allDay"] as? Bool
        startDateTime = dictionary?["startDateTime"] as? NSNumber
        endDateTime = dictionary?["endDateTime"] as? NSNumber
        reminder = dictionary?["reminder"] as? String
        notes = dictionary?["notes"] as? String
        schedule = dictionary?["schedule"] as? [Schedule]
        purchases = dictionary?["purchases"] as? [Purchase]
        checklist = dictionary?["checklist"] as? [String: [String : Bool]]
        isGroupActivity = dictionary?["isGroupActivity"] as? Bool
        admin = dictionary?["admin"] as? String
        badge = dictionary?["badge"] as? Int
        pinned = dictionary?["pinned"] as? Bool
        muted = dictionary?["muted"] as? Bool
        conversationID = dictionary?["conversationID"] as? String
        calendarExport = dictionary?["calendarExport"] as? Bool
        recipe = dictionary?["recipe"] as? Recipe
        workout = dictionary?["workout"] as? Workout
        event = dictionary?["purchases"] as? Event
    }
    
    func toAnyObject() -> [String: AnyObject] {
        var activityDict = [String: AnyObject]()
        
        activityDict["activityID"] = self.activityID as AnyObject
        
        activityDict["name"] = self.name as AnyObject
        
        activityDict["admin"] = self.admin as AnyObject
        
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

        if let value = self.notes as AnyObject? {
            activityDict["notes"] = value
        } else {
            activityDict["notes"] = "nothing" as AnyObject
        }

        if let value = self.conversationID as AnyObject? {
            activityDict["conversationID"] = value
        }
        
        if let value = self.schedule {
            var firebaseScheduleList = [[String: AnyObject?]]()
            for schedule in value {
                let firebaseSchedule = schedule.toAnyObject()
                firebaseScheduleList.append(firebaseSchedule)
            }
            activityDict["schedule"] = firebaseScheduleList as AnyObject
        }
        
        if let value = self.purchases {
            var firebasePurchasesList = [[String: AnyObject?]]()
            for purchase in value {
                let firebasePurchases = purchase.toAnyObject()
                firebasePurchasesList.append(firebasePurchases)
            }
            activityDict["purchases"] = firebasePurchasesList as AnyObject
        }
        
        if let value = self.checklist as AnyObject? {
            activityDict["checklist"] = value
        }
        
        return activityDict
    }
    
    func isBasic() -> Bool {
        var basic = false
        if let typeVal = activityType?.lowercased(), let type = ActivityType(rawValue: typeVal), type == .basic {
            basic = true
        }
        
        return basic
    }
    
    var type: ActivityType {
        if let activityType = activityType?.lowercased(), let value = ActivityType(rawValue: activityType) {
            return value
        } else {
            return .basic
        }
    }
}

enum ActivityType: String {
    case basic, complex, meal, workout, trip
    
    var activityCategoryText: String {
        switch self {
            case .basic: return "Build your own basic activity"
            case .complex: return "Build your own complex activity"
            case .meal: return "Build your own meal"
            case .workout: return "Build your own workout"
            case .trip: return "Build your own trip"
        }
    }
    
    var activitySubcategoryText: String {
        switch self {
            case .basic: return "Includes basic calendar activity fields"
            case .complex: return "Includes basic activity fields plus a schedule, a checklist and purchases fields"
            case .meal: return "Includes sections for photo, name, ingredients, preparation and steps"
            case .workout: return "Able to pick and choose exercises, sets and weights"
            case .trip: return "Add in transportation, lodgings and more"
        }
    }
    
    var activityTypeImage: String {
        switch self {
            case .basic: return "activityLarge"
            case .complex: return "activityLarge"
            case .meal: return "meal"
            case .workout: return "workout"
            case .trip: return "plane"
        }
    }
}

