//
//  ActivityViewController.swift
//  Pigeon-project
//
//  Created by Cory McHattie on 8/23/19.
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

let activityCellID = "activityCellID"
let notificationCellID = "notificationCellID"

//update to change first controller shown
protocol ManageAppearanceActivity: class {
    func manageAppearanceActivity(_ activityController: ActivityViewController, didFinishLoadingWith state: Bool )
}

protocol UpdateInvitationDelegate: class {
    func updateInvitation(invitation: Invitation)
}

protocol ActivityViewControllerDataStore: class {
    func getParticipants(forActivity activity: Activity, completion: @escaping ([User])->())
}

class ActivityViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, FSCalendarDataSource, FSCalendarDelegate, UIGestureRecognizerDelegate {
    fileprivate var isAppLoaded = false
    fileprivate let plotAppGroup = "group.immaturecreations.plot"
    fileprivate var sharedContainer : UserDefaults?
    
    let activityView = ActivityView()
    
    weak var delegate: ManageAppearanceActivity?
    
    var searchBar: UISearchBar?
    var searchActivityController: UISearchController?
    
    var activities = [Activity]()
    var filteredActivities = [Activity]()
    var pinnedActivities = [Activity]()
    var filteredPinnedActivities = [Activity]()
    var users = [User]()
    var filteredUsers = [User]()
    var conversations = [Conversation]()
    let activitiesFetcher = ActivitiesFetcher()
    let invitationsFetcher = InvitationsFetcher()
    
    let viewPlaceholder = ViewPlaceholder()
    let navigationItemActivityIndicator = NavigationItemActivityIndicator()
    
    var canTransitionToLarge = false
    var canTransitionToSmall = true
    
    // [ActivityID: Invitation]
    var invitations: [String: Invitation] = [:]
    var invitedActivities: [Activity] = []
    
    // [ActivityID: Participants]
    var activitiesParticipants: [String: [User]] = [:]
    
    var chatLogController: ChatLogController? = nil
    var messagesFetcher: MessagesFetcher? = nil
    
