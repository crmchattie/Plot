//
//  Activity.swift
//  Pigeon-project
//
//  Created by Cory McHattie on 4/27/19.
//  Copyright © 2019 Immature Creations. All rights reserved.
//

import UIKit
import Firebase

class Activity: NSObject, NSCopying, Codable {
    
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
    var schedule: [Activity]?
    var purchases: [Purchase]?
    var checklist: [Checklist]?
    var packinglist: [Packinglist]?
    var grocerylist: Grocerylist?
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
    var attractionID: String?
    var showExtras: Bool?
    
    
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
        case packinglist
        case grocerylist
        case calendarExport
        case recipeID
        case servings
        case workoutID
        case eventID
        case attractionID
        case showExtras
    }
    
    init(dictionary: [String: AnyObject]?) {
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
        
        if let scheduleFirebaseList = dictionary?["schedule"] as? [AnyObject] {
            var scheduleList = [Activity]()
            for schedule in scheduleFirebaseList {
                let sche = Activity(dictionary: schedule as? [String : AnyObject])
                if sche.name == "nothing" { continue }
                scheduleList.append(sche)
            }
            schedule = scheduleList
        }
        
        if let purchasesFirebaseList = dictionary?["purchases"] as? [AnyObject] {
            var purchasesList = [Purchase]()
            for purchase in purchasesFirebaseList {
                let purch = Purchase(dictionary: purchase as? [String : AnyObject])
                if purch.name == "nothing" { continue }
                purchasesList.append(purch)
            }
            purchases = purchasesList
        }
        
        if let checklistFirebaseList = dictionary?["checklist"] as? [AnyObject] {
            var checklistList = [Checklist]()
            for checklist in checklistFirebaseList {
                let check = Checklist(dictionary: checklist as? [String : AnyObject])
                if check.name == "nothing" { continue }
                checklistList.append(check)
            }
            checklist = checklistList
        } else if let items = dictionary?["checklist"] as? [String : [String : Bool]] {
            let check = Checklist(dictionary: ["name": "Checklist" as AnyObject])
            var checklistItems = [String: Bool]()
            for item in items.values {
                checklistItems[item.keys.first!] = item.values.first
            }
            check.items = checklistItems
            checklist = [check]
        }
        
        if let packinglistFirebaseList = dictionary?["packinglist"] as? [AnyObject] {
            var packinglistList = [Packinglist]()
            for packinglist in packinglistFirebaseList {
                let pack = Packinglist(dictionary: packinglist as? [String : AnyObject])
                if pack.name == "nothing" { continue }
                packinglistList.append(pack)
            }
            packinglist = packinglistList
        }
                
        if let groceryList = dictionary?["grocerylist"] as? [String : AnyObject] {
            grocerylist = Grocerylist(dictionary: groceryList)
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
        isGroupActivity = dictionary?["isGroupActivity"] as? Bool
        admin = dictionary?["admin"] as? String
        badge = dictionary?["badge"] as? Int
        pinned = dictionary?["pinned"] as? Bool
        muted = dictionary?["muted"] as? Bool
        conversationID = dictionary?["conversationID"] as? String
        calendarExport = dictionary?["calendarExport"] as? Bool
        recipeID = dictionary?["recipeID"] as? String
        servings = dictionary?["servings"] as? Int
        workoutID = dictionary?["workoutID"] as? String
        eventID = dictionary?["eventID"] as? String
        attractionID = dictionary?["attractionID"] as? String
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
        
        if let value = self.allDay as AnyObject? {
            dictionary["allDay"] = value
        }
        
        if let value = self.startDateTime as AnyObject? {
            dictionary["startDateTime"] = value
        }
        
        if let value = self.endDateTime as AnyObject? {
            dictionary["endDateTime"] = value
        }
        
        if let value = self.notes as AnyObject? {
            dictionary["notes"] = value
        }

        if let value = self.conversationID as AnyObject? {
            dictionary["conversationID"] = value
        }
        
        if let value = self.schedule {
            var firebaseScheduleList = [[String: AnyObject?]]()
            for schedule in value {
                let firebaseSchedule = schedule.scheduleToAnyObject()
                firebaseScheduleList.append(firebaseSchedule)
            }
            dictionary["schedule"] = firebaseScheduleList as AnyObject
        }
        
        if let value = self.purchases {
            var firebasePurchasesList = [[String: AnyObject?]]()
            for purchase in value {
                let firebasePurchases = purchase.toAnyObject()
                firebasePurchasesList.append(firebasePurchases)
            }
            dictionary["purchases"] = firebasePurchasesList as AnyObject
        }
        
        if let value = self.checklist {
            var firebaseChecklistList = [[String: AnyObject?]]()
            for checklist in value {
                let firebaseChecklist = checklist.toAnyObject()
                firebaseChecklistList.append(firebaseChecklist)
            }
            dictionary["checklist"] = firebaseChecklistList as AnyObject
        }
        
        if let value = self.packinglist {
            var firebasePackinglistList = [[String: AnyObject?]]()
            for packinglist in value {
                let firebasePackinglist = packinglist.toAnyObject()
                firebasePackinglistList.append(firebasePackinglist)
            }
            dictionary["packinglist"] = firebasePackinglistList as AnyObject
        }
        
        if let value = self.grocerylist {
            let firebase = value.toAnyObject()
            dictionary["grocerylist"] = firebase as AnyObject
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
        
        if let value = self.showExtras as AnyObject? {
            dictionary["showExtras"] = value
        }
        
        return dictionary
    }
    
    func scheduleToAnyObject() -> [String: AnyObject] {
        var dictionary = [String: AnyObject]()
                
        if let value = self.name as AnyObject? {
            dictionary["name"] = value
        }
        
        if let value = self.activityID as AnyObject? {
            dictionary["activityID"] = value
        }
        
        if let value = self.activityType as AnyObject? {
            dictionary["activityType"] = value
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
        
        if let value = self.allDay as AnyObject? {
            dictionary["allDay"] = value
        }
        
        if let value = self.startDateTime as AnyObject? {
            dictionary["startDateTime"] = value
        }
        
        if let value = self.endDateTime as AnyObject? {
            dictionary["endDateTime"] = value
        }
        
        if let value = self.reminder as AnyObject? {
            dictionary["reminder"] = value
        }
        
        if let value = self.checklist {
            var firebaseChecklistList = [[String: AnyObject?]]()
            for checklist in value {
                let firebaseChecklist = checklist.toAnyObject()
                firebaseChecklistList.append(firebaseChecklist)
            }
            dictionary["checklist"] = firebaseChecklistList as AnyObject
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
        
        return dictionary
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
    case basic, complex, recipe, workout, event
    
    var activityCategoryText: String {
        switch self {
            case .basic: return "Build your own basic activity"
            case .complex: return "Build your own complex activity"
            case .recipe: return "Build your own recipe"
            case .workout: return "Build your own workout"
            case .event: return "Build your own event"
        }
    }
    
    var activitySubcategoryText: String {
        switch self {
            case .basic: return "Includes basic calendar activity fields"
            case .complex: return "Includes basic activity fields plus a schedule, a checklist and purchases fields"
            case .recipe: return "Includes sections for photo, name, ingredients, preparation and steps"
            case .workout: return "Able to pick and choose exercises, sets and weights"
            case .event: return ""
        }
    }
    
    var activityTypeImage: String {
        switch self {
            case .basic: return "activityLarge"
            case .complex: return "activityLarge"
            case .recipe: return "meal"
            case .workout: return "workout"
            case .event: return "event"
        }
    }
}

