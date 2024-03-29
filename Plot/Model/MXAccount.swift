//
//  MXAccount.swift
//  Plot
//
//  Created by Cory McHattie on 8/18/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

let userFinancialAccountsEntity = "user-financial-accounts"
let financialAccountsEntity = "financial-accounts"
let userFinancialAccountsTasksEntity = "user-financial-accounts-tasks"

struct MXAccountResult: Codable {
    let account: MXAccount?
    let accounts: [MXAccount]?
    let pagination: MXPagination?
}

struct MXAccount: Codable, Equatable, Hashable {
    var account_number: String?
    var apr: Double?
    var apy: Double?
    var available_balance: Double?
    var available_credit: Double?
    var balance: Double
    var balances: [String: Double]?
    var cash_balance: Double?
    var cash_surrender_value: Double?
    var created_at: String
    var credit_limit: Double?
    var currency_code: String?
    var day_payment_is_due: Int?
    var death_benefit: Double?
    var guid: String
    var holdings_value: Double?
    //atrium API
    var identifier: String?
    //platform API
    var id: String?
    var imported_at: String?
    var institution_code: String?
    var insured_name: String?
    var interest_rate: Double?
    var is_closed: Bool?
    var is_hidden: Bool?
    var last_payment: Double?
    var last_payment_at: String?
    var loan_amount: Double?
    var loan_balance: Double?
    var matures_on: String?
    var member_guid: String?
    var member_id: String?
    var member_is_managed_by_user: Bool?
    var meta: String?
    var minimum_balance: Double?
    var minimum_payment: Double?
    var name: String
    var nickname: String?
    var original_balance: Double?
    var pay_out_amount: Double?
    var payment_due_at: String?
    var payoff_balance: Double?
    var premium_amount: Double?
    var routing_number: String?
    var started_on: String?
    var subtype: MXAccountSubType?
    var total_account_value: Double?
    var type: MXAccountType
    var updated_at: String
    var user_guid: String
    var user_id: String?
    var should_link: Bool?
    var tags: [String]?
    var participantsIDs: [String]?
    var user_created: Bool?
    var admin: String?
    var badge: Int?
    var pinned: Bool?
    var muted: Bool?
    var description: String?
    var bs_type: BalanceSheetType {
        switch self.type {
        case .checking, .savings, .investment, .property, .cash, .insurance, .prepaid:
            return .Asset
        case .loan, .creditCard, .lineOfCredit, .mortgage:
            return .Liability
        case .any:
            return .None
        }
    }
    var finalBalance: Double {
        if type == .investment {
            return balance
        } else {
            return available_balance ?? balance
        }
    }
    
    init(name: String, balance: Double, created_at: String, guid: String, user_guid: String, type: MXAccountType, subtype: MXAccountSubType, user_created: Bool?, admin: String) {
        self.name = name
        self.balance = balance
        self.created_at = created_at
        self.updated_at = created_at
        self.guid = guid
        self.user_guid = user_guid
        self.type = type
        self.subtype = subtype
        self.user_created = user_created
    }
    
    func balanceGivenDate(date: Date) -> Double? {
        let isodateFormatter = ISO8601DateFormatter()
        if let balances = self.balances {
            let sortedBalances = Array(balances.keys.sorted {$0.localizedStandardCompare($1) == .orderedDescending})
            let firstBalanceDate = isodateFormatter.date(from: sortedBalances.last!)!
            if date >= firstBalanceDate {
                if let balanceDate = sortedBalances.first(where: { isodateFormatter.date(from: $0)! < date }) {
                    return balances[balanceDate] ?? 0
                }
            }
        }
            
        return nil
    }
}

extension MXAccount {
    var promptContext: String {
        var context = String()
        let numberFormatter = NumberFormatter()
        numberFormatter.currencyCode = currency_code
        numberFormatter.numberStyle = .currency
        numberFormatter.maximumFractionDigits = 0
        let percentFormatter = NumberFormatter()
        percentFormatter.numberStyle = .percent
        percentFormatter.maximumFractionDigits = 2
        
        let isodateFormatter = ISO8601DateFormatter()
        let dateFormatterPrint = DateFormatter()
        dateFormatterPrint.dateFormat = "E, MMM d, yyyy"
        
        context += "Name: \(name)"
        
        let currentBalance = finalBalance
        if let balance = numberFormatter.string(from: currentBalance as NSNumber) {
            context += ", Balance: \(balance)"
        }
        if let date = isodateFormatter.date(from: updated_at) {
            context += ", Last Updated: \(dateFormatterPrint.string(from: date))"
        }
        context += ", Type: \(type)"
        if let subtype = subtype, subtype != .none {
            context += ", Subtype: \(subtype)"
        }
        if let apr = apr, let value = percentFormatter.string(from: apr / 100 as NSNumber) {
            context += ", Annual Percentage Rate: \(value)"
        }
        if let apy = apy, let value = percentFormatter.string(from: apy / 100 as NSNumber) {
            context += ", Annual Percentage Yield: \(value)"
        }
        context += "; "
        return context
    }
}

struct UserAccount: Codable, Equatable, Hashable {
    var name: String?
    var tags: [String]?
    var should_link: Bool?
    var badge: Int?
    var pinned: Bool?
    var muted: Bool?

    init(account: MXAccount) {
        self.name = account.name
        self.tags = account.tags
        self.should_link = account.should_link
        self.badge = account.badge
        self.pinned = account.pinned
        self.muted = account.muted
    }
}

struct AccountDetails: Codable, Equatable, Hashable {
    var name: String
    var balance: Double
    var lastPeriodBalance: Double?
    var level: AccountCatLevel
    var subtype: MXAccountSubType?
    var type: MXAccountType?
    var bs_type: BalanceSheetType?
    var currencyCode: String?
    var date: Date?
    var timeSegment: TimeSegmentType?
    var admin: String?
    var participantsIDs: [String]?
}

extension AccountDetails {
    func promptContext(selectedIndex: TimeSegmentType) -> String {
        var context = String()
        let numberFormatter = NumberFormatter()
        numberFormatter.currencyCode = currencyCode
        numberFormatter.numberStyle = .currency
        numberFormatter.maximumFractionDigits = 0
        
        context += "Name: \(name)"
        
        if let amount = numberFormatter.string(from: balance as NSNumber) {
            context += ", Amount: \(amount)"
            if let balance = lastPeriodBalance, let lastPeriodAmount = numberFormatter.string(from: balance as NSNumber), let difference = numberFormatter.string(from: self.balance - balance as NSNumber) {
                switch selectedIndex {
                case .day:
                    context += ", Yesterday's Amount: \(lastPeriodAmount)"
                case .week:
                    context += ", Last Week to Date's Amount: \(lastPeriodAmount)"
                case .month:
                    context += ", Last Month to Date's Amount: \(lastPeriodAmount)"
                case .year:
                    context += ", Last Year to Date's Amount: \(lastPeriodAmount)"
                }
                context += ", Difference Amount: \(difference)"
            } else if let lastPeriodAmount = numberFormatter.string(from: 0 as NSNumber), let difference = numberFormatter.string(from: self.balance - 0 as NSNumber) {
                switch selectedIndex {
                case .day:
                    context += ", Yesterday's Amount: \(lastPeriodAmount)"
                case .week:
                    context += ", Last Week to Date's Amount: \(lastPeriodAmount)"
                case .month:
                    context += ", Last Month to Date's Amount: \(lastPeriodAmount)"
                case .year:
                    context += ", Last Year to Date's Amount: \(lastPeriodAmount)"
                }
                context += ", Difference Amount: \(difference)"
            }
        }
        context += "; "
        return context
    }
}

enum AccountCatLevel: String, Codable {
    case account
    case subtype
    case type
    case bs_type
}

func assets(accounts: [MXAccount]) -> Double {
    var assets: Double = 0.0
    for account in accounts {
        if account.bs_type == .Asset {
            assets += account.balance
        }
    }
    return assets
}

func liabilities(accounts: [MXAccount]) -> Double {
    var liabilities: Double = 0.0
    for account in accounts {
        if account.bs_type == .Liability {
            liabilities += account.balance
        }
    }
    return liabilities
}

func networth(accounts: [MXAccount]) -> Double {
    let networth = assets(accounts: accounts) - liabilities(accounts: accounts)
    return networth
}

