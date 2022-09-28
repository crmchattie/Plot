//
//  FinanceService.swift
//  Plot
//
//  Created by Cory McHattie on 12/24/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import Foundation
import Firebase
import CodableFirebase

extension NSNotification.Name {
    static let financeUpdated = NSNotification.Name(Bundle.main.bundleIdentifier! + ".financeUpdated")
    static let hasLoadedFinancials = NSNotification.Name(Bundle.main.bundleIdentifier! + ".hasLoadedFinancials")
}

class FinanceService {
    let accountFetcher = FinancialAccountFetcher()
    let transactionFetcher = FinancialTransactionFetcher()
    let transactionRuleFetcher = FinancialTransactionRuleFetcher()
    let memberFetcher = FinancialMemberFetcher()
    let holdingFetcher = FinancialHoldingFetcher()

    var transactions = [Transaction]() {
        didSet {
            if oldValue != transactions {
                transactions.sort { (transaction1, transaction2) -> Bool in
                    if transaction1.should_link ?? true == transaction2.should_link ?? true {
                        if let date1 = self.isodateFormatter.date(from: transaction1.transacted_at), let date2 = self.isodateFormatter.date(from: transaction2.transacted_at) {
                            return date1 > date2
                        }
                        return transaction1.description < transaction2.description
                    }
                    return transaction1.should_link ?? true && !(transaction2.should_link ?? true)
                }
                NotificationCenter.default.post(name: .financeUpdated, object: nil)
            }
        }
    }
    var accounts = [MXAccount]() {
        didSet {
            if oldValue != accounts {
                accounts.sort { (account1, account2) -> Bool in
                    if account1.should_link ?? true == account2.should_link ?? true {
                        return account1.name < account2.name
                    }
                    return account1.should_link ?? true && !(account2.should_link ?? true)
                }
                setupMembersAccountsDict()
                NotificationCenter.default.post(name: .financeUpdated, object: nil)
            }
        }
    }
    var members = [MXMember]() {
        didSet {
            if oldValue != members {
                members.sort { (member1, member2) -> Bool in
                    return member1.name < member2.name
                }
                setupMembersAccountsDict()
                NotificationCenter.default.post(name: .financeUpdated, object: nil)
            }
        }
    }
    var holdings = [MXHolding]() {
        didSet {
            if oldValue != holdings {
                holdings.sort { (holding1, holding2) -> Bool in
                    if holding1.should_link ?? true == holding2.should_link ?? true {
                        return holding1.market_value ?? 0 > holding2.market_value ?? 0
                    }
                    return holding1.should_link ?? true && !(holding2.should_link ?? true)
                }
                NotificationCenter.default.post(name: .financeUpdated, object: nil)
            }
        }
    }
    var hasLoadedFinancials = false {
        didSet {
            NotificationCenter.default.post(name: .hasLoadedFinancials, object: nil)
        }
    }
    var memberAccountsDict = [MXMember: [MXAccount]]()
    var transactionRules = [TransactionRule]()
    var institutionDict = [String: String]()
    var mxUser: MXUser!
    
    var transactionGroups = financialTransactionsGroupsStatic
    
    var transactionTopLevelCategoriesDictionary = financialTransactionsTopLevelCategoriesDictionaryStatic
    var transactionTopLevelCategories = financialTransactionsTopLevelCategoriesStatic
    
    var transactionCategoriesDictionary = financialTransactionsCategoriesDictionaryStatic
    var transactionCategories = financialTransactionsCategoriesStatic
    
    let isodateFormatter = ISO8601DateFormatter()
    let dateFormatterPrint = DateFormatter()
    
    var isRunning: Bool = true
    
    func grabFinances(_ completion: @escaping () -> Void) {
        self.triggerUpdateMXUser {}
        self.observeAccountsForCurrentUser {
        }
        self.transactionRuleFetcher.fetchTransactionRules(completion: { transactionRules in
            self.transactionRules = transactionRules
            self.observeTransactionsForCurrentUser {
                self.grabAccountTransactions()
                    self.removePendingTransactions()
//                    self.grabTransactionAttributes()
                if self.isRunning {
                    completion()
                    self.isRunning = false
                }
            }
        })
        self.observeTransactionRulesForCurrentUser {}
        self.observeHoldingsForCurrentUser()
        self.observeMembersForCurrentUser {}

    }
    
    func regrabFinances(_ completion: @escaping () -> Void) {
        hasLoadedFinancials = false
        self.triggerUpdateMXUser {
            completion()
        }
    }
    
