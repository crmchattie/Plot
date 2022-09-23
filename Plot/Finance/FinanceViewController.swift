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

class FinanceViewController: UIViewController {
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
            
    var sections = [SectionType]()
    var groups = [SectionType: [AnyHashable]]()
    
    let isodateFormatter = ISO8601DateFormatter()
    let dateFormatterPrint = DateFormatter()
    
    var startDate = Date().localTime.startOfMonth
    var endDate = Date().localTime.endOfMonth
    
    var hasViewAppeared = false
    
    var participants: [String: [User]] = [:]
    
    var financeLevel: FinanceLevel = .all
    
    var filters: [filter] = [.search, .financeLevel, .financeAccount]
    var filterDictionary = [String: [String]]()
    
    let viewPlaceholder = ViewPlaceholder()
    
    let refreshControl = UIRefreshControl()
            
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.largeTitleDisplayMode = .never
        title = "Finances"
        
        customSegmented.delegate = self
        collectionView.dataSource = self
        collectionView.delegate = self
        
        collectionView.register(HeaderCell.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: kHeaderCell)
        collectionView.register(FinanceCollectionViewCell.self, forCellWithReuseIdentifier: kFinanceCollectionViewCell)
        collectionView.register(FinanceCollectionViewMemberCell.self, forCellWithReuseIdentifier: kFinanceCollectionViewMemberCell)
        
