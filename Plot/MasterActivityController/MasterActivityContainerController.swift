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

protocol ManageAppearanceHome: class {
    func manageAppearanceHome(_ homeController: MasterActivityContainerController, didFinishLoadingWith state: Bool )
}

class MasterActivityContainerController: UIViewController {
    
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
            summaryViewModel.activities = activities
//            mapVC.sections = [.activities]
//            mapVC.locations = [.activities: activities]
//            mapVC.addAnnotations()
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
    
    var transactions: [Transaction]! {
        didSet {
            summaryViewModel.transactions = transactions
            if !activities.isEmpty {
                summaryVC.fetchData()
            }
        }
    }

    var selectedDate = Date()
    
    let titles = ["Summary", "Activities", "Health", "Finances"]
    var index: Int = 0
    let customSegmented = CustomSegmentedControl(buttonImages: ["activity", "calendar", "heart", "money"], buttonTitles: nil, selectedIndex: 0)
    let containerView = UIView()
    
    let navigationItemActivityIndicator = NavigationItemActivityIndicator()
    
    var healthVCInitialized = false
    
    weak var delegate: ManageAppearanceHome?
        
    lazy var activitiesVC: ActivityViewController = {
        let vc = ActivityViewController()
        self.addAsChildVC(childVC: vc)
        return vc
    }()
    
    lazy var chatsVC: ChatsTableViewController = {
        let vc = ChatsTableViewController()
        self.addAsChildVC(childVC: vc)
        return vc
    }()
    
    lazy var listsVC: ListsViewController = {
        let vc = ListsViewController()
        self.addAsChildVC(childVC: vc)
        return vc
    }()
    
    lazy var financeVC: FinanceViewController = {
        let vc = FinanceViewController()
        self.addAsChildVC(childVC: vc)
        return vc
    }()
    
    lazy var healthVC: HealthViewController = {
        let vc = HealthViewController()
        healthVCInitialized = true
        self.addAsChildVC(childVC: vc)
        return vc
    }()
    
    let summaryViewModel = SummaryViewModel(activities: nil, transactions: nil, summaryService: SummaryService())
    
    lazy var summaryVC: SummaryViewController = {
        let vc = SummaryViewController(viewModel: summaryViewModel)
        self.addAsChildVC(childVC: vc)
        return vc
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        setNavBar()
        activitiesVC.delegate = self
        chatsVC.delegate = self
        listsVC.delegate = self
        financeVC.delegate = self
        changeToIndex(index: index)
        addObservers()
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
        childVC.view.frame = containerView.bounds
        containerView.addSubview(childVC.view)
        childVC.didMove(toParent: self)
    }
    
    private func removeAsChildVC(childVC: UIViewController) {
        childVC.willMove(toParent: nil)
        childVC.view.removeFromSuperview()
        childVC.removeFromParent()
    }
    
    func setupViews() {
        navigationItem.largeTitleDisplayMode = .never
        navigationController?.navigationBar.prefersLargeTitles = false
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
        
        customSegmented.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
        customSegmented.delegate = self
        
        customSegmented.constrainHeight(50)
        
        view.addSubview(customSegmented)
        view.addSubview(containerView)
        
        customSegmented.anchor(top: view.safeAreaLayoutGuide.topAnchor, leading: view.safeAreaLayoutGuide.leadingAnchor, bottom: nil, trailing: view.safeAreaLayoutGuide.trailingAnchor, padding: .init(top: 0, left: 0, bottom: 0, right: 0))
        containerView.anchor(top: customSegmented.bottomAnchor, leading: view.safeAreaLayoutGuide.leadingAnchor, bottom: view.safeAreaLayoutGuide.bottomAnchor, trailing: view.safeAreaLayoutGuide.trailingAnchor, padding: .init(top: 0, left: 0, bottom: 0, right: 0))
                
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
        customSegmented.backgroundColor = theme.generalBackgroundColor
        
        navigationController?.navigationBar.barStyle = theme.barStyle
        navigationController?.navigationBar.barTintColor = theme.barBackgroundColor
        let textAttributes = [NSAttributedString.Key.foregroundColor: theme.generalTitleColor]
        navigationController?.navigationBar.titleTextAttributes = textAttributes
        navigationController?.navigationBar.largeTitleTextAttributes = textAttributes
        navigationController?.navigationBar.backgroundColor = theme.barBackgroundColor
        
        tabBarController?.tabBar.barTintColor = theme.barBackgroundColor
        tabBarController?.tabBar.barStyle = theme.barStyle
        
    }
    
    func setNavBar() {
        navigationItem.leftBarButtonItems = nil
        navigationItem.rightBarButtonItems = nil
        navigationItem.title = titles[index]
        if index == 1 {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MMMM yyyy"
            let dateString = dateFormatter.string(from: selectedDate)
            navigationItem.title = dateString
            let newActivityBarButton =  UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(newItem))
            let searchBarButton =  UIBarButtonItem(barButtonSystemItem: .search, target: self, action: #selector(search))
            navigationItem.leftBarButtonItem = editButtonItem
            navigationItem.rightBarButtonItems = [newActivityBarButton, searchBarButton]
        } else if index == 2 {
            let newHealthItemBarButton =  UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(newItem))
            navigationItem.rightBarButtonItems = [newHealthItemBarButton]
        } else if index == 3 {
            let newFinanceItemBarButton =  UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(newItem))
            navigationItem.rightBarButtonItems = [newFinanceItemBarButton]
        }
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