enum BalanceSheetType: String, CaseIterable, Codable {
    case NetWorth
    case Asset
    case Liability
    case None
    
    static var allValues: [String] {
        var array = [String]()
        BalanceSheetType.allCases.forEach { bs_type in
            if bs_type != .None {
                array.append(bs_type.name)
            }
        }
        return array
    }
    
    var name: String {
        switch self {
        case .NetWorth: return "Net Worth"
        case .Asset: return "Assets"
        case .Liability: return "Liabilities"
        case .None: return "None"
        }
    }
}

enum MXAccountType: String, CaseIterable, Codable {
    case cash = "CASH"
    case checking = "CHECKING"
    case savings = "SAVINGS"
    case investment = "INVESTMENT"
    case property = "PROPERTY"
    case insurance = "INSURANCE"
    case prepaid = "PREPAID"
    case creditCard = "CREDIT_CARD"
    case mortgage = "MORTGAGE"
    case loan = "LOAN"
    case lineOfCredit = "LINE_OF_CREDIT"
    case any = "ANY"
    
    static var allValues: [String] {
        var array = [String]()
        MXAccountType.allCases.forEach { type in
            if type != .any {
                array.append(type.name)
            }
        }
        return array
    }
    
    var name: String {
        switch self {
        case .checking: return "Checking"
        case .savings: return "Savings"
        case .investment: return "Investment"
        case .property: return "Property"
        case .cash: return "Cash"
        case .insurance: return "Insurance"
        case .prepaid: return "Prepaid"
        case .loan: return "Loan"
        case .creditCard: return "Credit Card"
        case .lineOfCredit: return "Line of Credit"
        case .mortgage: return "Mortgage"
        case .any: return "Any"
        }
    }
    
    var bs_type: BalanceSheetType {
        switch self {
        case .checking: return .Asset
        case .savings: return .Asset
        case .investment: return .Asset
        case .property: return .Asset
        case .cash: return .Asset
        case .insurance: return .Asset
        case .prepaid: return .Asset
        case .loan: return .Liability
        case .creditCard: return .Liability
        case .lineOfCredit: return .Liability
        case .mortgage: return .Liability
        case .any: return .None
        }
    }
}

enum MXAccountSubType: String, CaseIterable, Codable {
    case moneyMarket = "MONEY_MARKET"
    case certificateOfDeposit = "CERTIFICATE_OF_DEPOSIT"
    case auto = "AUTO"
    case student = "STUDENT"
    case smallBusiness = "SMALL_BUSINESS"
    case personal = "PERSONAL"
    case personalWithCollateral = "PERSONAL_WITH_COLLATERAL"
    case homeEquity = "HOME_EQUITY"
    case plan401K = "PLAN_401_K"
    case plan403B = "PLAN_403_B"
    case plan529 = "PLAN_529"
    case ira = "IRA"
    case rolloverIra = "ROLLOVER_IRA"
    case rothIra = "ROTH_IRA"
    case taxable = "TAXABLE"
    case nonTaxable = "NON_TAXABLE"
    case brokerage = "BROKERAGE"
    case trust = "TRUST"
    case uniformGiftsToMinorsAct = "UNIFORM_GIFTS_TO_MINORS_ACT"
    case plan457 = "PLAN_457"
    case pension = "PENSION"
    case employeeStockOwnershipPlan = "EMPLOYEE_STOCK_OWNERSHIP_PLAN"
    case simplifiedEmployeePension = "SIMPLIFIED_EMPLOYEE_PENSION"
    case simpleIra = "SIMPLE_IRA"
    case boat = "BOAT"
    case powersports = "POWERSPORTS"
    case rv = "RV"
    case heloc = "HELOC"
    case planRoth401k = "PLAN_ROTH_401_K"
    case fixedAnnuity = "FIXED_ANNUITY"
    case variableAnnuity = "VARIABLE_ANNUITY"
    case vehicleInsurance = "VEHICLE_INSURANCE"
    case disability = "DISABILITY"
    case health = "HEALTH"
    case longTermCare = "LONG_TERM_CARE"
    case propertyAndCasualty = "PROPERTY_AND_CASUALTY"
    case universalLife = "UNIVERSAL_LIFE"
    case termLife = "TERM_LIFE"
    case wholeLife = "WHOLE_LIFE"
    case accidentalDeathAndDismemberment = "ACCIDENTAL_DEATH_AND_DISMEMBERMENT"
    case variableUniversalLife = "VARIABLE_UNIVERSAL_LIFE"
    case hsa = "HSA"
    case taxFreeSavingsAccount = "TAX_FREE_SAVINGS_ACCOUNT"
    case individual = "INDIVIDUAL"
    case registeredRetirementIncomeFund = "REGISTERED_RETIREMENT_INCOME_FUND"
    case cashManagementAccount = "CASH_MANAGEMENT_ACCOUNT"
    case employeeStockPurchasePlan = "EMPLOYEE_STOCK_PURCHASE_PLAN"
    case registeredEducationSavingsPlan = "REGISTERED_EDUCATION_SAVINGS_PLAN"
    case profitSharingPlan = "PROFIT_SHARING_PLAN"
    case uniformTransferToMinorsAct = "UNIFORM_TRANSFER_TO_MINORS_ACT"
    case plan401A = "PLAN_401_A"
    case sarsepIra = "SARSEP_IRA"
    case fixedAnnuityTraditionalIra = "FIXED_ANNUITY_TRADITIONAL_IRA"
    case variableAnnuityTraditionalIra = "VARIABLE_ANNUITY_TRADITIONAL_IRA"
    case seppIra = "SEPP_IRA"
    case inheritedTraditionalIra = "INHERITED_TRADITIONAL_IRA"
    case fixedAnnuityRothIra = "FIXED_ANNUITY_ROTH_IRA"
    case variableAnnuityRothIra = "VARIABLE_ANNUITY_ROTH_IRA"
    case inheritedRothIra = "INHERITED_ROTH_IRA"
    case coverdell = "COVERDELL"
    case advisoryAccount = "ADVISORY_ACCOUNT"
    case brokerageMargin = "BROKERAGE_MARGIN"
    case charitableGiftAccount = "CHARITABLE_GIFT_ACCOUNT"
    case churchAccount = "CHURCH_ACCOUNT"
    case conservatorship = "CONSERVATORSHIP"
    case custodial = "CUSTODIAL"
    case definedBenefitPlan = "DEFINED_BENEFIT_PLAN"
    case definedContributionPlan = "DEFINED_CONTRIBUTION_PLAN"
    case educational = "EDUCATIONAL"
    case estate = "ESTATE"
    case executor = "EXECUTOR"
    case groupRetirementSavingsPlan = "GROUP_RETIREMENT_SAVINGS_PLAN"
    case guaranteedInvestmentCertificate = "GUARANTEED_INVESTMENT_CERTIFICATE"
    case hra = "HRA"
    case indexedAnnuity = "INDEXED_ANNUITY"
    case investmentClub = "INVESTMENT_CLUB"
    case irrevocableTrust = "IRREVOCABLE_TRUST"
    case jointTenantsByEntirety = "JOINT_TENANTS_BY_ENTIRITY"
    case jointTenantsCommunityProperty = "JOINT_TENANTS_COMMUNITY_PROPERTY"
    case jointTenantsInCommon = "JOINT_TENANTS_IN_COMMON"
    case jointTenantsWithRightsOfSuvivorship = "JOINT_TENANTS_WITH_RIGHTS_OF_SURVIVORSHIP"
    case keoughPlan = "KEOUGH_PLAN"
    case lifeIncomeFund = "LIFE_INCOME_FUND"
    case livingTrust = "LIVING_TRUST"
    case lockedInRetirementAccount = "LOCKED_IN_RETIREMENT_ACCOUNT"
    case lockedInRetirementInvestmentFund = "LOCKED_IN_RETIREMENT_INVESTMENT_FUND"
    case lockedInRetirementSavingsAccount = "LOCKED_IN_RETIREMENT_SAVINGS_ACCOUNT"
    case moneyPurchasePlan = "MONEY_PURCHASE_PLAN"
    case partnership = "PARTNERSHIP"
    case plan409A = "PLAN_409_A"
    case plan409B = "PLAN_ROTH_403_B"
    case registeredDisabilitySavingsPlan = "REGISTERED_DISABILITY_SAVINGS_PLAN"
    case registeredLockedInSavingsPlan = "REGISTERED_LOCKED_IN_SAVINGS_PLAN"
    case registeredPensionPlan = "REGISTERED_PENSION_PLAN"
    case registeredRetirementSavingsPlan = "REGISTERED_RETIREMENT_SAVINGS_PLAN"
    case revocableTrust = "REVOCABLE_TRUST"
    case rothConversion = "ROTH_CONVERSION"
    case soleProprietorship = "SOLE_PROPRIETORSHIP"
    case spousalIra = "SPOUSAL_IRA"
    case spousalRothIra = "SPOUSAL_ROTH_IRA"
    case testamentaryTrust = "TESTAMENTARY_TRUST"
    case thriftSavingsPlan = "THRIFT_SAVINGS_PLAN"
    case inheritedAnnuity = "INHERITED_ANNUITY"
    case corporateAccount = "CORPORATE_ACCOUNT"
    case limitedLiabilityAccount = "LIMITED_LIABILITY_ACCOUNT"
    case none = "NONE"
    case any = "ANY"
    
