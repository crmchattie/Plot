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
    var member: MXMember?
    var members: [MXMember]?
    var pagination: MXPagination?
}

struct MXMember: Codable, Equatable, Hashable {
    var aggregated_at: String?
    var connection_status: ConnectionStatus
    var guid: String
    //atrium API
    var identifier: String?
    //platform API
    var id: String?
    var institution_code: String
    var is_being_aggregated: Bool
    var is_managed_by_user: Bool?
    var is_oauth: Bool?
    var metadata: String?
    var name: String
    var status: String?
    var successfully_aggregated_at: String?
    var user_guid: String
    var user_id: String?
    var oauth_window_uri: String?
    var participantsIDs: [String]?
    var admin: String?
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

enum MXClientRedirectStatus: String, CaseIterable, Codable {
    case cancelled = "CANCELLED"
    case denied = "DENIED"
    case impeded = "IMPEDED"
    case provider = "PROVIDER_ERROR"
    case server = "SERVER_ERROR"
    case session = "SESSION_ERROR"
    
    var description: String {
        switch self {
        case .cancelled:
            return "Authentication process was cancelled. Please try again"
        case .denied:
            return "Authentication was denied. Please try again"
        case .impeded:
            return "Authentication requires user action. Please complete action on provider's website"
        case .provider:
            return "An unknown error occurred at the provider. Please try again"
        case .server:
            return "An unknown error occurred. Please try again"
        case .session:
            return "Authentication was unsuccessful. Please try again"
        }
    }
}