    fileprivate lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd"
        return formatter
    }()
    
    fileprivate lazy var scopeGesture: UIPanGestureRecognizer = {
        [unowned self] in
        let panGesture = UIPanGestureRecognizer(target: activityView.calendar, action: #selector(activityView.calendar.handleScopeGesture(_:)))
        panGesture.delegate = self
        panGesture.minimumNumberOfTouches = 1
        panGesture.maximumNumberOfTouches = 2
        return panGesture
        }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        activitiesFetcher.delegate = self
        sharedContainer = UserDefaults(suiteName: plotAppGroup)
        configureView()
        setupSearchController()
        addObservers()
        
        // uncomment below to test out the recipe fetch API
    
//        let recipesFetcher = RecipesFetcher()
//        recipesFetcher.fetchRecipes(with: RecipesSearchRequest.from(query: "pasta", cuisine: "italian"), completion: { recipes in
//            print(recipes)
//        })
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if !isAppLoaded {
            managePresense()
            activitiesFetcher.fetchActivities()
        }
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
        
        navigationController?.navigationBar.barStyle = ThemeManager.currentTheme().barStyle
        navigationController?.navigationBar.barTintColor = ThemeManager.currentTheme().barBackgroundColor
        let textAttributes = [NSAttributedString.Key.foregroundColor: ThemeManager.currentTheme().generalTitleColor]
        navigationController?.navigationBar.titleTextAttributes = textAttributes
        navigationController?.navigationBar.largeTitleTextAttributes = textAttributes
        navigationController?.navigationBar.backgroundColor = ThemeManager.currentTheme().barBackgroundColor
        
        tabBarController?.tabBar.barTintColor = ThemeManager.currentTheme().barBackgroundColor
        tabBarController?.tabBar.barStyle = ThemeManager.currentTheme().barStyle
        
        activityView.tableView.indicatorStyle = theme.scrollBarStyle
        activityView.tableView.sectionIndexBackgroundColor = theme.generalBackgroundColor
        activityView.tableView.backgroundColor = theme.generalBackgroundColor
        activityView.tableView.reloadData()
        applyCalendarTheme()
    }
    
    fileprivate func applyCalendarTheme() {
        let theme = ThemeManager.currentTheme()
        activityView.calendar.backgroundColor = theme.generalBackgroundColor
        activityView.calendar.appearance.weekdayTextColor = theme.generalTitleColor
        activityView.calendar.appearance.headerTitleColor = theme.generalTitleColor
        activityView.calendar.appearance.eventDefaultColor = theme.generalTitleColor
        activityView.calendar.appearance.titleDefaultColor = theme.generalTitleColor
        activityView.calendar.appearance.titleSelectionColor = theme.generalBackgroundColor
        activityView.calendar.appearance.selectionColor = theme.generalTitleColor
        activityView.calendar.appearance.todayColor = FalconPalette.defaultBlue
        activityView.calendar.appearance.todaySelectionColor = FalconPalette.defaultBlue
        activityView.arrowButton.tintColor = theme.generalTitleColor
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return ThemeManager.currentTheme().statusBarStyle
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        guard activityView.tableView.isEditing else { return }
        activityView.tableView.endEditing(true)
        activityView.tableView.reloadData()
    }

    override var editButtonItem: UIBarButtonItem {
        let editButton = super.editButtonItem
        editButton.action = #selector(editButtonAction)
         return editButton
    }
    
    @objc func editButtonAction(sender: UIBarButtonItem) {
        if activityView.tableView.isEditing == true {
            activityView.tableView.setEditing(false, animated: true)
            //activityView.tableView.isEditing = false
            sender.style = .plain
            sender.title = "Edit"
         } else {
            //activityView.tableView.isEditing = true
            activityView.tableView.setEditing(true, animated: true)
            sender.style = .done
            sender.title = "Done"
         }
    }
    
    fileprivate func configureView() {
        view.addSubview(activityView)
        activityView.translatesAutoresizingMaskIntoConstraints = false
        activityView.topAnchor.constraint(equalTo:view.safeAreaLayoutGuide.topAnchor).isActive = true
        activityView.leadingAnchor.constraint(equalTo:view.safeAreaLayoutGuide.leadingAnchor).isActive = true
        activityView.trailingAnchor.constraint(equalTo:view.safeAreaLayoutGuide.trailingAnchor).isActive = true
        activityView.bottomAnchor.constraint(equalTo:view.safeAreaLayoutGuide.bottomAnchor).isActive = true
        
        activityView.arrowButton.addTarget(self, action: #selector(arrowButtonTapped), for: .touchUpInside)
        
        navigationItem.leftBarButtonItem = editButtonItem
        let newActivityBarButton =  UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(newActivity))
        
        let mapBarButton = UIBarButtonItem(image: UIImage(named: "map")!, style: .plain, target: self, action: #selector(showMappedActivities))
        
        let notificaionBarButton = UIBarButtonItem(image: UIImage(named: "notification-bell")!, style: .plain, target: self, action: #selector(showNotifications))
        
        navigationItem.rightBarButtonItems = [newActivityBarButton, notificaionBarButton, mapBarButton]
        extendedLayoutIncludesOpaqueBars = true
        edgesForExtendedLayout = UIRectEdge.top
        activityView.tableView.separatorStyle = .none
        definesPresentationContext = true
        
        activityView.addGestureRecognizer(self.scopeGesture)
        
        activityView.calendar.dataSource = self
        activityView.calendar.delegate = self
        activityView.calendar.select(Date())
        activityView.calendar.register(FSCalendarCell.self, forCellReuseIdentifier: "cell")
        activityView.calendar.scope = getCalendarScope()
        activityView.calendar.swipeToChooseGesture.isEnabled = true // Swipe-To-Choose
        
        let scopeGesture = UIPanGestureRecognizer(target: activityView.calendar, action: #selector(activityView.calendar.handleScopeGesture(_:)));
        activityView.calendar.addGestureRecognizer(scopeGesture)
        
        activityView.tableView.dataSource = self
        activityView.tableView.delegate = self
        activityView.tableView.register(ActivityCell.self, forCellReuseIdentifier: activityCellID)
        activityView.tableView.allowsMultipleSelectionDuringEditing = false
        activityView.tableView.indicatorStyle = ThemeManager.currentTheme().scrollBarStyle
        activityView.tableView.backgroundColor = view.backgroundColor
        activityView.tableView.rowHeight = UITableView.automaticDimension
        activityView.tableView.estimatedRowHeight = 105
  
        // apply theme
        applyCalendarTheme()
    }
    
    // MARK:- action: Selectors
    
    @objc fileprivate func newActivity() {
        self.createActivity()
    }
    
    @objc fileprivate func showMappedActivities() {
        let mapActivitiesViewController = MapActivitiesViewController()
        mapActivitiesViewController.activityViewController = self
        let navigationViewController = UINavigationController(rootViewController: mapActivitiesViewController)
        navigationViewController.modalPresentationStyle = .fullScreen
        self.present(navigationViewController, animated: true, completion: nil)
    }
    
    @objc fileprivate func showNotifications() {
        let notificationsViewController = NotificationsViewController()
        notificationsViewController.invitedActivities = self.invitedActivities
        notificationsViewController.notificationActivities = self.activities + self.pinnedActivities
        notificationsViewController.activityViewController = self
        let navigationViewController = UINavigationController(rootViewController: notificationsViewController)
        self.present(navigationViewController, animated: true, completion: nil)
    }
    
    func createActivity() {
        let destination = ActivityTypeViewController()
//        let destination = CreateActivityViewController()
        destination.hidesBottomBarWhenPushed = true
        destination.users = users
        destination.filteredUsers = filteredUsers
        destination.conversations = conversations
        navigationController?.pushViewController(destination, animated: true)
    }
    
    @objc fileprivate func arrowButtonTapped() {
        if activityView.calendar.scope == .month {
            weekView()
        } else {
            monthView()
        }
    }
    
    @objc fileprivate func monthView() {
        activityView.calendar.setScope(.month, animated: true)
        if activityView.calendar.isHidden {
            activityView.calendar.isHidden = false
            UIView.animate(withDuration: 0.25, animations:{
                self.activityView.calendarHeightConstraint?.constant = 300
                self.activityView.layoutIfNeeded()
            })
        }
    }
    
    @objc fileprivate func weekView() {
        activityView.calendar.setScope(.week, animated: true)
        if activityView.calendar.isHidden {
            activityView.calendar.isHidden = false
            UIView.animate(withDuration: 0.25, animations:{
                self.activityView.calendarHeightConstraint?.constant = 112
                self.activityView.layoutIfNeeded()
            })
        }
    }
    
    @objc fileprivate func listView() {
        UIView.animate(withDuration: 0.35, animations: {
            self.activityView.calendarHeightConstraint?.constant = 10
            self.activityView.layoutIfNeeded()
        }) { result in
            self.activityView.calendar.isHidden = true
        }
    }
    
    fileprivate func setupSearchController() {
        
        if #available(iOS 11.0, *) {
            searchActivityController = UISearchController(searchResultsController: nil)
            searchActivityController?.searchResultsUpdater = self
            searchActivityController?.obscuresBackgroundDuringPresentation = false
            searchActivityController?.searchBar.delegate = self
            searchActivityController?.definesPresentationContext = true
            navigationItem.searchController = searchActivityController
            navigationItem.hidesSearchBarWhenScrolling = true
        } else {
            searchBar = UISearchBar()
            searchBar?.delegate = self
            searchBar?.placeholder = "Search"
            searchBar?.searchBarStyle = .minimal
            searchBar?.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: 50)
            activityView.tableView.tableHeaderView = searchBar
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
    
    func checkIfThereAnyActivities(isEmpty: Bool) {
        guard isEmpty else {
            viewPlaceholder.remove(from: activityView.tableView, priority: .medium)
            return
        }
        viewPlaceholder.add(for: activityView.tableView, title: .emptyActivities, subtitle: .emptyActivities, priority: .medium, position: .top)
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
        activityView.tableView.beginUpdates()
        activityView.tableView.reloadRows(at: [indexPath], with: .none)
        activityView.tableView.endUpdates()
    }
    
    fileprivate func deleteCell(at indexPath: IndexPath) {
        activityView.tableView.beginUpdates()
        activityView.tableView.deleteRows(at: [indexPath], with: .none)
        activityView.tableView.endUpdates()
    }
    
    func handleReloadTable() {
        handleReloadActivities()
        let allActivities = pinnedActivities + activities
                
        saveDataToSharedContainer(activities: allActivities)
        
        if !isAppLoaded {
            UIView.transition(with: activityView.tableView, duration: 0.15, options: .transitionCrossDissolve, animations: { self.activityView.tableView.reloadData()
            }) { _ in
                self.scrollToFirstActivityWithDate(date: self.activityView.calendar.selectedDate!, within: 365)
            }
            
            
            configureTabBarBadge()
        } else {
            configureTabBarBadge()
            activityView.tableView.reloadData()
            scrollToFirstActivityWithDate(date: activityView.calendar.selectedDate!, within: 7)
        }
        
        if allActivities.count == 0 {
            checkIfThereAnyActivities(isEmpty: true)
        } else {
            checkIfThereAnyActivities(isEmpty: false)
        }
        
        guard !isAppLoaded else { return }
        delegate?.manageAppearanceActivity(self, didFinishLoadingWith: true)
        isAppLoaded = true
    }
    
    func handleReloadActivities() {
        activities.sort { (activity1, activity2) -> Bool in
            return activity1.startDateTime?.int64Value < activity2.startDateTime?.int64Value
        }
        
        pinnedActivities.sort { (activity1, activity2) -> Bool in
            return activity1.startDateTime?.int64Value < activity2.startDateTime?.int64Value
        }
        
        filteredPinnedActivities = pinnedActivities
        filteredActivities = activities
        
    }
    
    func handleReloadTableAftersearchBarCancelButtonClicked() {
        handleReloadActivities()
        self.activityView.tableView.reloadData()
    }
    
    func handleReloadTableAfterSearch() {
        filteredActivities.sort { (activity1, activity2) -> Bool in
            return activity1.startDateTime?.int64Value < activity2.startDateTime?.int64Value
        }
        
        self.activityView.tableView.reloadData()
    }
    
    func scrollToFirstActivityWithDate(date: Date, within days: Int) {
        let currentDate = date.stripTime()
        let currentDateInterval = DateInterval(start: currentDate, duration: TimeInterval(86399 * days))
        var index = 0
        var activityFound = false
        for activity in self.filteredActivities {
            if let startInterval = activity.startDateTime?.doubleValue, let endInterval = activity.endDateTime?.doubleValue {
                let startDate = Date(timeIntervalSince1970: startInterval)
                let endDate = Date(timeIntervalSince1970: endInterval)
                let activityDateInterval = DateInterval(start: startDate, end: endDate)
                if currentDateInterval.intersects(activityDateInterval) {
                    activityFound = true
                    break
                }
                
                index += 1
            }
        }
        
        let numberOfSections = activityView.tableView.numberOfSections
        if activityFound && numberOfSections > 1 {
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(300)) {
                let numberOfRows = self.activityView.tableView.numberOfRows(inSection: 1)
                if index < numberOfRows {
                    let indexPath = IndexPath(row: index, section: 1)
                    self.activityView.tableView.scrollToRow(at: indexPath, at: .top, animated: true)
                    
                }
            }
        }
    }
    
    // MARK:- UIGestureRecognizerDelegate
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        let shouldBegin = self.activityView.tableView.contentOffset.y <= -self.activityView.tableView.contentInset.top
        if shouldBegin {
            let velocity = self.scopeGesture.velocity(in: self.activityView)
            switch activityView.calendar.scope {
            case .month:
                return velocity.y <= 0
            case .week:
                return velocity.y > 0
            @unknown default:
                print("unknown default on calendar")
            }
        }
        activityView.layoutIfNeeded()
        return shouldBegin
    }
    
    // MARK: - UIScrollViewDelegate
    func scrollViewDidScroll(_ scrollView: UIScrollView)
    {
        if canTransitionToLarge && scrollView.contentOffset.y <= 0 {
            UIView.animate(withDuration: 0.5) {
                if #available(iOS 11.0, *) {
                    self.navigationItem.largeTitleDisplayMode = .always
                }
            }
            canTransitionToLarge = false
            canTransitionToSmall = true
        }
        else if canTransitionToSmall && scrollView.contentOffset.y > 0 {
            UIView.animate(withDuration: 0.5) {
                if #available(iOS 11.0, *) {
                    self.navigationItem.largeTitleDisplayMode = .never
                }
            }
            canTransitionToLarge = true
            canTransitionToSmall = false
        }
        activityView.layoutIfNeeded()
    }
    
    // MARK: - FSCalendarDelegate
    func calendar(_ calendar: FSCalendar, boundingRectWillChange bounds: CGRect, animated: Bool) {
        activityView.calendarHeightConstraint?.constant = bounds.height
        activityView.updateArrowDirection(down: calendar.scope == .week)
        activityView.layoutIfNeeded()
        saveCalendar(scope: calendar.scope)
    }
    
    func calendar(_ calendar: FSCalendar, didSelect date: Date, at monthPosition: FSCalendarMonthPosition) {
        self.scrollToFirstActivityWithDate(date: date, within: 1)
    }
    
    func calendarCurrentPageDidChange(_ calendar: FSCalendar) {
        let days = calendar.scope == .week ? 7 : 31
        self.scrollToFirstActivityWithDate(date: calendar.currentPage, within: days)
    }
    
    func saveCalendar(scope: FSCalendarScope) {
        UserDefaults.standard.setValue(scope.rawValue, forKey: kCalendarScope)
    }
    
    func getCalendarScope() -> FSCalendarScope {
        if let value = UserDefaults.standard.value(forKey: kCalendarScope) as? UInt, let scope = FSCalendarScope(rawValue: value) {
            return scope
        } else {
            // default
            return .week
        }
    }
    
    // MARK: - Table view data source
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            if filteredPinnedActivities.count == 0 {
                return ""
            }
            return " "//Pinned
        } else {
            return " "
        }
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0 {
            return 0
        } else {
            if filteredPinnedActivities.count == 0 {
                return 0
            }
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        view.tintColor = ThemeManager.currentTheme().inputTextViewColor
        if let headerTitle = view as? UITableViewHeaderFooterView {
            headerTitle.textLabel?.textColor = FalconPalette.defaultBlue
            //      headerTitle.textLabel?.font = UIFont.systemFont(ofSize: 10)
            headerTitle.textLabel?.font = UIFont.preferredFont(forTextStyle: .subheadline)
            headerTitle.textLabel?.adjustsFontForContentSizeCategory = true
            headerTitle.textLabel?.minimumScaleFactor = 0.1
            headerTitle.textLabel?.adjustsFontSizeToFitWidth = true
        }
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        
        let delete = setupDeleteAction(at: indexPath)
        let pin = setupPinAction(at: indexPath)
        let mute = setupMuteAction(at: indexPath)
        
        return [delete, pin, mute]
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return filteredPinnedActivities.count
        } else {
            return filteredActivities.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: activityCellID, for: indexPath) as? ActivityCell ?? ActivityCell()
        
        cell.delegate = self
        cell.updateInvitationDelegate = self
        cell.activityViewControllerDataStore = self
        cell.selectionStyle = .none
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
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        var activity: Activity!
        
        if indexPath.section == 0 {
            let pinnedActivity = filteredPinnedActivities[indexPath.row]
            activity = pinnedActivity
        } else {
            let unpinnedActivity = filteredActivities[indexPath.row]
            activity = unpinnedActivity
        }
        
