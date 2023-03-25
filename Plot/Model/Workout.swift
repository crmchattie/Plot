//
//  WorkoutSearchResult.swift
//  Plot
//
//  Created by Cory McHattie on 3/8/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import Foundation
import HealthKit

let workoutsEntity = "custom-workouts"
let userWorkoutsEntity = "user-custom-workouts"

struct Workout: Codable, Equatable, Hashable {
    var id: String
    var name: String
    var admin: String?
    var type: String?
    var participantsIDs: [String]?
    var lastModifiedDate: Date?
    var createdDate: Date?
    var startDateTime: Date?
    var endDateTime: Date?
    var length: Double?
    var totalEnergyBurned: Double?
    var totalDistance: Double?
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
    
    init(id: String, name: String, admin: String?, lastModifiedDate: Date?, createdDate: Date?, type: String?, startDateTime: Date?, endDateTime: Date?, length: Double?, totalEnergyBurned: Double?, totalDistance: Double?, user_created: Bool?, directAssociation: Bool?, directAssociationType: ObjectType?) {
        self.id = id
        self.name = name
        self.admin = admin
        self.lastModifiedDate = lastModifiedDate
        self.createdDate = createdDate
        self.type = type
        self.startDateTime = startDateTime
        self.endDateTime = endDateTime
        self.length = length
        self.totalEnergyBurned = totalEnergyBurned
        self.totalDistance = totalDistance
        self.user_created = user_created
        self.directAssociation = directAssociation
        self.directAssociationType = directAssociationType
    }
    
    init(forInitialSave id: String, hkWorkout: HKWorkout) {
        self.id = id
        self.hkSampleID = hkWorkout.uuid.uuidString
        self.name = hkWorkout.workoutActivityType.name
        self.type = hkWorkout.workoutActivityType.name
        self.startDateTime = hkWorkout.startDate
        self.endDateTime = hkWorkout.endDate
        self.length = hkWorkout.duration
        if let val = hkWorkout.totalEnergyBurned {
            self.totalEnergyBurned = val.doubleValue(for: HKUnit.kilocalorie())
        }
        if let val = hkWorkout.totalDistance {
            if hkWorkout.workoutActivityType == .swimming {
                self.totalDistance = val.doubleValue(for: HKUnit.yard())
            } else {
                self.totalDistance = val.doubleValue(for: HKUnit.mile())
            }
        }
    }
    
    init(fromTemplate template: Template) {
        self.id = UUID().uuidString
        self.createdDate = Date()
        self.name = template.name
        self.type = template.name
        self.totalEnergyBurned = template.totalEnergyBurned
        self.startDateTime = template.getStartDate()
        self.endDateTime = template.getEndDate()
        self.user_created = true
        self.directAssociation = true
        self.directAssociationType = .event
    }
}

func ==(lhs: Workout, rhs: Workout) -> Bool {
    return lhs.id == rhs.id
}

struct UserWorkout: Codable, Equatable, Hashable {
    var totalEnergyBurned: Double?
    var badge: Int?
    var pinned: Bool?
    var muted: Bool?
    var healthExport: Bool?
    var hkSampleID: String?
    var startDateTime: Date?
    
    init(workout: Workout) {
        self.totalEnergyBurned = workout.totalEnergyBurned
        self.badge = workout.badge
        self.pinned = workout.pinned
        self.muted = workout.muted
        self.healthExport = workout.healthExport
        self.hkSampleID = workout.hkSampleID
    }
}

enum WorkoutMeasure {
    case duration, calories
}

