//
//  ActivityTableViewController.swift
//  Pigeon-project
//
//  Created by Cory McHattie on 4/27/19.
//  Copyright © 2019 Immature Creations. All rights reserved.
//

import UIKit
import Firebase
import SDWebImage

fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
    switch (lhs, rhs) {
    case let (l?, r?):
        return l < r
    case (nil, _?):
        return true
    default:
        return false
    }
}

fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
    switch (lhs, rhs) {
    case let (l?, r?):
        return l > r
    default:
        return rhs < lhs
    }
}

//update to change first controller shown
//protocol ManageAppearanceActivity: class {
//    func manageAppearanceActivity(_ activityController: ActivityTableViewController, didFinishLoadingWith state: Bool )
//}

class ActivityTableViewController: UITableViewController {
    
    fileprivate let activityCellID = "activityCellID"
    fileprivate var isAppLoaded = false
    fileprivate let plotAppGroup = "group.immaturecreations.plot"
    private var sharedContainer : UserDefaults?
    
//    weak var delegate: ManageAppearanceActivity?
    
    var searchBar: UISearchBar?
    var searchActivityController: UISearchController?
    
    var activities = [Activity]()
    var filteredActivities = [Activity]()
    var pinnedActivities = [Activity]()
    var filteredPinnedActivities = [Activity]()
    var users = [User]()
    var filteredUsers = [User]()
    var conversations = [Conversation]()
//    let notificationsManager = InAppNotificationManager()
    let activitiesFetcher = ActivitiesFetcher()
    
    let viewPlaceholder = ViewPlaceholder()
    let navigationItemActivityIndicator = NavigationItemActivityIndicator()


    override func viewDidLoad() {
        super.viewDidLoad()
        sharedContainer = UserDefaults(suiteName: plotAppGroup)
        configureTableView()
        setupSearchController()
        addObservers()

    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if !isAppLoaded {
            managePresense()
            activitiesFetcher.fetchActivities()
        }

//        updateUsers()
//        print("View Will Appear Activity update: update users: \(users)")
//        print("View Will Appear Activity update: update filtered users: \(filteredUsers)")
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    fileprivate func addObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(changeTheme), name: .themeUpdated, object: nil)
//        print("Activity Observers added")
    }
    
    
    @objc fileprivate func changeTheme() {
        view.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
        tableView.indicatorStyle = ThemeManager.currentTheme().scrollBarStyle
        tableView.sectionIndexBackgroundColor = view.backgroundColor
        tableView.backgroundColor = view.backgroundColor
        tableView.reloadData()
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return ThemeManager.currentTheme().statusBarStyle
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        guard tableView.isEditing else { return }
        tableView.endEditing(true)
        tableView.reloadData()
    }
    
    fileprivate func configureTableView() {
        tableView.register(ActivityCell.self, forCellReuseIdentifier: activityCellID)
        tableView.allowsMultipleSelectionDuringEditing = false
        view.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
        tableView.indicatorStyle = ThemeManager.currentTheme().scrollBarStyle
        tableView.backgroundColor = view.backgroundColor
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 105
        navigationItem.leftBarButtonItem = editButtonItem
        let newActivityBarButton =  UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(newActivity))
        navigationItem.rightBarButtonItem = newActivityBarButton
        extendedLayoutIncludesOpaqueBars = true
        edgesForExtendedLayout = UIRectEdge.top
        tableView.separatorStyle = .none
        definesPresentationContext = true
        activitiesFetcher.delegate = self
    }
    
    // Actions
