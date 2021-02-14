//
//  Transaction.swift
//  Plot
//
//  Created by Cory McHattie on 8/18/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

let userFinancialTransactionsEntity = "user-financial-transactions"
let financialTransactionsEntity = "financial-transactions"
let userFinancialTransactionsCategoriesEntity = "user-financial-transactions-categories"
let userFinancialTransactionsTopLevelCategoriesEntity = "user-financial-transactions-top-level-categories"
let userFinancialTransactionsGroupsEntity = "user-financial-transactions-groups"
let userFinancialTransactionRulesEntity = "user-financial-transaction-rules"

var financialTransactionsCategories = ["Auto Payment", "Auto Insurance", "Gas", "Parking", "Public Transportation", "Service & Parts", "Auto & Transport", "Domain Names", "Fraud Protection", "Home Phone", "Hosting", "Internet", "Mobile Phone", "Television", "Utilities", "Bills & Utilities", "Advertising", "Legal", "Office Supplies", "Printing", "Shipping", "Business Services", "Book Supplies", "Student Loans", "Tuition", "Education", "Amusement", "Arts", "Movies & DVDs", "Music", "Newspapers & Magazines", "Entertainment", "ATM Fee", "Banking Fee", "Finance Charge", "Late Fee", "Service Fee", "Trade Commissions", "Fees & Charges", "Financial Advisor", "Life Insurance", "Financial", "Alcohol & Bars", "Coffee Shops", "Fast Food", "Groceries", "Restaurants", "Food & Dining", "Charity", "Gift", "Gifts & Donations", "Dentist", "Doctor", "Eyecase", "Gym", "Health Insurance", "Pharmacy", "Sports", "Furnishings", "Home Improvement", "Home Services", "Home Supplies", "Lawn Garden", "Home", "Home Insurance", "Mortgage & Rent", "Bonus", "Interest Income", "Paycheck", "Reimbursement", "Rental Income", "Income", "Buy", "Dividend & Cap Gains", "Sell", "Deposit", "Withdrawal", "Allowance", "Baby Supplies", "Babysitter Daycare", "Child Support", "Kids Activities", "Toys", "Kids", "Hair", "Laundry", "Spa & Massage", "Personal Care", "Health & Fitness", "Pet Food & Supplies", "Pet Grooming", "Veterinary", "Pets", "Books", "Clothing", "Hobbies", "Sporting Goods", "Shopping", "Federal Tax", "Local Tax", "Property Tax", "Sales Tax", "State Tax", "Taxes", "Credit Card Payment", "Transfer for Cash Spending", "Transfer", "Mortgage Payment", "Air Travel", "Hotel", "Rental Car & Taxi", "Vacation", "Travel", "Cash", "Check", "Uncategorized", "Investments", "Electronics & Software"]
var financialTransactionsTopLevelCategories = ["Auto & Transport", "Bills & Utilities", "Business Services", "Education", "Electronics & Software", "Entertainment", "Fees & Charges", "Financial", "Food & Dining", "Gifts & Donations", "Health & Fitness", "Home", "Income", "Invesments", "Kids", "Personal Care", "Pets", "Shopping", "Taxes", "Transfer", "Travel", "Uncategorized"]
var financialTransactionsGroups = ["Income", "Bills", "Discretionary", "Kids", "Living", "Transfer", "Work", "Uncategorized"]

struct MXTransactionResult: Codable {
    let transaction: Transaction?
    let transactions: [Transaction]?
    let pagination: MXPagination?
}