func categorizeWorkouts(workouts: [Workout], measure: WorkoutMeasure, start: Date, end: Date, completion: @escaping ([String: Double], [Workout]) -> ()) {
    var categoryDict = [String: Double]()
    var workoutsList = [Workout]()
    for workout in workouts {
        guard let startDate = workout.startDateTime?.localTime,
              let endDate = workout.endDateTime?.localTime else {
            continue
        }
        
        // Skipping activities that are outside of the interest range.
        if startDate > end || endDate <= start {
            continue
        }
        
        if let type = workout.type {
            if categoryDict[type] == nil {
                let measureDouble = measure == .duration ? (endDate.timeIntervalSince1970 - startDate.timeIntervalSince1970) / 60 : workout.totalEnergyBurned ?? 0
                categoryDict[type] = measureDouble
                workoutsList.append(workout)
            } else {
                let measureDouble = measure == .duration ? (endDate.timeIntervalSince1970 - startDate.timeIntervalSince1970) / 60 : workout.totalEnergyBurned ?? 0
                categoryDict[type]! += measureDouble
                workoutsList.append(workout)
            }
        }
    }
                
    completion(categoryDict, workoutsList)
}

func workoutsOverTimeChartData(workouts: [Workout], measure: WorkoutMeasure, categories: [String], start: Date, end: Date, segmentType: TimeSegmentType, completion: @escaping ([String: [Statistic]], [String: [Workout]]) -> ()) {
    var statistics = [String: [Statistic]]()
    var workoutDict = [String: [Workout]]()
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
        for category in categories {
            workoutListStats(workouts: workouts, measure: measure, category: category, chunkStart: date, chunkEnd: nextDate) { (stat, workouts) in
                if statistics[category] != nil, workoutDict[category] != nil {
                    var acStats = statistics[category]
                    var acWorkoutList = workoutDict[category]
                    acStats!.append(stat)
                    acWorkoutList!.append(contentsOf: workouts)
                    statistics[category] = acStats
                    workoutDict[category] = acWorkoutList
                } else {
                    statistics[category] = [stat]
                    workoutDict[category] = workouts
                }
            }
        }
        
        // Advance by one day:
        date = nextDate
        nextDate = calendar.date(byAdding: component, value: 1, to: nextDate)!
    }
    
    completion(statistics, workoutDict)
}

func workoutData(workouts: [Workout], measure: WorkoutMeasure, categories: [String]?, start: Date, end: Date, completion: @escaping (Statistic, [Workout]) -> ()) {
    if categories == nil {
        workoutListStats(workouts: workouts, measure: measure, category: nil, chunkStart: start, chunkEnd: end) { (stat, workouts) in
            completion(stat, workouts)
        }
    } else {
        var stat = Statistic(date: start, value: 0)
        var workoutList = [Workout]()
        for category in categories ?? [] {
            workoutListStats(workouts: workouts, measure: measure, category: category, chunkStart: start, chunkEnd: end) { (stats, workouts) in
                stat.value += stats.value
                workoutList.append(contentsOf: workouts)
            }
        }
        completion(stat, workoutList)
    }
}

/// Categorize a list of activities, filtering down to a specific chunk [chunkStart, chunkEnd]
/// - Parameters:
///   - activities: A list of activities to analize.
///   - activityCategory: no idea what this is.
///   - chunkStart: Start date in which the activities are split and categorized.
///   - chunkEnd: End date in which the activities are split and categorized.
///   - completion: list of statistical elements and activities.
func workoutListStats(
    workouts: [Workout],
    measure: WorkoutMeasure,
    category: String?,
    chunkStart: Date,
    chunkEnd: Date,
    completion: @escaping (Statistic, [Workout]) -> ()
) {
    var stat = Statistic(date: chunkStart, value: 0)
    var workoutList = [Workout]()
    for workout in workouts {
        guard var startDate = workout.startDateTime?.localTime,
              var endDate = workout.endDateTime?.localTime else {
            continue
        }
        
        // Skipping activities that are outside of the interest range.
        if startDate >= chunkEnd || endDate <= chunkStart {
            continue
        }
        
//        print(chunkStart)
//        print(chunkEnd)
//        print("passed dates workouts")
//        print(startDate)
//        print(endDate)
//                
        // Truncate events that out of the [chunkStart, chunkEnd] range.
        // Multi-day events, chunked into single day `Statistic`s are the best example.
        if startDate < chunkStart {
            startDate = chunkStart
        }
        if endDate > chunkEnd {
            endDate = chunkEnd
        }
        
        if let category = category, let type = workout.type, type == category {
            let measureDouble = measure == .duration ? (endDate.timeIntervalSince1970 - startDate.timeIntervalSince1970) / 60 : workout.totalEnergyBurned ?? 0
            stat.value += measureDouble
            workoutList.append(workout)
        } else if category == nil {
            let measureDouble = measure == .duration ? (endDate.timeIntervalSince1970 - startDate.timeIntervalSince1970) / 60 : workout.totalEnergyBurned ?? 0
            stat.value += measureDouble
            workoutList.append(workout)
        }
    }
    completion(stat, workoutList)
}

