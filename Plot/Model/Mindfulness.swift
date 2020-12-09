//
//  Mindfulness.swift
//  Plot
//
//  Created by Cory McHattie on 12/8/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import Foundation

let userMindfulnessEntity = "user-mindfulness"
let mindfulnessEntity = "mindfulness"

struct Mindfulness: Codable, Equatable, Hashable {
    var id: String
    var name: String?
    var startDateTime: Date?
    var endDateTime: Date?
    var lastModifiedDate: Date?
    var createdDate: Date?
    var participantsIDs: [String]?
    var admin: String?
    
}

func ==(lhs: Mindfulness, rhs: Mindfulness) -> Bool {
    return lhs.id == rhs.id
}
