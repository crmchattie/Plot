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

class FinanceService {
    let transactionFetcher = FinancialTransactionFetcher()
    let transactionRuleFetcher = FinancialTransactionRuleFetcher()
    let accountFetcher = FinancialAccountFetcher()

    var transactions = [Transaction]()
    var transactionRules = [TransactionRule]()
    var accounts = [MXAccount]()
    var members = [MXMember]()
    var institutionDict = [String: String]()
    var mxUser: MXUser!
    
    let isodateFormatter = ISO8601DateFormatter()
    let dateFormatterPrint = DateFormatter()
    
    func grabFinances(_ completion: @escaping () -> Void) {
        DispatchQueue.main.async { [unowned self] in
            getMXUser() { mxUser in
                self.mxUser = mxUser
            }
            
            accountFetcher.fetchAccounts { (firebaseAccounts) in
                print("accounts grabbed \(firebaseAccounts.count)")
                self.accounts = firebaseAccounts
                self.accounts.sort { (account1, account2) -> Bool in
                    return account1.name < account2.name
                }
                self.observeAccountsForCurrentUser()
            }
            
            transactionRuleFetcher.fetchTransactionRules { (firebaseTransactionRules) in
                print("transaction rules grabbed \(firebaseTransactionRules.count)")
                self.transactionRules = firebaseTransactionRules
                self.observeTransactionRulesForCurrentUser()
                self.transactionFetcher.fetchTransactions { (firebaseTransactions) in
                    print("transactions grabbed \(firebaseTransactions.count)")
                    self.transactions = firebaseTransactions
                    self.observeTransactionsForCurrentUser()
                    completion()
                }
            }
        }
    }
    
    func getMXData() {
        let dispatchGroup = DispatchGroup()
        var updatedAccounts = [MXAccount]()
        dispatchGroup.enter()
        self.getMXUser { user in
            dispatchGroup.enter()
            if let user = user {
                dispatchGroup.enter()
                self.getMXTransactions(user: user, account: nil, date: nil)
                self.getMXMembers(guid: user.guid) { (members) in
                    for member in members {
                        dispatchGroup.enter()
                        if member.connection_status == .connected && !member.is_being_aggregated, let date = self.isodateFormatter.date(from: member.aggregated_at), date < Date().addingTimeInterval(-10800) {
                            dispatchGroup.enter()
                            Service.shared.aggregateMXMember(guid: user.guid, member_guid: member.guid) { (search, err)  in
                                if let member = search?.member {
                                    dispatchGroup.enter()
                                    self.pollMemberStatus(guid: user.guid, member_guid: member.guid) { (member) in
                                        dispatchGroup.enter()
                                        self.getMXAccounts(guid: user.guid, member_guid: member.guid) { (accounts) in
                                            for account in accounts {
                                                dispatchGroup.enter()
                                                var _account = account
                                                if !self.accounts.contains(_account) {
                                                    self.getMXTransactions(user: user, account: _account, date: nil)
                                                    self.accounts.append(_account)
                                                } else if let index = self.accounts.firstIndex(of: account) {
                                                    let date = self.isodateFormatter.date(from: _account.updated_at ) ?? Date()
                                                    self.getMXTransactions(user: user, account: _account, date: date.addingTimeInterval(-604800))
                                                    _account.balances = self.accounts[index].balances
                                                    _account.description = self.accounts[index].description
                                                    _account.admin = self.accounts[index].admin
                                                    _account.participantsIDs = self.accounts[index].participantsIDs
                                                    self.accounts[index] = _account
                                                }
                                                updatedAccounts.append(_account)
                                                dispatchGroup.leave()
                                            }
                                            dispatchGroup.leave()
                                        }
                                        dispatchGroup.leave()
                                    }
                                    dispatchGroup.leave()
                                }
                            }
                        } else if member.connection_status == .connected && !member.is_being_aggregated {
                            dispatchGroup.enter()
                            self.getMXAccounts(guid: user.guid, member_guid: member.guid) { (accounts) in
                                for account in accounts {
                                    dispatchGroup.enter()
                                    var _account = account
                                    if !self.accounts.contains(_account) {
                                        self.accounts.append(_account)
                                        self.getMXTransactions(user: user, account: _account, date: nil)
                                    } else if let index = self.accounts.firstIndex(of: account) {
                                        _account.balances = self.accounts[index].balances
                                        _account.description = self.accounts[index].description
                                        _account.admin = self.accounts[index].admin
                                        _account.participantsIDs = self.accounts[index].participantsIDs
                                        self.accounts[index] = _account
                                    }
                                    updatedAccounts.append(_account)
                                    dispatchGroup.leave()
                                }
                                dispatchGroup.leave()
                            }
                        } else if member.connection_status != .connected && !member.is_being_aggregated {
                            dispatchGroup.enter()
                            self.members.append(member)
                            self.members.sort { (member1, member2) -> Bool in
                                return member1.name < member2.name
                            }
                            self.getInsitutionalDetails(institution_code: member.institution_code) {
                                dispatchGroup.leave()
                            }
                        }
                        dispatchGroup.leave()
                    }
                    dispatchGroup.leave()
                }
                dispatchGroup.leave()
            }
            dispatchGroup.leave()
        }
        
        dispatchGroup.notify(queue: .main) {
            self.updateFirebase(accounts: updatedAccounts, transactions: [])
        }
    }
    