struct Transaction: Codable, Equatable, Hashable {
    var account_guid: String?
    var account_name: String?
    var amount: Double
    var category: String
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
    var is_subscription: Bool?
    var latitude: Double?
    var longitude: Double?
    var member_guid: String?
    var memo: String?
    var merchant_category_code: Int?
    var merchant_guid: String?
    var original_description: String?
    var posted_at: String?
    var status: TransactionStatus
    var top_level_category: String
    var transacted_at: String
    var type: String?
    var updated_at: String
    var user_guid: String
    var participantsIDs: [String]?
    var date_for_reports: String?
    var user_created: Bool?
    var activityID: String?
    var tags: [String]?
    var should_link: Bool?
    var admin: String?
    var badge: Int?
    var pinned: Bool?
    var muted: Bool?
    var splitNumber: Int?
    var transactionDescription: String?
    var cash_flow_type: String {
        if type == "CREDIT" {
            return "Inflow"
        } else {
            return "Outflow"
        }
    }
    private var _group: String?
    var group: String {
        get {
            if let _group = _group {
                return _group
            } else {
                switch self.category {
                case "Auto Payment", "Auto Insurance": return "Bills"
                case "Gas", "Parking", "Public Transportation", "Service & Parts", "Auto & Transport": return "Living"
                case "Domain Names", "Fraud Protection", "Home Phone", "Hosting", "Internet", "Mobile Phone", "Television", "Utilities", "Bills & Utilities": return "Bills"
                case "Advertising", "Legal", "Office Supplies", "Printing", "Shipping", "Business Services": return "Living"
                case "Book Supplies", "Student Loans", "Tuition", "Education": return "Living"
                case "Amusement", "Arts", "Movies & DVDs", "Music", "Newspapers & Magazines", "Entertainment": return "Discretionary"
                case "ATM Fee", "Banking Fee", "Finance Charge", "Late Fee", "Service Fee", "Trade Commissions", "Fees & Charges": return "Bills"
                case "Financial Advisor", "Life Insurance", "Financial": return "Living"
                case "Alcohol & Bars", "Coffee Shops", "Fast Food", "Groceries", "Restaurants", "Food & Dining": return "Discretionary"
                case "Charity", "Gift", "Gifts & Donations": return "Living"
                case "Dentist", "Doctor", "Eyecase", "Gym", "Health Insurance", "Pharmacy", "Sports": return "Living"
                case "Furnishings", "Home Improvement", "Home Services", "Home Supplies", "Lawn Garden", "Home": return "Living"
                case "Home Insurance", "Mortgage & Rent": return "Bills"
                case "Bonus", "Interest Income", "Paycheck", "Reimbursement", "Rental Income", "Income": return "Income"
                case "Buy", "Dividend & Cap Gains", "Sell": return "Living"
                case "Deposit", "Withdrawal": return "Transfer"
                case "Allowance", "Baby Supplies", "Babysitter Daycare", "Child Support", "Kids Activities", "Toys", "Kids": return "Kids"
                case "Hair", "Laundry": return "Living"
                case "Spa & Massage": return "Discretionary"
                case "Personal Care", "Health & Fitness": return "Living"
                case "Pet Food & Supplies", "Pet Grooming", "Veterinary", "Pets": return "Living"
                case "Books", "Clothing", "Hobbies", "Sporting Goods", "Shopping": return "Discretionary"
                case "Federal Tax", "Local Tax", "Property Tax", "Sales Tax", "State Tax", "Taxes": return "Living"
                case "Credit Card Payment", "Transfer for Cash Spending", "Transfer", "Mortgage Payment": return "Transfer"
                case "Air Travel", "Hotel", "Rental Car & Taxi", "Vacation", "Travel": return "Discretionary"
                case "Cash", "Check", "Uncategorized": return "Uncategorized"
                case "Investments": return "Living"
                case "Electronics & Software": return "Discretionary"
                default:
                    return "Uncategorized"
                }
            }
        }
        set {
            _group = newValue
        }
    }
    
    init(description: String, amount: Double, created_at: String, guid: String, user_guid: String, status: TransactionStatus, category: String, top_level_category: String, user_created: Bool?, admin: String) {
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
        self.admin = admin
    }
}