//        self.showSpinner(onView: self.view)
        
        let destination = CreateActivityViewController()
        destination.hidesBottomBarWhenPushed = true
        destination.activity = activity
        destination.invitation = invitations[activity.activityID!]
        destination.users = users
        destination.filteredUsers = filteredUsers
        destination.conversations = conversations
        
        self.getParticipants(forActivity: activity) { (participants) in
            InvitationsFetcher.getAcceptedParticipant(forActivity: activity, allParticipants: participants) { acceptedParticipant in

//                self.removeSpinner()
                destination.acceptedParticipant = acceptedParticipant
                destination.selectedFalconUsers = participants
                self.navigationController?.pushViewController(destination, animated: true)
            }
        }
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

extension ActivityViewController: DeleteAndExitDelegate {
    
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

extension ActivityViewController: ActivityUpdatesDelegate {
    
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
        checkForDataMigration(forActivities: activities)
        
        let (pinned, unpinned) = activities.stablePartition { (element) -> Bool in
            let isPinned = element.pinned ?? false
            return isPinned == true
        }
        
        self.pinnedActivities = pinned
        self.activities = unpinned
        
        fetchInvitations()
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
    }
    
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
}

// For invitations update
extension ActivityViewController {
    func fetchInvitations() {
        invitationsFetcher.fetchInvitations { (invitations, activitiesForInvitations) in
            self.invitations = invitations
            self.invitedActivities = activitiesForInvitations
            self.handleReloadTable()
            self.navigationItemActivityIndicator.hideActivityIndicator(for: self.navigationItem, activityPriority: .mediumHigh)
            self.observeInvitationForCurrentUser()
        }
    }
    
