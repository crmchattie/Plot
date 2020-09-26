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
    
    var sections: [SectionType] = [.balanceSheet, .incomeStatement]
    var groups = [SectionType: [AnyHashable]]()
    
    let transactionFetcher = FinancialTransactionFetcher()
    let accountFetcher = FinancialAccountFetcher()
    
    private let kCompositionalHeader = "CompositionalHeader"
    private let kFinanceCollectionViewCell = "FinanceCollectionViewCell"
    
    let isodateFormatter = ISO8601DateFormatter()
    let dateFormatterPrint = DateFormatter()
    
    init() {
        let layout = UICollectionViewCompositionalLayout { (sectionNumber, _) -> NSCollectionLayoutSection? in
            let item = NSCollectionLayoutItem(layoutSize: .init(widthDimension: .fractionalWidth(1), heightDimension: .fractionalHeight(1)))
            item.contentInsets = .init(top: 0, leading: 0, bottom: 0, trailing: 0)
            
            let group = NSCollectionLayoutGroup.vertical(layoutSize: .init(widthDimension: .fractionalWidth(1), heightDimension: .absolute(30)), subitems: [item])
            
            let section = NSCollectionLayoutSection(group: group)
            section.contentInsets.leading = 16
            section.contentInsets.trailing = 16
            
            let kind = UICollectionView.elementKindSectionHeader
            section.boundarySupplementaryItems = [
                .init(layoutSize: .init(widthDimension: .fractionalWidth(1), heightDimension: .absolute(50)), elementKind: kind, alignment: .topLeading)
            ]
            return section
        }
        
        super.init(collectionViewLayout: layout)
    }
    
    static func topSection() -> NSCollectionLayoutSection {
        let item = NSCollectionLayoutItem(layoutSize: .init(widthDimension: .fractionalWidth(1), heightDimension: .fractionalHeight(1)))
        item.contentInsets = .init(top: 0, leading: 16, bottom: 16, trailing: 16)
        
        let group = NSCollectionLayoutGroup.vertical(layoutSize: .init(widthDimension: .fractionalWidth(1), heightDimension: .absolute(120)), subitems: [item])
        
        let section = NSCollectionLayoutSection(group: group)
        
        let kind = UICollectionView.elementKindSectionHeader
        section.boundarySupplementaryItems = [
            .init(layoutSize: .init(widthDimension: .fractionalWidth(1), heightDimension: .absolute(50)), elementKind: kind, alignment: .topLeading)
        ]
        
        return section
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
        
        collectionView.register(CompositionalHeader.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: kCompositionalHeader)
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
        accountFetcher.fetchAccounts { (firebaseAccounts) in
            self.accounts = firebaseAccounts
            self.observeAccountsForCurrentUser()
            
            self.transactionFetcher.fetchTransactions { (firebaseTransactions) in
                self.transactions = firebaseTransactions
                self.updateCollectionView()
                self.observeTransactionsForCurrentUser()
                self.getMXData()
            }
        }
    }
    
    func getMXData() {
        let dispatchGroup = DispatchGroup()
        var newTransactions = [Transaction]()
        var updatedAccounts = [MXAccount]()
        self.getMXUser { user in
            if let user = user {
                self.getMXMembers(guid: user.guid) { (members) in
                    for member in members {
                        dispatchGroup.enter()
                        if member.connection_status == "CONNECTED" && member.is_being_aggregated == false {
                            self.getMXAccounts(guid: user.guid, member_guid: member.guid) { (accounts) in
                                updatedAccounts.append(contentsOf: accounts)
                                dispatchGroup.leave()
                                for account in accounts {
                                    if account.should_link ?? true {
                                        dispatchGroup.enter()
                                        if let finalAccount = self.accounts.first(where: { $0.guid == account.guid}), let date = self.isodateFormatter.date(from: finalAccount.updated_at) {
                                            self.getTransactionsAcct(guid: user.guid, account: finalAccount, from_date: date, to_date: Date()) { (transactions) in
                                                dispatchGroup.leave()
                                                for transaction in transactions {
                                                    dispatchGroup.enter()
                                                    if !self.transactions.contains(transaction) {
                                                        self.transactions.append(transaction)
                                                        newTransactions.append(transaction)
                                                        dispatchGroup.leave()
                                                    } else {
                                                        dispatchGroup.leave()
                                                    }
                                                }
                                            }
                                        } else {
                                            self.getTransactionsAcct(guid: user.guid, account: account, from_date: nil, to_date: nil) { (transactions) in
                                                dispatchGroup.leave()
                                                for transaction in transactions {
                                                    dispatchGroup.enter()
                                                    if !self.transactions.contains(transaction) {
                                                        self.transactions.append(transaction)
                                                        newTransactions.append(transaction)
                                                        dispatchGroup.leave()
                                                    } else {
                                                        dispatchGroup.leave()
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        } else {
                            dispatchGroup.leave()
                        }
                    }
                    dispatchGroup.notify(queue: .main) {
                        self.accounts = updatedAccounts
                        self.updateCollectionView()
                        self.updateFirebase(accounts: updatedAccounts, transactions: newTransactions)
                    }
                }
            }
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
    
    func observeAccountsForCurrentUser() {
        self.accountFetcher.observeAccountForCurrentUser(accountsAdded: { [weak self] accountsAdded in
                for account in accountsAdded {
                    if !self!.accounts.contains(account) {
                        self!.accounts.append(account)
                        self!.groups[.balanceSheet] = nil
                        self!.updateCollectionView()
                    }
                }
            }, accountsRemoved: { [weak self] accountsRemoved in
                for account in accountsRemoved {
                    if let index = self!.accounts.firstIndex(where: {$0 == account}) {
                        self!.accounts.remove(at: index)
                        self!.groups[.balanceSheet] = nil
                        self!.updateCollectionView()
                    }
                }
            }, accountsChanged: { [weak self] accountsChanged in
                for account in accountsChanged {
                    if let index = self!.accounts.firstIndex(where: {$0 == account}) {
                        self!.accounts[index] = account
                        self!.groups[.balanceSheet] = nil
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
                        self!.groups[.incomeStatement] = nil
                        self!.updateCollectionView()
                    }
                }
            }, transactionsRemoved: { [weak self] transactionsRemoved in
                for transaction in transactionsRemoved {
                    if let index = self!.transactions.firstIndex(where: {$0 == transaction}) {
                        self!.transactions.remove(at: index)
                        self!.groups[.incomeStatement] = nil
                        self!.updateCollectionView()
                    }
                }
            }, transactionsChanged: { [weak self] transactionsChanged in
                for transaction in transactionsChanged {
                    if let index = self!.transactions.firstIndex(where: {$0 == transaction}) {
                        self!.transactions[index] = transaction
                        self!.groups[.incomeStatement] = nil
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
        print("updateCollectionView")
        guard currentReachabilityStatus != .notReachable else {
            return
        }
        
        let dispatchGroup = DispatchGroup()
        
        var snapshot = self.diffableDataSource.snapshot()
        snapshot.deleteAllItems()
        self.diffableDataSource.apply(snapshot)
        
        diffableDataSource.supplementaryViewProvider = .some({ (collectionView, kind, indexPath) -> UICollectionReusableView? in
            let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: self.kCompositionalHeader, for: indexPath) as! CompositionalHeader
            header.delegate = self
            let snapshot = self.diffableDataSource.snapshot()
            if let object = self.diffableDataSource.itemIdentifier(for: indexPath), let section = snapshot.sectionIdentifier(containingItem: object) {
                header.titleLabel.text = section.name
                header.subTitleLabel.isHidden = true
            }

            return header
        })
                                
        for section in sections {
            if let object = groups[section] {
                snapshot.appendSections([section])
                snapshot.appendItems(object, toSection: section)
                self.diffableDataSource.apply(snapshot)
                continue
            } else if section.type == "Accounts" {
                if section.subType == "Balance Sheet" {
                    dispatchGroup.enter()
                    categorizeAccounts(accounts: self.accounts) { (accountsList, accountsDict) in
                        self.groups[section] = accountsList
                        self.accountDict = accountsDict
                        dispatchGroup.leave()
                    }
                }
            } else if section.type == "Transactions" {
                if section.subType == "Income Statement" {
                    dispatchGroup.enter()
                    categorizeTransactions(transactions: self.transactions, start: Date().startOfMonth, end: Date().endOfMonth, type: .none) { (transactionsList, transactionsDict) in
                        self.groups[section] = transactionsList
                        self.transactionDict = transactionsDict
                        dispatchGroup.leave()
                    }
                }
            }
            
            dispatchGroup.notify(queue: .main) {
                if let object = self.groups[section] {
                    snapshot.appendSections([section])
                    snapshot.appendItems(object, toSection: section)
                    self.diffableDataSource.apply(snapshot)
                }
            }
        }
    }
    
    lazy var diffableDataSource: UICollectionViewDiffableDataSource<SectionType, AnyHashable> = .init(collectionView: self.collectionView) { (collectionView, indexPath, object) -> UICollectionViewCell? in
        if let object = object as? TransactionDetails {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: self.kFinanceCollectionViewCell, for: indexPath) as! FinanceCollectionViewCell
            cell.transactionDetails = object
            return cell
        } else if let object = object as? AccountDetails {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: self.kFinanceCollectionViewCell, for: indexPath) as! FinanceCollectionViewCell
            cell.accountDetails = object
            return cell
        }
        return nil
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let object = diffableDataSource.itemIdentifier(for: indexPath)
        let snapshot = self.diffableDataSource.snapshot()
        let section = snapshot.sectionIdentifier(containingItem: object!)
        if let object = object as? TransactionDetails {
            if section?.subType == "Income Statement", let transactions = transactionDict[object] {
                let destination = FinanceTableViewController()
                destination.delegate = self
                destination.transactions = transactions
                destination.hidesBottomBarWhenPushed = true
                self.navigationController?.pushViewController(destination, animated: true)
            }
        } else if let object = object as? AccountDetails {
            if section?.subType == "Balance Sheet", let accounts = accountDict[object] {
                let destination = FinanceTableViewController()
                destination.delegate = self
                destination.accounts = accounts
                destination.hidesBottomBarWhenPushed = true
                self.navigationController?.pushViewController(destination, animated: true)
            }
        }
    }
    
}

extension FinanceViewController: CompositionalHeaderDelegate {
    func viewTapped(labelText: String) {
        
    }
}

extension FinanceViewController: UpdateFinancialsDelegate {
    func updateTransactions(transactions: [Transaction]) {
//        groups[.incomeStatement] = nil
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
//        groups[.balanceSheet] = nil
//        for account in accounts {
//            if let index = self.accounts.firstIndex(of: account) {
//                self.accounts[index] = account
//            }
//        }
//        updateCollectionView()
    }
}
