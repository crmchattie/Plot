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
import CodableFirebase
import GoogleSignIn

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

protocol UpdateInvitationDelegate: class {
    func updateInvitation(invitation: Invitation)
}

protocol ActivityViewControllerDataStore: class {
    func getParticipants(forActivity activity: Activity, completion: @escaping ([User])->())
}

class ActivityViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, FSCalendarDataSource, FSCalendarDelegate, FSCalendarDelegateAppearance, UIGestureRecognizerDelegate {
    var networkController: NetworkController
    
    init(networkController: NetworkController) {
        self.networkController = networkController
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    fileprivate var isAppLoaded = false
    fileprivate let plotAppGroup = "group.immaturecreations.plot"
    fileprivate var sharedContainer : UserDefaults?
    
    let activityView = ActivityView()
            
    var searchBar: UISearchBar?
    var searchController: UISearchController?
    
    var activities: [Activity] {
        return networkController.activityService.activities
    }
    var filteredActivities = [Activity]()
    var pinnedActivities = [Activity]()
    var filteredPinnedActivities = [Activity]()
    var users: [User] {
        return networkController.userService.users
    }
    var filteredUsers: [User] {
        return networkController.userService.users
    }
    var conversations: [Conversation] {
        return networkController.conversationService.conversations
    }
    
    let viewPlaceholder = ViewPlaceholder()
    
    var canTransitionToLarge = false
    var canTransitionToSmall = true
    
    // [ActivityID: Invitation]
    var invitations: [String: Invitation] {
        return networkController.activityService.invitations
    }
    var invitedActivities: [Activity] {
        return networkController.activityService.invitedActivities
    }
    
    // [ActivityID: Participants]
    var activitiesParticipants: [String: [User]] = [:]
    
    var chatLogController: ChatLogController? = nil
    var messagesFetcher: MessagesFetcher? = nil
    
    var activityDates = [String: Int]()
    
    var hasLoadedCalendarEventActivities = false
    var categoryUpdateDispatchGroup: DispatchGroup?
    
    fileprivate lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd"
        return formatter
    }()
    
    let selectedDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
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
    
//    let closeButton: UIButton = {
//        let button = UIButton(type: .system)
//        button.setImage(UIImage(named: "close"), for: .normal)
//        button.tintColor = .systemBlue
//        button.addTarget(self, action: #selector(handleDismiss), for: .touchUpInside)
//        return button
//    }()
    
    @objc fileprivate func handleDismiss(button: UIButton) {
        dismiss(animated: true, completion: nil)
    }
                
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.largeTitleDisplayMode = .never
        
        let dateString = selectedDateFormatter.string(from: Date().localTime)
        title = dateString
        
        configureView()
        
        sharedContainer = UserDefaults(suiteName: plotAppGroup)
        addObservers()
        
        handleReloadTable()
        