    func getMXTransactions(user: MXUser, account: MXAccount?, date: Date?) {
        let dispatchGroup = DispatchGroup()
        var newTransactions = [Transaction]()
        dispatchGroup.enter()
        if let account = account {
            dispatchGroup.enter()
            if let date = date {
                self.getTransactionsAcct(guid: user.guid, account: account, from_date: date, to_date: Date().addingTimeInterval(86400)) {
                    (transactions) in
                    for transaction in transactions {
                        dispatchGroup.enter()
                        let finalAccount = self.accounts.first(where: { $0.guid == transaction.account_guid})
                        if !self.transactions.contains(transaction) {
                            updateTransactionWRule(transaction: transaction, transactionRules: self.transactionRules) { (transaction, bool) in
                                if finalAccount?.should_link ?? true {
                                    self.transactions.append(transaction)
                                    if transaction.status != .pending {
                                        newTransactions.append(transaction)
                                    }
                                } else {
                                    var _transaction = transaction
                                    _transaction.should_link = false
                                    self.transactions.append(_transaction)
                                    if transaction.status != .pending {
                                        newTransactions.append(transaction)
                                    }
                                }
                                dispatchGroup.leave()
                            }
                        } else {
                            dispatchGroup.leave()
                        }
                    }
                    dispatchGroup.leave()
                }
            } else {
                self.getTransactionsAcct(guid: user.guid, account: account, from_date: nil, to_date: nil) {
                    (transactions) in
                    for transaction in transactions {
                        dispatchGroup.enter()
                        let finalAccount = self.accounts.first(where: { $0.guid == transaction.account_guid})
                        if !self.transactions.contains(transaction) {
                            updateTransactionWRule(transaction: transaction, transactionRules: self.transactionRules) { (transaction, bool) in
                                if finalAccount?.should_link ?? true {
                                    self.transactions.append(transaction)
                                    if transaction.status != .pending {
                                        newTransactions.append(transaction)
                                    }
                                } else {
                                    var _transaction = transaction
                                    _transaction.should_link = false
                                    self.transactions.append(_transaction)
                                    if transaction.status != .pending {
                                        newTransactions.append(transaction)
                                    }
                                }
                                dispatchGroup.leave()
                            }
                        } else {
                            dispatchGroup.leave()
                        }
                    }
                    dispatchGroup.leave()
                }
            }
        } else {
            dispatchGroup.enter()
            let account = self.accounts.min(by:{ self.isodateFormatter.date(from: $0.updated_at)! < self.isodateFormatter.date(from: $1.updated_at)! })
            let date = self.isodateFormatter.date(from: account?.updated_at ?? "") ?? Date()
            self.getTransactions(guid: user.guid, from_date: date.addingTimeInterval(-604800), to_date: Date().addingTimeInterval(86400)) { (transactions) in
                for transaction in transactions {
                    dispatchGroup.enter()
                    let finalAccount = self.accounts.first(where: { $0.guid == transaction.account_guid})
                    if !self.transactions.contains(transaction) {
                        updateTransactionWRule(transaction: transaction, transactionRules: self.transactionRules) { (transaction, bool) in
                            if finalAccount?.should_link ?? true {
                                self.transactions.append(transaction)
                                if transaction.status != .pending {
                                    newTransactions.append(transaction)
                                }
                            } else {
                                var _transaction = transaction
                                _transaction.should_link = false
                                self.transactions.append(_transaction)
                                if transaction.status != .pending {
                                    newTransactions.append(transaction)
                                }
                            }
                            dispatchGroup.leave()
                        }
                    } else {
                        dispatchGroup.leave()
                    }
                }
                dispatchGroup.leave()
            }
        }
        
        dispatchGroup.leave()
        
        dispatchGroup.notify(queue: .main) {
            self.updateFirebase(accounts: [], transactions: newTransactions)
        }
    }
    
