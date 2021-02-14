//
//  MXHoldings.swift
//  Plot
//
//  Created by Cory McHattie on 8/23/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

let userFinancialHoldingsEntity = "user-financial-holdings"
let financialHoldingsEntity = "financial-holdings"

import Foundation

struct MXHoldingResult: Codable {
    let holding: MXHolding?
    let holdings: [MXHolding]?
    let pagination: MXPagination?
}

struct MXHolding: Codable, Equatable, Hashable {
    let account_guid: String?
    let cost_basis: Double?
    let created_at: String
    let currency_code: String?
    let cusip: String?
    let daily_change: Double?
    let description: String
    let guid: String?
    let holding_type: MXHoldingType?
    let id: String?
    let market_value: Double?
    let member_guid: String?
    let metadata: String?
    let purchase_price: String?
    let shares: Double?
    let symbol: String?
    let updated_at: String?
    let user_guid: String?
    var participantsIDs: [String]?
    var tags: [String]?
    var should_link: Bool?
    var admin: String?
    var badge: Int?
    var pinned: Bool?
    var muted: Bool?
}

struct UserHolding: Codable, Equatable, Hashable {
    var description: String?
    var tags: [String]?
    var should_link: Bool?
    var badge: Int?
    var pinned: Bool?
    var muted: Bool?
}

enum MXHoldingType: String, CaseIterable, Codable {
    case unknownType = "UNKNOWN_TYPE"
    case equity = "EQUITY"
    case exchangeTradedFund = "EXCHANGE_TRADED_FUND"
    case moneyMarket = "MONEY_MARKET"
    case mutualFund = "MUTUAL_FUND"
    case hedgeFund = "HEDGE_FUND"
    case annuity = "ANNUITY"
    case unitInvestmentTrust = "UNIT_INVESTMENT_TRUST"
    case cash = "CASH"
    case fixedIncome = "FIXED_INCOME"
    case options = "OPTIONS"
    case alternativeInvestments = "ALTERNATIVE_INVESTMENTS"
    case certificateOfDeposit = "CERTIFICATE_OF_DEPOSIT"
    case loan = "LOAN"
    
    var name: String {
        switch self {
        case .unknownType:
            return "Unknown Type"
        case .equity:
            return "Equity"
        case .exchangeTradedFund:
            return "Exchange Traded Fund"
        case .moneyMarket:
            return "Money Market"
        case .mutualFund:
            return "Mutual Fund"
        case .hedgeFund:
            return "Hedge Fund"
        case .annuity:
            return "Annuity"
        case .unitInvestmentTrust:
            return "Unit Investment Trust"
        case .cash:
            return "Cash"
        case .fixedIncome:
            return "Fixed Income"
        case .options:
            return "Options"
        case .alternativeInvestments:
            return "Alternative Investments"
        case .certificateOfDeposit:
            return "Certificate of Deposit"
        case .loan:
            return "Loan"
        }
    }
}

enum MXHoldingSubType: String, CaseIterable, Codable {
    case unknownSubtype = "UNKNOWN_SUBTYPE"
    case americanDepositaryReceipt = "AMERICAN_DEPOSITARY_RECEIPT"
    case stableValueFund = "STABLE_VALUE_FUND"
    case separateAccount = "SEPARATE_ACCOUNT"
    case segregatedFund = "SEGREGATED_FUND"
    case labourSponsoredInvestment = "LABOUR_SPONSORED_INVESTMENT"
    case collectiveInvestmentTrust = "COLLECTIVE_INVESTMENT_TRUST"
    case collegeSavings = "COLLEGE_SAVINGS"
    case incomeTrust = "INCOME_TRUST"
    case municipalBond = "MUNICIPAL_BOND"
    case corporateBond = "CORPORATE_BOND"
    case treasurySecurity = "TREASURY_SECURITY"
    case agencySecurity = "AGENCY_SECURITY"
    case mortgageBackedBond = "MORTGAGE_BACKED_BOND"
    case internationalBond = "INTERNATIONAL_BOND"
    case employeeStockOptions = "EMPLOYEE_STOCK_OPTIONS"
    case restrictedStockUnits = "RESTRICTED_STOCK_UNITS"
    case restrictedStock = "RESTRICTED_STOCK"
    case stockAppreciationRights = "STOCK_APPRECIATION_RIGHT"
    case limitedPartnershipUnits = "LIMITED_PARTNERSHIP_UNITS"
    case structuredProduct = "STRUCTURED_PRODUCT"
    case guaranteedInvestmentCertificate = "GUARANTEED_INVESTMENT_CERTIFICATE"
    
    var name: String {
        switch self {
        case .unknownSubtype:
            return "Unknown Type"
        case .americanDepositaryReceipt:
            return "American Depositary Receipt"
        case .stableValueFund:
            return "Stable Value Fund"
        case .separateAccount:
            return "Separate Account"
        case .segregatedFund:
            return "Segregated Fund"
        case .labourSponsoredInvestment:
            return "Labour Sponsored Investment"
        case .collectiveInvestmentTrust:
            return "Collective Invesment Trust"
        case .collegeSavings:
            return "College Savings"
        case .incomeTrust:
            return "Income Trust"
        case .municipalBond:
            return "Municipal Bond"
        case .corporateBond:
            return "Corporate Bond"
        case .treasurySecurity:
            return "Treasury Security"
        case .agencySecurity:
            return "Agency Security"
        case .mortgageBackedBond:
            return "Mortgage Backed Bond"
        case .internationalBond:
            return "International Bond"
        case .employeeStockOptions:
            return "Employee Stock Options"
        case .restrictedStockUnits:
            return "Restricted Stock Units"
        case .restrictedStock:
            return "Restricted Stock"
        case .stockAppreciationRights:
            return "Stock Appreciation Rights"
        case .limitedPartnershipUnits:
            return "Limited Partnership Units"
        case .structuredProduct:
            return "Structured Product"
        case .guaranteedInvestmentCertificate:
            return "Guaranteed Investment Certificate"
        }
    }
    
    var mxHoldingType: MXHoldingType {
        switch self {
        case .unknownSubtype:
            return .unknownType
        case .americanDepositaryReceipt:
            return .equity
        case .stableValueFund:
            return .moneyMarket
        case .separateAccount:
            return .mutualFund
        case .segregatedFund:
            return .mutualFund
        case .labourSponsoredInvestment:
            return .mutualFund
        case .collectiveInvestmentTrust:
            return .mutualFund
        case .collegeSavings:
            return .mutualFund
        case .incomeTrust:
            return .mutualFund
        case .municipalBond:
            return .fixedIncome
        case .corporateBond:
            return .fixedIncome
        case .treasurySecurity:
            return .fixedIncome
        case .agencySecurity:
            return .fixedIncome
        case .mortgageBackedBond:
            return .fixedIncome
        case .internationalBond:
            return .fixedIncome
        case .employeeStockOptions:
            return .options
        case .restrictedStockUnits:
            return .options
        case .restrictedStock:
            return .options
        case .stockAppreciationRights:
            return .options
        case .limitedPartnershipUnits:
            return .alternativeInvestments
        case .structuredProduct:
            return .alternativeInvestments
        case .guaranteedInvestmentCertificate:
            return .certificateOfDeposit
        }
    }
}
