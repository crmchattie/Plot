//
//  Mindfulness.swift
//  Plot
//
//  Created by Cory McHattie on 12/8/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import Foundation
import HealthKit

let userMindfulnessEntity = "user-mindfulness"
let mindfulnessEntity = "mindfulness"

struct Mindfulness: Codable, Equatable, Hashable {
    var id: String
    var name: String
    var admin: String?
    var length: Double?
    var lastModifiedDate: Date?
    var createdDate: Date?
    var startDateTime: Date?
    var endDateTime: Date?
    var participantsIDs: [String]?
    var badge: Int?
    var pinned: Bool?
    var muted: Bool?
    var transactionIDs: [String]?
    var activityID: String?
    var healthExport: Bool?
    var user_created: Bool?
    var recurrences: [String]?
    
    init(id: String, name: String, admin: String?, lastModifiedDate: Date?, createdDate: Date?, startDateTime: Date?, endDateTime: Date?) {
        self.id = id
        self.name = name
        self.admin = admin
        self.lastModifiedDate = lastModifiedDate
        self.createdDate = createdDate
        self.startDateTime = startDateTime
        self.endDateTime = endDateTime
    }
        
    init(from mindfuless: HKCategorySample) {
        self.id = mindfuless.uuid.uuidString
        self.name = "Mindfulness"
        self.startDateTime = mindfuless.startDate
        self.endDateTime = mindfuless.endDate
    }
}

func ==(lhs: Mindfulness, rhs: Mindfulness) -> Bool {
    return lhs.id == rhs.id
}
