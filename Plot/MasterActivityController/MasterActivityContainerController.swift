//
//  MasterActivityController.swift
//  Plot
//
//  Created by Cory McHattie on 4/21/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import UIKit
import Contacts
import Firebase
import LBTATools

fileprivate let activitiesControllerCell = "ActivitiesControllerCell"
fileprivate let healthControllerCell = "HealthControllerCell"
fileprivate let financeControllerCell = "FinanceControllerCell"
fileprivate let hostedViewCell = "HostedViewCell"
fileprivate let headerContainerCell = "HeaderContainerCell"


enum Mode {
    case small, fullscreen
}

protocol ManageAppearanceHome: class {
    func manageAppearanceHome(_ homeController: MasterActivityContainerController, didFinishLoadingWith state: Bool )
}

protocol MasterContainerActivityIndicatorDelegate: class {
    func showActivityIndicator()
    func hideActivityIndicator()
}

class MasterActivityContainerController: UIViewController {
    
    let collectionView:UICollectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout: UICollectionViewFlowLayout.init())
    let layout:UICollectionViewFlowLayout = UICollectionViewFlowLayout.init()
    
    var contacts = [CNContact]()
    var filteredContacts = [CNContact]()
    var users = [User]() {
        didSet {
            activitiesVC.users = users
            chatsVC.users = users
            listsVC.users = users
            financeVC.users = users
        }
    }
    var filteredUsers = [User]() {
        didSet {
            activitiesVC.filteredUsers = filteredUsers
            chatsVC.filteredUsers = filteredUsers
            listsVC.filteredUsers = filteredUsers
            financeVC.filteredUsers = filteredUsers
        }
    }
    var conversations = [Conversation]() {
        didSet {
            configureTabBarBadge()
            activitiesVC.conversations = conversations
            listsVC.conversations = conversations
            
            if let nav = self.tabBarController, let actTypeVC = nav.viewControllers![0] as? UINavigationController, let settingsVC = nav.viewControllers![2] as? UINavigationController {
                if actTypeVC.topViewController is DiscoverViewController, let activityTab = actTypeVC.topViewController as? DiscoverViewController {
                    activityTab.conversations = conversations
                }
                if settingsVC.topViewController is AccountSettingsController, let settingsTab = settingsVC.topViewController as? AccountSettingsController {
                    settingsTab.conversations = conversations
                }
            }
        }
    }
    var activities = [Activity]() {
        didSet {
            configureTabBarBadge()
            listsVC.activities = activities
            listsVC.activityViewController = activitiesVC
            
            if let nav = self.tabBarController, let actTypeVC = nav.viewControllers![0] as? UINavigationController, let settingsVC = nav.viewControllers![2] as? UINavigationController {
                if actTypeVC.topViewController is DiscoverViewController, let activityTab = actTypeVC.topViewController as? DiscoverViewController {
                    activityTab.activities = activities
                }
                if settingsVC.topViewController is AccountSettingsController, let settingsTab = settingsVC.topViewController as? AccountSettingsController {
                    settingsTab.activities = activities
                }
            }
        }
    }
    var invitations: [String: Invitation] = [:] {
        didSet {
            if let nav = self.tabBarController, let settingsVC = nav.viewControllers![2] as? UINavigationController {
                if settingsVC.topViewController is AccountSettingsController, let settingsTab = settingsVC.topViewController as? AccountSettingsController {
                    settingsTab.invitations = invitations
                }
            }
        }
    }
    var invitedActivities = [Activity]() {
        didSet {
            if let nav = self.tabBarController, let settingsVC = nav.viewControllers![2] as? UINavigationController {
                if settingsVC.topViewController is AccountSettingsController, let settingsTab = settingsVC.topViewController as? AccountSettingsController {
                    settingsTab.invitedActivities = invitedActivities
                }
            }
        }
    }
    var listList = [ListContainer]() {
        didSet {
            configureTabBarBadge()
            if let nav = self.tabBarController, let actTypeVC = nav.viewControllers![0] as? UINavigationController, let settingsVC = nav.viewControllers![2] as? UINavigationController {
                if actTypeVC.topViewController is DiscoverViewController, let activityTab = actTypeVC.topViewController as? DiscoverViewController {
                    activityTab.listList = listList
                }
                if settingsVC.topViewController is AccountSettingsController, let settingsTab = settingsVC.topViewController as? AccountSettingsController {
                    settingsTab.listList = listList
                }
            }
        }
    }
    var mxUser: MXUser! {
        didSet {
            if let nav = self.tabBarController, let actTypeVC = nav.viewControllers![0] as? UINavigationController {
                if actTypeVC.topViewController is DiscoverViewController, let activityTab = actTypeVC.topViewController as? DiscoverViewController {
                    activityTab.mxUser = mxUser
                }
            }
        }
    }
    
    var transactions: [Transaction]!
    
    var selectedDate = Date()
    
    let navigationItemActivityIndicator = NavigationItemActivityIndicator()
        
    weak var delegate: ManageAppearanceHome?
        
    var viewControllers = [UIViewController]()
    
    lazy var activitiesVC: ActivityViewController = {
        let vc = ActivityViewController(mode: .small)
        return vc
    }()
    
    lazy var chatsVC: ChatsTableViewController = {
        let vc = ChatsTableViewController()
        return vc
    }()
    
    lazy var listsVC: ListsViewController = {
        let vc = ListsViewController()
        return vc
    }()
    
    lazy var financeVC: FinanceViewController = {
        let vc = FinanceViewController(mode: .small)
        return vc
    }()
    
    lazy var healthVC: HealthViewController = {
        let vc = HealthViewController(mode: .small)
        return vc
    }()
    
    var sections: [SectionType] = [.calendar, .health, .finances]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        viewControllers = [activitiesVC, healthVC, financeVC]

        activitiesVC.delegate = self
        activitiesVC.activityIndicatorDelegate = self
        financeVC.delegate = self
        listsVC.delegate = self
        chatsVC.delegate = self
        setupViews()
        setNavBar()
        addObservers()
                
        delegate?.manageAppearanceHome(self, didFinishLoadingWith: true)
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: false)
        managePresense()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: false)
    }
    
    func addAsChildVC(childVC: UIViewController) {
        addChild(childVC)
        childVC.view.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        childVC.didMove(toParent: self)
    }

    func setupViews() {
        navigationItem.largeTitleDisplayMode = .always
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for:.default)
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.navigationBar.layoutIfNeeded()
        navigationController?.navigationBar.barStyle = ThemeManager.currentTheme().barStyle
        navigationController?.navigationBar.barTintColor = ThemeManager.currentTheme().barBackgroundColor
        let textAttributes = [NSAttributedString.Key.foregroundColor: ThemeManager.currentTheme().generalTitleColor]
        navigationController?.navigationBar.titleTextAttributes = textAttributes
        navigationController?.navigationBar.largeTitleTextAttributes = textAttributes
        navigationController?.navigationBar.backgroundColor = ThemeManager.currentTheme().barBackgroundColor
        
        tabBarController?.tabBar.barTintColor = ThemeManager.currentTheme().barBackgroundColor
        tabBarController?.tabBar.barStyle = ThemeManager.currentTheme().barStyle
        
        view.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
        collectionView.indicatorStyle = ThemeManager.currentTheme().scrollBarStyle
        collectionView.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
        
        layout.scrollDirection = UICollectionView.ScrollDirection.vertical
        collectionView.setCollectionViewLayout(layout, animated: true)
        collectionView.dataSource = self
        collectionView.delegate = self
        
        view.addSubview(collectionView)
        collectionView.fillSuperview()
        
        collectionView.register(ActivitiesControllerCell.self, forCellWithReuseIdentifier: activitiesControllerCell)
        collectionView.register(HealthControllerCell.self, forCellWithReuseIdentifier: healthControllerCell)
        collectionView.register(FinanceControllerCell.self, forCellWithReuseIdentifier: financeControllerCell)
        collectionView.register(HostedViewCell.self, forCellWithReuseIdentifier: hostedViewCell)
        collectionView.register(HeaderContainerCell.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: headerContainerCell)
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return ThemeManager.currentTheme().statusBarStyle
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    fileprivate func addObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(changeTheme), name: .themeUpdated, object: nil)
    }
    
    @objc fileprivate func changeTheme() {
        let theme = ThemeManager.currentTheme()
        view.backgroundColor = theme.generalBackgroundColor
        
        navigationController?.navigationBar.barStyle = theme.barStyle
        navigationController?.navigationBar.barTintColor = theme.barBackgroundColor
        let textAttributes = [NSAttributedString.Key.foregroundColor: theme.generalTitleColor]
        navigationController?.navigationBar.titleTextAttributes = textAttributes
        navigationController?.navigationBar.largeTitleTextAttributes = textAttributes
        navigationController?.navigationBar.backgroundColor = theme.barBackgroundColor
        
        tabBarController?.tabBar.barTintColor = theme.barBackgroundColor
        tabBarController?.tabBar.barStyle = theme.barStyle
        
        collectionView.indicatorStyle = theme.scrollBarStyle
        collectionView.backgroundColor = theme.generalBackgroundColor
        collectionView.reloadData()
        
    }
    
    func setNavBar() {
        let newItemBarButton =  UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(newItem))
        navigationItem.leftBarButtonItems = nil
        navigationItem.rightBarButtonItem = newItemBarButton
        
    }
    
    func configureTabBarBadge() {
        guard let tabItems = tabBarController?.tabBar.items as NSArray? else { return }
        guard let tabItem = tabItems[Tabs.home.rawValue] as? UITabBarItem else { return }
        guard !listList.isEmpty, !activities.isEmpty, !conversations.isEmpty, let uid = Auth.auth().currentUser?.uid else { return }
        var badge = 0
        
        for activity in activities {
            guard let activityBadge = activity.badge else { continue }
            badge += activityBadge
        }
        
        for conversation in conversations {
            guard let lastMessage = conversation.lastMessage, let conversationBadge = conversation.badge, lastMessage.fromId != uid  else { continue }
            badge += conversationBadge
        }
        
        for list in listList {
            badge += list.badge
        }
        
        guard badge > 0 else {
            tabItem.badgeValue = nil
            setApplicationBadge()
            return
        }
        tabItem.badgeValue = badge.toString()
        setApplicationBadge()
    }
    
    func setApplicationBadge() {
        guard let tabItems = tabBarController?.tabBar.items as NSArray? else { return }
        var badge = 0
        
        for tab in 0...tabItems.count - 1 {
            guard let tabItem = tabItems[tab] as? UITabBarItem else { return }
            if let tabBadge = tabItem.badgeValue?.toInt() {
                badge += tabBadge
            }
        }
        UIApplication.shared.applicationIconBadgeNumber = badge
        if let uid = Auth.auth().currentUser?.uid {
            let ref = Database.database().reference().child("users").child(uid)
            ref.updateChildValues(["badge": badge])
        }
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
}

