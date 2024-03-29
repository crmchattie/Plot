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

let kFinanceLevel = "FinanceLevel"

enum FinanceLevel: String {
    case all
    case top
}

class FinanceViewController: UIViewController, ObjectDetailShowing {
    var networkController: NetworkController
    
    init(networkController: NetworkController) {
        self.networkController = networkController
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    let collectionView: UICollectionView = {
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        layout.scrollDirection = .vertical
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.contentInset.bottom = 0
        return collectionView
    }()
    
    let customSegmented = CustomSegmentedControl(buttonImages: nil, buttonTitles: ["D","W","M", "Y"], selectedIndex: 2, selectedStrings: ["Day", "Week", "Month", "Year"])
    
    var user: MXUser {
        return networkController.financeService.mxUser
    }
    var transactions: [Transaction] {
        return networkController.financeService.transactions
    }
    var accounts: [MXAccount] {
        return networkController.financeService.accounts
    }
    var members: [MXMember] {
        return networkController.financeService.members
    }
    var holdings: [MXHolding] {
        return networkController.financeService.holdings
    }
    var institutionDict: [String: String] {
        return networkController.financeService.institutionDict
    }
    var users: [User] {
        return networkController.userService.users
    }
    var filteredUsers: [User] {
        return networkController.userService.users
    }
    
    var selectedIndex = 2
    
    var transactionsDictionary = [TransactionDetails: [Transaction]]()
    var accountsDictionary = [AccountDetails: [MXAccount]]()
    
    var setSections: [SectionType] = [.financialIssues, .incomeStatement, .balanceSheet, .transactions, .investments, .financialAccounts]
    var sections = [SectionType]()
    var groups = [SectionType: [AnyHashable]]()
    
    let isodateFormatter = ISO8601DateFormatter()
    let dateFormatterPrint = DateFormatter()
    
    var startDate = Date().localTime.startOfMonth
    var endDate = Date().localTime.dayAfter
    
    var hasViewAppeared = false
    
    var participants: [String: [User]] = [:]
    
    var financeLevel: FinanceLevel = .all
    
    var filters: [filter] = [.search, .financeAccount]
    var filterDictionary = [String: [String]]()
    
    let viewPlaceholder = ViewPlaceholder()
    
    let refreshControl = UIRefreshControl()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.largeTitleDisplayMode = .never
        if title == nil {
            title = "Finances"
        }
        
        customSegmented.delegate = self
        collectionView.dataSource = self
        collectionView.delegate = self
        
        collectionView.register(HeaderCell.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: kHeaderCell)
        collectionView.register(FinanceCollectionViewCell.self, forCellWithReuseIdentifier: kFinanceCollectionViewCell)
        collectionView.register(FinanceCollectionViewComparisonCell.self, forCellWithReuseIdentifier: kFinanceCollectionViewComparisonCell)
        collectionView.register(FinanceCollectionViewMemberCell.self, forCellWithReuseIdentifier: kFinanceCollectionViewMemberCell)
        
        setupMainView()
        addObservers()
        updateCollectionView()
        
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    fileprivate func addObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(financeUpdated), name: .financeGroupsUpdated, object: nil)
        
    }
    
    @objc fileprivate func financeUpdated() {
        DispatchQueue.main.async {
            self.updateCollectionView()
        }
    }
    
    fileprivate func setupMainView() {
        extendedLayoutIncludesOpaqueBars = true
        
        view.backgroundColor = .systemGroupedBackground
        collectionView.indicatorStyle = .default
        collectionView.backgroundColor = .systemGroupedBackground
        
        customSegmented.backgroundColor = .systemGroupedBackground
        customSegmented.constrainHeight(30)
        
        view.addSubview(customSegmented)
        view.addSubview(collectionView)
        
        customSegmented.anchor(top: view.safeAreaLayoutGuide.topAnchor, leading: view.leadingAnchor, bottom: nil, trailing: view.trailingAnchor, padding: .init(top: 0, left: 0, bottom: 0, right: 0))
        collectionView.anchor(top: customSegmented.bottomAnchor, leading: view.leadingAnchor, bottom: view.bottomAnchor, trailing: view.trailingAnchor, padding: .init(top: 10, left: 0, bottom: 0, right: 0))
        
        view.addSubview(activityIndicatorView)
        activityIndicatorView.centerInSuperview()
        
        let newItemBarButton =  UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(newItem))
        let filterBarButton = UIBarButtonItem(image: UIImage(named: "filter"), style: .plain, target: self, action: #selector(filter))
        navigationItem.rightBarButtonItems = [newItemBarButton, filterBarButton]
        
        refreshControl.addTarget(self, action: #selector(refreshControlAction(_:)), for: UIControl.Event.valueChanged)
        collectionView.refreshControl = refreshControl
        
        financeLevel = getFinanceLevel()
        
    }
    
    @objc fileprivate func newItem() {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "Transaction", style: .default, handler: { (_) in
            self.showTransactionDetailPresent(transaction: nil, updateDiscoverDelegate: nil, delegate: nil, users: nil, container: nil, movingBackwards: nil)
        }))
        
