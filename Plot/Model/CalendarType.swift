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
let calendarEventsEntity = "calendar-events"

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
    var eventIDs: [String: Bool]?
    var defaultCalendar: Bool?
    
    enum CodingKeys: String, CodingKey {
        case name, id, description, type, color, source, locationName, locationAddress, participantsIDs, lastModifiedDate, createdDate, admin, badge, pinned, muted, defaultCalendar
        case eventIDs = "calendar-events"
    }
    
    init(id: String, name: String?, color: String?, source: String, admin: String?, defaultCalendar: Bool?) {
        self.id = id
        self.name = name
        self.color = color
        self.source = source
        self.admin = admin
        self.defaultCalendar = defaultCalendar
    }
}

let prebuiltCalendars: [CalendarType] = [defaultCalendar, personalCalendar, homeCalendar, workCalendar, socialCalendar]

let defaultCalendar = CalendarType(id: UUID().uuidString, name: CalendarOptions.defaultCal.rawValue, color: CIColor(color: ChartColors.palette()[5]).stringRepresentation, source: CalendarSourceOptions.plot.name, admin: nil, defaultCalendar: true)
let homeCalendar = CalendarType(id: UUID().uuidString, name: CalendarOptions.homeCal.rawValue, color: CIColor(color: ChartColors.palette()[1]).stringRepresentation, source: CalendarSourceOptions.plot.name, admin: nil, defaultCalendar: false)
let personalCalendar = CalendarType(id: UUID().uuidString, name: CalendarOptions.personalCal.rawValue, color: CIColor(color: ChartColors.palette()[2]).stringRepresentation, source: CalendarSourceOptions.plot.name, admin: nil, defaultCalendar: false)
let socialCalendar = CalendarType(id: UUID().uuidString, name: CalendarOptions.socialCal.rawValue, color: CIColor(color: ChartColors.palette()[3]).stringRepresentation, source: CalendarSourceOptions.plot.name, admin: nil, defaultCalendar: false)
let workCalendar = CalendarType(id: UUID().uuidString, name: CalendarOptions.workCal.rawValue, color: CIColor(color: ChartColors.palette()[4]).stringRepresentation, source: CalendarSourceOptions.plot.name, admin: nil, defaultCalendar: false)

enum CalendarSourceOptions: String, CaseIterable {
    case plot = "Plot"
    case apple = "Apple"
    case google = "Google"
    
    var image: UIImage {
            switch self {
            case .plot: return UIImage(named: "plotLogo")!
            case .apple: return UIImage(named: "apple")!
            case .google: return UIImage(named: "googleCalendar")!
        }
    }
        
    var name: String {
            switch self {
            case .plot: return "Plot"
            case .apple: return "Apple"
            case .google: return "Google"
        }
    }
}

enum CalendarOptions: String, CaseIterable {
    case defaultCal = "Default"
    case homeCal = "Home"
    case personalCal = "Personal"
    case socialCal = "Social"
    case workCal = "Work"
}
