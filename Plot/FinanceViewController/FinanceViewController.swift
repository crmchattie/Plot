//
//  FinanceViewController.swift
//  Plot
//
//  Created by Cory McHattie on 8/21/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import UIKit
import Firebase
import CodableFirebase

protocol HomeBaseFinance: class {
    func sendUser(user: MXUser)
}

class FinanceViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    weak var delegate: HomeBaseFinance?
    
    let collectionView:UICollectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout: UICollectionViewFlowLayout.init())
    let layout:UICollectionViewFlowLayout = UICollectionViewFlowLayout.init()
    
    let customSegmented = CustomSegmentedControl(buttonImages: nil, buttonTitles: ["Day","Week","Month", "Year"])
    var index: Int = 2
    
    var transactions = [Transaction]()
    var transactionRules = [TransactionRule]()
    var accounts = [MXAccount]()
    var members = [MXMember]()
    var user: MXUser!
    
    var users = [User]()
    var filteredUsers = [User]()
    
    var transactionsAcctDict = [MXAccount: [Transaction]]()
    
    var transactionDict = [TransactionDetails: [Transaction]]()
    var accountDict = [AccountDetails: [MXAccount]]()
    
    var institutionDict = [String: String]()
    
    var sections: [SectionType] = [.balanceSheet, .financialAccounts, .incomeStatement, .transactions]
    var groups = [SectionType: [AnyHashable]]()
    
    let transactionFetcher = FinancialTransactionFetcher()
    let transactionRuleFetcher = FinancialTransactionRuleFetcher()
    let accountFetcher = FinancialAccountFetcher()
    
    private let kHeaderCell = "HeaderCell"
    private let kFinanceCollectionViewCell = "FinanceCollectionViewCell"
    private let kFinanceCollectionViewMemberCell = "FinanceCollectionViewMemberCell"
    
    let isodateFormatter = ISO8601DateFormatter()
    let dateFormatterPrint = DateFormatter()
    
    var startDate = Date().startOfMonth
    var endDate = Date().endOfMonth
    
    var hasViewAppeared = false
    
    var participants: [String: [User]] = [:]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupMainView()
        addObservers()
        
        getFinancialData()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    fileprivate func addObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(changeTheme), name: .themeUpdated, object: nil)
    }
    
    @objc fileprivate func changeTheme() {
        view.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
        
        navigationController?.navigationBar.barStyle = ThemeManager.currentTheme().barStyle
        navigationController?.navigationBar.barTintColor = ThemeManager.currentTheme().barBackgroundColor
        let textAttributes = [NSAttributedString.Key.foregroundColor: ThemeManager.currentTheme().generalTitleColor]
        navigationController?.navigationBar.titleTextAttributes = textAttributes
        navigationController?.navigationBar.largeTitleTextAttributes = textAttributes
        navigationController?.navigationBar.backgroundColor = ThemeManager.currentTheme().barBackgroundColor
        
        tabBarController?.tabBar.barTintColor = ThemeManager.currentTheme().barBackgroundColor
        tabBarController?.tabBar.barStyle = ThemeManager.currentTheme().barStyle
        
        collectionView.indicatorStyle = ThemeManager.currentTheme().scrollBarStyle
        collectionView.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
        collectionView.reloadData()
        
    }
    
    fileprivate func setupMainView() {
        navigationItem.largeTitleDisplayMode = .never
        navigationController?.navigationBar.prefersLargeTitles = false
        
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for:.default)
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.navigationBar.layoutIfNeeded()
        
        extendedLayoutIncludesOpaqueBars = true
        definesPresentationContext = true
        edgesForExtendedLayout = UIRectEdge.top
        view.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
        
        customSegmented.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
        customSegmented.constrainHeight(30)
        customSegmented.delegate = self
                
        layout.scrollDirection = UICollectionView.ScrollDirection.vertical
        collectionView.setCollectionViewLayout(layout, animated: true)
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(HeaderCell.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: kHeaderCell)
        collectionView.register(FinanceCollectionViewCell.self, forCellWithReuseIdentifier: kFinanceCollectionViewCell)
        collectionView.register(FinanceCollectionViewMemberCell.self, forCellWithReuseIdentifier: kFinanceCollectionViewMemberCell)
        collectionView.isUserInteractionEnabled = true
        collectionView.indicatorStyle = ThemeManager.currentTheme().scrollBarStyle
        collectionView.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
        
        view.addSubview(customSegmented)
        view.addSubview(collectionView)
                        
        customSegmented.anchor(top: view.safeAreaLayoutGuide.topAnchor, leading: view.safeAreaLayoutGuide.leadingAnchor, bottom: nil, trailing: view.safeAreaLayoutGuide.trailingAnchor, padding: .init(top: 0, left: 0, bottom: 0, right: 0))
        collectionView.anchor(top: customSegmented.bottomAnchor, leading: view.safeAreaLayoutGuide.leadingAnchor, bottom: view.safeAreaLayoutGuide.bottomAnchor, trailing: view.safeAreaLayoutGuide.trailingAnchor, padding: .init(top: 10, left: 0, bottom: 0, right: 0))
        

    }
    
    func getFinancialData() {
        let dispatchGroup = DispatchGroup()
        dispatchGroup.enter()
        accountFetcher.fetchAccounts { (firebaseAccounts) in
            self.accounts = firebaseAccounts
            self.observeAccountsForCurrentUser()
            dispatchGroup.leave()
        }
        
        dispatchGroup.enter()
        self.transactionRuleFetcher.fetchTransactionRules { (firebaseTransactionRules) in
            self.transactionRules = firebaseTransactionRules
            self.observeTransactionRulesForCurrentUser()
            self.transactionFetcher.fetchTransactions { (firebaseTransactions) in
                self.transactions = firebaseTransactions
                self.observeTransactionsForCurrentUser()
                dispatchGroup.leave()
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            self.getMXData()
            self.updateCollectionView()
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
                self.delegate?.sendUser(user: user)
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
                                            updatedAccounts.append(contentsOf: accounts)
                                            for account in accounts {
                                                dispatchGroup.enter()
                                                if !self.accounts.contains(account) {
                                                    self.getMXTransactions(user: user, account: account, date: nil)
                                                }
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
                                print("accountName #1 \(account.name)")
                                updatedAccounts.append(contentsOf: accounts)
                                for account in accounts {
                                    dispatchGroup.enter()
                                    if !self.accounts.contains(account) {
                                        self.getMXTransactions(user: user, account: account, date: nil)
                                    }
                                    dispatchGroup.leave()
                                }
                                dispatchGroup.leave()
                            }
                        } else if (member.connection_status == .prevented || member.connection_status == .denied) && !member.is_being_aggregated {
                            dispatchGroup.enter()
                            if !self.sections.contains(.issues) {
                                self.sections.insert(.issues, at: 0)
                            }
                            self.members.append(member)
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
            for account in updatedAccounts {
                print("accountName #2 \(account.name)")
            }
            self.accounts = updatedAccounts
            self.updateCollectionView()
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
                            updateTransaction(transaction: transaction, transactionRules: self.transactionRules) { (transaction) in
                                if finalAccount?.should_link ?? true {
                                    self.transactions.append(transaction)
                                    if transaction.status != .pending {
                                        newTransactions.append(transaction)
                                    }
                                } else {
                                    var _transaction = transaction
                                    self.transactions.append(_transaction)
                                    _transaction.should_link = false
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
                            updateTransaction(transaction: transaction, transactionRules: self.transactionRules) { (transaction) in
                                if finalAccount?.should_link ?? true {
                                    self.transactions.append(transaction)
                                    if transaction.status != .pending {
                                        newTransactions.append(transaction)
                                    }
                                } else {
                                    var _transaction = transaction
                                    self.transactions.append(_transaction)
                                    _transaction.should_link = false
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
            let date = self.isodateFormatter.date(from: account!.updated_at) ?? Date()
            self.getTransactions(guid: user.guid, from_date: date.addingTimeInterval(-604800), to_date: Date().addingTimeInterval(86400)) { (transactions) in
                for transaction in transactions {
                    dispatchGroup.enter()
                    let finalAccount = self.accounts.first(where: { $0.guid == transaction.account_guid})
                    if !self.transactions.contains(transaction) {
                        updateTransaction(transaction: transaction, transactionRules: self.transactionRules) { (transaction) in
                            if finalAccount?.should_link ?? true {
                                self.transactions.append(transaction)
                                if transaction.status != .pending {
                                    newTransactions.append(transaction)
                                }
                            } else {
                                var _transaction = transaction
                                self.transactions.append(_transaction)
                                _transaction.should_link = false
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
            self.updateCollectionView()
            self.updateFirebase(accounts: [], transactions: newTransactions)
        }
    }
    
    func getMXUser(completion: @escaping (MXUser?) -> ()) {
        if let currentUser = Auth.auth().currentUser?.uid {
            let mxIDReference = Database.database().reference().child(userFinancialEntity).child(currentUser)
            mxIDReference.observeSingleEvent(of: .value, with: { (snapshot) in
                if snapshot.exists(), let value = snapshot.value {
                    if let user = try? FirebaseDecoder().decode(MXUser.self, from: value) {
                        self.user = user
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
                            self.user = user
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
    
    func openMXConnect(guid: String, current_member_guid: String?) {
        Service.shared.getMXConnectURL(guid: guid, current_member_guid: current_member_guid ?? nil) { (search, err) in
            if let url = search?.user?.connect_widget_url {
                DispatchQueue.main.async {
                    let destination = WebViewController()
                    destination.urlString = url
                    destination.controllerTitle = ""
                    destination.delegate = self
                    let navigationViewController = UINavigationController(rootViewController: destination)
                    navigationViewController.modalPresentationStyle = .fullScreen
                    self.present(navigationViewController, animated: true, completion: nil)
                }
            }
        }
    }
    
    func pollMemberStatus(guid: String, member_guid: String, completion: @escaping (MXMember) -> ()) {
        Service.shared.getMXMember(guid: guid, member_guid: member_guid) { (search, err) in
            if let member = search?.member {
                if member.connection_status == .challenged {
                    if !self.sections.contains(.issues) {
                        self.sections.insert(.issues, at: 0)
                    }
                    self.members.append(member)
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
                    self!.updateCollectionView()
                }
            }
            }, accountsRemoved: { [weak self] accountsRemoved in
                for account in accountsRemoved {
                    if let index = self!.accounts.firstIndex(where: {$0 == account}) {
                        self!.accounts.remove(at: index)
                        self!.updateCollectionView()
                    }
                }
            }, accountsChanged: { [weak self] accountsChanged in
                for account in accountsChanged {
                    if let index = self!.accounts.firstIndex(where: {$0 == account}) {
                        self!.accounts[index] = account
                        self!.updateCollectionView()
                    }
                }
            }
        )
    }
    
    func observeTransactionsForCurrentUser() {
        self.transactionFetcher.observeTransactionForCurrentUser(transactionsAdded: { [weak self] transactionsAdded in
            for transaction in transactionsAdded {
                if !self!.transactions.contains(transaction) {
                    self!.transactions.append(transaction)
                    self!.updateCollectionView()
                }
            }
            }, transactionsRemoved: { [weak self] transactionsRemoved in
                for transaction in transactionsRemoved {
                    if let index = self!.transactions.firstIndex(where: {$0 == transaction}) {
                        self!.transactions.remove(at: index)
                        self!.updateCollectionView()
                    }
                }
            }, transactionsChanged: { [weak self] transactionsChanged in
                for transaction in transactionsChanged {
                    if let index = self!.transactions.firstIndex(where: {$0 == transaction}) {
                        self!.transactions[index] = transaction
                        self!.updateCollectionView()
                    }
                }
            }
        )
    }
    
    func observeTransactionRulesForCurrentUser() {
        self.transactionRuleFetcher.observeTransactionRuleForCurrentUser(transactionRulesAdded: { [weak self] transactionRulesAdded in
            for transactionRule in transactionRulesAdded {
                if !self!.transactionRules.contains(transactionRule) {
                    self!.transactionRules.append(transactionRule)
//                    self!.updateCollectionView()
                }
            }
            }, transactionRulesRemoved: { [weak self] transactionRulesRemoved in
                for transactionRule in transactionRulesRemoved {
                    if let index = self!.transactionRules.firstIndex(where: {$0 == transactionRule}) {
                        self!.transactionRules.remove(at: index)
//                        self!.updateCollectionView()
                    }
                }
            }, transactionRulesChanged: { [weak self] transactionRulesChanged in
                for transactionRule in transactionRulesChanged {
                    if let index = self!.transactionRules.firstIndex(where: {$0 == transactionRule}) {
                        self!.transactionRules[index] = transactionRule
//                        self!.updateCollectionView()
                    }
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
            var _account = account
            do {
                if _account.balances != nil {
                    _account.balances![_account.updated_at] = _account.balance
                } else {
                    _account.balances = [_account.updated_at: _account.balance]
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
                // store transaction info
                let value = try FirebaseEncoder().encode(transaction)
                ref.child(financialTransactionsEntity).child(transaction.guid).setValue(value)
                // store transaction description (name) just to put something there
                ref.child(userFinancialTransactionsEntity).child(currentUserID).child(transaction.guid).child("description").setValue(transaction.description)
            } catch let error {
                print(error)
            }
        }
    }
    
    private func updateCollectionView() {
        guard currentReachabilityStatus != .notReachable else {
            return
        }
        activityIndicatorView.startAnimating()
        
        let dispatchGroup = DispatchGroup()
        
        for section in sections {
            if section.type == "Issues" {
                dispatchGroup.enter()
                if !members.isEmpty {
                    members.sort { (member1, member2) -> Bool in
                        return member1.name < member2.name
                    }
                    self.groups[section] = members
                    dispatchGroup.leave()
                } else {
                    self.sections.removeAll(where: {$0 == section})
                    dispatchGroup.leave()
                }
            } else if section.type == "Accounts" {
                if section.subType == "Balance Sheet" {
                    dispatchGroup.enter()
                    categorizeAccounts(accounts: accounts) { (accountsList, accountsDict) in
                        if !accountsList.isEmpty {
                            self.groups[section] = accountsList
                            self.accountDict = accountsDict
                        } else {
                            self.sections.removeAll(where: {$0 == section})
                        }
                        dispatchGroup.leave()
                    }
                } else if section.subType == "Accounts" {
                    dispatchGroup.enter()
                    if !accounts.isEmpty {
                        accounts.sort { (account1, account2) -> Bool in
                            return account1.name < account2.name
                        }
                        self.groups[section] = accounts
                        dispatchGroup.leave()
                    } else {
                        self.sections.removeAll(where: {$0 == section})
                        dispatchGroup.leave()
                    }
                }
            } else if section.type == "Transactions" {
                if section.subType == "Income Statement" {
                    dispatchGroup.enter()
                    categorizeTransactions(transactions: transactions, start: startDate, end: endDate, type: .none) { (transactionsList, transactionsDict) in
                        if !transactionsList.isEmpty {
                            self.groups[section] = transactionsList
                            self.transactionDict = transactionsDict
                        } else {
                            self.sections.removeAll(where: {$0 == section})
                        }
                        dispatchGroup.leave()
                    }
                } else if section.subType == "Transactions" {
                    dispatchGroup.enter()
                    if !transactions.isEmpty {
                        var filteredTransactions = transactions.filter { (transaction) -> Bool in
                            if let date = transaction.date_for_reports, date != "", let transactionDate = isodateFormatter.date(from: date) {
                                if transactionDate > startDate.stripTime() && endDate.stripTime() > transactionDate {
                                    return true
                                }
                            } else if let transactionDate = isodateFormatter.date(from: transaction.transacted_at) {
                                if transactionDate > startDate.stripTime() && endDate.stripTime() > transactionDate {
                                    return true
                                }
                            }
                            return false
                        }
                        filteredTransactions = filteredTransactions.sorted(by: { (transaction1, transaction2) -> Bool in
                            if let date1 = isodateFormatter.date(from: transaction1.transacted_at), let date2 = isodateFormatter.date(from: transaction2.transacted_at) {
                                return date1 > date2
                            }
                            return transaction1.description < transaction2.description
                        })
                        self.groups[section] = filteredTransactions
                        dispatchGroup.leave()
                    } else {
                        self.sections.removeAll(where: {$0 == section})
                        dispatchGroup.leave()
                    }
                }
            }
            
            dispatchGroup.notify(queue: .main) {
                activityIndicatorView.stopAnimating()
                self.collectionView.reloadData()
            }
        }
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        sections.count
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let sec = sections[section]
        return groups[sec]?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let section = sections[indexPath.section]
        let object = groups[section]
        if section != .issues {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: self.kFinanceCollectionViewCell, for: indexPath) as! FinanceCollectionViewCell
            if let object = object as? [TransactionDetails] {
                cell.transactionDetails = object[indexPath.item]
            } else if let object = object as? [AccountDetails] {
                cell.accountDetails = object[indexPath.item]
            } else if let object = object as? [Transaction] {
                cell.transaction = object[indexPath.item]
            } else if let object = object as? [MXAccount] {
                cell.account = object[indexPath.item]
            }
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: self.kFinanceCollectionViewMemberCell, for: indexPath) as! FinanceCollectionViewMemberCell
            if let object = object as? [MXMember] {
                if let imageURL = institutionDict[object[indexPath.item].institution_code] {
                    cell.imageURL = imageURL
                    cell.member = object[indexPath.item]
                }
            }
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        var height: CGFloat = 328
        let section = sections[indexPath.section]
        let object = groups[section]
        if section != .issues {
            let dummyCell = FinanceCollectionViewCell(frame: .init(x: 0, y: 0, width: view.frame.width - 32, height: 1000))
            if let object = object as? [TransactionDetails] {
                dummyCell.transactionDetails = object[indexPath.item]
            } else if let object = object as? [AccountDetails] {
                dummyCell.accountDetails = object[indexPath.item]
            } else if let object = object as? [Transaction] {
                dummyCell.transaction = object[indexPath.item]
            } else if let object = object as? [MXAccount] {
                dummyCell.account = object[indexPath.item]
            }
            dummyCell.layoutIfNeeded()
            let estimatedSize = dummyCell.systemLayoutSizeFitting(.init(width: view.frame.width - 32, height: 1000))
            height = estimatedSize.height
        } else {
            let dummyCell = FinanceCollectionViewMemberCell(frame: .init(x: 0, y: 0, width: view.frame.width - 32, height: 1000))
            if let object = object as? [MXMember] {
                if let imageURL = institutionDict[object[indexPath.item].institution_code] {
                    dummyCell.imageURL = imageURL
                    dummyCell.member = object[indexPath.item]
                }
            }
            dummyCell.layoutIfNeeded()
            let estimatedSize = dummyCell.systemLayoutSizeFitting(.init(width: view.frame.width - 32, height: 1000))
            height = estimatedSize.height
        }
        return CGSize(width: view.frame.width - 32, height: height)
        
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: view.frame.width, height: 30)
    }
    
    func collectionView(_ collectionView: UICollectionView,
        viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let section = sections[indexPath.section]
        let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: self.kHeaderCell, for: indexPath) as! HeaderCell
        header.delegate = self
        header.titleLabel.text = section.name
        header.subTitleLabel.isHidden = true
        return header
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 16, bottom: 20, right: 16)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    //    lazy var diffableDataSource: UICollectionViewDiffableDataSource<SectionType, AnyHashable> = .init(collectionView: self.collectionView) { (collectionView, indexPath, object) -> UICollectionViewCell? in
    //        if let object = object as? TransactionDetails {
    //            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: self.kFinanceCollectionViewCell, for: indexPath) as! FinanceCollectionViewCell
    //            if object.level != .group {
    //                cell.transactionDetails = object
    //            }
    //            return cell
    //        } else if let object = object as? AccountDetails {
    //            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: self.kFinanceCollectionViewCell, for: indexPath) as! FinanceCollectionViewCell
    //            if object.level != .bs_type {
    //                cell.accountDetails = object
    //            }
    //            return cell
    //        } else if let object = object as? Transaction {
    //            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: self.kFinanceCollectionViewCell, for: indexPath) as! FinanceCollectionViewCell
    //            cell.transaction = object
    //            return cell
    //        } else if let object = object as? MXAccount {
    //            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: self.kFinanceCollectionViewCell, for: indexPath) as! FinanceCollectionViewCell
    //            cell.account = object
    //            return cell
    //        }
    //        return nil
    //    }
    //
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let section = sections[indexPath.section]
        let object = groups[section]
        if let object = object as? [TransactionDetails] {
            if section.subType == "Income Statement", let transactions = transactionDict[object[indexPath.item]] {
                let destination = FinanceTableViewController()
                destination.delegate = self
                destination.transactions = transactions
                destination.user = user
                destination.users = users
                destination.filteredUsers = filteredUsers
                destination.hidesBottomBarWhenPushed = true
                self.navigationController?.pushViewController(destination, animated: true)
            }
        } else if let object = object as? [AccountDetails] {
            if section.subType == "Balance Sheet", let accounts = accountDict[object[indexPath.item]] {
                let destination = FinanceTableViewController()
                destination.delegate = self
                destination.accounts = accounts
                destination.user = user
                destination.users = users
                destination.filteredUsers = filteredUsers
                destination.hidesBottomBarWhenPushed = true
                self.navigationController?.pushViewController(destination, animated: true)
            }
        } else if let object = object as? [Transaction] {
            if section.subType == "Transactions" {
                let destination = FinanceTransactionViewController()
                destination.user = user
                destination.transaction = object[indexPath.item]
                destination.users = users
                destination.filteredUsers = filteredUsers
                destination.hidesBottomBarWhenPushed = true
                self.getParticipants(transaction: object[indexPath.item], account: nil) { (participants) in
                    destination.selectedFalconUsers = participants
                    let navigationViewController = UINavigationController(rootViewController: destination)
                    self.present(navigationViewController, animated: true, completion: nil)
                }
            }
        } else if let object = object as? [MXAccount] {
            if section.subType == "Accounts" {
                let destination = FinanceAccountViewController()
                destination.account = object[indexPath.item]
                destination.users = users
                destination.filteredUsers = filteredUsers
                destination.hidesBottomBarWhenPushed = true
                self.getParticipants(transaction: nil, account: object[indexPath.item]) { (participants) in
                    destination.selectedFalconUsers = participants
                    let navigationViewController = UINavigationController(rootViewController: destination)
                    self.present(navigationViewController, animated: true, completion: nil)
                }
            }
        } else if let object = object as? [MXMember] {
            if section.type == "Issues", let user = user {
                self.openMXConnect(guid: user.guid, current_member_guid: object[indexPath.item].guid)
            }
        }
        collectionView.deselectItem(at: indexPath, animated: true)
    }
    
    func getParticipants(transaction: Transaction?, account: MXAccount?, completion: @escaping ([User])->()) {
        if let transaction = transaction, let participantsIDs = transaction.participantsIDs, let currentUserID = Auth.auth().currentUser?.uid {
            let group = DispatchGroup()
            let ID = transaction.guid
            let olderParticipants = self.participants[ID]
            var participants: [User] = []
            for id in participantsIDs {
                if transaction.admin == currentUserID && id == currentUserID {
                    continue
                }
                
                if let first = olderParticipants?.filter({$0.id == id}).first {
                    participants.append(first)
                    continue
                }
                
                group.enter()
                let participantReference = Database.database().reference().child("users").child(id)
                participantReference.observeSingleEvent(of: .value, with: { (snapshot) in
                    if snapshot.exists(), var dictionary = snapshot.value as? [String: AnyObject] {
                        dictionary.updateValue(snapshot.key as AnyObject, forKey: "id")
                        let user = User(dictionary: dictionary)
                        participants.append(user)
                    }
                    
                    group.leave()
                })
            }
            
            group.notify(queue: .main) {
                self.participants[ID] = participants
                completion(participants)
            }
        } else if let account = account, let participantsIDs = account.participantsIDs, let currentUserID = Auth.auth().currentUser?.uid {
            let group = DispatchGroup()
            let ID = account.guid
            let olderParticipants = self.participants[ID]
            var participants: [User] = []
            
            for id in participantsIDs {
                if account.admin == currentUserID && id == currentUserID {
                    continue
                }
                
                if let first = olderParticipants?.filter({$0.id == id}).first {
                    participants.append(first)
                    continue
                }
                
                group.enter()
                let participantReference = Database.database().reference().child("users").child(id)
                participantReference.observeSingleEvent(of: .value, with: { (snapshot) in
                    if snapshot.exists(), var dictionary = snapshot.value as? [String: AnyObject] {
                        dictionary.updateValue(snapshot.key as AnyObject, forKey: "id")
                        let user = User(dictionary: dictionary)
                        participants.append(user)
                    }
                    
                    group.leave()
                })
            }
            
            group.notify(queue: .main) {
                self.participants[ID] = participants
                completion(participants)
            }
        } else {
            let participants: [User] = []
            completion(participants)
        }
    }
    
}

extension FinanceViewController: HeaderCellDelegate {
    func viewTapped(labelText: String) {
        
    }
}

extension FinanceViewController: UpdateFinancialsDelegate {
    func updateTransactions(transactions: [Transaction]) {
        
    }
    func updateAccounts(accounts: [MXAccount]) {
        
    }
}

extension FinanceViewController: EndedWebViewDelegate {
    func updateMXMembers() {
        sections.removeAll(where: { $0 == .issues })
        members.removeAll()
        getMXData()
    }
}

extension FinanceViewController: CustomSegmentedControlDelegate {
    func changeToIndex(index:Int) {
        if index == 0 {
            startDate = Date().startOfDay
            endDate = Date().endOfDay
        } else if index == 1 {
            startDate = Date().startOfWeek
            endDate = Date().endOfWeek
        } else if index == 2 {
            startDate = Date().startOfMonth
            endDate = Date().endOfMonth
        } else {
            startDate = Date().startOfYear
            endDate = Date().endOfYear
        }
        self.index = index
        updateCollectionView()
        
    }
}


