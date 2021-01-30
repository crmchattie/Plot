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
    let connection_status: ConnectionStatus
    let guid: String
    let identifier: String?
    let institution_code: String
    let is_being_aggregated: Bool
    let metadata: String?
    let name: String
    let status: String?
    let successfully_aggregated_at: String
    let user_guid: String
    var participantsIDs: [String]?
}

enum ConnectionStatus: String, CaseIterable, Codable {
    case created = "CREATED"
    case prevented = "PREVENTED"
    case denied = "DENIED"
    case challenged = "CHALLENGED"
    case rejected = "REJECTED"
    case locked = "LOCKED"
    case connected = "CONNECTED"
    case impeded = "IMPEDED"
    case reconnected = "RECONNECTED"
    case degraded = "DEGRADED"
    case disconnected = "DISCONNECTED"
    case discontinued = "DISCONTINUED"
    case closed = "CLOSED"
    case delayed = "DELAYED"
    case failed = "FAILED"
    case updated = "UPDATED"
    case disabled = "DISABLED"
    case imported = "IMPORTED"
    case resumed = "RESUMED"
    case expired = "EXPIRED"
    case impaired = "IMPAIRED"
    case pending = "PENDING"
}
