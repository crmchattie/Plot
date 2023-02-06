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
let listTasksEntity = "list-tasks"

struct ListType: Codable, Equatable, Hashable, Comparable {
    static func < (lhs: ListType, rhs: ListType) -> Bool {
        lhs.name ?? "" < rhs.name ?? ""
    }
    
    var name: String?
    var id: String?
    var description: String?
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
    var category: String?
    var taskIDs: [String: Bool]?
    var defaultList: Bool?
    var financeList: Bool?
    var healthList: Bool?
    var goalList: Bool?
    
    init(id: String, name: String?, color: String?, source: String, admin: String?, defaultList: Bool?, financeList: Bool?, healthList: Bool?, goalList: Bool?) {
        self.id = id
        self.name = name
        self.color = color
        self.source = source
        self.admin = admin
        self.defaultList = defaultList
        self.financeList = financeList
        self.healthList = healthList
        self.goalList = goalList
    }
}

let prebuiltLists: [ListType] = [defaultList, financeList, healthList]

let defaultList = ListType(id: UUID().uuidString, name: ListOptions.defaultList.rawValue, color: CIColor(color: ChartColors.palette()[5]).stringRepresentation, source: ListSourceOptions.plot.name, admin: nil, defaultList: true, financeList: false, healthList: false, goalList: false)
let financeList = ListType(id: UUID().uuidString, name: "Finances", color: CIColor(color: ChartColors.palette()[1]).stringRepresentation, source: ListSourceOptions.plot.name, admin: nil, defaultList: false, financeList: true, healthList: false, goalList: false)
let healthList = ListType(id: UUID().uuidString, name: "Health", color: CIColor(color: ChartColors.palette()[2]).stringRepresentation, source: ListSourceOptions.plot.name, admin: nil, defaultList: false, financeList: false, healthList: true, goalList: false)

enum ListSourceOptions: String, CaseIterable {
    case plot = "Plot"
    case apple = "Apple"
    case google = "Google"
    
    var image: UIImage {
            switch self {
            case .plot: return UIImage(named: "plotLogo")!
            case .apple: return UIImage(named: "apple")!
            case .google: return UIImage(named: "google")!
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

enum ListOptions: String, CaseIterable {
    case defaultList = "Default"
    case todayList = "Today"
    case scheduledList = "Scheduled"
    case flaggedList = "Flagged"
    case allList = "All"
    case goalList = "Goals"
}
