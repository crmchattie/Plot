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
    var activityFiles: [String]?
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
        
        if let checklistFirebaseList = dictionary?["checklist"] as? [Any] {
            var checklistList = [Checklist]()
            for checklist in checklistFirebaseList {
                if let check = try? FirebaseDecoder().decode(Checklist.self, from: checklist) {
                    if check.name == "nothing" { continue }
                    checklistList.append(check)
                }
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
        
        if let packinglistFirebaseList = dictionary?["packinglist"] as? [Any] {
            var packinglistList = [Packinglist]()
            for packinglist in packinglistFirebaseList {
                if let pack = try? FirebaseDecoder().decode(Packinglist.self, from: packinglist) {
                    if pack.name == "nothing" { continue }
                    packinglistList.append(pack)
                }
            }
            packinglist = packinglistList
        }
        
        if let grocerylist = try? FirebaseDecoder().decode(Grocerylist.self, from: dictionary?["grocerylist"] as Any) {
            self.grocerylist = grocerylist
        }
        
        transportation = dictionary?["transportation"] as? String
        activityOriginalPhotoURL = dictionary?["activityOriginalPhotoURL"] as? String
        activityThumbnailPhotoURL = dictionary?["activityThumbnailPhotoURL"] as? String
        activityPhotos = dictionary?["activityPhotos"] as? [String]
        activityFiles = dictionary?["activityFiles"] as? [String]
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
        
        if let value = self.placeID as AnyObject? {
            dictionary["placeID"] = value
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

enum ActivityType: String, Equatable, Hashable {
    case basic, complex, meal, workout, event, flight
    
    var activityCategoryText: String {
        switch self {
            case .basic: return "Build your own basic activity"
            case .complex: return "Build your own complex activity"
            case .meal: return "Build your own meal"
            case .workout: return "Build your own workout"
            case .event: return "Build your own event"
            case .flight: return "Look up your flight"
        }
    }
    
    var activitySubcategoryText: String {
        switch self {
            case .basic: return "Includes basic calendar activity fields"
            case .complex: return "Includes basic activity fields plus a schedule, a checklist and purchases fields"
            case .meal: return "Build a meal by looking up grocery products and/or restaurant menu items"
            case .workout: return "Build a workout by setting type, duration and intensity"
            case .event: return ""
            case .flight: return "Look up your flight details based on flight number, airline or airport"
        }
    }
    
    var activityTypeImage: String {
        switch self {
            case .basic: return "activityLarge"
            case .complex: return "activityLarge"
            case .meal: return "food"
            case .workout: return "workout"
            case .event: return "event"
            case .flight: return "plane"
        }
    }
}

