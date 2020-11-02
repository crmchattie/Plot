//
//  ActivityContainer.swift
//  Plot
//
//  Created by Cory McHattie on 6/30/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

//import Foundation
//
//struct ActivityContainer: Codable, Equatable, Hashable {
//    var customActivity: ActivityType?
//    var recipe: Recipe?
//    var event: Event?
//    var attraction: Attraction?
//    var workout: PreBuiltWorkout?
//    var fsVenue: FSVenue?
//    var sygicPlace: SygicPlace?
//    
//    var type: String {
//        if customActivity != nil {
//            return "customActivity"
//        } else if recipe != nil {
//            return "recipe"
//        } else if event != nil {
//            return "event"
//        } else if attraction != nil {
//            return "attraction"
//        } else if workout != nil {
//            return "workout"
//        } else if fsVenue != nil {
//            return "fsVenue"
//        } else if sygicPlace != nil {
//            return "sygicPlace"
//        } else {
//            return "none"
//        }
//    }
//}
//
//func ==(lhs: ActivityContainer, rhs: ActivityContainer) -> Bool {
//    return lhs.customActivity == rhs.customActivity && lhs.recipe == rhs.recipe && lhs.event == rhs.event && lhs.attraction == rhs.attraction && lhs.workout == rhs.workout && lhs.fsVenue == rhs.fsVenue && lhs.sygicPlace == rhs.sygicPlace
//}
//
//struct ActivityArrayContainer: Codable, Equatable, Hashable {
//    var customActivities: [ActivityType]?
//    var recipes: [Recipe]?
//    var events: [Event]?
//    var attractions: [Attraction]?
//    var workouts: [PreBuiltWorkout]?
//    var fsVenues: [GroupItem]?
//    var sygicPlaces: [SygicPlace]?
//    
//    var type: String {
//        if customActivities != nil {
//            return "customActivities"
//        } else if recipes != nil {
//            return "recipes"
//        } else if events != nil {
//            return "events"
//        } else if attractions != nil {
//            return "attractions"
//        } else if workouts != nil {
//            return "workouts"
//        } else if fsVenues != nil {
//            return "fsVenues"
//        } else if sygicPlaces != nil {
//            return "sygicPlaces"
//        } else {
//            return "none"
//        }
//    }
//}
//
//func ==(lhs: ActivityArrayContainer, rhs: ActivityArrayContainer) -> Bool {
//    return lhs.customActivities == rhs.customActivities && lhs.recipes == rhs.recipes && lhs.events == rhs.events && lhs.attractions == rhs.attractions && lhs.workouts == rhs.workouts && lhs.fsVenues == rhs.fsVenues && lhs.sygicPlaces == rhs.sygicPlaces
//}
