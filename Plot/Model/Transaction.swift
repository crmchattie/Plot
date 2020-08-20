//
//  Transaction.swift
//  Plot
//
//  Created by Cory McHattie on 8/18/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import Foundation

struct MXTransactionResult: Codable, Equatable {
    let transaction: Transaction?
    let transactions: [Transaction]?
}

struct Transaction: Codable, Equatable {
    let account_guid: String
    let amount: Double
    let category: String
    let check_number: Int
    let check_number_string: String
    let created_at: String
    let currency_code: String
    let date: String
    let description: String
    let guid: String
    let is_bill_pay: Bool
    let is_direct_deposit: Bool
    let is_expense: Bool
    let is_fee: Bool
    let is_income: Bool
    let is_international: Bool
    let is_overdraft_fee: Bool
    let is_payroll_advance: Bool
    let latitude: Double
    let longitude: Double
    let member_guid: String
    let memo: String
    let merchant_category_code: Int
    let merchant_guid: String
    let original_description: String
    let posted_at: String
    let status: String
    let top_level_category: String
    let transacted_at: String
    let type: String
    let updated_at: String
    let user_guid: String
}

func ==(lhs: Transaction, rhs: Transaction) -> Bool {
    return lhs.guid == rhs.guid && lhs.member_guid == rhs.member_guid && lhs.user_guid == rhs.user_guid
}


