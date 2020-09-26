//
//  MXMember.swift
//  Plot
//
//  Created by Cory McHattie on 8/18/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

let userFinancialMembersEntity = "user-financial-members"
let financialMembersEntity = "financial-members"

struct MXMemberResult: Codable {
    let member: MXMember?
    let members: [MXMember]?
    let pagination: MXPagination?
}

struct MXMember: Codable, Equatable, Hashable {
    let aggregated_at: String
    let connection_status: String
    let guid: String
    let identifier: String?
    let institution_code: String
    let is_being_aggregated: Bool
    let metadata: String?
    let name: String
    let status: String
    let successfully_aggregated_at: String
    let user_guid: String
    var participantsIDs: [String]?
}

func ==(lhs: MXMember, rhs: MXMember) -> Bool {
    return lhs.guid == rhs.guid
}
