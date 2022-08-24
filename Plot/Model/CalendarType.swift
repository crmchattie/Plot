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

let calendarEntity = "calendars"
let userCalendarEntity = "user-calendars"

struct CalendarType: Codable, Equatable, Hashable, Comparable {
    static func < (lhs: CalendarType, rhs: CalendarType) -> Bool {
        lhs.name ?? "" < rhs.name ?? ""
    }
    
    var name: String?
    var id: String?
    var description: String?
    var type: String?
    //CIColor(color: UIcolor).stringRepresentation
    var color: String?
    var source: String?
    var locationName: String?
    var locationAddress: [String : [Double]]?
    var participantsIDs: [String]?
    var lastModifiedDate: Date?
    var createdDate: Date?
    var admin: String?
    var badge: Int?
    var pinned: Bool?
    var muted: Bool?
    
    init(id: String, name: String?, color: String?, source: String) {
        self.id = id
        self.name = name
        self.color = color
        self.source = source
    }
}

let prebuiltCalendars: [CalendarType] = [defaultCalendar, personalCalendar, homeCalendar, workCalendar, socialCalendar]

let defaultCalendar = CalendarType(id: UUID().uuidString, name: "Default", color: CIColor(color: ChartColors.palette()[1]).stringRepresentation, source: CalendarOptions.plot.name)
let homeCalendar = CalendarType(id: UUID().uuidString, name: "Home", color: CIColor(color: ChartColors.palette()[1]).stringRepresentation, source: CalendarOptions.plot.name)
let personalCalendar = CalendarType(id: UUID().uuidString, name: "Personal", color: CIColor(color: ChartColors.palette()[0]).stringRepresentation, source: CalendarOptions.plot.name)
let socialCalendar = CalendarType(id: UUID().uuidString, name: "Social", color: CIColor(color: ChartColors.palette()[3]).stringRepresentation, source: CalendarOptions.plot.name)
let workCalendar = CalendarType(id: UUID().uuidString, name: "Work", color: CIColor(color: ChartColors.palette()[2]).stringRepresentation, source: CalendarOptions.plot.name)

enum CalendarOptions:String, CaseIterable {
    case plot = "Plot"
    case apple = "iCloud"
    case google = "Google"
    
    var image: UIImage {
            switch self {
            case .plot: return UIImage(named: "plotLogo")!
            case .apple: return UIImage(named: "iCloud")!
            case .google: return UIImage(named: "googleCalendar")!
        }
    }
        
    var name: String {
            switch self {
            case .plot: return "Plot"
            case .apple: return "iCloud"
            case .google: return "Google"
        }
    }
}