    static var allValues: [String] {
        var array = [String]()
        MXAccountSubType.allCases.forEach { subtype in
            if subtype != .none && subtype != .any {
                array.append(subtype.name)
            }
        }
        return array
    }
    
    var name: String {
        switch self {
        case .moneyMarket: return "Money Market"
        case .certificateOfDeposit: return "Certificate of Deposit"
        case .auto: return "Auto"
        case .student: return "Student"
        case .smallBusiness: return "Small Business"
        case .personal: return "Personal"
        case .personalWithCollateral: return "Personal with Collateral"
        case .homeEquity: return "Home Equity"
        case .plan401K: return "Plan 401K"
        case .plan403B: return "Plan 403B"
        case .plan529: return "Plan 529"
        case .ira: return "IRA"
        case .rolloverIra: return "Rollover IRA"
        case .rothIra: return "Roth IRA"
        case .taxable: return "Taxable"
        case .nonTaxable: return "Non-Taxable"
        case .brokerage: return "Brokerage"
        case .trust: return "Trust"
        case .uniformGiftsToMinorsAct: return "Uniform Gifts to Minors Act"
        case .plan457: return "Plan 457"
        case .pension: return "Pension"
        case .employeeStockOwnershipPlan: return "Employee Stock Ownership Plan"
        case .simplifiedEmployeePension: return "Simplified Employee Pension"
        case .simpleIra: return "Simple IRA"
        case .boat: return "Boat"
        case .powersports: return "Powersports"
        case .rv: return "RV"
        case .heloc: return "HELOC"
        case .planRoth401k: return "Plan Roth 401K"
        case .fixedAnnuity: return "Fixed Annuity"
        case .variableAnnuity: return "Variable Annuity"
        case .vehicleInsurance: return "Vehicle Insurance"
        case .disability: return "Disability"
        case .health: return "Health"
        case .longTermCare: return "Long Term Care"
        case .propertyAndCasualty: return "Property and Casualty"
        case .universalLife: return "Universal Life"
        case .termLife: return "Term Life"
        case .wholeLife: return "Whole Life"
        case .accidentalDeathAndDismemberment: return "Accidental Death and Dismemberment"
        case .variableUniversalLife: return "Variable Universal Life"
        case .hsa: return "HSA"
        case .taxFreeSavingsAccount: return "Tax Free Savings Account"
        case .individual: return "Individual"
        case .registeredRetirementIncomeFund: return "Registered Retirement Income Fund"
        case .cashManagementAccount: return "Cash Management Account"
        case .employeeStockPurchasePlan: return "Employee Stock Purchase Plan"
        case .registeredEducationSavingsPlan: return "Registered Education Savings Plan"
        case .profitSharingPlan: return "Profit Sharing Plan"
        case .uniformTransferToMinorsAct: return "Uniform Transfer to Minors Act"
        case .plan401A: return "Plan 401A"
        case .sarsepIra: return "SARSEP IRA"
        case .fixedAnnuityTraditionalIra: return "Fixed Annuity Traditional IRA"
        case .variableAnnuityTraditionalIra: return "Variable Annuity Traditional IRA"
        case .seppIra: return "SEPP IRA"
        case .inheritedTraditionalIra: return "Inherited Traditional IRA"
        case .fixedAnnuityRothIra: return "Fixed Annuity Roth IRA"
        case .variableAnnuityRothIra: return "Variable Annuity Roth IRA"
        case .inheritedRothIra: return "Inherited Roth IRA"
        case .coverdell: return "Coverdell"
        case .advisoryAccount: return "Advisory Account"
        case .brokerageMargin: return "Brokerage Margin"
        case .charitableGiftAccount: return "Charitable Gift Account"
        case .churchAccount: return "Church Account"
        case .conservatorship: return "Conservatorship"
        case .custodial: return "Custodial"
        case .definedBenefitPlan: return "Defined Benefit Plan"
        case .definedContributionPlan: return "Defined Contribution Plan"
        case .educational: return "Educational"
        case .estate: return "Estate"
        case .executor: return "Executor"
        case .groupRetirementSavingsPlan: return "Group Retirement Savings Plan"
        case .guaranteedInvestmentCertificate: return "Guaranteed Investment Certificate"
        case .hra: return "HRA"
        case .indexedAnnuity: return "Indexed Annuity"
        case .investmentClub: return "Investment Club"
        case .irrevocableTrust: return "Irrevocable Trust"
        case .jointTenantsByEntirety: return "Joint Tenants by Entirety"
        case .jointTenantsCommunityProperty: return "Joint Tenants Community Property"
        case .jointTenantsInCommon: return "Joint Tenants in Common"
        case .jointTenantsWithRightsOfSuvivorship: return "Joint Tenants with Rights of Survivorship"
        case .keoughPlan: return "Keough Plan"
        case .lifeIncomeFund: return "Life Income Fund"
        case .livingTrust: return "Living Trust"
        case .lockedInRetirementAccount: return "Locked in Retirement Account"
        case .lockedInRetirementInvestmentFund: return "Locked in Retirement Investment Fund"
        case .lockedInRetirementSavingsAccount: return "Locked in Retirement Savings Account"
        case .moneyPurchasePlan: return "Money Purchase Plan"
        case .partnership: return "Partnership"
        case .plan409A: return "Plan 409A"
        case .plan409B: return "Plan Roth 409B"
        case .registeredDisabilitySavingsPlan: return "Registered Disability Savings Plan"
        case .registeredLockedInSavingsPlan: return "Registered Locked in Savings Plan"
        case .registeredPensionPlan: return "Registered Pension Plan"
        case .registeredRetirementSavingsPlan: return "Registered Retirement Savings Plan"
        case .revocableTrust: return "Revocable Trust"
        case .rothConversion: return "Roth Conversion"
        case .soleProprietorship: return "Sole Proprietorship"
        case .spousalIra: return "Spousal IRA"
        case .spousalRothIra: return "Spousal Roth IRA"
        case .testamentaryTrust: return "Testamentary Trust"
        case .thriftSavingsPlan: return "Thrift Savings Plan"
        case .inheritedAnnuity: return "Inherited Annuity"
        case .corporateAccount: return "Corporate Account"
        case .limitedLiabilityAccount: return "Limited Liability Account"
        case .none: return "None"
        case .any: return "Any"
        }
    }
    
