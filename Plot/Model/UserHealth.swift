//
//  UserHealth.swift
//  Plot
//
//  Created by Hafiz Usama on 2020-10-06.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import Foundation

let userHealthEntity = "user-health"
let healthkitWorkoutsKey = "healthkit-workouts"
let lastSyncDateKey = "lastSyncDate"
let identifierKey = "identifier"

struct UserHealth: Codable, Equatable {
    let identifier: String
    var lastSyncDate: Date
}

func ==(lhs: UserHealth, rhs: UserHealth) -> Bool {
    return lhs.identifier == rhs.identifier
}
