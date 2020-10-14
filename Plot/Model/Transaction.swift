//
//  Transaction.swift
//  Plot
//
//  Created by Cory McHattie on 8/18/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

let userFinancialTransactionsEntity = "user-financial-transactions"
let financialTransactionsEntity = "financial-transactions"
let financialTransactionsCategoriesEntity = "financial-transactions-categories"
let financialTransactionsTopLevelCategoriesEntity = "financial-transactions-top-level-categories"
let financialTransactionsGroupsEntity = "user-financial-transactions-groups"
let userFinancialTransactionsCategoriesEntity = "user-financial-transactions-categories"
let userFinancialTransactionsTopLevelCategoriesEntity = "user-financial-transactions-top-level-categories"
let userFinancialTransactionsGroupsEntity = "user-financial-transactions-groups"
let userFinancialTransactionRulesEntity = "user-financial-transaction-rules"

struct MXTransactionResult: Codable {
    let transaction: Transaction?
    let transactions: [Transaction]?
    let pagination: MXPagination?
}

struct Transaction: Codable, Equatable, Hashable {
    var account_guid: String?
    var amount: Double
    var category: TransactionCategory
    var check_number: Int?
    var check_number_string: String?
    var created_at: String
    var currency_code: String?
    var date: String
    var description: String
    var guid: String
    var is_bill_pay: Bool?
    var is_direct_deposit: Bool?
    var is_expense: Bool?
    var is_fee: Bool?
    var is_income: Bool?
    var is_international: Bool?
    var is_overdraft_fee: Bool?
    var is_payroll_advance: Bool?
    var latitude: Double?
    var longitude: Double?
    var member_guid: String?
    var memo: String?
    var merchant_category_code: Int?
    var merchant_guid: String?
    var original_description: String?
    var posted_at: String?
    var status: TransactionStatus
    var top_level_category: TransactionTopLevelCategory
    var transacted_at: String
    var type: String?
    var updated_at: String
    var user_guid: String
    var tags: [String]?
    var should_link: Bool?
    var participantsIDs: [String]?
    var date_for_reports: String?
    var user_created: Bool?
    var admin: String?
    var activityID: String?
    var badge: Int?
    var pinned: Bool?
    var muted: Bool?
    var splitNumber: Int?
    var cash_flow_type: String {
        if type == "CREDIT" {
            return "Inflow"
        } else {
            return "Outflow"
        }
    }
    private var _group: TransactionGroup?
    var group: TransactionGroup {
        get {
            if let _group = _group {
                return _group
            } else {
                switch self.category {
                case .autoPayment, .autoInsurance: return .bills
                case .gas, .parking, .publicTransportation, .serviceParts: return .living
                case .domainNames, .fraudProtection, .homePhone, .hosting, .internet, .mobilePhone, .television, .utilities: return .bills
                case .advertising, .legal, .officeSupplies, .printing, .shipping: return .living
                case .booksSupplies, .studentLoan, .tuition: return .living
                case .amusement, .arts, .moviesDvds, .music, .newspapersMagazines: return .discretionary
                case .atmFee, .bankingFee, .financeCharge, .lateFee, .serviceFee, .tradeCommissions: return .living
                case .financialAdvisor, .lifeInsurance: return .bills
                case .alcoholBars, .coffeeShops, .fastFood, .groceries, .restaurants: return .discretionary
                case .charity, .gift: return .living
                case .dentist, .doctor, .eyecare, .gym, .healthInsurance, .pharmacy, .sports: return .living
                case .furnishings, .homeImprovement, .homeServices, .homeSupplies, .lawnGarden, .home: return .living
                case .homeInsurance, .mortgageRent: return .bills
                case .bonus, .interestIncome, .paycheck, .reimbursement, .rentalIncome, .income: return .income
                case .buy, .dividendCapGains, .sell: return .living
                case  .deposit, .withdrawal: return .transfer
                case .allowance, .babySupplies, .babysitterDaycare, .childSupport, .kidsActivities, .toys: return .kids
                case .hair, .laundry: return .living
                case .spaMassage: return .discretionary
                case .petFoodSupplies, .petGrooming, .veterinary: return .living
                case .books, .clothing, .hobbies, .sportingGoods: return .discretionary
                case .federalTax, .localTax, .propertyTax, .salesTax, .stateTax: return .living
                case .creditCardPayment, .transferCashSpending, .transfer, .mortgagePayment: return .transfer
                case .airTravel, .hotel, .rentalCarTaxi, .vacation: return .discretionary
                case .cash, .check, .uncategorized: return .uncategorized
                case .investments: return .living
                case .kids: return .living
                case .personalCare: return .living
                case .pets: return .living
                case .shopping: return .discretionary
                case .taxes: return .living
                case .travel: return .discretionary
                case .autoTransport: return .living
                case .billsUtilities: return .bills
                case .businessServices: return .living
                case .education: return .living
                case .entertainment: return .discretionary
                case .feesCharges: return .bills
                case .financial: return .living
                case .foodDining: return .discretionary
                case .giftsDonations: return .discretionary
                case .healthFitness: return .living
                case .electronicsSoftware: return .discretionary
                }
            }
        }
        set {
            _group = newValue
        }
    }
    