    func getMXUser(completion: @escaping (MXUser?) -> ()) {
        if let currentUser = Auth.auth().currentUser?.uid {
            let mxIDReference = Database.database().reference().child(userFinancialEntity).child(currentUser)
            mxIDReference.observeSingleEvent(of: .value, with: { (snapshot) in
                if snapshot.exists(), let value = snapshot.value {
                    if let user = try? FirebaseDecoder().decode(MXUser.self, from: value) {
                        completion(user)
                    }
                } else if !snapshot.exists() {
                    let identifier = UUID().uuidString
                    Service.shared.createMXUser(id: identifier) { (search, err) in
                        if search?.user != nil {
                            var user = search?.user
                            user!.identifier = identifier
                            if let firebaseUser = try? FirebaseEncoder().encode(user) {
                                mxIDReference.setValue(firebaseUser)
                            }
                            completion(user)
                        }
                    }
                }
            })
        }
    }
    
    func getMXMembers(guid: String, completion: @escaping ([MXMember]) -> ()) {
        Service.shared.getMXMembers(guid: guid, page: "1", records_per_page: "100") { (search, err) in
            if let members = search?.members {
                completion(members)
            } else if let member = search?.member {
                completion([member])
            }
        }
    }
    
    func getMXAccounts(guid: String, member_guid: String, completion: @escaping ([MXAccount]) -> ()) {
        Service.shared.getMXMemberAccounts(guid: guid, member_guid: member_guid, page: "1", records_per_page: "100") { (search, err) in
            if search?.accounts != nil {
                var accounts = search?.accounts
                for index in 0...accounts!.count - 1 {
                    if let currentUserID = Auth.auth().currentUser?.uid {
                        let reference = Database.database().reference().child(userFinancialAccountsEntity).child(currentUserID).child(accounts![index].guid).child("should_link")
                        reference.observeSingleEvent(of: .value, with: { (snapshot) in
                            if snapshot.exists(), let value = snapshot.value, let should_link = value as? Bool {
                                accounts![index].should_link = should_link
                            } else if !snapshot.exists() {
                                reference.setValue(true)
                                accounts![index].should_link = true
                            }
                            if index == accounts!.count - 1 {
                                completion(accounts!)
                            }
                        })
                    }
                }
            } else if search?.account != nil {
                var account = search?.account
                if let currentUserID = Auth.auth().currentUser?.uid {
                    let reference = Database.database().reference().child(userFinancialAccountsEntity).child(currentUserID).child(account!.guid).child("should_link")
                    reference.observeSingleEvent(of: .value, with: { (snapshot) in
                        if snapshot.exists(), let value = snapshot.value, let should_link = value as? Bool {
                            account!.should_link = should_link
                        } else if !snapshot.exists() {
                            reference.setValue(true)
                            account!.should_link = true
                        }
                        completion([account!])
                    })
                }
            }
        }
    }
    
