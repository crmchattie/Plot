//
//  ActivityViewModel.swift
//  Pigeon-project
//
//  Created by Cory McHattie on 6/6/19.
//  Copyright © 2019 Immature Creations. All rights reserved.
//

//import UIKit
//
//extension CreateActivityViewController {
//        
//    class ViewModel {
//        
//        private let activity: Activity
//        
//        var activityID: String? {
//            get {
//                return activity.activityID
//            }
//            set {
//                activity.activityID = newValue
//            }
//        }
//        
//        var name: String? {
//            get {
//                return activity.name
//            }
//            set {
//                activity.name = newValue
//            }
//        }
//        
//        var type: String? {
//            get {
//                return activity.type
//            }
//            set {
//                activity.type = newValue
//            }
//        }
//        
//        var description: String? {
//            get {
//                return activity.description
//            }
//            set {
//                activity.description = newValue
//            }
//        }
//        
//        var locationName: String? {
//            get {
//                return activity.locationName
//            }
//            set {
//                activity.locationName = newValue
//            }
//        }
//        
//        var locationAddress: String? {
//            get {
//                return activity.locationAddress
//            }
//            set {
//                activity.locationAddress = newValue
//            }
//        }
//        
//        var participantsIDs: [String]? {
//            get {
//                return activity.participantsIDs
//            }
//            set {
//                activity.participantsIDs = newValue
//            }
//        }
//        
//        var participantsNames: String? {
//            get {
//                return activity.participantsNames
//            }
//            set {
//                activity.participantsNames = newValue
//            }
//        }
//        
//        var transportation: String? {
//            get {
//                return activity.transportation
//            }
//            set {
//                activity.transportation = newValue
//            }
//        }
//        
//        var activityPhotoURL: String? {
//            get {
//                return activity.activityPhotoURL
//            }
//            set {
//                activity.activityPhotoURL = newValue
//            }
//        }
//        
//        var activityThumbnailPhotoURL: String? {
//            get {
//                return activity.activityThumbnailPhotoURL
//            }
//            set {
//                activity.activityThumbnailPhotoURL = newValue
//            }
//        }
//        
//        var allDay: Bool? {
//            get {
//                return activity.allDay
//            }
//            set {
//                activity.allDay = newValue
//            }
//        }
//        
//        var startDateTime: Date {
//            get {
//                return activity.startDateTime ?? Date().addingTimeInterval(60*60*24)
//            }
//            set {
//                activity.startDateTime = newValue
//            }
//        }
//        
//        var endDateTime: Date {
//            get {
//                return activity.endDateTime ?? Date().addingTimeInterval(60*60*25)
//            }
//            set {
//                activity.endDateTime = newValue
//            }
//        }
//        
//        let reminderOptions: [String] = [Activity.Alert.none.rawValue, Activity.Alert.halfHour.rawValue, Activity.Alert.oneHour.rawValue, Activity.Alert.oneDay.rawValue, Activity.Alert.oneWeek.rawValue]
//        
//        var reminder: String? {
//            get {
//                return activity.reminder.rawValue
//            }
//            set {
//                if let value = newValue {
//                    activity.reminder = Activity.Alert(rawValue: value)!
//                }
//            }
//        }
//        
//        var notes: String? {
//            get {
//                return activity.notes
//            }
//            set {
//                activity.notes = newValue
//            }
//        }
//        
//        var schedule: Schedule? {
//            get {
//                return activity.schedule
//            }
//            set {
//                activity.schedule = newValue
//            }
//        }
//        
//        var purchases: Purchase? {
//            get {
//                return activity.purchases
//            }
//            set {
//                activity.purchases = newValue
//            }
//        }
//        
//        var checklist: [String : [String]] {
//            get {
//                return activity.checklist
//            }
//            set {
//                activity.checklist = newValue
//            }
//        }
//        
//        var admin: String? {
//            get {
//                return activity.admin
//            }
//            set {
//                activity.admin = newValue
//            }
//        }
//        
//        var badge: Int? {
//            get {
//                return activity.badge
//            }
//            set {
//                activity.badge = newValue
//            }
//        }
//        
//        var pinned: Bool? {
//            get {
//                return activity.pinned
//            }
//            set {
//                activity.pinned = newValue
//            }
//        }
//        
//        var muted: Bool? {
//            get {
//                return activity.muted
//            }
//            set {
//                activity.muted = newValue
//            }
//        }
//        
//        
//        // MARK: - Life Cycle
//        
//        init(activity: Activity) {
//            self.activity = activity
//        }
//    }
//}
