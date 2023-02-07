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

func mindfulnessData(mindfulnesses: [Mindfulness], start: Date, end: Date, completion: @escaping ([Statistic], [Mindfulness]) -> ()) {
    mindfulnessListStats(mindfulnesses: mindfulnesses, chunkStart: start, chunkEnd: end) { (stats, mindfulnesses) in
        completion(stats, mindfulnesses)
    }    
}

/// Categorize a list of activities, filtering down to a specific chunk [chunkStart, chunkEnd]
/// - Parameters:
///   - activities: A list of activities to analize.
///   - activityCategory: no idea what this is.
///   - chunkStart: Start date in which the activities are split and categorized.
///   - chunkEnd: End date in which the activities are split and categorized.
///   - completion: list of statistical elements and activities.
func mindfulnessListStats(
    mindfulnesses: [Mindfulness],
    chunkStart: Date,
    chunkEnd: Date,
    completion: @escaping ([Statistic], [Mindfulness]) -> ()
) {
    var statistics = [Statistic]()
    var mindfulnessList = [Mindfulness]()
    for mindfulness in mindfulnesses {
        guard var startDate = mindfulness.startDateTime,
              var endDate = mindfulness.endDateTime else {
            return
        }
        
        // Skipping activities that are outside of the interest range.
        if startDate >= chunkEnd || endDate <= chunkStart {
            continue
        }
                
        // Truncate events that out of the [chunkStart, chunkEnd] range.
        // Multi-day events, chunked into single day `Statistic`s are the best example.
        if startDate < chunkStart {
            startDate = chunkStart
        }
        if endDate > chunkEnd {
            endDate = chunkEnd
        }
        
        var duration = (endDate.timeIntervalSince1970 - startDate.timeIntervalSince1970) / 60
        if statistics.isEmpty {
            let stat = Statistic(date: chunkStart, value: duration)
            statistics.append(stat)
            mindfulnessList.append(mindfulness)
        } else {
            if let index = statistics.firstIndex(where: { $0.date == chunkStart }) {
                statistics[index].value += duration
                mindfulnessList.append(mindfulness)
            }
        }
    }
    completion(statistics, mindfulnessList)
}