    var mxAccountType: MXAccountType {
        switch self {
        case .moneyMarket: return .savings
        case .certificateOfDeposit: return .savings
        case .auto: return .loan
        case .student: return .loan
        case .smallBusiness: return .loan
        case .personal: return .loan
        case .personalWithCollateral: return .loan
        case .homeEquity: return .loan
        case .plan401K: return .investment
        case .plan403B: return .investment
        case .plan529: return .investment
        case .ira: return .investment
        case .rolloverIra: return .investment
        case .rothIra: return .investment
        case .taxable: return .investment
        case .nonTaxable: return .investment
        case .brokerage: return .investment
        case .trust: return .investment
        case .uniformGiftsToMinorsAct: return .investment
        case .plan457: return .investment
        case .pension: return .investment
        case .employeeStockOwnershipPlan: return .investment
        case .simplifiedEmployeePension: return .investment
        case .simpleIra: return .investment
        case .boat: return .loan
        case .powersports: return .loan
        case .rv: return .loan
        case .heloc: return .loan
        case .planRoth401k: return .investment
        case .fixedAnnuity: return .investment
        case .variableAnnuity: return .investment
        case .vehicleInsurance: return .insurance
        case .disability: return .insurance
        case .health: return .insurance
        case .longTermCare: return .insurance
        case .propertyAndCasualty: return .insurance
        case .universalLife: return .insurance
        case .termLife: return .insurance
        case .wholeLife: return .insurance
        case .accidentalDeathAndDismemberment: return .insurance
        case .variableUniversalLife: return .insurance
        case .hsa: return .investment
        case .taxFreeSavingsAccount: return .investment
        case .individual: return .investment
        case .registeredRetirementIncomeFund: return .investment
        case .cashManagementAccount: return .investment
        case .employeeStockPurchasePlan: return .investment
        case .registeredEducationSavingsPlan: return .investment
        case .profitSharingPlan: return .investment
        case .uniformTransferToMinorsAct: return .investment
        case .plan401A: return .investment
        case .sarsepIra: return .investment
        case .fixedAnnuityTraditionalIra: return .investment
        case .variableAnnuityTraditionalIra: return .investment
        case .seppIra: return .investment
        case .inheritedTraditionalIra: return .investment
        case .fixedAnnuityRothIra: return .investment
        case .variableAnnuityRothIra: return .investment
        case .inheritedRothIra: return .investment
        case .coverdell: return .investment
        case .advisoryAccount: return .investment
        case .brokerageMargin: return .investment
        case .charitableGiftAccount: return .investment
        case .churchAccount: return .investment
        case .conservatorship: return .investment
        case .custodial: return .investment
        case .definedBenefitPlan: return .investment
        case .definedContributionPlan: return .investment
        case .educational: return .investment
        case .estate: return .investment
        case .executor: return .investment
        case .groupRetirementSavingsPlan: return .investment
        case .guaranteedInvestmentCertificate: return .investment
        case .hra: return .investment
        case .indexedAnnuity: return .investment
        case .investmentClub: return .investment
        case .irrevocableTrust: return .investment
        case .jointTenantsByEntirety: return .investment
        case .jointTenantsCommunityProperty: return .investment
        case .jointTenantsInCommon: return .investment
        case .jointTenantsWithRightsOfSuvivorship: return .investment
        case .keoughPlan: return .investment
        case .lifeIncomeFund: return .investment
        case .livingTrust: return .investment
        case .lockedInRetirementAccount: return .investment
        case .lockedInRetirementInvestmentFund: return .investment
        case .lockedInRetirementSavingsAccount: return .investment
        case .moneyPurchasePlan: return .investment
        case .partnership: return .investment
        case .plan409A: return .investment
        case .plan409B: return .investment
        case .registeredDisabilitySavingsPlan: return .investment
        case .registeredLockedInSavingsPlan: return .investment
        case .registeredPensionPlan: return .investment
        case .registeredRetirementSavingsPlan: return .investment
        case .revocableTrust: return .investment
        case .rothConversion: return .investment
        case .soleProprietorship: return .investment
        case .spousalIra: return .investment
        case .spousalRothIra: return .investment
        case .testamentaryTrust: return .investment
        case .thriftSavingsPlan: return .investment
        case .inheritedAnnuity: return .investment
        case .corporateAccount: return .investment
        case .limitedLiabilityAccount: return .investment
        case .none: return .any
        case .any: return .any
        }
    }
    
    var bs_type: BalanceSheetType {
        return self.mxAccountType.bs_type
    }
}

