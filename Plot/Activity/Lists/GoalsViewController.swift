//
//  GoalsViewController.swift
//  Plot
//
//  Created by Cory McHattie on 2/15/23.
//  Copyright © 2023 Immature Creations. All rights reserved.
//

import UIKit
import Firebase
import GoogleSignIn
import FSCalendar

let kShowCompletedGoals = "showCompletedGoals"
let kShowRecurringGoals = "showRecurringGoals"
let kGoalSort = "goalSort"

class GoalsViewController: UIViewController, ObjectDetailShowing, UIGestureRecognizerDelegate {
    var networkController: NetworkController
    
    init(networkController: NetworkController) {
        self.networkController = networkController
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
                
    let headerCellID = "headerCellID"
    let listCellID = "listCellID"
    
    var sections = [SectionType]()
    var lists = [SectionType: [ListType]]()
    var goalList = [ListType: [Activity]]()
    var filteredLists = [SectionType: [ListType]]()
    var networkGoals: [Activity] {
        return networkController.activityService.goals
    }
    var goals = [Activity]()
    var filteredGoals = [Activity]()
    
    lazy var users: [User] = networkController.userService.users
    lazy var filteredUsers: [User] = networkController.userService.users
    lazy var conversations: [Conversation] = networkController.conversationService.conversations
    
    var searchBar: UISearchBar?
    var searchController: UISearchController?
    
    let viewPlaceholder = ViewPlaceholder()
        
    var listIndex: Int = 0
    
    var participants: [String: [User]] = [:]
    
    var showCompletedGoals: Bool = true
    var showRecurringGoals: Bool = true
    var goalSort: String = "Due Date"
    var filters: [filter] = [.search, .showCompletedGoals, .goalCategory]
    var filterDictionary = [String: [String]]()
    
    let refreshControl = UIRefreshControl()
    
    let activityView = CalendarView()
    
    var calendarViewFilter: CalendarViewFilter = .list
    
    var selectedDate = Date().localTime
    
    var activityDates = [String: Int]()
    
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
    
    var canTransitionToLarge = false
    var canTransitionToSmall = true

    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGroupedBackground
        compileActivityDates(activities: networkGoals)
        setupMainView()
        setupTableView()
        addObservers()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        showRecurringGoals = getShowRecurringGoalsBool()
        showCompletedGoals = getShowCompletedGoalsBool()
        goalSort = getSortGoals()
        sortandreload()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    fileprivate func addObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(goalsUpdated), name: .goalsUpdated, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(metricsUpdated), name: .calendarActivitiesUpdated, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(metricsUpdated), name: .tasksUpdated, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(metricsUpdated), name: .healthUpdated, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(metricsUpdated), name: .workoutsUpdated, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(metricsUpdated), name: .mindfulnessUpdated, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(metricsUpdated), name: .moodsUpdated, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(metricsUpdated), name: .financeUpdated, object: nil)

    }
    
    @objc fileprivate func goalsUpdated() {
        compileActivityDates(activities: networkGoals)
        sortandreload()
    }
    
    @objc fileprivate func metricsUpdated() {
        networkController.checkGoals {}
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
    
    fileprivate func setupMainView() {
        navigationController?.isNavigationBarHidden = false
        navigationController?.navigationBar.isHidden = false
        navigationItem.largeTitleDisplayMode = .never
        extendedLayoutIncludesOpaqueBars = true
        navigationItem.largeTitleDisplayMode = .never
        view.backgroundColor = .systemGroupedBackground
        edgesForExtendedLayout = UIRectEdge.top
        
        let newItemBarButton =  UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(newItem))
        let filterBarButton = UIBarButtonItem(image: UIImage(named: "filter"), style: .plain, target: self, action: #selector(filter))
        navigationItem.rightBarButtonItems = [newItemBarButton, filterBarButton]
        
        refreshControl.addTarget(self, action: #selector(refreshControlAction(_:)), for: UIControl.Event.valueChanged)
        activityView.tableView.refreshControl = refreshControl
        
        let dateString = selectedDateFormatter.string(from: selectedDate)
        title = dateString
                
    }
    
    fileprivate func setupTableView() {
        
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
        activityView.tableView.register(TableViewHeader.self,
                           forHeaderFooterViewReuseIdentifier: headerCellID)
        activityView.tableView.register(ListCell.self, forCellReuseIdentifier: listCellID)
        activityView.tableView.register(TaskCell.self, forCellReuseIdentifier: taskCellID)
        activityView.tableView.allowsMultipleSelectionDuringEditing = false
        activityView.tableView.indicatorStyle = .default
        activityView.tableView.backgroundColor = view.backgroundColor
        activityView.tableView.rowHeight = UITableView.automaticDimension
        
        // apply theme
        applyCalendarTheme()
        
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
    
    func checkIfThereAreAnyResults(isEmpty: Bool) {
        guard isEmpty else {
            viewPlaceholder.remove(from: activityView.tableView, priority: .medium)
            return
        }
        viewPlaceholder.add(for: activityView.tableView, title: .emptyGoals, subtitle: .emptyTasksEvents, priority: .medium, position: .top)
    }
    
    @objc func refreshControlAction(_ refreshControl: UIRefreshControl) {
        networkController.checkGoalsForCompletion {
            DispatchQueue.main.async {
                self.sortandreload()
                self.refreshControl.endRefreshing()
            }
        }
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
            self.activityView.calendarHeightConstraint?.constant = 0
            self.activityView.layoutIfNeeded()
        }) { result in
            self.activityView.calendar.isHidden = true
        }
    }
    
    func sortandreload() {
        goals = []
        sections = []
        lists = [:]
        goalList = [:]
        
        if showRecurringGoals {
            goals = networkGoals.filter({
                if $0.endDate ?? selectedDate >= selectedDate, $0.startDate ?? selectedDate <= selectedDate {
                    return true
                }
                return false
            })
        } else {
            goals = []
            for goal in networkGoals {
                if !goals.contains(where: {$0.activityID == goal.activityID}) {
                    if goal.endDate ?? selectedDate >= selectedDate, goal.startDate ?? selectedDate <= selectedDate {
                        goals.append(goal)
                    }
                }
            }
        }
        
        if !showCompletedGoals {
            filteredGoals = goals.filter({ !($0.isCompleted ?? false) })
        } else {
            filteredGoals = goals
        }
        
        if let value = filterDictionary["search"] {
            let searchText = value[0]
            filteredGoals = filteredGoals.filter({ (task) -> Bool in
                if let name = task.name {
                    return name.lowercased().contains(searchText.lowercased())
                }
                return ("").lowercased().contains(searchText.lowercased())
            })
        }
        
        sortGoals()
        
        if !filteredGoals.isEmpty {
            sections.append(.goals)
        }
                
        activityView.tableView.reloadData()
    }
    
    func openList(list: ListType) {
        let destination = GoalListViewController(networkController: self.networkController)
        destination.list = list
        navigationController?.pushViewController(destination, animated: true)
    }
    
    @objc fileprivate func newItem() {
        self.showGoalDetailPresent(task: nil, updateDiscoverDelegate: nil, delegate: nil, event: nil, transaction: nil, workout: nil, mindfulness: nil, template: nil, users: nil, container: nil, list: nil, startDateTime: nil, endDateTime: nil)
    }
    
    @objc fileprivate func filter() {
        filterDictionary["showRecurringGoals"] = showRecurringGoals ? ["Yes"] : ["No"]
        filterDictionary["showCompletedGoals"] = showCompletedGoals ? ["Yes"] : ["No"]
        filterDictionary["goalSort"] = [goalSort]
        let destination = FilterViewController(networkController: networkController)
        let navigationViewController = UINavigationController(rootViewController: destination)
        destination.delegate = self
        destination.filters = filters
        destination.filterDictionary = filterDictionary
        self.present(navigationViewController, animated: true, completion: nil)
    }
    
    @objc fileprivate func search() {
        setupSearchController()
    }
    
    func saveUserDefaults() {
        UserDefaults.standard.setValue(goalSort, forKey: kGoalSort)
        UserDefaults.standard.setValue(showCompletedGoals, forKey: kShowCompletedGoals)
        UserDefaults.standard.setValue(showRecurringGoals, forKey: kShowRecurringGoals)
    }
    
    func getShowCompletedGoalsBool() -> Bool {
        if let value = UserDefaults.standard.value(forKey: kShowCompletedGoals) as? Bool {
            return value
        } else {
            return true
        }
    }
    
    func getShowRecurringGoalsBool() -> Bool {
        if let value = UserDefaults.standard.value(forKey: kShowRecurringGoals) as? Bool {
            return value
        } else {
            return false
        }
    }
    
    func getSortGoals() -> String {
        if let value = UserDefaults.standard.value(forKey: kGoalSort) as? String {
            return value
        } else {
            return "Due Date"
        }
    }
    
    func sortGoals() {
        filteredGoals.sort { goal1, goal2 in
            if goal1.endDate == goal2.endDate {
                return goal1.name ?? "" < goal2.name ?? ""
            }
            return goal1.endDate ?? Date.distantFuture < goal2.endDate ?? Date.distantFuture
        }
    }
}

