//
//  Mood.swift
//  Plot
//
//  Created by Cory McHattie on 12/4/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import Foundation

let userMoodsEntity = "user-moods"
let moodsEntity = "moods"

struct Mood: Codable, Equatable, Hashable {
    var id: String
    var mood: MoodType?
    var applicableTo: ApplicableTo?
    var notes: String?
    var moodDate: Date?
    var lastModifiedDate: Date?
    var createdDate: Date?
}

func ==(lhs: Mood, rhs: Mood) -> Bool {
    return lhs.id == rhs.id
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
