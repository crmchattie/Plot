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
    var memberAccountsDict = [MXMember: [MXAccount]]()
    var transactionRules = [TransactionRule]()
    var institutionDict = [String: String]()
    var mxUser: MXUser!
    
    let isodateFormatter = ISO8601DateFormatter()
    let dateFormatterPrint = DateFormatter()
    
    func grabFinances(_ completion: @escaping () -> Void) {
        DispatchQueue.main.async { [unowned self] in
            memberFetcher.fetchMembers { (firebaseMembers) in
                self.members = firebaseMembers
//                self.setupMembersDict()
                self.observeMembersForCurrentUser()
            }
            
            accountFetcher.fetchAccounts { (firebaseAccounts) in
                self.accounts = firebaseAccounts
                self.setupMembersAccountsDict()
                self.observeAccountsForCurrentUser()
            }
            
            transactionRuleFetcher.fetchTransactionRules { (firebaseTransactionRules) in
                self.transactionRules = firebaseTransactionRules
                self.observeTransactionRulesForCurrentUser()
                self.transactionFetcher.fetchTransactions { (firebaseTransactions) in
                    self.transactions = firebaseTransactions
                    self.removePendingTransactions()
                    self.observeTransactionsForCurrentUser()
                    completion()
                }
            }
            
            holdingFetcher.fetchHoldings { (firebaseHoldings) in
                self.holdings = firebaseHoldings
                self.observeHoldingsForCurrentUser()
            }
        }
    }
    
    func setupMembersDict() {
        for member in self.members {
            self.getInsitutionalDetails(institution_code: member.institution_code)
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
    
    func triggerUpdateMXUser() {
        Service.shared.triggerUpdateMXUser() { (search, err) in
            print("tiggeredUpdateMXUser")
        }
    }
    
    func removePendingTransactions() {
        let pendingTransactions = self.transactions.filter{($0.status == .pending)}
        let postedTransactions = self.transactions.filter{($0.status == .posted)}
        let lastFortNight = Calendar.current.date(byAdding: .day, value: -14, to: Date())
        for transaction in pendingTransactions {
            let transactionDate = isodateFormatter.date(from: transaction.transacted_at) ?? Date()
            //older than 14 days
            if transactionDate < lastFortNight! {
                deleteTransaction(transaction_guid: transaction.guid)
                continue
            }
            //matches posted transaction's GUID
            if let _ = postedTransactions.firstIndex(where: {$0.guid == transaction.guid}) {
                deleteTransaction(transaction_guid: transaction.guid)
                continue
            }
            //posted transaction matches name and merchant (time (amount - tips)
            if let _ = postedTransactions.firstIndex(where: {$0.description == transaction.description && $0.transacted_at == transaction.transacted_at && $0.account_guid == transaction.account_guid && $0.description == transaction.description}) {
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
            reference.child(financialMembersEntity).child(current_member_guid).removeValue()
            
            let accounts = self.memberAccountsDict[member]
            self.memberAccountsDict[member] = nil
            if let accounts = accounts {
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
                reference.child(userFinancialAccountsEntity).child(currentUserId).child(account.guid).removeValue()
                reference.child(financialAccountsEntity).child(account.guid).removeValue()
            }
        }
    }
    
    func getMXData() {
        let dispatchGroup = DispatchGroup()
        var updatedMembers = [MXMember]()
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
                        updatedMembers.append(member)
                        if let index = self.members.firstIndex(where: {$0.guid == member.guid}) {
                            self.members[index] = member
                            self.getInsitutionalDetails(institution_code: member.institution_code)
                        } else {
                            self.members.append(member)
                            self.getInsitutionalDetails(institution_code: member.institution_code)
                        }
                        if member.connection_status == .connected && !member.is_being_aggregated, let date = self.isodateFormatter.date(from: member.aggregated_at), date < Date().addingTimeInterval(-10800) {
                            Service.shared.aggregateMXMember(guid: user.guid, member_guid: member.guid) { (search, err)  in
                                if let member = search?.member {
                                    self.pollMemberStatus(guid: user.guid, member_guid: member.guid) { (member) in
                                        self.getMXAccounts(guid: user.guid, member_guid: member.guid) { (accounts) in
                                            self.memberAccountsDict[member] = accounts
                                            for account in accounts {
                                                dispatchGroup.enter()
                                                var _account = account
                                                if let index = self.accounts.firstIndex(where: {$0.guid == account.guid}) {
                                                    let date = self.isodateFormatter.date(from: _account.updated_at ) ?? Date()
                                                    self.getMXTransactions(user: user, account: _account, date: date.addingTimeInterval(-604800))
                                                    _account.balances = self.accounts[index].balances
                                                    _account.description = self.accounts[index].description
                                                    _account.admin = self.accounts[index].admin
                                                    _account.participantsIDs = self.accounts[index].participantsIDs
                                                    self.accounts[index] = _account
                                                } else {
                                                    self.getMXTransactions(user: user, account: _account, date: nil)
                                                    self.accounts.append(_account)
                                                }
                                                updatedAccounts.append(_account)
                                                dispatchGroup.leave()
                                            }
                                            dispatchGroup.leave()
                                        }
                                    }
                                }
                            }
                        } else if member.connection_status == .connected && !member.is_being_aggregated {
                            self.getMXAccounts(guid: user.guid, member_guid: member.guid) { (accounts) in
                                self.memberAccountsDict[member] = accounts
                                for account in accounts {
                                    dispatchGroup.enter()
                                    var _account = account
                                    if let index = self.accounts.firstIndex(where: {$0.guid == account.guid}) {
                                        let date = self.isodateFormatter.date(from: _account.updated_at ) ?? Date()
                                        self.getMXTransactions(user: user, account: _account, date: date.addingTimeInterval(-604800))
                                        _account.balances = self.accounts[index].balances
                                        _account.description = self.accounts[index].description
                                        _account.admin = self.accounts[index].admin
                                        _account.participantsIDs = self.accounts[index].participantsIDs
                                        self.accounts[index] = _account
                                    } else {
                                        self.getMXTransactions(user: user, account: _account, date: nil)
                                        self.accounts.append(_account)
                                    }
                                    updatedAccounts.append(_account)
                                    dispatchGroup.leave()
                                }
                                dispatchGroup.leave()
                            }
                        } else if member.connection_status == .connected && member.is_being_aggregated {
                            self.pollMemberStatus(guid: user.guid, member_guid: member.guid) { (member) in
                                self.getMXAccounts(guid: user.guid, member_guid: member.guid) { (accounts) in
                                    self.memberAccountsDict[member] = accounts
                                    for account in accounts {
                                        dispatchGroup.enter()
                                        var _account = account
                                        if let index = self.accounts.firstIndex(where: {$0.guid == account.guid}) {
                                            let date = self.isodateFormatter.date(from: _account.updated_at ) ?? Date()
                                            self.getMXTransactions(user: user, account: _account, date: date.addingTimeInterval(-604800))
                                            _account.balances = self.accounts[index].balances
                                            _account.description = self.accounts[index].description
                                            _account.admin = self.accounts[index].admin
                                            _account.participantsIDs = self.accounts[index].participantsIDs
                                            self.accounts[index] = _account
                                        } else {
                                            self.getMXTransactions(user: user, account: _account, date: nil)
                                            self.accounts.append(_account)
                                        }
                                        updatedAccounts.append(_account)
                                        dispatchGroup.leave()
                                    }
                                    dispatchGroup.leave()
                                }
                            }
                        } else {
                            dispatchGroup.leave()
                        }
                    }
                    dispatchGroup.leave()
                }
                dispatchGroup.leave()
            }
            dispatchGroup.leave()
        }
        
        dispatchGroup.notify(queue: .main) {
            self.updateFirebase(members: updatedMembers, accounts: updatedAccounts, transactions: [])
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
                        if self.transactions.first(where: { $0.guid == transaction.guid}) == nil {
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
                        if self.transactions.first(where: { $0.guid == transaction.guid}) == nil {
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
                    if self.transactions.first(where: { $0.guid == transaction.guid}) == nil {
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
            self.updateFirebase(members: [], accounts: [], transactions: newTransactions)
        }
    }
    
    func getMXUser(completion: @escaping (MXUser?) -> ()) {
        if let currentUser = Auth.auth().currentUser?.uid {
            let mxIDReference = Database.database().reference().child(userFinancialEntity).child(currentUser)
            mxIDReference.observeSingleEvent(of: .value, with: { (snapshot) in
                if snapshot.exists(), let value = snapshot.value {
                    if let user = try? FirebaseDecoder().decode(MXUser.self, from: value) {
                        self.mxUser = user
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
                            self.mxUser = user
                            completion(user)
                        }
                    }
                }
            })
        }
    }
    
    func deleteUserIfNecessary() {
        if self.members.isEmpty, let currentUser = Auth.auth().currentUser?.uid, let mxUser = mxUser {
            let mxIDReference = Database.database().reference().child(userFinancialEntity).child(currentUser)
            mxIDReference.removeValue()
            Service.shared.deleteMXUser(guid: mxUser.guid) { (string, err) in }
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
                    completion(member)
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
    
    func getInsitutionalDetails(institution_code: String) {
        Service.shared.getMXInstitution(institution_code: institution_code) { (search, err) in
            if let institution = search?.institution {
                self.institutionDict[institution_code] = institution.medium_logo_url
            }
        }
    }
    
    func observeMembersForCurrentUser() {
        self.memberFetcher.observeMemberForCurrentUser(membersAdded: { [weak self] membersAdded in
            for member in membersAdded {
                if let index = self!.members.firstIndex(where: {$0.guid == member.guid}) {
                    self!.members[index] = member
                } else {
                    self!.members.append(member)
                }
            }
        })
    }
    
    func observeAccountsForCurrentUser() {
        self.accountFetcher.observeAccountForCurrentUser(accountsAdded: { [weak self] accountsAdded in
            for account in accountsAdded {
                if let index = self!.accounts.firstIndex(where: {$0.guid == account.guid}) {
                    self!.accounts[index] = account
                } else {
                    self!.accounts.append(account)
                }
            }
        }, accountsChanged: { [weak self] accountsChanged in
            for account in accountsChanged {
                if let index = self!.accounts.firstIndex(where: {$0.guid == account.guid}) {
                    self!.accounts[index] = account
                }
            }
        })
    }
    
    func observeTransactionsForCurrentUser() {
        self.transactionFetcher.observeTransactionForCurrentUser(transactionsAdded: { [weak self] transactionsAdded in
            for transaction in transactionsAdded {
                if let index = self!.transactions.firstIndex(where: {$0.guid == transaction.guid}) {
                    self!.transactions[index] = transaction
                } else {
                    self!.transactions.append(transaction)
                }
            }
        }, transactionsChanged: { [weak self] transactionsChanged in
            for transaction in transactionsChanged {
                if let index = self!.transactions.firstIndex(where: {$0.guid == transaction.guid}) {
                    self!.transactions[index] = transaction
                }
            }
        })
    }
    
    func observeTransactionRulesForCurrentUser() {
        self.transactionRuleFetcher.observeTransactionRuleForCurrentUser(transactionRulesAdded: { [weak self] transactionRulesAdded in
            var newTransactions = [Transaction]()
            for transactionRule in transactionRulesAdded {
                if let index = self!.transactionRules.firstIndex(where: {$0.guid == transactionRule.guid}) {
                    self!.transactionRules[index] = transactionRule
                } else {
                    self!.transactionRules.append(transactionRule)
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
            }, transactionRulesRemoved: { [weak self] transactionRulesRemoved in
                for transactionRule in transactionRulesRemoved {
                    if let index = self!.transactionRules.firstIndex(where: {$0.guid == transactionRule.guid}) {
                        self!.transactionRules[index] = transactionRule
                    }
                }
            }, transactionRulesChanged: { [weak self] transactionRulesChanged in
                var newTransactions = [Transaction]()
                for transactionRule in transactionRulesChanged {
                    if let index = self!.transactionRules.firstIndex(where: {$0.guid == transactionRule.guid}) {
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
    
    func observeHoldingsForCurrentUser() {
        self.holdingFetcher.observeHoldingForCurrentUser(holdingsAdded: { [weak self] holdingsAdded in
            for holding in holdingsAdded {
                if let index = self!.holdings.firstIndex(where: {$0.guid == holding.guid}) {
                    self!.holdings[index] = holding
                } else {
                    self!.holdings.append(holding)
                }
            }
        }, holdingsChanged: { [weak self] holdingsChanged in
            for holding in holdingsChanged {
                if let index = self!.holdings.firstIndex(where: {$0.guid == holding.guid}) {
                    self!.holdings[index] = holding
                }
            }
        })
    }
    
    private func updateFirebase(members: [MXMember], accounts: [MXAccount], transactions: [Transaction]) {
        guard let currentUserID = Auth.auth().currentUser?.uid else {
            return
        }
        let ref = Database.database().reference()
        for member in members {
            do {
                // store account info
                let value = try FirebaseEncoder().encode(member)
                ref.child(financialMembersEntity).child(member.guid).setValue(value)
                // store account balance at given date
                ref.child(userFinancialMembersEntity).child(currentUserID).child(member.guid).child("name").setValue(member.name)
            } catch let error {
                print(error)
            }
        }
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
