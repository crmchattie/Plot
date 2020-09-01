//
//  MXHoldings.swift
//  Plot
//
//  Created by Cory McHattie on 8/23/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

let usersFinancialHoldingsEntity = "user-financial-holdings"
let financialHoldingsEntity = "financial-holdings"

import Foundation

struct MXHoldingResult: Codable {
    let holding: MXHolding?
    let holdings: [MXHolding]?
    let pagination: MXPagination?
}

struct MXHolding: Codable, Equatable {
    let account_guid: String
    let cost_basis: Decimal?
    let created_at: String
    let currency_code: String?
    let cusip: String?
    let daily_change: Double?
    let description: String?
    let guid: String
    let holding_type: String?
    let market_value: Double?
    let member_guid: String
    let purchase_price: String?
    let shares: Double?
    let symbol: String?
    let updated_at: String
    let user_guid: String
    var participantsIDs: [String]?
}

func ==(lhs: MXHolding, rhs: MXHolding) -> Bool {
    return lhs.guid == rhs.guid && lhs.member_guid == rhs.member_guid && lhs.user_guid == rhs.user_guid
}
