//
//  MXInstitution.swift
//  Plot
//
//  Created by Cory McHattie on 8/18/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

struct MXInstitutionResult: Codable {
    let institution: MXInstitution?
    let institutions: [MXInstitution]?
    let pagination: MXPagination?
}

struct MXInstitution: Codable, Equatable {
    var code: String
    var instructional_text: String
    var medium_logo_url: String
    var name: String
    var small_logo_url: String
    var supports_account_identification: Bool
    var supports_account_statement: Bool
    var supports_account_verification: Bool
    var supports_oauth: Bool
    var supports_transaction_history: Bool
    var url: String
    
}
