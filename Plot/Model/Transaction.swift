//
//  Transaction.swift
//  Plot
//
//  Created by Cory McHattie on 8/18/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

let usersFinancialTransactionsEntity = "user-financial-transactions"

import Foundation

struct MXTransactionResult: Codable, Equatable {
    let transaction: Transaction?
    let transactions: [Transaction]?
}

struct Transaction: Codable, Equatable {
    let account_guid: String
    let amount: Double
    let category: TransactionCategory
    let check_number: Int?
    let check_number_string: String?
    let created_at: String
    let currency_code: String?
    let date: String
    let description: String
    let guid: String
    let is_bill_pay: Bool
    let is_direct_deposit: Bool
    let is_expense: Bool
    let is_fee: Bool
    let is_income: Bool
    let is_international: Bool?
    let is_overdraft_fee: Bool
    let is_payroll_advance: Bool
    let latitude: Double?
    let longitude: Double?
    let member_guid: String
    let memo: String?
    let merchant_category_code: Int
    let merchant_guid: String?
    let original_description: String
    let posted_at: String
    let status: String
    let top_level_category: TransactionTopLevelCategory
    let transacted_at: String
    let type: String
    let updated_at: String
    let user_guid: String
    //user defined tags
    var tags: [String]?
    var participantsIDs: [String]?
    var group: TransactionGroup {
        switch self.category {
            case .autoPayment: return .bills
            case .autoInsurance, .gas, .parking, .publicTransportation, .serviceParts: return .living
            case .domainNames, .fraudProtection, .homePhone, .hosting, .internet, .mobilePhone, .television, .utilities: return .bills
            case .advertising, .legal, .officeSupplies, .printing, .shipping: return .living
            case .booksSupplies, .studentLoan, .tuition: return .living
            case .amusement, .arts, .moviesDvds, .music, .newspapersMagazines: return .discretionary
            case .atmFee, .bankingFee, .financeCharge, .lateFee, .serviceFee, .tradeCommissions: return .bills
            case .financialAdvisor, .lifeInsurance: return .living
            case .alcoholBars, .coffeeShops, .fastFood, .groceries, .restaurants: return .discretionary
            case .charity, .gift: return .living
            case .dentist, .doctor, .eyecare, .gym, .healthInsurance, .pharmacy, .sports: return .living
            case .furnishings, .homeImprovement, .homeInsurance, .homeServices, .homeSupplies, .lawnGarden, .mortgageRent: return .living
            case .bonus, .interestIncome, .paycheck, .reimbursement, .rentalIncome: return .income
            case .buy, .deposit, .dividendCapGains, .sell, .withdrawal: return .living
            case .allowance, .babySupplies, .babysitterDaycare, .childSupport, .kidsActivities, .toys: return .kids
            case .hair, .laundry, .spaMassage: return .living
            case .petFoodSupplies, .petGrooming, .veterinary: return .living
            case .books, .clothing, .hobbies, .sportingGoods: return .discretionary
            case .federalTax, .localTax, .propertyTax, .salesTax, .stateTax: return .bills
            case .creditCardPayment, .transferCashSpending, .mortgagePayment: return .transfer
            case .airTravel, .hotel, .rentalCarTaxi, .vacation: return .discretionary
            case .cash, .check: return .discretionary
        }
    }
}

func ==(lhs: Transaction, rhs: Transaction) -> Bool {
    return lhs.guid == rhs.guid && lhs.member_guid == rhs.member_guid && lhs.user_guid == rhs.user_guid
}

enum TransactionGroup: String, Hashable, CaseIterable, Codable {
    case discretionary, bills, living, kids, transfer, income
    
    var name: String {
        switch self {
        case .discretionary: return "Discretionary"
        case .bills: return "Bills"
        case .living: return "Living"
        case .kids: return "Kids"
        case .transfer: return "Transfer"
        case .income: return "Income"
        }
    }
}

enum TransactionTopLevelCategory: String, Hashable, CaseIterable, Codable {
    case autoTransport, billsUtilities, businessServices, education, entertainment, feesCharges, financial, foodDining, giftsDonations, healthFitness, home, income, investments, kids, personalCare, pets, shopping, taxes, transfer, travel, uncategorized
    
    enum CodingKeys: String, CodingKey {
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
    }
    