extension Workout {
    var hkWorkoutActivityType: HKWorkoutActivityType {        
        switch type {
        case "American Football":           return .americanFootball
        case "Archery":                     return .archery
        case "Australian Football":         return .australianFootball
        case "Badminton":                   return .badminton
        case "Baseball":                    return .baseball
        case "Basketball":                  return .basketball
        case "Bowling":                     return .bowling
        case "Boxing":                      return .boxing
        case "Climbing":                    return .climbing
        case "Cross Training":              return .crossTraining
        case "Curling":                     return .curling
        case "Cycling":                     return .cycling
        case "Dance":                       return .dance
        case "Dance Inspired Training":     return .danceInspiredTraining
        case "Elliptical":                  return .elliptical
        case "Equestrian Sports":           return .equestrianSports
        case "Fencing":                     return .fencing
        case "Fishing":                     return .fishing
        case "Functional Strength Training":return .functionalStrengthTraining
        case "Golf":                        return .golf
        case "Gymnastics":                  return .gymnastics
        case "Handball":                    return .handball
        case "Hiking":                      return .hiking
        case "Hockey":                      return .hockey
        case "Hunting":                     return .hunting
        case "Lacrosse":                    return .lacrosse
        case "Martial Arts":                return .martialArts
        case "Mind and Body":               return .mindAndBody
        case "Mixed Metabolic Cardio Training":return .mixedMetabolicCardioTraining
        case "Paddle Sports":               return .paddleSports
        case "Play":                        return .play
        case "Preparation and Recovery":    return .preparationAndRecovery
        case "Racquetball":                 return .racquetball
        case "Rowing":                      return .rowing
        case "Rugby":                       return .rugby
        case "Running":                     return .running
        case "Sailing":                     return .sailing
        case "Skating Sports":              return .skatingSports
        case "Snow Sports":                 return .snowSports
        case "Soccer":                      return .soccer
        case "Softball":                    return .softball
        case "Squash":                      return .squash
        case "Stair Climbing":              return .stairClimbing
        case "Surfing Sports":              return .surfingSports
        case "Swimming":                    return .swimming
        case "Table Tennis":                return .tableTennis
        case "Tennis":                      return .tennis
        case "Track and Field":             return .trackAndField
        case "Traditional Strength Training":return .traditionalStrengthTraining
        case "Volleyball":                  return .volleyball
        case "Walking":                     return .walking
        case "Water Fitness":               return .waterFitness
        case "Water Polo":                  return .waterPolo
        case "Water Sports":                return .waterSports
        case "Wrestling":                   return .wrestling
        case "Yoga":                        return .yoga
            
        // iOS 10
        case "Barre":                       return .barre
        case "Core Training":               return .coreTraining
        case "Cross Country Skiing":        return .crossCountrySkiing
        case "Downhill Skiing":             return .downhillSkiing
        case "Flexibility":                 return .flexibility
        case "High Intensity Interval Training": return .highIntensityIntervalTraining
        case "Jump Rope":                   return .jumpRope
        case "Kickboxing":                  return .kickboxing
        case "Pilates":                     return .pilates
        case "Snowboarding":                return .snowboarding
        case "Stairs":                      return .stairs
        case "Step Training":               return .stepTraining
        case "Wheelchair Walk Pace":        return .wheelchairWalkPace
        case "Wheelchair Run Pace":         return .wheelchairRunPace
            
        // iOS 11
        case "Tai Chi":                     return .taiChi
        case "Mixed Cardio":                return .mixedCardio
        case "Hand Cycling":                return .handCycling
            
        // iOS 13
        case "Disc Sports":                 return .discSports
        case "Fitness Gaming":              return .fitnessGaming
        case "Cricket":
            return .cricket
        case "Cardio Dance":
            if #available(iOS 14.0, *) {
                return .cardioDance
            } else {
                return .running
            }
        case "Social Dance":
            if #available(iOS 14.0, *) {
                return .socialDance
            } else {
                return .running
            }
        case "Pickleball":
            if #available(iOS 14.0, *) {
                return .pickleball
            } else {
                return .running
            }
        case "Cooldown":
            if #available(iOS 14.0, *) {
                return .cooldown
            } else {
                return .running
            }
        case "Triathlon":
            if #available(iOS 16.0, *) {
                return .swimBikeRun
            } else {
                return .running
            }
        case "Transition":
            if #available(iOS 16.0, *) {
                return .transition
            } else {
                return .walking
            }
        case "Other":
            return .other
        default:
            return .running
        }
    }
}

