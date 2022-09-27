//
//  Template.swift
//  Plot
//
//  Created by Cory McHattie on 9/27/22.
//  Copyright © 2022 Immature Creations. All rights reserved.
//

import Foundation

let templateEntity = "templates"

struct Template: Codable, Equatable, Hashable {
    var name: String
    var object: ObjectType
    var category: ActivityCategory
    var subcategory: String
    var type: String
    var frequency: String?
    var occurrence: String?
    var description: String?
    var order: Int?
    var subtemplates: [Template]?

}

enum ObjectType: String, Codable, CaseIterable {
    case event = "Event"
    case task = "Task"
    case subtask = "Subtask"
    case workout = "Workout"
    case schedule = "Schedule"
}