    init(description: String, amount: Double, created_at: String, guid: String, user_guid: String, status: TransactionStatus, category: TransactionCategory, top_level_category: TransactionTopLevelCategory, user_created: Bool?, admin: String) {
        self.description = description
        self.amount = amount
        self.created_at = created_at
        self.date = created_at
        self.transacted_at = created_at
        self.updated_at = created_at
        self.guid = guid
        self.user_guid = user_guid
        self.status = status
        self.category = category
        self.top_level_category = top_level_category
        self.user_created = user_created
    }
}

func ==(lhs: Transaction, rhs: Transaction) -> Bool {
    return lhs.guid == rhs.guid && lhs.member_guid == rhs.member_guid && lhs.user_guid == rhs.user_guid
}

struct UserTransaction: Codable, Equatable, Hashable {
    var description: String?
    var category: TransactionCategory?
    var top_level_category: TransactionTopLevelCategory?
    var group: TransactionGroup?
    var tags: [String]?
    var should_link: Bool?
    var date_for_reports: String?
    var badge: Int?
    var pinned: Bool?
    var muted: Bool?
}

enum TransactionCatLevel: String, Codable {
    case category
    case top
    case group
}

enum TransactionStatus: String, Codable {
    case pending = "PENDING"
    case posted = "POSTED"
    
    var name: String {
        switch self {
        case .pending: return "Pending"
        case .posted: return "Posted"
        }
    }
}

enum TransactionGroup: String, CaseIterable, Codable {
    case difference = "Difference"
    case income = "Income"
    case expense = "Expenses"
    case bills = "Bills"
    case discretionary = "Discretionary"
    case kids = "Kids"
    case living = "Living"
    case transfer = "Transfer"
    case work = "Work"
    case uncategorized = "Uncategorized"
    
}

enum TransactionTopLevelCategory: String, CaseIterable, Codable {
    case autoTransport = "Auto & Transport"
    case billsUtilities = "Bills & Utilities"
    case businessServices = "Business Services"
    case education = "Education"
    case electronicsSoftware = "Electronics & Software"
    case entertainment = "Entertainment"
    case feesCharges = "Fees & Charges"
    case financial = "Financial"
    case foodDining = "Food & Dining"
    case giftsDonations = "Gifts & Donations"
    case healthFitness = "Health & Fitness"
    case home = "Home"
    case income = "Income"
    case investments = "Invesments"
    case kids = "Kids"
    case personalCare = "Personal Care"
    case pets = "Pets"
    case shopping = "Shopping"
    case taxes = "Taxes"
    case transfer = "Transfer"
    case travel = "Travel"
    case uncategorized = "Uncategorized"
    
