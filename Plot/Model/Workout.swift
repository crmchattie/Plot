//
//  WorkoutSearchResult.swift
//  Plot
//
//  Created by Cory McHattie on 3/8/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import Foundation

let workoutsEntity = "workouts"
let userWorkoutsEntity = "user-workouts"

struct Workout: Codable, Equatable, Hashable {
    var id: String
    var name: String
    var type: String?
    var weight: Int?
    var duration: Double?
    var calories: Double?
    var participantsIDs: [String]?
    var lastModifiedDate: Date?
    var createdDate: Date?
    var startDateTime: Date?
    var endDateTime: Date?
    var admin: String?
    var badge: Int?
    var pinned: Bool?
    var muted: Bool?
}

func ==(lhs: Workout, rhs: Workout) -> Bool {
    return lhs.id == rhs.id
}

enum WorkoutTypes: String, Comparable, CaseIterable {
    static func < (lhs: WorkoutTypes, rhs: WorkoutTypes) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
    
    case weightLiftingGeneral = "Weight Lifting: General"
    case aerobicsWater = "Aerobics: Water"
    case stretchingHathaYoga = "Stretching/Hatha/Yoga"
    case calisthenicsModerate = "Calisthenics: Moderate"
    case aerobicsLowImpact = "Aerobics: Low Impact"
    case stairStepMachineGeneral = "Stair Step Machine: General"
    case teachingAerobics = "Teaching Aerobics"
    case weightLiftingVigorous = "Weight Lifting: Vigorous"
    case aerobicsStepLowImpact = "Aerobics Step: Low Impact"
    case aerobicsHighImpact = "Aerobics: High Impact"
    case bicyclingStationaryModerate = "Bicycling Stationary: Moderate"
    case rowingStationaryModerate = "Rowing Stationary: Moderate"
    case calisthenicsVigorous = "Calisthenics: Vigorous"
    case circuitTrainingGeneral = "Circuit Training: General"
    case rowingStationaryVigorous = "Rowing Stationary: Vigorous"
    case ellipticalTrainerGeneral = "Elliptical Trainer: General"
    case skiMachineGeneral = "Ski Machine: General"
    case aerobicsStepHighImpact = "Aerobics: Step High Impact"
    case bicyclingStationaryVigorous = "Bicycling: Stationary Vigorous"
    case billiards = "Billiards"
    case bowling = "Bowling"
    case dancingSlowWaltzFoxtrot = "Dancing: Slow/Waltz/Foxtrot"
    case frisbee = "Frisbee"
    case volleyballNoncompetitiveGeneralPlay = "Volleyball: Noncompetitive General Play"
    case waterVolleyball = "Water Volleyball"
    case archeryNonhunting = "Archery: Nonhunting"
    case golfUsingCart = "Golf: Using Cart"
    case hangGliding = "Hang Gliding"
    case curling = "Curling"
    case gymnasticsGeneral = "Gymnastics: General"
    case horsebackRidingGeneral = "Horseback Riding: General"
    case taiChi = "Tai Chi"
    case volleyballCompetitiveGymnasiumPlay = "Volleyball: Competitive Gymnasium Play"
    case walkingThreeHalf = "Walking: 3.5 Mph (17 Min/Mi)"
    case badmintonGeneral = "Badminton: General"
    case walkingFour = "Walking: 4 Mph (15 Min/Mi)"
    case kayaking = "Kayaking"
    case skateboarding = "Skateboarding"
    case snorkeling = "Snorkeling"
    case softballGeneralPlay = "Softball: General Play"
    case walkingFourHalf = "Walking: 4.5 Mph (13 Min/Mi)"
    case whitewaterRaftingKayaking = "Whitewater Rafting/Kayaking"
    case dancingDiscoBallroomSquare = "Dancing: Disco/Ballroom/Square"
    case golfCarryingClubs = "Golf: Carrying Clubs"
    case dancingFastBalletTwist = "Dancing: Fast Ballet Twist"
    case fencing = "Fencing"
    case hikingCrosscountry = "Hiking: Crosscountry"
    case skiingDownhill = "Skiing: Downhill"
    case swimmingGeneral = "Swimming: General"
    case walkJogLessThanTen = "Walk/Jog: <10 Min."
    case waterSkiing = "Water Skiing"
    case wrestling = "Wrestling"
    case basketballWheelchair = "Basketball: Wheelchair"
    case raceWalking = "Race Walking"
    case iceSkatingGeneral = "Ice Skating: General"
    case racquetballCasualGeneral = "Racquetball: Casual General"
    case rollerbladeSkating = "Rollerblade Skating"
    case scubaOrSkinDiving = "Scuba Diving"
    case sleddingLugeToboggan = "Sledding: Luge Toboggan"
    case soccerGeneral = "Soccer: General"
    case tennisGeneral = "Tennis: General"
    case basketballPlayingAGame = "Basketball: Playing A Game"
    case bicyclingLessThanFourteen = "Bicycling: 12-13.9 Mph"
    case footballTouchFlagGeneral = "Football: Touch/Flag/General"
    case iceFieldHockey = "Ice/Field Hockey"
    case rockClimbingRappelling = "Rock Climbing: Rappelling"
    case runningFive = "Running: 5 Mph (12 Min/Mile)"
    case runningPushingWheelchairMarathonWheeling = "Running: Pushing Wheelchair/Marathon Wheeling"
    case skiingCrosscountry = "Skiing: Crosscountry"
    case snowShoeing = "Snow Shoeing"
    case swimmingBackstroke = "Swimming: Backstroke"
    case volleyballBeach = "Volleyball: Beach"
    case bicyclingBmxOrMountain = "Bicycling: BMX Or Mountain"
    case boxingSparring = "Boxing: Sparring"
    case footballCompetitive = "Football: Competitive"
    case orienteering = "Orienteering"
    case runningFiveTwo = "Running: 5.2 Mph (11.5 Min/Mile)"
    case runningCrosscountry = "Running: Crosscountry"
    case bicyclingLessThanFifteen = "Bicycling: 14-15.9 Mph"
    case martialArtsJudoKarateKickbox = "Martial Arts: Judo/Karate/Kickbox"
    case racquetballCompetitive = "Racquetball: Competitive"
    case ropeJumping = "Rope Jumping"
    case runningSix = "Running: 6 Mph (10 Min/Mile)"
    case swimmingBreaststroke = "Swimming: Breaststroke"
    case swimmingLapsVigorous = "Swimming: Laps Vigorous"
    case swimmingTreadingVigorous = "Swimming Treading: Vigorous"
    case waterPolo = "Water Polo"
    case rockClimbingAscending = "Rock Climbing: Ascending"
    case running6SixSeven = "Running: 6.7 Mph (9 Min/Mile)"
    case swimmingButterfly = "Swimming: Butterfly"
    case swimmingCrawl = "Swimming: Crawl"
    case bicyclingSixteenNineteen = "Bicycling: 16-19.9 Mph"
    case handballGeneral = "Handball: General"
    case runningSevenFive = "Running: 7.5 Mph (8 Min/Mile)"
    case runningEightSix = "Running: 8.6 Mph (7 Min/Mile)"
    case bicyclingGreaterThanTwenty = "Bicycling: > 20 Mph"
    case runningTen = "Running: 10 Mph (6 Min/Mile)"
    