        GIDSignIn.sharedInstance().delegate = self
        GIDSignIn.sharedInstance()?.presentingViewController = self
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    fileprivate func addObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(changeTheme), name: .themeUpdated, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(activitiesUpdated), name: .activitiesUpdated, object: nil)
    }
    
    @objc fileprivate func changeTheme() {
        let theme = ThemeManager.currentTheme()
        view.backgroundColor = theme.generalBackgroundColor
        activityView.tableView.indicatorStyle = theme.scrollBarStyle
        activityView.tableView.sectionIndexBackgroundColor = theme.generalBackgroundColor
        activityView.tableView.backgroundColor = theme.generalBackgroundColor
        activityView.tableView.reloadData()
        applyCalendarTheme()
    }
    
    @objc fileprivate func activitiesUpdated() {
        handleReloadTable()
    }
    
    fileprivate func applyCalendarTheme() {
        let theme = ThemeManager.currentTheme()
        activityView.calendar.backgroundColor = theme.generalBackgroundColor
        activityView.calendar.appearance.weekdayTextColor = theme.generalTitleColor
        activityView.calendar.appearance.headerTitleColor = theme.generalTitleColor
        activityView.calendar.appearance.eventDefaultColor = FalconPalette.defaultBlue
        activityView.calendar.appearance.eventSelectionColor = FalconPalette.defaultBlue
        activityView.calendar.appearance.titleDefaultColor = theme.generalTitleColor
        activityView.calendar.appearance.titleSelectionColor = theme.generalBackgroundColor
        activityView.calendar.appearance.selectionColor = theme.generalTitleColor
        activityView.calendar.appearance.todayColor = FalconPalette.defaultBlue
        activityView.calendar.appearance.todaySelectionColor = FalconPalette.defaultBlue
        activityView.arrowButton.tintColor = theme.generalTitleColor
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        guard activityView.tableView.isEditing else { return }
        activityView.tableView.endEditing(true)
        activityView.tableView.reloadData()
    }
    
    @objc func editButtonAction(sender: UIBarButtonItem) {
        if activityView.tableView.isEditing == true {
            activityView.tableView.setEditing(false, animated: true)
            sender.style = .plain
            sender.title = "Edit"
        } else {
            activityView.tableView.setEditing(true, animated: true)
            sender.style = .done
            sender.title = "Done"
        }
    }
    
    fileprivate func configureView() {
        let newItemBarButton =  UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(newItem))
        let searchBarButton =  UIBarButtonItem(barButtonSystemItem: .search, target: self, action: #selector(search))
        navigationItem.rightBarButtonItems = [newItemBarButton, searchBarButton]
        
        view.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
        
        edgesForExtendedLayout = UIRectEdge.top

        view.addSubview(activityView)
        
        activityView.translatesAutoresizingMaskIntoConstraints = false
        activityView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        activityView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        activityView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        activityView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        
        activityView.arrowButton.addTarget(self, action: #selector(arrowButtonTapped), for: .touchUpInside)
        
        activityView.tableView.separatorStyle = .none
        
        activityView.addGestureRecognizer(self.scopeGesture)
        
        activityView.calendar.dataSource = self
        activityView.calendar.delegate = self
        activityView.calendar.select(Date().localTime)
        activityView.calendar.register(FSCalendarCell.self, forCellReuseIdentifier: "cell")
        activityView.calendar.scope = getCalendarScope()
        activityView.calendar.swipeToChooseGesture.isEnabled = true // Swipe-To-Choose
        activityView.calendar.calendarHeaderView.isHidden = true
        activityView.calendar.headerHeight = 0
        activityView.calendar.appearance.headerMinimumDissolvedAlpha = 0.0
        
        let scopeGesture = UIPanGestureRecognizer(target: activityView.calendar, action: #selector(activityView.calendar.handleScopeGesture(_:)));
        activityView.calendar.addGestureRecognizer(scopeGesture)
        
        activityView.tableView.dataSource = self
        activityView.tableView.delegate = self
        activityView.tableView.register(ActivityCell.self, forCellReuseIdentifier: activityCellID)
        activityView.tableView.allowsMultipleSelectionDuringEditing = false
        activityView.tableView.indicatorStyle = ThemeManager.currentTheme().scrollBarStyle
        activityView.tableView.backgroundColor = view.backgroundColor
        activityView.tableView.rowHeight = UITableView.automaticDimension
        
        // apply theme
        applyCalendarTheme()
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return ThemeManager.currentTheme().statusBarStyle
    }
    
    @objc fileprivate func newItem() {
        if !networkController.activityService.calendars.keys.contains(icloudString) || !networkController.activityService.calendars.keys.contains(googleString) {
            let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            
            alert.addAction(UIAlertAction(title: "Event", style: .default, handler: { (_) in
                let calendar = Calendar.current
                var dateComponents = calendar.dateComponents([.day, .month, .year], from: self.activityView.calendar.selectedDate ?? Date())
                dateComponents.hour = calendar.component(.hour, from: Date())
                dateComponents.minute = calendar.component(.minute, from: Date())
                
                let destination = CreateActivityViewController()
                destination.users = self.networkController.userService.users
                destination.filteredUsers = self.networkController.userService.users
                destination.startDateTime = calendar.date(from: dateComponents)
                destination.endDateTime = calendar.date(from: dateComponents)
                let navigationViewController = UINavigationController(rootViewController: destination)
                self.present(navigationViewController, animated: true, completion: nil)
            }))
            
            alert.addAction(UIAlertAction(title: "Calendar", style: .default, handler: { (_) in
                self.newCalendar()
            }))
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (_) in
                print("User click Dismiss button")
            }))
            
            self.present(alert, animated: true, completion: {
                print("completion block")
            })
        } else {
            let calendar = Calendar.current
            var dateComponents = calendar.dateComponents([.day, .month, .year], from: self.activityView.calendar.selectedDate ?? Date())
            dateComponents.hour = calendar.component(.hour, from: Date())
            dateComponents.minute = calendar.component(.minute, from: Date())
            
            let destination = CreateActivityViewController()
            destination.users = self.networkController.userService.users
            destination.filteredUsers = self.networkController.userService.users
            destination.startDateTime = calendar.date(from: dateComponents)
            destination.endDateTime = calendar.date(from: dateComponents)
            let navigationViewController = UINavigationController(rootViewController: destination)
            self.present(navigationViewController, animated: true, completion: nil)
        }
    }
    
    @objc func newCalendar() {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        if !networkController.activityService.calendars.keys.contains(icloudString) {
            alert.addAction(UIAlertAction(title: icloudString, style: .default, handler: { (_) in
                self.networkController.activityService.updatePrimaryCalendar(value: googleString)
            }))
        }
        
        if !networkController.activityService.calendars.keys.contains(googleString) {
            alert.addAction(UIAlertAction(title: "Google", style: .default, handler: { (_) in
                GIDSignIn.sharedInstance()?.signIn()
            }))
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (_) in
            print("User click Dismiss button")
        }))
        
        self.present(alert, animated: true, completion: {
            print("completion block")
        })
    }
    
    @objc fileprivate func search() {
        setupSearchController()
    }
    
    // MARK:- action: Selectors
    
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
            self.activityView.calendarHeightConstraint?.constant = 0
            self.activityView.layoutIfNeeded()
        }) { result in
            self.activityView.calendar.isHidden = true
        }
    }
    
    func setupSearchController() {
        activityView.tableView.setContentOffset(.zero, animated: false)
        searchBar = UISearchBar()
        searchBar?.delegate = self
        searchBar?.placeholder = "Search"
        searchBar?.searchBarStyle = .minimal
        searchBar?.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: 50)
        searchBar?.becomeFirstResponder()
        searchBar?.showsCancelButton = true
        activityView.tableView.tableHeaderView = searchBar
    }
    
    func checkIfThereAnyActivities(isEmpty: Bool) {
        guard isEmpty else {
            viewPlaceholder.remove(from: activityView.tableView, priority: .medium)
            return
        }
        viewPlaceholder.add(for: activityView.tableView, title: .emptyActivities, subtitle: .emptyActivities, priority: .medium, position: .top)
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
        guard !isAppLoaded else { return }
        isAppLoaded = true
        
        let allActivities = pinnedActivities + activities
        saveDataToSharedContainer(activities: allActivities)
        compileActivityDates(activities: allActivities)
        handleReloadActivities()
        
    }
    
    func handleReloadActivities() {
        let startDate = activityView.calendar.selectedDate?.startOfDay
        let endDate = activityView.calendar.selectedDate?.endOfDay
        filteredActivities = activities.filter({ (activity) -> Bool in
            if let activityStartDate = activity.startDate, let activityEndDate = activity.endDate {
                if activityStartDate > startDate && endDate > activityStartDate {
                    return true
                } else if activityEndDate.timeIntervalSince(activityStartDate) > 86399 && activityEndDate > startDate && endDate > activityEndDate {
                    return true
                } else if startDate > activityStartDate && activityEndDate > endDate {
                    return true
                }
            }
            return false
        })
        
        activityView.tableView.reloadData()
    }
    
    func handleReloadTableAftersearchBarCancelButtonClicked() {
        handleReloadActivities()
    }
    
    func handleReloadTableAfterSearch() {
        filteredPinnedActivities.sort { (activity1, activity2) -> Bool in
            return activity1.startDateTime?.int64Value < activity2.startDateTime?.int64Value
        }
        
        filteredActivities.sort { (activity1, activity2) -> Bool in
            return activity1.startDateTime?.int64Value < activity2.startDateTime?.int64Value
        }
        
        self.activityView.tableView.reloadData()
    }
    
    func scrollToFirstActivityWithDate(date: Date, animated: Bool) {
        var index = 0
        var activityFound = false
        var calendar = Calendar.current
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        for activity in self.filteredActivities {
            if let endDate = activity.endDateWTZ {
                if (date < endDate) || (activity.allDay ?? false && calendar.compare(date, to: endDate, toGranularity: .day) != .orderedDescending) {
                    activityFound = true
                    break
                }
                index += 1
            }
        }
                
        let numberOfSections = activityView.tableView.numberOfSections
        if activityFound && numberOfSections > 1 {
            let numberOfRows = self.activityView.tableView.numberOfRows(inSection: 1)
            if index < numberOfRows {
                let indexPath = IndexPath(row: index, section: 1)
                self.activityView.tableView.scrollToRow(at: indexPath, at: .top, animated: animated)
                if !animated {
                    self.activityView.tableView.reloadRows(at: [indexPath], with: .none)
                }
            }
        } else if !activityFound {
            let numberOfRows = self.activityView.tableView.numberOfRows(inSection: 1)
            if numberOfRows > 0 {
                let indexPath = IndexPath(row: numberOfRows - 1, section: 1)
                self.activityView.tableView.scrollToRow(at: indexPath, at: .top, animated: animated)
                if !animated {
                    self.activityView.tableView.reloadRows(at: [indexPath], with: .none)
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
            canTransitionToLarge = false
            canTransitionToSmall = true
        }
        else if canTransitionToSmall && scrollView.contentOffset.y > 0 {
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
        let dateString = selectedDateFormatter.string(from: date)
        title = dateString
        self.handleReloadActivities()
    }
    
    func calendarCurrentPageDidChange(_ calendar: FSCalendar) {
        let dateString = selectedDateFormatter.string(from: calendar.currentPage)
        title = dateString
        self.handleReloadActivities()
    }
    
    func saveCalendar(scope: FSCalendarScope) {
        UserDefaults.standard.setValue(scope.rawValue, forKey: kCalendarScope)
    }
    
    func getCalendarScope() -> FSCalendarScope {
        if let value = UserDefaults.standard.value(forKey: kCalendarScope) as? UInt, let scope = FSCalendarScope(rawValue: value) {
            return scope
        } else {
            return .week
        }
    }
    
    func calendar(_ calendar: FSCalendar, numberOfEventsFor date: Date) -> Int {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy/MM/dd"
        let dateString = dateFormatter.string(from: date)
        if let value = activityDates[dateString] {
            return value
        }
        return 0
    }
    
    // MARK: - Table view data source
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return UIView()
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let delete = setupDeleteAction(at: indexPath)
        //        let pin = setupPinAction(at: indexPath)
        let mute = setupMuteAction(at: indexPath)
        
        return [delete, mute]
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if filteredPinnedActivities.count == 0 && filteredActivities.count == 0 {
            checkIfThereAnyActivities(isEmpty: true)
        } else {
            checkIfThereAnyActivities(isEmpty: false)
        }
        
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
        loadActivity(activity: activity)
    }
    
    func loadActivity(activity: Activity) {
        let dispatchGroup = DispatchGroup()
        showActivityIndicator()
        
        if let recipeString = activity.recipeID, let recipeID = Int(recipeString) {
            dispatchGroup.enter()
            Service.shared.fetchRecipesInfo(id: recipeID) { (search, err) in
                if let detailedRecipe = search {
                    dispatchGroup.leave()
                    dispatchGroup.notify(queue: .main) {
                        let destination = RecipeDetailViewController()
                        destination.hidesBottomBarWhenPushed = true
                        destination.recipe = detailedRecipe
                        destination.detailedRecipe = detailedRecipe
                        destination.activity = activity
                        destination.invitation = self.invitations[activity.activityID!]
                        destination.users = self.users
                        destination.filteredUsers = self.filteredUsers
                        destination.activities = self.filteredActivities + self.filteredPinnedActivities
                        destination.conversations = self.conversations
                        self.getParticipants(forActivity: activity) { (participants) in
                            InvitationsFetcher.getAcceptedParticipant(forActivity: activity, allParticipants: participants) { acceptedParticipant in
                                destination.acceptedParticipant = acceptedParticipant
                                destination.selectedFalconUsers = participants
                                self.hideActivityIndicator()
                                self.navigationController?.pushViewController(destination, animated: true)
                            }
                        }
                    }
                } else {
                    dispatchGroup.leave()
                    dispatchGroup.notify(queue: .main) {
                        self.hideActivityIndicator()
                        self.activityNotFoundAlert()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: {
                            self.dismiss(animated: true, completion: nil)
                        })
                    }
                }
            }
        } else if let eventID = activity.eventID {
            dispatchGroup.enter()
            Service.shared.fetchEventsSegment(size: "50", id: eventID, keyword: "", attractionId: "", venueId: "", postalCode: "", radius: "", unit: "", startDateTime: "", endDateTime: "", city: "", stateCode: "", countryCode: "", classificationName: "", classificationId: "") { (search, err) in
                if let events = search?.embedded?.events {
                    let event = events[0]
                    dispatchGroup.leave()
                    dispatchGroup.notify(queue: .main) {
                        print("\(eventID)")
                        let destination = EventDetailViewController()
                        destination.hidesBottomBarWhenPushed = true
                        destination.event = event
                        destination.activity = activity
                        destination.invitation = self.invitations[activity.activityID!]
                        destination.users = self.users
                        destination.filteredUsers = self.filteredUsers
                        destination.activities = self.filteredActivities + self.filteredPinnedActivities
                        destination.conversations = self.conversations
                        self.getParticipants(forActivity: activity) { (participants) in
                            InvitationsFetcher.getAcceptedParticipant(forActivity: activity, allParticipants: participants) { acceptedParticipant in
                                print("\(eventID)")
                                destination.acceptedParticipant = acceptedParticipant
                                destination.selectedFalconUsers = participants
                                self.hideActivityIndicator()
                                self.navigationController?.pushViewController(destination, animated: true)
                            }
                        }
                    }
                } else {
                    dispatchGroup.leave()
                    dispatchGroup.notify(queue: .main) {
                        self.hideActivityIndicator()
                        self.activityNotFoundAlert()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: {
                            self.dismiss(animated: true, completion: nil)
                        })
                    }
                }
            }
        } else if let workoutID = activity.workoutID {
            var reference = Database.database().reference()
            dispatchGroup.enter()
            reference = Database.database().reference().child("workouts").child("workouts")
            reference.child(workoutID).observeSingleEvent(of: .value, with: { (snapshot) in
                if snapshot.exists(), let workoutSnapshotValue = snapshot.value {
                    if let workout = try? FirebaseDecoder().decode(PreBuiltWorkout.self, from: workoutSnapshotValue) {
                        dispatchGroup.leave()
                        let destination = WorkoutDetailViewController()
                        destination.hidesBottomBarWhenPushed = true
                        destination.workout = workout
                        destination.intColor = 0
                        destination.activity = activity
                        destination.invitation = self.invitations[activity.activityID!]
                        destination.users = self.users
                        destination.filteredUsers = self.filteredUsers
                        destination.activities = self.filteredActivities + self.filteredPinnedActivities
                        destination.conversations = self.conversations
                        self.getParticipants(forActivity: activity) { (participants) in
                            InvitationsFetcher.getAcceptedParticipant(forActivity: activity, allParticipants: participants) { acceptedParticipant in
                                destination.acceptedParticipant = acceptedParticipant
                                destination.selectedFalconUsers = participants
                                self.hideActivityIndicator()
                                self.navigationController?.pushViewController(destination, animated: true)
                            }
                        }
                    }
                }
            })
            { (error) in
                print(error.localizedDescription)
            }
        } else if let attractionID = activity.attractionID {
            dispatchGroup.enter()
            Service.shared.fetchAttractionsSegment(size: "50", id: attractionID, keyword: "", classificationName: "", classificationId: "") { (search, err) in
                if let attraction = search?.embedded?.attractions![0] {
                    dispatchGroup.leave()
                    dispatchGroup.notify(queue: .main) {
                        let destination = EventDetailViewController()
                        destination.hidesBottomBarWhenPushed = true
                        destination.attraction = attraction
                        destination.activity = activity
                        destination.invitation = self.invitations[activity.activityID!]
                        destination.users = self.users
                        destination.filteredUsers = self.filteredUsers
                        destination.activities = self.filteredActivities + self.filteredPinnedActivities
                        destination.conversations = self.conversations
                        self.getParticipants(forActivity: activity) { (participants) in
                            InvitationsFetcher.getAcceptedParticipant(forActivity: activity, allParticipants: participants) { acceptedParticipant in
                                destination.acceptedParticipant = acceptedParticipant
                                destination.selectedFalconUsers = participants
                                self.hideActivityIndicator()
                                self.navigationController?.pushViewController(destination, animated: true)
                            }
                        }
                    }
                } else {
                    dispatchGroup.leave()
                    dispatchGroup.notify(queue: .main) {
                        self.hideActivityIndicator()
                        self.activityNotFoundAlert()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: {
                            self.dismiss(animated: true, completion: nil)
                        })
                    }
                }
            }
        } else if let placeID = activity.placeID {
            dispatchGroup.enter()
            Service.shared.fetchFSDetails(id: placeID) { (search, err) in
                if let place = search?.response?.venue {
                    dispatchGroup.leave()
                    dispatchGroup.notify(queue: .main) {
                        let destination = PlaceDetailViewController()
                        destination.hidesBottomBarWhenPushed = true
                        destination.place = place
                        destination.activity = activity
                        destination.invitation = self.invitations[activity.activityID!]
                        destination.users = self.users
                        destination.filteredUsers = self.filteredUsers
                        destination.activities = self.filteredActivities + self.filteredPinnedActivities
                        destination.conversations = self.conversations
                        self.getParticipants(forActivity: activity) { (participants) in
                            InvitationsFetcher.getAcceptedParticipant(forActivity: activity, allParticipants: participants) { acceptedParticipant in
                                destination.acceptedParticipant = acceptedParticipant
                                destination.selectedFalconUsers = participants
                                self.hideActivityIndicator()
                                self.navigationController?.pushViewController(destination, animated: true)
                            }
                        }
                    }
                } else {
                    dispatchGroup.leave()
                    dispatchGroup.notify(queue: .main) {
                        self.hideActivityIndicator()
                        self.activityNotFoundAlert()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: {
                            self.dismiss(animated: true, completion: nil)
                        })
                    }
                }
            }
        } else {
            self.hideActivityIndicator()
            let destination = CreateActivityViewController()
            destination.hidesBottomBarWhenPushed = true
            destination.activity = activity
            destination.invitation = invitations[activity.activityID ?? ""]
            destination.users = users
            destination.filteredUsers = filteredUsers
            destination.activities = filteredActivities + filteredPinnedActivities
            destination.conversations = conversations
            self.getParticipants(forActivity: activity) { (participants) in
                InvitationsFetcher.getAcceptedParticipant(forActivity: activity, allParticipants: participants) { acceptedParticipant in
                    destination.acceptedParticipant = acceptedParticipant
                    destination.selectedFalconUsers = participants
                    self.navigationController?.pushViewController(destination, animated: true)
                }
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
    
    fileprivate func compileActivityDates(activities: [Activity]) {
        activityDates = [String: Int]()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy/MM/dd"
        let dispatchGroup = DispatchGroup()
        for activity in activities {
            dispatchGroup.enter()
            dateFormatter.timeZone = TimeZone(identifier: activity.startTimeZone ?? "UTC")
            if let startDate = activity.startDate, let endDate = activity.endDate {
                if activity.allDay ?? false && endDate.timeIntervalSince(startDate) < 86399 {
                    activityDates[dateFormatter.string(from: startDate), default: 0] += 1
                } else {
                    let dayDurationInSeconds: TimeInterval = 86399
                    for activityDate in stride(from: startDate, to: endDate, by: dayDurationInSeconds) {
                        activityDates[dateFormatter.string(from: activityDate), default: 0] += 1
                    }
                }
                dispatchGroup.leave()
            }
        }
        dispatchGroup.notify(queue: .main) {
            self.activityView.calendar.reloadData()
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

extension ActivityViewController: UpdateInvitationDelegate {
    func updateInvitation(invitation: Invitation) {
        InvitationsFetcher.update(invitation: invitation) { result in
            if result {
                self.networkController.activityService.invitations[invitation.activityID] = invitation
                NotificationCenter.default.post(name: .activitiesUpdated, object: nil)
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
        
        guard activity.locationAddress != nil else {
            return
        }
        
        var locations = [activity]
        
        if activity.schedule != nil {
            var scheduleList = [Activity]()
            var locationAddress = [String : [Double]]()
            locationAddress = activity.locationAddress!
            for schedule in activity.schedule! {
                if schedule.name == "nothing" { continue }
                scheduleList.append(schedule)
                guard let localAddress = schedule.locationAddress else { continue }
                for (key, value) in localAddress {
                    locationAddress[key] = value
                }
            }
            locations.append(contentsOf: scheduleList)
        }
        
        let destination = MapViewController()
        destination.hidesBottomBarWhenPushed = true
        destination.sections = [.activity]
        destination.locations = [.activity: locations]
        navigationController?.pushViewController(destination, animated: true)
    
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
        chatLogController?.deleteAndExitDelegate = self
        //chatLogController?.activityID = activityID
        
        if let membersIDs = conversation.chatParticipantsIDs, let uid = Auth.auth().currentUser?.uid, membersIDs.contains(uid) {
            chatLogController?.observeTypingIndicator()
            chatLogController?.configureTitleViewWithOnlineStatus()
        }
        
        chatLogController?.messagesFetcher.collectionDelegate = chatLogController
        guard let destination = chatLogController else { return }
        self.chatLogController?.startCollectionViewAtBottom()
        
        self.navigationController?.pushViewController(destination, animated: true)
        
        chatLogController = nil
        messagesFetcher?.delegate = nil
        messagesFetcher = nil
    }
}

extension ActivityViewController: ChooseChatDelegate {
    func chosenChat(chatID: String, activityID: String?, grocerylistID: String?, checklistID: String?, packinglistID: String?, activitylistID: String?) {
        if let activityID = activityID {
            let updatedConversationID = ["conversationID": chatID as AnyObject]
            Database.database().reference().child("activities").child(activityID).child(messageMetaDataFirebaseFolder).updateChildValues(updatedConversationID)

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
                if let index = activities.firstIndex(where: {$0.activityID == activityID}) {
                    let activity = activities[index]
                    if activity.grocerylistID != nil {
                        if conversation.grocerylists != nil {
                            var grocerylists = conversation.grocerylists!
                            grocerylists.append(activity.grocerylistID!)
                            let updatedGrocerylists = [grocerylistsEntity: grocerylists as AnyObject]
                            Database.database().reference().child("groupChats").child(conversation.chatID!).child(messageMetaDataFirebaseFolder).updateChildValues(updatedGrocerylists)
                        } else {
                            let updatedGrocerylists = [grocerylistsEntity: [activity.grocerylistID!] as AnyObject]
                            Database.database().reference().child("groupChats").child(conversation.chatID!).child(messageMetaDataFirebaseFolder).updateChildValues(updatedGrocerylists)
                        }
                        Database.database().reference().child(grocerylistsEntity).child(activity.grocerylistID!).updateChildValues(updatedConversationID)
                    }
                    if activity.checklistIDs != nil {
                        if conversation.checklists != nil {
                            let checklists = conversation.checklists! + activity.checklistIDs!
                            let updatedChecklists = [checklistsEntity: checklists as AnyObject]
                            Database.database().reference().child("groupChats").child(conversation.chatID!).child(messageMetaDataFirebaseFolder).updateChildValues(updatedChecklists)
                        } else {
                            let updatedChecklists = [checklistsEntity: activity.checklistIDs! as AnyObject]
                            Database.database().reference().child("groupChats").child(conversation.chatID!).child(messageMetaDataFirebaseFolder).updateChildValues(updatedChecklists)
                        }
                        for ID in activity.checklistIDs! {
                            Database.database().reference().child(checklistsEntity).child(ID).updateChildValues(updatedConversationID)

                        }
                    }
                    if activity.packinglistIDs != nil {
                        if conversation.packinglists != nil {
                            let packinglists = conversation.packinglists! + activity.packinglistIDs!
                            let updatedPackinglists = [packinglistsEntity: packinglists as AnyObject]
                            Database.database().reference().child("groupChats").child(conversation.chatID!).child(messageMetaDataFirebaseFolder).updateChildValues(updatedPackinglists)
                        } else {
                            let updatedPackinglists = [packinglistsEntity: activity.packinglistIDs! as AnyObject]
                            Database.database().reference().child("groupChats").child(conversation.chatID!).child(messageMetaDataFirebaseFolder).updateChildValues(updatedPackinglists)
                        }
                       for ID in activity.packinglistIDs! {
                            Database.database().reference().child(packinglistsEntity).child(ID).updateChildValues(updatedConversationID)

                        }
                    }
                }
            }
            self.connectedToChatAlert()
            self.dismiss(animated: true, completion: nil)
        }
    }
}

extension ActivityViewController: GIDSignInDelegate {
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        if (error == nil) {
            self.networkController.activityService.updatePrimaryCalendar(value: googleString)
        } else {
          print("\(error.localizedDescription)")
        }
    }
}
