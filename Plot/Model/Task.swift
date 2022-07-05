//
//  Schedule.swift
//  Pigeon-project
//
//  Created by Cory McHattie on 6/4/19.
//  Copyright © 2019 Immature Creations. All rights reserved.
//

import UIKit
import Firebase
import CodableFirebase

let taskEntity = "tasks"
let userTaskEntity = "user-tasks"
let userTaskCategoriesEntity = "user-tasks-categories"

class Task: NSObject, Codable {
        
    var name: String?
    var taskID: String?
    var taskType: String?
    var taskDescription: String?
    var locationName: String?
    var locationAddress: [String : [Double]]?
    var participantsIDs: [String]?
    var transportation: String?
    var allDay: Bool?
    var startDateTime: NSNumber?
    var endDateTime: NSNumber?
    var recurrences: [String]?
    var reminder: String?
    var checklist: [Checklist]?
    var recipeID: String?
    var workoutID: String?
    var eventID: String?
    var completed: Bool?
    var isGroupTask: Bool?
    var admin: String?
    var badge: Int?
    var pinned: Bool?
    var muted: Bool?
        
    fileprivate var reminderDate: Date?
    
        enum CodingKeys: String, CodingKey {
            case name
            case taskID
            case taskType
            case taskDescription
            case locationName
            case locationAddress
            case transportation
            case recurrences
            case reminder
            case checklist
            case recipeID
            case workoutID
            case eventID
            case completed
            case isGroupTask
            case admin
            case badge
            case pinned
            case muted
        }
        
        init(dictionary: [String: AnyObject]?) {
            super.init()
            
            name = dictionary?["name"] as? String
            taskID = dictionary?["taskID"] as? String
            taskType = dictionary?["taskType"] as? String
            taskDescription = dictionary?["taskDescription"] as? String
            locationName = dictionary?["locationName"] as? String
            locationAddress = dictionary?["locationAddress"] as? [String : [Double]]
            participantsIDs = dictionary?["participantsIDs"] as? [String]
            transportation = dictionary?["transportation"] as? String
            allDay = dictionary?["allDay"] as? Bool
            startDateTime = (dictionary?["startDateTime"] as? NSNumber)
            endDateTime = (dictionary?["endDateTime"] as? NSNumber)
            reminder = dictionary?["reminder"] as? String
            recipeID = dictionary?["recipeID"] as? String
            workoutID = dictionary?["workoutID"] as? String
            eventID = dictionary?["purchasesID"] as? String
            completed = dictionary?["completed"] as? Bool
            recurrences = dictionary?["recurrences"] as? [String]
            isGroupTask = dictionary?["isGroupTask"] as? Bool
            admin = dictionary?["admin"] as? String
            badge = dictionary?["badge"] as? Int
            pinned = dictionary?["pinned"] as? Bool
            muted = dictionary?["muted"] as? Bool
            
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
            
        }
    
    func toAnyObject() -> [String: AnyObject] {
        var dictionary = [String: AnyObject]()
                
        if let value = self.name as AnyObject? {
            dictionary["name"] = value
        }
        
        if let value = self.admin as AnyObject? {
            dictionary["admin"] = value
        }
        
        if let value = self.taskID as AnyObject? {
            dictionary["taskID"] = value
        }
        
        if let value = self.taskType as AnyObject? {
            dictionary["taskType"] = value
        }
        
        if let value = self.taskDescription as AnyObject? {
            dictionary["taskDescription"] = value
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
        
        if let value = self.recipeID as AnyObject? {
            dictionary["recipeID"] = value
        }
        
        if let value = self.workoutID as AnyObject? {
            dictionary["workoutID"] = value
        }
        
        if let value = self.eventID as AnyObject? {
            dictionary["eventID"] = value
        }
        
        if let value = self.completed as AnyObject? {
            dictionary["completed"] = value
        }
        
        if let value = self.recurrences as AnyObject? {
            dictionary["recurrences"] = value
        }
        
        if let value = self.checklist {
            var firebaseChecklistList = [[String: AnyObject?]]()
            for checklist in value {
                let firebaseChecklist = checklist.toAnyObject()
                firebaseChecklistList.append(firebaseChecklist)
            }
            dictionary["checklist"] = firebaseChecklistList as AnyObject
        }
        
        return dictionary
    }
}