    func setupMembersAccountsDict() {
        memberAccountsDict = [MXMember: [MXAccount]]()
        for member in self.members {
            for account in accounts {
                if account.member_guid == member.guid {
                    memberAccountsDict[member, default: []].append(account)
                }
            }
        }
    }
    
    func triggerUpdateMXUser(_ completion: @escaping () -> Void) {
        Service.shared.triggerUpdateMXUser() { [weak self] (json, err) in
            self?.hasLoadedFinancials = true
            completion()
        }
    }
    
    func removePendingTransactions() {
        let pendingTransactions = self.transactions.filter{($0.status == .pending)}
        let postedTransactions = self.transactions.filter{($0.status == .posted)}
        let lastWeek = Calendar.current.date(byAdding: .day, value: -7, to: Date())
        for transaction in pendingTransactions {
            let transactionDate = isodateFormatter.date(from: transaction.transacted_at) ?? Date()
            //older than 7 days
            if transactionDate < lastWeek! {
                deleteTransaction(transaction_guid: transaction.guid)
                continue
            }
            //matches posted transaction's GUID
            if let _ = postedTransactions.firstIndex(where: {$0.guid == transaction.guid}) {
                deleteTransaction(transaction_guid: transaction.guid)
                continue
            }
            //posted transaction matches name and merchant (time (amount - tips)
            if let _ = postedTransactions.firstIndex(where: {$0.description == transaction.description && $0.transacted_at == transaction.transacted_at && $0.account_guid == transaction.account_guid}) {
                deleteTransaction(transaction_guid: transaction.guid)
                continue
            }
        }
    }
    
    func deleteTransaction(transaction_guid: String) {
        if let currentUserId = Auth.auth().currentUser?.uid, let index = self.transactions.firstIndex(where: {$0.guid == transaction_guid}) {
            self.transactions.remove(at: index)
            let reference = Database.database().reference()
            reference.child(userFinancialTransactionsEntity).child(currentUserId).child(transaction_guid).removeValue()
            reference.child(financialTransactionsEntity).child(transaction_guid).removeValue()
        }
    }
    
    func deleteMXMember(member: MXMember) {
        Service.shared.deleteMXMember(current_member_guid: member.guid) { (search, err) in
            self.deleteMXMemberFB(member: member)
        }
    }
    
    func deleteMXMemberFB(member: MXMember) {
        let current_member_guid = member.guid
        if let currentUserId = Auth.auth().currentUser?.uid, let index = self.members.firstIndex(where: {$0.guid == current_member_guid}) {
            self.members.remove(at: index)
            let reference = Database.database().reference()
            reference.child(userFinancialMembersEntity).child(currentUserId).child(current_member_guid).removeValue()
            self.memberAccountsDict[member] = nil
            if let accounts = self.memberAccountsDict[member] {
                deleteMXAccountsFB(accounts: accounts)
            } else {
                var memberAccounts = [MXAccount]()
                for account in self.accounts {
                    if account.member_guid == member.guid {
                        memberAccounts.append(account)
                    }
                }
                deleteMXAccountsFB(accounts: memberAccounts)
            }
        }
    }
    
    func deleteMXAccountsFB(accounts: [MXAccount]) {
        if let currentUserId = Auth.auth().currentUser?.uid {
            let reference = Database.database().reference()
            for account in accounts {
                if let index = self.accounts.firstIndex(where: {$0.guid == account.guid}) {
                    self.accounts.remove(at: index)
                }
                reference.child(userFinancialAccountsEntity).child(currentUserId).child(account.guid).removeValue()
            }
        }
    }
    
    func observeMembersForCurrentUser(_ completion: @escaping () -> Void) {
        self.memberFetcher.observeMemberForCurrentUser(membersInitialAdd: { [weak self] membersInitialAdd in
            if self?.members.isEmpty ?? true {
                self?.members = membersInitialAdd
                completion()
            } else if !membersInitialAdd.isEmpty {
                for member in membersInitialAdd {
                    if let index = self?.members.firstIndex(where: {$0.guid == member.guid}) {
                        self?.members[index] = member
                    } else {
                        self?.members.append(member)
                    }
                }
            } else {
                completion()
            }
        }, membersAdded: { [weak self] membersAdded in
            for member in membersAdded {
                if let index = self?.members.firstIndex(where: {$0.guid == member.guid}) {
                    self?.members[index] = member
                } else {
                    self?.members.append(member)
                }
            }
        }, membersChanged: { [weak self] membersChanged in
            for member in membersChanged {
                if let index = self?.members.firstIndex(where: {$0.guid == member.guid}) {
                    self?.members[index] = member
                } else {
                    self?.members.append(member)
                }
            }
        })
    }
    
