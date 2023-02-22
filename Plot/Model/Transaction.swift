//
//  Transaction.swift
//  Plot
//
//  Created by Cory McHattie on 8/18/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import Foundation

let userFinancialTransactionsEntity = "user-financial-transactions"
let financialTransactionsEntity = "financial-transactions"
let userFinancialTransactionsCategoriesEntity = "user-financial-transactions-categories"
let userFinancialTransactionsTopLevelCategoriesEntity = "user-financial-transactions-top-level-categories"
let userFinancialTransactionsGroupsEntity = "user-financial-transactions-groups"
let userFinancialTransactionRulesEntity = "user-financial-transaction-rules"
let userFinancialTransactionsEventsEntity = "user-financial-transactions-events"
let userFinancialTransactionsTasksEntity = "user-financial-transactions-tasks"

var financialTransactionsGroupsStatic = ["Income", "Bills", "Discretionary", "Kids", "Living", "Transfer", "Work", "Uncategorized"]

var financialTransactionsTopLevelCategoriesStatic = ["Auto & Transport", "Bills & Utilities", "Business Services", "Education", "Entertainment", "Fees & Charges", "Financial", "Food & Dining", "Gifts & Donations", "Health & Fitness", "Home", "Income", "Invesments", "Kids", "Personal Care", "Pets", "Shopping", "Taxes", "Transfer", "Travel", "Uncategorized"]
var financialTransactionsTopLevelCategoriesDictionaryStatic = ["Auto & Transport": ["Auto Payment", "Auto Insurance", "Gas", "Parking", "Public Transportation", "Service & Parts", "Auto & Transport"], "Bills & Utilities": ["Domain Names", "Fraud Protection", "Home Phone", "Hosting", "Internet", "Mobile Phone", "Television", "Utilities", "Bills & Utilities"], "Business Services": ["Advertising", "Legal", "Office Supplies", "Printing", "Shipping", "Business Services"], "Education": ["Book Supplies", "Student Loans", "Tuition", "Education"], "Entertainment": ["Amusement", "Arts", "Movies & DVDs", "Music", "Newspapers & Magazines", "Entertainment"], "Fees & Charges": ["ATM Fee", "Banking Fee", "Finance Charge", "Late Fee", "Service Fee", "Trade Commissions", "Fees & Charges"], "Financial": ["Financial Advisor", "Life Insurance", "Financial"], "Food & Dining": ["Alcohol & Bars", "Coffee Shops", "Fast Food", "Groceries", "Restaurants", "Food & Dining"], "Gifts & Donations": ["Charity", "Gift", "Gifts & Donations"], "Health & Fitness": ["Dentist", "Doctor", "Eyecare", "Gym", "Health Insurance", "Pharmacy", "Sports", "Health & Fitness"], "Home": ["Furnishings", "Home Improvement", "Home Insurance", "Home Services", "Home Supplies", "Lawn & Garden", "Mortgage & Rent", "Home"], "Income": ["Bonus", "Interest Income", "Paycheck", "Reimbursement", "Rental Income", "Income"], "Invesments": ["Buy", "Deposit", "Dividend & Cap Gains", "Sell", "Withdrawal", "Investments"], "Kids": ["Allowance", "Baby Supplies", "Babysitter & Daycare", "Child Support", "Kids Activities", "Toys", "Kids"], "Personal Care": ["Hair", "Laundry", "Spa & Massage", "Personal Care"], "Pets": ["Pet Food & Supplies", "Pet Grooming", "Veterinary", "Pets"], "Shopping": ["Books", "Clothing", "Hobbies", "Sporting Goods", "Shopping"], "Taxes": ["Federal Tax", "Local Tax", "Property Tax", "Sales Tax", "State Tax", "Taxes"], "Transfer": ["Credit Card Payment", "Transfer for Cash Spending", "Mortgage Payment", "Transfer"], "Travel": ["Air Travel", "Hotel", "Rental Car & Taxi", "Vacation", "Travel"], "Uncategorized": ["Cash", "Check", "Uncategorized"]]