extension MasterActivityContainerController: CustomSegmentedControlDelegate {
    func changeToIndex(index:Int) {
        if self.index == 1 {
            if activitiesVC.activityView.tableView.isEditing == true {
                activitiesVC.activityView.tableView.setEditing(false, animated: true)
                editButtonItem.style = .plain
                editButtonItem.title = "Edit"
            }
            if let searchBar = activitiesVC.searchBar, searchBar.isFirstResponder {
                activitiesVC.searchBar!.endEditing(true)
                if let cancelButton : UIButton = activitiesVC.searchBar!.value(forKey: "cancelButton") as? UIButton {
                    cancelButton.isEnabled = true
                }
            }
        }
        
        summaryVC.view.isHidden = !(index == 0)
        activitiesVC.view.isHidden = !(index == 1)
        let isHealthVCIsHidden = !(index == 2)
        financeVC.view.isHidden = !(index == 3)
        chatsVC.view.isHidden = !(index == 5)
        listsVC.view.isHidden = !(index == 6)

        if isHealthVCIsHidden && !healthVCInitialized {
            // Don't do anything if healthVC is hidden and not initialized. We don't to access healthVC so that its viewDidAppear execute
        } else {
            healthVC.delegate = self
            healthVC.view.isHidden = isHealthVCIsHidden
        }

        self.index = index
        setNavBar()
    }
}

extension MasterActivityContainerController {
    override var editButtonItem: UIBarButtonItem {
        let editButton = super.editButtonItem
        editButton.action = #selector(editButtonAction)
        return editButton
    }
    
    @objc func editButtonAction(sender: UIBarButtonItem) {
        if index == 1 {
            if activitiesVC.activityView.tableView.isEditing == true {
                activitiesVC.activityView.tableView.setEditing(false, animated: true)
                sender.style = .plain
                sender.title = "Edit"
            } else {
                activitiesVC.activityView.tableView.setEditing(true, animated: true)
                sender.style = .done
                sender.title = "Done"
            }
        }
    }
    
    @objc fileprivate func newChat() {
        let destination = ContactsController()
        destination.hidesBottomBarWhenPushed = true
        let isContactsAccessGranted = destination.checkContactsAuthorizationStatus()
        if isContactsAccessGranted {
            destination.users = users
            destination.filteredUsers = filteredUsers
            destination.contacts = contacts
            destination.filteredContacts = filteredContacts
            destination.conversations = conversations
        }
        navigationController?.pushViewController(destination, animated: true)
    }
    
    @objc fileprivate func newList() {
        let alertController = UIAlertController(title: "Type of List", message: nil, preferredStyle: .actionSheet)
        let groceryList = UIAlertAction(title: "Grocery List", style: .default) { (action:UIAlertAction) in
            let destination = GrocerylistViewController()
            destination.hidesBottomBarWhenPushed = true
            destination.connectedToAct = false
            destination.comingFromLists = true
            destination.users = self.users
            destination.filteredUsers = self.filteredUsers
            destination.activities = self.activities
            self.navigationController?.pushViewController(destination, animated: true)
        }
//        let packingList = UIAlertAction(title: "Packing List", style: .default) { (action:UIAlertAction) in
//            let destination = PackinglistViewController()
//            destination.hidesBottomBarWhenPushed = true
//            destination.connectedToAct = false
//            destination.comingFromLists = true
//            destination.users = self.users
//            destination.filteredUsers = self.filteredUsers
//            destination.activities = self.activities
//            self.navigationController?.pushViewController(destination, animated: true)
//        }
        let activityList = UIAlertAction(title: "Activity List", style: .default) { (action:UIAlertAction) in
            let destination = ActivitylistViewController()
            destination.hidesBottomBarWhenPushed = true
            destination.connectedToAct = false
            destination.comingFromLists = true
            destination.users = self.users
            destination.filteredUsers = self.filteredUsers
            destination.activities = self.activities
            self.navigationController?.pushViewController(destination, animated: true)
        }
        let checkList = UIAlertAction(title: "Checklist", style: .default) { (action:UIAlertAction) in
            let destination = ChecklistViewController()
            destination.hidesBottomBarWhenPushed = true
            destination.connectedToAct = false
            destination.comingFromLists = true
            destination.users = self.users
            destination.filteredUsers = self.filteredUsers
            destination.activities = self.activities
            self.navigationController?.pushViewController(destination, animated: true)
        }
        let cancelAlert = UIAlertAction(title: "Cancel", style: .cancel) { (action:UIAlertAction) in
            print("You've pressed cancel")
            
        }
        
        alertController.addAction(groceryList)
        alertController.addAction(activityList)
//                alertController.addAction(packingList)
        alertController.addAction(checkList)
        alertController.addAction(cancelAlert)
        self.present(alertController, animated: true, completion: nil)
    }
    
    @objc fileprivate func search() {
        if self.index == 1 {
            activitiesVC.setupSearchController()
        }
    }
    
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
    
    @objc fileprivate func goToMap() {
        
    }
}

extension MasterActivityContainerController: HomeBaseActivities {
    func manageAppearanceActivity(_ activityController: ActivityViewController, didFinishLoadingWith state: Bool) {
        delegate?.manageAppearanceHome(self, didFinishLoadingWith: true)
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

extension MasterActivityContainerController: HomeBaseHealth {
    
}


extension MasterActivityContainerController: EndedWebViewDelegate {
    func updateMXMembers() {
        financeVC.getMXData()
    }
}