//    @objc fileprivate func addButtonPressed(_ sender: UIBarButtonItem) {
//        let addViewModel = viewModel.addViewModel()
//        let addVC = CreateActivityViewController(viewModel: addViewModel)
//        addVC.hidesBottomBarWhenPushed = true
//        navigationController?.pushViewController(addVC, animated: true)
//        addVC.users = users
//        addVC.filteredUsers = filteredUsers
//    }
    
    @objc fileprivate func newActivity() {
        let destination = CreateActivityViewController()
        destination.hidesBottomBarWhenPushed = true
        destination.users = users
        destination.filteredUsers = filteredUsers
        destination.conversations = conversations
//        print("New Activity update: update users: \(users)")
//        print("New Activity update: update filtered users: \(filteredUsers)")
        navigationController?.pushViewController(destination, animated: true)

    }
    
    fileprivate func setupSearchController() {
        
//        if #available(iOS 11.0, *) {
//            searchActivityController = UISearchController(searchResultsController: nil)
//            searchActivityController?.searchResultsUpdater = self
//            searchActivityController?.obscuresBackgroundDuringPresentation = false
//            searchActivityController?.searchBar.delegate = self
//            searchActivityController?.definesPresentationContext = true
//            navigationItem.searchController = searchActivityController
//        } else {
//            searchBar = UISearchBar()
//            searchBar?.delegate = self
//            searchBar?.placeholder = "Search"
//            searchBar?.searchBarStyle = .minimal
//            searchBar?.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: 50)
//            tableView.tableHeaderView = searchBar
//        }
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
    
    func checkIfThereAnyActivities(isEmpty: Bool) {
        guard isEmpty else {
            viewPlaceholder.remove(from: view, priority: .medium)
            return
        }
        viewPlaceholder.add(for: view, title: .emptyActivities, subtitle: .emptyActivities, priority: .medium, position: .top)
    }
    
    func configureTabBarBadge() {
        guard let tabItems = tabBarController?.tabBar.items as NSArray? else { return }
        guard let tabItem = tabItems[Tabs.activity.rawValue] as? UITabBarItem else { return }
        var badge = 0
        
        for activity in filteredActivities {
            guard let activityBadge = activity.badge else { continue }
            badge += activityBadge
        }

        for activity in filteredPinnedActivities {
            guard let activityBadge = activity.badge else { continue }
            badge += activityBadge
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
    
    fileprivate func updateCell(at indexPath: IndexPath) {
        tableView.beginUpdates()
        tableView.reloadRows(at: [indexPath], with: .none)
        tableView.endUpdates()
    }
    
    fileprivate func deleteCell(at indexPath: IndexPath) {
        tableView.beginUpdates()
        tableView.deleteRows(at: [indexPath], with: .none)
        tableView.endUpdates()
    }
    
    func handleReloadTable() {
        activities.sort { (activity1, activity2) -> Bool in
            return activity1.startDateTime?.int64Value < activity2.startDateTime?.int64Value
        }
        
        pinnedActivities.sort { (activity1, activity2) -> Bool in
            return activity1.startDateTime?.int64Value < activity2.startDateTime?.int64Value
        }
        
        filteredPinnedActivities = pinnedActivities
        filteredActivities = activities
        let allActivities = pinnedActivities + activities
        
        saveDataToSharedContainer(activities: allActivities)
        
        if !isAppLoaded {
            UIView.transition(with: tableView, duration: 0.15, options: .transitionCrossDissolve, animations: { self.tableView.reloadData()}, completion: nil)
            configureTabBarBadge()
        } else {
            configureTabBarBadge()
            tableView.reloadData()
        }
        
        if filteredActivities.count == 0 && filteredPinnedActivities.count == 0 {
            checkIfThereAnyActivities(isEmpty: true)
        } else {
             checkIfThereAnyActivities(isEmpty: false)
        }
        
        guard !isAppLoaded else { return }
//        delegate?.manageAppearanceActivity(self, didFinishLoadingWith: true)
        isAppLoaded = true
    }
    
    func handleReloadTableAfterSearch() {
        filteredActivities.sort { (activity1, activity2) -> Bool in
            return activity1.startDateTime?.int64Value < activity2.startDateTime?.int64Value
        }
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    
    
    // MARK: - Table view data source
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            if filteredPinnedActivities.count == 0 {
                return ""
            }
            return " "//Pinned
        } else {
            return " "
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0 {
            return 8
        } else {
            if filteredPinnedActivities.count == 0 {
                return 0
            }
            return 8
        }
    }
    
    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        view.tintColor = ThemeManager.currentTheme().inputTextViewColor
        
        //    if section == 0 {
        //      view.tintColor = ThemeManager.currentTheme().generalBackgroundColor
        //    } else {
        //      view.tintColor = ThemeManager.currentTheme().inputTextViewColor
        //    }
        
        if let headerTitle = view as? UITableViewHeaderFooterView {
            headerTitle.textLabel?.textColor = FalconPalette.defaultBlue
            //      headerTitle.textLabel?.font = UIFont.systemFont(ofSize: 10)
            headerTitle.textLabel?.font = UIFont.preferredFont(forTextStyle: .subheadline)
            headerTitle.textLabel?.adjustsFontForContentSizeCategory = true
            headerTitle.textLabel?.minimumScaleFactor = 0.1
            headerTitle.textLabel?.adjustsFontSizeToFitWidth = true
        }
    }
    
//    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
////
////        let delete = setupDeleteAction(at: indexPath)
////        let pin = setupPinAction(at: indexPath)
////        let mute = setupMuteAction(at: indexPath)
//
////        return [delete, pin, mute]
//        return
//    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return filteredPinnedActivities.count
        } else {
            return filteredActivities.count
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: activityCellID, for: indexPath) as? ActivityCell ?? ActivityCell()
        
        if indexPath.section == 0 {
            cell.configureCell(for: indexPath, activity: filteredPinnedActivities[indexPath.row], withInvitation: nil)
        } else {
            cell.configureCell(for: indexPath, activity: filteredActivities[indexPath.row], withInvitation: nil)
        }
        
        return cell
    }
    