//        alert.addAction(UIAlertAction(title: "Investment", style: .default, handler: { (_) in
//            self.showHoldingDetailPresent(holding: nil, updateDiscoverDelegate: nil)
//        }))
        
        alert.addAction(UIAlertAction(title: "Account", style: .default, handler: { (_) in
            print("User click Edit button")
            self.newAccount()
        }))
        
        alert.addAction(UIAlertAction(title: "Transaction Rule", style: .default, handler: { (_) in
            print("User click Edit button")
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (_) in
            print("User click Dismiss button")
        }))
        
        self.present(alert, animated: true, completion: {
            print("completion block")
        })
    }
    
    @objc fileprivate func filter() {
        filterDictionary["financeLevel"] = [financeLevel.rawValue.capitalized]
        let destination = FilterViewController(networkController: networkController)
        let navigationViewController = UINavigationController(rootViewController: destination)
        destination.delegate = self
        destination.filters = filters
        destination.filterDictionary = filterDictionary
        self.present(navigationViewController, animated: true, completion: nil)
    }
    
    @objc func newAccount() {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "Connect To Account", style: .default, handler: { (_) in
            self.openMXConnect(current_member_guid: nil, delegate: self)
        }))
        
        alert.addAction(UIAlertAction(title: "Manually Add Account", style: .default, handler: { (_) in
            self.showAccountDetailPresent(account: nil, updateDiscoverDelegate: nil)
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (_) in
            print("User click Dismiss button")
        }))
        
        self.present(alert, animated: true, completion: {
            print("completion block")
        })
    }
    
    @objc func refreshControlAction(_ refreshControl: UIRefreshControl) {
        networkController.financeService.regrabFinances {
            DispatchQueue.main.async {
                self.updateCollectionView()
                self.refreshControl.endRefreshing()
            }
        }
    }
    
    func saveFinanceLevel() {
        UserDefaults.standard.setValue(financeLevel.rawValue, forKey: kFinanceLevel)
    }
    
    func getFinanceLevel() -> FinanceLevel {
        if let value = UserDefaults.standard.value(forKey: kFinanceLevel) as? String, let view = FinanceLevel(rawValue: value) {
            return view
        } else {
            return .all
        }
    }
    
    private func updateCollectionView() {
        var accountLevel: AccountCatLevel!
        var transactionLevel: TransactionCatLevel!
        
        activityIndicatorView.startAnimating()
        
        if let level = filterDictionary["financeLevel"], level[0] == "Top" {
            accountLevel = .bs_type
            transactionLevel = .group
            financeLevel = .top
        } else {
            accountLevel = .none
            transactionLevel = .none
            financeLevel = .all
        }
        
        self.saveFinanceLevel()
    
        self.sections = []
        self.groups = [SectionType: [AnyHashable]]()
        
        var filteredAccounts = accounts
        var filteredAccountsString = accounts.map({ $0.guid })
        if let accountsString = filterDictionary["financeAccount"]  {
            filteredAccounts = filteredAccounts.filter({ accountsString.contains($0.guid) })
            filteredAccountsString = accountsString
        }
        
        for section in setSections {
            if section.type == "Issues" && filterDictionary["search"] == nil {
                var challengedMembers = [MXMember]()
                for member in members {
                    if let _ = filterDictionary["financeAccount"] {
                        if member.connection_status != .connected && member.connection_status != .created && member.connection_status != .updated && member.connection_status != .delayed && member.connection_status != .resumed && member.connection_status != .pending && (filteredAccounts.first(where: {$0.member_guid == member.guid}) != nil) {
                            challengedMembers.append(member)
                        }
                    } else if member.connection_status != .connected && member.connection_status != .created && member.connection_status != .updated && member.connection_status != .delayed && member.connection_status != .resumed && member.connection_status != .pending {
                        challengedMembers.append(member)
                    }
                }
                if !challengedMembers.isEmpty {
                    self.sections.append(section)
                    self.groups[section] = challengedMembers
                }
            } else if section.type == "Accounts" {
                if section.subType == "Balance Sheet" && filterDictionary["search"] == nil {
                    categorizeAccounts(accounts: filteredAccounts, timeSegment: TimeSegmentType(rawValue: selectedIndex) ?? .month, level: accountLevel, accountDetails: nil, date: nil) { (accountsList, accountsDict) in
                        if !accountsList.isEmpty {
                            if accountsList.first?.lastPeriodBalance != nil {
                                self.sections.append(.balancesFinances)
                                self.groups[.balancesFinances] = accountsList.filter {$0.level == .bs_type}
                            }
                            self.sections.append(section)
                            self.groups[section] = accountsList
                            self.accountsDictionary = accountsDict
                        }
                    }
                } else if section.subType == "Accounts" {
                    if let value = filterDictionary["search"] {
                        let searchText = value[0]
                        filteredAccounts = filteredAccounts.filter({ (account) -> Bool in
                            return account.name.lowercased().contains(searchText.lowercased())
                        })
                    }
                    if !filteredAccounts.isEmpty {
                        self.sections.append(section)
                        self.groups[section] = filteredAccounts
                    }
                }
            } else if section.type == "Transactions" {
                if section.subType == "Income Statement" && filterDictionary["search"] == nil {
                    categorizeTransactions(transactions: transactions, start: startDate, end: endDate, level: transactionLevel, transactionDetails: nil, accounts: filteredAccountsString) { (transactionsList, transactionsDict) in
                        if !transactionsList.isEmpty {
                            if self.selectedIndex == 0 {
                                categorizeTransactions(transactions: self.transactions, start: self.startDate.dayBefore, end: self.endDate.dayBefore, level: .group, transactionDetails: nil, accounts: filteredAccountsString) { (transactionsListPrior, _) in
                                    if !transactionsListPrior.isEmpty {
                                        addPriorTransactionDetails(currentDetailsList: transactionsList, currentDetailsDict: transactionsDict, priorDetailsList: transactionsListPrior) { (finalTransactionList, finalTransactionsDict) in
                                            self.sections.append(.cashFlow)
                                            self.groups[.cashFlow] = finalTransactionList.filter {$0.level == .group}
                                            
                                            self.sections.append(section)
                                            self.groups[section] = finalTransactionList
                                            self.transactionsDictionary = finalTransactionsDict
                                        }
                                    } else {
                                        self.sections.append(section)
                                        self.groups[section] = transactionsList
                                        self.transactionsDictionary = transactionsDict
                                    }
                                }
                            } else if self.selectedIndex == 1 {
                                categorizeTransactions(transactions: self.transactions, start: self.startDate.weekBefore, end: self.endDate.weekBefore, level: .group, transactionDetails: nil, accounts: filteredAccountsString) { (transactionsListPrior, _) in
                                    if !transactionsListPrior.isEmpty {
                                        addPriorTransactionDetails(currentDetailsList: transactionsList, currentDetailsDict: transactionsDict, priorDetailsList: transactionsListPrior) { (finalTransactionList, finalTransactionsDict) in
                                            self.sections.append(.cashFlow)
                                            self.groups[.cashFlow] = finalTransactionList.filter {$0.level == .group}
                                            
                                            self.sections.append(section)
                                            self.groups[section] = finalTransactionList
                                            self.transactionsDictionary = finalTransactionsDict
                                        }
                                    } else {
                                        self.sections.append(section)
                                        self.groups[section] = transactionsList
                                        self.transactionsDictionary = transactionsDict
                                    }
                                }
                            } else if self.selectedIndex == 2 {
                                categorizeTransactions(transactions: self.transactions, start: self.startDate.monthBefore, end: self.endDate.monthBefore, level: .group, transactionDetails: nil, accounts: filteredAccountsString) { (transactionsListPrior, _) in
                                    if !transactionsListPrior.isEmpty {
                                        addPriorTransactionDetails(currentDetailsList: transactionsList, currentDetailsDict: transactionsDict, priorDetailsList: transactionsListPrior) { (finalTransactionList, finalTransactionsDict) in
                                            self.sections.append(.cashFlow)
                                            self.groups[.cashFlow] = finalTransactionList.filter {$0.level == .group}
                                            
                                            self.sections.append(section)
                                            self.groups[section] = finalTransactionList
                                            self.transactionsDictionary = finalTransactionsDict
                                        }
                                    } else {
                                        self.sections.append(section)
                                        self.groups[section] = transactionsList
                                        self.transactionsDictionary = transactionsDict
                                    }
                                }
                            } else {
                                categorizeTransactions(transactions: self.transactions, start: self.startDate.lastYear, end: self.endDate.lastYear, level: .group, transactionDetails: nil, accounts: filteredAccountsString) { (transactionsListPrior, _) in
                                    if !transactionsListPrior.isEmpty {
                                        addPriorTransactionDetails(currentDetailsList: transactionsList, currentDetailsDict: transactionsDict, priorDetailsList: transactionsListPrior) { (finalTransactionList, finalTransactionsDict) in
                                            self.sections.append(.cashFlow)
                                            self.groups[.cashFlow] = finalTransactionList.filter {$0.level == .group}
                                            
                                            self.sections.append(section)
                                            self.groups[section] = finalTransactionList
                                            self.transactionsDictionary = finalTransactionsDict
                                        }
                                    } else {
                                        self.sections.append(section)
                                        self.groups[section] = transactionsList
                                        self.transactionsDictionary = transactionsDict
                                    }
                                }
                            }
                        }
                    }
                } else if section.subType == "Transactions" {
                    if !transactions.isEmpty {
                        var filteredTransactions = transactions
                        if let value = filterDictionary["search"] {
                            let searchText = value[0]
                            filteredTransactions = filteredTransactions.filter({ (transaction) -> Bool in
                                return transaction.description.lowercased().contains(searchText.lowercased())
                            })
                        }
                        if let _ = filterDictionary["financeAccount"] {
                            filteredTransactions = filteredTransactions.filter({ (transaction) -> Bool in
                                filteredAccountsString.contains(transaction.account_guid ?? "")
                            })
                        }
                        filteredTransactions = filteredTransactions.filter({ (transaction) -> Bool in
                            if let transactionDate = transaction.transactionDate {
                                if transactionDate.localTime > startDate && endDate > transactionDate.localTime {
                                    return true
                                }
                            }
                            return false
                        })
                        if !filteredTransactions.isEmpty {
                            self.sections.append(section)
                            self.groups[section] = filteredTransactions
                        }
                    }
                }
            } else if section.type == "Investments" {
                var filteredHoldings = holdings
                if let value = filterDictionary["search"] {
                    let searchText = value[0]
                    filteredHoldings = filteredHoldings.filter({ (holding) -> Bool in
                        return holding.description.lowercased().contains(searchText.lowercased())
                    })
                }
                if let _ = filterDictionary["financeAccount"] {
                    filteredHoldings = filteredHoldings.filter { (holding) -> Bool in
                        filteredAccountsString.contains(holding.account_guid ?? "")
                    }
                }
                if !filteredHoldings.isEmpty {
                    self.sections.append(section)
                    self.groups[section] = filteredHoldings
                }
            }
        }
        
        DispatchQueue.main.async {
            activityIndicatorView.stopAnimating()
            self.collectionView.reloadData()
        }
    }
}