        setupMainView()
        addObservers()
        updateCollectionView()
        
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    fileprivate func addObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(financeUpdated), name: .financeUpdated, object: nil)

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
            let destination = FinanceTransactionViewController(networkController: self.networkController)
            let cancelBarButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: destination, action: nil)
            destination.navigationItem.leftBarButtonItem = cancelBarButton
            let navigationViewController = UINavigationController(rootViewController: destination)
            self.present(navigationViewController, animated: true, completion: nil)
        }))
        
        alert.addAction(UIAlertAction(title: "Investment", style: .default, handler: { (_) in
            let destination = FinanceHoldingViewController(networkController: self.networkController)
            let cancelBarButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: destination, action: nil)
            destination.navigationItem.leftBarButtonItem = cancelBarButton
            let navigationViewController = UINavigationController(rootViewController: destination)
            self.present(navigationViewController, animated: true, completion: nil)
        }))
        
        alert.addAction(UIAlertAction(title: "Account", style: .default, handler: { (_) in
            print("User click Edit button")
            self.newAccount()
        }))
        
        alert.addAction(UIAlertAction(title: "Transaction Rule", style: .default, handler: { (_) in
            print("User click Edit button")
            let destination = FinanceTransactionRuleViewController(networkController: self.networkController)
            let cancelBarButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: destination, action: nil)
            destination.navigationItem.leftBarButtonItem = cancelBarButton
            let navigationViewController = UINavigationController(rootViewController: destination)
            self.present(navigationViewController, animated: true, completion: nil)
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
            self.openMXConnect(current_member_guid: nil)
        }))
        
        alert.addAction(UIAlertAction(title: "Manually Add Account", style: .default, handler: { (_) in
            let destination = FinanceAccountViewController(networkController: self.networkController)
            self.navigationController?.pushViewController(destination, animated: true)
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
    
    func openMXConnect(current_member_guid: String?) {
        let destination = WebViewController()
        destination.current_member_guid = current_member_guid
        destination.controllerTitle = ""
        destination.delegate = self
        let navigationViewController = UINavigationController(rootViewController: destination)
        navigationViewController.modalPresentationStyle = .fullScreen
        self.present(navigationViewController, animated: true, completion: nil)
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
        
        let setSections: [SectionType] = [.financialIssues, .incomeStatement, .balanceSheet, .transactions, .investments, .financialAccounts]
                
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
                    categorizeAccounts(accounts: filteredAccounts, level: accountLevel) { (accountsList, accountsDict) in
                        if !accountsList.isEmpty {
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
                    categorizeTransactions(transactions: transactions, start: startDate, end: endDate, level: transactionLevel, accounts: filteredAccountsString) { (transactionsList, transactionsDict) in
                        if !transactionsList.isEmpty {
                            self.sections.append(section)
                            self.groups[section] = transactionsList
                            self.transactionsDictionary = transactionsDict
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
                            if let date = transaction.date_for_reports, date != "", let transactionDate = isodateFormatter.date(from: date) {
                                if transactionDate > startDate && endDate > transactionDate {
                                    return true
                                }
                            } else if let transactionDate = isodateFormatter.date(from: transaction.transacted_at) {
                                if transactionDate > startDate && endDate > transactionDate {
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
            self.collectionView.reloadData()
        }
    }
    
    func openTransactionDetails(transactionDetails: TransactionDetails) {
        let financeDetailViewModel = FinanceDetailViewModel(accountDetails: nil, allAccounts: nil, accounts: nil, transactionDetails: transactionDetails, allTransactions: transactions, transactions: transactionsDictionary[transactionDetails], filterAccounts: filterDictionary["financeAccount"],  financeDetailService: FinanceDetailService())
        let financeDetailViewController = FinanceBarChartViewController(viewModel: financeDetailViewModel, networkController: networkController)
        financeDetailViewController.selectedIndex = selectedIndex
//        financeDetailViewController.delegate = self
        financeDetailViewController.hidesBottomBarWhenPushed = true
        self.navigationController?.pushViewController(financeDetailViewController, animated: true)
    }
    
    func openAccountDetails(accountDetails: AccountDetails) {
        let financeDetailViewModel = FinanceDetailViewModel(accountDetails: accountDetails, allAccounts: accounts, accounts: accountsDictionary[accountDetails], transactionDetails: nil, allTransactions: nil, transactions: nil, filterAccounts: nil, financeDetailService: FinanceDetailService())
        let financeDetailViewController = FinanceLineChartDetailViewController(viewModel: financeDetailViewModel, networkController: networkController)
        financeDetailViewController.selectedIndex = selectedIndex
//        financeDetailViewController.delegate = self
        financeDetailViewController.hidesBottomBarWhenPushed = true
        self.navigationController?.pushViewController(financeDetailViewController, animated: true)
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
        if section != .financialIssues {
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
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: kFinanceCollectionViewMemberCell, for: indexPath) as! FinanceCollectionViewMemberCell
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
        } else {
            let dummyCell = FinanceCollectionViewMemberCell(frame: .init(x: 0, y: 0, width: self.collectionView.frame.size.width, height: 1000))
            if let object = object as? [MXMember] {
                dummyCell.member = object[indexPath.item]
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
        if section == .transactions || section == .financialAccounts || section == .financialIssues || section == .investments {
            return 10
        }
        return 0
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 0, bottom: 10, right: 0)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let section = sections[indexPath.section]
        let object = groups[section]
        if let object = object as? [TransactionDetails] {
            if section.subType == "Income Statement" {
                openTransactionDetails(transactionDetails: object[indexPath.item])
            }
        } else if let object = object as? [AccountDetails] {
            if section.subType == "Balance Sheet" {
                openAccountDetails(accountDetails: object[indexPath.item])
            }
        } else if let object = object as? [Transaction] {
            if section.subType == "Transactions" {
                let destination = FinanceTransactionViewController(networkController: self.networkController)
                destination.transaction = object[indexPath.item]
                ParticipantsFetcher.getParticipants(forTransaction: object[indexPath.item]) { (participants) in
                    destination.selectedFalconUsers = participants
                    self.navigationController?.pushViewController(destination, animated: true)
                }
            }
        } else if let object = object as? [MXAccount] {
            if section.subType == "Accounts" {
                let destination = FinanceAccountViewController(networkController: self.networkController)
                destination.account = object[indexPath.item]
                ParticipantsFetcher.getParticipants(forAccount: object[indexPath.item]) { (participants) in
                    destination.selectedFalconUsers = participants
                    self.navigationController?.pushViewController(destination, animated: true)
                }
            }
        } else if let object = object as? [MXHolding] {
            if section.subType == "Investments" {
                let destination = FinanceHoldingViewController(networkController: self.networkController)
                destination.holding = object[indexPath.item]
                ParticipantsFetcher.getParticipants(forHolding: object[indexPath.item]) { (participants) in
                    destination.selectedFalconUsers = participants
                    self.navigationController?.pushViewController(destination, animated: true)
                }
            }
        } else if let object = object as? [MXMember] {
            if section.type == "Issues" {
                self.openMXConnect(current_member_guid: object[indexPath.item].guid)
            }
        }
        collectionView.deselectItem(at: indexPath, animated: true)
    }
}

extension FinanceViewController: HeaderCellDelegate {
    func viewTapped(sectionType: SectionType) {
        let destination = FinanceDetailViewController(networkController: networkController)
        destination.title = sectionType.name
        destination.setSections = [sectionType]
        navigationController?.pushViewController(destination, animated: true)
    }
}

extension FinanceViewController: EndedWebViewDelegate {
    func updateMXMembers() {
        sections.removeAll(where: { $0 == .financialIssues })
        groups[.financialIssues] = nil
        collectionView.reloadData()
        networkController.financeService.triggerUpdateMXUser {}
    }
}

extension FinanceViewController: CustomSegmentedControlDelegate {
    func changeToIndex(index:Int) {
        if index == 0 {
            startDate = Date().localTime.startOfDay
            endDate = Date().localTime.endOfDay
        } else if index == 1 {
            startDate = Date().localTime.startOfWeek
            endDate = Date().localTime.endOfWeek
        } else if index == 2 {
            startDate = Date().localTime.startOfMonth
            endDate = Date().localTime.endOfMonth
        } else {
            startDate = Date().localTime.startOfYear
            endDate = Date().localTime.endOfYear
        }
        updateCollectionView()
        selectedIndex = index
    }
}

extension FinanceViewController: UpdateFilter {
    func updateFilter(filterDictionary : [String: [String]]) {
        self.filterDictionary = filterDictionary
        updateCollectionView()
    }
}


