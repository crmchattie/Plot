//
//  SelectActivityTableViewController.swift
//  Pigeon-project
//
//  Created by Cory McHattie on 4/27/19.
//  Copyright © 2019 Immature Creations. All rights reserved.
//

import UIKit
import Firebase
import SDWebImage
import CodableFirebase

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


class SelectActivityTableViewController: UITableViewController {
    
    fileprivate let eventCellID = "eventCellID"
    
    var searchBar: UISearchBar?
    var searchActivityController: UISearchController?
    
    var activities = [Activity]()
    var filteredActivities = [Activity]()
    var pinnedActivities = [Activity]()
    var filteredPinnedActivities = [Activity]()
    var users = [User]()
    var filteredUsers = [User]()
    var selectedFalconUsers = [User]()
    var conversation: Conversation!
    // [ActivityID: Invitation]
    var invitations: [String: Invitation] = [:]
    var invitedActivities: [Activity] = []
    
    var chatLogController: ChatLogController? = nil
    var messagesFetcher: MessagesFetcher? = nil
    var networkController = NetworkController()

    
    // [ActivityID: Participants]
    var activitiesParticipants: [String: [User]] = [:]
//    let notificationsManager = InAppNotificationManager()
    
//    let navigationItemActivityIndicator = NavigationItemActivityIndicator()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureTableView()
        setupSearchController()
        addObservers()
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        handleReloadTable()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    fileprivate func addObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(changeTheme), name: .themeUpdated, object: nil)
//        NotificationCenter.default.addObserver(self, selector: #selector(updateUsers), name: .falconUsersUpdated, object: nil)
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
        tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(EventCell.self, forCellReuseIdentifier: eventCellID)
        tableView.allowsMultipleSelectionDuringEditing = false
        view.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
//        let newActivityBarButton =  UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(newActivity))
//        navigationItem.rightBarButtonItem = newActivityBarButton
        tableView.indicatorStyle = ThemeManager.currentTheme().scrollBarStyle
        tableView.backgroundColor = view.backgroundColor
        extendedLayoutIncludesOpaqueBars = true
        edgesForExtendedLayout = UIRectEdge.top
        tableView.separatorStyle = .none
        definesPresentationContext = true
        navigationItem.title = conversation.chatName
        
    }
    
//    @objc fileprivate func newActivity() {
//        let destination = ActivityTypeViewController()
//        destination.hidesBottomBarWhenPushed = true
//        destination.users = users
//        destination.filteredUsers = filteredUsers
//        destination.activities = activities + pinnedActivities
//        destination.selectedFalconUsers = selectedFalconUsers
//        destination.conversation = conversation
//        navigationController?.pushViewController(destination, animated: true)
//    }
    
    
    fileprivate func setupSearchController() {
        
        if #available(iOS 11.0, *) {
            searchActivityController = UISearchController(searchResultsController: nil)
            searchActivityController?.searchResultsUpdater = self
            searchActivityController?.obscuresBackgroundDuringPresentation = false
            searchActivityController?.searchBar.delegate = self
            searchActivityController?.definesPresentationContext = true
            navigationItem.searchController = searchActivityController
        } else {
            searchBar = UISearchBar()
            searchBar?.delegate = self
            searchBar?.placeholder = "Search"
            searchBar?.searchBarStyle = .minimal
            searchBar?.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: 50)
            tableView.tableHeaderView = searchBar
        }
    }
    