extension FinanceViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        if sections.count == 0 {
            viewPlaceholder.add(for: collectionView, title: .emptySearch, subtitle: .emptySearch, priority: .medium, position: .fill)
        } else {
            viewPlaceholder.remove(from: collectionView, priority: .medium)
        }
        return sections.count
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let sec = sections[section]
        if sec == .transactions || sec == .financialAccounts || sec == .investments {
            if groups[sec]?.count ?? 0 < 10 {
                return groups[sec]?.count ?? 0
            }
            return 10
        }
        return groups[sec]?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let section = sections[indexPath.section]
        let object = groups[section]
        let totalItems = collectionView.numberOfItems(inSection: indexPath.section) - 1
        if section == .cashFlow, let object = object as? [TransactionDetails] {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: kFinanceCollectionViewComparisonCell, for: indexPath) as! FinanceCollectionViewComparisonCell
            cell.selectedIndex = TimeSegmentType(rawValue: selectedIndex) ?? .month
            cell.transactionDetails = object[indexPath.item]
            return cell
        } else if section == .balancesFinances, let object = object as? [AccountDetails] {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: kFinanceCollectionViewComparisonCell, for: indexPath) as! FinanceCollectionViewComparisonCell
            cell.selectedIndex = TimeSegmentType(rawValue: selectedIndex) ?? .month
            cell.accountDetails = object[indexPath.item]
            return cell
        } else if section == .financialIssues, let object = object as? [MXMember] {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: kFinanceCollectionViewMemberCell, for: indexPath) as! FinanceCollectionViewMemberCell
            cell.member = object[indexPath.item]
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: kFinanceCollectionViewCell, for: indexPath) as! FinanceCollectionViewCell
            if indexPath.item == 0 {
                cell.firstPosition = true
            }
            if indexPath.item == totalItems {
                cell.lastPosition = true
            }
            if let object = object as? [TransactionDetails] {
                if let level = filterDictionary["financeLevel"], level[0] == "Top" {
                    cell.mode = .small
                } else {
                    cell.mode = .fullscreen
                }
                cell.transactionDetails = object[indexPath.item]
            } else if let object = object as? [AccountDetails] {
                if let level = filterDictionary["financeLevel"], level[0] == "Top" {
                    cell.mode = .small
                } else {
                    cell.mode = .fullscreen
                }
                cell.accountDetails = object[indexPath.item]
            } else if let object = object as? [MXHolding] {
                cell.mode = .fullscreen
                cell.firstPosition = true
                cell.lastPosition = true
                cell.holding = object[indexPath.item]
            } else if let object = object as? [Transaction] {
                cell.firstPosition = true
                cell.lastPosition = true
                cell.transaction = object[indexPath.item]
            } else if let object = object as? [MXAccount] {
                cell.firstPosition = true
                cell.lastPosition = true
                cell.account = object[indexPath.item]
            }
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        var height: CGFloat = 328
        let section = sections[indexPath.section]
        let object = groups[section]
        if section == .cashFlow, let object = object as? [TransactionDetails] {
            let dummyCell = collectionView.dequeueReusableCell(withReuseIdentifier: kFinanceCollectionViewComparisonCell, for: indexPath) as! FinanceCollectionViewComparisonCell
            dummyCell.transactionDetails = object[indexPath.item]
            dummyCell.layoutIfNeeded()
            let estimatedSize = dummyCell.systemLayoutSizeFitting(.init(width: self.collectionView.frame.size.width - 30, height: 1000))
            height = estimatedSize.height
        } else if section == .balancesFinances, let object = object as? [AccountDetails] {
            let dummyCell = collectionView.dequeueReusableCell(withReuseIdentifier: kFinanceCollectionViewComparisonCell, for: indexPath) as! FinanceCollectionViewComparisonCell
            dummyCell.accountDetails = object[indexPath.item]
            dummyCell.layoutIfNeeded()
            let estimatedSize = dummyCell.systemLayoutSizeFitting(.init(width: self.collectionView.frame.size.width - 30, height: 1000))
            height = estimatedSize.height
        } else if section == .financialIssues, let object = object as? [MXMember] {
            let dummyCell = FinanceCollectionViewMemberCell(frame: .init(x: 0, y: 0, width: self.collectionView.frame.size.width, height: 1000))
            dummyCell.member = object[indexPath.item]
            dummyCell.layoutIfNeeded()
            let estimatedSize = dummyCell.systemLayoutSizeFitting(.init(width: self.collectionView.frame.size.width - 30, height: 1000))
            height = estimatedSize.height
        } else {
            let totalItems = collectionView.numberOfItems(inSection: indexPath.section) - 1
            let dummyCell = FinanceCollectionViewCell(frame: .init(x: 0, y: 0, width: self.collectionView.frame.size.width - 30, height: 1000))
            if indexPath.item == 0 {
                dummyCell.firstPosition = true
            }
            if indexPath.item == totalItems {
                dummyCell.lastPosition = true
            }
            if let object = object as? [TransactionDetails] {
                if let level = filterDictionary["financeLevel"], level[0] == "Top" {
                    dummyCell.mode = .small
                } else {
                    dummyCell.mode = .fullscreen
                }
                dummyCell.transactionDetails = object[indexPath.item]
            } else if let object = object as? [AccountDetails] {
                if let level = filterDictionary["financeLevel"], level[0] == "Top" {
                    dummyCell.mode = .small
                } else {
                    dummyCell.mode = .fullscreen
                }
                dummyCell.accountDetails = object[indexPath.item]
            } else if let object = object as? [MXHolding] {
                dummyCell.mode = .fullscreen
                dummyCell.firstPosition = true
                dummyCell.lastPosition = true
                dummyCell.holding = object[indexPath.item]
            } else if let object = object as? [Transaction] {
                dummyCell.firstPosition = true
                dummyCell.lastPosition = true
                dummyCell.transaction = object[indexPath.item]
            } else if let object = object as? [MXAccount] {
                dummyCell.firstPosition = true
                dummyCell.lastPosition = true
                dummyCell.account = object[indexPath.item]
            }
            dummyCell.layoutIfNeeded()
            let estimatedSize = dummyCell.systemLayoutSizeFitting(.init(width: self.collectionView.frame.size.width - 30, height: 1000))
            height = estimatedSize.height
        }
        return CGSize(width: self.collectionView.frame.size.width - 30, height: height)

    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: self.collectionView.frame.size.width, height: 40)
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let section = sections[indexPath.section]
        let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: kHeaderCell, for: indexPath) as! HeaderCell
        header.backgroundColor = .systemGroupedBackground
        header.delegate = self
        header.sectionType = section
        header.titleLabel.text = section.name
        if (section == .transactions || section == .financialAccounts || section == .investments) && groups[section]?.count ?? 0 > 10 {
            header.view.isUserInteractionEnabled = true
            header.subTitleLabel.isHidden = false
        } else {
            header.view.isUserInteractionEnabled = false
            header.subTitleLabel.isHidden = true
        }
        return header
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        let section = sections[section]
        if section == .transactions || section == .financialAccounts || section == .financialIssues || section == .investments || section == .cashFlow || section == .balancesFinances {
            return 10
        }
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 5, left: 0, bottom: 5, right: 0)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let section = sections[indexPath.section]
        let object = groups[section]
        if let object = object as? [TransactionDetails], let specificTransactions = transactionsDictionary[object[indexPath.item]] {
            showTransactionDetailDetailPush(transactionDetails: object[indexPath.item], allTransactions: transactions, transactions: specificTransactions, filterDictionary: filterDictionary["financeAccount"], selectedIndex: selectedIndex)
        } else if let object = object as? [AccountDetails], let accounts = accountsDictionary[object[indexPath.item]] {
            showAccountDetailDetailPush(accountDetails: object[indexPath.item], allAccounts: accounts, accounts: accounts, selectedIndex: selectedIndex)
        } else if let object = object as? [Transaction] {
            showTransactionDetailPresent(transaction: object[indexPath.item], updateDiscoverDelegate: nil, delegate: nil, users: nil, container: nil, movingBackwards: nil)
        } else if let object = object as? [MXAccount] {
            showAccountDetailPresent(account: object[indexPath.item], updateDiscoverDelegate: nil)
        } else if let object = object as? [MXHolding] {
            showHoldingDetailPresent(holding: object[indexPath.item], updateDiscoverDelegate: nil)
        } else if let object = object as? [MXMember] {
            self.openMXConnect(current_member_guid: object[indexPath.item].guid, delegate: self)
        }
        collectionView.deselectItem(at: indexPath, animated: true)
    }
}

extension FinanceViewController: HeaderCellDelegate {
    func viewTapped(sectionType: SectionType) {
        let destination = FinanceDetailViewController(networkController: networkController)
        destination.title = sectionType.name
        destination.setSections = [sectionType]
        destination.selectedIndex = selectedIndex
        navigationController?.pushViewController(destination, animated: true)
    }
}

extension FinanceViewController: EndedWebViewDelegate {
    func updateMXMembers() {
        sections.removeAll(where: { $0 == .financialIssues })
        groups[.financialIssues] = nil
        collectionView.reloadData()
        networkController.financeService.regrabFinances {}
    }
}

extension FinanceViewController: CustomSegmentedControlDelegate {
    func changeToIndex(index:Int) {
        if index == 0 {
            startDate = Date().localTime.startOfDay
        } else if index == 1 {
            startDate = Date().localTime.startOfWeek
        } else if index == 2 {
            startDate = Date().localTime.startOfMonth
        } else {
            startDate = Date().localTime.startOfYear
        }
        selectedIndex = index
        updateCollectionView()
    }
}

extension FinanceViewController: UpdateFilter {
    func updateFilter(filterDictionary : [String: [String]]) {
        self.filterDictionary = filterDictionary
        updateCollectionView()
    }
}


