//
//  MXInstitution.swift
//  Plot
//
//  Created by Cory McHattie on 8/18/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

struct MXInstitutionResult: Codable, Equatable {
    let institution: MXInstitution?
    let institutions: [MXInstitution]?
}

struct MXInstitution: Codable, Equatable {
    let code: String
    let medium_logo_url: String
    let name: String
    let small_logo_url: String
    let supports_account_identification: Bool
    let supports_account_statement: Bool
    let supports_account_verification: Bool
    let supports_transaction_history: Bool
    let url: String
    
}

func ==(lhs: MXInstitution, rhs: MXInstitution) -> Bool {
    return lhs.code == rhs.code && lhs.name == rhs.name
    
}