    func getTransactionsAcct(guid: String, account: MXAccount, from_date: Date?, to_date: Date?, completion: @escaping ([Transaction]) -> ()) {
        dateFormatterPrint.dateFormat = "yyyy-MM-dd"
        if let fromDate = from_date, let toDate = to_date {
            let from_date_string = dateFormatterPrint.string(from: fromDate)
            let to_date_string = dateFormatterPrint.string(from: toDate)
            Service.shared.getMXAccountTransactions(guid: guid, account_guid: account.guid, page: "1", records_per_page: "100", from_date: from_date_string, to_date: to_date_string) { (search, err) in
                if let transactions = search?.transactions {
                    completion(transactions)
                } else if let transaction = search?.transaction {
                    completion([transaction])
                } else {
                    completion([])
                }
            }
        } else {
            Service.shared.getMXAccountTransactions(guid: guid, account_guid: account.guid, page: "1", records_per_page: "100", from_date: nil, to_date: nil) { (search, err) in
                if let transactions = search?.transactions {
                    completion(transactions)
                } else if let transaction = search?.transaction {
                    completion([transaction])
                }  else {
                    completion([])
                }
            }
        }
    }
    
    func getTransactions(guid: String, from_date: Date?, to_date: Date?, completion: @escaping ([Transaction]) -> ()) {
        dateFormatterPrint.dateFormat = "yyyy-MM-dd"
        if let fromDate = from_date, let toDate = to_date {
            let from_date_string = dateFormatterPrint.string(from: fromDate)
            let to_date_string = dateFormatterPrint.string(from: toDate)
            Service.shared.getMXTransactions(guid: guid, page: "1", records_per_page: "100", from_date: from_date_string, to_date: to_date_string) { (search, err) in
                if let transactions = search?.transactions {
                    completion(transactions)
                } else if let transaction = search?.transaction {
                    completion([transaction])
                } else {
                    completion([])
                }
            }
        } else {
            Service.shared.getMXTransactions(guid: guid, page: "1", records_per_page: "100", from_date: nil, to_date: nil) { (search, err) in
                if let transactions = search?.transactions {
                    completion(transactions)
                } else if let transaction = search?.transaction {
                    completion([transaction])
                }  else {
                    completion([])
                }
            }
        }
    }
    
    func pollMemberStatus(guid: String, member_guid: String, completion: @escaping (MXMember) -> ()) {
        Service.shared.getMXMember(guid: guid, member_guid: member_guid) { (search, err) in
            if let member = search?.member {
                if member.connection_status == .challenged {
                    self.members.append(member)
                    self.members.sort { (member1, member2) -> Bool in
                        return member1.name < member2.name
                    }
                    self.getInsitutionalDetails(institution_code: member.institution_code) {
                        completion(member)
                    }
                } else if member.is_being_aggregated {
                    self.pollMemberStatus(guid: guid, member_guid: member_guid) { member in
                        completion(member)
                    }
                } else {
                    completion(member)
                }
            }
        }
    }
    
    func getInsitutionalDetails(institution_code: String, completion: @escaping () -> ()) {
        Service.shared.getMXInstitution(institution_code: institution_code) { (search, err) in
            if let institution = search?.institution {
                self.institutionDict[institution_code] = institution.medium_logo_url
                completion()
            }
        }
    }
    
