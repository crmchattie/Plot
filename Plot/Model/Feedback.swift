//
//  Feedback.swift
//  Plot
//
//  Created by Cory McHattie on 9/23/22.
//  Copyright © 2022 Immature Creations. All rights reserved.
//

import Foundation

let feedBackEntity = "feedback"

struct Feedback: Codable, Equatable, Hashable {
    var id: String
    var feedback: String
    var userID: String
    var createdDate: Date
    
    init(id: String, feedback: String, userID: String, createdDate: Date) {
        self.id = id
        self.feedback = feedback
        self.userID = userID
        self.createdDate = createdDate
    }
}
