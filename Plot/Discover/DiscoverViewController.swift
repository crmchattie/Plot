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
import GoogleSignIn

protocol UpdateDiscover: AnyObject {
    func itemCreated()
}

class DiscoverViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout {
    
        
    fileprivate var reference: DatabaseReference!
    
    private let kCompositionalHeader = "CompositionalHeader"
    private let kActivityHeaderCell = "ActivityHeaderCell"
    
    var customTypes: [CustomType] = [.event, .task, .workout, .mindfulness, .transaction, .investment, .financialAccount, .transactionRule]
    var sections: [SectionType] = [.event, .task, .customWorkout, .mindfulness, .customTransaction, .investment, .customFinancialAccount, .customTransactionRule]
    var groups = [SectionType: [AnyHashable]]()
    
    var intColor: Int = 0
    
    let navigationItemActivityIndicator = NavigationItemActivityIndicator()
    
    var networkController = NetworkController()
    
    init() {
        
        let layout = UICollectionViewCompositionalLayout { (_, _) -> NSCollectionLayoutSection? in
            
            let item = NSCollectionLayoutItem(layoutSize: .init(widthDimension: .fractionalWidth(1), heightDimension: .fractionalHeight(1)))
            item.contentInsets.bottom = 0
            
            let group = NSCollectionLayoutGroup.vertical(layoutSize: .init(widthDimension: .fractionalWidth(1), heightDimension: .absolute(60)), subitems: [item])
            group.contentInsets.trailing = 30
            
            let section = NSCollectionLayoutSection(group: group)
            section.orthogonalScrollingBehavior = .groupPaging
            section.contentInsets.leading = 15
            return section
        }
        
        super.init(collectionViewLayout: layout)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Discover"
        navigationController?.navigationBar.layoutIfNeeded()
        
        extendedLayoutIncludesOpaqueBars = true
        definesPresentationContext = true
        edgesForExtendedLayout = .top
        view.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
        
        collectionView.indicatorStyle = ThemeManager.currentTheme().scrollBarStyle
        collectionView.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
        
        collectionView.register(CompositionalHeader.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: kCompositionalHeader)
        collectionView.register(ActivityHeaderCell.self, forCellWithReuseIdentifier: kActivityHeaderCell)
        
//        let cancelBarButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancel))
//        navigationItem.leftBarButtonItem = cancelBarButton
        
        let doneBarButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(done))
        navigationItem.rightBarButtonItem = doneBarButton
        

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
    
    @IBAction func done(_ sender: AnyObject) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func cancel(_ sender: AnyObject) {
        self.dismiss(animated: true, completion: nil)
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
        UIWindow(frame: UIScreen.main.bounds).backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
        view.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
        navigationController?.navigationBar.barStyle = ThemeManager.currentTheme().barStyle
        navigationController?.navigationBar.barTintColor = ThemeManager.currentTheme().barBackgroundColor
        let textAttributes = [NSAttributedString.Key.foregroundColor: ThemeManager.currentTheme().generalTitleColor]
        navigationController?.navigationBar.titleTextAttributes = textAttributes
        navigationController?.navigationBar.largeTitleTextAttributes = textAttributes
        navigationController?.navigationBar.backgroundColor = ThemeManager.currentTheme().barBackgroundColor
        
        collectionView.indicatorStyle = ThemeManager.currentTheme().scrollBarStyle
        collectionView.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
        collectionView.reloadData()
        
    }
    
    @objc func updateSections() {
        if !networkController.activityService.calendars.keys.contains(CalendarSourceOptions.apple.name) && !networkController.activityService.calendars.keys.contains(CalendarSourceOptions.google.name) {
            customTypes.removeAll(where: {$0 == .calendar})
            sections.removeAll(where: {$0 == .calendar})
            fetchData()
        } else if !sections.contains(.calendar) {
            customTypes.insert(.calendar, at: 1)
            sections.insert(.calendar, at: 1)
            fetchData()
        }
        if !networkController.activityService.lists.keys.contains(ListSourceOptions.apple.name) && !networkController.activityService.lists.keys.contains(ListSourceOptions.google.name) {
            customTypes.removeAll(where: {$0 == .lists})
            sections.removeAll(where: {$0 == .lists})
            fetchData()
        } else if !sections.contains(.lists) {
            customTypes.insert(.lists, at: 1)
            sections.insert(.lists, at: 1)
            fetchData()
        }
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return ThemeManager.currentTheme().statusBarStyle
    }
    
