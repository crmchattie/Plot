//
//  DiscoverViewController.swift
//  Plot
//
//  Created by Hafiz Usama on 2019-11-11.
//  Copyright © 2019 Immature Creations. All rights reserved.
//

import UIKit
import MapKit
import Firebase
import CodableFirebase
import SwiftUI

class DiscoverViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout {
        
    fileprivate var reference: DatabaseReference!
    
    private let kCompositionalHeader = "CompositionalHeader"
    private let kActivityHeaderCell = "ActivityHeaderCell"
    
    var customTypes: [CustomType] = [.basic, .meal, .workout, .mood, .mindfulness, .sleep, .work, .transaction, .financialAccount]
    var sections: [SectionType] = [.activity, .customMeal, .customWorkout, .mood, .mindfulness, .sleep, .work, .customTransaction, .customFinancialAccount]
    var groups = [SectionType: [AnyHashable]]()
    
    var intColor: Int = 0
        
    var users = [User]()
    var filteredUsers = [User]()
    var selectedFalconUsers = [User]()
    var activities = [Activity]()
    var conversations = [Conversation]()
    var conversation: Conversation?
    var listList = [ListContainer]()
    var mxUser: MXUser!
        
    let navigationItemActivityIndicator = NavigationItemActivityIndicator()
    
    init() {
        
        let layout = UICollectionViewCompositionalLayout { (_, _) -> NSCollectionLayoutSection? in
            
            let item = NSCollectionLayoutItem(layoutSize: .init(widthDimension: .fractionalWidth(1), heightDimension: .fractionalHeight(1)))
            item.contentInsets.bottom = 16
            
            let group = NSCollectionLayoutGroup.vertical(layoutSize: .init(widthDimension: .fractionalWidth(1), heightDimension: .absolute(60)), subitems: [item])
            group.contentInsets.trailing = 32
            
            let section = NSCollectionLayoutSection(group: group)
            section.orthogonalScrollingBehavior = .groupPaging
            section.contentInsets.leading = 16
            
//            let kind = UICollectionView.elementKindSectionHeader
//            section.boundarySupplementaryItems = [
//                .init(layoutSize: .init(widthDimension: .fractionalWidth(0.92), heightDimension: .absolute(30)), elementKind: kind, alignment: .topLeading)
//            ]
            
            return section
        }
        
        super.init(collectionViewLayout: layout)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.largeTitleDisplayMode = .always
        navigationController?.navigationBar.prefersLargeTitles = true
        
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for:.default)
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.navigationBar.layoutIfNeeded()
                
        tabBarController?.tabBar.barTintColor = ThemeManager.currentTheme().barBackgroundColor
        tabBarController?.tabBar.barStyle = ThemeManager.currentTheme().barStyle
        
        extendedLayoutIncludesOpaqueBars = true
        definesPresentationContext = true
        edgesForExtendedLayout = UIRectEdge.top
        view.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
        
        collectionView.indicatorStyle = ThemeManager.currentTheme().scrollBarStyle
        collectionView.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
        
        collectionView.register(CompositionalHeader.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: kCompositionalHeader)
        collectionView.register(ActivityHeaderCell.self, forCellWithReuseIdentifier: kActivityHeaderCell)
                
        addObservers()
        
        for index in 0...sections.count - 1 {
            groups[sections[index]] = [customTypes[index]]
        }
                
