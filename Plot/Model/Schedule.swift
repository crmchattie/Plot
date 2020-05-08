//
//  Schedule.swift
//  Pigeon-project
//
//  Created by Cory McHattie on 6/4/19.
//  Copyright © 2019 Immature Creations. All rights reserved.
//

import UIKit

class Schedule: NSObject, Codable {
        
    var name: String?
    var scheduleID: String?
    var scheduleType: String?
    var scheduleDescription: String?
    var locationName: String?
    var locationAddress: [String : [Double]]?
    var participantsIDs: [String]?
    var transportation: String?
    var allDay: Bool?
    var startDateTime: NSNumber?
    var endDateTime: NSNumber?
    var reminder: String?
    var checklist: [String : [String : Bool]]?
    var recipeID: String?
    var workoutID: String?
    var eventID: String?
        
        fileprivate var reminderDate: Date?
    
        enum CodingKeys: String, CodingKey {
            case name
            case scheduleID
            case scheduleType
            case scheduleDescription
            case locationName
            case locationAddress
            case transportation
            case reminder
            case checklist
            case recipeID
            case workoutID
            case eventID
        }
        
        init(dictionary: [String: AnyObject]?) {
            super.init()
            
            name = dictionary?["name"] as? String
            scheduleID = dictionary?["scheduleID"] as? String
            scheduleType = dictionary?["scheduleType"] as? String
            scheduleDescription = dictionary?["scheduleDescription"] as? String
            locationName = dictionary?["locationName"] as? String
            locationAddress = dictionary?["locationAddress"] as? [String : [Double]]
            participantsIDs = dictionary?["participantsIDs"] as? [String]
            transportation = dictionary?["transportation"] as? String
            allDay = dictionary?["allDay"] as? Bool
            startDateTime = (dictionary?["startDateTime"] as? NSNumber)
            endDateTime = (dictionary?["endDateTime"] as? NSNumber)
            reminder = dictionary?["reminder"] as? String
            checklist = dictionary?["checklist"] as? [String : [String : Bool]]
            recipeID = dictionary?["recipeID"] as? String
            workoutID = dictionary?["workoutID"] as? String
            eventID = dictionary?["purchasesID"] as? String
            
        }
    
    func toAnyObject() -> [String: AnyObject] {
        var dictionary = [String: AnyObject]()
                
        if let value = self.name as AnyObject? {
            dictionary["name"] = value
        }
        
        if let value = self.scheduleID as AnyObject? {
            dictionary["scheduleID"] = value
        }
        
        if let value = self.scheduleType as AnyObject? {
            dictionary["scheduleType"] = value
        }
        
        if let value = self.scheduleDescription as AnyObject? {
            dictionary["scheduleDescription"] = value
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
        
        if let value = self.checklist as AnyObject? {
            dictionary["checklist"] = value
        }
        
        if let value = self.recipeID as AnyObject? {
            dictionary["recipeID"] = value
        }
        
        if let value = self.workoutID as AnyObject? {
            dictionary["workoutID"] = value
        }
        
        if let value = self.eventID as AnyObject? {
            dictionary["eventID"] = value
        }
        
        return dictionary
    }
}