    var caloriesBurned: Double {
        switch self {
        case .weightLiftingGeneral: return 0.024
        case .aerobicsWater: return 0.032
        case .stretchingHathaYoga: return 0.032
        case .calisthenicsModerate: return 0.036
        case .aerobicsLowImpact: return 0.044
        case .stairStepMachineGeneral: return 0.048
        case .teachingAerobics: return 0.048
        case .weightLiftingVigorous: return 0.048
        case .aerobicsStepLowImpact: return 0.056
        case .aerobicsHighImpact: return 0.056
        case .bicyclingStationaryModerate: return 0.056
        case .rowingStationaryModerate: return 0.056
        case .calisthenicsVigorous: return 0.064
        case .circuitTrainingGeneral: return 0.064
        case .rowingStationaryVigorous: return 0.068
        case .ellipticalTrainerGeneral: return 0.072
        case .skiMachineGeneral: return 0.076
        case .aerobicsStepHighImpact: return 0.080
        case .bicyclingStationaryVigorous: return 0.084
        case .billiards: return 0.020
        case .bowling: return 0.024
        case .dancingSlowWaltzFoxtrot: return 0.024
        case .frisbee: return 0.024
        case .volleyballNoncompetitiveGeneralPlay: return 0.024
        case .waterVolleyball: return 0.024
        case .archeryNonhunting: return 0.028
        case .golfUsingCart: return 0.028
        case .hangGliding: return 0.028
        case .curling: return 0.032
        case .gymnasticsGeneral: return 0.032
        case .horsebackRidingGeneral: return 0.032
        case .taiChi: return 0.032
        case .volleyballCompetitiveGymnasiumPlay: return 0.032
        case .walkingThreeHalf: return 0.032
        case .badmintonGeneral: return 0.036
        case .walkingFour: return 0.036
        case .kayaking: return 0.040
        case .skateboarding: return 0.040
        case .snorkeling: return 0.040
        case .softballGeneralPlay: return 0.040
        case .walkingFourHalf: return 0.040
        case .whitewaterRaftingKayaking: return 0.040
        case .dancingDiscoBallroomSquare: return 0.044
        case .golfCarryingClubs: return 0.044
        case .dancingFastBalletTwist: return 0.048
        case .fencing: return 0.048
        case .hikingCrosscountry: return 0.048
        case .skiingDownhill: return 0.048
        case .swimmingGeneral: return 0.048
        case .walkJogLessThanTen: return 0.048
        case .waterSkiing: return 0.048
        case .wrestling: return 0.048
        case .basketballWheelchair: return 0.052
        case .raceWalking: return 0.052
        case .iceSkatingGeneral: return 0.056
        case .racquetballCasualGeneral: return 0.056
        case .rollerbladeSkating: return 0.056
        case .scubaOrSkinDiving: return 0.056
        case .sleddingLugeToboggan: return 0.056
        case .soccerGeneral: return 0.056
        case .tennisGeneral: return 0.056
        case .basketballPlayingAGame: return 0.064
        case .bicyclingLessThanFourteen: return 0.064
        case .footballTouchFlagGeneral: return 0.064
        case .iceFieldHockey: return 0.064
        case .rockClimbingRappelling: return 0.064
        case .runningFive: return 0.064
        case .runningPushingWheelchairMarathonWheeling: return 0.064
        case .skiingCrosscountry: return 0.064
        case .snowShoeing: return 0.064
        case .swimmingBackstroke: return 0.064
        case .volleyballBeach: return 0.064
        case .bicyclingBmxOrMountain: return 0.068
        case .boxingSparring: return 0.072
        case .footballCompetitive: return 0.072
        case .orienteering: return 0.072
        case .runningFiveTwo: return 0.072
        case .runningCrosscountry: return 0.072
        case .bicyclingLessThanFifteen: return 0.080
        case .martialArtsJudoKarateKickbox: return 0.080
        case .racquetballCompetitive: return 0.080
        case .ropeJumping: return 0.080
        case .runningSix: return 0.080
        case .swimmingBreaststroke: return 0.080
        case .swimmingLapsVigorous: return 0.080
        case .swimmingTreadingVigorous: return 0.080
        case .waterPolo: return 0.080
        case .rockClimbingAscending: return 0.088
        case .running6SixSeven: return 0.088
        case .swimmingButterfly: return 0.088
        case .swimmingCrawl: return 0.088
        case .bicyclingSixteenNineteen: return 0.096
        case .handballGeneral: return 0.096
        case .runningSevenFive: return 0.100
        case .runningEightSix: return 0.116
        case .bicyclingGreaterThanTwenty: return 0.132
        case .runningTen: return 0.132
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
