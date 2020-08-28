//
//  MXAccount.swift
//  Plot
//
//  Created by Cory McHattie on 8/18/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

let usersFinancialAccountsEntity = "user-financial-accounts"

struct MXAccountResult: Codable, Equatable {
    let account: MXAccount?
    let accounts: [MXAccount]?
}

struct MXAccount: Codable, Equatable {
    let account_number: String
    let apr: Double?
    let apy: Double?
    let available_balance: Double
    let available_credit: Double?
    let balance: Double
    let cash_balance: Double?
    let cash_surrender_value: Double?
    let created_at: String
    let credit_limit: Double?
    let currency_code: String
    let day_payment_is_due: Int?
    let death_benefit: Double?
    let guid: String
    let holdings_value: Double?
    let institution_code: String
    let interest_rate: Double?
    let is_closed: Bool
    let last_payment: Double?
    let last_payment_at: String?
    let loan_amount: Double?
    let matures_on: String?
    let member_guid: String
    let minimum_balance: Double?
    let minimum_payment: Double?
    let name: String
    let original_balance: Double?
    let payment_due_at: String?
    let payoff_balance: Double?
    let started_on: String?
    let subtype: String
    let total_account_value: Double?
    let type: String
    let updated_at: String
    let user_guid: String
    var participantsIDs: [String]?
    var bs_type: String {
        if self.type == "CHECKING" || self.type == "SAVINGS" || self.type == "INVESTMENT" || self.type == "PROPERTY" || self.type == "CASH" || self.type == "INSURANCE" || self.type == "PREPAID" {
            return "asset"
        } else if self.type == "LOAN" || self.type == "CREDIT_CARD" || self.type == "LINE_OF_CREDIT" || self.type == "MORTGAGE" {
            return "liability"
        } else {
            return "none"
        }
    }
}

func ==(lhs: MXAccount, rhs: MXAccount) -> Bool {
    return lhs.guid == rhs.guid && lhs.user_guid == rhs.user_guid
}

func assets(accounts: [MXAccount]) -> Double {
    var assets: Double = 0.0
    for account in accounts {
        if account.bs_type == "asset" {
            assets += account.balance
        }
    }
    return assets
}

func liabilities(accounts: [MXAccount]) -> Double {
    var liabilities: Double = 0.0
    for account in accounts {
        if account.bs_type == "liability" {
            liabilities += account.balance
        }
    }
    return liabilities
}

func networth(accounts: [MXAccount]) -> Double {
    let networth = assets(accounts: accounts) - liabilities(accounts: accounts)
    return networth
}

