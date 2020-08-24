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
    
    var mxUser: MXUser!
    var mxMembers = [MXMember]()
    var mxAccountsDict = [String: [MXAccount]]()
    var transactionsDict = [String: [Transaction]]()
    
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
                
        grabMXUser()
        
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
    
    func grabMXUser() {
        if let currentUser = Auth.auth().currentUser?.uid {
            let mxIDReference = Database.database().reference().child(usersFinancialEntity).child(currentUser)
            mxIDReference.observe(.value, with: { (snapshot) in
                if snapshot.exists(), let value = snapshot.value {
                    if let user = try? FirebaseDecoder().decode(MXUser.self, from: value) {
                        self.mxUser = user
                        self.grabMXMembers(guid: user.guid)
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
                            self.mxUser = user
                            self.grabMXMembers(guid: user!.guid)
                        }
                    }
                }
            })
        }
    }
    
    func grabMXMembers(guid: String) {
        let dispatchGroup = DispatchGroup()
        dispatchGroup.enter()
        Service.shared.getMXMembers(guid: guid) { (search, err) in
            if let members = search?.members {
                self.mxMembers = members
                dispatchGroup.leave()
            } else if let member = search?.member {
                self.mxMembers = [member]
                dispatchGroup.leave()
            } else {
                dispatchGroup.leave()
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            for member in self.mxMembers {
                if member.connection_status == "CONNECTED" && member.is_being_aggregated == false {
                    self.grabMXAccounts(guid: guid, member_guid: member.guid)
                }
            }
        }
    }
    
    func grabMXAccounts(guid: String, member_guid: String) {
        let dispatchGroup = DispatchGroup()
        dispatchGroup.enter()
        Service.shared.getMXMemberAccounts(guid: guid, member_guid: member_guid) { (search, err) in
            if let accounts = search?.accounts {
                self.mxAccountsDict[member_guid] = accounts
                dispatchGroup.leave()
            } else if let account = search?.account {
                self.mxAccountsDict[member_guid] = [account]
                dispatchGroup.leave()
            } else {
                dispatchGroup.leave()
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            for (_, values) in self.mxAccountsDict {
                for value in values {
                    if self.transactionsDict[value.guid] == nil {
                        self.grabTransactions(guid: guid, account_guid: value.guid)
                    }
                }
            }
        }
    }
    
    func grabTransactions(guid: String, account_guid: String) {
        let dispatchGroup = DispatchGroup()
        dispatchGroup.enter()
        Service.shared.getMXAccountTransactions(guid: guid, account_guid: account_guid, from_date: nil, to_date: nil) { (search, err) in
            if let transactions = search?.transactions {
                self.transactionsDict[account_guid] = transactions
                dispatchGroup.leave()
            } else if let transaction = search?.transaction {
                self.transactionsDict[account_guid] = [transaction]
                dispatchGroup.leave()
            } else {
                dispatchGroup.leave()
            }
        }
    }
    
    func categorizeTransactions() {
        
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