extension MasterActivityContainerController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UIGestureRecognizerDelegate {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return sections.count
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: hostedViewCell, for: indexPath) as! HostedViewCell
        cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
//        let VC = viewControllers[indexPath.section]
//        cell.hostedView = VC.view
        return cell
    }
    
    static let cellSize: CGFloat = 500
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return .init(width: view.frame.width - 40, height: MasterActivityContainerController.cellSize)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return .init(top: 15, left: 0, bottom: 15, right: 0)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: view.frame.width, height: 30)
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionView.elementKindSectionHeader {
            let sectionHeader = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: headerContainerCell, for: indexPath) as! HeaderContainerCell
            let section = sections[indexPath.section]
            sectionHeader.titleLabel.text = section.name
            return sectionHeader
        } else { //No footer in this case but can add option for that
            return UICollectionReusableView()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        showDailyListFullScreen(indexPath: indexPath)
    }
    
    fileprivate func showDailyListFullScreen(indexPath: IndexPath) {
        let section = sections[indexPath.section]
        if section == .calendar {
            activitiesVC.mode = .fullscreen
//            let fullController = ActivityViewController(mode: .fullscreen)
            let backEnabledNavigationController = BackEnabledNavigationController(rootViewController: activitiesVC)
            backEnabledNavigationController.modalPresentationStyle = .fullScreen
            present(backEnabledNavigationController, animated: true)
        } else if section == .health {
            healthVC.mode = .fullscreen
//            let fullController = HealthViewController(mode: .fullscreen)
            let backEnabledNavigationController = BackEnabledNavigationController(rootViewController: healthVC)
            backEnabledNavigationController.modalPresentationStyle = .fullScreen
            present(backEnabledNavigationController, animated: true)
        } else {
            financeVC.mode = .fullscreen
//            financeVC.collectionView.reloadData()
//            let fullController = FinanceViewController(mode: .fullscreen)
            let backEnabledNavigationController = BackEnabledNavigationController(rootViewController: financeVC)
            backEnabledNavigationController.modalPresentationStyle = .fullScreen
            present(backEnabledNavigationController, animated: true)
        }
    }
}

