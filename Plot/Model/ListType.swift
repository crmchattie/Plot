//
//  ListType.swift
//  Plot
//
//  Created by Cory McHattie on 8/18/22.
//  Copyright © 2022 Immature Creations. All rights reserved.
//

import UIKit
import Firebase
import CodableFirebase

let listEntity = "lists"
let userListEntity = "user-lists"

struct ListType: Codable, Equatable, Hashable, Comparable {
    static func < (lhs: ListType, rhs: ListType) -> Bool {
        lhs.name ?? "" < rhs.name ?? ""
    }
    
    var name: String?
    var id: String?
    var description: String?
    var type: String?
    //CIColor(color: UIcolor).stringRepresentation
    var color: String?
    var source: String?
    var participantsIDs: [String]?
    var lastModifiedDate: Date?
    var createdDate: Date?
    var admin: String?
    var badge: Int?
    var pinned: Bool?
    var muted: Bool?
    
    init(id: String, name: String, color: String, source: String) {
        self.id = id
        self.name = name
        self.color = color
        self.source = source
    }
}

let prebuiltLists: [ListType] = [defaultList, homeList, personalList, socialList, workList]

let defaultList = ListType(id: UUID().uuidString, name: "Default", color: CIColor(color: ChartColors.palette()[1]).stringRepresentation, source: CalendarOptions.plot.name)
let homeList = ListType(id: UUID().uuidString, name: "Home", color: CIColor(color: ChartColors.palette()[1]).stringRepresentation, source: CalendarOptions.plot.name)
let personalList = ListType(id: UUID().uuidString, name: "Personal", color: CIColor(color: ChartColors.palette()[0]).stringRepresentation, source: CalendarOptions.plot.name)
let socialList = ListType(id: UUID().uuidString, name: "Social", color: CIColor(color: ChartColors.palette()[3]).stringRepresentation, source: CalendarOptions.plot.name)
let workList = ListType(id: UUID().uuidString, name: "Work", color: CIColor(color: ChartColors.palette()[2]).stringRepresentation, source: CalendarOptions.plot.name)

enum ListOptions:String, CaseIterable {
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
