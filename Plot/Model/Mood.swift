//
//  Mood.swift
//  Plot
//
//  Created by Cory McHattie on 12/4/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import Foundation

let userMoodEntity = "user-moods"
let moodEntity = "moods"

struct Mood: Codable, Equatable, Hashable {
    var id: String
    var mood: MoodType?
    var applicableTo: ApplicableTo?
    var notes: String?
    var moodDate: Date?
    var lastModifiedDate: Date?
    var createdDate: Date?
    var participantsIDs: [String]?
    var containerID: String?
    var badge: Int?
    var pinned: Bool?
    var muted: Bool?
    
    init(id: String, lastModifiedDate: Date?, createdDate: Date?, moodDate: Date?, applicableTo: ApplicableTo?) {
        self.id = id
        self.lastModifiedDate = lastModifiedDate
        self.createdDate = createdDate
        self.moodDate = moodDate
        self.applicableTo = applicableTo
    }
    
    init(fromTemplate template: Template) {
        self.id = UUID().uuidString
        self.mood = template.mood
    }
}

func ==(lhs: Mood, rhs: Mood) -> Bool {
    return lhs.id == rhs.id
}

struct UserMood: Codable, Equatable, Hashable {
    var badge: Int?
    var pinned: Bool?
    var muted: Bool?
    
    init(mood: Mood) {
        self.badge = mood.badge
        self.pinned = mood.pinned
        self.muted = mood.muted
    }
}

enum MoodType: String, CaseIterable, Codable {
    case content = "Content"
    case energized = "Energized"
    case frustrated = "Frustrated"
    case happy = "Happy"
    case lazy = "Lazy"
    case optimistic = "Optimistic"
    case proud = "Proud"
    case sad = "Sad"
    case stressed = "Stressed"
    case tired = "Tired"
    
    var image: String {
        switch self {
        case .happy: return "faceHappy" //smiling
        case .sad: return "faceSad" //crying
        case .tired: return "faceTired" //tired
        case .stressed: return "faceStressed" //anxious
        case .proud: return "faceProud" //smirking
        case .optimistic: return "faceOptimistic"  //smiling with sunglasses
        case .energized: return "faceEnergized" //grinning
        case .lazy: return "faceLazy" //slightly frowning
        case .content: return "faceContent" //slightly smiling
        case .frustrated: return "faceFrustrated" //steam
        }
    }
}

enum ApplicableTo: String, CaseIterable, Codable {
    case specificTime
    case daily
    case weekly
    case monthly
    case yearly
    case activity
}