//    fileprivate func managePresense() {
//        if currentReachabilityStatus == .notReachable {
//            navigationItemActivityIndicator.showActivityIndicator(for: navigationItem, with: .connecting,
//                                                                  activityPriority: .high,
//                                                                  color: ThemeManager.currentTheme().generalTitleColor)
//        }
//
//        let connectedReference = Database.database().reference(withPath: ".info/connected")
//        connectedReference.observe(.value, with: { (snapshot) in
//
//            if self.currentReachabilityStatus != .notReachable {
//                self.navigationItemActivityIndicator.hideActivityIndicator(for: self.navigationItem, activityPriority: .crazy)
//            } else {
//                self.navigationItemActivityIndicator.showActivityIndicator(for: self.navigationItem, with: .noInternet, activityPriority: .crazy, color: ThemeManager.currentTheme().generalTitleColor)
//            }
//        })
//    }
    
    
    
    func handleReloadTable() {
        let currentDate = NSNumber(value: Int((Date().localTime).timeIntervalSince1970)).int64Value
        pinnedActivities.sort { (activity1, activity2) -> Bool in
            if currentDate.isBetween(activity1.startDateTime?.int64Value ?? 0, and: activity1.endDateTime?.int64Value ?? 0) && currentDate.isBetween(activity2.startDateTime?.int64Value ?? 0, and: activity2.endDateTime?.int64Value ?? 0) {
                return activity1.startDateTime?.int64Value ?? 0 < activity2.startDateTime?.int64Value ?? 0
            } else if currentDate.isBetween(activity1.startDateTime?.int64Value ?? 0, and: activity1.endDateTime?.int64Value ?? 0) {
                return currentDate < activity2.startDateTime?.int64Value ?? 0
            } else if currentDate.isBetween(activity2.startDateTime?.int64Value ?? 0, and: activity2.endDateTime?.int64Value ?? 0) {
                return activity1.startDateTime?.int64Value ?? 0 < currentDate
            }
            return activity1.startDateTime?.int64Value ?? 0 < activity2.startDateTime?.int64Value ?? 0
        }
        
        activities.sort { (activity1, activity2) -> Bool in
            if currentDate.isBetween(activity1.startDateTime?.int64Value ?? 0, and: activity1.endDateTime?.int64Value ?? 0) && currentDate.isBetween(activity2.startDateTime?.int64Value ?? 0, and: activity2.endDateTime?.int64Value ?? 0) {
                return activity1.startDateTime?.int64Value ?? 0 < activity2.startDateTime?.int64Value ?? 0
            } else if currentDate.isBetween(activity1.startDateTime?.int64Value ?? 0, and: activity1.endDateTime?.int64Value ?? 0) {
                return currentDate < activity2.startDateTime?.int64Value ?? 0
            } else if currentDate.isBetween(activity2.startDateTime?.int64Value ?? 0, and: activity2.endDateTime?.int64Value ?? 0) {
                return activity1.startDateTime?.int64Value ?? 0 < currentDate
            }
            return activity1.startDateTime?.int64Value ?? 0 < activity2.startDateTime?.int64Value ?? 0
        }
        
        filteredPinnedActivities = pinnedActivities
        filteredActivities = activities
        
        tableView.reloadData()
        
    }
    
    func handleReloadTableAfterSearch() {
        let currentDate = NSNumber(value: Int((Date().localTime).timeIntervalSince1970)).int64Value
        filteredActivities.sort { (activity1, activity2) -> Bool in
            if currentDate.isBetween(activity1.startDateTime?.int64Value ?? 0, and: activity1.endDateTime?.int64Value ?? 0) && currentDate.isBetween(activity2.startDateTime?.int64Value ?? 0, and: activity2.endDateTime?.int64Value ?? 0) {
                return activity1.startDateTime?.int64Value ?? 0 < activity2.startDateTime?.int64Value ?? 0
            } else if currentDate.isBetween(activity1.startDateTime?.int64Value ?? 0, and: activity1.endDateTime?.int64Value ?? 0) {
                return currentDate < activity2.startDateTime?.int64Value ?? 0
            } else if currentDate.isBetween(activity2.startDateTime?.int64Value ?? 0, and: activity2.endDateTime?.int64Value ?? 0) {
                return activity1.startDateTime?.int64Value ?? 0 < currentDate
            }
            return activity1.startDateTime?.int64Value ?? 0 < activity2.startDateTime?.int64Value ?? 0
        }
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    
    
    // MARK: - Table view data source
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return false
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
//
//        let delete = setupDeleteAction(at: indexPath)
//        let pin = setupPinAction(at: indexPath)
//        let mute = setupMuteAction(at: indexPath)
//
//        return [delete, pin, mute]
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
        
        let cell = tableView.dequeueReusableCell(withIdentifier: eventCellID, for: indexPath) as? EventCell ?? EventCell()
        
        cell.updateInvitationDelegate = self
        
        if indexPath.section == 0 {
            let activity = filteredPinnedActivities[indexPath.row]
            var invitation: Invitation? = nil
            if let activityID = activity.activityID, let value = invitations[activityID] {
                invitation = value
            }
            
            cell.configureCell(for: indexPath, activity: activity, withInvitation: invitation)

        } else {
            let activity = filteredActivities[indexPath.row]
            var invitation: Invitation? = nil
            if let activityID = activity.activityID, let value = invitations[activityID] {
                invitation = value
            }
            
            cell.configureCell(for: indexPath, activity: activity, withInvitation: invitation)
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        var activity: Activity!
        
        if indexPath.section == 0 {
            let pinnedActivity = filteredPinnedActivities[indexPath.row]
            activity = pinnedActivity
        } else {
            let unpinnedActivity = filteredActivities[indexPath.row]
            activity = unpinnedActivity
        }
        
        let destination = EventViewController(networkController: networkController)
        destination.hidesBottomBarWhenPushed = true
        destination.activity = activity
        destination.invitation = invitations[activity.activityID ?? ""]
        ParticipantsFetcher.getParticipants(forActivity: activity) { (participants) in
            ParticipantsFetcher.getAcceptedParticipant(forActivity: activity, allParticipants: participants) { acceptedParticipant in
                destination.acceptedParticipant = acceptedParticipant
                destination.selectedFalconUsers = participants
                self.navigationController?.pushViewController(destination, animated: true)
            }
        }
    }
    
    func showActivityIndicator() {
        if let tabController = self.tabBarController {
            self.showSpinner(onView: tabController.view)
        }
        self.navigationController?.view.isUserInteractionEnabled = false
    }

    func hideActivityIndicator() {
        self.navigationController?.view.isUserInteractionEnabled = true
        self.removeSpinner()
    }
}


