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

let kShowCompletedGoals = "showCompletedGoals"
let kShowRecurringGoals = "showRecurringGoals"
let kGoalSort = "goalSort"

class GoalsViewController: UIViewController, ObjectDetailShowing {
    var networkController: NetworkController
    
    init(networkController: NetworkController) {
        self.networkController = networkController
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
            
    let tableView = UITableView(frame: .zero, style: .insetGrouped)
    
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
    var filters: [filter] = [.search, .taskSort, .showCompletedGoals, .showRecurringGoals, .goalCategory]
    var filterDictionary = [String: [String]]()
    
    let refreshControl = UIRefreshControl()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGroupedBackground
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
        NotificationCenter.default.addObserver(self, selector: #selector(listsUpdated), name: .listsUpdated, object: nil)

    }
    
    @objc fileprivate func goalsUpdated() {
        sortandreload()
    }
    
    @objc fileprivate func listsUpdated() {
        sortandreload()
    }
    
    fileprivate func setupMainView() {
        navigationController?.isNavigationBarHidden = false
        navigationController?.navigationBar.isHidden = false
        navigationItem.largeTitleDisplayMode = .never
        extendedLayoutIncludesOpaqueBars = true
        
        navigationItem.largeTitleDisplayMode = .never
        navigationItem.title = "Goals"
        view.backgroundColor = .systemGroupedBackground
        
        let newItemBarButton =  UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(newItem))
        let filterBarButton = UIBarButtonItem(image: UIImage(named: "filter"), style: .plain, target: self, action: #selector(filter))
        navigationItem.rightBarButtonItems = [newItemBarButton, filterBarButton]
        
        refreshControl.addTarget(self, action: #selector(refreshControlAction(_:)), for: UIControl.Event.valueChanged)
        tableView.refreshControl = refreshControl
    }
    
    fileprivate func setupTableView() {
        
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        
        if #available(iOS 11.0, *) {
            tableView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 0).isActive = true
            tableView.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: 0).isActive = true
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0).isActive = true
        } else {
            tableView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 0).isActive = true
            tableView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: 0).isActive = true
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0).isActive = true
        }
        tableView.delegate = self
        tableView.dataSource = self
        tableView.indicatorStyle = .default
        tableView.register(TableViewHeader.self,
                           forHeaderFooterViewReuseIdentifier: headerCellID)
        tableView.register(ListCell.self, forCellReuseIdentifier: listCellID)
        tableView.register(TaskCell.self, forCellReuseIdentifier: taskCellID)
        
        tableView.backgroundColor = .systemGroupedBackground
        tableView.separatorStyle = .none
        tableView.keyboardDismissMode = .onDrag
        
    }
    
    func setupSearchController() {
        tableView.setContentOffset(.zero, animated: false)
        searchBar = UISearchBar()
        searchBar?.delegate = self
        searchBar?.placeholder = "Search"
        searchBar?.searchBarStyle = .minimal
        searchBar?.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: 50)
        searchBar?.becomeFirstResponder()
        searchBar?.showsCancelButton = true
        tableView.tableHeaderView = searchBar
    }
    
    func checkIfThereAreAnyResults(isEmpty: Bool) {
        guard isEmpty else {
            viewPlaceholder.remove(from: tableView, priority: .medium)
            return
        }
        viewPlaceholder.add(for: tableView, title: .emptyGoals, subtitle: .emptyTasksEvents, priority: .medium, position: .top)
    }
    
    @objc func refreshControlAction(_ refreshControl: UIRefreshControl) {
        networkController.activityService.regrabLists {
            DispatchQueue.main.async {
                self.sortandreload()
                self.refreshControl.endRefreshing()
            }
        }
    }
    
    func sortandreload() {
        goals = []
        sections = []
        lists = [:]
        goalList = [:]
        
        if showRecurringGoals {
            goals = networkGoals.filter({
                if $0.goalEndDate >= Date(), $0.goalStartDate <= Date() {
                    return true
                }
                return false
            })
        } else {
            goals = []
            for goal in networkGoals {
                if !goals.contains(where: {$0.activityID == goal.activityID}) {
                    if goal.goalEndDate >= Date(), goal.goalStartDate <= Date() {
                        goals.append(goal)
                    }
                }
            }
        }
        
        var listOfLists = [ListType]()
        
        let flaggedGoals = goals.filter {
            if $0.flagged ?? false {
                return true
            }
            return false
        }
        if !flaggedGoals.isEmpty {
            let flaggedList = ListType(id: "", name: ListOptions.flaggedList.rawValue, color: "", source: "", admin: nil, defaultList: false, financeList: false, healthList: false, goalList: false)
            goalList[flaggedList] = flaggedGoals
            listOfLists.insert(flaggedList, at: 0)
        }
        
        let scheduledGoals = goals.filter {
            if let _ = $0.endDate {
                return true
            }
            return false
        }
        if !scheduledGoals.isEmpty {
            let scheduledList = ListType(id: "", name: ListOptions.scheduledList.rawValue, color: "", source: "", admin: nil, defaultList: false, financeList: false, healthList: false, goalList: false)
            goalList[scheduledList] = scheduledGoals
            listOfLists.insert(scheduledList, at: 0)
        }
        
        let dailyGoals = goals.filter {
            if let endDate = $0.endDate {
                return NSCalendar.current.isDateInToday(endDate)
            }
            return false
        }
        if !dailyGoals.isEmpty {
            let dailyList = ListType(id: "", name: ListOptions.todayList.rawValue, color: "", source: "", admin: nil, defaultList: false, financeList: false, healthList: false, goalList: false)
            goalList[dailyList] = dailyGoals
            listOfLists.insert(dailyList, at: 0)
        }
        
        if !listOfLists.isEmpty {
            sections.append(.presetLists)
            lists[.presetLists, default: []].append(contentsOf: listOfLists)
        }
        
        listOfLists = []
        
        for (id, list) in networkController.activityService.listIDs {
            let currentGoalList = goals.filter { $0.listID == id }
            if !currentGoalList.isEmpty {
                listOfLists.append(list)
                goalList[list] = currentGoalList
            }
        }
        
        if !listOfLists.isEmpty {
            if sections.count > 0 {
                sections.insert(.myLists, at: 1)
            } else {
                sections.append(.myLists)
            }
            lists[.myLists, default: []].append(contentsOf: listOfLists.sorted(by: {$0.name ?? "" < $1.name ?? "" }))
        }
        
        if !showCompletedGoals {
            filteredGoals = goals.filter({ !($0.isCompleted ?? false) })
        } else {
            filteredGoals = goals
        }
        
        sortGoals()
        
        if !filteredGoals.isEmpty {
            sections.append(.goals)
        }
                
        filteredLists = lists
        tableView.reloadData()
    }
    
    func openList(list: ListType) {
        let destination = GoalListViewController(networkController: self.networkController)
        destination.list = list
        navigationController?.pushViewController(destination, animated: true)
    }
    
    @objc fileprivate func newItem() {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "Goal", style: .default, handler: { (_) in
            self.showGoalDetailPresent(task: nil, updateDiscoverDelegate: nil, delegate: nil, event: nil, transaction: nil, workout: nil, mindfulness: nil, template: nil, users: nil, container: nil, list: nil, startDateTime: nil, endDateTime: nil)
        }))
        
        alert.addAction(UIAlertAction(title: "List", style: .default, handler: { (_) in
            self.showListDetailPresent(list: nil, updateDiscoverDelegate: nil)
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (_) in
            print("User click Dismiss button")
        }))
        
        self.present(alert, animated: true, completion: {
            print("completion block")
        })
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
        if goalSort == "Due Date" {
            filteredGoals.sort { goal1, goal2 in
                if !(goal1.isCompleted ?? false) && !(goal2.isCompleted ?? false) {
                    if goal1.endDate ?? Date.distantFuture == goal2.endDate ?? Date.distantFuture {
                        if goal1.priority == goal2.priority {
                            return goal1.name ?? "" < goal2.name ?? ""
                        }
                        return TaskPriority(rawValue: goal1.priority ?? "None")! > TaskPriority(rawValue: goal2.priority ?? "None")!
                    }
                    return goal1.endDate ?? Date.distantFuture < goal2.endDate ?? Date.distantFuture
                } else if goal1.isCompleted ?? false && goal2.isCompleted ?? false {
                    if goal1.completedDate ?? 0 == goal2.completedDate ?? 0 {
                        return goal1.name ?? "" < goal2.name ?? ""
                    }
                    return Int(truncating: goal1.completedDate ?? 0) > Int(truncating: goal2.completedDate ?? 0)
                }
                return !(goal1.isCompleted ?? false)
            }
        } else if goalSort == "Priority" {
            filteredGoals.sort { goal1, goal2 in
                if !(goal1.isCompleted ?? false) && !(goal2.isCompleted ?? false) {
                    if goal1.priority == goal2.priority {
                        if goal1.endDate ?? Date.distantFuture == goal2.endDate ?? Date.distantFuture {
                            return goal1.name ?? "" < goal2.name ?? ""
                        }
                        return goal1.endDate ?? Date.distantFuture < goal2.endDate ?? Date.distantFuture
                    }
                    return TaskPriority(rawValue: goal1.priority ?? "None")! > TaskPriority(rawValue: goal2.priority ?? "None")!
                } else if goal1.isCompleted ?? false && goal2.isCompleted ?? false {
                    if goal1.completedDate ?? 0 == goal2.completedDate ?? 0 {
                        return goal1.name ?? "" < goal2.name ?? ""
                    }
                    return Int(truncating: goal1.completedDate ?? 0) > Int(truncating: goal2.completedDate ?? 0)
                }
                return !(goal1.isCompleted ?? false)
            }
        } else if goalSort == "Title" {
            filteredGoals.sort { goal1, goal2 in
                if !(goal1.isCompleted ?? false) && !(goal2.isCompleted ?? false) {
                    if goal1.name ?? "" == goal2.name ?? "" {
                        if goal1.priority == goal2.priority {
                            return goal1.endDate ?? Date.distantFuture < goal2.endDate ?? Date.distantFuture
                        }
                    }
                    return goal1.name ?? "" < goal2.name ?? ""
                } else if goal1.isCompleted ?? false && goal2.isCompleted ?? false {
                    if goal1.completedDate ?? 0 == goal2.completedDate ?? 0 {
                        return goal1.name ?? "" < goal2.name ?? ""
                    }
                    return Int(truncating: goal1.completedDate ?? 0) > Int(truncating: goal2.completedDate ?? 0)
                }
                return !(goal1.isCompleted ?? false)
            }
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
        let header = tableView.dequeueReusableHeaderFooterView(withIdentifier:
                                                                headerCellID) as? TableViewHeader ?? TableViewHeader()
        let section = sections[section]
        header.backgroundColor = .systemGroupedBackground
        header.titleLabel.text = section.name
        header.subTitleLabel.isHidden = true
        header.sectionType = section
        return header

    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 40
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
                        if $0.goalEndDate >= Date(), $0.goalStartDate <= Date() {
                            return true
                        }
                        return false
                    })
                    self.showRecurringGoals = true
                } else {
                    goals = []
                    for goal in networkGoals {
                        if !goals.contains(where: {$0.activityID == goal.activityID}) {
                            if goal.goalEndDate >= Date(), goal.goalStartDate <= Date() {
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
                self.tableView.reloadData()
                self.tableView.layoutIfNeeded()
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
