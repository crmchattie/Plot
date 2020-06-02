//
//  Invitation.swift
//  Plot
//
//  Created by Hafiz Usama on 10/23/19.
//  Copyright © 2019 Immature Creations. All rights reserved.
//

import Foundation

enum Status: Int, Codable {
    case pending, accepted, declined, uninvited
    
    var description: String {
      get {
        switch self {
          case .pending:
            return "Pending"
          case .accepted:
            return "Accepted"
          case .declined:
            return "Declined"
          case .uninvited:
            return "Invite"
        }
      }
    }
}

let invitationsEntity = "invitations"
let userInvitationsEntity = "user-invitations"

struct Invitation: Codable, Equatable {
    let invitationID: String
    let activityID: String
    let participantID: String
    let dateInvited: Date
    var dateAccepted: Date?
    var status: Status
}

func ==(lhs: Invitation, rhs: Invitation) -> Bool {
    return lhs.activityID == rhs.activityID && lhs.participantID == rhs.participantID
}
