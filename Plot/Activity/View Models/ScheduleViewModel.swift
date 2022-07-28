//
//  ScheduleViewModel.swift
//  Pigeon-project
//
//  Created by Cory McHattie on 6/5/19.
//  Copyright © 2019 Immature Creations. All rights reserved.
//

//import UIKit
//
//extension ScheduleViewController {
//    
//    class ViewModel {
//        
//        private let schedule: Schedule
//        
//        var name: String? {
//            get {
//                return schedule.name
//            }
//            set {
//                schedule.name = newValue
//            }
//        }
//        
//        var description: String? {
//            get {
//                return schedule.description
//            }
//            set {
//                schedule.description = newValue
//            }
//        }
//        
//        var locationName: String? {
//            get {
//                return schedule.locationName
//            }
//            set {
//                schedule.locationName = newValue
//            }
//        }
//        
//        var locationAddress: String? {
//            get {
//                return schedule.locationAddress
//            }
//            set {
//                schedule.locationAddress = newValue
//            }
//        }
//        
//        var participantsIDs: [String]? {
//            get {
//                return schedule.participantsIDs
//            }
//            set {
//                schedule.participantsIDs = newValue
//            }
//        }
//        
//        var participantsNames: String? {
//            get {
//                return schedule.participantsNames
//            }
//            set {
//                schedule.participantsNames = newValue
//            }
//        }
//        
//        var transportation: String? {
//            get {
//                return schedule.transportation
//            }
//            set {
//                schedule.transportation = newValue
//            }
//        }
//        
//        var allDay: Bool? {
//            get {
//                return schedule.allDay
//            }
//            set {
//                schedule.allDay = newValue
//            }
//        }
//        
//        var startDateTime: Date {
//            get {
//                return schedule.startDateTime
//            }
//            set {
//                schedule.startDateTime = newValue
//            }
//        }
//        
//        var endDateTime: Date {
//            get {
//                return schedule.endDateTime
//            }
//            set {
//                schedule.endDateTime = newValue
//            }
//        }
//        
//        
//        let reminderOptions: [String] = [Schedule.Alert.none.rawValue, Schedule.Alert.halfHour.rawValue, Schedule.Alert.oneHour.rawValue, Schedule.Alert.oneDay.rawValue, Schedule.Alert.oneWeek.rawValue]
//        
//        var reminder: String? {
//            get {
//                return schedule.reminder.rawValue
//            }
//            set {
//                if let value = newValue {
//                    schedule.reminder = Schedule.Alert(rawValue: value)!
//                }
//            }
//        }
//        
//        var checklist: [String : [String]] {
//            get {
//                return schedule.checklist
//            }
//            set {
//                schedule.checklist = newValue
//            }
//        }
//        
//        
//        // MARK: - Life Cycle
//        
//        init(schedule: Schedule) {
//            self.schedule = schedule
//        }
//    }
//}