struct UserTransaction: Codable, Equatable, Hashable {
    var description: String?
    var category: String?
    var top_level_category: String?
    var group: String?
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

//
//    var categoryLists: [TransactionCategory] {
//        switch self {
//        case .autoTransport: return ["Auto Insurance", "Auto Payment", "Gas", "Parking", "Public Transportation", "Service & Parts", .autoTransport]
//        case "Bills"Utilities: return ["Domain Names", "Fraud Protection", "Home Phone", "Hosting", "Internet", "Mobile Phone", "Television", "Utilities", "Bills"Utilities]
//        case .businessServices: return [.advertising, .legal, .officeSupplies, .printing, .shipping, .businessServices]
//        case .education: return [.booksSupplies, .studentLoan, .tuition, .education]
//        case .electronicsSoftware: return [.electronicsSoftware]
//        case .entertainment: return [.amusement, .arts, .moviesDvds, .music, .newspapersMagazines, .entertainment]
//        case .feesCharges: return [.atmFee, .bankingFee, .financeCharge, .lateFee, .serviceFee, .tradeCommissions, .feesCharges]
//        case .financial: return [.financialAdvisor, .lifeInsurance, .financial]
//        case .foodDining: return [.alcoholBars, .coffeeShops, .fastFood, .groceries, .restaurants, .foodDining]
//        case .giftsDonations: return [.charity, .gift, .giftsDonations]
//        case .healthFitness: return [.dentist, .doctor, .eyecare, .gym, .healthInsurance, .pharmacy, .sports, .healthFitness]
//        case .home: return [.furnishings, .homeImprovement, .homeInsurance, .homeServices, .homeSupplies, .lawnGarden, .mortgageRent, .home]
//        case "Income": return [.bonus, .interestIncome, .paycheck, .reimbursement, .rentalIncome, "Income"]
//        case .investments: return [.buy, .deposit, .dividendCapGains, .sell, .withdrawal, .investments]
//        case "Kids": return [.allowance, .babySupplies, .babysitterDaycare, .childSupport, "Kids"Activities, .toys, "Kids"]
//        case .personalCare: return [.hair, .laundry, .spaMassage, .personalCare]
//        case .pets: return [.petFoodSupplies, .petGrooming, .veterinary, .pets]
//        case .shopping: return [.books, .clothing, .hobbies, .sportingGoods, .shopping]
//        case .taxes: return [.federalTax, .localTax, .propertyTax, .salesTax, .stateTax, .taxes]
//        case "Transfer": return [.creditCardPayment, "Transfer"CashSpending, "Transfer", .mortgagePayment]
//        case .travel: return [.airTravel, .hotel, .rentalCarTaxi, .vacation, .travel]
//        case "Uncategorized": return [.cash, .check, "Uncategorized"]
//        }
//    }


struct TransactionDetails: Codable, Equatable, Hashable {
    var uuid = UUID().uuidString
    var name: String
    var amount: Double
    var level: TransactionCatLevel
    var category: String?
    var topLevelCategory: String?
    var group: String
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
    let user_guid: String?
    var category: String?
    var top_level_category: String?
    var group: String?
    var amount: Double?
    var should_link: Bool?
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

func categorizeTransactions(transactions: [Transaction], start: Date?, end: Date?, level: TransactionCatLevel?, completion: @escaping ([TransactionDetails], [TransactionDetails: [Transaction]]) -> ()) {
    var transactionsList = [TransactionDetails]()
    var transactionsDict = [TransactionDetails: [Transaction]]()
    // create dateFormatter with UTC time format
    let isodateFormatter = ISO8601DateFormatter()
    for transaction in transactions {
        guard transaction.should_link ?? true else { continue }
        if let date = transaction.date_for_reports, date != "", let transactionDate = isodateFormatter.date(from: date), let start = start, let end = end {
            if transactionDate < start || end < transactionDate {
                continue
            }
        } else if let transactionDate = isodateFormatter.date(from: transaction.transacted_at), let start = start, let end = end {
            if transactionDate < start || end < transactionDate {
                continue
            }
        }        
        switch transaction.type {
        case "DEBIT":
            switch level {
            case .category:
                if let index = transactionsDict.keys.firstIndex(where: {$0.name == transaction.category && $0.level == .category && $0.category == transaction.category && $0.topLevelCategory == transaction.top_level_category && $0.group == transaction.group}) {
                    var transactionDetail = transactionsDict.keys[index]
                    var transactions = transactionsDict[transactionDetail]
                    
                    transactionsDict[transactionDetail] = nil
                    
                    transactionDetail.amount -= transaction.amount
                    transactions!.append(transaction)
                    
                    transactionsDict[transactionDetail] = transactions
                } else {
                    let transactionDetail = TransactionDetails(name: transaction.category, amount: -transaction.amount, level: .category, category: transaction.category, topLevelCategory: transaction.top_level_category, group: transaction.group)
                    transactionsDict[transactionDetail] = [transaction]
                }
            case .top:
                if let index = transactionsDict.keys.firstIndex(where: {$0.name == transaction.top_level_category && $0.level == .top && $0.topLevelCategory == transaction.top_level_category && $0.group == transaction.group}) {
                    var transactionDetail = transactionsDict.keys[index]
                    var transactions = transactionsDict[transactionDetail]
                    
                    transactionsDict[transactionDetail] = nil
                    
                    transactionDetail.amount -= transaction.amount
                    transactions!.append(transaction)
                    
                    transactionsDict[transactionDetail] = transactions
                } else {
                    let transactionDetail = TransactionDetails(name: transaction.top_level_category, amount: -transaction.amount, level: .top, category: nil, topLevelCategory: transaction.top_level_category, group: transaction.group)
                    transactionsDict[transactionDetail] = [transaction]
                }
            case .group:
                if let index = transactionsDict.keys.firstIndex(where: {$0.name == transaction.group && $0.level == .group && $0.group == transaction.group}) {
                    var transactionDetail = transactionsDict.keys[index]
                    var transactions = transactionsDict[transactionDetail]
                    
                    transactionsDict[transactionDetail] = nil
                    
                    transactionDetail.amount -= transaction.amount
                    transactions!.append(transaction)
                    
                    transactionsDict[transactionDetail] = transactions
                } else {
                    let transactionDetail = TransactionDetails(name: transaction.group, amount: -transaction.amount, level: .group, category: nil, topLevelCategory: nil, group: transaction.group)
                    transactionsDict[transactionDetail] = [transaction]
                }
            case .none:
                if let index = transactionsDict.keys.firstIndex(where: {$0.name == transaction.category && $0.level == .category && $0.category == transaction.category && $0.topLevelCategory == transaction.top_level_category && $0.group == transaction.group}) {
                    var transactionDetail = transactionsDict.keys[index]
                    var transactions = transactionsDict[transactionDetail]
                    
                    transactionsDict[transactionDetail] = nil
                    
                    transactionDetail.amount -= transaction.amount
                    transactions!.append(transaction)
                    
                    transactionsDict[transactionDetail] = transactions
                } else {
                    let transactionDetail = TransactionDetails(name: transaction.category, amount: -transaction.amount, level: .category, category: transaction.category, topLevelCategory: transaction.top_level_category, group: transaction.group)
                    transactionsDict[transactionDetail] = [transaction]
                }
                if let index = transactionsDict.keys.firstIndex(where: {$0.name == transaction.top_level_category && $0.level == .top && $0.topLevelCategory == transaction.top_level_category && $0.group == transaction.group}) {
                    var transactionDetail = transactionsDict.keys[index]
                    var transactions = transactionsDict[transactionDetail]
                    
                    transactionsDict[transactionDetail] = nil
                    
                    transactionDetail.amount -= transaction.amount
                    transactions!.append(transaction)
                    
                    transactionsDict[transactionDetail] = transactions
                } else {
                    let transactionDetail = TransactionDetails(name: transaction.top_level_category, amount: -transaction.amount, level: .top, category: nil, topLevelCategory: transaction.top_level_category, group: transaction.group)
                    transactionsDict[transactionDetail] = [transaction]
                }
                if let index = transactionsDict.keys.firstIndex(where: {$0.name == transaction.group && $0.level == .group && $0.group == transaction.group}) {
                    var transactionDetail = transactionsDict.keys[index]
                    var transactions = transactionsDict[transactionDetail]
                    
                    transactionsDict[transactionDetail] = nil
                    
                    transactionDetail.amount -= transaction.amount
                    transactions!.append(transaction)
                    
                    transactionsDict[transactionDetail] = transactions
                } else {
                    let transactionDetail = TransactionDetails(name: transaction.group, amount: -transaction.amount, level: .group, category: nil, topLevelCategory: nil, group: transaction.group)
                    transactionsDict[transactionDetail] = [transaction]
                }
            }
        case "CREDIT":
            switch level {
            case .category:
                if let index = transactionsDict.keys.firstIndex(where: {$0.name == transaction.category && $0.level == .category && $0.category == transaction.category && $0.topLevelCategory == transaction.top_level_category && $0.group == transaction.group}) {
                    var transactionDetail = transactionsDict.keys[index]
                    var transactions = transactionsDict[transactionDetail]
                    
                    transactionsDict[transactionDetail] = nil
                    
                    transactionDetail.amount += transaction.amount
                    transactions!.append(transaction)
                    
                    transactionsDict[transactionDetail] = transactions
                } else {
                    let transactionDetail = TransactionDetails(name: transaction.category, amount: transaction.amount, level: .category, category: transaction.category, topLevelCategory: transaction.top_level_category, group: transaction.group)
                    transactionsDict[transactionDetail] = [transaction]
                }
            case .top:
                if let index = transactionsDict.keys.firstIndex(where: {$0.name == transaction.top_level_category && $0.level == .top && $0.topLevelCategory == transaction.top_level_category && $0.group == transaction.group}) {
                    var transactionDetail = transactionsDict.keys[index]
                    var transactions = transactionsDict[transactionDetail]
                    
                    transactionsDict[transactionDetail] = nil
                    
                    transactionDetail.amount += transaction.amount
                    transactions!.append(transaction)
                    
                    transactionsDict[transactionDetail] = transactions
                } else {
                    let transactionDetail = TransactionDetails(name: transaction.top_level_category, amount: transaction.amount, level: .top, category: nil, topLevelCategory: transaction.top_level_category, group: transaction.group)
                    transactionsDict[transactionDetail] = [transaction]
                }
            case .group:
                if let index = transactionsDict.keys.firstIndex(where: {$0.name == transaction.group && $0.level == .group && $0.group == transaction.group}) {
                    var transactionDetail = transactionsDict.keys[index]
                    var transactions = transactionsDict[transactionDetail]
                    
                    transactionsDict[transactionDetail] = nil
                    
                    transactionDetail.amount += transaction.amount
                    transactions!.append(transaction)
                    
                    transactionsDict[transactionDetail] = transactions
                } else {
                    let transactionDetail = TransactionDetails(name: transaction.group, amount: transaction.amount, level: .group, category: nil, topLevelCategory: nil, group: transaction.group)
                    transactionsDict[transactionDetail] = [transaction]
                }
            case .none:
                if let index = transactionsDict.keys.firstIndex(where: {$0.name == transaction.category && $0.level == .category && $0.category == transaction.category && $0.topLevelCategory == transaction.top_level_category && $0.group == transaction.group}) {
                    var transactionDetail = transactionsDict.keys[index]
                    var transactions = transactionsDict[transactionDetail]
                    
                    transactionsDict[transactionDetail] = nil
                    
                    transactionDetail.amount += transaction.amount
                    transactions!.append(transaction)
                    
                    transactionsDict[transactionDetail] = transactions
                } else {
                    let transactionDetail = TransactionDetails(name: transaction.category, amount: transaction.amount, level: .category, category: transaction.category, topLevelCategory: transaction.top_level_category, group: transaction.group)
                    transactionsDict[transactionDetail] = [transaction]
                }
                if let index = transactionsDict.keys.firstIndex(where: {$0.name == transaction.top_level_category && $0.level == .top && $0.topLevelCategory == transaction.top_level_category && $0.group == transaction.group}) {
                    var transactionDetail = transactionsDict.keys[index]
                    var transactions = transactionsDict[transactionDetail]
                    
                    transactionsDict[transactionDetail] = nil
                    
                    transactionDetail.amount += transaction.amount
                    transactions!.append(transaction)
                    
                    transactionsDict[transactionDetail] = transactions
                } else {
                    let transactionDetail = TransactionDetails(name: transaction.top_level_category, amount: transaction.amount, level: .top, category: nil, topLevelCategory: transaction.top_level_category, group: transaction.group)
                    transactionsDict[transactionDetail] = [transaction]
                }
                if let index = transactionsDict.keys.firstIndex(where: {$0.name == transaction.group && $0.level == .group && $0.group == transaction.group}) {
                    var transactionDetail = transactionsDict.keys[index]
                    var transactions = transactionsDict[transactionDetail]
                    
                    transactionsDict[transactionDetail] = nil
                    
                    transactionDetail.amount += transaction.amount
                    transactions!.append(transaction)
                    
                    transactionsDict[transactionDetail] = transactions
                } else {
                    let transactionDetail = TransactionDetails(name: transaction.group, amount: transaction.amount, level: .group, category: nil, topLevelCategory: nil, group: transaction.group)
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
        var groupArray = Array(Set(transactionsList.compactMap({ $0.group })))
        groupArray.sort()
        var topLevelCategoryArray = Array(Set(transactionsList.compactMap({ $0.topLevelCategory })))
        topLevelCategoryArray.sort()
        var categoryArray = Array(Set(transactionsList.compactMap({ $0.category })))
        categoryArray.sort()
        if let index = groupArray.firstIndex(of: "Income") {
            groupArray.remove(at: index)
            groupArray.insert("Income", at: 0)
            groupArray.insert("Expense", at: 1)
        } else {
            groupArray.insert("Expense", at: 0)
        }
        for group in groupArray {
            if group == "Expense" {
                var amount = 0.0
                var transactions = [Transaction]()
                
                let filteredTL = transactionsList.filter { ($0.level == .group && $0.group != "Income") }
                for transactionDetail in filteredTL {
                    amount += transactionDetail.amount
                    transactions.append(contentsOf: transactionsDict[transactionDetail] ?? [])
                }
                
                let expenseTransactionDetail = TransactionDetails(name: group, amount: amount, level: .group, category: nil, topLevelCategory: nil, group: group)
                
                if amount != 0.0 {
                    sortedTransactionsList.append(expenseTransactionDetail)
                    transactionsDict[expenseTransactionDetail] = transactions
                }
                
                if let incomeTransactionDetail = transactionsList.first(where: { ($0.level == .group && $0.group == "Income") }), let incomeTransactions = transactionsDict[incomeTransactionDetail] {
                    let diffAmount = incomeTransactionDetail.amount + expenseTransactionDetail.amount
                    let diffTransactions = incomeTransactions + transactions
                    let diffTransactionDetail = TransactionDetails(name: "Difference", amount: diffAmount, level: .group, category: nil, topLevelCategory: nil, group: "Difference")
                    sortedTransactionsList.insert(diffTransactionDetail, at: 0)
                    transactionsDict[diffTransactionDetail] = diffTransactions
                }
            }
            
            if let transactionDetail = transactionsList.first(where: {$0.level == .group && $0.group == group}) {
                if transactionDetail.amount != 0 {
                    sortedTransactionsList.append(transactionDetail)
                }
                for top in Array(Set(transactionsList.map({ $0.topLevelCategory }))) {
                    if let transactionDetail = transactionsList.first(where: {$0.level == .top && $0.group == group && $0.topLevelCategory == top}) {
                        if transactionDetail.amount != 0 {
                            sortedTransactionsList.append(transactionDetail)
                        }
                        for cat in Array(Set(transactionsList.map({ $0.category }))) {
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

func transactionDetailsOverTimeChartData(transactions: [Transaction], transactionDetails: [TransactionDetails], start: Date, end: Date, segmentType: TimeSegmentType, completion: @escaping ([TransactionDetails: [Statistic]], [TransactionDetails: [Transaction]]) -> ()) {
    var statistics = [TransactionDetails: [Statistic]]()
    var transactionDict = [TransactionDetails: [Transaction]]()
    let calendar = NSCalendar(calendarIdentifier: NSCalendar.Identifier.gregorian)!
    calendar.timeZone = TimeZone(secondsFromGMT: 0)!
    var date = start
    switch segmentType {
    case .day:
        var nextDate = calendar.date(byAdding: .hour, value: 1, to: date, options: [])!
        // While date <= endDate ...
        while nextDate.compare(end) != .orderedDescending {
            for transactionDetail in transactionDetails {
                transactionListStats(transactions: transactions, transactionDetail: transactionDetail, start: start, end: end, date: date, nextDate: nextDate) { (stats, transactions) in
                    if statistics[transactionDetail] != nil, transactionDict[transactionDetail] != nil {
                        var tdStats = statistics[transactionDetail]
                        var tdTransactionList = transactionDict[transactionDetail]
                        tdStats!.append(contentsOf: stats)
                        tdTransactionList!.append(contentsOf: transactions)
                        statistics[transactionDetail] = tdStats
                        transactionDict[transactionDetail] = tdTransactionList
                    } else {
                        statistics[transactionDetail] = stats
                        transactionDict[transactionDetail] = transactions
                    }
                }
            }
            // Advance by one day:
            date = nextDate
            nextDate = calendar.date(byAdding: .hour, value: 1, to: nextDate, options: [])!
        }
    case .week:
        var nextDate = calendar.date(byAdding: .day, value: 1, to: date, options: [])!
        // While date <= endDate ...
        while nextDate.compare(end) != .orderedDescending {
            for transactionDetail in transactionDetails {
                transactionListStats(transactions: transactions, transactionDetail: transactionDetail, start: start, end: end, date: date, nextDate: nextDate) { (stats, transactions) in
                    if statistics[transactionDetail] != nil, transactionDict[transactionDetail] != nil {
                        var tdStats = statistics[transactionDetail]
                        var tdTransactionList = transactionDict[transactionDetail]
                        tdStats!.append(contentsOf: stats)
                        tdTransactionList!.append(contentsOf: transactions)
                        statistics[transactionDetail] = tdStats
                        transactionDict[transactionDetail] = tdTransactionList
                    } else {
                        statistics[transactionDetail] = stats
                        transactionDict[transactionDetail] = transactions
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
            for transactionDetail in transactionDetails {
                transactionListStats(transactions: transactions, transactionDetail: transactionDetail, start: start, end: end, date: date, nextDate: nextDate) { (stats, transactions) in
                    if statistics[transactionDetail] != nil, transactionDict[transactionDetail] != nil {
                        var tdStats = statistics[transactionDetail]
                        var tdTransactionList = transactionDict[transactionDetail]
                        tdStats!.append(contentsOf: stats)
                        tdTransactionList!.append(contentsOf: transactions)
                        statistics[transactionDetail] = tdStats
                        transactionDict[transactionDetail] = tdTransactionList
                    } else {
                        statistics[transactionDetail] = stats
                        transactionDict[transactionDetail] = transactions
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
            for transactionDetail in transactionDetails {
                transactionListStats(transactions: transactions, transactionDetail: transactionDetail, start: start, end: end, date: date, nextDate: nextDate) { (stats, transactions) in
                    if statistics[transactionDetail] != nil, transactionDict[transactionDetail] != nil {
                        var tdStats = statistics[transactionDetail]
                        var tdTransactionList = transactionDict[transactionDetail]
                        tdStats!.append(contentsOf: stats)
                        tdTransactionList!.append(contentsOf: transactions)
                        statistics[transactionDetail] = tdStats
                        transactionDict[transactionDetail] = tdTransactionList
                    } else {
                        statistics[transactionDetail] = stats
                        transactionDict[transactionDetail] = transactions
                    }
                }
            }
            
            // Advance by one day:
            date = nextDate
            nextDate = calendar.date(byAdding: .month, value: 1, to: nextDate, options: [])!
        }
    }
    completion(statistics, transactionDict)
}

func transactionListStats(transactions: [Transaction], transactionDetail: TransactionDetails, start: Date, end: Date, date: Date, nextDate: Date, completion: @escaping ([Statistic], [Transaction]) -> ()) {
    var statistics = [Statistic]()
    var transactionList = [Transaction]()
    let isodateFormatter = ISO8601DateFormatter()
    for transaction in transactions {
        guard transaction.should_link ?? true else { continue }
        if let date_for_reports = transaction.date_for_reports, date_for_reports != "", let transactionDate = isodateFormatter.date(from: date_for_reports) {
            if transactionDate < start || end < transactionDate {
                continue
            }
        } else if let transactionDate = isodateFormatter.date(from: transaction.transacted_at) {
            if transactionDate < start || end < transactionDate {
                continue
            }
        }
        if let date_for_reports = transaction.date_for_reports, date_for_reports != "", let transactionDate = isodateFormatter.date(from: date_for_reports) {
            if transactionDate < date || nextDate < transactionDate {
                continue
            }
        } else if let transactionDate = isodateFormatter.date(from: transaction.transacted_at) {
            if transactionDate < date || nextDate < transactionDate {
                continue
            }
        }
        
        if transactionDetail.name == "Difference" {
            switch transaction.type {
            case "DEBIT":
                if statistics.isEmpty {
                    let stat = Statistic(date: nextDate, value: -transaction.amount)
                    statistics.append(stat)
                    transactionList.append(transaction)
                } else {
                    if let index = statistics.firstIndex(where: {$0.date == nextDate}) {
                        statistics[index].value -= transaction.amount
                        transactionList.append(transaction)
                    }
                }
            case "CREDIT":
                if statistics.isEmpty {
                    let stat = Statistic(date: nextDate, value: transaction.amount)
                    statistics.append(stat)
                    transactionList.append(transaction)
                } else {
                    if let index = statistics.firstIndex(where: {$0.date == nextDate}) {
                        statistics[index].value += transaction.amount
                        transactionList.append(transaction)
                    }
                }
            default:
                continue
            }
        } else if transactionDetail.name == "Expense" && transaction.group != "Income" {
            switch transaction.type {
            case "DEBIT":
                if statistics.isEmpty {
                    let stat = Statistic(date: nextDate, value: transaction.amount)
                    statistics.append(stat)
                    transactionList.append(transaction)
                } else {
                    if let index = statistics.firstIndex(where: {$0.date == nextDate}) {
                        statistics[index].value += transaction.amount
                        transactionList.append(transaction)
                    }
                }
            case "CREDIT":
                if statistics.isEmpty {
                    let stat = Statistic(date: nextDate, value: -transaction.amount)
                    statistics.append(stat)
                    transactionList.append(transaction)
                } else {
                    if let index = statistics.firstIndex(where: {$0.date == nextDate}) {
                        statistics[index].value -= transaction.amount
                        transactionList.append(transaction)
                    }
                }
            default:
                continue
            }
        } else if transactionDetail.level == .category && transactionDetail.name == transaction.category {
            if transaction.group == "Income" {
                switch transaction.type {
                case "DEBIT":
                    if statistics.isEmpty {
                        let stat = Statistic(date: nextDate, value: -transaction.amount)
                        statistics.append(stat)
                        transactionList.append(transaction)
                    } else {
                        if let index = statistics.firstIndex(where: {$0.date == nextDate}) {
                            statistics[index].value -= transaction.amount
                            transactionList.append(transaction)
                        }
                    }
                case "CREDIT":
                    if statistics.isEmpty {
                        let stat = Statistic(date: nextDate, value: transaction.amount)
                        statistics.append(stat)
                        transactionList.append(transaction)
                    } else {
                        if let index = statistics.firstIndex(where: {$0.date == nextDate}) {
                            statistics[index].value += transaction.amount
                            transactionList.append(transaction)
                        }
                    }
                default:
                    continue
                }
            } else {
                switch transaction.type {
                case "DEBIT":
                    if statistics.isEmpty {
                        let stat = Statistic(date: nextDate, value: transaction.amount)
                        statistics.append(stat)
                        transactionList.append(transaction)
                    } else {
                        if let index = statistics.firstIndex(where: {$0.date == nextDate}) {
                            statistics[index].value += transaction.amount
                            transactionList.append(transaction)
                        }
                    }
                case "CREDIT":
                    if statistics.isEmpty {
                        let stat = Statistic(date: nextDate, value: -transaction.amount)
                        statistics.append(stat)
                        transactionList.append(transaction)
                    } else {
                        if let index = statistics.firstIndex(where: {$0.date == nextDate}) {
                            statistics[index].value -= transaction.amount
                            transactionList.append(transaction)
                        }
                    }
                default:
                    continue
                }
            }
        } else if transactionDetail.level == .top && transactionDetail.name == transaction.top_level_category {
            if transaction.group == "Income" {
                switch transaction.type {
                case "DEBIT":
                    if statistics.isEmpty {
                        let stat = Statistic(date: nextDate, value: -transaction.amount)
                        statistics.append(stat)
                        transactionList.append(transaction)
                    } else {
                        if let index = statistics.firstIndex(where: {$0.date == nextDate}) {
                            statistics[index].value -= transaction.amount
                            transactionList.append(transaction)
                        }
                    }
                case "CREDIT":
                    if statistics.isEmpty {
                        let stat = Statistic(date: nextDate, value: transaction.amount)
                        statistics.append(stat)
                        transactionList.append(transaction)
                    } else {
                        if let index = statistics.firstIndex(where: {$0.date == nextDate}) {
                            statistics[index].value += transaction.amount
                            transactionList.append(transaction)
                        }
                    }
                default:
                    continue
                }
            } else {
                switch transaction.type {
                case "DEBIT":
                    if statistics.isEmpty {
                        let stat = Statistic(date: nextDate, value: transaction.amount)
                        statistics.append(stat)
                        transactionList.append(transaction)
                    } else {
                        if let index = statistics.firstIndex(where: {$0.date == nextDate}) {
                            statistics[index].value += transaction.amount
                            transactionList.append(transaction)
                        }
                    }
                case "CREDIT":
                    if statistics.isEmpty {
                        let stat = Statistic(date: nextDate, value: -transaction.amount)
                        statistics.append(stat)
                        transactionList.append(transaction)
                    } else {
                        if let index = statistics.firstIndex(where: {$0.date == nextDate}) {
                            statistics[index].value -= transaction.amount
                            transactionList.append(transaction)
                        }
                    }
                default:
                    continue
                }
            }
        } else if transactionDetail.level == .group && transactionDetail.name == transaction.group {
            if transaction.group == "Income" {
                switch transaction.type {
                case "DEBIT":
                    if statistics.isEmpty {
                        let stat = Statistic(date: nextDate, value: -transaction.amount)
                        statistics.append(stat)
                        transactionList.append(transaction)
                    } else {
                        if let index = statistics.firstIndex(where: {$0.date == nextDate}) {
                            statistics[index].value -= transaction.amount
                            transactionList.append(transaction)
                        }
                    }
                case "CREDIT":
                    if statistics.isEmpty {
                        let stat = Statistic(date: nextDate, value: transaction.amount)
                        statistics.append(stat)
                        transactionList.append(transaction)
                    } else {
                        if let index = statistics.firstIndex(where: {$0.date == nextDate}) {
                            statistics[index].value += transaction.amount
                            transactionList.append(transaction)
                        }
                    }
                default:
                    continue
                }
            } else {
                switch transaction.type {
                case "DEBIT":
                    if statistics.isEmpty {
                        let stat = Statistic(date: nextDate, value: transaction.amount)
                        statistics.append(stat)
                        transactionList.append(transaction)
                    } else {
                        if let index = statistics.firstIndex(where: {$0.date == nextDate}) {
                            statistics[index].value += transaction.amount
                            transactionList.append(transaction)
                        }
                    }
                case "CREDIT":
                    if statistics.isEmpty {
                        let stat = Statistic(date: nextDate, value: -transaction.amount)
                        statistics.append(stat)
                        transactionList.append(transaction)
                    } else {
                        if let index = statistics.firstIndex(where: {$0.date == nextDate}) {
                            statistics[index].value -= transaction.amount
                            transactionList.append(transaction)
                        }
                    }
                default:
                    continue
                }
            }
        }
    }
    completion(statistics, transactionList)
}

func updateTransactionWRule(transaction: Transaction, transactionRules: [TransactionRule], completion: @escaping (Transaction, Bool) -> ()) {
    var bool = false
    var _transaction = transaction
    for rule in transactionRules {
        if transaction.description.lowercased().contains(rule.match_description.lowercased()) {
            bool = true
            if rule.amount != nil, rule.amount == _transaction.amount {
                if rule.description != nil {
                    _transaction.description = rule.description!
                }
                if rule.should_link != nil {
                    _transaction.should_link = rule.should_link
                }
                _transaction.group = rule.group ?? "Uncategorized"
                _transaction.top_level_category = rule.top_level_category ?? "Uncategorized"
                _transaction.category = rule.category ?? "Uncategorized"
            } else if rule.amount == nil {
                if rule.description != nil {
                    _transaction.description = rule.description!
                }
                if rule.should_link != nil {
                    _transaction.should_link = rule.should_link
                }
                _transaction.group = rule.group ?? "Uncategorized"
                _transaction.top_level_category = rule.top_level_category ?? "Uncategorized"
                _transaction.category = rule.category ?? "Uncategorized"
            }
        }
    }
    completion(_transaction, bool)
}

