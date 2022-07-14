//
//  MXUser.swift
//  Plot
//
//  Created by Cory McHattie on 8/18/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

let userFinancialEntity = "user-financial"

struct MXUserResult: Codable {
    let user: MXUser?
    let users: [MXUser]?
    let pagination: MXPagination?
}

struct MXUser: Codable, Equatable {
    var guid: String
    //atrium API
    var identifier: String?
    //platform API
    var id: String?
    var is_disabled: Bool?
    var metadata: String?
    var connect_widget_url: String?
    
}

func ==(lhs: MXUser, rhs: MXUser) -> Bool {
    return lhs.guid == rhs.guid && lhs.identifier == rhs.identifier
}

struct MXPagination: Codable {
    let current_page: Int
    let per_page: Int
    let total_entries: Int
    let total_pages: Int
}