//    chatLogController = ChatLogController(collectionViewLayout: AutoSizingCollectionViewFlowLayout())
//    messagesFetcher = MessagesFetcher()
//    messagesFetcher?.delegate = self
//    messagesFetcher?.loadMessagesData(for: conversation)
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        var activity: Activity!
        
        if indexPath.section == 0 {
            let pinnedActivity = filteredPinnedActivities[indexPath.row]
            activity = pinnedActivity
        } else {
            let unpinnedActivity = filteredActivities[indexPath.row]
            activity = unpinnedActivity
        }
        
        let destination = CreateActivityViewController()
        destination.hidesBottomBarWhenPushed = true
        destination.activity = activity
        destination.users = users
        destination.filteredUsers = filteredUsers
        destination.conversations = conversations

        navigationController?.pushViewController(destination, animated: true)
    }
    
    fileprivate func saveDataToSharedContainer(activities: [Activity]) {
        if let sharedContainer = sharedContainer {
            var activitiesArray = [Any]()
            for activity in activities {
                let activityNSDictionary = activity.toAnyObject()
                activitiesArray.append(NSKeyedArchiver.archivedData(withRootObject: activityNSDictionary))
            }
            sharedContainer.set(activitiesArray, forKey: "ActivitiesArray")
            sharedContainer.synchronize()
        }
    }
}

extension ActivityTableViewController: DeleteAndExitDelegate {
    
    func deleteAndExit(from otherActivityID: String) {
        
        let pinnedIDs = pinnedActivities.map({$0.activityID ?? ""})
        let section = pinnedIDs.contains(otherActivityID) ? 0 : 1
        guard let row = activityIndex(for: otherActivityID, at: section) else { return }
        
        let indexPath = IndexPath(row: row, section: section)
        section == 0 ? deletePinnedActivity(at: indexPath) : deleteUnPinnedActivity(at: indexPath)
    }
    
    func activityIndex(for otherActivityID: String, at section: Int) -> Int? {
        let activitiesArray = section == 0 ? filteredPinnedActivities : filteredActivities
        guard let index = activitiesArray.firstIndex(where: { (activity) -> Bool in
            guard let activityID = activity.activityID else { return false }
            return activityID == otherActivityID
        }) else { return nil }
        return index
    }
}

