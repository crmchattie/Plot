//
//  WorkoutSearchResult.swift
//  Plot
//
//  Created by Cory McHattie on 3/8/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import Foundation

// MARK: - Response
struct Workout: Codable {
    let id, title, identifier: String
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
}

// MARK: - Exercise
struct Exercise: Codable {
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
}

// MARK: - Anim
struct Anim: Codable {
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
struct DiagramImgs: Codable {
    let muscleGroups, muscleGroupsSecondary: [String]?
    let background: String?

    enum CodingKeys: String, CodingKey {
        case muscleGroups = "muscle_groups"
        case muscleGroupsSecondary = "muscle_groups_secondary"
        case background
    }
}