func categorizeAccounts(accounts: [MXAccount], timeSegment: TimeSegmentType, level: AccountCatLevel?, accountDetails: [AccountDetails]?, date: Date?, completion: @escaping ([AccountDetails], [AccountDetails: [MXAccount]]) -> ()) {
    var accountsList = [AccountDetails]()
    var accountsDict = [AccountDetails: [MXAccount]]()
    for account in accounts {
        var finalDate = Date().localTime.dayAfter
        var balance = 0.0
        guard account.should_link ?? true else { continue }
        if let date = date {
            finalDate = date
        }
        if let balanceGivenDate = account.balanceGivenDate(date: finalDate) {
            balance = balanceGivenDate
        } else {
            continue
        }
        if let accountDetails = accountDetails {
            for accountDetail in accountDetails {
                if accountDetail.name == "Net Worth" {
                    if account.bs_type == .Asset {
                        if let index = accountsDict.keys.firstIndex(where: {$0.name == account.bs_type.name && $0.level == .bs_type && $0.bs_type == account.bs_type}) {
                            var accountDetail = accountsDict.keys[index]
                            var accounts = accountsDict[accountDetail]
                            
                            accountsDict[accountDetail] = nil

                            accountDetail.balance += balance
                            
                            accounts!.append(account)
                            accountsDict[accountDetail] = accounts
                        } else {
                            let accountDetail = AccountDetails(name: account.bs_type.name, balance: balance, level: .bs_type, subtype: nil, type: nil, bs_type: account.bs_type, currencyCode: account.currency_code ?? "USD")
                            accountsDict[accountDetail] = [account]
                        }
                    } else if account.bs_type == .Liability {
                        if let index = accountsDict.keys.firstIndex(where: {$0.name == account.bs_type.name && $0.level == .bs_type && $0.bs_type == account.bs_type}) {
                            var accountDetail = accountsDict.keys[index]
                            var accounts = accountsDict[accountDetail]
                            
                            accountsDict[accountDetail] = nil

                            accountDetail.balance -= balance
                            
                            accounts!.append(account)
                            accountsDict[accountDetail] = accounts
                        } else {
                            let accountDetail = AccountDetails(name: account.bs_type.name, balance: -balance, level: .bs_type, subtype: nil, type: nil, bs_type: account.bs_type, currencyCode: account.currency_code ?? "USD")
                            accountsDict[accountDetail] = [account]
                        }
                    }
                } else if accountDetail.name == account.name && accountDetail.level == .account {
                    let accountDetail = AccountDetails(name: account.name, balance: balance, level: .account, subtype: account.subtype ?? MXAccountSubType.none, type: account.type, bs_type: account.bs_type, currencyCode: account.currency_code ?? "USD")
                    accountsDict[accountDetail] = [account]
                } else if accountDetail.name == account.subtype?.name ?? MXAccountSubType.none.name && accountDetail.level == .subtype {
                    if let index = accountsDict.keys.firstIndex(where: {$0.name == account.subtype?.name ?? MXAccountSubType.none.name && $0.level == .subtype && $0.subtype == account.subtype ?? MXAccountSubType.none && $0.type == account.type && $0.bs_type == account.bs_type}) {
                        var accountDetail = accountsDict.keys[index]
                        var accounts = accountsDict[accountDetail]
                        
                        accountsDict[accountDetail] = nil
                        
                        accountDetail.balance += balance
                        accounts!.append(account)
                        
                        accountsDict[accountDetail] = accounts
                    } else {
                        let accountDetail = AccountDetails(name: account.subtype?.name ?? MXAccountSubType.none.name, balance: balance, level: .subtype, subtype: account.subtype ?? MXAccountSubType.none, type: account.type, bs_type: account.bs_type, currencyCode: account.currency_code ?? "USD")
                        accountsDict[accountDetail] = [account]
                    }
                } else if accountDetail.name == account.type.name && accountDetail.level == .type {
                    if let index = accountsDict.keys.firstIndex(where: {$0.name == account.type.name && $0.level == .type && $0.type == account.type && $0.bs_type == account.bs_type}) {
                        var accountDetail = accountsDict.keys[index]
                        var accounts = accountsDict[accountDetail]
                        
                        accountsDict[accountDetail] = nil
                        
                        accountDetail.balance += balance
                        accounts!.append(account)
                        
                        accountsDict[accountDetail] = accounts
                    } else {
                        let accountDetail = AccountDetails(name: account.type.name, balance: balance, level: .type, subtype: nil, type: account.type, bs_type: account.bs_type, currencyCode: account.currency_code ?? "USD")
                        accountsDict[accountDetail] = [account]
                    }
                } else if accountDetail.name == account.bs_type.name && accountDetail.level == .bs_type {
                    if let index = accountsDict.keys.firstIndex(where: {$0.name == account.bs_type.name && $0.level == .bs_type && $0.bs_type == account.bs_type}) {
                        var accountDetail = accountsDict.keys[index]
                        var accounts = accountsDict[accountDetail]
                        
                        accountsDict[accountDetail] = nil

                        accountDetail.balance += balance
                        
                        accounts!.append(account)
                        accountsDict[accountDetail] = accounts
                    } else {
                        let accountDetail = AccountDetails(name: account.bs_type.name, balance: balance, level: .bs_type, subtype: nil, type: nil, bs_type: account.bs_type, currencyCode: account.currency_code ?? "USD")
                        accountsDict[accountDetail] = [account]
                    }
                }
            }
        } else {
            switch level {
            case .account:
                var accountDetail = AccountDetails(name: account.name, balance: balance, level: .account, subtype: account.subtype ?? MXAccountSubType.none, type: account.type, bs_type: account.bs_type, currencyCode: account.currency_code ?? "USD")
                switch timeSegment {
                case .day:
                    let oldDate = finalDate.dayBefore
                    if let oldBalance = account.balanceGivenDate(date: oldDate) {
                        accountDetail.lastPeriodBalance = oldBalance
                    }
                case .week:
                    let oldDate = finalDate.weekBefore
                    if let oldBalance = account.balanceGivenDate(date: oldDate) {
                        accountDetail.lastPeriodBalance = oldBalance
                    }
                case .month:
                    let oldDate = finalDate.monthBefore
                    if let oldBalance = account.balanceGivenDate(date: oldDate) {
                        accountDetail.lastPeriodBalance = oldBalance
                    }
                case .year:
                    let oldDate = finalDate.lastYear
                    if let oldBalance = account.balanceGivenDate(date: oldDate) {
                        accountDetail.lastPeriodBalance = oldBalance
                    }
                }
                accountsDict[accountDetail] = [account]
            case .subtype:
                if let index = accountsDict.keys.firstIndex(where: {$0.name == account.subtype?.name ?? MXAccountSubType.none.name && $0.level == .subtype && $0.subtype == account.subtype ?? MXAccountSubType.none && $0.type == account.type && $0.bs_type == account.bs_type}) {
                    var accountDetail = accountsDict.keys[index]
                    var accounts = accountsDict[accountDetail]
                    
                    accountsDict[accountDetail] = nil
                    
                    accountDetail.balance += balance
                    switch timeSegment {
                    case .day:
                        let oldDate = finalDate.dayBefore
                        if let oldBalance = account.balanceGivenDate(date: oldDate) {
                            if accountDetail.lastPeriodBalance != nil {
                                accountDetail.lastPeriodBalance! += oldBalance
                            } else {
                                accountDetail.lastPeriodBalance = oldBalance
                            }
                        }
                    case .week:
                        let oldDate = finalDate.weekBefore
                        if let oldBalance = account.balanceGivenDate(date: oldDate) {
                            if accountDetail.lastPeriodBalance != nil {
                                accountDetail.lastPeriodBalance! += oldBalance
                            } else {
                                accountDetail.lastPeriodBalance = oldBalance
                            }
                        }
                    case .month:
                        let oldDate = finalDate.monthBefore
                        if let oldBalance = account.balanceGivenDate(date: oldDate) {
                            if accountDetail.lastPeriodBalance != nil {
                                accountDetail.lastPeriodBalance! += oldBalance
                            } else {
                                accountDetail.lastPeriodBalance = oldBalance
                            }
                        }
                    case .year:
                        let oldDate = finalDate.lastYear
                        if let oldBalance = account.balanceGivenDate(date: oldDate) {
                            if accountDetail.lastPeriodBalance != nil {
                                accountDetail.lastPeriodBalance! += oldBalance
                            } else {
                                accountDetail.lastPeriodBalance = oldBalance
                            }
                        }
                    }
                    accounts!.append(account)
                    
                    accountsDict[accountDetail] = accounts
                } else {
                    var accountDetail = AccountDetails(name: account.subtype?.name ?? MXAccountSubType.none.name, balance: balance, level: .subtype, subtype: account.subtype ?? MXAccountSubType.none, type: account.type, bs_type: account.bs_type, currencyCode: account.currency_code ?? "USD")
                    switch timeSegment {
                    case .day:
                        let oldDate = finalDate.dayBefore
                        if let oldBalance = account.balanceGivenDate(date: oldDate) {
                            accountDetail.lastPeriodBalance = oldBalance
                        }
                    case .week:
                        let oldDate = finalDate.weekBefore
                        if let oldBalance = account.balanceGivenDate(date: oldDate) {
                            accountDetail.lastPeriodBalance = oldBalance
                        }
                    case .month:
                        let oldDate = finalDate.monthBefore
                        if let oldBalance = account.balanceGivenDate(date: oldDate) {
                            accountDetail.lastPeriodBalance = oldBalance
                        }
                    case .year:
                        let oldDate = finalDate.lastYear
                        if let oldBalance = account.balanceGivenDate(date: oldDate) {
                            accountDetail.lastPeriodBalance = oldBalance
                        }
                    }
                    accountsDict[accountDetail] = [account]
                }
            case .type:
                if let index = accountsDict.keys.firstIndex(where: {$0.name == account.type.name && $0.level == .type && $0.type == account.type && $0.bs_type == account.bs_type}) {
                    var accountDetail = accountsDict.keys[index]
                    var accounts = accountsDict[accountDetail]
                    
                    accountsDict[accountDetail] = nil
                    
                    accountDetail.balance += balance
                    switch timeSegment {
                    case .day:
                        let oldDate = finalDate.dayBefore
                        if let oldBalance = account.balanceGivenDate(date: oldDate) {
                            if accountDetail.lastPeriodBalance != nil {
                                accountDetail.lastPeriodBalance! += oldBalance
                            } else {
                                accountDetail.lastPeriodBalance = oldBalance
                            }
                        }
                    case .week:
                        let oldDate = finalDate.weekBefore
                        if let oldBalance = account.balanceGivenDate(date: oldDate) {
                            if accountDetail.lastPeriodBalance != nil {
                                accountDetail.lastPeriodBalance! += oldBalance
                            } else {
                                accountDetail.lastPeriodBalance = oldBalance
                            }
                        }
                    case .month:
                        let oldDate = finalDate.monthBefore
                        if let oldBalance = account.balanceGivenDate(date: oldDate) {
                            if accountDetail.lastPeriodBalance != nil {
                                accountDetail.lastPeriodBalance! += oldBalance
                            } else {
                                accountDetail.lastPeriodBalance = oldBalance
                            }
                        }
                    case .year:
                        let oldDate = finalDate.lastYear
                        if let oldBalance = account.balanceGivenDate(date: oldDate) {
                            if accountDetail.lastPeriodBalance != nil {
                                accountDetail.lastPeriodBalance! += oldBalance
                            } else {
                                accountDetail.lastPeriodBalance = oldBalance
                            }
                        }
                    }
                    
                    accounts!.append(account)
                    
                    accountsDict[accountDetail] = accounts
                } else {
                    var accountDetail = AccountDetails(name: account.type.name, balance: balance, level: .type, subtype: nil, type: account.type, bs_type: account.bs_type, currencyCode: account.currency_code ?? "USD")
                    switch timeSegment {
                    case .day:
                        let oldDate = finalDate.dayBefore
                        if let oldBalance = account.balanceGivenDate(date: oldDate) {
                            accountDetail.lastPeriodBalance = oldBalance
                        }
                    case .week:
                        let oldDate = finalDate.weekBefore
                        if let oldBalance = account.balanceGivenDate(date: oldDate) {
                            accountDetail.lastPeriodBalance = oldBalance
                        }
                    case .month:
                        let oldDate = finalDate.monthBefore
                        if let oldBalance = account.balanceGivenDate(date: oldDate) {
                            accountDetail.lastPeriodBalance = oldBalance
                        }
                    case .year:
                        let oldDate = finalDate.lastYear
                        if let oldBalance = account.balanceGivenDate(date: oldDate) {
                            accountDetail.lastPeriodBalance = oldBalance
                        }
                    }
                    
                    accountsDict[accountDetail] = [account]
                }
            case .bs_type:
                if let index = accountsDict.keys.firstIndex(where: {$0.name == account.bs_type.name && $0.level == .bs_type && $0.bs_type == account.bs_type}) {
                    var accountDetail = accountsDict.keys[index]
                    var accounts = accountsDict[accountDetail]
                    
                    accountsDict[accountDetail] = nil

                    accountDetail.balance += balance
                    
                    switch timeSegment {
                    case .day:
                        let oldDate = finalDate.dayBefore
                        if let oldBalance = account.balanceGivenDate(date: oldDate) {
                            if accountDetail.lastPeriodBalance != nil {
                                accountDetail.lastPeriodBalance! += oldBalance
                            } else {
                                accountDetail.lastPeriodBalance = oldBalance
                            }
                        }
                    case .week:
                        let oldDate = finalDate.weekBefore
                        if let oldBalance = account.balanceGivenDate(date: oldDate) {
                            if accountDetail.lastPeriodBalance != nil {
                                accountDetail.lastPeriodBalance! += oldBalance
                            } else {
                                accountDetail.lastPeriodBalance = oldBalance
                            }
                        }
                    case .month:
                        let oldDate = finalDate.monthBefore
                        if let oldBalance = account.balanceGivenDate(date: oldDate) {
                            if accountDetail.lastPeriodBalance != nil {
                                accountDetail.lastPeriodBalance! += oldBalance
                            } else {
                                accountDetail.lastPeriodBalance = oldBalance
                            }
                        }
                    case .year:
                        let oldDate = finalDate.lastYear
                        if let oldBalance = account.balanceGivenDate(date: oldDate) {
                            if accountDetail.lastPeriodBalance != nil {
                                accountDetail.lastPeriodBalance! += oldBalance
                            } else {
                                accountDetail.lastPeriodBalance = oldBalance
                            }
                        }
                    }
                    accounts!.append(account)
                    accountsDict[accountDetail] = accounts
                } else {
                    var accountDetail = AccountDetails(name: account.bs_type.name, balance: balance, level: .bs_type, subtype: nil, type: nil, bs_type: account.bs_type, currencyCode: account.currency_code ?? "USD")
                    switch timeSegment {
                    case .day:
                        let oldDate = finalDate.dayBefore
                        if let oldBalance = account.balanceGivenDate(date: oldDate) {
                            accountDetail.lastPeriodBalance = oldBalance
                        }
                    case .week:
                        let oldDate = finalDate.weekBefore
                        if let oldBalance = account.balanceGivenDate(date: oldDate) {
                            accountDetail.lastPeriodBalance = oldBalance
                        }
                    case .month:
                        let oldDate = finalDate.monthBefore
                        if let oldBalance = account.balanceGivenDate(date: oldDate) {
                            accountDetail.lastPeriodBalance = oldBalance
                        }
                    case .year:
                        let oldDate = finalDate.lastYear
                        if let oldBalance = account.balanceGivenDate(date: oldDate) {
                            accountDetail.lastPeriodBalance = oldBalance
                        }
                    }
                    accountsDict[accountDetail] = [account]
                }
            case .none:
                var accountDetail = AccountDetails(name: account.name, balance: balance, level: .account, subtype: account.subtype ?? MXAccountSubType.none, type: account.type, bs_type: account.bs_type, currencyCode: account.currency_code ?? "USD")
                accountsDict[accountDetail] = [account]
                
                switch timeSegment {
                case .day:
                    let oldDate = finalDate.dayBefore
                    if let oldBalance = account.balanceGivenDate(date: oldDate) {
                        accountDetail.lastPeriodBalance = oldBalance
                    }
                case .week:
                    let oldDate = finalDate.weekBefore
                    if let oldBalance = account.balanceGivenDate(date: oldDate) {
                        accountDetail.lastPeriodBalance = oldBalance
                    }
                case .month:
                    let oldDate = finalDate.monthBefore
                    if let oldBalance = account.balanceGivenDate(date: oldDate) {
                        accountDetail.lastPeriodBalance = oldBalance
                    }
                case .year:
                    let oldDate = finalDate.lastYear
                    if let oldBalance = account.balanceGivenDate(date: oldDate) {
                        accountDetail.lastPeriodBalance = oldBalance
                    }
                }
                
                if let index = accountsDict.keys.firstIndex(where: {$0.name == account.subtype?.name ?? MXAccountSubType.none.name && $0.level == .subtype && $0.subtype == account.subtype ?? MXAccountSubType.none && $0.type == account.type && $0.bs_type == account.bs_type}) {
                    var accountDetail = accountsDict.keys[index]
                    var accounts = accountsDict[accountDetail]
                    
                    accountsDict[accountDetail] = nil
                    
                    accountDetail.balance += balance
                    switch timeSegment {
                    case .day:
                        let oldDate = finalDate.dayBefore
                        if let oldBalance = account.balanceGivenDate(date: oldDate) {
                            if accountDetail.lastPeriodBalance != nil {
                                accountDetail.lastPeriodBalance! += oldBalance
                            } else {
                                accountDetail.lastPeriodBalance = oldBalance
                            }
                        }
                    case .week:
                        let oldDate = finalDate.weekBefore
                        if let oldBalance = account.balanceGivenDate(date: oldDate) {
                            if accountDetail.lastPeriodBalance != nil {
                                accountDetail.lastPeriodBalance! += oldBalance
                            } else {
                                accountDetail.lastPeriodBalance = oldBalance
                            }
                        }
                    case .month:
                        let oldDate = finalDate.monthBefore
                        if let oldBalance = account.balanceGivenDate(date: oldDate) {
                            if accountDetail.lastPeriodBalance != nil {
                                accountDetail.lastPeriodBalance! += oldBalance
                            } else {
                                accountDetail.lastPeriodBalance = oldBalance
                            }
                        }
                    case .year:
                        let oldDate = finalDate.lastYear
                        if let oldBalance = account.balanceGivenDate(date: oldDate) {
                            if accountDetail.lastPeriodBalance != nil {
                                accountDetail.lastPeriodBalance! += oldBalance
                            } else {
                                accountDetail.lastPeriodBalance = oldBalance
                            }
                        }
                    }
                    accounts!.append(account)
                    
                    accountsDict[accountDetail] = accounts
                } else {
                    var accountDetail = AccountDetails(name: account.subtype?.name ?? MXAccountSubType.none.name, balance: balance, level: .subtype, subtype: account.subtype ?? MXAccountSubType.none, type: account.type, bs_type: account.bs_type, currencyCode: account.currency_code ?? "USD")
                    switch timeSegment {
                    case .day:
                        let oldDate = finalDate.dayBefore
                        if let oldBalance = account.balanceGivenDate(date: oldDate) {
                            accountDetail.lastPeriodBalance = oldBalance
                        }
                    case .week:
                        let oldDate = finalDate.weekBefore
                        if let oldBalance = account.balanceGivenDate(date: oldDate) {
                            accountDetail.lastPeriodBalance = oldBalance
                        }
                    case .month:
                        let oldDate = finalDate.monthBefore
                        if let oldBalance = account.balanceGivenDate(date: oldDate) {
                            accountDetail.lastPeriodBalance = oldBalance
                        }
                    case .year:
                        let oldDate = finalDate.lastYear
                        if let oldBalance = account.balanceGivenDate(date: oldDate) {
                            accountDetail.lastPeriodBalance = oldBalance
                        }
                    }
                    accountsDict[accountDetail] = [account]
                }
                
                if let index = accountsDict.keys.firstIndex(where: {$0.name == account.type.name && $0.level == .type && $0.type == account.type && $0.bs_type == account.bs_type}) {
                    var accountDetail = accountsDict.keys[index]
                    var accounts = accountsDict[accountDetail]
                    
                    accountsDict[accountDetail] = nil
                    
                    accountDetail.balance += balance
                    switch timeSegment {
                    case .day:
                        let oldDate = finalDate.dayBefore
                        if let oldBalance = account.balanceGivenDate(date: oldDate) {
                            if accountDetail.lastPeriodBalance != nil {
                                accountDetail.lastPeriodBalance! += oldBalance
                            } else {
                                accountDetail.lastPeriodBalance = oldBalance
                            }
                        }
                    case .week:
                        let oldDate = finalDate.weekBefore
                        if let oldBalance = account.balanceGivenDate(date: oldDate) {
                            if accountDetail.lastPeriodBalance != nil {
                                accountDetail.lastPeriodBalance! += oldBalance
                            } else {
                                accountDetail.lastPeriodBalance = oldBalance
                            }
                        }
                    case .month:
                        let oldDate = finalDate.monthBefore
                        if let oldBalance = account.balanceGivenDate(date: oldDate) {
                            if accountDetail.lastPeriodBalance != nil {
                                accountDetail.lastPeriodBalance! += oldBalance
                            } else {
                                accountDetail.lastPeriodBalance = oldBalance
                            }
                        }
                    case .year:
                        let oldDate = finalDate.lastYear
                        if let oldBalance = account.balanceGivenDate(date: oldDate) {
                            if accountDetail.lastPeriodBalance != nil {
                                accountDetail.lastPeriodBalance! += oldBalance
                            } else {
                                accountDetail.lastPeriodBalance = oldBalance
                            }
                        }
                    }
                    accounts!.append(account)
                    
                    accountsDict[accountDetail] = accounts
                } else {
                    var accountDetail = AccountDetails(name: account.type.name, balance: balance, level: .type, subtype: nil, type: account.type, bs_type: account.bs_type, currencyCode: account.currency_code ?? "USD")
                    switch timeSegment {
                    case .day:
                        let oldDate = finalDate.dayBefore
                        if let oldBalance = account.balanceGivenDate(date: oldDate) {
                            accountDetail.lastPeriodBalance = oldBalance
                        }
                    case .week:
                        let oldDate = finalDate.weekBefore
                        if let oldBalance = account.balanceGivenDate(date: oldDate) {
                            accountDetail.lastPeriodBalance = oldBalance
                        }
                    case .month:
                        let oldDate = finalDate.monthBefore
                        if let oldBalance = account.balanceGivenDate(date: oldDate) {
                            accountDetail.lastPeriodBalance = oldBalance
                        }
                    case .year:
                        let oldDate = finalDate.lastYear
                        if let oldBalance = account.balanceGivenDate(date: oldDate) {
                            accountDetail.lastPeriodBalance = oldBalance
                        }
                    }
                    accountsDict[accountDetail] = [account]
                }
                
                if let index = accountsDict.keys.firstIndex(where: {$0.name == account.bs_type.name && $0.level == .bs_type && $0.bs_type == account.bs_type}) {
                    var accountDetail = accountsDict.keys[index]
                    var accounts = accountsDict[accountDetail]
                    
                    accountsDict[accountDetail] = nil
                    
                    accountDetail.balance += balance
                    switch timeSegment {
                    case .day:
                        let oldDate = finalDate.dayBefore
                        if let oldBalance = account.balanceGivenDate(date: oldDate) {
                            if accountDetail.lastPeriodBalance != nil {
                                accountDetail.lastPeriodBalance! += oldBalance
                            } else {
                                accountDetail.lastPeriodBalance = oldBalance
                            }
                        }
                    case .week:
                        let oldDate = finalDate.weekBefore
                        if let oldBalance = account.balanceGivenDate(date: oldDate) {
                            if accountDetail.lastPeriodBalance != nil {
                                accountDetail.lastPeriodBalance! += oldBalance
                            } else {
                                accountDetail.lastPeriodBalance = oldBalance
                            }
                        }
                    case .month:
                        let oldDate = finalDate.monthBefore
                        if let oldBalance = account.balanceGivenDate(date: oldDate) {
                            if accountDetail.lastPeriodBalance != nil {
                                accountDetail.lastPeriodBalance! += oldBalance
                            } else {
                                accountDetail.lastPeriodBalance = oldBalance
                            }
                        }
                    case .year:
                        let oldDate = finalDate.lastYear
                        if let oldBalance = account.balanceGivenDate(date: oldDate) {
                            if accountDetail.lastPeriodBalance != nil {
                                accountDetail.lastPeriodBalance! += oldBalance
                            } else {
                                accountDetail.lastPeriodBalance = oldBalance
                            }
                        }
                    }
                    accounts!.append(account)
                    
                    accountsDict[accountDetail] = accounts
                } else {
                    var accountDetail = AccountDetails(name: account.bs_type.name, balance: balance, level: .bs_type, subtype: nil, type: nil, bs_type: account.bs_type, currencyCode: account.currency_code ?? "USD")
                    switch timeSegment {
                    case .day:
                        let oldDate = finalDate.dayBefore
                        if let oldBalance = account.balanceGivenDate(date: oldDate) {
                            accountDetail.lastPeriodBalance = oldBalance
                        }
                    case .week:
                        let oldDate = finalDate.weekBefore
                        if let oldBalance = account.balanceGivenDate(date: oldDate) {
                            accountDetail.lastPeriodBalance = oldBalance
                        }
                    case .month:
                        let oldDate = finalDate.monthBefore
                        if let oldBalance = account.balanceGivenDate(date: oldDate) {
                            accountDetail.lastPeriodBalance = oldBalance
                        }
                    case .year:
                        let oldDate = finalDate.lastYear
                        if let oldBalance = account.balanceGivenDate(date: oldDate) {
                            accountDetail.lastPeriodBalance = oldBalance
                        }
                    }
                    accountsDict[accountDetail] = [account]
                }
            }
        }
    }
    
    accountsList = Array(accountsDict.keys)
    var sortedAccountsList = [AccountDetails]()
    if !accountsList.isEmpty {
        if let assetAccountDetail = accountsList.first(where: {$0.level == .bs_type && $0.bs_type == .Asset}), let liabilityAccountDetail = accountsList.first(where: {$0.level == .bs_type && $0.bs_type == .Liability}) {
            let assetAccounts = accountsDict[assetAccountDetail] ?? []
            let liabilityAccounts = accountsDict[liabilityAccountDetail] ?? []
            let accounts = assetAccounts + liabilityAccounts
            let balance = assetAccountDetail.balance - liabilityAccountDetail.balance
            let lastPeriodBalance = (assetAccountDetail.lastPeriodBalance ?? 0) - (liabilityAccountDetail.lastPeriodBalance ?? 0)
            var accountDetail = AccountDetails(name: "Net Worth", balance: balance, level: .bs_type, subtype: nil, type: nil, bs_type: .NetWorth, currencyCode: "USD")
            if lastPeriodBalance > 0 {
                accountDetail.lastPeriodBalance = lastPeriodBalance
            }
            sortedAccountsList.insert(accountDetail, at: 0)
            accountsDict[accountDetail] = accounts
        }
        for bs_type in BalanceSheetType.allCases {
            if let accountDetail = accountsList.first(where: {$0.level == .bs_type && $0.bs_type == bs_type}) {
                sortedAccountsList.append(accountDetail)
                for type in MXAccountType.allCases {
                    if let accountDetail = accountsList.first(where: {$0.level == .type && $0.bs_type == bs_type && $0.type == type}) {
                        sortedAccountsList.append(accountDetail)
                        for subtype in MXAccountSubType.allCases {
                            if let accountDetail = accountsList.first(where: {$0.level == .subtype && $0.bs_type == bs_type && $0.type == type && $0.subtype == subtype}) {
                                if subtype != .none {
                                    sortedAccountsList.append(accountDetail)
                                }
                            }
                            let accounts = accountsList.filter({$0.level == .account && $0.bs_type == bs_type && $0.type == type && $0.subtype == subtype})
                            let sortedAccounts = accounts.sorted(by: {$0.name < $1.name})
                            for account in sortedAccounts {
                                sortedAccountsList.append(account)
                            }
                        }
                    }
                }
            }
        }
    }
    completion(sortedAccountsList, accountsDict)
}