    func observeInvitationForCurrentUser() {
        self.invitationsFetcher.observeInvitationForCurrentUser(invitationsAdded: { [weak self] invitationsAdded in
            for invitation in invitationsAdded {
                self?.invitations[invitation.activityID] = invitation
                self?.updateCellForActivityID(activityID: invitation.activityID)
            }
        }) { [weak self] (invitationsRemoved) in
            for invitation in invitationsRemoved {
                self?.invitations.removeValue(forKey: invitation.activityID)
                self?.updateCellForActivityID(activityID: invitation.activityID)
            }
        }
    }
    
    func updateCellForActivityID(activityID: String) {
        if let index = filteredActivities.firstIndex(where: {$0.activityID == activityID}) {
            let indexPath = IndexPath(row: index, section: 1)
            updateCell(at: indexPath)
        }
    }
}

extension ActivityViewController: UpdateInvitationDelegate {
    func updateInvitation(invitation: Invitation) {
        InvitationsFetcher.update(invitation: invitation) { result in
            if result {
                self.invitations[invitation.activityID] = invitation
            }
        }
    }
}

extension ActivityViewController: ActivityViewControllerDataStore {
    func getParticipants(forActivity activity: Activity, completion: @escaping ([User])->()) {
        guard let activityID = activity.activityID, let participantsIDs = activity.participantsIDs, let currentUserID = Auth.auth().currentUser?.uid else {
            return
        }

        let group = DispatchGroup()
        let olderParticipants = self.activitiesParticipants[activityID]
        var participants: [User] = []
        for id in participantsIDs {
            // Only if the current user is created this activity
            if activity.admin == currentUserID && id == currentUserID {
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
            self.activitiesParticipants[activityID] = participants
            completion(participants)
        }
    }
}

extension ActivityViewController: ActivityCellDelegate {
    func openMap(forActivity activity: Activity) {
        guard currentReachabilityStatus != .notReachable else {
            basicErrorAlertWith(title: basicErrorTitleForAlert, message: noInternetError, controller: self)
            return
        }
        
        guard let locationAddress = activity.locationAddress else {
            return
        }
        
        let destination = MapViewController()
        destination.hidesBottomBarWhenPushed = true
        destination.locationAddress = locationAddress
        
        // If we're presenting a modal sheet
        if let presentedViewController = presentedViewController as? UINavigationController {
            presentedViewController.pushViewController(destination, animated: true)
        } else {
            navigationController?.pushViewController(destination, animated: true)
        }
    }
    