    var name: String {
        switch self {
        case .autoTransport: return "Auto & Transport"
        case .billsUtilities: return "Bills & Utilities"
        case .businessServices: return "Business Services"
        case .education: return "Education"
        case .entertainment: return "Entertainment"
        case .feesCharges: return "Fees & Charges"
        case .financial: return "Financial"
        case .foodDining: return "Food & Dining"
        case .giftsDonations: return "Gifts & Donations"
        case .healthFitness: return "Health & Fitness"
        case .home: return "Home"
        case .income: return "Income"
        case .investments: return "Invesments"
        case .kids: return "Kids"
        case .personalCare: return "Personal Care"
        case .pets: return "Pets"
        case .shopping: return "Shopping"
        case .taxes: return "Taxes"
        case .transfer: return "Transfer"
        case .travel: return "Travel"
        case .uncategorized: return "Uncategorized"
        }
    }
}

enum TransactionCategory: String, Hashable, CaseIterable, Codable {
    case autoInsurance, autoPayment, gas, parking, publicTransportation, serviceParts
    case domainNames, fraudProtection, homePhone, hosting, internet, mobilePhone, television, utilities
    case advertising, legal, officeSupplies, printing, shipping
    case booksSupplies, studentLoan, tuition
    case amusement, arts, moviesDvds, music, newspapersMagazines
    case atmFee, bankingFee, financeCharge, lateFee, serviceFee, tradeCommissions
    case financialAdvisor, lifeInsurance
    case alcoholBars, coffeeShops, fastFood, groceries, restaurants
    case charity, gift
    case dentist, doctor, eyecare, gym, healthInsurance, pharmacy, sports
    case furnishings, homeImprovement, homeInsurance, homeServices, homeSupplies, lawnGarden, mortgageRent
    case bonus, interestIncome, paycheck, reimbursement, rentalIncome
    case buy, deposit, dividendCapGains, sell, withdrawal
    case allowance, babySupplies, babysitterDaycare, childSupport, kidsActivities, toys
    case hair, laundry, spaMassage
    case petFoodSupplies, petGrooming, veterinary
    case books, clothing, hobbies, sportingGoods
    case federalTax, localTax, propertyTax, salesTax, stateTax
    case creditCardPayment, transferCashSpending, mortgagePayment
    case airTravel, hotel, rentalCarTaxi, vacation
    case cash, check
    
    enum CodingKeys: String, CodingKey {
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
    }
    
    var name: String {
        switch self {
        case .autoInsurance: return "Auto Insurance"
        case .autoPayment: return "Auto Payment"
        case .gas: return "Gas"
        case .parking: return "Parking"
        case .publicTransportation: return "Public Transportation"
        case .serviceParts: return "Service & Parts"
        case .domainNames: return "Domain Names"
        case .fraudProtection: return "Fraud Protection"
        case .homePhone: return "Home Phone"
        case .hosting: return "Hosting"
        case .internet: return "Internet"
        case .mobilePhone: return "Mobile Phone"
        case .television: return "Television"
        case .utilities: return "Utilities"
        case .advertising: return "Advertising"
        case .legal: return "Legal"
        case .officeSupplies: return "Office Supplies"
        case .printing: return "Print"
        case .shipping: return "Shipping"
        case .booksSupplies: return "Book Supplies"
        case .studentLoan: return "Student Loans"
        case .tuition: return "Tuition"
        case .amusement: return "Amusement"
        case .arts: return "Arts"
        case .moviesDvds: return "Movies & DVDs"
        case .music: return "Music"
        case .newspapersMagazines: return "Newspapers & Magazines"
        case .atmFee: return "ATM Fee"
        case .bankingFee: return "Banking Fee"
        case .financeCharge: return "Finance Charge"
        case .lateFee: return "Late Fee"
        case .serviceFee: return "Service Fee"
        case .tradeCommissions: return "Trade Commissions"
        case .financialAdvisor: return "Financial Advisor"
        case .lifeInsurance: return "Life Insurance"
        case .alcoholBars: return "Alcohol & Bars"
        case .coffeeShops: return "Coffee Shops"
        case .fastFood: return "Fast Food"
        case .groceries: return "Groceries"
        case .restaurants: return "Restaurants"
        case .charity: return "Charity"
        case .gift: return "Gift"
        case .dentist: return "Dentist"
        case .doctor: return "Doctor"
        case .eyecare: return "Eyecare"
        case .gym: return "Gym"
        case .healthInsurance: return "Health Insurance"
        case .pharmacy: return "Pharmacy"
        case .sports: return "Sports"
        case .furnishings: return "Furnishings"
        case .homeImprovement: return "Home Improvement"
        case .homeInsurance: return "Home Insurance"
        case .homeServices: return "Home Services"
        case .homeSupplies: return "Home Supplies"
        case .lawnGarden: return "Lawn Garden"
        case .mortgageRent: return "Mortgage & Rent"
        case .bonus: return "Bonus"
        case .interestIncome: return "Interest Income"
        case .paycheck: return "Paycheck"
        case .reimbursement: return "Reimbursement"
        case .rentalIncome: return "Rental Income"
        case .buy: return "Buy"
        case .deposit: return "Deposit"
        case .dividendCapGains: return "Dividend & Cap Gains"
        case .sell: return "Sell"
        case .withdrawal: return "Withdrawal"
        case .allowance: return "Allowance"
        case .babySupplies: return "Baby Supplies"
        case .babysitterDaycare: return "Babysitter & Daycare"
        case .childSupport: return "Child Support"
        case .kidsActivities: return "Kids Activities"
        case .toys: return "Toys"
        case .hair: return "Hair"
        case .laundry: return "Laundry"
        case .spaMassage: return "Spa & Massage"
        case .petFoodSupplies: return "Pet Food & Supplies"
        case .petGrooming: return "Pet Grooming"
        case .veterinary: return "Veterinary"
        case .books: return "Books"
        case .clothing: return "Clothing"
        case .hobbies: return "Hobbies"
        case .sportingGoods: return "Sporting Goods"
        case .federalTax: return "Federal Tax"
        case .localTax: return "Local Tax"
        case .propertyTax: return "Property Tax"
        case .salesTax: return "Sales Tax"
        case .stateTax: return "State Tax"
        case .creditCardPayment: return "Credit Card Payment"
        case .transferCashSpending: return "Transfer for Cash Spending"
        case .mortgagePayment: return "Mortgage Payment"
        case .airTravel: return "Air Travel"
        case .hotel: return "Hotel"
        case .rentalCarTaxi: return "Rental Car & Taxi"
        case .vacation: return "Vacation"
        case .cash: return "Cash"
        case .check: return "Check"
        }
    }
    