var financialTransactionsCategoriesStatic = ["Auto Payment", "Auto Insurance", "Gas", "Parking", "Public Transportation", "Service & Parts", "Auto & Transport", "Domain Names", "Fraud Protection", "Home Phone", "Hosting", "Internet", "Mobile Phone", "Television", "Utilities", "Bills & Utilities", "Advertising", "Legal", "Office Supplies", "Printing", "Shipping", "Business Services", "Book Supplies", "Student Loans", "Tuition", "Education", "Amusement", "Arts", "Movies & DVDs", "Music", "Newspapers & Magazines", "Entertainment", "ATM Fee", "Banking Fee", "Finance Charge", "Late Fee", "Service Fee", "Trade Commissions", "Fees & Charges", "Financial Advisor", "Life Insurance", "Financial", "Alcohol & Bars", "Coffee Shops", "Fast Food", "Groceries", "Restaurants", "Food & Dining", "Charity", "Gift", "Gifts & Donations", "Dentist", "Doctor", "Eyecare", "Gym", "Health Insurance", "Pharmacy", "Sports", "Health & Fitness", "Furnishings", "Home Improvement", "Home Insurance", "Home Services", "Home Supplies", "Lawn & Garden", "Mortgage & Rent", "Home", "Bonus", "Interest Income", "Paycheck", "Reimbursement", "Rental Income", "Income", "Buy", "Deposit", "Dividend & Cap Gains", "Sell", "Withdrawal", "Investments", "Allowance", "Baby Supplies", "Babysitter & Daycare", "Child Support", "Kids Activities", "Toys", "Kids", "Hair", "Laundry", "Spa & Massage", "Personal Care", "Pet Food & Supplies", "Pet Grooming", "Veterinary", "Pets", "Books", "Clothing", "Hobbies", "Sporting Goods", "Shopping", "Federal Tax", "Local Tax", "Property Tax", "Sales Tax", "State Tax", "Taxes", "Credit Card Payment", "Transfer for Cash Spending", "Mortgage Payment", "Transfer", "Air Travel", "Hotel", "Rental Car & Taxi", "Vacation", "Travel", "Cash", "Check", "Uncategorized"]
var financialTransactionsCategoriesDictionaryStatic = ["Auto Payment": "Auto & Transport", "Auto Insurance": "Auto & Transport", "Gas": "Auto & Transport", "Parking": "Auto & Transport", "Public Transportation": "Auto & Transport", "Service & Parts": "Auto & Transport", "Auto & Transport": "Auto & Transport", "Domain Names": "Bills & Utilities", "Fraud Protection": "Bills & Utilities", "Home Phone": "Bills & Utilities", "Hosting": "Bills & Utilities", "Internet": "Bills & Utilities", "Mobile Phone": "Bills & Utilities", "Television": "Bills & Utilities", "Utilities": "Bills & Utilities", "Bills & Utilities": "Bills & Utilities", "Advertising": "Business Services", "Legal": "Business Services", "Office Supplies": "Business Services", "Printing": "Business Services", "Shipping": "Business Services", "Business Services": "Business Services", "Book Supplies": "Education", "Student Loans": "Education", "Tuition": "Education", "Education": "Education", "Amusement": "Entertainment", "Arts": "Entertainment", "Movies & DVDs": "Entertainment", "Music": "Entertainment", "Newspapers & Magazines": "Entertainment", "Entertainment": "Entertainment", "ATM Fee": "Fees & Charges", "Banking Fee": "Fees & Charges", "Finance Charge": "Fees & Charges", "Late Fee": "Fees & Charges", "Service Fee": "Fees & Charges", "Trade Commissions": "Fees & Charges", "Fees & Charges": "Fees & Charges", "Financial Advisor": "Financial", "Life Insurance": "Financial", "Financial": "Financial", "Alcohol & Bars": "Food & Dining", "Coffee Shops": "Food & Dining", "Fast Food": "Food & Dining", "Groceries": "Food & Dining", "Restaurants": "Food & Dining", "Food & Dining": "Food & Dining", "Charity": "Gifts & Donations", "Gift": "Gifts & Donations", "Gifts & Donations": "Gifts & Donations", "Dentist": "Health & Fitness", "Doctor": "Health & Fitness", "Eyecare": "Health & Fitness", "Gym": "Health & Fitness", "Health Insurance": "Health & Fitness", "Pharmacy": "Health & Fitness", "Sports": "Health & Fitness", "Health & Fitness": "Health & Fitness", "Furnishings": "Home", "Home Improvement": "Home", "Home Insurance": "Home", "Home Services": "Home", "Home Supplies": "Home", "Lawn & Garden": "Home", "Mortgage & Rent": "Home", "Home": "Home", "Bonus": "Income", "Interest Income": "Income", "Paycheck": "Income", "Reimbursement": "Income", "Rental Income": "Income", "Income": "Income", "Buy": "Investments", "Deposit": "Investments", "Dividend & Cap Gains": "Investments", "Sell": "Investments", "Withdrawal": "Investments", "Investments": "Investments", "Allowance": "Kids", "Baby Supplies": "Kids", "Babysitter & Daycare": "Kids", "Child Support": "Kids", "Kids Activities": "Kids", "Toys": "Kids", "Kids": "Kids", "Hair": "Personal Care", "Laundry": "Personal Care", "Spa & Massage": "Personal Care", "Personal Care": "Personal Care", "Pet Food & Supplies": "Pets", "Pet Grooming": "Pets", "Veterinary": "Pets", "Pets": "Pets", "Books": "Shopping", "Clothing": "Shopping", "Hobbies": "Shopping", "Sporting Goods": "Shopping", "Shopping": "Shopping", "Federal Tax": "Taxes", "Local Tax": "Taxes", "Property Tax": "Taxes", "Sales Tax": "Taxes", "State Tax": "Taxes", "Taxes": "Taxes", "Credit Card Payment": "Transfer", "Transfer for Cash Spending": "Transfer", "Mortgage Payment": "Transfer", "Transfer": "Transfer", "Air Travel": "Travel", "Hotel": "Travel", "Rental Car & Taxi": "Travel", "Vacation": "Travel", "Travel": "Travel", "Cash": "Uncategorized", "Check": "Uncategorized", "Uncategorized": "Uncategorized"]