    func openChat(forConversation conversationID: String?, activityID: String?) {
        if conversationID == nil {
            let activity = activities.first(where: {$0.activityID == activityID})
            let destination = ChooseChatTableViewController()
            let navController = UINavigationController(rootViewController: destination)
            destination.delegate = self
            destination.activity = activity
            destination.conversations = conversations
            destination.pinnedConversations = conversations
            destination.filteredConversations = conversations
            destination.filteredPinnedConversations = conversations
            present(navController, animated: true, completion: nil)
        } else {
            let groupChatDataReference = Database.database().reference().child("groupChats").child(conversationID!).child(messageMetaDataFirebaseFolder)
            groupChatDataReference.observeSingleEvent(of: .value, with: { (snapshot) in
                guard var dictionary = snapshot.value as? [String: AnyObject] else { return }
                dictionary.updateValue(conversationID as AnyObject, forKey: "id")
                
                if let membersIDs = dictionary["chatParticipantsIDs"] as? [String:AnyObject] {
                    dictionary.updateValue(Array(membersIDs.values) as AnyObject, forKey: "chatParticipantsIDs")
                }
                
                let conversation = Conversation(dictionary: dictionary)
                
                if conversation.chatName == nil {
                    if let activityID = activityID, let participants = self.activitiesParticipants[activityID], participants.count > 0 {
                        let user = participants[0]
                        conversation.chatName = user.name
                        conversation.chatPhotoURL = user.photoURL
                        conversation.chatThumbnailPhotoURL = user.thumbnailPhotoURL
                    }
                }
                
                self.chatLogController = ChatLogController(collectionViewLayout: AutoSizingCollectionViewFlowLayout())
                self.chatLogController?.activityID = activityID ?? ""
                self.messagesFetcher = MessagesFetcher()
                self.messagesFetcher?.delegate = self
                self.messagesFetcher?.loadMessagesData(for: conversation)
            })
        }
    }
}

extension ActivityViewController: MessagesDelegate {
    
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
        