    func observeAccountsForCurrentUser(_ completion: @escaping () -> Void) {
        self.accountFetcher.observeAccountForCurrentUser(accountsInitialAdd: { [weak self] accountsInitialAdd in
            if self?.accounts.isEmpty ?? true {
                self?.accounts = accountsInitialAdd
                completion()
            } else if !accountsInitialAdd.isEmpty {
                for account in accountsInitialAdd {
                    print("accountsInitialAdd")
                    print(account.name)
                    if let index = self?.accounts.firstIndex(where: {$0.guid == account.guid}) {
                        self?.accounts[index] = account
                    } else {
                        self?.accounts.append(account)
                    }
                }
            } else {
                completion()
            }
        }, accountsAdded: { [weak self] accountsAdded in
            for account in accountsAdded {
                if let index = self?.accounts.firstIndex(where: {$0.guid == account.guid}) {
                    self?.accounts[index] = account
                } else {
                    self?.accounts.append(account)
                }
            }
        }, accountsChanged: { [weak self] accountsChanged in
            for account in accountsChanged {
                if let index = self?.accounts.firstIndex(where: {$0.guid == account.guid}) {
                    self?.accounts[index] = account
                } else {
                    self?.accounts.append(account)
                }
            }
        })
    }
    
    func observeTransactionsForCurrentUser(_ completion: @escaping () -> Void) {
        self.transactionFetcher.observeTransactionForCurrentUser(transactionsInitialAdd: {
            [weak self] transactionsInitialAdd in
            if !transactionsInitialAdd.isEmpty {
                if self!.transactions.isEmpty {
                    self?.transactions = transactionsInitialAdd
                }
                for transaction in transactionsInitialAdd {
                    updateTransactionWRule(transaction: transaction, transactionRules: self!.transactionRules) { (transaction, bool) in
                        if bool {
                            self?.updateExistingTransactionsFB(transactions: [transaction])
                        } else {
                            if let index = self?.transactions.firstIndex(where: {$0.guid == transaction.guid}) {
                                self?.transactions[index] = transaction
                            } else {
                                self?.transactions.append(transaction)
                            }
                        }
                    }
                }
                completion()
            } else {
                completion()
            }
        }, transactionsAdded: { [weak self] transactionsAdded in
            for transaction in transactionsAdded {
                updateTransactionWRule(transaction: transaction, transactionRules: self!.transactionRules) { (transaction, bool) in
                    if bool {
                        self?.updateExistingTransactionsFB(transactions: [transaction])
                    } else {
                        if let index = self?.transactions.firstIndex(where: {$0.guid == transaction.guid}) {
                            self?.transactions[index] = transaction
                        } else {
                            self?.transactions.append(transaction)
                        }
                    }
                }
            }
        }, transactionsChanged: { [weak self] transactionsChanged in
            for transaction in transactionsChanged {
                if let index = self?.transactions.firstIndex(where: {$0.guid == transaction.guid}) {
                    self?.transactions[index] = transaction
                } else {
                    self?.transactions.append(transaction)
                }
            }
        })
    }
    
    func observeTransactionRulesForCurrentUser(_ completion: @escaping () -> Void) {
        self.transactionRuleFetcher.observeTransactionRuleForCurrentUser(transactionRulesAdded: { [weak self] transactionRulesAdded in
            for transactionRule in transactionRulesAdded {
                if let index = self?.transactionRules.firstIndex(where: {$0.guid == transactionRule.guid}) {
                    self?.transactionRules[index] = transactionRule
                } else {
                    self?.transactionRules.append(transactionRule)
                }
                if !self!.transactions.isEmpty {
                    for index in 0...self!.transactions.count - 1 {
                        updateTransactionWRule(transaction: self!.transactions[index], transactionRules: self!.transactionRules) { (transaction, bool) in
                            if bool {
                                self?.updateExistingTransactionsFB(transactions: [transaction])
                            }
                        }
                    }
                }
            }
            completion()
            }, transactionRulesRemoved: { [weak self] transactionRulesRemoved in
                for transactionRule in transactionRulesRemoved {
                    if let index = self?.transactionRules.firstIndex(where: {$0.guid == transactionRule.guid}) {
                        self?.transactionRules[index] = transactionRule
                    }
                }
            }, transactionRulesChanged: { [weak self] transactionRulesChanged in
                for transactionRule in transactionRulesChanged {
                    if let index = self?.transactionRules.firstIndex(where: {$0.guid == transactionRule.guid}) {
                        self?.transactionRules[index] = transactionRule
                    } else {
                        self?.transactionRules.append(transactionRule)
                    }
                    if !self!.transactions.isEmpty {
                        for index in 0...self!.transactions.count - 1 {
                            updateTransactionWRule(transaction: self!.transactions[index], transactionRules: self!.transactionRules) { (transaction, bool) in
                                if bool {
                                    self?.updateExistingTransactionsFB(transactions: [transaction])
                                }
                            }
                        }
                    }
                }
            }
        )
    }
    