    var categoryLists: [TransactionCategory] {
        switch self {
        case .autoTransport: return [.autoInsurance, .autoPayment, .gas, .parking, .publicTransportation, .serviceParts, .autoTransport]
        case .billsUtilities: return [.domainNames, .fraudProtection, .homePhone, .hosting, .internet, .mobilePhone, .television, .utilities, .billsUtilities]
        case .businessServices: return [.advertising, .legal, .officeSupplies, .printing, .shipping, .businessServices]
        case .education: return [.booksSupplies, .studentLoan, .tuition, .education]
        case .electronicsSoftware: return [.electronicsSoftware]
        case .entertainment: return [.amusement, .arts, .moviesDvds, .music, .newspapersMagazines, .entertainment]
        case .feesCharges: return [.atmFee, .bankingFee, .financeCharge, .lateFee, .serviceFee, .tradeCommissions, .feesCharges]
        case .financial: return [.financialAdvisor, .lifeInsurance, .financial]
        case .foodDining: return [.alcoholBars, .coffeeShops, .fastFood, .groceries, .restaurants, .foodDining]
        case .giftsDonations: return [.charity, .gift, .giftsDonations]
        case .healthFitness: return [.dentist, .doctor, .eyecare, .gym, .healthInsurance, .pharmacy, .sports, .healthFitness]
        case .home: return [.furnishings, .homeImprovement, .homeInsurance, .homeServices, .homeSupplies, .lawnGarden, .mortgageRent, .home]
        case .income: return [.bonus, .interestIncome, .paycheck, .reimbursement, .rentalIncome, .income]
        case .investments: return [.buy, .deposit, .dividendCapGains, .sell, .withdrawal, .investments]
        case .kids: return [.allowance, .babySupplies, .babysitterDaycare, .childSupport, .kidsActivities, .toys, .kids]
        case .personalCare: return [.hair, .laundry, .spaMassage, .personalCare]
        case .pets: return [.petFoodSupplies, .petGrooming, .veterinary, .pets]
        case .shopping: return [.books, .clothing, .hobbies, .sportingGoods, .shopping]
        case .taxes: return [.federalTax, .localTax, .propertyTax, .salesTax, .stateTax, .taxes]
        case .transfer: return [.creditCardPayment, .transferCashSpending, .transfer, .mortgagePayment]
        case .travel: return [.airTravel, .hotel, .rentalCarTaxi, .vacation, .travel]
        case .uncategorized: return [.cash, .check, .uncategorized]
        }
    }
}

enum TransactionCategory: String, CaseIterable, Codable {
    case autoInsurance = "Auto Insurance"
    case autoPayment = "Auto Payment"
    case gas = "Gas"
    case parking = "Parking"
    case publicTransportation = "Public Transportation"
    case serviceParts = "Service & Parts"
    case domainNames = "Domain Names"
    case fraudProtection = "Fraud Protection"
    case homePhone = "Home Phone"
    case hosting = "Hosting"
    case internet = "Internet"
    case mobilePhone = "Mobile Phone"
    case television = "Television"
    case utilities = "Utilities"
    case advertising = "Advertising"
    case legal = "Legal"
    case officeSupplies = "Office Supplies"
    case printing = "Print"
    case shipping = "Shipping"
    case booksSupplies = "Book Supplies"
    case studentLoan = "Student Loans"
    case tuition = "Tuition"
    case amusement = "Amusement"
    case arts = "Arts"
    case moviesDvds = "Movies & DVDs"
    case music = "Music"
    case newspapersMagazines = "Newspapers & Magazines"
    case atmFee = "ATM Fee"
    case bankingFee = "Banking Fee"
    case financeCharge = "Finance Charge"
    case lateFee = "Late Fee"
    case serviceFee = "Service Fee"
    case tradeCommissions = "Trade Commissions"
    case financialAdvisor = "Financial Advisor"
    case lifeInsurance = "Life Insurance"
    case alcoholBars = "Alcohol & Bars"
    case coffeeShops = "Coffee Shops"
    case fastFood = "Fast Food"
    case groceries = "Groceries"
    case restaurants = "Restaurants"
    case charity = "Charity"
    case gift = "Gift"
    case dentist = "Dentist"
    case doctor = "Doctor"
    case eyecare = "Eyecare"
    case gym = "Gym"
    case healthInsurance = "Health Insurance"
    case pharmacy = "Pharmacy"
    case sports = "Sports"
    case furnishings = "Furnishings"
    case homeImprovement = "Home Improvement"
    case homeInsurance = "Home Insurance"
    case homeServices = "Home Services"
    case homeSupplies = "Home Supplies"
    case lawnGarden = "Lawn Garden"
    case mortgageRent = "Mortgage & Rent"
    case bonus = "Bonus"
    case interestIncome = "Interest Income"
    case paycheck = "Paycheck"
    case reimbursement = "Reimbursement"
    case rentalIncome = "Rental Income"
    case buy = "Buy"
    case deposit = "Deposit"
    case dividendCapGains = "Dividend & Cap Gains"
    case sell = "Sell"
    case withdrawal = "Withdrawal"
    case allowance = "Allowance"
    case babySupplies = "Baby Supplies"
    case babysitterDaycare = "Babysitter & Daycare"
    case childSupport = "Child Support"
    case kidsActivities = "Kids Activities"
    case toys = "Toys"
    case hair = "Hair"
    case laundry = "Laundry"
    case spaMassage = "Spa & Massage"
    case petFoodSupplies = "Pet Food & Supplies"
    case petGrooming = "Pet Grooming"
    case veterinary = "Veterinary"
    case books = "Books"
    case clothing = "Clothing"
    case hobbies = "Hobbies"
    case sportingGoods = "Sporting Goods"
    case federalTax = "Federal Tax"
    case localTax = "Local Tax"
    case propertyTax = "Property Tax"
    case salesTax = "Sales Tax"
    case stateTax = "State Tax"
    case creditCardPayment = "Credit Card Payment"
    case transferCashSpending = "Transfer for Cash Spending"
    case mortgagePayment = "Mortgage Payment"
    case airTravel = "Air Travel"
    case hotel = "Hotel"
    case rentalCarTaxi = "Rental Car & Taxi"
    case vacation = "Vacation"
    case cash = "Cash"
    case check = "Check"
    case autoTransport = "Auto & Transport"
    case billsUtilities = "Bills & Utilities"
    case businessServices = "Business Services"
    case education = "Education"
    case entertainment = "Entertainment"
    case feesCharges = "Fees & Charges"
    case financial = "Financial"
    case foodDining = "Food & Dining"
    case giftsDonations = "Gifts & Donations"
    case healthFitness = "Health & Fitness"
    case home = "Home"
    case income = "Income"
    case investments = "Invesments"
    case kids = "Kids"
    case personalCare = "Personal Care"
    case pets = "Pets"
    case shopping = "Shopping"
    case taxes = "Taxes"
    case transfer = "Transfer"
    case travel = "Travel"
    case uncategorized = "Uncategorized"
    case electronicsSoftware = "Electronics & Software"
    
