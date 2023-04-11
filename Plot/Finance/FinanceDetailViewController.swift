//
//  FinanceDetailViewController.swift
//  Plot
//
//  Created by Cory McHattie on 2/17/21.
//  Copyright © 2021 Immature Creations. All rights reserved.
//


import UIKit
import Firebase
import CodableFirebase

class FinanceDetailViewController: UIViewController, ObjectDetailShowing {
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
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 10, right: 0)
        layout.scrollDirection = .vertical
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.contentInset.bottom = 0
        return collectionView
    }()
        
    var user: MXUser {
        return networkController.financeService.mxUser
    }
    var transactions = [Transaction]()
    var accounts: [MXAccount] {
        return networkController.financeService.accounts
    }
    var members: [MXMember] {
        return networkController.financeService.members
    }
    var holdings: [MXHolding] {
        return networkController.financeService.holdings
    }
            
    var setSections = [SectionType]()
    var sections = [SectionType]()
    var groups = [SectionType: [AnyHashable]]()
    
    private let kHeaderCell = "HeaderCell"
    private let kFinanceCollectionViewCell = "FinanceCollectionViewCell"
    private let kFinanceCollectionViewMemberCell = "FinanceCollectionViewMemberCell"
    
    let isodateFormatter = ISO8601DateFormatter()
    let dateFormatterPrint = DateFormatter()
        
    var participants: [String: [User]] = [:]
    
    var filters: [filter] = []
    var filterDictionary = [String: [String]]()
    
    var startDate = Date().localTime.startOfMonth
    var endDate = Date().localTime.nextYear
    
    let viewPlaceholder = ViewPlaceholder()
    
    var selectedIndex = 2
            
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.largeTitleDisplayMode = .never
                
        collectionView.dataSource = self
        collectionView.delegate = self
        
        collectionView.register(HeaderCell.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: kHeaderCell)
        collectionView.register(FinanceCollectionViewCell.self, forCellWithReuseIdentifier: kFinanceCollectionViewCell)
        collectionView.register(FinanceCollectionViewMemberCell.self, forCellWithReuseIdentifier: kFinanceCollectionViewMemberCell)
        
        setupMainView()
        setupData()
        addObservers()
        
        if selectedIndex == 0 {
            startDate = Date().localTime.startOfDay
            endDate = Date().localTime.nextYear
        } else if selectedIndex == 1 {
            startDate = Date().localTime.startOfWeek
            endDate = Date().localTime.nextYear
        } else if selectedIndex == 2 {
            startDate = Date().localTime.startOfMonth
            endDate = Date().localTime.nextYear
        } else {
            startDate = Date().localTime.startOfYear
            endDate = Date().localTime.nextYear
        }
    }
    
    deinit {
        print("deinit")
        if setSections.contains(.transactions) {
            networkController.financeService.transactionFetcher.removeObservers()
        }
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
        edgesForExtendedLayout = UIRectEdge.top
        view.backgroundColor = .systemGroupedBackground
        collectionView.indicatorStyle = .default
        collectionView.backgroundColor = .systemGroupedBackground
        
        let newItemBarButton =  UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(newItem))
        let filterBarButton = UIBarButtonItem(image: UIImage(named: "filter"), style: .plain, target: self, action: #selector(filter))
        navigationItem.rightBarButtonItems = [newItemBarButton, filterBarButton]

        view.addSubview(collectionView)
        collectionView.anchor(top: view.safeAreaLayoutGuide.topAnchor, leading: view.leadingAnchor, bottom: view.bottomAnchor, trailing: view.trailingAnchor, padding: .init(top: 0, left: 0, bottom: 0, right: 0))
        
        view.addSubview(activityIndicatorView)
        activityIndicatorView.centerInSuperview()
    }
    
    @objc fileprivate func setupData() {
        activityIndicatorView.startAnimating()
        if setSections.contains(.transactions) {
            transactions.append(contentsOf: networkController.financeService.transactions)
            networkController.financeService.transactionFetcher.loadUnloadedTransaction(startDate: nil, endDate: nil) { transactionsList in
                for transaction in transactionsList {
                    if let index = self.transactions.firstIndex(where: { $0.guid == transaction.guid }) {
                        self.transactions[index] = transaction
                    } else {
                        self.transactions.append(transaction)
                    }
                }
                let filteredTransactions = self.transactions.filter { (transaction) -> Bool in
                    if let transactionDate = transaction.transactionDate {
                        if transactionDate.localTime > self.startDate && self.endDate > transactionDate.localTime {
                            return true
                        }
                    }
                    return false
                }
                self.sections.append(.transactions)
                self.groups[.transactions] = filteredTransactions
                self.filters = [.search, .financeAccount, .showPendingTransactions, .startDate, .endDate]
                DispatchQueue.main.async {
                    activityIndicatorView.stopAnimating()
                    self.collectionView.reloadData()
                }
            }
        } else if setSections.contains(.financialAccounts) {
            self.sections.append(.financialAccounts)
            self.groups[.financialAccounts] = accounts
            filters = [.search]
            DispatchQueue.main.async {
                activityIndicatorView.stopAnimating()
                self.collectionView.reloadData()
            }
        } else if setSections.contains(.investments) {
            self.sections.append(.investments)
            self.groups[.investments] = holdings
            filters = [.search, .financeAccount]
            DispatchQueue.main.async {
                activityIndicatorView.stopAnimating()
                self.collectionView.reloadData()
            }
        }
    }
    
    @objc fileprivate func newItem() {
        if setSections.contains(.transactions) {
            showTransactionDetailPresent(transaction: nil, updateDiscoverDelegate: nil, delegate: nil, users: nil, container: nil, movingBackwards: nil)
        } else if setSections.contains(.investments) {
            showHoldingDetailPresent(holding: nil, updateDiscoverDelegate: nil)
        } else if setSections.contains(.financialAccounts) {
            self.newAccount()
        }
    }
    
    @objc fileprivate func filter() {
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
    
    private func updateCollectionView() {
        self.sections = []
        self.groups = [SectionType: [AnyHashable]]()
        
        DispatchQueue.main.async {
            activityIndicatorView.startAnimating()
            self.collectionView.reloadData()
        }
                
        for section in setSections {
            if section.type == "Accounts" {
                var filteredAccounts = accounts
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
            } else if section.type == "Transactions" {
                var filteredTransactions = transactions
                if let value = filterDictionary["search"] {
                    let searchText = value[0]
                    filteredTransactions = filteredTransactions.filter({ (transaction) -> Bool in
                        return transaction.description.lowercased().contains(searchText.lowercased())
                    })
                }
                if let accounts = filterDictionary["financeAccount"] {
                    filteredTransactions = filteredTransactions.filter({ (transaction) -> Bool in
                        accounts.contains(transaction.account_guid ?? "")
                    })
                }
                if let value = filterDictionary["showPendingTransactions"] {
                    let bool = value[0].lowercased()
                    if bool == "no" {
                        filteredTransactions = filteredTransactions.filter({ (transaction) -> Bool in
                            transaction.status == .posted
                        })
                    }
                }
                if let filterStartDate = filterDictionary["startDate"], let filterEndDate = filterDictionary["endDate"] {
                    startDate = isodateFormatter.date(from: filterStartDate[0]) ?? Date.distantPast
                    endDate = isodateFormatter.date(from: filterEndDate[0]) ?? Date.distantFuture
                    
                    filteredTransactions = filteredTransactions.filter { (transaction) -> Bool in
                        if let transactionDate = transaction.transactionDate {
                            if transactionDate.localTime > startDate && endDate > transactionDate.localTime {
                                return true
                            }
                        }
                        return false
                    }
                }
                else if let filterStartDate = filterDictionary["startDate"] {
                    startDate = isodateFormatter.date(from: filterStartDate[0]) ?? Date.distantPast
                    filteredTransactions = filteredTransactions.filter { (transaction) -> Bool in
                        if let transactionDate = transaction.transactionDate {
                            if transactionDate > startDate {
                                return true
                            }
                        }
                        return false
                    }
                }
                else if let filterEndDate = filterDictionary["endDate"] {
                    endDate = isodateFormatter.date(from: filterEndDate[0]) ?? Date.distantFuture
                    filteredTransactions = filteredTransactions.filter { (transaction) -> Bool in
                        if let transactionDate = transaction.transactionDate {
                            if endDate > transactionDate {
                                return true
                            }
                        }
                        return false
                    }
                }
                else {
                    filteredTransactions = filteredTransactions.filter { (transaction) -> Bool in
                        if let transactionDate = transaction.transactionDate {
                            if transactionDate.localTime > startDate && endDate > transactionDate.localTime {
                                return true
                            }
                        }
                        return false
                    }
                }
                if !filteredTransactions.isEmpty {
                    self.sections.append(section)
                    self.groups[section] = filteredTransactions
                }
            } else if section.type == "Investments" {
                var filteredHoldings = holdings
                if let value = filterDictionary["search"] {
                    let searchText = value[0]
                    filteredHoldings = filteredHoldings.filter({ (holding) -> Bool in
                        return holding.description.lowercased().contains(searchText.lowercased())
                    })
                }
                if let accounts =  filterDictionary["financeAccount"] {
                    filteredHoldings = filteredHoldings.filter { (holding) -> Bool in
                        accounts.contains(holding.account_guid ?? "")
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

extension FinanceDetailViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        if sections.count == 0, !filterDictionary.isEmpty {
            viewPlaceholder.add(for: collectionView, title: .emptySearch, subtitle: .emptySearch, priority: .medium, position: .fill)
        } else {
            viewPlaceholder.remove(from: collectionView, priority: .medium)
        }
        return sections.count
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let sec = sections[section]
        return groups[sec]?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let section = sections[indexPath.section]
        let object = groups[section]
        let totalItems = collectionView.numberOfItems(inSection: indexPath.section) - 1
        if section != .financialIssues {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: self.kFinanceCollectionViewCell, for: indexPath) as! FinanceCollectionViewCell
            if indexPath.item == 0 {
                cell.firstPosition = true
            }
            if indexPath.item == totalItems {
                cell.lastPosition = true
            }
            if let object = object as? [TransactionDetails] {
                cell.transactionDetails = object[indexPath.item]
            } else if let object = object as? [AccountDetails] {
                cell.accountDetails = object[indexPath.item]
            } else if let object = object as? [MXHolding] {
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
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: self.kFinanceCollectionViewMemberCell, for: indexPath) as! FinanceCollectionViewMemberCell
            cell.backgroundColor = .secondarySystemGroupedBackground
            if let object = object as? [MXMember] {
                cell.member = object[indexPath.item]
            }
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        var height: CGFloat = 328
        let section = sections[indexPath.section]
        let object = groups[section]
        let totalItems = collectionView.numberOfItems(inSection: indexPath.section) - 1
        if section != .financialIssues {
            let dummyCell = FinanceCollectionViewCell(frame: .init(x: 0, y: 0, width: self.collectionView.frame.size.width - 30, height: 1000))
            if indexPath.item == 0 {
                dummyCell.firstPosition = true
            }
            if indexPath.item == totalItems {
                dummyCell.lastPosition = true
            }
            if let object = object as? [TransactionDetails] {
                dummyCell.transactionDetails = object[indexPath.item]
            } else if let object = object as? [AccountDetails] {
                dummyCell.accountDetails = object[indexPath.item]
            } else if let object = object as? [MXHolding] {
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
        } else {
            height = 70
        }
        return CGSize(width: self.collectionView.frame.size.width - 30, height: height)
        
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: self.collectionView.frame.size.width, height: 0)
    }
    
    func collectionView(_ collectionView: UICollectionView,
        viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let section = sections[indexPath.section]
        let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: self.kHeaderCell, for: indexPath) as! HeaderCell
        header.backgroundColor = .systemGroupedBackground
        header.delegate = self
        header.titleLabel.text = section.name
        header.subTitleLabel.isHidden = true
        return header
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        let section = sections[section]
        if section == .transactions || section == .financialAccounts || section == .financialIssues || section == .investments {
            return 10
        }
        return 0
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let section = sections[indexPath.section]
        let object = groups[section]
        if let object = object as? [TransactionDetails] {
            if section.subType == "Income Statement" {
                let accounts = transactions.compactMap({ $0.account_guid })
                showTransactionDetailDetailPush(transactionDetails: object[indexPath.item], allTransactions: transactions, transactions: transactions, filterDictionary: accounts, selectedIndex: nil)
            }
        } else if let object = object as? [AccountDetails] {
            if section.subType == "Balance Sheet" {
                showAccountDetailDetailPush(accountDetails: object[indexPath.item], allAccounts: accounts, accounts: accounts, selectedIndex: nil)
            }
        } else if let object = object as? [Transaction] {
            if section.subType == "Transactions" {
                showTransactionDetailPresent(transaction: object[indexPath.item], updateDiscoverDelegate: nil, delegate: nil, users: nil, container: nil, movingBackwards: nil)
            }
        } else if let object = object as? [MXAccount] {
            if section.subType == "Accounts" {
                showAccountDetailPresent(account: object[indexPath.item], updateDiscoverDelegate: nil)
            }
        } else if let object = object as? [MXHolding] {
            if section.subType == "Investments" {
                showHoldingDetailPresent(holding: object[indexPath.item], updateDiscoverDelegate: nil)
            }
        } else if let object = object as? [MXMember] {
            if section.type == "Issues" {
                self.openMXConnect(current_member_guid: object[indexPath.item].guid, delegate: self)
            }
        }
        collectionView.deselectItem(at: indexPath, animated: true)
    }
}

extension FinanceDetailViewController: HeaderCellDelegate {
    func viewTapped(sectionType: SectionType) {
        
    }
}

extension FinanceDetailViewController: EndedWebViewDelegate {
    func updateMXMembers() {
        sections.removeAll(where: { $0 == .financialIssues })
        groups[.financialIssues] = nil
        collectionView.reloadData()
        networkController.financeService.regrabFinances {}
    }
}

extension FinanceDetailViewController: UpdateFilter {
    func updateFilter(filterDictionary : [String: [String]]) {
        self.filterDictionary = filterDictionary
        updateCollectionView()
    }
}