    lazy var diffableDataSource: UICollectionViewDiffableDataSource<SectionType, AnyHashable> = .init(collectionView: self.collectionView) { (collectionView, indexPath, object) -> UICollectionViewCell? in
        if let object = object as? CustomType {
            let totalSections = self.groups.count - 1
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: self.kActivityHeaderCell, for: indexPath) as! ActivityHeaderCell
            cell.intColor = (indexPath.section % 5)
            if indexPath.section == 0 {
                cell.firstPosition = true
            }
            if indexPath.section == totalSections {
                cell.lastPosition = true
            }
            cell.activityType = object
            return cell
        }
        return nil
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let object = diffableDataSource.itemIdentifier(for: indexPath)
        if let activityType = object as? CustomType {
            switch activityType {
            case .event:
                let destination = EventViewController(networkController: networkController)
                destination.updateDiscoverDelegate = self
                self.navigationController?.pushViewController(destination, animated: true)
            case .task:
                let destination = TaskViewController(networkController: networkController)
                destination.updateDiscoverDelegate = self
                self.navigationController?.pushViewController(destination, animated: true)
            case .flight:
                print("flight")
            case .meal:
                let destination = MealViewController(networkController: self.networkController)
                destination.updateDiscoverDelegate = self
                self.navigationController?.pushViewController(destination, animated: true)
            case .workout:
                let destination = WorkoutViewController(networkController: self.networkController)
                destination.updateDiscoverDelegate = self
                self.navigationController?.pushViewController(destination, animated: true)
            case .mindfulness:
                let destination = MindfulnessViewController(networkController: self.networkController)
                destination.updateDiscoverDelegate = self
                self.navigationController?.pushViewController(destination, animated: true)
            case .mood:
                let destination = MoodViewController()
                self.navigationController?.pushViewController(destination, animated: true)
            case .sleep:
                let destination = SchedulerViewController()
                destination.type = activityType
                self.navigationController?.pushViewController(destination, animated: true)
            case .work:
                let destination = SchedulerViewController()
                destination.type = activityType
                self.navigationController?.pushViewController(destination, animated: true)
            case .transaction:
                let destination = FinanceTransactionViewController(networkController: self.networkController)
                destination.updateDiscoverDelegate = self
                self.navigationController?.pushViewController(destination, animated: true)
            case .investment:
                let destination = FinanceHoldingViewController(networkController: self.networkController)
                destination.updateDiscoverDelegate = self
                self.navigationController?.pushViewController(destination, animated: true)
            case .financialAccount:
                self.newAccount()
            case .transactionRule:
                let destination = FinanceTransactionRuleViewController(networkController: self.networkController)
                destination.updateDiscoverDelegate = self
                self.navigationController?.pushViewController(destination, animated: true)
            default:
                print("default")
            }
        } else {
            print("neither meals or events")
        }
    }
    
    private func fetchData() {        
        var snapshot = self.diffableDataSource.snapshot()
        snapshot.deleteAllItems()
        self.diffableDataSource.apply(snapshot)
                        
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
    
    @objc func newAccount() {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "Connect To Account", style: .default, handler: { (_) in
            self.openMXConnect(current_member_guid: nil)
        }))
        
        alert.addAction(UIAlertAction(title: "Manually Add Account", style: .default, handler: { (_) in
            let destination = FinanceAccountViewController(networkController: self.networkController)
            destination.updateDiscoverDelegate = self
            self.navigationController?.pushViewController(destination, animated: true)
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (_) in
            print("User click Dismiss button")
        }))
        
        self.present(alert, animated: true, completion: {
            print("completion block")
        })
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
        case "Event":
            let destination = ActivityTypeViewController()
            destination.hidesBottomBarWhenPushed = true
            destination.users = networkController.userService.users
            destination.filteredUsers = networkController.userService.users
            navigationController?.pushViewController(destination, animated: true)
        default:
            print("Default")
        }
    }
}

extension DiscoverViewController: EndedWebViewDelegate {
    func updateMXMembers() {
        networkController.financeService.triggerUpdateMXUser()
    }
}

extension DiscoverViewController: GIDSignInDelegate {
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        if (error == nil) {
            self.networkController.activityService.updatePrimaryCalendar(value: CalendarSourceOptions.google.name)
            self.networkController.activityService.updatePrimaryList(value: ListSourceOptions.google.name)
        } else {
          print("\(error.localizedDescription)")
        }
    }
}

extension DiscoverViewController: UpdateDiscover {
    func itemCreated() {
        self.dismiss(animated: true)
    }
}