//extension ActivityTableViewController: MessagesDelegate {
//
//    func messages(shouldChangeMessageStatusToReadAt reference: DatabaseReference) {
//        chatLogController?.updateMessageStatus(messageRef: reference)
//    }
//
//    func messages(shouldBeUpdatedTo messages: [Message], conversation: Conversation) {
//
//        chatLogController?.hidesBottomBarWhenPushed = true
//        chatLogController?.messagesFetcher = messagesFetcher
//        chatLogController?.messages = messages
//        chatLogController?.conversation = conversation
//        chatLogController?.deleteAndExitDelegate = self
//
//        if let membersIDs = conversation.chatParticipantsIDs, let uid = Auth.auth().currentUser?.uid, membersIDs.contains(uid) {
//            chatLogController?.observeTypingIndicator()
//            chatLogController?.configureTitleViewWithOnlineStatus()
//        }
//
//        chatLogController?.messagesFetcher.collectionDelegate = chatLogController
//        guard let destination = chatLogController else { return }
//
//        if #available(iOS 11.0, *) {
//        } else {
//            self.chatLogController?.startCollectionViewAtBottom()
//        }
//
//        navigationController?.pushViewController(destination, animated: true)
//        chatLogController = nil
//        messagesFetcher?.delegate = nil
//        messagesFetcher = nil
//    }
//}

extension ActivityTableViewController: ActivityUpdatesDelegate {
    func activities(remove activity: Activity) {
        let activityID = activity.activityID ?? ""
        
        if let index = activities.firstIndex(where: {$0.activityID == activityID}) {
            activities.remove(at: index)
        }

        if let index = filteredActivities.firstIndex(where: {$0.activityID == activityID}) {
            filteredActivities.remove(at: index)
            let indexPath = IndexPath(row: index, section: 1)
            deleteCell(at: indexPath)
        }
    }
    
    
    func activities(didStartFetching: Bool) {
    guard !isAppLoaded else { return }
    navigationItemActivityIndicator.showActivityIndicator(for: navigationItem, with: .updating,
                                                              activityPriority: .mediumHigh, color: ThemeManager.currentTheme().generalTitleColor)
    }
    
    func activities(didStartUpdatingData: Bool) {
        navigationItemActivityIndicator.showActivityIndicator(for: navigationItem, with: .updating,
                                                              activityPriority: .lowMedium, color: ThemeManager.currentTheme().generalTitleColor)
    }
    
    func activities(didFinishFetching: Bool, activities: [Activity]) {
//        notificationsManager.observersForNotificationsActivities(activities: activities)
        
        let (pinned, unpinned) = activities.stablePartition { (element) -> Bool in
            let isPinned = element.pinned ?? false
            return isPinned == true
        }
        
        self.activities = unpinned
        self.pinnedActivities = pinned
        
        
        handleReloadTable()
        navigationItemActivityIndicator.hideActivityIndicator(for: navigationItem, activityPriority: .mediumHigh)
    }
    
    func activities(update activity: Activity, reloadNeeded: Bool) {
        let activityID = activity.activityID ?? ""
        
        if let index = activities.firstIndex(where: {$0.activityID == activityID}) {
            activities[index] = activity
        }
        if let index = pinnedActivities.firstIndex(where: {$0.activityID == activityID}) {
            pinnedActivities[index] = activity
        }
        if let index = filteredActivities.firstIndex(where: {$0.activityID == activityID}) {
            filteredActivities[index] = activity
            let indexPath = IndexPath(row: index, section: 1)
            if reloadNeeded { updateCell(at: indexPath) }
        }
        if let index = filteredPinnedActivities.firstIndex(where: {$0.activityID == activityID}) {
            filteredPinnedActivities[index] = activity
            let indexPath = IndexPath(row: index, section: 0)
            if reloadNeeded { updateCell(at: indexPath) }
        }
        
//        let allActivities = activities + pinnedActivities
//        notificationsManager.updateActivities(to: allActivities)
//        navigationItemActivityIndicator.hideActivityIndicator(for: navigationItem, activityPriority: .lowMedium)
        
    }
}

