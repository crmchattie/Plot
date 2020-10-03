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
    
}

class FinanceViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout {
    weak var delegate: HomeBaseFinance?
    
    var transactions = [Transaction]()
    var accounts = [MXAccount]()
    
    var transactionsAcctDict = [MXAccount: [Transaction]]()
    
    var transactionDict = [TransactionDetails: [Transaction]]()
    var accountDict = [AccountDetails: [MXAccount]]()
    
    var sections: [SectionType] = [.balanceSheet, .financialAccounts, .incomeStatement, .transactions]
    var groups = [SectionType: [AnyHashable]]()
    
    let transactionFetcher = FinancialTransactionFetcher()
    let accountFetcher = FinancialAccountFetcher()
    
    private let kHeaderCell = "HeaderCell"
    private let kFinanceCollectionViewCell = "FinanceCollectionViewCell"
    
    let isodateFormatter = ISO8601DateFormatter()
    let dateFormatterPrint = DateFormatter()
    
    let startDate = Date().startOfMonth
    let endDate = Date().endOfMonth
    
    //    init() {
    //        let layout = UICollectionViewCompositionalLayout { (sectionNumber, _) -> NSCollectionLayoutSection? in
    //            if sectionNumber % 2 != 0 {
    //                return FinanceViewController.transactionsSection()
    //            }
    //            let item = NSCollectionLayoutItem(layoutSize: .init(widthDimension: .fractionalWidth(1), heightDimension: .fractionalHeight(1)))
    //            item.contentInsets = .init(top: 0, leading: 0, bottom: 0, trailing: 0)
    //
    //            let group = NSCollectionLayoutGroup.vertical(layoutSize: .init(widthDimension: .fractionalWidth(1), heightDimension: .absolute(30)), subitems: [item])
    //            group.contentInsets = .init(top: 10, leading: 0, bottom: 0, trailing: 0)
    //
    //            let section = NSCollectionLayoutSection(group: group)
    //            section.contentInsets.leading = 16
    //            section.contentInsets.trailing = 16
    //
    //            let kind = UICollectionView.elementKindSectionHeader
    //            section.boundarySupplementaryItems = [
    //                .init(layoutSize: .init(widthDimension: .fractionalWidth(1), heightDimension: .absolute(50)), elementKind: kind, alignment: .topLeading)
    //            ]
    //            return section
    //        }
    //
    //        super.init(collectionViewLayout: layout)
    //    }
    //
    //    static func transactionsSection() -> NSCollectionLayoutSection {
    //        let item = NSCollectionLayoutItem(layoutSize: .init(widthDimension: .fractionalWidth(1), heightDimension: .fractionalHeight(1)))
    //        item.contentInsets = .init(top: 0, leading: 0, bottom: 20, trailing: 0)
    //
    //        let group = NSCollectionLayoutGroup.vertical(layoutSize: .init(widthDimension: .fractionalWidth(1), heightDimension: .absolute(85)), subitems: [item])
    //
    //        let section = NSCollectionLayoutSection(group: group)
    //        section.contentInsets.leading = 16
    //        section.contentInsets.trailing = 16
    //
    //        let kind = UICollectionView.elementKindSectionHeader
    //        section.boundarySupplementaryItems = [
    //            .init(layoutSize: .init(widthDimension: .fractionalWidth(1), heightDimension: .absolute(50)), elementKind: kind, alignment: .topLeading)
    //        ]
    //
    //        return section
    //    }
    //
//    required init?(coder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
    
    init() {
        super.init(collectionViewLayout: UICollectionViewFlowLayout())
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(activityIndicatorView)
        activityIndicatorView.centerInSuperview()
        
        navigationItem.largeTitleDisplayMode = .never
        navigationController?.navigationBar.prefersLargeTitles = false
        
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for:.default)
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.navigationBar.layoutIfNeeded()
        
        extendedLayoutIncludesOpaqueBars = true
        definesPresentationContext = true
        edgesForExtendedLayout = UIRectEdge.top
        view.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
        
        collectionView.indicatorStyle = ThemeManager.currentTheme().scrollBarStyle
        collectionView.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
        
