//
//  Scheduler.swift
//  Plot
//
//  Created by Cory McHattie on 12/4/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import Foundation

let userWorkEntity = "user-work"
let workEntity = "work"

let userSleepEntity = "user-sleep"
let sleepEntity = "sleep"

struct Scheduler: Codable, Equatable, Hashable {
    var id: String
    var name: String?
    // day (Monday) :
    var activeDays: [DaysofWeek]?
    // StartTime/Endtime - "HH:mm:ss"
    var startTime: Date?
    var endTime: Date?
    var schedulerDate: Date?
    var lastModifiedDate: Date?
    var createdDate: Date?
}



func ==(lhs: Scheduler, rhs: Scheduler) -> Bool {
    return lhs.id == rhs.id
}

enum DaysofWeek: String, CaseIterable, Codable {
    case monday
    case tuesday
    case wednesday
    case thursday
    case friday
    case saturday
    case sunday
    
    var integer: Int {
        switch self {
        case .monday: return 0
        case .tuesday: return 1
        case .wednesday: return 2
        case .thursday: return 3
        case .friday: return 4
        case .saturday: return 5
        case .sunday: return 6
        }
    }
}

func getDaysOfWeek(integers: [Int]) -> [DaysofWeek] {
    var daysOfWeek = [DaysofWeek]()
    DaysofWeek.allCases.forEach { (dayOfWeek) in
        if integers.contains(dayOfWeek.integer) {
            daysOfWeek.append(dayOfWeek)
        }
    }
    return daysOfWeek
}