extension SelectActivityTableViewController: UISearchBarDelegate, UISearchControllerDelegate, UISearchResultsUpdating {
    
    func updateSearchResults(for searchController: UISearchController) {}
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = nil
        //        filtededConversations = conversations
        //        filteredPinnedConversations = pinnedConversations
        //        handleReloadTable()
        guard #available(iOS 11.0, *) else {
            searchBar.setShowsCancelButton(false, animated: true)
            searchBar.resignFirstResponder()
            return
        }
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        
        filteredActivities = searchText.isEmpty ? activities :
            activities.filter({ (activity) -> Bool in
                if let name = activity.name {
                    return name.lowercased().contains(searchText.lowercased())
                }
                return ("").lowercased().contains(searchText.lowercased())
            })
        
        filteredPinnedActivities = searchText.isEmpty ? pinnedActivities :
            pinnedActivities.filter({ (activity) -> Bool in
                if let name = activity.name {
                    return name.lowercased().contains(searchText.lowercased())
                }
                return ("").lowercased().contains(searchText.lowercased())
            })
        
        handleReloadTableAfterSearch()
    }
    
    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        searchBar.keyboardAppearance = ThemeManager.currentTheme().keyboardAppearance
        guard #available(iOS 11.0, *) else {
            searchBar.setShowsCancelButton(true, animated: true)
            return true
        }
        return true
    }
}

extension SelectActivityTableViewController { /* hiding keyboard */
    
    override func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        
        if #available(iOS 11.0, *) {
            searchActivityController?.searchBar.endEditing(true)
        } else {
            self.searchBar?.endEditing(true)
        }
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        setNeedsStatusBarAppearanceUpdate()
        if #available(iOS 11.0, *) {
            searchActivityController?.searchBar.endEditing(true)
        } else {
            self.searchBar?.endEditing(true)
        }
    }
}

extension SelectActivityTableViewController: MessagesDelegate {
    
    func messages(shouldChangeMessageStatusToReadAt reference: DatabaseReference) {
        chatLogController?.updateMessageStatus(messageRef: reference)
    }
    
    func messages(shouldBeUpdatedTo messages: [Message], conversation: Conversation) {
        
        chatLogController?.hidesBottomBarWhenPushed = true
        chatLogController?.messagesFetcher = messagesFetcher
        chatLogController?.messages = messages
        chatLogController?.conversation = conversation
        //chatLogController?.activityID = activityID
        
        if let membersIDs = conversation.chatParticipantsIDs, let uid = Auth.auth().currentUser?.uid, membersIDs.contains(uid) {
            chatLogController?.observeTypingIndicator()
            chatLogController?.configureTitleViewWithOnlineStatus()
        }
        
        chatLogController?.messagesFetcher.collectionDelegate = chatLogController
        guard let destination = chatLogController else { return }
        
        self.chatLogController?.startCollectionViewAtBottom()
        
        navigationController?.pushViewController(destination, animated: true)
        chatLogController = nil
        messagesFetcher?.delegate = nil
        messagesFetcher = nil
    }
}


extension SelectActivityTableViewController: UpdateInvitationDelegate {
    func updateInvitation(invitation: Invitation) {
        InvitationsFetcher.update(invitation: invitation) { result in
            if result {
                self.invitations[invitation.activityID] = invitation
            }
        }
    }
}