        collectionView.register(HeaderCell.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: kHeaderCell)
        collectionView.register(FinanceCollectionViewCell.self, forCellWithReuseIdentifier: kFinanceCollectionViewCell)
        
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
    
    func getFinancialData() {
        let dispatchGroup = DispatchGroup()
        dispatchGroup.enter()
        accountFetcher.fetchAccounts { (firebaseAccounts) in
            self.accounts = firebaseAccounts
            self.observeAccountsForCurrentUser()
            dispatchGroup.leave()
        }
        
        dispatchGroup.enter()
        self.transactionFetcher.fetchTransactions { (firebaseTransactions) in
            self.transactions = firebaseTransactions
            self.observeTransactionsForCurrentUser()
            dispatchGroup.leave()
        }
        
        dispatchGroup.notify(queue: .main) {
            self.getMXData()
            self.updateCollectionView()
        }
    }
    
//    func getMXData() {
//        let dispatchGroup = DispatchGroup()
//        var newTransactions = [Transaction]()
//        var updatedAccounts = [MXAccount]()
//        self.getMXUser { user in
//            if let user = user {
//                self.getMXMembers(guid: user.guid) { (members) in
//                    for member in members {
//                        if member.connection_status == "CONNECTED" && member.is_being_aggregated == false {
//                            dispatchGroup.enter()
//                            self.getMXAccounts(guid: user.guid, member_guid: member.guid) { (accounts) in
//                                updatedAccounts.append(contentsOf: accounts)
//                                dispatchGroup.leave()
//                                for account in accounts {
//                                    if account.should_link ?? true {
//                                        dispatchGroup.enter()
//                                        if let finalAccount = self.accounts.first(where: { $0.guid == account.guid}), let date = self.isodateFormatter.date(from: finalAccount.updated_at) {
//                                            self.getTransactionsAcct(guid: user.guid, account: finalAccount, from_date: date.addingTimeInterval(-604800), to_date: Date().addingTimeInterval(86400)) { (transactions) in
//                                                dispatchGroup.leave()
//                                                for transaction in transactions {
//                                                    dispatchGroup.enter()
//                                                    if !self.transactions.contains(transaction) {
//                                                        self.transactions.append(transaction)
//                                                        if transaction.status != .pending {
//                                                            newTransactions.append(transaction)
//                                                        }
//                                                        dispatchGroup.leave()
//                                                    } else {
//                                                        dispatchGroup.leave()
//                                                    }
//                                                }
//                                            }
//                                        } else {
//                                            self.getTransactionsAcct(guid: user.guid, account: account, from_date: nil, to_date: nil) { (transactions) in
//                                                dispatchGroup.leave()
//                                                for transaction in transactions {
//                                                    dispatchGroup.enter()
//                                                    if !self.transactions.contains(transaction) {
//                                                        self.transactions.append(transaction)
//                                                        if transaction.status != .pending {
//                                                            newTransactions.append(transaction)
//                                                        }
//                                                        dispatchGroup.leave()
//                                                    } else {
//                                                        dispatchGroup.leave()
//                                                    }
//                                                }
//                                            }
//                                        }
//                                    }
//                                }
//                            }
//                        }
//                    }
//                    dispatchGroup.notify(queue: .main) {
//                        self.accounts = updatedAccounts
//                        self.updateCollectionView()
//                        self.updateFirebase(accounts: updatedAccounts, transactions: newTransactions)
//                    }
//                }
//            }
//        }
//    }
    
