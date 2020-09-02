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
    //    func sendLists(lists: [ListContainer])
}

class FinanceViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout {
    weak var delegate: HomeBaseFinance?
    
    //    var user: MXUser!
    //    var members = [MXMember]()
    var accountsDict = [String: [MXAccount]]()
    var transactionsAcctDict = [MXAccount: [Transaction]]()
    var categoryAmountDict = [String: Double]()
    var topcategoryAmountDict = [String: Double]()
    var groupAmountDict = [String: Double]()
    
    var sections: [SectionType] = []
    var groups = [SectionType: [AnyHashable]]()
    
    init() {
        
        let layout = UICollectionViewCompositionalLayout { (sectionNumber, _) -> NSCollectionLayoutSection? in
            if sectionNumber == 0 {
                return FinanceViewController.topSection()
            } else {
                let item = NSCollectionLayoutItem(layoutSize: .init(widthDimension: .fractionalWidth(1), heightDimension: .fractionalHeight(1/2)))
                item.contentInsets = .init(top: 0, leading: 16, bottom: 16, trailing: 16)
                
                let group = NSCollectionLayoutGroup.vertical(layoutSize: .init(widthDimension: .fractionalWidth(1), heightDimension: .absolute(120)), subitems: [item])
                
                let section = NSCollectionLayoutSection(group: group)
                
                let kind = UICollectionView.elementKindSectionHeader
                section.boundarySupplementaryItems = [
                    .init(layoutSize: .init(widthDimension: .fractionalWidth(0.92), heightDimension: .absolute(50)), elementKind: kind, alignment: .topLeading)
                ]
                return section
            }
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
        
        //        collectionView.register(CompositionalHeader.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: kCompositionalHeader)
        
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
        getMXUser { user in
            if let user = user {
                self.getMXMembers(guid: user.guid) { (members) in
                    for member in members {
                        dispatchGroup.enter()
                        if member.connection_status == "CONNECTED" && member.is_being_aggregated == false {
                            self.getMXAccounts(guid: user.guid, member_guid: member.guid) { (accounts) in
                                dispatchGroup.leave()
                                for account in accounts {
                                    if account.should_link ?? true {
                                        dispatchGroup.enter()
                                        self.getTransactionsAcct(guid: user.guid, account: account) { _ in
                                            dispatchGroup.leave()
                                        }
                                    }
                                }
                            }
                        } else {
                            dispatchGroup.leave()
                        }
                    }
                    dispatchGroup.notify(queue: .main) {
                        self.categorizeTransactions(transactionsAcctDict: self.transactionsAcctDict)
                    }
                }
            }
        }
    }
    
    func getMXUser(completion: @escaping (MXUser?) -> ()) {
        if let currentUser = Auth.auth().currentUser?.uid {
            let mxIDReference = Database.database().reference().child(usersFinancialEntity).child(currentUser)
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
                    if let currentUser = Auth.auth().currentUser?.uid {
                        let reference = Database.database().reference().child(financialAccountsEntity).child(currentUser).child(accounts![index].guid).child("should_link")
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
                if let currentUser = Auth.auth().currentUser?.uid {
                    let reference = Database.database().reference().child(financialAccountsEntity).child(currentUser).child(account!.guid).child("should_link")
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
    
    func getTransactionsAcct(guid: String, account: MXAccount, completion: @escaping ([Transaction]) -> ()) {
        Service.shared.getMXAccountTransactions(guid: guid, account_guid: account.guid, page: "1", records_per_page: "100", from_date: nil, to_date: nil) { (search, err) in
            if let transactions = search?.transactions {
                self.transactionsAcctDict[account] = transactions
                completion(transactions)
            } else if let transaction = search?.transaction {
                self.transactionsAcctDict[account] = [transaction]
                completion([transaction])
            }
        }
    }
    
    func categorizeTransactions(transactionsAcctDict: [MXAccount: [Transaction]]) {
        var categoryAmountDict = [String: Double]()
        var categoryTransactionsDict = [String: [Transaction]]()
        var topcategoryAmountDict = [String: Double]()
        var topcategoryTransactionsDict = [String: [Transaction]]()
        var groupAmountDict = [String: Double]()
        var groupTransactionsDict = [String: [Transaction]]()
        for (account, transactions) in transactionsAcctDict {
            for transaction in transactions {
                switch account.bs_type {
                case "Asset":
                    switch transaction.type {
                    case "DEBIT":
                        if categoryAmountDict[transaction.category.rawValue] == nil {
                            categoryAmountDict[transaction.category.rawValue] = -transaction.amount
                            
                            categoryTransactionsDict[transaction.category.rawValue] = [transaction]
                        } else {
                            var transactionAmount = categoryAmountDict[transaction.category.rawValue]
                            transactionAmount! -= transaction.amount
                            categoryAmountDict[transaction.category.rawValue] = transactionAmount
                            
                            var transactionList = categoryTransactionsDict[transaction.category.rawValue]
                            transactionList!.append(transaction)
                            categoryTransactionsDict[transaction.category.rawValue] = transactionList
                        }
                        
                        if topcategoryAmountDict[transaction.top_level_category.rawValue] == nil {
                            topcategoryAmountDict[transaction.top_level_category.rawValue] = -transaction.amount
                            
                            topcategoryTransactionsDict[transaction.top_level_category.rawValue] = [transaction]
                        } else {
                            var transactionAmount = topcategoryAmountDict[transaction.top_level_category.rawValue]
                            transactionAmount! -= transaction.amount
                            topcategoryAmountDict[transaction.top_level_category.rawValue] = transactionAmount
                            
                            var transactionList = topcategoryTransactionsDict[transaction.top_level_category.rawValue]
                            transactionList!.append(transaction)
                            topcategoryTransactionsDict[transaction.top_level_category.rawValue] = transactionList
                        }
                        
                        if groupAmountDict[transaction.group.rawValue] == nil {
                            groupAmountDict[transaction.group.rawValue] = -transaction.amount
                            
                            groupTransactionsDict[transaction.group.rawValue] = [transaction]
                        } else {
                            var transactionAmount = groupAmountDict[transaction.group.rawValue]
                            transactionAmount! -= transaction.amount
                            groupAmountDict[transaction.group.rawValue] = transactionAmount
                            
                            var transactionList = groupTransactionsDict[transaction.group.rawValue]
                            transactionList!.append(transaction)
                            groupTransactionsDict[transaction.group.rawValue] = transactionList
                        }
                    case "CREDIT":
                        if categoryAmountDict[transaction.category.rawValue] == nil {
                            categoryAmountDict[transaction.category.rawValue] = transaction.amount
                            
                            categoryTransactionsDict[transaction.category.rawValue] = [transaction]
                        } else {
                            var transactionAmount = categoryAmountDict[transaction.category.rawValue]
                            transactionAmount! += transaction.amount
                            categoryAmountDict[transaction.category.rawValue] = transactionAmount
                            
                            var transactionList = categoryTransactionsDict[transaction.category.rawValue]
                            transactionList!.append(transaction)
                            categoryTransactionsDict[transaction.category.rawValue] = transactionList
                        }
                        
                        if topcategoryAmountDict[transaction.top_level_category.rawValue] == nil {
                            topcategoryAmountDict[transaction.top_level_category.rawValue] = transaction.amount
                            
                            topcategoryTransactionsDict[transaction.top_level_category.rawValue] = [transaction]
                        } else {
                            var transactionAmount = topcategoryAmountDict[transaction.top_level_category.rawValue]
                            transactionAmount! += transaction.amount
                            topcategoryAmountDict[transaction.top_level_category.rawValue] = transactionAmount
                            
                            var transactionList = topcategoryTransactionsDict[transaction.top_level_category.rawValue]
                            transactionList!.append(transaction)
                            topcategoryTransactionsDict[transaction.top_level_category.rawValue] = transactionList
                        }
                        
                        if groupAmountDict[transaction.group.rawValue] == nil {
                            groupAmountDict[transaction.group.rawValue] = transaction.amount
                            
                            groupTransactionsDict[transaction.group.rawValue] = [transaction]
                        } else {
                            var transactionAmount = groupAmountDict[transaction.group.rawValue]
                            transactionAmount! += transaction.amount
                            groupAmountDict[transaction.group.rawValue] = transactionAmount
                            
                            var transactionList = groupTransactionsDict[transaction.group.rawValue]
                            transactionList!.append(transaction)
                            groupTransactionsDict[transaction.group.rawValue] = transactionList
                        }
                    default:
                        continue
                    }
                case "Liability":
                    switch transaction.type {
                    case "DEBIT":
                        if categoryAmountDict[transaction.category.rawValue] == nil {
                            categoryAmountDict[transaction.category.rawValue] = transaction.amount
                            
                            categoryTransactionsDict[transaction.category.rawValue] = [transaction]
                        } else {
                            var transactionAmount = categoryAmountDict[transaction.category.rawValue]
                            transactionAmount! += transaction.amount
                            categoryAmountDict[transaction.category.rawValue] = transactionAmount
                            
                            var transactionList = categoryTransactionsDict[transaction.category.rawValue]
                            transactionList!.append(transaction)
                            categoryTransactionsDict[transaction.category.rawValue] = transactionList
                        }
                        
                        if topcategoryAmountDict[transaction.top_level_category.rawValue] == nil {
                            topcategoryAmountDict[transaction.top_level_category.rawValue] = transaction.amount
                            
                            topcategoryTransactionsDict[transaction.top_level_category.rawValue] = [transaction]
                        } else {
                            var transactionAmount = topcategoryAmountDict[transaction.top_level_category.rawValue]
                            transactionAmount! += transaction.amount
                            topcategoryAmountDict[transaction.top_level_category.rawValue] = transactionAmount
                            
                            var transactionList = topcategoryTransactionsDict[transaction.top_level_category.rawValue]
                            transactionList!.append(transaction)
                            topcategoryTransactionsDict[transaction.top_level_category.rawValue] = transactionList
                        }
                        
                        if groupAmountDict[transaction.group.rawValue] == nil {
                            groupAmountDict[transaction.group.rawValue] = transaction.amount
                            
                            groupTransactionsDict[transaction.group.rawValue] = [transaction]
                        } else {
                            var transactionAmount = groupAmountDict[transaction.group.rawValue]
                            transactionAmount! += transaction.amount
                            groupAmountDict[transaction.group.rawValue] = transactionAmount
                            
                            var transactionList = groupTransactionsDict[transaction.group.rawValue]
                            transactionList!.append(transaction)
                            groupTransactionsDict[transaction.group.rawValue] = transactionList
                        }
                    case "CREDIT":
                        if categoryAmountDict[transaction.category.rawValue] == nil {
                            categoryAmountDict[transaction.category.rawValue] = -transaction.amount
                            
                            categoryTransactionsDict[transaction.category.rawValue] = [transaction]
                        } else {
                            var transactionAmount = categoryAmountDict[transaction.category.rawValue]
                            transactionAmount! -= transaction.amount
                            categoryAmountDict[transaction.category.rawValue] = transactionAmount
                            
                            var transactionList = categoryTransactionsDict[transaction.category.rawValue]
                            transactionList!.append(transaction)
                            categoryTransactionsDict[transaction.category.rawValue] = transactionList
                        }
                        
                        if topcategoryAmountDict[transaction.top_level_category.rawValue] == nil {
                            topcategoryAmountDict[transaction.top_level_category.rawValue] = -transaction.amount
                            
                            topcategoryTransactionsDict[transaction.top_level_category.rawValue] = [transaction]
                        } else {
                            var transactionAmount = topcategoryAmountDict[transaction.top_level_category.rawValue]
                            transactionAmount! -= transaction.amount
                            topcategoryAmountDict[transaction.top_level_category.rawValue] = transactionAmount
                            
                            var transactionList = topcategoryTransactionsDict[transaction.top_level_category.rawValue]
                            transactionList!.append(transaction)
                            topcategoryTransactionsDict[transaction.top_level_category.rawValue] = transactionList
                        }
                        
                        if groupAmountDict[transaction.group.rawValue] == nil {
                            groupAmountDict[transaction.group.rawValue] = -transaction.amount
                            
                            groupTransactionsDict[transaction.group.rawValue] = [transaction]
                        } else {
                            var transactionAmount = groupAmountDict[transaction.group.rawValue]
                            transactionAmount! -= transaction.amount
                            groupAmountDict[transaction.group.rawValue] = transactionAmount
                            
                            var transactionList = groupTransactionsDict[transaction.group.rawValue]
                            transactionList!.append(transaction)
                            groupTransactionsDict[transaction.group.rawValue] = transactionList
                        }
                    default:
                        continue
                    }
                default:
                    continue
                }
            }
        }
//        print("categoryAmountDict")
//        for (key, value) in categoryAmountDict {
//            print("key count \(categoryTransactionsDict[key]!.count)")
//            print("key \(key)")
//            print("value \(Int(value.round(to: 0)))")
//        }
//        print("topcategoryAmountDict")
//        for (key, value) in topcategoryAmountDict {
//            print("key count \(topcategoryTransactionsDict[key]!.count)")
//            print("key \(key)")
//            print("value \(Int(value.round(to: 0)))")
//        }
//        print("groupAmountDict")
//        for (key, value) in groupAmountDict {
//            print("key count \(groupTransactionsDict[key]!.count)")
//            print("key \(key)")
//            print("value \(Int(value.round(to: 0)))")
//        }
    }
    
    lazy var diffableDataSource: UICollectionViewDiffableDataSource<SectionType, AnyHashable> = .init(collectionView: self.collectionView) { (collectionView, indexPath, object) -> UICollectionViewCell? in
        //        if let object = object as? ActivityType {
        //            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: self.kActivityHeaderCell, for: indexPath) as! ActivityHeaderCell
        //            cell.intColor = (indexPath.item % 5)
        //            cell.activityType = object
        //            return cell
        //        }
        return nil
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let object = diffableDataSource.itemIdentifier(for: indexPath)
        let snapshot = self.diffableDataSource.snapshot()
        let section = snapshot.sectionIdentifier(containingItem: object!)
        if let recipe = object as? Recipe {
            //            destination.activityType = section?.image
            //            self.navigationController?.pushViewController(destination, animated: true)
        }
    }
    
    private func fetchData() {
        guard currentReachabilityStatus != .notReachable else {
            return
        }
        
        var snapshot = self.diffableDataSource.snapshot()
        snapshot.deleteAllItems()
        self.diffableDataSource.apply(snapshot)
        
        //        diffableDataSource.supplementaryViewProvider = .some({ (collectionView, kind, indexPath) -> UICollectionReusableView? in
        //            let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: self.kCompositionalHeader, for: indexPath) as! CompositionalHeader
        //            header.delegate = self
        //            let snapshot = self.diffableDataSource.snapshot()
        //            if let object = self.diffableDataSource.itemIdentifier(for: indexPath), let section = snapshot.sectionIdentifier(containingItem: object) {
        //                header.titleLabel.text = section.name
        //                if section == .custom {
        //                    header.subTitleLabel.isHidden = true
        //                } else {
        //                    header.subTitleLabel.isHidden = false
        //                }
        //            }
        //
        //            return header
        //        })
        
        activityIndicatorView.startAnimating()
        
        let dispatchGroup = DispatchGroup()
        
        for section in sections {
            if let object = groups[section] {
                snapshot.appendSections([section])
                snapshot.appendItems(object, toSection: section)
                self.diffableDataSource.apply(snapshot)
                continue
            }
            
            dispatchGroup.notify(queue: .main) {
                if let object = self.groups[section] {
                    activityIndicatorView.stopAnimating()
                    snapshot.appendSections([section])
                    snapshot.appendItems(object, toSection: section)
                    self.diffableDataSource.apply(snapshot)
                }
            }
        }
    }
    
}