extension GoalsViewController: FSCalendarDataSource, FSCalendarDelegate, FSCalendarDelegateAppearance {
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
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy/MM/dd"
        if let value = activityDates[dateString] {
            print(value)
        }
        sortandreload()
    }
    
    func calendarCurrentPageDidChange(_ calendar: FSCalendar) {
        self.selectedDate = calendar.currentPage
        let dateString = selectedDateFormatter.string(from: self.selectedDate)
        title = dateString
        sortandreload()
    }
    
    func saveCalendarScope(scope: FSCalendarScope) {
        UserDefaults.standard.setValue(scope.rawValue, forKey: kGoalsScope)
    }
    
    func getCalendarScope() -> FSCalendarScope {
        if let value = UserDefaults.standard.value(forKey: kGoalsScope) as? UInt, let scope = FSCalendarScope(rawValue: value) {
            return scope
        } else {
            return .week
        }
    }
    
    func saveCalendarView() {
        UserDefaults.standard.setValue(calendarViewFilter.rawValue, forKey: kGoalsView)
    }
    
    func getCalendarView() -> CalendarViewFilter {
        if let value = UserDefaults.standard.value(forKey: kGoalsView) as? String, let view = CalendarViewFilter(rawValue: value) {
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
    
    fileprivate func compileActivityDates(activities: [Activity]) {
        activityDates = [:]
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy/MM/dd"
        let dispatchGroup = DispatchGroup()
        for activity in activities {
            dispatchGroup.enter()
            dateFormatter.timeZone = TimeZone(identifier: activity.startTimeZone ?? "UTC")
            if activity.isCompleted ?? false {
                if let startDate = activity.startDate?.localTime, let endDate = activity.endDate?.localTime {
                    for activityDate in stride(from: startDate, to: endDate, by: 86400) {
                        activityDates[dateFormatter.string(from: activityDate), default: 0] += 1
                    }
                    dispatchGroup.leave()
                } else if let endDate = activity.endDate?.localTime {
                    activityDates[dateFormatter.string(from: endDate), default: 0] += 1
                    dispatchGroup.leave()
                }
            }
        }
        dispatchGroup.notify(queue: .main) {
            self.activityView.calendar.reloadData()
        }
    }
}

extension GoalsViewController: UITableViewDataSource, UITableViewDelegate {
    
//    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
//
//        let delete = setupDeleteAction(at: indexPath)
//        let mute = setupMuteAction(at: indexPath)
//
//        return [delete, mute]
//    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return UIView()
        

    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let section = sections[section]
        let lists = filteredLists[section] ?? []
        if lists.count == 0 && filteredGoals.isEmpty {
            checkIfThereAreAnyResults(isEmpty: true)
        } else {
            checkIfThereAreAnyResults(isEmpty: false)
        }
        if lists.count > 0 {
            return lists.count
        } else {
            return filteredGoals.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let section = sections[indexPath.section]
        let cell = tableView.dequeueReusableCell(withIdentifier: listCellID, for: indexPath) as? ListCell ?? ListCell()
        if let filteredLists = filteredLists[section] {
            let list = filteredLists[indexPath.row]
            cell.configureCell(for: indexPath, list: list, taskNumber: goalList[list]?.filter({ !($0.isCompleted ?? false) }).count ?? 0)
            return cell
        } else if !filteredGoals.isEmpty {
            let goal = filteredGoals[indexPath.row]
            let cell = tableView.dequeueReusableCell(withIdentifier: taskCellID, for: indexPath) as? TaskCell ?? TaskCell()
            if let listID = goal.listID, let list = networkController.activityService.listIDs[listID], let color = list.color {
                cell.activityTypeButton.tintColor = UIColor(ciColor: CIColor(string: color))
            } else if let list = networkController.activityService.lists[ListSourceOptions.plot.name]?.first(where: { $0.defaultList ?? false }), let color = list.color {
                cell.activityTypeButton.tintColor = UIColor(ciColor: CIColor(string: color))
            }
            cell.configureCell(for: indexPath, task: goal)
            cell.updateCompletionDelegate = self
            return cell
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let section = sections[indexPath.section]
        if let filteredLists = filteredLists[section] {
            let list = filteredLists[indexPath.row]
            openList(list: list)
        } else {
            let goal = filteredGoals[indexPath.row]
            showGoalDetailPresent(task: goal, updateDiscoverDelegate: nil, delegate: nil, event: nil, transaction: nil, workout: nil, mindfulness: nil, template: nil, users: nil, container: nil, list: nil, startDateTime: nil, endDateTime: nil)
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }

}

extension GoalsViewController: UpdateFilter {
    func updateFilter(filterDictionary : [String: [String]]) {
        self.filterDictionary = filterDictionary
        updateTableViewWFilters()
    }
    
    func updateTableViewWFilters() {
        sections = [.goals]
        filteredLists = [:]
        if filterDictionary.isEmpty {
            sortandreload()
        } else {
            let dispatchGroup = DispatchGroup()
            if let value = filterDictionary["showRecurringGoals"] {
                dispatchGroup.enter()
                let bool = value[0].lowercased()
                if bool == "yes" {
                    goals = networkGoals.filter({
                        if $0.endDate ?? selectedDate >= selectedDate, $0.startDate ?? selectedDate <= selectedDate {
                            return true
                        }
                        return false
                    })
                    self.showRecurringGoals = true
                } else {
                    goals = []
                    for goal in networkGoals {
                        if !goals.contains(where: {$0.activityID == goal.activityID}) {
                            if goal.endDate ?? selectedDate >= selectedDate, goal.startDate ?? selectedDate <= selectedDate {
                                goals.append(goal)
                            }
                        }
                    }
                    self.showRecurringGoals = false
                }
                dispatchGroup.leave()
            }
            if let value = filterDictionary["showCompletedGoals"] {
                dispatchGroup.enter()
                let bool = value[0].lowercased()
                if bool == "yes" {
                    filteredGoals = goals
                    self.showCompletedGoals = true
                } else {
                    filteredGoals = goals.filter({ !($0.isCompleted ?? false) })
                    self.showCompletedGoals = false
                }
                dispatchGroup.leave()
            }
            if let value = filterDictionary["search"] {
                dispatchGroup.enter()
                let searchText = value[0]
                filteredGoals = filteredGoals.filter({ (task) -> Bool in
                    if let name = task.name {
                        return name.lowercased().contains(searchText.lowercased())
                    }
                    return ("").lowercased().contains(searchText.lowercased())
                })
                dispatchGroup.leave()
            }
            if let categories = filterDictionary["goalCategory"] {
                dispatchGroup.enter()
                filteredGoals = filteredGoals.filter({ (task) -> Bool in
                    if let category = task.category {
                        return categories.contains(category)
                    }
                    return false
                })
                dispatchGroup.leave()
            }
            if let value = filterDictionary["goalSort"] {
                let sort = value[0]
                self.goalSort = sort
            }
            
            dispatchGroup.notify(queue: .main) {
                self.sortGoals()
                self.activityView.tableView.reloadData()
                self.activityView.tableView.layoutIfNeeded()
                self.saveUserDefaults()
            }
        }
    }
}

extension GoalsViewController: GIDSignInDelegate {
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

extension GoalsViewController: UpdateCompletionDelegate {
    func updateCompletion(task: Activity) {
        if task.isGoal ?? false, let goal = task.goal, let metric = goal.metric, let unit = goal.unit, let target = goal.targetNumber {
            if let metricSecond = goal.metricSecond, metricSecond.canBeUpdatedByUser, let unitSecond = goal.unitSecond, let targetSecond = goal.targetNumberSecond {
                if metric.canBeUpdatedByUser {
                    let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
                    
                    alert.addAction(UIAlertAction(title: metric.alertTitle, style: .default, handler: { (_) in
                        self.newMetric(task: task, metric: metric, unit: unit, target: target, submetric: goal.submetric, option: goal.option?.first)
                    }))
                    
                    alert.addAction(UIAlertAction(title: metricSecond.alertTitle, style: .default, handler: { (_) in
                        self.newMetric(task: task, metric: metricSecond, unit: unitSecond, target: targetSecond, submetric: goal.submetricSecond, option: goal.optionSecond?.first)
                    }))
                    
                    alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (_) in
                        print("User click Dismiss button")
                    }))
                    
                    self.present(alert, animated: true, completion: {
                        print("completion block")
                    })
                } else {
                    self.newMetric(task: task, metric: metric, unit: unit, target: target, submetric: goal.submetric, option: goal.option?.first)
                }
            } else if metric.canBeUpdatedByUser {
                self.newMetric(task: task, metric: metric, unit: unit, target: target, submetric: goal.submetric, option: goal.option?.first)
            } else {
                basicErrorAlertWithClose(title: basicErrorTitleForAlert, message: goalCannotBeUpdatedByUserMessage, controller: self)
            }
        }
    }
}
