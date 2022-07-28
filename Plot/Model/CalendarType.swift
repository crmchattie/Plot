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

let calendarEntity = "calendar"
let userCalendarEntity = "user-calendar"

struct CalendarType: Codable, Equatable, Hashable {
        
    var name: String?
    var id: String?
    var description: String?
    var type: String?
    var color: String?
    var locationName: String?
    var locationAddress: [String : [Double]]?
    var participantsIDs: [String]?
    var lastModifiedDate: Date?
    var createdDate: Date?
    var admin: String?
    var badge: Int?
    var pinned: Bool?
    var muted: Bool?
    
    init(id: String, name: String, color: String) {
        self.id = id
        self.name = name
        self.color = color
    }
}

let prebuiltCalendars: [CalendarType] = [personal, home, work, social]

let personal = CalendarType(id: UUID().uuidString, name: "Personal", color: CIColor(color: ChartColors.palette()[0]).stringRepresentation)
let home = CalendarType(id: UUID().uuidString, name: "Home", color: CIColor(color: ChartColors.palette()[1]).stringRepresentation)
let work = CalendarType(id: UUID().uuidString, name: "Work", color: CIColor(color: ChartColors.palette()[2]).stringRepresentation)
let social = CalendarType(id: UUID().uuidString, name: "Social", color: CIColor(color: ChartColors.palette()[3]).stringRepresentation)
