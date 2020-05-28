//
//  MasterActivityController.swift
//  Plot
//
//  Created by Cory McHattie on 4/21/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import UIKit
import Contacts

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
            notificationsVC.users = users
            mapVC.searchVC.users = users
        }
    }
    var filteredUsers = [User]() {
        didSet {
            activitiesVC.filteredUsers = filteredUsers
            chatsVC.filteredUsers = filteredUsers
            listsVC.filteredUsers = filteredUsers
            notificationsVC.filteredUsers = filteredUsers
            mapVC.searchVC.filteredUsers = filteredUsers
        }
    }
    var conversations = [Conversation]() {
        didSet {
            activitiesVC.conversations = conversations
            notificationsVC.conversations = conversations
            mapVC.conversations = conversations
            listsVC.conversations = conversations
            let nav = self.tabBarController!.viewControllers![0] as! UINavigationController
            
            if nav.topViewController is ActivityTypeViewController {
                let activityTab = nav.topViewController as! ActivityTypeViewController
                activityTab.conversations = conversations
            }
        }
    }
    var activities = [Activity]() {
        didSet {
            notificationsVC.notificationActivities = activities
            notificationsVC.activityViewController = activitiesVC
            mapVC.activities = activities
            mapVC.activityViewController = activitiesVC
            listsVC.activities = activities
            listsVC.activityViewController = activitiesVC
            
            let nav = self.tabBarController!.viewControllers![0] as! UINavigationController
            
            if nav.topViewController is ActivityTypeViewController {
                let activityTab = nav.topViewController as! ActivityTypeViewController
                activityTab.activities = activities
                
            }
        }
    }
    var invitations: [String: Invitation] = [:] {
        didSet {
            notificationsVC.invitations = invitations
            mapVC.searchVC.invitations = invitations
        }
    }
    var invitedActivities = [Activity]() {
        didSet {
            notificationsVC.invitedActivities = invitedActivities
        }
    }
    var selectedDate = Date()
    
    let titles = ["Updates", "Chats", "Activities", "Lists", "Map"]
    var index: Int = 2
    
    let customSegmented = CustomSegmentedControl(buttonImages: ["notification-bell","chat","activity", "list", "map"])
    let containerView = UIView()
    
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
    
    lazy var mapVC: MapActivitiesViewController = {
        let vc = MapActivitiesViewController()
        self.addAsChildVC(childVC: vc)
        return vc
    }()
    
    lazy var listsVC: ListsViewController = {
        let vc = ListsViewController()
        self.addAsChildVC(childVC: vc)
        return vc
    }()
    
    lazy var notificationsVC: NotificationsViewController = {
        let vc = NotificationsViewController()
        self.addAsChildVC(childVC: vc)
        return vc
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("viewDidLoad")
        setupViews()
        setNavBar()
        activitiesVC.delegate = self
        chatsVC.delegate = self
        changeToIndex(index: index)
        addObservers()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: false)
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
        
        customSegmented.constrainHeight(constant: 50)
        
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
        if index == 1 {
            navigationItem.title = titles[index]
            let newChatBarButton =  UIBarButtonItem(barButtonSystemItem: .compose, target: self, action: #selector(newChat))
            let searchBarButton =  UIBarButtonItem(barButtonSystemItem: .search, target: self, action: #selector(search))
            navigationItem.leftBarButtonItem = editButtonItem
            navigationItem.rightBarButtonItems = [newChatBarButton, searchBarButton]
        } else if index == 2 {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MMMM yyyy"
            let dateString = dateFormatter.string(from: selectedDate)
            navigationItem.title = dateString
            let newActivityBarButton =  UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(newActivity))
            let searchBarButton =  UIBarButtonItem(barButtonSystemItem: .search, target: self, action: #selector(search))
            navigationItem.leftBarButtonItem = editButtonItem
            navigationItem.rightBarButtonItems = [newActivityBarButton, searchBarButton]
        } else if index == 3 {
            navigationItem.title = titles[index]
            let newListBarButton =  UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(newList))
            let searchBarButton =  UIBarButtonItem(barButtonSystemItem: .search, target: self, action: #selector(search))
            navigationItem.leftBarButtonItem = editButtonItem
            navigationItem.rightBarButtonItems = [newListBarButton, searchBarButton]
        } else {
            navigationItem.title = titles[index]
            navigationItem.leftBarButtonItem = nil
            navigationItem.rightBarButtonItems = nil
        }
    }
}