    var top_level_category: TransactionTopLevelCategory {
        switch self {
        case .autoInsurance, .autoPayment, .gas, .parking, .publicTransportation, .serviceParts: return .autoTransport
        case .domainNames, .fraudProtection, .homePhone, .hosting, .internet, .mobilePhone, .television, .utilities: return .billsUtilities
        case .advertising, .legal, .officeSupplies, .printing, .shipping: return .businessServices
        case .booksSupplies, .studentLoan, .tuition: return .education
        case .amusement, .arts, .moviesDvds, .music, .newspapersMagazines: return .entertainment
        case .atmFee, .bankingFee, .financeCharge, .lateFee, .serviceFee, .tradeCommissions: return .feesCharges
        case .financialAdvisor, .lifeInsurance: return .financial
        case .alcoholBars, .coffeeShops, .fastFood, .groceries, .restaurants: return .foodDining
        case .charity, .gift: return .giftsDonations
        case .dentist, .doctor, .eyecare, .gym, .healthInsurance, .pharmacy, .sports: return .healthFitness
        case .furnishings, .homeImprovement, .homeInsurance, .homeServices, .homeSupplies, .lawnGarden, .mortgageRent, .home: return .home
        case .bonus, .interestIncome, .paycheck, .reimbursement, .rentalIncome, .income: return .income
        case .buy, .deposit, .dividendCapGains, .sell, .withdrawal: return .investments
        case .allowance, .babySupplies, .babysitterDaycare, .childSupport, .kidsActivities, .toys: return .kids
        case .hair, .laundry, .spaMassage: return .personalCare
        case .petFoodSupplies, .petGrooming, .veterinary: return .pets
        case .books, .clothing, .hobbies, .sportingGoods: return .shopping
        case .federalTax, .localTax, .propertyTax, .salesTax, .stateTax: return .taxes
        case .creditCardPayment, .transferCashSpending, .transfer, .mortgagePayment: return .transfer
        case .airTravel, .hotel, .rentalCarTaxi, .vacation: return .travel
        case .cash, .check, .uncategorized: return .uncategorized
        case .investments: return .investments
        case .kids: return .kids
        case .personalCare: return .personalCare
        case .pets: return .pets
        case .shopping: return .shopping
        case .taxes: return .taxes
        case .travel: return .travel
        case .autoTransport: return .autoTransport
        case .billsUtilities: return .billsUtilities
        case .businessServices: return .businessServices
        case .education: return .education
        case .entertainment: return .entertainment
        case .feesCharges: return .feesCharges
        case .financial: return .financial
        case .foodDining: return .foodDining
        case .giftsDonations: return .healthFitness
        case .healthFitness: return .healthFitness
        case .electronicsSoftware: return .electronicsSoftware
        }
    }
    