var financialTransactionsGroupsWExpense = ["Net Savings", "Income", "Expense", "Bills", "Discretionary", "Kids", "Living", "Transfer", "Work"]
var financialTransactionsTopLevelCategoriesStaticWOUncategorized = ["Income", "Auto & Transport", "Bills & Utilities", "Business Services", "Education", "Entertainment", "Fees & Charges", "Financial", "Food & Dining", "Gifts & Donations", "Health & Fitness", "Home", "Invesments", "Kids", "Personal Care", "Pets", "Shopping", "Taxes", "Transfer", "Travel"]
var financialTransactionsCategoriesStaticWOUncategorized = ["Bonus", "Interest Income", "Paycheck", "Reimbursement", "Rental Income", "Income", "Auto Payment", "Auto Insurance", "Gas", "Parking", "Public Transportation", "Service & Parts", "Auto & Transport", "Domain Names", "Fraud Protection", "Home Phone", "Hosting", "Internet", "Mobile Phone", "Television", "Utilities", "Bills & Utilities", "Advertising", "Legal", "Office Supplies", "Printing", "Shipping", "Business Services", "Book Supplies", "Student Loans", "Tuition", "Education", "Amusement", "Arts", "Movies & DVDs", "Music", "Newspapers & Magazines", "Entertainment", "ATM Fee", "Banking Fee", "Finance Charge", "Late Fee", "Service Fee", "Trade Commissions", "Fees & Charges", "Financial Advisor", "Life Insurance", "Financial", "Alcohol & Bars", "Coffee Shops", "Fast Food", "Groceries", "Restaurants", "Food & Dining", "Charity", "Gift", "Gifts & Donations", "Dentist", "Doctor", "Eyecare", "Gym", "Health Insurance", "Pharmacy", "Sports", "Health & Fitness", "Furnishings", "Home Improvement", "Home Insurance", "Home Services", "Home Supplies", "Lawn & Garden", "Mortgage & Rent", "Home", "Buy", "Deposit", "Dividend & Cap Gains", "Sell", "Withdrawal", "Investments", "Allowance", "Baby Supplies", "Babysitter & Daycare", "Child Support", "Kids Activities", "Toys", "Kids", "Hair", "Laundry", "Spa & Massage", "Personal Care", "Pet Food & Supplies", "Pet Grooming", "Veterinary", "Pets", "Books", "Clothing", "Hobbies", "Sporting Goods", "Shopping", "Federal Tax", "Local Tax", "Property Tax", "Sales Tax", "State Tax", "Taxes", "Credit Card Payment", "Transfer for Cash Spending", "Mortgage Payment", "Transfer", "Air Travel", "Hotel", "Rental Car & Taxi", "Vacation", "Travel", "Cash", "Check"]