        // If we're presenting a modal sheet
        if let presentedViewController = presentedViewController as? UINavigationController {
            presentedViewController.pushViewController(destination, animated: true)
        } else {
            navigationController?.pushViewController(destination, animated: true)
        }
        
        chatLogController = nil
        messagesFetcher?.delegate = nil
        messagesFetcher = nil
    }
}

extension ActivityViewController: UpdateChatDelegate {
    func updateChat(chatID: String, activityID: String) {
        if let conversation = conversations.first(where: {$0.chatID == chatID}) {
            if conversation.activities != nil {
                   var activities = conversation.activities!
                   activities.append(activityID)
                   let updatedActivities = ["activities": activities as AnyObject]
                   Database.database().reference().child("groupChats").child(conversation.chatID!).child(messageMetaDataFirebaseFolder).updateChildValues(updatedActivities)
               } else {
                   let updatedActivities = ["activities": [activityID] as AnyObject]
                   Database.database().reference().child("groupChats").child(conversation.chatID!).child(messageMetaDataFirebaseFolder).updateChildValues(updatedActivities)
               }
           }
        let updatedConversationID = ["conversationID": chatID as AnyObject]
        Database.database().reference().child("activities").child(activityID).child(messageMetaDataFirebaseFolder).updateChildValues(updatedConversationID)
    }
}