    var group: TransactionGroup {
        switch self {
        case .autoPayment, .autoInsurance: return .bills
        case .gas, .parking, .publicTransportation, .serviceParts: return .living
        case .domainNames, .fraudProtection, .homePhone, .hosting, .internet, .mobilePhone, .television, .utilities: return .bills
        case .advertising, .legal, .officeSupplies, .printing, .shipping: return .living
        case .booksSupplies, .studentLoan, .tuition: return .living
        case .amusement, .arts, .moviesDvds, .music, .newspapersMagazines: return .discretionary
        case .atmFee, .bankingFee, .financeCharge, .lateFee, .serviceFee, .tradeCommissions: return .living
        case .financialAdvisor, .lifeInsurance: return .bills
        case .alcoholBars, .coffeeShops, .fastFood, .groceries, .restaurants: return .discretionary
        case .charity, .gift: return .living
        case .dentist, .doctor, .eyecare, .gym, .healthInsurance, .pharmacy, .sports: return .living
        case .furnishings, .homeImprovement, .homeServices, .homeSupplies, .lawnGarden, .home: return .living
        case .homeInsurance, .mortgageRent: return .bills
        case .bonus, .interestIncome, .paycheck, .reimbursement, .rentalIncome, .income: return .income
        case .buy, .dividendCapGains, .sell: return .living
        case  .deposit, .withdrawal: return .transfer
        case .allowance, .babySupplies, .babysitterDaycare, .childSupport, .kidsActivities, .toys: return .kids
        case .hair, .laundry: return .living
        case .spaMassage: return .discretionary
        case .petFoodSupplies, .petGrooming, .veterinary: return .living
        case .books, .clothing, .hobbies, .sportingGoods: return .discretionary
        case .federalTax, .localTax, .propertyTax, .salesTax, .stateTax: return .living
        case .creditCardPayment, .transferCashSpending, .transfer, .mortgagePayment: return .transfer
        case .airTravel, .hotel, .rentalCarTaxi, .vacation: return .discretionary
        case .cash, .check, .uncategorized: return .uncategorized
        case .investments: return .living
        case .kids: return .living
        case .personalCare: return .living
        case .pets: return .living
        case .shopping: return .discretionary
        case .taxes: return .living
        case .travel: return .discretionary
        case .autoTransport: return .living
        case .billsUtilities: return .bills
        case .businessServices: return .living
        case .education: return .living
        case .entertainment: return .discretionary
        case .feesCharges: return .bills
        case .financial: return .living
        case .foodDining: return .discretionary
        case .giftsDonations: return .discretionary
        case .healthFitness: return .living
        case .electronicsSoftware: return .discretionary
        }
    }
}

struct TransactionDetails: Codable, Equatable, Hashable {
    let uuid = UUID().uuidString
    var name: String
    var amount: Double
    var level: TransactionCatLevel
    var category: TransactionCategory?
    var topLevelCategory: TransactionTopLevelCategory?
    var group: TransactionGroup
}

struct MXTransactionRuleResult: Codable {
    let transaction_rule: TransactionRule
}

struct TransactionRule: Codable, Equatable, Hashable {
    let created_at: String
    let guid: String
    var match_description: String
    var description: String?
    let updated_at: String
    let user_guid: String
    var category: TransactionCategory?
    var top_level_category: TransactionTopLevelCategory?
    var group: TransactionGroup?
    var amount: Double?
}

struct MXTransactionCategoryResult: Codable {
    let category: TransactionCategoryFull
}

struct TransactionCategoryFull: Codable, Equatable, Hashable {
    let created_at: String
    let name: String
    let guid: String
    let parent_guid: String
    let updated_at: String
    let is_default: Bool
    let is_income: Bool?
    let metadata: String?
}