extension MasterActivityContainerController {
    @objc fileprivate func newItem() {
        tabBarController?.selectedIndex = 0
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
}

extension MasterActivityContainerController: HomeBaseActivities {
    func manageAppearanceActivity(_ activityController: ActivityViewController, didFinishLoadingWith state: Bool) {
//        delegate?.manageAppearanceHome(self, didFinishLoadingWith: true)
    }
    
    func sendActivities(activities: [Activity], invitedActivities: [Activity], invitations: [String : Invitation]) {
        self.activities = activities
        self.invitedActivities = invitedActivities
        self.invitations = invitations
    }
    
    
    func sendDate(selectedDate: Date) {
        self.selectedDate = selectedDate
        setNavBar()
    }
}

extension MasterActivityContainerController: HomeBaseChats {
    func sendChats(conversations: [Conversation]) {
        self.conversations = conversations
    }
}

extension MasterActivityContainerController: HomeBaseLists {
    func sendLists(lists: [ListContainer]) {
        self.listList = lists
    }
}

extension MasterActivityContainerController: HomeBaseFinance {
    func sendUser(user: MXUser) {
        self.mxUser = user
    }
    func sendTransactions(transactions: [Transaction]) {
        self.transactions = transactions
    }
    func sendAccounts(accounts: [MXAccount]) {
        
    }
}

extension MasterActivityContainerController: EndedWebViewDelegate {
    func updateMXMembers() {
        financeVC.getMXData()
    }
}

extension MasterActivityContainerController: MasterContainerActivityIndicatorDelegate {
    func showActivityIndicator() {
        navigationItemActivityIndicator.showActivityIndicator(for: navigationItem, with: .updating,
                                                              activityPriority: .medium,
                                                              color: ThemeManager.currentTheme().generalTitleColor)
    }
    
    func hideActivityIndicator() {
        self.navigationItemActivityIndicator.hideActivityIndicator(for: self.navigationItem, activityPriority: .medium)
    }
}