func accountDetailsOverTimeChartData(accounts: [MXAccount], accountDetails: [AccountDetails], start: Date, end: Date, segmentType: TimeSegmentType, completion: @escaping ([AccountDetails: [Statistic]], [AccountDetails: [MXAccount]]) -> ()) {
    var statistics = [AccountDetails: [Statistic]]()
    var accountDict = [AccountDetails: [MXAccount]]()
    let calendar = NSCalendar(calendarIdentifier: NSCalendar.Identifier.gregorian)!
    calendar.timeZone = TimeZone(secondsFromGMT: 0)!
    var date = start
    switch segmentType {
    case .day:
        var nextDate = calendar.date(byAdding: .day, value: 1, to: date, options: [])!
        // While date <= endDate ...
        while nextDate.compare(end) != .orderedDescending {
            for accountDetail in accountDetails {
                accountListStats(accounts: accounts, accountDetail: accountDetail, date: date, nextDate: nextDate) { (stats, accounts) in
                    if accountDict[accountDetail] != nil {
                        var tdStats = statistics[accountDetail]
                        var tdAccountList = accountDict[accountDetail]
                        tdStats!.append(contentsOf: stats)
                        for account in accounts {
                            if !tdAccountList!.contains(account) {
                                tdAccountList!.append(account)
                            }
                        }
                        statistics[accountDetail] = tdStats
                        accountDict[accountDetail] = tdAccountList
                    } else {
                        statistics[accountDetail] = stats
                        accountDict[accountDetail] = accounts
                    }
                }
            }
            // Advance by one day:
            date = nextDate
            nextDate = calendar.date(byAdding: .day, value: 1, to: nextDate, options: [])!
        }
    case .week:
        var nextDate = calendar.date(byAdding: .day, value: 1, to: date, options: [])!
        // While date <= endDate ...
        while nextDate.compare(end) != .orderedDescending {
            for accountDetail in accountDetails {
                accountListStats(accounts: accounts, accountDetail: accountDetail, date: date, nextDate: nextDate) { (stats, accounts) in
                    if accountDict[accountDetail] != nil, accountDict[accountDetail] != nil {
                        var tdStats = statistics[accountDetail]
                        var tdAccountList = accountDict[accountDetail]
                        tdStats!.append(contentsOf: stats)
                        for account in accounts {
                            if !tdAccountList!.contains(account) {
                                tdAccountList!.append(account)
                            }
                        }
                        statistics[accountDetail] = tdStats
                        accountDict[accountDetail] = tdAccountList
                    } else {
                        statistics[accountDetail] = stats
                        accountDict[accountDetail] = accounts
                    }
                }
            }
            // Advance by one day:
            date = nextDate
            nextDate = calendar.date(byAdding: .day, value: 1, to: nextDate, options: [])!
        }
    case .month:
        var nextDate = calendar.date(byAdding: .day, value: 1, to: date, options: [])!
        // While date <= endDate ...
        while nextDate.compare(end) != .orderedDescending {
            for accountDetail in accountDetails {
                accountListStats(accounts: accounts, accountDetail: accountDetail, date: date, nextDate: nextDate) { (stats, accounts) in
                    if accountDict[accountDetail] != nil, accountDict[accountDetail] != nil {
                        var tdStats = statistics[accountDetail]
                        var tdAccountList = accountDict[accountDetail]
                        tdStats!.append(contentsOf: stats)
                        for account in accounts {
                            if !tdAccountList!.contains(account) {
                                tdAccountList!.append(account)
                            }
                        }
                        statistics[accountDetail] = tdStats
                        accountDict[accountDetail] = tdAccountList
                    } else {
                        statistics[accountDetail] = stats
                        accountDict[accountDetail] = accounts
                    }
                }
            }
            
            // Advance by one day:
            date = nextDate
            nextDate = calendar.date(byAdding: .day, value: 1, to: nextDate, options: [])!
        }
    case .year:
        var nextDate = calendar.date(byAdding: .month, value: 1, to: date, options: [])!
        // While date <= endDate ...
        while nextDate.compare(end) != .orderedDescending {
            for accountDetail in accountDetails {
                accountListStats(accounts: accounts, accountDetail: accountDetail, date: date, nextDate: nextDate) { (stats, accounts) in
                    if accountDict[accountDetail] != nil, accountDict[accountDetail] != nil {
                        var tdStats = statistics[accountDetail]
                        var tdAccountList = accountDict[accountDetail]
                        tdStats!.append(contentsOf: stats)
                        for account in accounts {
                            if !tdAccountList!.contains(account) {
                                tdAccountList!.append(account)
                            }
                        }
                        statistics[accountDetail] = tdStats
                        accountDict[accountDetail] = tdAccountList
                    } else {
                        statistics[accountDetail] = stats
                        accountDict[accountDetail] = accounts
                    }
                }
            }
            // Advance by one day:
            date = nextDate
            nextDate = calendar.date(byAdding: .month, value: 1, to: nextDate, options: [])!
        }
    }
    completion(statistics, accountDict)
}