    func getMXData() {
        print("getMXData")
        let dispatchGroup = DispatchGroup()
        var newTransactions = [Transaction]()
        var updatedAccounts = [MXAccount]()
        dispatchGroup.enter()
        self.getMXUser { user in
            dispatchGroup.enter()
            dispatchGroup.leave()
            if let user = user {
                dispatchGroup.enter()
                self.getMXMembers(guid: user.guid) { (members) in
                    for member in members {
                        dispatchGroup.enter()
                        if member.connection_status == "CONNECTED" && member.is_being_aggregated == false {
                            dispatchGroup.enter()
                            self.getMXAccounts(guid: user.guid, member_guid: member.guid) { (accounts) in
                                updatedAccounts.append(contentsOf: accounts)
                                for account in accounts {
                                    dispatchGroup.enter()
                                    if !self.accounts.contains(account) {
                                        dispatchGroup.enter()
                                        self.getTransactionsAcct(guid: user.guid, account: account, from_date: nil, to_date: nil) {
                                            (transactions) in
                                            for transaction in transactions {
                                                dispatchGroup.enter()
                                                if !self.transactions.contains(transaction) {
                                                    self.transactions.append(transaction)
                                                    if transaction.status != .pending {
                                                        newTransactions.append(transaction)
                                                    }
                                                    dispatchGroup.leave()
                                                } else {
                                                    dispatchGroup.leave()
                                                }
                                            }
                                            dispatchGroup.leave()
                                        }
                                    }
                                    dispatchGroup.leave()
                                }
                                dispatchGroup.leave()
                            }
                        }
                        dispatchGroup.leave()
                    }
                    dispatchGroup.leave()
                }
                
                dispatchGroup.enter()
                let date = self.isodateFormatter.date(from: self.accounts[0].updated_at) ?? Date()
                self.getTransactions(guid: user.guid, from_date: date.addingTimeInterval(-604800), to_date: Date().addingTimeInterval(86400)) { (transactions) in
                    for transaction in transactions {
                        dispatchGroup.enter()
                        let finalAccount = self.accounts.first(where: { $0.guid == transaction.account_guid})
                        if !self.transactions.contains(transaction), finalAccount?.should_link ?? true {
                            self.transactions.append(transaction)
                            if transaction.status != .pending {
                                newTransactions.append(transaction)
                            }
                            dispatchGroup.leave()
                        } else {
                            dispatchGroup.leave()
                        }
                    }
                }
                dispatchGroup.leave()
//                for account in self.accounts {
//                    if account.should_link ?? true {
//                        dispatchGroup.enter()
//                        if let finalAccount = self.accounts.first(where: { $0.guid == account.guid}), let date = self.isodateFormatter.date(from: finalAccount.updated_at) {
//                            self.getTransactionsAcct(guid: user.guid, account: finalAccount, from_date: date.addingTimeInterval(-604800), to_date: Date().addingTimeInterval(86400)) { (transactions) in
//                                dispatchGroup.leave()
//                                for transaction in transactions {
//                                    dispatchGroup.enter()
//                                    if !self.transactions.contains(transaction) {
//                                        self.transactions.append(transaction)
//                                        if transaction.status != .pending {
//                                            newTransactions.append(transaction)
//                                        }
//                                        dispatchGroup.leave()
//                                    } else {
//                                        dispatchGroup.leave()
//                                    }
//                                }
//                            }
//                        }
//                    }
//                }
            }
            dispatchGroup.leave()
        }
        
        dispatchGroup.notify(queue: .main) {
            self.accounts = updatedAccounts
            self.updateCollectionView()
            self.updateFirebase(accounts: updatedAccounts, transactions: newTransactions)
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
    
    private func updateFirebase(accounts: [MXAccount], transactions: [Transaction]) {
        guard let currentUserID = Auth.auth().currentUser?.uid else {
            return
        }
        let ref = Database.database().reference()
        for account in accounts {
            do {
                // store account info
                let value = try FirebaseEncoder().encode(account)
                ref.child(financialAccountsEntity).child(account.guid).setValue(value)
                // store account balance at given date
                ref.child(userFinancialAccountsEntity).child(currentUserID).child(account.guid).child("balances").child(account.updated_at).setValue(account.balance)
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
        
        let dispatchGroup = DispatchGroup()
        
        //        var snapshot = self.diffableDataSource.snapshot()
        //        snapshot.deleteAllItems()
        //        self.diffableDataSource.apply(snapshot)
        //
        //        diffableDataSource.supplementaryViewProvider = .some({ (collectionView, kind, indexPath) -> UICollectionReusableView? in
        //            let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: self.kHeaderCell, for: indexPath) as! HeaderCell
        //            header.delegate = self
        //            let snapshot = self.diffableDataSource.snapshot()
        //            if let object = self.diffableDataSource.itemIdentifier(for: indexPath), let section = snapshot.sectionIdentifier(containingItem: object) {
        //                header.titleLabel.text = section.name
        //                header.subTitleLabel.isHidden = true
        //            }
        //
        //            return header
        //        })
        
        for section in sections {
            if section.type == "Accounts" {
                if section.subType == "Balance Sheet" {
                    dispatchGroup.enter()
                    categorizeAccounts(accounts: accounts) { (accountsList, accountsDict) in
                        self.groups[section] = accountsList
                        self.accountDict = accountsDict
                        dispatchGroup.leave()
                    }
                } else if section.subType == "Accounts" {
                    accounts.sort { (account1, account2) -> Bool in
                        return account1.name < account2.name
                    }
                    self.groups[section] = accounts
                }
            } else if section.type == "Transactions" {
                if section.subType == "Income Statement" {
                    dispatchGroup.enter()
                    categorizeTransactions(transactions: transactions, start: startDate, end: endDate, type: .none) { (transactionsList, transactionsDict) in
                        self.groups[section] = transactionsList
                        self.transactionDict = transactionsDict
                        dispatchGroup.leave()
                    }
                } else if section.subType == "Transactions" {
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
                }
            }
            
            dispatchGroup.notify(queue: .main) {
                self.collectionView.reloadData()
//                if let object = self.groups[section] {
//                    snapshot.appendSections([section])
//                    snapshot.appendItems(object, toSection: section)
//                    self.diffableDataSource.apply(snapshot)
//                }
            }
        }
    }
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        sections.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let sec = sections[section]
        return groups[sec]?.count ?? 0
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let section = sections[indexPath.section]
        let object = groups[section]
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
        
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        var height: CGFloat = 328
        let section = sections[indexPath.section]
        let object = groups[section]
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
        return CGSize(width: view.frame.width - 32, height: height)
        
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: view.frame.width, height: 30)
    }
    
    override func collectionView(_ collectionView: UICollectionView,
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
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let section = sections[indexPath.section]
        let object = groups[section]
        if let object = object as? [TransactionDetails] {
            if section.subType == "Income Statement", let transactions = transactionDict[object[indexPath.item]] {
                let destination = FinanceTableViewController()
                destination.delegate = self
                destination.transactions = transactions
                destination.hidesBottomBarWhenPushed = true
                self.navigationController?.pushViewController(destination, animated: true)
            }
        } else if let object = object as? [AccountDetails] {
            if section.subType == "Balance Sheet", let accounts = accountDict[object[indexPath.item]] {
                let destination = FinanceTableViewController()
                destination.delegate = self
                destination.accounts = accounts
                destination.hidesBottomBarWhenPushed = true
                self.navigationController?.pushViewController(destination, animated: true)
            }
        } else if let object = object as? [Transaction] {
            if section.subType == "Transactions" {
                let destination = FinanceTransactionViewController()
                destination.transaction = object[indexPath.item]
                destination.hidesBottomBarWhenPushed = true
                let navigationViewController = UINavigationController(rootViewController: destination)
                self.present(navigationViewController, animated: true, completion: nil)
                //                navigationController?.pushViewController(destination, animated: true)
            }
        } else if let object = object as? [MXAccount] {
            if section.subType == "Accounts" {
                let destination = FinanceAccountViewController()
                destination.account = object[indexPath.item]
                destination.hidesBottomBarWhenPushed = true
                let navigationViewController = UINavigationController(rootViewController: destination)
                self.present(navigationViewController, animated: true, completion: nil)
                //                    navigationController?.pushViewController(destination, animated: true)
            }
        }
        collectionView.deselectItem(at: indexPath, animated: true)
    }
    
}

extension FinanceViewController: HeaderCellDelegate {
    func viewTapped(labelText: String) {
        
    }
}

extension FinanceViewController: UpdateFinancialsDelegate {
    func updateTransactions(transactions: [Transaction]) {
        //        for transaction in transactions {
        //            print("transactionDes delegate \(transaction.description)")
        //            if let index = self.transactions.firstIndex(of: transaction) {
        //                print("transactionDes delegate \(transaction.description)")
        //                self.transactions[index] = transaction
        //            }
        //        }
        //        updateCollectionView()
    }
    func updateAccounts(accounts: [MXAccount]) {
        //        for account in accounts {
        //            if let index = self.accounts.firstIndex(of: account) {
        //                self.accounts[index] = account
        //            }
        //        }
        //        updateCollectionView()
    }
}
