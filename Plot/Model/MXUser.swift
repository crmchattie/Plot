//
//  MXUser.swift
//  Plot
//
//  Created by Cory McHattie on 8/18/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

let usersFinancialEntity = "user-financial"

struct MXUserResult: Codable, Equatable {
    let user: MXUser?
    let users: [MXUser]?
}

struct MXUser: Codable, Equatable {
    let guid: String
    var identifier: String?
    var is_disabled: Bool?
    let metadata: String?
    let connect_widget_url: String?
}

func ==(lhs: MXUser, rhs: MXUser) -> Bool {
    return lhs.guid == rhs.guid && lhs.identifier == rhs.identifier
}
