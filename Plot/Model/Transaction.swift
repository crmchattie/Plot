//
//  Transaction.swift
//  Plot
//
//  Created by Cory McHattie on 8/18/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

let usersFinancialTransactionsEntity = "user-financial-transactions"
let financialTransactionsEntity = "financial-transactions"

struct MXTransactionResult: Codable {
    let transaction: Transaction?
    let transactions: [Transaction]?
    let pagination: MXPagination?
}

struct Transaction: Codable, Equatable {
    let account_guid: String
    let amount: Double
    var category: TransactionCategory
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
    var top_level_category: TransactionTopLevelCategory
    let transacted_at: String
    let type: String
    let updated_at: String
    let user_guid: String
    //user defined tags
    var tags: [String]?
    var participantsIDs: [String]?
    var cash_flow_type: String {
        if type == "CREDIT" {
            return "Inflow"
        } else {
            return "Outflow"
        }
    }
    var group: TransactionGroup {
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

func ==(lhs: Transaction, rhs: Transaction) -> Bool {
    return lhs.guid == rhs.guid && lhs.member_guid == rhs.member_guid && lhs.user_guid == rhs.user_guid
}

enum TransactionGroup: String, CaseIterable, Codable {
    case discretionary = "Discretionary"
    case bills = "Bills"
    case living = "Living"
    case kids = "Kids"
    case transfer = "Transfer"
    case income = "Income"
    case uncategorized = "Uncategorized"
    
}

enum TransactionTopLevelCategory: String, CaseIterable, Codable {
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