func topLevelCategoryColor(_ value: String) -> UIColor {
    if value == "Uncategorized" {
        return UIColor.lightGray
    }
    
    let saturation = CGFloat(0.70)
    let lightness = CGFloat(0.70)

    return ColorHash(value, [saturation], [lightness]).color
}

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
    var category_guid: String?
    var check_number: Int?
    var check_number_string: String?
    var created_at: String
    var currency_code: String?
    var date: String
    var description: String
    var guid: String
    //atrium API
    var identifier: String?
    //platform API
    var id: String?
    var is_bill_pay: Bool?
    var is_direct_deposit: Bool?
    var is_expense: Bool?
    var is_fee: Bool?
    var is_income: Bool?
    var is_international: Bool?
    var is_overdraft_fee: Bool?
    var is_payroll_advance: Bool?
    var is_recurring: Bool?
    var is_subscription: Bool?
    var latitude: Double?
    var longitude: Double?
    var member_guid: String?
    var member_is_managed_by_user: Bool?
    var memo: String?
    var merchant_category_code: Int?
    var merchant_guid: String?
    var merchant_location_guid: String?
    var original_description: String?
    var posted_at: String?
    var status: TransactionStatus
    var top_level_category: String
    var transacted_at: String
    var type: TransactionType?
    var updated_at: String
    var user_guid: String
    var user_id: String?
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
    var transactionIDs: [String]?
    var containerID: String?
    var plot_is_recurring: Bool?
    var plot_recurrence_frequency: String?
    var plot_created: Bool?
    var transfer_between_accounts: Bool?
    var cash_flow_type: String? {
        if type == .credit {
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
    
    init(description: String, amount: Double, created_at: String, guid: String, user_guid: String, type: TransactionType?, status: TransactionStatus, category: String, top_level_category: String, user_created: Bool?, admin: String) {
        self.description = description
        self.amount = amount
        self.created_at = created_at
        self.date = created_at
        self.transacted_at = created_at
        self.updated_at = created_at
        self.guid = guid
        self.user_guid = user_guid
        self.type = type
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
    
    init(transaction: Transaction) {
        self.description = transaction.description
        self.category = transaction.category
        self.top_level_category = transaction.top_level_category
        self.group = transaction.group
        self.tags = transaction.tags
        self.should_link = transaction.should_link
        self.date_for_reports = transaction.date_for_reports
        self.badge = transaction.badge
        self.pinned = transaction.pinned
        self.muted = transaction.muted
    }
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

enum TransactionType: String, Codable, CaseIterable {
    case debit = "DEBIT"
    case credit = "CREDIT"
    
    var name: String {
        switch self {
        case .credit: return "Inflow"
        case .debit: return "Outflow"
        }
    }
}

struct TransactionDetails: Codable, Equatable, Hashable {
    var uuid = UUID().uuidString
    var name: String
    var amount: Double
    var lastPeriodAmount: Double?
    var level: TransactionCatLevel
    var category: String?
    var topLevelCategory: String?
    var group: String?
    var currencyCode: String?
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

func categorizeTransactions(transactions: [Transaction], start: Date?, end: Date?, level: TransactionCatLevel?, accounts: [String]?, completion: @escaping ([TransactionDetails], [TransactionDetails: [Transaction]]) -> ()) {
    var transactionsList = [TransactionDetails]()
    var transactionsDict = [TransactionDetails: [Transaction]]()
    // create dateFormatter with UTC time format
    let isodateFormatter = ISO8601DateFormatter()
    for transaction in transactions {
        guard transaction.should_link ?? true && !(transaction.plot_created ?? false) && !(transaction.transfer_between_accounts ?? false) && transaction.top_level_category != "Investments" && transaction.category != "Investments" else { continue }
        if accounts != nil {
            guard accounts!.contains(transaction.account_guid ?? "") else { continue }
        }
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
        case .debit:
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
                    let transactionDetail = TransactionDetails(name: transaction.category, amount: -transaction.amount, level: .category, category: transaction.category, topLevelCategory: transaction.top_level_category, group: transaction.group, currencyCode: transaction.currency_code ?? "USD")
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
                    let transactionDetail = TransactionDetails(name: transaction.top_level_category, amount: -transaction.amount, level: .top, category: nil, topLevelCategory: transaction.top_level_category, group: transaction.group, currencyCode: transaction.currency_code ?? "USD")
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
                    let transactionDetail = TransactionDetails(name: transaction.group, amount: -transaction.amount, level: .group, category: nil, topLevelCategory: nil, group: transaction.group, currencyCode: transaction.currency_code ?? "USD")
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
                    let transactionDetail = TransactionDetails(name: transaction.category, amount: -transaction.amount, level: .category, category: transaction.category, topLevelCategory: transaction.top_level_category, group: transaction.group, currencyCode: transaction.currency_code ?? "USD")
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
                    let transactionDetail = TransactionDetails(name: transaction.top_level_category, amount: -transaction.amount, level: .top, category: nil, topLevelCategory: transaction.top_level_category, group: transaction.group, currencyCode: transaction.currency_code ?? "USD")
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
                    let transactionDetail = TransactionDetails(name: transaction.group, amount: -transaction.amount, level: .group, category: nil, topLevelCategory: nil, group: transaction.group, currencyCode: transaction.currency_code ?? "USD")
                    transactionsDict[transactionDetail] = [transaction]
                }
            }
        case .credit:
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
                    let transactionDetail = TransactionDetails(name: transaction.category, amount: transaction.amount, level: .category, category: transaction.category, topLevelCategory: transaction.top_level_category, group: transaction.group, currencyCode: transaction.currency_code ?? "USD")
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
                    let transactionDetail = TransactionDetails(name: transaction.top_level_category, amount: transaction.amount, level: .top, category: nil, topLevelCategory: transaction.top_level_category, group: transaction.group, currencyCode: transaction.currency_code ?? "USD")
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
                    let transactionDetail = TransactionDetails(name: transaction.group, amount: transaction.amount, level: .group, category: nil, topLevelCategory: nil, group: transaction.group, currencyCode: transaction.currency_code ?? "USD")
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
                    let transactionDetail = TransactionDetails(name: transaction.category, amount: transaction.amount, level: .category, category: transaction.category, topLevelCategory: transaction.top_level_category, group: transaction.group, currencyCode: transaction.currency_code ?? "USD")
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
                    let transactionDetail = TransactionDetails(name: transaction.top_level_category, amount: transaction.amount, level: .top, category: nil, topLevelCategory: transaction.top_level_category, group: transaction.group, currencyCode: transaction.currency_code ?? "USD")
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
                    let transactionDetail = TransactionDetails(name: transaction.group, amount: transaction.amount, level: .group, category: nil, topLevelCategory: nil, group: transaction.group, currencyCode: transaction.currency_code ?? "USD")
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
                
                let expenseTransactionDetail = TransactionDetails(name: group, amount: amount, level: .group, category: nil, topLevelCategory: nil, group: group, currencyCode: "USD")
                
                if amount != 0.0 {
                    sortedTransactionsList.append(expenseTransactionDetail)
                    transactionsDict[expenseTransactionDetail] = transactions
                }
                
                if let incomeTransactionDetail = transactionsList.first(where: { ($0.level == .group && $0.group == "Income") }), let incomeTransactions = transactionsDict[incomeTransactionDetail] {
                    let diffAmount = incomeTransactionDetail.amount + expenseTransactionDetail.amount
                    let diffTransactions = incomeTransactions + transactions
                    let diffName = diffAmount > 0 ? "Net Savings" : "Net Spending"
                    let diffTransactionDetail = TransactionDetails(name: diffName, amount: diffAmount, level: .group, category: nil, topLevelCategory: nil, group: diffName, currencyCode: "USD")
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

func addPriorTransactionDetails(currentDetailsList: [TransactionDetails], currentDetailsDict: [TransactionDetails: [Transaction]], priorDetailsList: [TransactionDetails], completion: @escaping ([TransactionDetails], [TransactionDetails: [Transaction]]) -> ()) {
    var finalDetailsList = currentDetailsList
    var finalDetailsDict = [TransactionDetails: [Transaction]]()
    for index in 0...finalDetailsList.count - 1 {
        if finalDetailsList[index].name == "Net Spending" || finalDetailsList[index].name == "Net Savings" {
            if let priorDetail = priorDetailsList.first(where: {$0.name == "Net Spending"}) {
                finalDetailsList[index].lastPeriodAmount = priorDetail.amount
            } else if let priorDetail = priorDetailsList.first(where: {$0.name == "Net Savings"}) {
                finalDetailsList[index].lastPeriodAmount = priorDetail.amount
            }
            finalDetailsDict[finalDetailsList[index]] = currentDetailsDict[currentDetailsList[index]] ?? []
        } else {
            if let priorDetail = priorDetailsList.first(where: {$0.name == finalDetailsList[index].name && $0.level == finalDetailsList[index].level}) {
                finalDetailsList[index].lastPeriodAmount = priorDetail.amount
            }
            finalDetailsDict[finalDetailsList[index]] = currentDetailsDict[currentDetailsList[index]] ?? []
        }
    }
    completion(finalDetailsList, finalDetailsDict)
}

func transactionDetailsOverTimeChartData(transactions: [Transaction], transactionDetails: [TransactionDetails], start: Date, end: Date, segmentType: TimeSegmentType, accounts: [String]?, completion: @escaping ([TransactionDetails: [Statistic]], [TransactionDetails: [Transaction]]) -> ()) {
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
                transactionListStats(transactions: transactions, transactionDetail: transactionDetail, date: date, nextDate: nextDate, accounts: accounts, ignore_plot_created: nil, ignore_transfer_between_accounts: nil) { (stats, transactions) in
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
                transactionListStats(transactions: transactions, transactionDetail: transactionDetail, date: date, nextDate: nextDate, accounts: accounts, ignore_plot_created: nil, ignore_transfer_between_accounts: nil) { (stats, transactions) in
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
                transactionListStats(transactions: transactions, transactionDetail: transactionDetail, date: date, nextDate: nextDate, accounts: accounts, ignore_plot_created: nil, ignore_transfer_between_accounts: nil) { (stats, transactions) in
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
                transactionListStats(transactions: transactions, transactionDetail: transactionDetail, date: date, nextDate: nextDate, accounts: accounts, ignore_plot_created: nil, ignore_transfer_between_accounts: nil) { (stats, transactions) in
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

func transactionListStats(transactions: [Transaction], transactionDetail: TransactionDetails, date: Date, nextDate: Date, accounts: [String]?, ignore_plot_created: Bool?, ignore_transfer_between_accounts: Bool?, completion: @escaping ([Statistic], [Transaction]) -> ()) {
    var statistics = [Statistic]()
    var transactionList = [Transaction]()
    let isodateFormatter = ISO8601DateFormatter()
    for transaction in transactions {
        guard transaction.should_link ?? true else { continue }
        guard transaction.top_level_category != "Investments" && transaction.category != "Investments" else { continue }
        if ignore_plot_created ?? true {
            guard !(transaction.plot_created ?? false) else { continue }
        }
        if ignore_transfer_between_accounts ?? true {
            guard !(transaction.transfer_between_accounts ?? false) else { continue }
        }
        if let accounts = accounts {
            guard accounts.contains(transaction.account_guid ?? "") else { continue }
        }
        
        if let date_for_reports = transaction.date_for_reports, date_for_reports != "", let transactionDate = isodateFormatter.date(from: date_for_reports) {
            if transactionDate.localTime < date || nextDate < transactionDate.localTime {
                continue
            }
        } else if let transactionDate = isodateFormatter.date(from: transaction.transacted_at) {
            if transactionDate.localTime < date || nextDate < transactionDate.localTime {
                continue
            }
        }
        
        if transactionDetail.name == "Net Savings" || transactionDetail.name == "Net Spending" {
            switch transaction.type {
            case .debit:
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
            case .credit:
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
            case .debit:
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
            case .credit:
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
                case .debit:
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
                case .credit:
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
                case .debit:
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
                case .credit:
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
                case .debit:
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
                case .credit:
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
                case .debit:
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
                case .credit:
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
                case .debit:
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
                case .credit:
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
                case .debit:
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
                case .credit:
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

//transactions that involve doing something with your time e.g. dining out, grabbing drinks, groceries
var financialTransactionCategoriesAssociatedWithEvents = ["Amusement", "Arts", "Alcohol & Bars", "Coffee Shops", "Fast Food", "Restaurants", "Food & Dining", "Dentist", "Doctor", "Hair", "Spa & Massage", "Personal Care", "Pet Grooming", "Veterinary", "Groceries"]

//recurring transaction(bills)
var financialTransactionCategoriesAssociatedWithRecurringCosts = ["Auto Insurance", "Domain Names", "Hosting", "Internet", "Television", "Utilities", "Bills & Utilities", "Tuition", "Life Insurance", "Health Insurance", "Home Insurance", "Mortgage & Rent", "Child Support", "Paycheck"]

var financialTransactionCategoriesToSkip = ["Cash", "Check", "Uncategorized", "Transfer", "Public Transportation", "Rental Car & Taxi", "Alcohol & Bars", "Coffee Shops", "Fast Food", "Groceries", "Restaurants", "Food & Dining"]

var financialTransactionDescriptionsToSkip = ["aplpay", "mtamnr"]

var subscriptionProviders = ["spotify", "netflix", "amazon prime", "disney plus", "hulu", "crunchyroll", "espn plus", "apple music", "hbo", "amazon music", "dashpass", "apple tv plus", "audible"]

func categorizeTransactionsIntoTasks(transactions: [Transaction], completion: @escaping (Transaction, Activity, PlotRecurrenceFrequency) -> Void) {
    let isodateFormatter = ISO8601DateFormatter()
    for transaction in transactions {
        guard !(transaction.plot_is_recurring ?? false) && !(transaction.plot_created ?? false) else { continue }
        //amount period to period differs
        if financialTransactionCategoriesAssociatedWithRecurringCosts.contains(transaction.category), abs(transaction.amount) > 0 {
            let filteredTransactions = transactions.filter({ $0.description == transaction.description && $0.category == transaction.category && abs($0.amount) > 0 }).sorted(by: {
                return isodateFormatter.date(from: $0.transacted_at) ?? Date() > isodateFormatter.date(from: $1.transacted_at) ?? Date()
            })
            if let mostFrequentDayInterval = getMostFrequentDaysBetweenDates(dates: filteredTransactions.map({ isodateFormatter.date(from: $0.transacted_at) ?? Date() })), let frequency = getFrequency(int: mostFrequentDayInterval) {
                TaskBuilder.createActivityWithList(from: transaction) { task in
                    if let task = task {
                        completion(transaction, task, frequency)
                    }
                }
            }
        } else {
            
            //amount period to period is the same
            let filteredTransactions = transactions.filter({ $0.description == transaction.description && $0.category == transaction.category && $0.amount == transaction.amount }).sorted(by: {
                return isodateFormatter.date(from: $0.transacted_at) ?? Date() > isodateFormatter.date(from: $1.transacted_at) ?? Date()
            })
            
                        
            if filteredTransactions.count > 1, abs(transaction.amount) > 0, !financialTransactionCategoriesToSkip.contains(transaction.category), !containsWord(str: transaction.description.lowercased(), wordGroups: financialTransactionDescriptionsToSkip) {
                if let mostFrequentDayInterval = getMostFrequentDaysBetweenDates(dates: filteredTransactions.map({ isodateFormatter.date(from: $0.transacted_at) ?? Date() })), let frequency = getFrequency(int: mostFrequentDayInterval) {
                    TaskBuilder.createActivityWithList(from: transaction) { task in
                        if let task = task {
                            completion(transaction, task, frequency)
                        }
                    }
                }
            }
        }
    }
}

func categorizeTransactionsIntoEvents(transactions: [Transaction], completion: @escaping ([Transaction: Activity]) -> Void) {
    for transaction in transactions {
        guard transaction.status == .posted else { continue }
        if financialTransactionCategoriesAssociatedWithEvents.contains(transaction.category), !transaction.transacted_at.contains("12:00:00"), abs(transaction.amount) > 0, let event = EventBuilder.createActivity(from: transaction) {
            completion([transaction:event])
        }
    }
}

func getDaysArrayBetweenRecurringTransactions(transactions: [Transaction]) -> [Double] {
    let isodateFormatter = ISO8601DateFormatter()
    var counts = [Double]()
    for index in 0...transactions.count - 1 {
        if transactions.indices.contains(index), transactions.indices.contains(index + 1), let first = isodateFormatter.date(from: transactions[index].transacted_at), let second = isodateFormatter.date(from: transactions[index + 1].transacted_at) {
            let days = Calendar.current.numberOfDaysBetween(second, and: first)
            counts.append(Double(days))
        }
    }
    return counts
}

func getDateComponentsArrayBetweenRecurringTransactions(transactions: [Transaction]) -> [DateComponents] {
    let isodateFormatter = ISO8601DateFormatter()
    var dates = [DateComponents]()
    for transaction in transactions {
        if let first = isodateFormatter.date(from: transaction.transacted_at) {
            let date = Calendar.current.dateComponents([.year, .month, .day], from: first)
            dates.append(date)
        }
    }
    return dates
}

func getMostFrequentDaysBetweenRecurringTransactions(transactions: [Transaction]) -> Int? {
    let isodateFormatter = ISO8601DateFormatter()
    var counts = [Int: Int]()
    for index in 0...transactions.count - 1 {
        if transactions.indices.contains(index), transactions.indices.contains(index + 1), let first = isodateFormatter.date(from: transactions[index].transacted_at), let second = isodateFormatter.date(from: transactions[index + 1].transacted_at) {
            let days = Calendar.current.numberOfDaysBetween(second, and: first)
            counts[days] = (counts[days] ?? 0) + 1
        }
    }
    
    if let (value, _) = counts.max(by: {$0.1 < $1.1}) {
        return value
    }
    return nil
}

//    //paychecks
//    let paycheckTransactions = transactions.filter({ $0.category == "Paycheck" }).sorted(by: {
//        return isodateFormatter.date(from: $0.transacted_at) ?? Date() > isodateFormatter.date(from: $1.transacted_at) ?? Date()
//    })
//    if paycheckTransactions.count > 1 {
//        for transaction in getRecurringTransactions(transactions: paycheckTransactions) {
////            TaskBuilder.createActivityWithList(from: transaction) { task in
////                if let task = task {
////                    task.category = ActivityCategory.finances.rawValue
////                    task.subcategory = ActivitySubcategory.bills.rawValue
////                    completion([transaction:task])
////                }
////            }
//        }
//    }

func containsWord(str: String, wordGroups: [String]) -> Bool {
    // Get all the words from your input string
    let words = str.split(separator: " ")
    
    for group in wordGroups {
        // Put all the words in the group into set to improve lookup time
        let set = Set(group.split(separator: " "))
        for word in words {
            if set.contains(word) {
                return true
            }
        }
    }
    
    return false
}

