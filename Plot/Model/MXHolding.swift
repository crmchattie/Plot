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
    var account_guid: String?
    var account_name: String?
    var cost_basis: Double?
    var created_at: String
    var currency_code: String?
    var cusip: String?
    var daily_change: Double?
    var description: String
    var guid: String
    var holding_type: MXHoldingType?
    var holding_type_id: String?
    //atrium API
    var identifier: String?
    //platform API
    var id: String?
    var market_value: Double?
    var member_guid: String?
    var metadata: String?
    var purchase_price: String?
    var shares: Double?
    var symbol: String?
    var updated_at: String
    var user_guid: String
    var participantsIDs: [String]?
    var tags: [String]?
    var should_link: Bool?
    var admin: String?
    var badge: Int?
    var pinned: Bool?
    var muted: Bool?
    var user_created: Bool?
    var holdingDescription: String?
    
    init(description: String, market_value: Double, created_at: String, guid: String, user_guid: String, holding_type: MXHoldingType, user_created: Bool?, admin: String) {
        self.description = description
        self.market_value = market_value
        self.created_at = created_at
        self.updated_at = created_at
        self.guid = guid
        self.user_guid = user_guid
        self.holding_type = holding_type
        self.user_created = user_created
    }
}

extension MXHolding {
    var promptContext: String {
        var context = String()
        let numberFormatter = NumberFormatter()
        numberFormatter.currencyCode = currency_code ?? "USD"
        numberFormatter.numberStyle = .currency
        numberFormatter.maximumFractionDigits = 0
        
        context += "Name: \(symbol ?? description)"
                              
        let isodateFormatter = ISO8601DateFormatter()
        let dateFormatterPrint = DateFormatter()
        dateFormatterPrint.dateFormat = "E, MMM d, yyyy"
        
        if let marketValue = market_value, let amount = numberFormatter.string(from: marketValue as NSNumber), let costBasis = cost_basis, costBasis != 0 {
            let percentFormatter = NumberFormatter()
            percentFormatter.numberStyle = .percent
            percentFormatter.positivePrefix = percentFormatter.plusSign
            percentFormatter.maximumFractionDigits = 0
            percentFormatter.minimumFractionDigits = 0
            
            let percent = marketValue / costBasis - 1
            if let percentText = percentFormatter.string(from: NSNumber(value: percent)) {
                context += ", Market Value: \(amount) (\(percentText))"
                
            }
        } else if let marketValue = market_value, let amount = numberFormatter.string(from: marketValue as NSNumber) {
            context += ", Market Value: \(amount)"
        }
        if let date = isodateFormatter.date(from: updated_at) {
            context += ", Last Updated: \(dateFormatterPrint.string(from: date))"
        }
        context += "; "
        return context
    }
}

struct UserHolding: Codable, Equatable, Hashable {
    var description: String?
    var tags: [String]?
    var should_link: Bool?
    var badge: Int?
    var pinned: Bool?
    var muted: Bool?
    
    init(holding: MXHolding) {
        self.description = holding.description
        self.tags = holding.tags
        self.should_link = holding.should_link
        self.badge = holding.badge
        self.pinned = holding.pinned
        self.muted = holding.muted
    }
}

struct HoldingDetails: Codable, Equatable, Hashable {
    var name: String
    var balance: Double
    var currencyCode: String?
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

func categorizeHoldings(holdings: [MXHolding], completion: @escaping ([HoldingDetails], [HoldingDetails: [MXHolding]]) -> ()) {
    var holdingsList = [HoldingDetails]()
    var holdingsDict = [HoldingDetails: [MXHolding]]()
    for holding in holdings {
        guard holding.should_link ?? true else { continue }
        if let index = holdingsDict.keys.firstIndex(where: {$0.name == holding.symbol ?? holding.description}) {
            var holdingDetail = holdingsDict.keys[index]
            var holdings = holdingsDict[holdingDetail]
            
            holdingsDict[holdingDetail] = nil
            
            holdingDetail.balance += holding.market_value ?? 0
            holdings!.append(holding)
            
            holdingsDict[holdingDetail] = holdings
        } else {
            let holdingDetail = HoldingDetails(name: holding.symbol ?? holding.description, balance: holding.market_value ?? 0, currencyCode: holding.currency_code)
            holdingsDict[holdingDetail] = [holding]
        }
    }
    holdingsList = Array(holdingsDict.keys)
    completion(holdingsList, holdingsDict)
}

