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
        
        fileprivate var reminderDate: Date?
    
        enum CodingKeys: String, CodingKey {
            case name
            case scheduleType
            case scheduleDescription
            case locationName
            case locationAddress
            case transportation
            case reminder
            case checklist
        }
        
        init(dictionary: [String: AnyObject]?){
            super.init()
            
            name = dictionary?["name"] as? String
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
            
        }
    
    func toAnyObject() -> [String: AnyObject] {
        var scheduleDict = [String: AnyObject]()
        
        scheduleDict["name"] = self.name as AnyObject
        
        if let value = self.scheduleType as AnyObject? {
            scheduleDict["scheduleType"] = value
        }
        
        if let value = self.scheduleDescription as AnyObject? {
            scheduleDict["scheduleDescription"] = value
        }
        
        scheduleDict["locationName"] = self.locationName as AnyObject
        scheduleDict["locationAddress"] = self.locationAddress as AnyObject
        scheduleDict["participantsIDs"] = self.participantsIDs as AnyObject
        
        if let value = self.transportation as AnyObject? {
            scheduleDict["transportation"] = value
        }
        
        scheduleDict["allDay"] = self.allDay as AnyObject
        scheduleDict["startDateTime"] = self.startDateTime as AnyObject
        scheduleDict["endDateTime"] = self.endDateTime as AnyObject
        scheduleDict["reminder"] = self.reminder as AnyObject
        
        if let value = self.checklist as AnyObject? {
            scheduleDict["checklist"] = value
        }
        
        return scheduleDict
    }
}

