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
    static let transactionRulesUpdated = NSNotification.Name(Bundle.main.bundleIdentifier! + ".transactionRulesUpdated")
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
    var transactionRules = [TransactionRule]() {
        didSet {
            if oldValue != transactionRules {
                transactionRules.sort { (rule1, rule2) -> Bool in
                    return rule1.match_description < rule2.match_description
                }
                NotificationCenter.default.post(name: .transactionRulesUpdated, object: nil)
            }
        }
    }
    var hasLoadedFinancials = false {
        didSet {
            NotificationCenter.default.post(name: .hasLoadedFinancials, object: nil)
        }
    }
    var memberAccountsDict = [MXMember: [MXAccount]]()
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
        self.observeAccountsForCurrentUser {}
        self.transactionRuleFetcher.fetchTransactionRules(completion: { transactionRules in
            self.transactionRules = transactionRules
            self.observeTransactionsForCurrentUser {
                self.grabAccountTransactions()
                self.removePendingTransactions()
                self.flagTransfersBetweenAccounts()
                if self.isRunning {
                    self.isRunning = false
                    completion()
                }
            }
        })
        self.observeTransactionRulesForCurrentUser {}
        self.observeHoldingsForCurrentUser()
        self.observeMembersForCurrentUser {}
    }
    
    func setupFirebase() {
        self.observeAccountsForCurrentUser {}
        self.transactionRuleFetcher.fetchTransactionRules(completion: { transactionRules in
            self.transactionRules = transactionRules
            self.observeTransactionsForCurrentUser {}
            self.hasLoadedFinancials = true
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
        if let currentUserID = Auth.auth().currentUser?.uid, let index = self.transactions.firstIndex(where: {$0.guid == transaction_guid}) {
            self.transactions.remove(at: index)
            let reference = Database.database().reference()
            reference.child(userFinancialTransactionsEntity).child(currentUserID).child(transaction_guid).removeValue()
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
        if let currentUserID = Auth.auth().currentUser?.uid, let index = self.members.firstIndex(where: {$0.guid == current_member_guid}) {
            self.members.remove(at: index)
            let reference = Database.database().reference()
            reference.child(userFinancialMembersEntity).child(currentUserID).child(current_member_guid).removeValue()
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
        if let currentUserID = Auth.auth().currentUser?.uid {
            let reference = Database.database().reference()
            for account in accounts {
                if let index = self.accounts.firstIndex(where: {$0.guid == account.guid}) {
                    self.accounts.remove(at: index)
                }
                reference.child(userFinancialAccountsEntity).child(currentUserID).child(account.guid).removeValue()
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
                    if let index = self?.accounts.firstIndex(where: {$0.guid == account.guid}) {
                        self?.accounts[index] = account
                    } else {
                        self?.accounts.append(account)
                    }
                }
            } else {
                completion()
            }
            self?.createTasksFromAccounts(accounts: accountsInitialAdd)
        }, accountsAdded: { [weak self] accountsAdded in
            for account in accountsAdded {
                if let index = self?.accounts.firstIndex(where: {$0.guid == account.guid}) {
                    self?.accounts[index] = account
                } else {
                    self?.accounts.append(account)
                }
            }
            self?.createTasksFromAccounts(accounts: accountsAdded)
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
            self?.createEventsFromTransactions(transactions: transactionsInitialAdd)
            self?.createTasksFromTransactions(transactions: transactionsInitialAdd) {
                self?.createFutureTasksFromRecurringTransactions(transactions: self!.transactions)
            }
            self?.updateTasksFromAccounts(accounts: self!.accounts)
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
            self?.createEventsFromTransactions(transactions: transactionsAdded)
            self?.createTasksFromTransactions(transactions: transactionsAdded) {
                self?.createFutureTasksFromRecurringTransactions(transactions: self!.transactions)
            }
            self?.updateTasksFromAccounts(accounts: self!.accounts)
        }, transactionsRemoved: { [weak self] transactionsRemoved in
            for transaction in transactionsRemoved {
                if let index = self?.transactions.firstIndex(where: {$0.guid == transaction.guid}) {
                    self?.transactions.remove(at: index)
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
    
    private func flagTransfersBetweenAccounts() {
        let reference = Database.database().reference().child(financialTransactionsEntity)
        for transaction in transactions {
            guard !(transaction.transfer_between_accounts ?? false) else { continue }
            if (transaction.type == .credit && accounts.first(where: {$0.guid == transaction.account_guid})?.type == .creditCard) || transaction.category == "Credit Card Payment" {
                reference.child(transaction.guid).child("transfer_between_accounts").setValue(true)
            }
        }
    }
    
    private func createTasksFromAccounts(accounts: [MXAccount]) {
        guard let currentUserID = Auth.auth().currentUser?.uid else {
            return
        }
        let reference = Database.database().reference().child(userFinancialAccountsTasksEntity).child(currentUserID)
        reference.observeSingleEvent(of: .value) { dataSnapshot in
            if dataSnapshot.exists(), let dataSnapshotValue = dataSnapshot.value as? [String: [String: String]] {
                for account in accounts {
                    if let accountTasks = dataSnapshotValue[account.guid], let payment_due_at = account.payment_due_at {
                        if accountTasks[payment_due_at] == nil {
                            TaskBuilder.createActivityWithList(from: account) { activity in
                                if let activity = activity, let activityID = activity.activityID {
                                    reference.child(account.guid).child(payment_due_at).setValue(activityID)
                                    let activityActions = ActivityActions(activity: activity, active: false, selectedFalconUsers: [])
                                    activityActions.createNewActivity(updateDirectAssociation: false)
                                }
                            }
                        }
                    }
                }
            } else {
                for account in accounts {
                    if let payment_due_at = account.payment_due_at {
                        TaskBuilder.createActivityWithList(from: account) { activity in
                            if let activity = activity, let activityID = activity.activityID {
                                reference.child(account.guid).child(payment_due_at).setValue(activityID)
                                let activityActions = ActivityActions(activity: activity, active: false, selectedFalconUsers: [])
                                activityActions.createNewActivity(updateDirectAssociation: false)
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func updateTasksFromAccounts(accounts: [MXAccount]) {
        guard let currentUserID = Auth.auth().currentUser?.uid else {
            return
        }
        let isodateFormatter = ISO8601DateFormatter()
        let reference = Database.database().reference().child(userFinancialAccountsTasksEntity).child(currentUserID)
        reference.observeSingleEvent(of: .value) { dataSnapshot in
            if dataSnapshot.exists(), let dataSnapshotValue = dataSnapshot.value as? [String: [String: String]] {
                for account in accounts {
                    if let accountTasks = dataSnapshotValue[account.guid], let payment_due_at = account.payment_due_at {
                        if let activityID = accountTasks[payment_due_at] {
                            let transactions = self.transactions.filter({ $0.account_guid == account.guid && $0.type == .credit && $0.description.lowercased().contains("payment") &&  Calendar.current.numberOfDaysBetween(isodateFormatter.date(from: $0.transacted_at) ?? Date.distantPast, and: isodateFormatter.date(from: payment_due_at) ?? Date.distantFuture) < 30 })
                            if !transactions.isEmpty {
                                ActivitiesFetcher.getDataFromSnapshot(ID: activityID, parentID: nil) { activities in
                                    if let activity = activities.first, !(activity.isCompleted ?? false) {
                                        let activityAction = ActivityActions(activity: activity, active: true, selectedFalconUsers: [])
                                        activityAction.updateCompletion(isComplete: true)
                                        let containerID = Database.database().reference().child(containerEntity).childByAutoId().key ?? ""
                                        let container = Container(id: containerID, activityIDs: nil, taskIDs: [activity.activityID ?? ""], workoutIDs: nil, mindfulnessIDs: nil, mealIDs: nil, transactionIDs: transactions.map({$0.guid}), participantsIDs: activity.participantsIDs)
                                        ContainerFunctions.updateContainerAndStuffInside(container: container)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func updateTransactionCreateContainer(transaction: Transaction, activity: Activity) {
        let activityActions = ActivityActions(activity: activity, active: false, selectedFalconUsers: [])
        activityActions.createNewActivity(updateDirectAssociation: false)
        if activity.isTask ?? false {
            let containerID = Database.database().reference().child(containerEntity).childByAutoId().key ?? ""
            let container = Container(id: containerID, activityIDs: nil, taskIDs: [activity.activityID ?? ""], workoutIDs: nil, mindfulnessIDs: nil, mealIDs: nil, transactionIDs: [transaction.guid], participantsIDs: transaction.participantsIDs)
            ContainerFunctions.updateContainerAndStuffInside(container: container)
        } else {
            let containerID = Database.database().reference().child(containerEntity).childByAutoId().key ?? ""
            let container = Container(id: containerID, activityIDs: [activity.activityID ?? ""], taskIDs: nil, workoutIDs: nil, mindfulnessIDs: nil, mealIDs: nil, transactionIDs: [transaction.guid], participantsIDs: transaction.participantsIDs)
            ContainerFunctions.updateContainerAndStuffInside(container: container)
        }
    }
    
    private func createEventsFromTransactions(transactions: [Transaction]) {
        guard let currentUserID = Auth.auth().currentUser?.uid else {
            return
        }
        
        let userReference = Database.database().reference().child(userFinancialTransactionsEventsEntity).child(currentUserID)
        
        userReference.observeSingleEvent(of: .value) { dataSnapshot in
            if dataSnapshot.exists(), let dataSnapshotValue = dataSnapshot.value as? [String: String] {
                categorizeTransactionsIntoEvents(transactions: transactions) { [self] transactionsActivities in
                    for (transaction, activity) in transactionsActivities {
                        if dataSnapshotValue[transaction.guid] == nil, let activityID = activity.activityID {
                            userReference.child(transaction.guid).setValue(activityID)
                            self.updateTransactionCreateContainer(transaction: transaction, activity: activity)
                        }
                    }
                }
            } else {
                categorizeTransactionsIntoEvents(transactions: transactions) { transactionsActivities in
                    for (transaction, activity) in transactionsActivities {
                        if let activityID = activity.activityID {
                            userReference.child(transaction.guid).setValue(activityID)
                            self.updateTransactionCreateContainer(transaction: transaction, activity: activity)
                        }
                    }
                }
            }
        }
    }
    
    private func createTasksFromTransactions(transactions: [Transaction], completion: @escaping () -> Void) {
        guard let currentUserID = Auth.auth().currentUser?.uid else {
            return
        }
        
        let userReference = Database.database().reference().child(userFinancialTransactionsTasksEntity).child(currentUserID)
        let reference = Database.database().reference().child(financialTransactionsEntity)
        
        
        userReference.observeSingleEvent(of: .value) { dataSnapshot in
            if dataSnapshot.exists(), let dataSnapshotValue = dataSnapshot.value as? [String: String] {
                categorizeTransactionsIntoTasks(transactions: transactions) { [self] transactionsActivities in
                    for (transaction, activity) in transactionsActivities {
                        if dataSnapshotValue[transaction.guid] == nil, let activityID = activity.activityID {
                            userReference.child(transaction.guid).setValue(activityID)
                            reference.child(transaction.guid).child("plot_is_recurring").setValue(true)
                            self.updateTransactionCreateContainer(transaction: transaction, activity: activity)
                        }
                    }
                    completion()
                }
            } else {
                categorizeTransactionsIntoTasks(transactions: transactions) { transactionsActivities in
                    for (transaction, activity) in transactionsActivities {
                        if let activityID = activity.activityID {
                            userReference.child(transaction.guid).setValue(activityID)
                            reference.child(transaction.guid).child("plot_is_recurring").setValue(true)
                            self.updateTransactionCreateContainer(transaction: transaction, activity: activity)
                        }
                    }
                    completion()
                }
            }
        }
    }
    
    private func createFutureTransaction(oldTransaction: Transaction, newDateString: String, averageAmount: Double) {
        guard let currentUserID = Auth.auth().currentUser?.uid else {
            return
        }
        
        let userReference = Database.database().reference().child(userFinancialTransactionsTasksEntity).child(currentUserID)
        let ID = Database.database().reference().child(userFinancialTransactionsEntity).child(currentUserID).childByAutoId().key ?? ""
        var newTransaction = oldTransaction
        newTransaction.guid = ID
        newTransaction.status = .pending
        newTransaction.plot_created = true
        newTransaction.amount = averageAmount
        newTransaction.transacted_at = newDateString
        newTransaction.containerID = nil
        TaskBuilder.createActivityWithList(from: newTransaction) { task in
            if let task = task, let activityID = task.activityID {
                let createTransaction = TransactionActions(transaction: newTransaction, active: false, selectedFalconUsers: [])
                createTransaction.createNewTransaction()

                userReference.child(newTransaction.guid).setValue(activityID)
                self.updateTransactionCreateContainer(transaction: newTransaction, activity: task)
            }
        }
        
    }
    
    private func createFutureTasksFromRecurringTransactions(transactions: [Transaction]) {
        guard let currentUserID = Auth.auth().currentUser?.uid else {
            return
        }
        
        let userReference = Database.database().reference().child(userFinancialTransactionsTasksEntity).child(currentUserID)
        
        userReference.observeSingleEvent(of: .value) { dataSnapshot in
            if dataSnapshot.exists(), let dataSnapshotValue = dataSnapshot.value as? [String: String] {
                let isodateFormatter = ISO8601DateFormatter()
                
                let recurringTransactions = transactions.filter({$0.plot_is_recurring ?? false})
                
                let descriptionsMerchants = recurringTransactions.reduce(into: [String: String]()) {
                    $0[$1.description] = $1.merchant_guid ?? ""
                }
                for (description, merchant) in descriptionsMerchants {
                    let filteredTransactions = recurringTransactions.filter({ $0.description == description && $0.merchant_guid ?? "" == merchant }).sorted(by: {
                        return isodateFormatter.date(from: $0.transacted_at) ?? Date() > isodateFormatter.date(from: $1.transacted_at) ?? Date()
                    })
                    //make sure first && second transactions are not plot_created, if not create new transaction/task
                    //if first is plot_created && transacted_date is more than 7 days past, then delete transaction and activity given recurrances may have stopped, otherwise do nothing
                    //if second is plot_created, potentially delete if first is 'real' transaction and reassign existing task to 'real' transaction
                    //make sure new plot_created transaction is in the future
                    if filteredTransactions.count > 1 {
                        if !(filteredTransactions[0].plot_created ?? false), !(filteredTransactions[1].plot_created ?? false), let first = isodateFormatter.date(from: filteredTransactions[0].transacted_at) {
                            var days = 0
                            if let mostFrequentDays = getMostFrequentDaysBetweenRecurringTransactions(transactions: filteredTransactions) {
                                days = mostFrequentDays
                            } else if let second = isodateFormatter.date(from: filteredTransactions[1].transacted_at) {
                                days = Calendar.current.numberOfDaysBetween(second, and: first)
                            }
                            let newDate = first.addDays(days)
                            if newDate > Date(), !filteredTransactions.contains(where: { $0.transacted_at == isodateFormatter.string(from: newDate) }) {
                                self.createFutureTransaction(oldTransaction: filteredTransactions[0], newDateString: isodateFormatter.string(from: newDate), averageAmount: filteredTransactions.reduce(0.0, {$0 + $1.amount}) / Double(filteredTransactions.count))
                                
                            }
                        } else if filteredTransactions[0].plot_created ?? false, !(filteredTransactions[1].plot_created ?? false), let first = isodateFormatter.date(from: filteredTransactions[0].transacted_at), let second = isodateFormatter.date(from: filteredTransactions[1].transacted_at) {
                            let deleteTransaction = filteredTransactions[0]
                            let days = Calendar.current.numberOfDaysBetween(first, and: second)
                            if days < 7 {
                                let keepTransaction = filteredTransactions[1]
                                if keepTransaction.containerID == nil, let activityID = dataSnapshotValue[deleteTransaction.guid], let containerID = deleteTransaction.containerID {
                                    userReference.child(deleteTransaction.guid).setValue(nil)
                                    ParticipantsFetcher.getParticipants(forTransaction: deleteTransaction) { users in
                                        let transactionAction = TransactionActions(transaction: deleteTransaction, active: true, selectedFalconUsers: users)
                                        transactionAction.deleteTransaction()
                                    }
                                    
                                    ActivitiesFetcher.getDataFromSnapshot(ID: activityID, parentID: nil) { activities in
                                        if let activity = activities.first, !(activity.isCompleted ?? false) {
                                            let activityAction = ActivityActions(activity: activity, active: true, selectedFalconUsers: [])
                                            activityAction.updateCompletion(isComplete: true)
                                        }
                                    }

                                    userReference.child(keepTransaction.guid).setValue(activityID)
                                    ContainerFunctions.grabContainerAndStuffInside(id: containerID) { container, _, _, _, transactions in
                                        if let transactions = transactions {
                                            var newTransactions = transactions.filter({ $0.guid != deleteTransaction.guid })
                                            newTransactions.append(keepTransaction)
                                            var newContainer = container
                                            newContainer.transactionIDs = newTransactions.map({ $0.guid })
                                            ContainerFunctions.updateContainerAndStuffInside(container: newContainer)
                                        }
                                    }
                                } else if let activityID = dataSnapshotValue[deleteTransaction.guid] {
                                    ParticipantsFetcher.getParticipants(forTransaction: deleteTransaction) { users in
                                        let transactionAction = TransactionActions(transaction: deleteTransaction, active: true, selectedFalconUsers: users)
                                        transactionAction.deleteTransaction()
                                    }
                                    
                                    ActivitiesFetcher.getDataFromSnapshot(ID: activityID, parentID: nil) { activities in
                                        if let activity = activities.first, !(activity.isCompleted ?? false) {
                                            let activityAction = ActivityActions(activity: activity, active: true, selectedFalconUsers: [])
                                            activityAction.deleteActivity(updateExternal: true, updateDirectAssociation: false)
                                        }
                                    }
                                }
                                
                                var days = 0
                                if let mostFrequentDays = getMostFrequentDaysBetweenRecurringTransactions(transactions: filteredTransactions) {
                                    days = mostFrequentDays
                                } else if filteredTransactions.count > 2, let third = isodateFormatter.date(from: filteredTransactions[2].transacted_at) {
                                    days = Calendar.current.numberOfDaysBetween(third, and: second)
                                } else {
                                    days = Calendar.current.numberOfDaysBetween(second, and: first)
                                }
                                let newDate = second.addDays(days)
                                if newDate > Date(), !filteredTransactions.contains(where: { $0.transacted_at == isodateFormatter.string(from: newDate) }) {
                                    self.createFutureTransaction(oldTransaction: keepTransaction, newDateString: isodateFormatter.string(from: newDate), averageAmount: filteredTransactions.reduce(0.0, {$0 + $1.amount}) / Double(filteredTransactions.count))
                                }
                            } else {
                                let days = Calendar.current.numberOfDaysBetween(first, and: Date())
                                if days > 7 {
                                    //delete transaction and activity
                                    if let activityID = dataSnapshotValue[deleteTransaction.guid] {
                                        ParticipantsFetcher.getParticipants(forTransaction: deleteTransaction) { users in
                                            let transactionAction = TransactionActions(transaction: deleteTransaction, active: true, selectedFalconUsers: users)
                                            transactionAction.deleteTransaction()
                                        }
                                        ActivitiesFetcher.getDataFromSnapshot(ID: activityID, parentID: nil) { activities in
                                            if let activity = activities.first {
                                                ParticipantsFetcher.getParticipants(forActivity: activity) { users in
                                                    let activityAction = ActivityActions(activity: activity, active: true, selectedFalconUsers: users)
                                                    activityAction.deleteActivity(updateExternal: true, updateDirectAssociation: false)
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        else if !(filteredTransactions[0].plot_created ?? false), filteredTransactions[1].plot_created ?? false, let first = isodateFormatter.date(from: filteredTransactions[0].transacted_at), let second = isodateFormatter.date(from: filteredTransactions[1].transacted_at) {
                            let days = Calendar.current.numberOfDaysBetween(first, and: second)
                            if days < 7 {
                                //delete second transaction, assign first transaction to container, update reference & update task to complete; create next plot_created transaction/activity
                                let keepTransaction = filteredTransactions[0]
                                let deleteTransaction = filteredTransactions[1]
                                if keepTransaction.containerID == nil, let activityID = dataSnapshotValue[deleteTransaction.guid], let containerID = deleteTransaction.containerID {
                                    userReference.child(deleteTransaction.guid).setValue(nil)
                                    ParticipantsFetcher.getParticipants(forTransaction: deleteTransaction) { users in
                                        let transactionAction = TransactionActions(transaction: deleteTransaction, active: true, selectedFalconUsers: users)
                                        transactionAction.deleteTransaction()
                                    }
                                    
                                    ActivitiesFetcher.getDataFromSnapshot(ID: activityID, parentID: nil) { activities in
                                        if let activity = activities.first, !(activity.isCompleted ?? false) {
                                            let activityAction = ActivityActions(activity: activity, active: true, selectedFalconUsers: [])
                                            activityAction.updateCompletion(isComplete: true)
                                        }
                                    }

                                    userReference.child(keepTransaction.guid).setValue(activityID)
                                    ContainerFunctions.grabContainerAndStuffInside(id: containerID) { container, _, _, _, transactions in
                                        if let transactions = transactions {
                                            var newTransactions = transactions.filter({ $0.guid != deleteTransaction.guid })
                                            newTransactions.append(keepTransaction)
                                            var newContainer = container
                                            newContainer.transactionIDs = newTransactions.map({ $0.guid })
                                            ContainerFunctions.updateContainerAndStuffInside(container: newContainer)
                                        }
                                    }
                                } else if let activityID = dataSnapshotValue[deleteTransaction.guid] {
                                    ParticipantsFetcher.getParticipants(forTransaction: deleteTransaction) { users in
                                        let transactionAction = TransactionActions(transaction: deleteTransaction, active: true, selectedFalconUsers: users)
                                        transactionAction.deleteTransaction()
                                    }
                                    
                                    ActivitiesFetcher.getDataFromSnapshot(ID: activityID, parentID: nil) { activities in
                                        if let activity = activities.first, !(activity.isCompleted ?? false) {
                                            let activityAction = ActivityActions(activity: activity, active: true, selectedFalconUsers: [])
                                            activityAction.deleteActivity(updateExternal: true, updateDirectAssociation: false)
                                        }
                                    }
                                }
                                
                                var days = 0
                                if let mostFrequentDays = getMostFrequentDaysBetweenRecurringTransactions(transactions: filteredTransactions) {
                                    days = mostFrequentDays
                                } else if filteredTransactions.count > 2, let third = isodateFormatter.date(from: filteredTransactions[2].transacted_at) {
                                    days = Calendar.current.numberOfDaysBetween(third, and: second)
                                }
                                let newDate = first.addDays(days)
                                if newDate > Date(), !filteredTransactions.contains(where: { $0.transacted_at == isodateFormatter.string(from: newDate) }) {
                                    self.createFutureTransaction(oldTransaction: keepTransaction, newDateString: isodateFormatter.string(from: newDate), averageAmount: filteredTransactions.reduce(0.0, {$0 + $1.amount}) / Double(filteredTransactions.count))
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
