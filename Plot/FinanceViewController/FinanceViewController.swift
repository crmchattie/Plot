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
    
    private let kHeaderCell = "HeaderCell"
    private let kFinanceCollectionViewCell = "FinanceCollectionViewCell"
    private let kFinanceCollectionViewMemberCell = "FinanceCollectionViewMemberCell"
    
    let isodateFormatter = ISO8601DateFormatter()
    let dateFormatterPrint = DateFormatter()
    
    var startDate = Date().localTime.startOfMonth
    var endDate = Date().localTime.endOfMonth
    
    var hasViewAppeared = false
    
    var participants: [String: [User]] = [:]
    
    var financeLevel: FinanceLevel = .all
    
    var filters: [filter] = [.financeLevel, .financeAccount]
    var filterDictionary = [String: [String]]()
    
    @objc fileprivate func handleDismiss(button: UIButton) {
        dismiss(animated: true, completion: nil)
    }
            
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.largeTitleDisplayMode = .never
        title = "Finance"
        
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
        NotificationCenter.default.addObserver(self, selector: #selector(changeTheme), name: .themeUpdated, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(financeUpdated), name: .financeUpdated, object: nil)

    }
    
    @objc fileprivate func changeTheme() {
        view.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
        collectionView.indicatorStyle = ThemeManager.currentTheme().scrollBarStyle
        collectionView.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
        customSegmented.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
        collectionView.reloadData()
        
    }
    
    @objc fileprivate func financeUpdated() {
        DispatchQueue.main.async {
            self.updateCollectionView()
        }
    }
    
    fileprivate func setupMainView() {
        extendedLayoutIncludesOpaqueBars = true
        
        view.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
        collectionView.indicatorStyle = ThemeManager.currentTheme().scrollBarStyle
        collectionView.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
        
        customSegmented.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
        customSegmented.constrainHeight(30)
                        
        view.addSubview(customSegmented)
        view.addSubview(collectionView)

        customSegmented.anchor(top: view.safeAreaLayoutGuide.topAnchor, leading: view.leadingAnchor, bottom: nil, trailing: view.trailingAnchor, padding: .init(top: 0, left: 0, bottom: 0, right: 0))
        collectionView.anchor(top: customSegmented.bottomAnchor, leading: view.leadingAnchor, bottom: view.bottomAnchor, trailing: view.trailingAnchor, padding: .init(top: 10, left: 0, bottom: 0, right: 0))
        
        let newItemBarButton =  UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(newItem))
        let filterBarButton = UIBarButtonItem(image: UIImage(named: "filter"), style: .plain, target: self, action: #selector(filter))
        navigationItem.rightBarButtonItems = [newItemBarButton, filterBarButton]
        
        financeLevel = getFinanceLevel()
                

    }
    
    @objc fileprivate func newItem() {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        alert.addAction(UIAlertAction(title: "Transaction", style: .default, handler: { (_) in
            let destination = FinanceTransactionViewController()
            destination.users = self.networkController.userService.users
            destination.filteredUsers = self.networkController.userService.users
            let cancelBarButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: destination, action: nil)
            destination.navigationItem.leftBarButtonItem = cancelBarButton
            let navigationViewController = UINavigationController(rootViewController: destination)
            self.present(navigationViewController, animated: true, completion: nil)
        }))
        
        alert.addAction(UIAlertAction(title: "Account", style: .default, handler: { (_) in
            print("User click Edit button")
            self.openMXConnect(current_member_guid: nil)
        }))
        
        alert.addAction(UIAlertAction(title: "Transaction Rule", style: .default, handler: { (_) in
            print("User click Edit button")
            let destination = FinanceTransactionRuleViewController()
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
        let destination = FilterViewController()
        let navigationViewController = UINavigationController(rootViewController: destination)
        destination.delegate = self
        destination.filters = filters
        destination.filterDictionary = filterDictionary
        self.present(navigationViewController, animated: true, completion: nil)
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
        
        let setSections: [SectionType] = [.financialIssues, .incomeStatement, .balanceSheet, .transactions, .investments, .financialAccounts]
                
        self.sections = []
        self.groups = [SectionType: [AnyHashable]]()
                        
        let dispatchGroup = DispatchGroup()
        
        for section in setSections {
            dispatchGroup.enter()
            if section.type == "Issues" {
                dispatchGroup.enter()
                var challengedMembers = [MXMember]()
                for member in members {
                    dispatchGroup.enter()
                    if member.connection_status != .connected && member.connection_status != .created && member.connection_status != .updated && member.connection_status != .delayed && member.connection_status != .resumed && member.connection_status != .pending {
                        challengedMembers.append(member)
                    }
                    dispatchGroup.leave()
                }
                if !challengedMembers.isEmpty {
                    self.sections.append(section)
                    self.groups[section] = challengedMembers
                    dispatchGroup.leave()
                } else {
                    dispatchGroup.leave()
                }
            } else if section.type == "Accounts" {
                if section.subType == "Balance Sheet" {
                    dispatchGroup.enter()
                    categorizeAccounts(accounts: accounts, level: accountLevel) { (accountsList, accountsDict) in
                        if !accountsList.isEmpty {
                            self.sections.append(section)
                            self.groups[section] = accountsList
                            self.accountsDictionary = accountsDict
                        }
                        dispatchGroup.leave()
                    }
                } else if section.subType == "Accounts" {
                    dispatchGroup.enter()
                    if !accounts.isEmpty {
                        self.sections.append(section)
                        self.groups[section] = accounts
                        dispatchGroup.leave()
                    } else {
                        dispatchGroup.leave()
                    }
                }
            } else if section.type == "Transactions" {
                var accounts = [String]()
                if let filterAccounts = filterDictionary["financeAccount"] {
                    accounts = filterAccounts
                } else {
                    accounts = transactions.compactMap({ $0.account_guid })
                }
                if section.subType == "Income Statement" {
                    dispatchGroup.enter()
                    categorizeTransactions(transactions: transactions, start: startDate, end: endDate, level: transactionLevel, accounts: accounts) { (transactionsList, transactionsDict) in
                        if !transactionsList.isEmpty {
                            self.sections.append(section)
                            self.groups[section] = transactionsList
                            self.transactionsDictionary = transactionsDict
                        }
                        dispatchGroup.leave()
                    }
                } else if section.subType == "Transactions" {
                    if !transactions.isEmpty {
                        dispatchGroup.enter()
                        var filteredTransactions = transactions.filter { (transaction) -> Bool in
                            if let account = transaction.account_guid {
                                if accounts.contains(account) {
                                    if let date = transaction.date_for_reports, date != "", let transactionDate = isodateFormatter.date(from: date) {
                                        if transactionDate > startDate && endDate > transactionDate {
                                            return true
                                        }
                                    } else if let transactionDate = isodateFormatter.date(from: transaction.transacted_at) {
                                        if transactionDate > startDate && endDate > transactionDate {
                                            return true
                                        }
                                    }
                                }
                            }
                            return false
                        }
                        if !filteredTransactions.isEmpty {
                            self.sections.append(section)
                            filteredTransactions.sort { (transaction1, transaction2) -> Bool in
                                if transaction1.should_link ?? true == transaction2.should_link ?? true {
                                    if let date1 = isodateFormatter.date(from: transaction1.transacted_at), let date2 = isodateFormatter.date(from: transaction2.transacted_at) {
                                        return date1 > date2
                                    }
                                    return transaction1.description < transaction2.description
                                }
                                return transaction1.should_link ?? true && !(transaction2.should_link ?? true)
                            }
                            self.groups[section] = filteredTransactions
                            dispatchGroup.leave()
                        } else {
                            dispatchGroup.leave()
                        }
                    }
                }
            } else if section.type == "Investments" {
                if !holdings.isEmpty {
                    self.sections.append(section)
                    self.groups[section] = holdings
                }
            }
            dispatchGroup.leave()
        }
        
        dispatchGroup.notify(queue: .main) {
            print("moving forward")
            self.collectionView.reloadData()
            self.saveFinanceLevel()
        }
    }
    
    func getParticipants(transaction: Transaction?, account: MXAccount?, holding: MXHolding?, completion: @escaping ([User])->()) {
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
        } else if let holding = holding, let participantsIDs = holding.participantsIDs, let currentUserID = Auth.auth().currentUser?.uid {
            let group = DispatchGroup()
            let ID = holding.guid
            let olderParticipants = self.participants[ID]
            var participants: [User] = []
            
            for id in participantsIDs {
                if holding.admin == currentUserID && id == currentUserID {
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
    
    func openTransactionDetails(transactionDetails: TransactionDetails) {
        var accounts = [String]()
        if let filterAccounts = filterDictionary["financeAccount"] {
            accounts = filterAccounts
        } else {
            accounts = transactions.compactMap({ $0.account_guid })
        }
        let financeDetailViewModel = FinanceDetailViewModel(accountDetails: nil, allAccounts: nil, accounts: nil, transactionDetails: transactionDetails, allTransactions: transactions, transactions: transactionsDictionary[transactionDetails], filterAccounts: accounts,  financeDetailService: FinanceDetailService())
        let financeDetailViewController = FinanceBarChartViewController(viewModel: financeDetailViewModel)
        financeDetailViewController.selectedIndex = selectedIndex
//        financeDetailViewController.delegate = self
        financeDetailViewController.users = users
        financeDetailViewController.filteredUsers = filteredUsers
        financeDetailViewController.hidesBottomBarWhenPushed = true
        self.navigationController?.pushViewController(financeDetailViewController, animated: true)
    }
    
    func openAccountDetails(accountDetails: AccountDetails) {
        let financeDetailViewModel = FinanceDetailViewModel(accountDetails: accountDetails, allAccounts: accounts, accounts: accountsDictionary[accountDetails], transactionDetails: nil, allTransactions: nil, transactions: nil, filterAccounts: nil, financeDetailService: FinanceDetailService())
        let financeDetailViewController = FinanceLineChartDetailViewController(viewModel: financeDetailViewModel)
        financeDetailViewController.selectedIndex = selectedIndex
//        financeDetailViewController.delegate = self
        financeDetailViewController.users = users
        financeDetailViewController.filteredUsers = filteredUsers
        financeDetailViewController.hidesBottomBarWhenPushed = true
        self.navigationController?.pushViewController(financeDetailViewController, animated: true)
    }
}

extension FinanceViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return sections.count
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let sec = sections[section]
        if sec == .transactions || sec == .financialAccounts || sec == .investments {
            if groups[sec]?.count ?? 0 < 10 {
                return groups[sec]?.count ?? 0
            }
            return 10
        } else {
            return groups[sec]?.count ?? 0
        }
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
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: self.kFinanceCollectionViewMemberCell, for: indexPath) as! FinanceCollectionViewMemberCell
            cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
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
            height = 70
        }
        return CGSize(width: self.collectionView.frame.size.width - 30, height: height)
        
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: self.collectionView.frame.size.width, height: 40)
    }
    
    func collectionView(_ collectionView: UICollectionView,
        viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let section = sections[indexPath.section]
        let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: self.kHeaderCell, for: indexPath) as! HeaderCell
        header.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
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
                let destination = FinanceTransactionViewController()
                destination.transaction = object[indexPath.item]
                destination.users = users
                destination.filteredUsers = filteredUsers
                self.getParticipants(transaction: object[indexPath.item], account: nil, holding: nil) { (participants) in
                    destination.selectedFalconUsers = participants
                    self.navigationController?.pushViewController(destination, animated: true)
                }
            }
        } else if let object = object as? [MXAccount] {
            if section.subType == "Accounts" {
                let destination = FinanceAccountViewController()
                destination.account = object[indexPath.item]
                destination.users = users
                destination.filteredUsers = filteredUsers
                self.getParticipants(transaction: nil, account: object[indexPath.item], holding: nil) { (participants) in
                    destination.selectedFalconUsers = participants
                    self.navigationController?.pushViewController(destination, animated: true)
                }
            }
        } else if let object = object as? [MXHolding] {
            if section.subType == "Investments" {
                let destination = FinanceHoldingViewController()
                destination.holding = object[indexPath.item]
                destination.accounts = accounts
                destination.users = users
                destination.filteredUsers = filteredUsers
                self.getParticipants(transaction: nil, account: nil, holding: object[indexPath.item]) { (participants) in
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
        let destination = FinanceDetailViewController()
        destination.title = sectionType.name
        destination.networkController = networkController
        destination.setSections = [sectionType]
        destination.selectedIndex = selectedIndex
        navigationController?.pushViewController(destination, animated: true)
    }
}

//extension FinanceViewController: UpdateFinancialsDelegate {
//    func updateTransactions(transactions: [Transaction]) {
//        for transaction in transactions {
//            if let index = networkController.financeService.transactions.firstIndex(of: transaction) {
//                networkController.financeService.transactions[index] = transaction
//            }
//        }
//        updateCollectionView()
//    }
//    func updateAccounts(accounts: [MXAccount]) {
//        for account in accounts {
//            if let index = networkController.financeService.accounts.firstIndex(of: account) {
//                networkController.financeService.accounts[index] = account
//            }
//        }
//        updateCollectionView()
//    }
//}
//
//extension FinanceViewController: UpdateAccountDelegate {
//    func updateAccount(account: MXAccount) {
//        if let index = networkController.financeService.accounts.firstIndex(of: account) {
//            networkController.financeService.accounts[index] = account
//            updateCollectionView()
//        }
//    }
//}
//
//extension FinanceViewController: UpdateTransactionDelegate {
//    func updateTransaction(transaction: Transaction) {
//        if let index = networkController.financeService.transactions.firstIndex(of: transaction) {
//            networkController.financeService.transactions[index] = transaction
//            updateCollectionView()
//        }
//    }
//}

extension FinanceViewController: EndedWebViewDelegate {
    func updateMXMembers() {
        sections.removeAll(where: { $0 == .financialIssues })
        groups[.financialIssues] = nil
        collectionView.reloadData()
        networkController.financeService.triggerUpdateMXUser()
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


