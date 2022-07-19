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

struct Task: Codable, Equatable, Hashable {
        
    var name: String?
    var id: String?
    var type: String?
    var description: String?
    var locationName: String?
    var locationAddress: [String : [Double]]?
    var participantsIDs: [String]?
    var transportation: String?
    var allDay: Bool?
    var startDateTime: Date?
    var endDateTime: Date?
    var lastModifiedDate: Date?
    var createdDate: Date?
    var recurrences: [String]?
    var reminder: String?
    var checklistIDs: [String]?
    var transactionIDs: [String]?
    var mealIDs: [String]?
    var workoutIDs: [String]?
    var mindfulnessIDs: [String]?
    var scheduleIDs: [String]?
    var completed: Bool?
    var isGroupTask: Bool?
    var admin: String?
    var badge: Int?
    var pinned: Bool?
    var muted: Bool?
    
    init(name: String, id: String, createdDate: Date, lastModifiedDate: Date, admin: String) {
        self.name = name
        self.id = id
        self.createdDate = createdDate
        self.lastModifiedDate = lastModifiedDate
        self.admin = admin
    }
        
}

func ==(lhs: Task, rhs: Task) -> Bool {
    return lhs.id == rhs.id
}