extension MasterActivityContainerController: CustomSegmentedControlDelegate {
    func changeToIndex(index:Int) {
        print("changeToIndex \(index)")
        if self.index == 1 {
            if chatsVC.tableView.isEditing == true {
                chatsVC.tableView.setEditing(false, animated: true)
                editButtonItem.style = .plain
                editButtonItem.title = "Edit"
            }
            if let searchBar = chatsVC.searchBar, searchBar.isFirstResponder {
                chatsVC.searchBar!.endEditing(true)
                if let cancelButton : UIButton = chatsVC.searchBar!.value(forKey: "cancelButton") as? UIButton {
                    cancelButton.isEnabled = true
                }
            }
        } else if self.index == 2 {
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
        } else if self.index == 3 {
            if listsVC.tableView.isEditing == true {
                listsVC.tableView.setEditing(false, animated: true)
                editButtonItem.style = .plain
                editButtonItem.title = "Edit"
            }
            if let searchBar = listsVC.searchBar, searchBar.isFirstResponder {
                listsVC.searchBar!.endEditing(true)
                if let cancelButton : UIButton = listsVC.searchBar!.value(forKey: "cancelButton") as? UIButton {
                    cancelButton.isEnabled = true
                }
            }
        }
        notificationsVC.view.isHidden = !(index == 0)
        if index == 0 {
            notificationsVC.sortInvitedActivities()
        }
        chatsVC.view.isHidden = !(index == 1)
        activitiesVC.view.isHidden = !(index == 2)
        listsVC.view.isHidden = !(index == 3)
        mapVC.view.isHidden = !(index == 4)
        if index == 3 {
            mapVC.myViewDidLoad()
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
            if chatsVC.tableView.isEditing == true {
                chatsVC.tableView.setEditing(false, animated: true)
                sender.style = .plain
                sender.title = "Edit"
            } else {
                chatsVC.tableView.setEditing(true, animated: true)
                sender.style = .done
                sender.title = "Done"
            }
        } else if index == 2 {
            if activitiesVC.activityView.tableView.isEditing == true {
                activitiesVC.activityView.tableView.setEditing(false, animated: true)
                sender.style = .plain
                sender.title = "Edit"
            } else {
                activitiesVC.activityView.tableView.setEditing(true, animated: true)
                sender.style = .done
                sender.title = "Done"
            }
        } else if index == 3 {
            if listsVC.tableView.isEditing == true {
                listsVC.tableView.setEditing(false, animated: true)
                sender.style = .plain
                sender.title = "Edit"
            } else {
                listsVC.tableView.setEditing(true, animated: true)
                sender.style = .done
                sender.title = "Done"
            }
        }
    }
    
    @objc fileprivate func newActivity() {
        tabBarController?.selectedIndex = 0
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
        let alertController = UIAlertController(title: "Type of List", message: nil, preferredStyle: .alert)
        let groceryList = UIAlertAction(title: "Grocery List", style: .default) { (action:UIAlertAction) in
            let destination = GrocerylistViewController()
            destination.connectedToAct = false
            destination.comingFromLists = true
            destination.users = self.users
            destination.filteredUsers = self.filteredUsers
            self.navigationController?.pushViewController(destination, animated: true)
        }
        let packingList = UIAlertAction(title: "Packing List", style: .default) { (action:UIAlertAction) in
            let destination = PackinglistViewController()
            destination.connectedToAct = false
            destination.comingFromLists = true
            destination.users = self.users
            destination.filteredUsers = self.filteredUsers
            self.navigationController?.pushViewController(destination, animated: true)
        }
        let checkList = UIAlertAction(title: "Checklist", style: .default) { (action:UIAlertAction) in
            let destination = ChecklistViewController()
            destination.connectedToAct = false
            destination.comingFromLists = true
            destination.users = self.users
            destination.filteredUsers = self.filteredUsers
            self.navigationController?.pushViewController(destination, animated: true)
        }
        let cancelAlert = UIAlertAction(title: "Cancel", style: .cancel) { (action:UIAlertAction) in
            print("You've pressed cancel")
            
        }
        
        alertController.addAction(groceryList)
        //                alertController.addAction(packingList)
        alertController.addAction(checkList)
        alertController.addAction(cancelAlert)
        self.present(alertController, animated: true, completion: nil)
    }
    
    @objc fileprivate func search() {
        if self.index == 1 {
            chatsVC.setupSearchController()
        } else if self.index == 2 {
            activitiesVC.setupSearchController()
        } else if self.index == 3 {
            listsVC.setupSearchController()
        }
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
