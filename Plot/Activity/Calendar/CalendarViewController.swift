//
//  CalendarViewController.swift
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
import FSCalendar

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

protocol UpdateInvitationDelegate: AnyObject {
    func updateInvitation(invitation: Invitation)
}

class CalendarViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, FSCalendarDataSource, FSCalendarDelegate, FSCalendarDelegateAppearance, UIGestureRecognizerDelegate, ObjectDetailShowing {
    var networkController: NetworkController
    
    init(networkController: NetworkController) {
        self.networkController = networkController
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
        
    let activityView = CalendarView()
    
    var searchBar: UISearchBar?
    var searchController: UISearchController?
    
    var activities: [Activity] {
        return networkController.activityService.calendarActivities
    }
    
    var filteredActivities = [Activity]()
    var pinnedActivities = [Activity]()
    var filteredPinnedActivities = [Activity]()
    lazy var users: [User] = networkController.userService.users
    lazy var filteredUsers: [User] = networkController.userService.users
    lazy var conversations: [Conversation] = networkController.conversationService.conversations
    
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
    var participants: [String: [User]] = [:]
    
    var activityDates = [String: Int]()
    
    var hasLoadedCalendarEventActivities = false
    var categoryUpdateDispatchGroup: DispatchGroup?
    
    var calendarViewFilter: CalendarViewFilter = .list
    var filters: [filter] = [.search, .calendarView, .calendarCategory]
    var filterDictionary = [String: [String]]()
    
    var selectedDate = Date().localTime
    
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
    
    let refreshControl = UIRefreshControl()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.largeTitleDisplayMode = .never
        
        let dateString = selectedDateFormatter.string(from: selectedDate)
        title = dateString
        
        configureView()
        
        addObservers()
        
        handleReloadTable()
        
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    fileprivate func addObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(calendarActivitiesUpdated), name: .calendarActivitiesUpdated, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(invitationsUpdated), name: .invitationsUpdated, object: nil)
    }
    
    @objc fileprivate func calendarActivitiesUpdated() {
        filteredPinnedActivities = pinnedActivities
        filteredActivities = activities
        if filterDictionary["search"] != nil || filterDictionary["calendarCategory"] != nil {
            updateTableViewWFilters()
        } else {
            activityView.tableView.reloadData()
        }
    }
    
    @objc fileprivate func invitationsUpdated() {
        activityView.tableView.reloadData()
    }
    
    fileprivate func applyCalendarTheme() {
        activityView.calendar.backgroundColor = .systemGroupedBackground
        activityView.calendar.appearance.weekdayTextColor = .label
        activityView.calendar.appearance.headerTitleColor = .label
        activityView.calendar.appearance.eventDefaultColor = FalconPalette.defaultBlue
        activityView.calendar.appearance.eventSelectionColor = FalconPalette.defaultBlue
        activityView.calendar.appearance.titleDefaultColor = .label
        activityView.calendar.appearance.titleSelectionColor = .systemGroupedBackground
        activityView.calendar.appearance.selectionColor = .label
        activityView.calendar.appearance.todayColor = FalconPalette.defaultBlue
        activityView.calendar.appearance.todaySelectionColor = FalconPalette.defaultBlue
        activityView.arrowButton.tintColor = .label
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
        extendedLayoutIncludesOpaqueBars = true
        let newItemBarButton =  UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(newItem))
        let filterBarButton = UIBarButtonItem(image: UIImage(named: "filter"), style: .plain, target: self, action: #selector(filter))
        navigationItem.rightBarButtonItems = [newItemBarButton, filterBarButton]
        
        refreshControl.addTarget(self, action: #selector(refreshControlAction(_:)), for: UIControl.Event.valueChanged)
        activityView.tableView.refreshControl = refreshControl
        
        view.backgroundColor = .systemGroupedBackground
        
        edgesForExtendedLayout = UIRectEdge.top
        
        view.addSubview(activityView)
        
        activityView.translatesAutoresizingMaskIntoConstraints = false
        activityView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
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
        
        calendarViewFilter = getCalendarView()
        
        activityView.tableView.dataSource = self
        activityView.tableView.delegate = self
        activityView.tableView.register(EventCell.self, forCellReuseIdentifier: eventCellID)
        activityView.tableView.register(TaskCell.self, forCellReuseIdentifier: taskCellID)
        activityView.tableView.allowsMultipleSelectionDuringEditing = false
        activityView.tableView.indicatorStyle = .default
        activityView.tableView.backgroundColor = view.backgroundColor
        activityView.tableView.rowHeight = UITableView.automaticDimension
        
        // apply theme
        applyCalendarTheme()
    }
    
    @objc fileprivate func newItem() {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "Event", style: .default, handler: { (_) in
            let calendar = Calendar.current
            var dateComponents = calendar.dateComponents([.day, .month, .year], from: self.selectedDate)
            dateComponents.hour = calendar.component(.hour, from: Date())
            dateComponents.minute = calendar.component(.minute, from: Date())
            self.showEventDetailPresent(event: nil, updateDiscoverDelegate: nil, delegate: nil, task: nil, transaction: nil, workout: nil, mindfulness: nil, template: nil, users: nil, container: nil, startDateTime: calendar.date(from: dateComponents), endDateTime: calendar.date(from: dateComponents))
        }))
        
        alert.addAction(UIAlertAction(title: "Task", style: .default, handler: { (_) in
            let calendar = Calendar.current
            var dateComponents = calendar.dateComponents([.day, .month, .year], from: self.selectedDate)
            dateComponents.hour = calendar.component(.hour, from: Date())
            dateComponents.minute = calendar.component(.minute, from: Date())
            self.showTaskDetailPresent(task: nil, updateDiscoverDelegate: nil, delegate: nil, event: nil, transaction: nil, workout: nil, mindfulness: nil, template: nil, users: nil, container: nil, list: nil, startDateTime: nil, endDateTime: calendar.date(from: dateComponents))
        }))
        
        alert.addAction(UIAlertAction(title: "Calendar", style: .default, handler: { (_) in
            self.showCalendarDetailPresent(calendar: nil, updateDiscoverDelegate: nil)
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (_) in
            print("User click Dismiss button")
        }))
        
        self.present(alert, animated: true, completion: {
            print("completion block")
        })
    }
    
    @objc func newCalendar() {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        if !networkController.activityService.calendars.keys.contains(CalendarSourceOptions.apple.name) {
            alert.addAction(UIAlertAction(title: CalendarSourceOptions.apple.name, style: .default, handler: { (_) in
                self.networkController.activityService.updatePrimaryCalendar(value: CalendarSourceOptions.apple.name)
            }))
        }
        
        if !networkController.activityService.calendars.keys.contains(CalendarSourceOptions.google.name) {
            alert.addAction(UIAlertAction(title: CalendarSourceOptions.google.name, style: .default, handler: { (_) in
                GIDSignIn.sharedInstance().delegate = self
                GIDSignIn.sharedInstance()?.presentingViewController = self
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
    
    @objc fileprivate func filter() {
        filterDictionary["calendarView"] = [calendarViewFilter.rawValue.capitalized]
        let destination = FilterViewController(networkController: networkController)
        let navigationViewController = UINavigationController(rootViewController: destination)
        destination.delegate = self
        destination.filters = filters
        destination.filterDictionary = filterDictionary
        self.present(navigationViewController, animated: true, completion: nil)
    }
    
    @objc func refreshControlAction(_ refreshControl: UIRefreshControl) {
        networkController.activityService.regrabEvents {
            DispatchQueue.main.async {
                self.filteredPinnedActivities = self.pinnedActivities
                self.filteredActivities = self.activities
                self.activityView.tableView.reloadData()
                self.refreshControl.endRefreshing()
            }
        }
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
        viewPlaceholder.add(for: activityView.tableView, title: .emptyEvents, subtitle: .emptyTasksEvents, priority: .medium, position: .top)
    }
    
    func handleReloadTable() {
        filteredPinnedActivities = pinnedActivities
        filteredActivities = activities
        let allActivities = pinnedActivities + activities
        compileActivityDates(activities: allActivities)
        activityView.tableView.layoutIfNeeded()
        handleReloadActivities(animated: false)
    }
    
    func handleReloadActivities(animated: Bool) {
        if calendarViewFilter == .list {
            scrollToFirstActivityWithDate(animated: animated)
        } else {
            filterEvents()
        }
    }
    
    func scrollToFirstActivityWithDate(animated: Bool) {
        let date = selectedDate
        var index = 0
        var activityFound = false
        for activity in self.filteredActivities {
            if let endDate = activity.endDate?.localTime {
                if date < endDate {
                    activityFound = true
                    break
                }
                index += 1
            }
        }
        
        if activityFound {
            let numberOfRows = self.activityView.tableView.numberOfRows(inSection: 1)
            if index < numberOfRows {
                let indexPath = IndexPath(row: index, section: 1)
                self.activityView.tableView.scrollToRow(at: indexPath, at: .top, animated: animated)
                if !animated {
                    self.activityView.tableView.reloadData()
                }
            }
        } else if !activityFound {
            let numberOfRows = self.activityView.tableView.numberOfRows(inSection: 1)
            if numberOfRows > 0 {
                let indexPath = IndexPath(row: numberOfRows - 1, section: 1)
                self.activityView.tableView.scrollToRow(at: indexPath, at: .top, animated: animated)
                if !animated {
                    self.activityView.tableView.reloadData()
                }
            }
        }
    }
    
    func filterEvents() {
        let startDate = selectedDate.startOfDay
        let endDate = selectedDate.endOfDay
        filteredPinnedActivities = pinnedActivities.filter({ (activity) -> Bool in
            if let activityStartDate = activity.startDate, activityStartDate > startDate, endDate > activityStartDate {
                return true
            } else if let activityEndDate = activity.endDate, activityEndDate > startDate,  endDate > activityEndDate {
                if activity.allDay ?? false, let activityStartDate = activity.startDate, Calendar.current.dateComponents([.hour], from: activityStartDate, to: activityEndDate).hour > 22 {
                    return false
                }
                return true
            } else if let activityStartDate = activity.startDate, let activityEndDate = activity.endDate, startDate > activityStartDate, activityEndDate > endDate {
                return true
            }
            return false
        })
        filteredActivities = activities.filter({ (activity) -> Bool in
            if let activityStartDate = activity.startDate, activityStartDate > startDate, endDate > activityStartDate {
                return true
            } else if let activityEndDate = activity.endDate, activityEndDate > startDate,  endDate > activityEndDate {
                if activity.allDay ?? false, let activityStartDate = activity.startDate, Calendar.current.dateComponents([.hour], from: activityStartDate, to: activityEndDate).hour > 22 {
                    return false
                }
                return true
            } else if let activityStartDate = activity.startDate, let activityEndDate = activity.endDate, startDate > activityStartDate, activityEndDate > endDate {
                return true
            }
            return false
        })
        self.activityView.tableView.reloadData()
    }
    
    func handleReloadTableAftersearchBarCancelButtonClicked() {
        handleReloadActivities(animated: true)
    }
    
    func handleReloadTableAfterSearch() {
        let currentDate = Date().localTime
        filteredPinnedActivities.sort { (activity1, activity2) -> Bool in
            if let startDate1 = activity1.startDate, let endDate1 = activity1.endDate, let startDate2 = activity2.startDate, let endDate2 = activity2.endDate {
                if currentDate.isBetween(startDate1, and: endDate1) && currentDate.isBetween(startDate2, and: endDate2) {
                    return startDate1 < startDate2
                } else if currentDate.isBetween(startDate1, and: endDate1) {
                    return currentDate < startDate2
                } else if currentDate.isBetween(startDate2, and: endDate2) {
                    return startDate1 < currentDate
                }
            } else if let startDate1 = activity1.startDate, let endDate1 = activity1.endDate, let finalDate2 = activity2.finalDate {
                if currentDate.isBetween(startDate1, and: endDate1) {
                    return currentDate < finalDate2
                }
                return startDate1 < finalDate2
            } else if let finalDate1 = activity1.finalDate, let startDate2 = activity2.startDate, let endDate2 = activity2.endDate {
                if currentDate.isBetween(startDate2, and: endDate2) {
                    return finalDate1 < currentDate
                }
                return finalDate1 < startDate2
            }
            if activity1.finalDate == activity2.finalDate {
                return activity1.name ?? "" < activity2.name ?? ""
            }
            return activity1.finalDate ?? Date.distantPast < activity2.finalDate ?? Date.distantPast
        }
        
        filteredActivities.sort { (activity1, activity2) -> Bool in
            if let startDate1 = activity1.startDate, let endDate1 = activity1.endDate, let startDate2 = activity2.startDate, let endDate2 = activity2.endDate {
                if currentDate.isBetween(startDate1, and: endDate1) && currentDate.isBetween(startDate2, and: endDate2) {
                    return startDate1 < startDate2
                } else if currentDate.isBetween(startDate1, and: endDate1) {
                    return currentDate < startDate2
                } else if currentDate.isBetween(startDate2, and: endDate2) {
                    return startDate1 < currentDate
                }
            } else if let startDate1 = activity1.startDate, let endDate1 = activity1.endDate, let finalDate2 = activity2.finalDate {
                if currentDate.isBetween(startDate1, and: endDate1) {
                    return currentDate < finalDate2
                }
                return startDate1 < finalDate2
            } else if let finalDate1 = activity1.finalDate, let startDate2 = activity2.startDate, let endDate2 = activity2.endDate {
                if currentDate.isBetween(startDate2, and: endDate2) {
                    return finalDate1 < currentDate
                }
                return finalDate1 < startDate2
            }
            if activity1.finalDate == activity2.finalDate {
                return activity1.name ?? "" < activity2.name ?? ""
            }
            return activity1.finalDate ?? Date.distantPast < activity2.finalDate ?? Date.distantPast
        }
        
        self.activityView.tableView.reloadData()
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
        saveCalendarScope(scope: calendar.scope)
    }
    
    func calendar(_ calendar: FSCalendar, didSelect date: Date, at monthPosition: FSCalendarMonthPosition) {
        self.selectedDate = date
        let dateString = selectedDateFormatter.string(from: self.selectedDate)
        title = dateString
        handleReloadActivities(animated: true)
    }
    
    func calendarCurrentPageDidChange(_ calendar: FSCalendar) {
        self.selectedDate = calendar.currentPage
        let dateString = selectedDateFormatter.string(from: self.selectedDate)
        title = dateString
        handleReloadActivities(animated: true)
    }
    
    func saveCalendarScope(scope: FSCalendarScope) {
        UserDefaults.standard.setValue(scope.rawValue, forKey: kCalendarScope)
    }
    
    func getCalendarScope() -> FSCalendarScope {
        if let value = UserDefaults.standard.value(forKey: kCalendarScope) as? UInt, let scope = FSCalendarScope(rawValue: value) {
            return scope
        } else {
            return .week
        }
    }
    
    func saveCalendarView() {
        UserDefaults.standard.setValue(calendarViewFilter.rawValue, forKey: kCalendarView)
    }
    
    func getCalendarView() -> CalendarViewFilter {
        if let value = UserDefaults.standard.value(forKey: kCalendarView) as? String, let view = CalendarViewFilter(rawValue: value) {
            return view
        } else {
            return .list
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
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
//    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
//        let delete = setupDeleteAction(at: indexPath)
//        let pin = setupPinAction(at: indexPath)
//        let mute = setupMuteAction(at: indexPath)
//
//        return [delete, mute]
//    }
    
//    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool
//    {
//        return true
//    }
//
//    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
//        return UISwipeActionsConfiguration(actions: [
//            makeDeleteContextualAction(forRowAt: indexPath)
//        ])
//    }
    
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
        if indexPath.section == 0 {
            let activity = filteredPinnedActivities[indexPath.row]
            if activity.isTask ?? false {
                let cell = tableView.dequeueReusableCell(withIdentifier: taskCellID, for: indexPath) as? TaskCell ?? TaskCell()
                if let listID = activity.listID, let list = networkController.activityService.listIDs[listID], let color = list.color {
                    cell.activityTypeButton.tintColor = UIColor(ciColor: CIColor(string: color))
                } else if let list = networkController.activityService.lists[ListSourceOptions.plot.name]?.first(where: { $0.defaultList ?? false }), let color = list.color {
                    cell.activityTypeButton.tintColor = UIColor(ciColor: CIColor(string: color))
                }
                cell.configureCell(for: indexPath, task: activity)
                return cell
            } else {
                let cell = tableView.dequeueReusableCell(withIdentifier: eventCellID, for: indexPath) as? EventCell ?? EventCell()
                cell.updateInvitationDelegate = self
                var invitation: Invitation? = nil
                if let calendarID = activity.calendarID, let calendar = networkController.activityService.calendarIDs[calendarID], let color = calendar.color {
                    cell.activityTypeButton.tintColor = UIColor(ciColor: CIColor(string: color))
                } else if let calendar = networkController.activityService.calendars[CalendarSourceOptions.plot.name]?.first(where: { $0.defaultCalendar ?? false }), let color = calendar.color {
                    cell.activityTypeButton.tintColor = UIColor(ciColor: CIColor(string: color))
                }
                if let activityID = activity.activityID, let value = invitations[activityID] {
                    invitation = value
                }
                cell.configureCell(for: indexPath, activity: activity, withInvitation: invitation)
                return cell
            }
        } else {
            let activity = filteredActivities[indexPath.row]
            if activity.isTask ?? false {
                let cell = tableView.dequeueReusableCell(withIdentifier: taskCellID, for: indexPath) as? TaskCell ?? TaskCell()
                if let listID = activity.listID, let list = networkController.activityService.listIDs[listID], let color = list.color {
                    cell.activityTypeButton.tintColor = UIColor(ciColor: CIColor(string: color))
                } else if let list = networkController.activityService.lists[ListSourceOptions.plot.name]?.first(where: { $0.defaultList ?? false }), let color = list.color {
                    cell.activityTypeButton.tintColor = UIColor(ciColor: CIColor(string: color))
                }
                cell.configureCell(for: indexPath, task: activity)
                return cell
            } else {
                let cell = tableView.dequeueReusableCell(withIdentifier: eventCellID, for: indexPath) as? EventCell ?? EventCell()
                cell.updateInvitationDelegate = self
                var invitation: Invitation? = nil
                if let calendarID = activity.calendarID, let calendar = networkController.activityService.calendarIDs[calendarID], let color = calendar.color {
                    cell.activityTypeButton.tintColor = UIColor(ciColor: CIColor(string: color))
                } else if let calendar = networkController.activityService.calendars[CalendarSourceOptions.plot.name]?.first(where: { $0.defaultCalendar ?? false }), let color = calendar.color {
                    cell.activityTypeButton.tintColor = UIColor(ciColor: CIColor(string: color))
                }
                if let activityID = activity.activityID, let value = invitations[activityID] {
                    invitation = value
                }
                cell.configureCell(for: indexPath, activity: activity, withInvitation: invitation)
                return cell
            }
        }
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
        if activity.isTask ?? false {
            showTaskDetailPresent(task: activity, updateDiscoverDelegate: nil, delegate: nil, event: nil, transaction: nil, workout: nil, mindfulness: nil, template: nil, users: nil, container: nil, list: nil, startDateTime: nil, endDateTime: nil)
        } else {
            showEventDetailPresent(event: activity, updateDiscoverDelegate: nil, delegate: nil, task: nil, transaction: nil, workout: nil, mindfulness: nil, template: nil, users: nil, container: nil, startDateTime: nil, endDateTime: nil)
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
            } else if let endDate = activity.endDate {
                activityDates[dateFormatter.string(from: endDate), default: 0] += 1
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

extension CalendarViewController: DeleteAndExitDelegate {
    
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

extension CalendarViewController: UpdateInvitationDelegate {
    func updateInvitation(invitation: Invitation) {
        InvitationsFetcher.update(invitation: invitation) { result in
            if result {
                self.networkController.activityService.invitations[invitation.activityID] = invitation
                NotificationCenter.default.post(name: .eventsUpdated, object: nil)
            }
        }
    }
}

extension CalendarViewController: GIDSignInDelegate {
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        if (error == nil) {
            let grantedScopes = user?.grantedScopes as? [String]
            if let grantedScopes = grantedScopes {
                if grantedScopes.contains(googleEmailScope) && grantedScopes.contains(googleTaskScope) {
                    self.networkController.activityService.updatePrimaryCalendar(value: CalendarSourceOptions.google.name)
                    self.networkController.activityService.updatePrimaryList(value: ListSourceOptions.google.name)
                } else if grantedScopes.contains(googleEmailScope) {
                    self.networkController.activityService.updatePrimaryCalendar(value: CalendarSourceOptions.google.name)
                } else if grantedScopes.contains(googleTaskScope) {
                    self.networkController.activityService.updatePrimaryList(value: ListSourceOptions.google.name)
                }
            }
        } else {
            print("\(error.localizedDescription)")
        }
    }
}

extension CalendarViewController: UpdateFilter {
    func updateFilter(filterDictionary : [String: [String]]) {
        self.filterDictionary = filterDictionary
        updateTableViewWFilters()
    }
    
    func updateTableViewWFilters() {
        filteredPinnedActivities = pinnedActivities
        filteredActivities = activities
        let dispatchGroup = DispatchGroup()
        if let value = filterDictionary["calendarView"], let view = CalendarViewFilter(rawValue: value[0].lowercased()), self.calendarViewFilter != view {
            self.calendarViewFilter = view
        }
        if let value = filterDictionary["search"] {
            dispatchGroup.enter()
            self.calendarViewFilter = .list
            let searchText = value[0]
            filteredPinnedActivities = filteredPinnedActivities.filter({ (activity) -> Bool in
                    if let name = activity.name {
                        return name.lowercased().contains(searchText.lowercased())
                    }
                    return ("").lowercased().contains(searchText.lowercased())
                })
            filteredActivities = filteredActivities.filter({ (activity) -> Bool in
                    if let name = activity.name {
                        return name.lowercased().contains(searchText.lowercased())
                    }
                    return ("").lowercased().contains(searchText.lowercased())
                })
            dispatchGroup.leave()
        }
        if let categories = filterDictionary["calendarCategory"] {
            dispatchGroup.enter()
            self.calendarViewFilter = .list
            filteredPinnedActivities = filteredPinnedActivities.filter({ (activity) -> Bool in
                if let category = activity.category {
                    return categories.contains(category)
                }
                return false
            })
            filteredActivities = filteredActivities.filter({ (activity) -> Bool in
                if let category = activity.category {
                    return categories.contains(category)
                }
                return false
            })
            dispatchGroup.leave()
        }
        
        dispatchGroup.notify(queue: .main) {
            self.activityView.tableView.reloadData()
            self.activityView.tableView.layoutIfNeeded()
            self.handleReloadActivities(animated: false)
            self.saveCalendarView()
        }
    }
}