    var group: TransactionGroup {
        switch self {
        case .autoPayment: return .bills
        case .autoInsurance, .gas, .parking, .publicTransportation, .serviceParts: return .living
        case .domainNames, .fraudProtection, .homePhone, .hosting, .internet, .mobilePhone, .television, .utilities: return .bills
        case .advertising, .legal, .officeSupplies, .printing, .shipping: return .living
        case .booksSupplies, .studentLoan, .tuition: return .living
        case .amusement, .arts, .moviesDvds, .music, .newspapersMagazines: return .discretionary
        case .atmFee, .bankingFee, .financeCharge, .lateFee, .serviceFee, .tradeCommissions: return .bills
        case .financialAdvisor, .lifeInsurance: return .living
        case .alcoholBars, .coffeeShops, .fastFood, .groceries, .restaurants: return .discretionary
        case .charity, .gift: return .living
        case .dentist, .doctor, .eyecare, .gym, .healthInsurance, .pharmacy, .sports: return .living
        case .furnishings, .homeImprovement, .homeInsurance, .homeServices, .homeSupplies, .lawnGarden, .mortgageRent: return .living
        case .bonus, .interestIncome, .paycheck, .reimbursement, .rentalIncome: return .income
        case .buy, .deposit, .dividendCapGains, .sell, .withdrawal: return .living
        case .allowance, .babySupplies, .babysitterDaycare, .childSupport, .kidsActivities, .toys: return .kids
        case .hair, .laundry, .spaMassage: return .living
        case .petFoodSupplies, .petGrooming, .veterinary: return .living
        case .books, .clothing, .hobbies, .sportingGoods: return .discretionary
        case .federalTax, .localTax, .propertyTax, .salesTax, .stateTax: return .bills
        case .creditCardPayment, .transferCashSpending, .mortgagePayment: return .transfer
        case .airTravel, .hotel, .rentalCarTaxi, .vacation: return .discretionary
        case .cash, .check: return .discretionary
        }
    }
    
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
        case .furnishings, .homeImprovement, .homeInsurance, .homeServices, .homeSupplies, .lawnGarden, .mortgageRent: return .home
        case .bonus, .interestIncome, .paycheck, .reimbursement, .rentalIncome: return .income
        case .buy, .deposit, .dividendCapGains, .sell, .withdrawal: return .investments
        case .allowance, .babySupplies, .babysitterDaycare, .childSupport, .kidsActivities, .toys: return .kids
        case .hair, .laundry, .spaMassage: return .personalCare
        case .petFoodSupplies, .petGrooming, .veterinary: return .pets
        case .books, .clothing, .hobbies, .sportingGoods: return .shopping
        case .federalTax, .localTax, .propertyTax, .salesTax, .stateTax: return .taxes
        case .creditCardPayment, .transferCashSpending, .mortgagePayment: return .transfer
        case .airTravel, .hotel, .rentalCarTaxi, .vacation: return .travel
        case .cash, .check: return .uncategorized
        }
    }
}