    func observeAccountsForCurrentUser() {
        self.accountFetcher.observeAccountForCurrentUser(accountsAdded: { [weak self] accountsAdded in
            for account in accountsAdded {
                if !self!.accounts.contains(account) {
                    self!.accounts.append(account)
                }
            }
        })
    }
    
    func observeTransactionsForCurrentUser() {
        self.transactionFetcher.observeTransactionForCurrentUser(transactionsAdded: { [weak self] transactionsAdded in
            for transaction in transactionsAdded {
                if !self!.transactions.contains(transaction) {
                    self!.transactions.append(transaction)
                }
            }
        })
    }
    
    func observeTransactionRulesForCurrentUser() {
        self.transactionRuleFetcher.observeTransactionRuleForCurrentUser(transactionRulesAdded: { [weak self] transactionRulesAdded in
            var newTransactions = [Transaction]()
            for transactionRule in transactionRulesAdded {
                self!.transactionRules.append(transactionRule)
                if !self!.transactions.isEmpty {
                    for index in 0...self!.transactions.count - 1 {
                        updateTransactionWRule(transaction: self!.transactions[index], transactionRules: self!.transactionRules) { (transaction, bool) in
                            if bool {
                                self!.transactions[index] = transaction
                                newTransactions.append(transaction)
                            }
                        }
                    }
                }
            }
            if !newTransactions.isEmpty {
                self!.updateExistingTransactionsFB(transactions: newTransactions)
            }
            }, transactionRulesRemoved: { [weak self] transactionRulesRemoved in
                for transactionRule in transactionRulesRemoved {
                    if let index = self!.transactionRules.firstIndex(where: {$0 == transactionRule}) {
                        self!.transactionRules.remove(at: index)
                    }
                }
            }, transactionRulesChanged: { [weak self] transactionRulesChanged in
                var newTransactions = [Transaction]()
                for transactionRule in transactionRulesChanged {
                    if let index = self!.transactionRules.firstIndex(where: {$0 == transactionRule}) {
                        self!.transactionRules[index] = transactionRule
                    }
                    if !self!.transactions.isEmpty {
                        for index in 0...self!.transactions.count - 1 {
                            updateTransactionWRule(transaction: self!.transactions[index], transactionRules: self!.transactionRules) { (transaction, bool) in
                                if bool {
                                    self!.transactions[index] = transaction
                                    newTransactions.append(transaction)
                                }
                            }
                        }
                    }
                }
                if !newTransactions.isEmpty {
                    self!.updateExistingTransactionsFB(transactions: newTransactions)
                }
            }
        )
    }
    
    private func updateFirebase(accounts: [MXAccount], transactions: [Transaction]) {
        guard let currentUserID = Auth.auth().currentUser?.uid else {
            return
        }
        let ref = Database.database().reference()
        for account in accounts {
            do {
                var _account = account
                if _account.balances != nil {
                    if !_account.balances!.values.contains(_account.available_balance ?? _account.balance) {
                        _account.balances![_account.updated_at] = _account.available_balance ?? _account.balance
                    }
                } else {
                    _account.balances = [_account.updated_at: _account.available_balance ?? _account.balance]
                }
                // store account info
                let value = try FirebaseEncoder().encode(_account)
                ref.child(financialAccountsEntity).child(_account.guid).setValue(value)
                // store account balance at given date
                ref.child(userFinancialAccountsEntity).child(currentUserID).child(_account.guid).child("name").setValue(_account.name)
            } catch let error {
                print(error)
            }
        }
        for transaction in transactions {
            do {
                var _transaction = transaction
                _transaction.admin = currentUserID
                _transaction.participantsIDs = [currentUserID]
                // store transaction info
                let value = try FirebaseEncoder().encode(_transaction)
                ref.child(financialTransactionsEntity).child(_transaction.guid).setValue(value)
                // store transaction description (name) just to put something there
                ref.child(userFinancialTransactionsEntity).child(currentUserID).child(transaction.guid).child("description").setValue(transaction.description)
            } catch let error {
                print(error)
            }
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