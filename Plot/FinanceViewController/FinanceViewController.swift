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
        layout.scrollDirection = .vertical
        layout.sectionInset = UIEdgeInsets(top: 0, left: 10, bottom: 20, right: 10)
        
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
    var institutionDict: [String: String] {
        return networkController.financeService.institutionDict
    }
    var users: [User] {
        return networkController.userService.users
    }
    var filteredUsers: [User] {
        return networkController.userService.users
    }
            
    var setSections: [SectionType] = [.financialIssues, .balanceSheet, .financialAccounts, .incomeStatement, .transactions]
    var sections = [SectionType]()
    var groups = [SectionType: [AnyHashable]]()
    
    private let kHeaderCell = "HeaderCell"
    private let kFinanceCollectionViewCell = "FinanceCollectionViewCell"
    private let kFinanceCollectionViewMemberCell = "FinanceCollectionViewMemberCell"
    
    let isodateFormatter = ISO8601DateFormatter()
    let dateFormatterPrint = DateFormatter()
    
    var startDate = Date().startOfMonth
    var endDate = Date().endOfMonth
    
    var hasViewAppeared = false
    
    var participants: [String: [User]] = [:]
    
    let closeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(named: "close"), for: .normal)
        button.tintColor = .systemBlue
        button.addTarget(self, action: #selector(handleDismiss), for: .touchUpInside)
        return button
    }()
    
    @objc fileprivate func handleDismiss(button: UIButton) {
        dismiss(animated: true, completion: nil)
    }
    
    override var prefersStatusBarHidden: Bool { return true }
        
    override func viewDidLoad() {
        super.viewDidLoad()
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
    
    override func viewWillAppear(_ animated: Bool) {
        navigationController?.isNavigationBarHidden = true
        navigationController?.navigationBar.isHidden = true
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    fileprivate func addObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(changeTheme), name: .themeUpdated, object: nil)
    }
    
    @objc fileprivate func changeTheme() {
        view.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
        collectionView.indicatorStyle = ThemeManager.currentTheme().scrollBarStyle
        collectionView.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
        customSegmented.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
        collectionView.reloadData()
        
    }
    
    fileprivate func setupMainView() {
        edgesForExtendedLayout = UIRectEdge.top
        view.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
        collectionView.indicatorStyle = ThemeManager.currentTheme().scrollBarStyle
        collectionView.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
        
        customSegmented.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
        customSegmented.constrainHeight(30)
                        
        closeButton.constrainHeight(50)
        closeButton.constrainWidth(50)
        
        view.addSubview(closeButton)
        view.addSubview(customSegmented)
        view.addSubview(collectionView)

        closeButton.anchor(top: view.topAnchor, leading: nil, bottom: nil, trailing: view.trailingAnchor, padding: .init(top: 20, left: 0, bottom: 0, right: 20))

        customSegmented.anchor(top: closeButton.bottomAnchor, leading: view.safeAreaLayoutGuide.leadingAnchor, bottom: nil, trailing: view.safeAreaLayoutGuide.trailingAnchor, padding: .init(top: 0, left: 0, bottom: 0, right: 0))
        collectionView.anchor(top: customSegmented.bottomAnchor, leading: view.safeAreaLayoutGuide.leadingAnchor, bottom: view.safeAreaLayoutGuide.bottomAnchor, trailing: view.safeAreaLayoutGuide.trailingAnchor, padding: .init(top: 10, left: 0, bottom: 0, right: 0))
                

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
    
    private func updateCollectionView() {
        guard currentReachabilityStatus != .notReachable else {
            return
        }
        var accountLevel: AccountCatLevel!
        var transactionLevel: TransactionCatLevel!
        accountLevel = .none
        transactionLevel = .none
        
        setSections = [.financialIssues, .balanceSheet, .financialAccounts, .incomeStatement, .transactions]
                
        self.sections = []
        self.groups = [SectionType: [AnyHashable]]()
                        
        let dispatchGroup = DispatchGroup()
        
        for section in setSections {
            dispatchGroup.enter()
            if section.type == "Issues" {
                dispatchGroup.enter()
                if !members.isEmpty {
                    sections.append(.financialIssues)
                    self.groups[section] = members
                    dispatchGroup.leave()
                } else {
                    dispatchGroup.leave()
                }
            } else if section.type == "Accounts" {
                if section.subType == "Balance Sheet" {
                    dispatchGroup.enter()
                    categorizeAccounts(accounts: accounts, level: accountLevel) { (accountsList, accountsDict) in
                        if !accountsList.isEmpty {
                            self.sections.append(.balanceSheet)
                            self.groups[section] = accountsList
                        }
                        dispatchGroup.leave()
                    }
                } else if section.subType == "Accounts" {
                    dispatchGroup.enter()
                    if !accounts.isEmpty {
                        self.sections.append(.financialAccounts)
                        self.groups[section] = accounts
                        dispatchGroup.leave()
                    } else {
                        dispatchGroup.leave()
                    }
                }
            } else if section.type == "Transactions" {
                if section.subType == "Income Statement" {
                    dispatchGroup.enter()
                    categorizeTransactions(transactions: transactions, start: startDate, end: endDate, level: transactionLevel) { (transactionsList, transactionsDict) in
                        if !transactionsList.isEmpty {
                            self.sections.append(.incomeStatement)
                            self.groups[section] = transactionsList
                        }
                        dispatchGroup.leave()
                    }
                } else if section.subType == "Transactions" {
                    if !transactions.isEmpty {
                        dispatchGroup.enter()
                        var filteredTransactions = transactions.filter { (transaction) -> Bool in
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
                        }
                        if !filteredTransactions.isEmpty {
                            self.sections.append(.transactions)
                            filteredTransactions = filteredTransactions.sorted(by: { (transaction1, transaction2) -> Bool in
                                if let date1 = isodateFormatter.date(from: transaction1.transacted_at), let date2 = isodateFormatter.date(from: transaction2.transacted_at) {
                                    return date1 > date2
                                }
                                return transaction1.description < transaction2.description
                            })
                            self.groups[section] = filteredTransactions
                            dispatchGroup.leave()
                        } else {
                            dispatchGroup.leave()
                        }
                    }
                }
            }
            dispatchGroup.leave()
        }
        
        dispatchGroup.notify(queue: .main) {
            self.collectionView.reloadData()
        }
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
    
    func openTransactionDetails(transactionDetails: TransactionDetails) {
        let financeDetailViewModel = FinanceDetailViewModel(accountDetails: nil, accounts: nil, transactionDetails: transactionDetails, transactions: transactions, financeDetailService: FinanceDetailService())
        let financeDetailViewController = FinanceBarChartViewController(viewModel: financeDetailViewModel)
        financeDetailViewController.delegate = self
        financeDetailViewController.users = users
        financeDetailViewController.filteredUsers = filteredUsers
        financeDetailViewController.hidesBottomBarWhenPushed = true
        self.navigationController?.pushViewController(financeDetailViewController, animated: true)
    }
    
    func openAccountDetails(accountDetails: AccountDetails) {
        let financeDetailViewModel = FinanceDetailViewModel(accountDetails: accountDetails, accounts: accounts, transactionDetails: nil, transactions: nil, financeDetailService: FinanceDetailService())
        let financeDetailViewController = FinanceLineChartDetailViewController(viewModel: financeDetailViewModel)
        financeDetailViewController.delegate = self
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
        return groups[sec]?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let section = sections[indexPath.section]
        let object = groups[section]
        if section != .financialIssues {
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
        if section != .financialIssues {
            let dummyCell = FinanceCollectionViewCell(frame: .init(x: 0, y: 0, width: self.collectionView.frame.size.width - 20, height: 1000))
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
            let estimatedSize = dummyCell.systemLayoutSizeFitting(.init(width: self.collectionView.frame.size.width - 20, height: 1000))
            height = estimatedSize.height
        } else {
            let dummyCell = FinanceCollectionViewMemberCell(frame: .init(x: 0, y: 0, width: self.collectionView.frame.size.width - 20, height: 1000))
            if let object = object as? [MXMember] {
                if let imageURL = institutionDict[object[indexPath.item].institution_code] {
                    dummyCell.imageURL = imageURL
                    dummyCell.member = object[indexPath.item]
                }
            }
            dummyCell.layoutIfNeeded()
            let estimatedSize = dummyCell.systemLayoutSizeFitting(.init(width: self.collectionView.frame.size.width - 20, height: 1000))
            height = estimatedSize.height
        }
        return CGSize(width: self.collectionView.frame.size.width - 20, height: height)
        
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: self.collectionView.frame.size.width, height: 35)
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
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
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
                destination.delegate = self
                destination.transaction = object[indexPath.item]
                destination.users = users
                destination.filteredUsers = filteredUsers
                destination.hidesBottomBarWhenPushed = true
                self.getParticipants(transaction: object[indexPath.item], account: nil) { (participants) in
                    destination.selectedFalconUsers = participants
                    self.navigationController?.pushViewController(destination, animated: true)
                }
            }
        } else if let object = object as? [MXAccount] {
            if section.subType == "Accounts" {
                let destination = FinanceAccountViewController()
                destination.delegate = self
                destination.account = object[indexPath.item]
                destination.users = users
                destination.filteredUsers = filteredUsers
                destination.hidesBottomBarWhenPushed = true
                self.getParticipants(transaction: nil, account: object[indexPath.item]) { (participants) in
                    destination.selectedFalconUsers = participants
                    self.navigationController?.pushViewController(destination, animated: true)
                }
            }
        } else if let object = object as? [MXMember] {
            if section.type == "Issues" {
                self.openMXConnect(guid: user.guid, current_member_guid: object[indexPath.item].guid)
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
        for transaction in transactions {
            if let index = networkController.financeService.transactions.firstIndex(of: transaction) {
                networkController.financeService.transactions[index] = transaction
            }
        }
        updateCollectionView()
    }
    func updateAccounts(accounts: [MXAccount]) {
        for account in accounts {
            if let index = networkController.financeService.accounts.firstIndex(of: account) {
                networkController.financeService.accounts[index] = account
            }
        }
        updateCollectionView()
    }
}

extension FinanceViewController: UpdateAccountDelegate {
    func updateAccount(account: MXAccount) {
        if let index = networkController.financeService.accounts.firstIndex(of: account) {
            networkController.financeService.accounts[index] = account
            updateCollectionView()
        }
    }
}

extension FinanceViewController: UpdateTransactionDelegate {
    func updateTransaction(transaction: Transaction) {
        if let index = networkController.financeService.transactions.firstIndex(of: transaction) {
            networkController.financeService.transactions[index] = transaction
            updateCollectionView()
        }
    }
}

extension FinanceViewController: EndedWebViewDelegate {
    func updateMXMembers() {
        sections.removeAll(where: { $0 == .financialIssues })
        groups[.financialIssues] = nil
        collectionView.reloadData()
        networkController.financeService.getMXData()
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
        updateCollectionView()
        
    }
}