// MARK: - Response
struct PreBuiltWorkout: Codable, Equatable, Hashable {
    let uuid = UUID().uuidString
    let id, identifier: String
    var title: String
    let notes, workoutDuration, tagsStr: String?
    let equipment: [String]?
    let equipment_level: String?
    let exercises: [Exercise]?

    enum CodingKeys: String, CodingKey {
        case id, title, notes, identifier, equipment, equipment_level
        case workoutDuration = "workout_duration"
        case tagsStr = "tags_str"
        case exercises
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(uuid)
    }
}

func ==(lhs: PreBuiltWorkout, rhs: PreBuiltWorkout) -> Bool {
    return lhs.uuid == rhs.uuid
}

// MARK: - Exercise
struct Exercise: Codable, Equatable, Hashable {
    let id, exerciseWpID, sets, reps: String?
    let repsType, rest, restType, notes: String?
    let ss, restBetween: String?
    let isCardio, isYoga: Bool?
    let sanskrit, modification, warning, pronunciation: String?
    let alignmentCues, postContent, commonName: String?
    let anim: Anim?
    let tags, types, name: String?
    let illustrationM, illustrationF: String?
    let muscleGroups, muscleGroupsSecondary: String?
    let diagramImgs: DiagramImgs?
    let ssHex: String?
    let equipment: [String]?
    let equipment_level: String?

    enum CodingKeys: String, CodingKey {
        case id
        case exerciseWpID = "exercise_wp_id"
        case sets, reps
        case repsType = "reps_type"
        case rest
        case restType = "rest_type"
        case notes, ss
        case restBetween = "rest_between"
        case isCardio = "is_cardio"
        case isYoga = "is_yoga"
        case sanskrit, modification, warning, pronunciation
        case alignmentCues = "alignment_cues"
        case postContent = "post_content"
        case commonName = "common_name"
        case anim, tags, types, name
        case illustrationM = "illustration_m"
        case illustrationF = "illustration_f"
        case muscleGroups = "muscle_groups"
        case muscleGroupsSecondary = "muscle_groups_secondary"
        case diagramImgs = "diagram_imgs"
        case ssHex = "ss_hex"
        case equipment
        case equipment_level
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

func ==(lhs: Exercise, rhs: Exercise) -> Bool {
    return lhs.id == rhs.id
}

// MARK: - Anim
struct Anim: Codable, Equatable, Hashable {
    let female: String?
    let femaleID: String?
    let male: String?
    let maleID: String?

    enum CodingKeys: String, CodingKey {
        case female
        case femaleID = "female_id"
        case male
        case maleID = "male_id"
    }
}

// MARK: - DiagramImgs
struct DiagramImgs: Codable, Equatable, Hashable {
    let muscleGroups, muscleGroupsSecondary: [String]?
    let background: String?

    enum CodingKeys: String, CodingKey {
        case muscleGroups = "muscle_groups"
        case muscleGroupsSecondary = "muscle_groups_secondary"
        case background
    }
}