        fetchData()
        
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        managePresense()
    }
    
    fileprivate func managePresense() {
        if currentReachabilityStatus == .notReachable {
            navigationItemActivityIndicator.showActivityIndicator(for: navigationItem, with: .connecting,
                                                                  activityPriority: .high,
                                                                  color: ThemeManager.currentTheme().generalTitleColor)
        }
        
        let connectedReference = Database.database().reference(withPath: ".info/connected")
        connectedReference.observe(.value, with: { (snapshot) in
            
            if self.currentReachabilityStatus != .notReachable {
                self.navigationItemActivityIndicator.hideActivityIndicator(for: self.navigationItem, activityPriority: .crazy)
            } else {
                self.navigationItemActivityIndicator.showActivityIndicator(for: self.navigationItem, with: .noInternet, activityPriority: .crazy, color: ThemeManager.currentTheme().generalTitleColor)
            }
        })
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
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return ThemeManager.currentTheme().statusBarStyle
    }
    
    lazy var diffableDataSource: UICollectionViewDiffableDataSource<SectionType, AnyHashable> = .init(collectionView: self.collectionView) { (collectionView, indexPath, object) -> UICollectionViewCell? in
        if let object = object as? CustomType {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: self.kActivityHeaderCell, for: indexPath) as! ActivityHeaderCell
            cell.intColor = (indexPath.section % 5)
            cell.activityType = object
            return cell
        }
        return nil
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let object = diffableDataSource.itemIdentifier(for: indexPath)
        if let activityType = object as? CustomType {
            switch activityType {
            case .basic:
                let destination = CreateActivityViewController()
                destination.hidesBottomBarWhenPushed = true
                destination.users = self.users
                destination.filteredUsers = self.filteredUsers
                destination.conversations = self.conversations
                self.navigationController?.pushViewController(destination, animated: true)
            case .flight:
                let destination = FlightSearchViewController()
                destination.hidesBottomBarWhenPushed = true
                destination.users = self.users
                destination.filteredUsers = self.filteredUsers
                destination.conversations = self.conversations
                self.navigationController?.pushViewController(destination, animated: true)
            case .meal:
                let destination = MealViewController()
                destination.hidesBottomBarWhenPushed = true
                destination.users = self.users
                destination.filteredUsers = self.filteredUsers
                self.navigationController?.pushViewController(destination, animated: true)
            case .workout:
                let destination = WorkoutViewController()
                destination.hidesBottomBarWhenPushed = true
                destination.users = self.users
                destination.filteredUsers = self.filteredUsers
                self.navigationController?.pushViewController(destination, animated: true)
            case .mindfulness:
                let destination = MindfulnessViewController()
                destination.hidesBottomBarWhenPushed = true
                destination.users = self.users
                destination.filteredUsers = self.filteredUsers
                self.navigationController?.pushViewController(destination, animated: true)
            case .mood:
                let destination = MoodViewController()
                destination.hidesBottomBarWhenPushed = true
                self.navigationController?.pushViewController(destination, animated: true)
            case .sleep:
                let destination = SchedulerViewController()
                destination.hidesBottomBarWhenPushed = true
                destination.type = activityType
                self.navigationController?.pushViewController(destination, animated: true)
            case .work:
                let destination = SchedulerViewController()
                destination.hidesBottomBarWhenPushed = true
                destination.type = activityType
                self.navigationController?.pushViewController(destination, animated: true)
            case .transaction:
                let destination = FinanceTransactionViewController()
                destination.hidesBottomBarWhenPushed = true
                destination.users = self.users
                destination.filteredUsers = self.filteredUsers
                self.navigationController?.pushViewController(destination, animated: true)
            case .financialAccount:
                if let user = self.mxUser {
                    let accountAlertController = UIAlertController(title: "New Account", message: nil, preferredStyle: .actionSheet)
                    let custom = UIAlertAction(title: "Manual Entry", style: .default) { (action:UIAlertAction) in
                        let destination = FinanceAccountViewController()
                        destination.hidesBottomBarWhenPushed = true
                        destination.users = self.users
                        destination.filteredUsers = self.filteredUsers
                        self.navigationController?.pushViewController(destination, animated: true)
                    }
                    let automatic = UIAlertAction(title: "Automatic Entry", style: .default) { (action:UIAlertAction) in
                        self.openMXConnect(guid: user.guid, current_member_guid: nil)
                    }
                    let cancelAlert = UIAlertAction(title: "Cancel", style: .cancel) { (action:UIAlertAction) in
                        print("You've pressed cancel")
                    }
                    accountAlertController.addAction(custom)
                    accountAlertController.addAction(automatic)
                    accountAlertController.addAction(cancelAlert)
                    self.present(accountAlertController, animated: true, completion: nil)
                    
                }
            case .transactionRule:
                if let user = self.mxUser {
                    let destination = FinanceTransactionRuleViewController()
                    destination.hidesBottomBarWhenPushed = true
                    destination.user = user
                    let navigationViewController = UINavigationController(rootViewController: destination)
                    self.present(navigationViewController, animated: true, completion: nil)
                }
            default:
                print("default")
            }
        } else {
            print("neither meals or events")
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
//                header.subTitleLabel.isHidden = true
//            }
//            
//            return header
//        })
                        
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
                    snapshot.appendSections([section])
                    snapshot.appendItems(object, toSection: section)
                    self.diffableDataSource.apply(snapshot)
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
    
    func getSelectedFalconUsers(forActivity activity: Activity, completion: @escaping ([User])->()) {
        guard let participantsIDs = activity.participantsIDs, let currentUserID = Auth.auth().currentUser?.uid else {
            return
        }
        var selectedFalconUsers = [User]()
        let group = DispatchGroup()
        for id in participantsIDs {
            // Only if the current user is created this activity
            if activity.admin == currentUserID && id == currentUserID {
                continue
            }
            
            group.enter()
            let participantReference = Database.database().reference().child("users").child(id)
            participantReference.observeSingleEvent(of: .value, with: { (snapshot) in
                if snapshot.exists(), var dictionary = snapshot.value as? [String: AnyObject] {
                    dictionary.updateValue(snapshot.key as AnyObject, forKey: "id")
                    let user = User(dictionary: dictionary)
                    selectedFalconUsers.append(user)
                }
                group.leave()
            })
        }
        
        group.notify(queue: .main) {
            completion(selectedFalconUsers)
        }
    }
    
}

extension DiscoverViewController: CompositionalHeaderDelegate {
    func viewTapped(labelText: String) {
        switch labelText {
        case "Activity":
            let destination = ActivityTypeViewController()
            destination.hidesBottomBarWhenPushed = true
            destination.users = users
            destination.filteredUsers = filteredUsers
            destination.conversations = conversations
            destination.activities = activities
            destination.conversation = conversation
            destination.listList = listList
            navigationController?.pushViewController(destination, animated: true)
        default:
            print("Default")
        }
    }
}

extension DiscoverViewController: EndedWebViewDelegate {
    func updateMXMembers() {
        if let nav = self.tabBarController, let containerVC = nav.viewControllers![1] as? UINavigationController {
            if containerVC.topViewController is MasterActivityContainerController, let containerTab = containerVC.topViewController as? MasterActivityContainerController {
                containerTab.financeVC.getMXData()
            }
        }
    }
}