func categorizeTransactions(transactions: [Transaction], start: Date?, end: Date?, type: TransactionCatLevel?, completion: @escaping ([TransactionDetails], [TransactionDetails: [Transaction]]) -> ()) {
    var transactionsList = [TransactionDetails]()
    var transactionsDict = [TransactionDetails: [Transaction]]()
    // create dateFormatter with UTC time format
    let isodateFormatter = ISO8601DateFormatter()
    for transaction in transactions {
        if let date = transaction.date_for_reports, date != "", let transactionDate = isodateFormatter.date(from: date), let start = start, let end = end {
            if transactionDate < start.stripTime() || end.stripTime() < transactionDate {
                continue
            }
        } else if let transactionDate = isodateFormatter.date(from: transaction.transacted_at), let start = start, let end = end {
            if transactionDate < start.stripTime() || end.stripTime() < transactionDate {
                continue
            }
        }
        guard transaction.should_link ?? true else { continue }
        switch transaction.type {
        case "DEBIT":
            switch type {
            case .category:
                if let index = transactionsDict.keys.firstIndex(where: {$0.name == transaction.category.rawValue && $0.level == .category && $0.category == transaction.category && $0.topLevelCategory == transaction.top_level_category && $0.group == transaction.group}) {
                    var transactionDetail = transactionsDict.keys[index]
                    var transactions = transactionsDict[transactionDetail]
                    
                    transactionsDict[transactionDetail] = nil
                    
                    transactionDetail.amount -= transaction.amount
                    transactions!.append(transaction)
                    
                    transactionsDict[transactionDetail] = transactions
                } else {
                    let transactionDetail = TransactionDetails(name: transaction.category.rawValue, amount: -transaction.amount, level: .category, category: transaction.category, topLevelCategory: transaction.top_level_category, group: transaction.group)
                    transactionsDict[transactionDetail] = [transaction]
                }
            case .top:
                if let index = transactionsDict.keys.firstIndex(where: {$0.name == transaction.top_level_category.rawValue && $0.level == .top && $0.topLevelCategory == transaction.top_level_category && $0.group == transaction.group}) {
                    var transactionDetail = transactionsDict.keys[index]
                    var transactions = transactionsDict[transactionDetail]
                    
                    transactionsDict[transactionDetail] = nil
                    
                    transactionDetail.amount -= transaction.amount
                    transactions!.append(transaction)
                    
                    transactionsDict[transactionDetail] = transactions
                } else {
                    let transactionDetail = TransactionDetails(name: transaction.top_level_category.rawValue, amount: -transaction.amount, level: .top, category: nil, topLevelCategory: transaction.top_level_category, group: transaction.group)
                    transactionsDict[transactionDetail] = [transaction]
                }
            case .group:
                if let index = transactionsDict.keys.firstIndex(where: {$0.name == transaction.group.rawValue && $0.level == .group && $0.group == transaction.group}) {
                    var transactionDetail = transactionsDict.keys[index]
                    var transactions = transactionsDict[transactionDetail]
                    
                    transactionsDict[transactionDetail] = nil
                    
                    transactionDetail.amount -= transaction.amount
                    transactions!.append(transaction)
                    
                    transactionsDict[transactionDetail] = transactions
                } else {
                    let transactionDetail = TransactionDetails(name: transaction.group.rawValue, amount: -transaction.amount, level: .group, category: nil, topLevelCategory: nil, group: transaction.group)
                    transactionsDict[transactionDetail] = [transaction]
                }
            case .none:
                if let index = transactionsDict.keys.firstIndex(where: {$0.name == transaction.category.rawValue && $0.level == .category && $0.category == transaction.category && $0.topLevelCategory == transaction.top_level_category && $0.group == transaction.group}) {
                    var transactionDetail = transactionsDict.keys[index]
                    var transactions = transactionsDict[transactionDetail]
                    
                    transactionsDict[transactionDetail] = nil
                    
                    transactionDetail.amount -= transaction.amount
                    transactions!.append(transaction)
                    
                    transactionsDict[transactionDetail] = transactions
                } else {
                    let transactionDetail = TransactionDetails(name: transaction.category.rawValue, amount: -transaction.amount, level: .category, category: transaction.category, topLevelCategory: transaction.top_level_category, group: transaction.group)
                    transactionsDict[transactionDetail] = [transaction]
                }
                if let index = transactionsDict.keys.firstIndex(where: {$0.name == transaction.top_level_category.rawValue && $0.level == .top && $0.topLevelCategory == transaction.top_level_category && $0.group == transaction.group}) {
                    var transactionDetail = transactionsDict.keys[index]
                    var transactions = transactionsDict[transactionDetail]
                    
                    transactionsDict[transactionDetail] = nil
                    
                    transactionDetail.amount -= transaction.amount
                    transactions!.append(transaction)
                    
                    transactionsDict[transactionDetail] = transactions
                } else {
                    let transactionDetail = TransactionDetails(name: transaction.top_level_category.rawValue, amount: -transaction.amount, level: .top, category: nil, topLevelCategory: transaction.top_level_category, group: transaction.group)
                    transactionsDict[transactionDetail] = [transaction]
                }
                if let index = transactionsDict.keys.firstIndex(where: {$0.name == transaction.group.rawValue && $0.level == .group && $0.group == transaction.group}) {
                    var transactionDetail = transactionsDict.keys[index]
                    var transactions = transactionsDict[transactionDetail]
                    
                    transactionsDict[transactionDetail] = nil
                    
                    transactionDetail.amount -= transaction.amount
                    transactions!.append(transaction)
                    
                    transactionsDict[transactionDetail] = transactions
                } else {
                    let transactionDetail = TransactionDetails(name: transaction.group.rawValue, amount: -transaction.amount, level: .group, category: nil, topLevelCategory: nil, group: transaction.group)
                    transactionsDict[transactionDetail] = [transaction]
                }
            }
        case "CREDIT":
            switch type {
            case .category:
                if let index = transactionsDict.keys.firstIndex(where: {$0.name == transaction.category.rawValue && $0.level == .category && $0.category == transaction.category && $0.topLevelCategory == transaction.top_level_category && $0.group == transaction.group}) {
                    var transactionDetail = transactionsDict.keys[index]
                    var transactions = transactionsDict[transactionDetail]
                    
                    transactionsDict[transactionDetail] = nil
                    
                    transactionDetail.amount += transaction.amount
                    transactions!.append(transaction)
                    
                    transactionsDict[transactionDetail] = transactions
                } else {
                    let transactionDetail = TransactionDetails(name: transaction.category.rawValue, amount: transaction.amount, level: .category, category: transaction.category, topLevelCategory: transaction.top_level_category, group: transaction.group)
                    transactionsDict[transactionDetail] = [transaction]
                }
            case .top:
                if let index = transactionsDict.keys.firstIndex(where: {$0.name == transaction.top_level_category.rawValue && $0.level == .top && $0.topLevelCategory == transaction.top_level_category && $0.group == transaction.group}) {
                    var transactionDetail = transactionsDict.keys[index]
                    var transactions = transactionsDict[transactionDetail]
                    
                    transactionsDict[transactionDetail] = nil
                    
                    transactionDetail.amount += transaction.amount
                    transactions!.append(transaction)
                    
                    transactionsDict[transactionDetail] = transactions
                } else {
                    let transactionDetail = TransactionDetails(name: transaction.top_level_category.rawValue, amount: transaction.amount, level: .top, category: nil, topLevelCategory: transaction.top_level_category, group: transaction.group)
                    transactionsDict[transactionDetail] = [transaction]
                }
            case .group:
                if let index = transactionsDict.keys.firstIndex(where: {$0.name == transaction.group.rawValue && $0.level == .group && $0.group == transaction.group}) {
                    var transactionDetail = transactionsDict.keys[index]
                    var transactions = transactionsDict[transactionDetail]
                    
                    transactionsDict[transactionDetail] = nil
                    
                    transactionDetail.amount += transaction.amount
                    transactions!.append(transaction)
                    
                    transactionsDict[transactionDetail] = transactions
                } else {
                    let transactionDetail = TransactionDetails(name: transaction.group.rawValue, amount: transaction.amount, level: .group, category: nil, topLevelCategory: nil, group: transaction.group)
                    transactionsDict[transactionDetail] = [transaction]
                }
            case .none:
                if let index = transactionsDict.keys.firstIndex(where: {$0.name == transaction.category.rawValue && $0.level == .category && $0.category == transaction.category && $0.topLevelCategory == transaction.top_level_category && $0.group == transaction.group}) {
                    var transactionDetail = transactionsDict.keys[index]
                    var transactions = transactionsDict[transactionDetail]
                    
                    transactionsDict[transactionDetail] = nil
                    
                    transactionDetail.amount += transaction.amount
                    transactions!.append(transaction)
                    
                    transactionsDict[transactionDetail] = transactions
                } else {
                    let transactionDetail = TransactionDetails(name: transaction.category.rawValue, amount: transaction.amount, level: .category, category: transaction.category, topLevelCategory: transaction.top_level_category, group: transaction.group)
                    transactionsDict[transactionDetail] = [transaction]
                }
                if let index = transactionsDict.keys.firstIndex(where: {$0.name == transaction.top_level_category.rawValue && $0.level == .top && $0.topLevelCategory == transaction.top_level_category && $0.group == transaction.group}) {
                    var transactionDetail = transactionsDict.keys[index]
                    var transactions = transactionsDict[transactionDetail]
                    
                    transactionsDict[transactionDetail] = nil
                    
                    transactionDetail.amount += transaction.amount
                    transactions!.append(transaction)
                    
                    transactionsDict[transactionDetail] = transactions
                } else {
                    let transactionDetail = TransactionDetails(name: transaction.top_level_category.rawValue, amount: transaction.amount, level: .top, category: nil, topLevelCategory: transaction.top_level_category, group: transaction.group)
                    transactionsDict[transactionDetail] = [transaction]
                }
                if let index = transactionsDict.keys.firstIndex(where: {$0.name == transaction.group.rawValue && $0.level == .group && $0.group == transaction.group}) {
                    var transactionDetail = transactionsDict.keys[index]
                    var transactions = transactionsDict[transactionDetail]
                    
                    transactionsDict[transactionDetail] = nil
                    
                    transactionDetail.amount += transaction.amount
                    transactions!.append(transaction)
                    
                    transactionsDict[transactionDetail] = transactions
                } else {
                    let transactionDetail = TransactionDetails(name: transaction.group.rawValue, amount: transaction.amount, level: .group, category: nil, topLevelCategory: nil, group: transaction.group)
                    transactionsDict[transactionDetail] = [transaction]
                }
            }
        default:
            continue
        }
    }
    transactionsList = Array(transactionsDict.keys)
    var sortedTransactionsList = [TransactionDetails]()
    if !transactionsList.isEmpty {
        var groupArray = transactionsList.map({ $0.group })
        if let index = groupArray.firstIndex(of: .income) {
            groupArray.remove(at: index)
            groupArray.insert(.income, at: 0)
            groupArray.insert(.expense, at: 1)
        } else {
            groupArray.insert(.expense, at: 0)
        }
        for group in groupArray {
            if group == .expense {
                var amount = 0.0
                var transactions = [Transaction]()
                
                let filteredTL = transactionsList.filter { ($0.level == .group && $0.group != .income) }
                for transactionDetail in filteredTL {
                    amount += transactionDetail.amount
                    transactions.append(contentsOf: transactionsDict[transactionDetail] ?? [])
                }
                
                let expenseTransactionDetail = TransactionDetails(name: group.rawValue, amount: amount, level: .group, category: nil, topLevelCategory: nil, group: group)
                
                sortedTransactionsList.append(expenseTransactionDetail)
                transactionsDict[expenseTransactionDetail] = transactions
                
                if let incomeTransactionDetail = transactionsList.first(where: { ($0.level == .group && $0.group == .income) }), let incomeTransactions = transactionsDict[incomeTransactionDetail] {
                    let diffAmount = incomeTransactionDetail.amount + expenseTransactionDetail.amount
                    let diffTransactions = incomeTransactions + transactions
                    let diffTransactionDetail = TransactionDetails(name: "Difference", amount: diffAmount, level: .group, category: nil, topLevelCategory: nil, group: .difference)
                    sortedTransactionsList.insert(diffTransactionDetail, at: 0)
                    transactionsDict[diffTransactionDetail] = diffTransactions
                } else {
                    let diffAmount = expenseTransactionDetail.amount
                    let diffTransactions = transactions
                    let diffTransactionDetail = TransactionDetails(name: "Difference", amount: diffAmount, level: .group, category: nil, topLevelCategory: nil, group: .difference)
                    sortedTransactionsList.insert(diffTransactionDetail, at: 0)
                    transactionsDict[diffTransactionDetail] = diffTransactions
                }
            }
            
            if let transactionDetail = transactionsList.first(where: {$0.level == .group && $0.group == group}) {
                if transactionDetail.amount != 0 {
                    sortedTransactionsList.append(transactionDetail)
                }
                for top in transactionsList.map({ $0.topLevelCategory }) {
                    if let transactionDetail = transactionsList.first(where: {$0.level == .top && $0.group == group && $0.topLevelCategory == top}) {
                        if transactionDetail.amount != 0 {
                            sortedTransactionsList.append(transactionDetail)
                        }
                        for cat in transactionsList.map({ $0.category }) {
                            if let transactionDetail = transactionsList.first(where: {$0.level == .category && $0.group == group && $0.topLevelCategory == top && $0.category == cat}) {
                                if transactionDetail.amount != 0 {
                                    sortedTransactionsList.append(transactionDetail)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    completion(sortedTransactionsList, transactionsDict)
}