func accountListStats(accounts: [MXAccount], accountDetail: AccountDetails, date: Date, nextDate: Date, completion: @escaping ([Statistic], [MXAccount]) -> ()) {
    var statistics = [Statistic]()
    var accountList = [MXAccount]()
    let isodateFormatter = ISO8601DateFormatter()
    
    for account in accounts {
        guard account.should_link ?? true else { continue }
        if let balances = account.balances {
            let sortedBalances = Array(balances.keys.sorted {$0.localizedStandardCompare($1) == .orderedDescending})
            let firstBalanceDate = isodateFormatter.date(from: sortedBalances.last!)!
            //need to include for future dates
            let lastBalanceDate = Date().addingTimeInterval(86400)
            if date >= firstBalanceDate, nextDate >= firstBalanceDate, date <= lastBalanceDate, nextDate <= lastBalanceDate {
                var currentBalance = 0.0
                if let balanceDate = sortedBalances.first(where: { isodateFormatter.date(from: $0)! > date && nextDate > isodateFormatter.date(from: $0)! }) {
                    currentBalance = balances[balanceDate] ?? 0
                } else if let balanceDate = sortedBalances.first(where: { isodateFormatter.date(from: $0)! < date }) {
                    currentBalance = balances[balanceDate] ?? 0
                } else {
                    continue
                }
                                            
                if accountDetail.name == "Net Worth" {
                    if account.bs_type == .Asset {
                        if let index = statistics.firstIndex(where: {$0.date == nextDate}) {
                            statistics[index].value += currentBalance
                            if !accountList.contains(account) {
                                accountList.append(account)
                            }
                        } else {
                            let stat = Statistic(date: nextDate, value: currentBalance)
                            statistics.append(stat)
                            if !accountList.contains(account) {
                                accountList.append(account)
                            }
                        }
                    } else if account.bs_type == .Liability {
                        if let index = statistics.firstIndex(where: {$0.date == nextDate}) {
                            statistics[index].value -= currentBalance
                            if !accountList.contains(account) {
                                accountList.append(account)
                            }
                        } else {
                            let stat = Statistic(date: nextDate, value: -currentBalance)
                            statistics.append(stat)
                            if !accountList.contains(account) {
                                accountList.append(account)
                            }
                        }
                    }
                } else if accountDetail.name == account.name && accountDetail.level == .account {
                    if let index = statistics.firstIndex(where: {$0.date == nextDate}) {
                        statistics[index].value += currentBalance
                        if !accountList.contains(account) {
                            accountList.append(account)
                        }
                    } else {
                        let stat = Statistic(date: nextDate, value: currentBalance)
                        statistics.append(stat)
                        if !accountList.contains(account) {
                            accountList.append(account)
                        }
                    }
                } else if accountDetail.name == account.subtype?.name ?? MXAccountSubType.none.name && accountDetail.level == .subtype {
                    if let index = statistics.firstIndex(where: {$0.date == nextDate}) {
                        statistics[index].value += currentBalance
                        if !accountList.contains(account) {
                            accountList.append(account)
                        }
                    } else {
                        let stat = Statistic(date: nextDate, value: currentBalance)
                        statistics.append(stat)
                        if !accountList.contains(account) {
                            accountList.append(account)
                        }
                    }
                } else if accountDetail.name == account.type.name && accountDetail.level == .type {
                    if let index = statistics.firstIndex(where: {$0.date == nextDate}) {
                        statistics[index].value += currentBalance
                        if !accountList.contains(account) {
                            accountList.append(account)
                        }
                    } else {
                        let stat = Statistic(date: nextDate, value: currentBalance)
                        statistics.append(stat)
                        if !accountList.contains(account) {
                            accountList.append(account)
                        }
                    }
                } else if accountDetail.name == account.bs_type.name && accountDetail.level == .bs_type {
                    if let index = statistics.firstIndex(where: {$0.date == nextDate}) {
                        statistics[index].value += currentBalance
                        if !accountList.contains(account) {
                            accountList.append(account)
                        }
                    } else {
                        let stat = Statistic(date: nextDate, value: currentBalance)
                        statistics.append(stat)
                        if !accountList.contains(account) {
                            accountList.append(account)
                        }
                    }
                }
            }
        }
    }
    
    completion(statistics, accountList)
}
