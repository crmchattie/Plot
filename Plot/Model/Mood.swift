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
    var admin: String?
    
    init(id: String, admin: String?, lastModifiedDate: Date?, createdDate: Date?, moodDate: Date?, applicableTo: ApplicableTo?) {
        self.id = id
        self.admin = admin
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
    case excited = "Excited"
    case frustrated = "Frustrated"
    case happy = "Happy"
//    case lazy = "Lazy"
//    case optimistic = "Optimistic"
//    case proud = "Proud"
    case sad = "Sad"
    case stressed = "Stressed"
//    case tired = "Tired"
    
    var image: String {
        switch self {
        case .happy: return "faceHappy" //smiling
        case .sad: return "faceSad" //crying
//        case .tired: return "faceTired" //tired
        case .stressed: return "faceStressed" //anxious
//        case .proud: return "faceProud" //smirking
//        case .optimistic: return "faceOptimistic"  //smiling with sunglasses
        case .excited: return "faceEnergized" //grinning
//        case .lazy: return "faceLazy" //slightly frowning
        case .content: return "faceContent" //slightly smiling
        case .frustrated: return "faceFrustrated" //steam
        }
    }
    
    var color: UIColor {
        switch self {
        case .happy: return ChartColors.palette()[0]
        case .sad: return ChartColors.palette()[5]
//        case .tired: return ChartColors.palette()[3]
        case .stressed: return ChartColors.palette()[2]
//        case .proud: return ChartColors.palette()[5]
//        case .optimistic: return ChartColors.palette()[6]
        case .excited: return ChartColors.palette()[7]
//        case .lazy: return ChartColors.palette()[8]
        case .content: return ChartColors.palette()[8]
        case .frustrated: return ChartColors.palette()[4]
        }
    }
        
    static var allValues: [String] {
        var array = [String]()
        MoodType.allCases.forEach { category in
            array.append(category.rawValue)
        }
        return array
    }
}

enum ApplicableTo: String, CaseIterable, Codable {
    case specificTime
    case daily
    case weekly
    case monthly
    case yearly
    case mood
}

func categorizeMoods(moods: [Mood], start: Date, end: Date, completion: @escaping ([String: Double], [Mood]) -> ()) {
    var categoryDict = [String: Double]()
    var moodsList = [Mood]()
    // create dateFormatter with UTC time format
    for mood in moods {
        guard let moodDate = mood.moodDate, moodDate < end, moodDate >= start else { continue }
        if let type = mood.mood {
            if categoryDict[type.rawValue] == nil {
                categoryDict[type.rawValue] = 1
                moodsList.append(mood)
            } else {
                categoryDict[type.rawValue]! += 1
                moodsList.append(mood)
            }
        }
    }
    completion(categoryDict, moodsList)
}

func moodsOverTimeChartData(moods: [Mood], types: [String], start: Date, end: Date, segmentType: TimeSegmentType, completion: @escaping ([String: [Statistic]], [String: [Mood]]) -> ()) {
    var statistics = [String: [Statistic]]()
    var moodDict = [String: [Mood]]()
    let calendar = Calendar.current
    var date = start
    
    let component: Calendar.Component = {
        switch segmentType {
        case .day: return .hour
        case .week: return .day
        case .month: return .day
        case .year: return .month
        }
    }()
    
    var nextDate = calendar.date(byAdding: component, value: 1, to: date)!
    while date < end {
        for type in types {
            moodListStats(moods: moods, type: type, chunkStart: date, chunkEnd: nextDate) { (stat, moods) in
                if statistics[type] != nil, moodDict[type] != nil {
                    var acStats = statistics[type]
                    var acMoodList = moodDict[type]
                    acStats!.append(stat)
                    acMoodList!.append(contentsOf: moods)
                    statistics[type] = acStats
                    moodDict[type] = acMoodList
                } else {
                    statistics[type] = [stat]
                    moodDict[type] = moods
                }
            }
        }
        
        // Advance by one day:
        date = nextDate
        nextDate = calendar.date(byAdding: component, value: 1, to: nextDate)!
    }
    
    completion(statistics, moodDict)
}

func moodData(moods: [Mood], types: [String]?, start: Date, end: Date, completion: @escaping (Statistic, [Mood]) -> ()) {
    if types == nil {
        moodListStats(moods: moods, type: nil, chunkStart: start, chunkEnd: end) { (stat, moods) in
            completion(stat, moods)
        }
    } else {
        var stat = Statistic(date: start, value: 0)
        var moodList = [Mood]()
        for type in types ?? [] {
            moodListStats(moods: moods, type: type, chunkStart: start, chunkEnd: end) { (stats, moods) in
                stat.value += stats.value
                moodList.append(contentsOf: moods)
            }
        }
        completion(stat, moodList)
    }
}

/// Categorize a list of moods, filtering down to a specific chunk [chunkStart, chunkEnd]
/// - Parameters:
///   - moods: A list of moods to analize.
///   - moodCategory: no idea what this is.
///   - chunkStart: Start date in which the moods are split and categorized.
///   - chunkEnd: End date in which the moods are split and categorized.
///   - completion: list of statistical elements and moods.
func moodListStats(
    moods: [Mood],
    type: String?,
    chunkStart: Date,
    chunkEnd: Date,
    completion: @escaping (Statistic, [Mood]) -> ()
) {
    var stat = Statistic(date: chunkStart, value: 0)
    var moodList = [Mood]()
    for mood in moods {
        guard let moodDate = mood.moodDate, moodDate < chunkEnd, moodDate >= chunkStart else {
            continue
        }
        
        if let type = type, let moodType = mood.mood?.rawValue, moodType == type {
            stat.value += 1
            moodList.append(mood)
        } else if type == nil {
            stat.value += 1
            moodList.append(mood)
        }
    }
    completion(stat, moodList)
}