    func observeHoldingsForCurrentUser() {
        self.holdingFetcher.observeHoldingForCurrentUser(holdingsInitialAdd: { [weak self] holdingsAdded in
            if self?.holdings.isEmpty ?? true {
                self?.holdings = holdingsAdded
            } else {
                for holding in holdingsAdded {
                    if let index = self?.holdings.firstIndex(where: {$0.guid == holding.guid}) {
                        self?.holdings[index] = holding
                    } else {
                        self?.holdings.append(holding)
                    }
                }
            }
        }, holdingsAdded: { [weak self] holdingsAdded in
            for holding in holdingsAdded {
                if let index = self?.holdings.firstIndex(where: {$0.guid == holding.guid}) {
                    self?.holdings[index] = holding
                } else {
                    self?.holdings.append(holding)
                }
            }
        }, holdingsChanged: { [weak self] holdingsChanged in
            for holding in holdingsChanged {
                if let index = self?.holdings.firstIndex(where: {$0.guid == holding.guid}) {
                    self?.holdings[index] = holding
                }
            }
        })
    }
    
    func grabTransactionAttributes() {
        guard let currentUserID = Auth.auth().currentUser?.uid else {
            return
        }
        let reference = Database.database().reference()
        reference.child(userFinancialTransactionsCategoriesEntity).child(currentUserID).observeSingleEvent(of: .value, with: { snapshot in
            if snapshot.exists(), let values = snapshot.value as? [String: String] {
                for (key, value) in values {
                    self.transactionTopLevelCategoriesDictionary[key, default: []].append(value)
                    self.transactionCategories.append(key)
                }
            }
        })
        reference.child(userFinancialTransactionsTopLevelCategoriesEntity).child(currentUserID).observeSingleEvent(of: .value, with: { snapshot in
            if snapshot.exists(), let values = snapshot.value as? [String: [String]] {
                for (key, value) in values {
                    self.transactionTopLevelCategoriesDictionary[key, default: []].append(contentsOf: value)
                    self.transactionTopLevelCategories.append(key)
                }
            }
        })
        reference.child(userFinancialTransactionsGroupsEntity).child(currentUserID).observeSingleEvent(of: .value, with: { snapshot in
            if snapshot.exists(), let values = snapshot.value as? [String: String] {
                let array = Array(values.keys)
                self.transactionGroups.append(contentsOf: array)
            }
        })
    }
    
    func grabAccountTransactions() {
        transactionFetcher.grabTransactionsViaAccounts(accounts: accounts) { [weak self] transactions in
            self?.transactions.append(contentsOf: transactions)
        }
    }
    
    private func updateExistingTransactionsFB(transactions: [Transaction]) {
        guard let currentUserID = Auth.auth().currentUser?.uid else {
            return
        }
        let ref = Database.database().reference()
        for transaction in transactions {
            ref.child(userFinancialTransactionsEntity).child(currentUserID).child(transaction.guid).child("description").setValue(transaction.description)
            ref.child(userFinancialTransactionsEntity).child(currentUserID).child(transaction.guid).child("should_link").setValue(transaction.should_link)
            ref.child(userFinancialTransactionsEntity).child(currentUserID).child(transaction.guid).child("category").setValue(transaction.category)
            ref.child(userFinancialTransactionsEntity).child(currentUserID).child(transaction.guid).child("top_level_category").setValue(transaction.top_level_category)
            ref.child(userFinancialTransactionsEntity).child(currentUserID).child(transaction.guid).child("group").setValue(transaction.group)
        }
    }
}
