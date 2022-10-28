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
    var healthExport: Bool?
    var user_created: Bool?
    var recurrences: [String]?
    var containerID: String?
    var hkSampleID: String?
    var directAssociation: Bool?
    var directAssociationObjectID: String?
    var directAssociationType: ObjectType?
    
    init(id: String, name: String, admin: String?, lastModifiedDate: Date?, createdDate: Date?, startDateTime: Date?, endDateTime: Date?, user_created: Bool?, directAssociation: Bool?, directAssociationType: ObjectType?) {
        self.id = id
        self.name = name
        self.admin = admin
        self.lastModifiedDate = lastModifiedDate
        self.createdDate = createdDate
        self.startDateTime = startDateTime
        self.endDateTime = endDateTime
        self.user_created = user_created
        self.directAssociation = directAssociation
        self.directAssociationType = directAssociationType
    }
    
    init(forInitialSave id: String, mindfuless: HKCategorySample) {
        self.id = id
        self.hkSampleID = mindfuless.uuid.uuidString
        self.name = "Mindfulness"
        self.startDateTime = mindfuless.startDate
        self.endDateTime = mindfuless.endDate
    }
    
    init(fromTemplate template: Template) {
        self.id = UUID().uuidString
        self.name = template.name
        self.user_created = true
        self.directAssociation = true
    }
} 

func ==(lhs: Mindfulness, rhs: Mindfulness) -> Bool {
    return lhs.id == rhs.id
}

struct UserMindfulness: Codable, Equatable, Hashable {
    var badge: Int?
    var pinned: Bool?
    var muted: Bool?
    var healthExport: Bool?
    var hkSampleID: String?
    var identifier: String?
    
    init(mindfulness: Mindfulness) {
        self.badge = mindfulness.badge
        self.pinned = mindfulness.pinned
        self.muted = mindfulness.muted
        self.healthExport = mindfulness.healthExport
        self.hkSampleID = mindfulness.hkSampleID
    }
}
