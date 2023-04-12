//
//  ListViewController.swift
//  Plot
//
//  Created by Cory McHattie on 4/21/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import UIKit
import Firebase
import GoogleSignIn

let kShowCompletedTasks = "showCompletedTasks"
let kShowRecurringTasks = "showRecurringTasks"
let kTaskSort = "taskSort"

class ListsViewController: UIViewController, ObjectDetailShowing {
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
    var taskList = [ListType: [Activity]]()
    var filteredLists = [SectionType: [ListType]]()
    var networkTasks: [Activity] {
        return networkController.activityService.tasks
    }
    var tasks = [Activity]()
    var filteredTasks = [Activity]()
    
    lazy var users: [User] = networkController.userService.users
    lazy var filteredUsers: [User] = networkController.userService.users
    lazy var conversations: [Conversation] = networkController.conversationService.conversations
    
    var searchBar: UISearchBar?
    var searchController: UISearchController?
    
    let viewPlaceholder = ViewPlaceholder()
        
    var listIndex: Int = 0
    
    var participants: [String: [User]] = [:]
    
    var showCompletedTasks: Bool = true
    var showRecurringTasks: Bool = true
    var taskSort: String = "Due Date"
    var filters: [filter] = [.search, .taskSort, .showCompletedTasks, .showRecurringTasks, .taskCategory]
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
        showRecurringTasks = getShowRecurringTasksBool()
        showCompletedTasks = getShowCompletedTasksBool()
        taskSort = getSortTasks()
        sortandreload()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    fileprivate func addObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(tasksUpdated), name: .tasksUpdated, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(listsUpdated), name: .listsUpdated, object: nil)

    }
    
    @objc fileprivate func tasksUpdated() {
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
        navigationItem.title = "Tasks"
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
        viewPlaceholder.add(for: tableView, title: .emptyTasks, subtitle: .emptyTasksEvents, priority: .medium, position: .top)
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
        networkController.activityService.activitiesFetcher.loadUnloadedActivities(startDate: nil, endDate: nil, isCalendar: nil, isEvent: nil, isTask: true, isGoal: nil) { loadedTaskList in
            self.tasks = []
            self.sections = []
            self.lists = [:]
            self.taskList = [:]
            if self.showRecurringTasks {
                self.tasks = self.networkTasks + loadedTaskList
            } else {
                for task in self.networkTasks + loadedTaskList {
                    if !self.tasks.contains(where: {$0.activityID == task.activityID}) {
                        self.tasks.append(task)
                    }
                }
            }
            
            var listOfLists = [ListType]()
            
            let flaggedTasks = self.tasks.filter {
                if $0.flagged ?? false {
                    return true
                }
                return false
            }
            if !flaggedTasks.isEmpty {
                let flaggedList = ListType(id: "", name: ListOptions.flaggedList.rawValue, color: "", source: "", admin: nil, defaultList: false, financeList: false, healthList: false, goalList: false)
                self.taskList[flaggedList] = flaggedTasks
                listOfLists.insert(flaggedList, at: 0)
            }
            
            let scheduledTasks = self.tasks.filter {
                if let _ = $0.endDate {
                    return true
                }
                return false
            }
            if !scheduledTasks.isEmpty {
                let scheduledList = ListType(id: "", name: ListOptions.scheduledList.rawValue, color: "", source: "", admin: nil, defaultList: false, financeList: false, healthList: false, goalList: false)
                self.taskList[scheduledList] = scheduledTasks
                listOfLists.insert(scheduledList, at: 0)
            }
            
            let dailyTasks = self.tasks.filter {
                if let endDate = $0.endDate {
                    return NSCalendar.current.isDateInToday(endDate)
                }
                return false
            }
            if !dailyTasks.isEmpty {
                let dailyList = ListType(id: "", name: ListOptions.todayList.rawValue, color: "", source: "", admin: nil, defaultList: false, financeList: false, healthList: false, goalList: false)
                self.taskList[dailyList] = dailyTasks
                listOfLists.insert(dailyList, at: 0)
            }
            
            if !listOfLists.isEmpty {
                self.sections.append(.presetLists)
                self.lists[.presetLists, default: []].append(contentsOf: listOfLists)
            }
            
            listOfLists = []
            
            for (id, list) in self.networkController.activityService.listIDs {
                let currentTaskList = self.tasks.filter { $0.listID == id }
                if !currentTaskList.isEmpty {
                    listOfLists.append(list)
                    self.taskList[list] = currentTaskList
                }
            }
            
            if !listOfLists.isEmpty {
                if self.sections.count > 0 {
                    self.sections.insert(.myLists, at: 1)
                } else {
                    self.sections.append(.myLists)
                }
                self.lists[.myLists, default: []].append(contentsOf: listOfLists.sorted(by: {$0.name ?? "" < $1.name ?? "" }))
            }
            
            if !self.showCompletedTasks {
                self.filteredTasks = self.tasks.filter({ !($0.isCompleted ?? false) })
            } else {
                self.filteredTasks = self.tasks
            }
            
            self.sortTasks()
            
            if !self.filteredTasks.isEmpty {
                self.sections.append(.tasks)
            }
                    
            self.filteredLists = self.lists
            
            DispatchQueue.main.async {
                activityIndicatorView.stopAnimating()
                self.tableView.reloadData()
            }
        }
    }
    
    func openList(list: ListType) {
        let destination = ListViewController(networkController: self.networkController)
        destination.list = list
        navigationController?.pushViewController(destination, animated: true)
    }
    
    @objc fileprivate func newItem() {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "Task", style: .default, handler: { (_) in
            self.showTaskDetailPresent(task: nil, updateDiscoverDelegate: nil, delegate: nil, event: nil, transaction: nil, workout: nil, mindfulness: nil, template: nil, users: nil, container: nil, list: nil, startDateTime: nil, endDateTime: nil)
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
        filterDictionary["showRecurringTasks"] = showRecurringTasks ? ["Yes"] : ["No"]
        filterDictionary["showCompletedTasks"] = showCompletedTasks ? ["Yes"] : ["No"]
        filterDictionary["taskSort"] = [taskSort]
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
        UserDefaults.standard.setValue(taskSort, forKey: kTaskSort)
        UserDefaults.standard.setValue(showCompletedTasks, forKey: kShowCompletedTasks)
        UserDefaults.standard.setValue(showRecurringTasks, forKey: kShowRecurringTasks)
    }
    
    func getShowCompletedTasksBool() -> Bool {
        if let value = UserDefaults.standard.value(forKey: kShowCompletedTasks) as? Bool {
            return value
        } else {
            return true
        }
    }
    
    func getShowRecurringTasksBool() -> Bool {
        if let value = UserDefaults.standard.value(forKey: kShowRecurringTasks) as? Bool {
            return value
        } else {
            return false
        }
    }
    
    func getSortTasks() -> String {
        if let value = UserDefaults.standard.value(forKey: kTaskSort) as? String {
            return value
        } else {
            return "Due Date"
        }
    }
    
    func sortTasks() {
        if taskSort == "Due Date" {
            filteredTasks.sort { task1, task2 in
                if !(task1.isCompleted ?? false) && !(task2.isCompleted ?? false) {
                    if task1.endDate ?? Date.distantFuture == task2.endDate ?? Date.distantFuture {
                        if task1.priority == task2.priority {
                            return task1.name ?? "" < task2.name ?? ""
                        }
                        return TaskPriority(rawValue: task1.priority ?? "None")! > TaskPriority(rawValue: task2.priority ?? "None")!
                    }
                    return task1.endDate ?? Date.distantFuture < task2.endDate ?? Date.distantFuture
                } else if task1.isCompleted ?? false && task2.isCompleted ?? false {
                    if task1.completedDate ?? 0 == task2.completedDate ?? 0 {
                        return task1.name ?? "" < task2.name ?? ""
                    }
                    return Int(truncating: task1.completedDate ?? 0) > Int(truncating: task2.completedDate ?? 0)
                }
                return !(task1.isCompleted ?? false)
            }
        } else if taskSort == "Priority" {
            filteredTasks.sort { task1, task2 in
                if !(task1.isCompleted ?? false) && !(task2.isCompleted ?? false) {
                    if task1.priority == task2.priority {
                        if task1.endDate ?? Date.distantFuture == task2.endDate ?? Date.distantFuture {
                            return task1.name ?? "" < task2.name ?? ""
                        }
                        return task1.endDate ?? Date.distantFuture < task2.endDate ?? Date.distantFuture
                    }
                    return TaskPriority(rawValue: task1.priority ?? "None")! > TaskPriority(rawValue: task2.priority ?? "None")!
                } else if task1.isCompleted ?? false && task2.isCompleted ?? false {
                    if task1.completedDate ?? 0 == task2.completedDate ?? 0 {
                        return task1.name ?? "" < task2.name ?? ""
                    }
                    return Int(truncating: task1.completedDate ?? 0) > Int(truncating: task2.completedDate ?? 0)
                }
                return !(task1.isCompleted ?? false)
            }
        } else if taskSort == "Title" {
            filteredTasks.sort { task1, task2 in
                if !(task1.isCompleted ?? false) && !(task2.isCompleted ?? false) {
                    if task1.name ?? "" == task2.name ?? "" {
                        if task1.priority == task2.priority {
                            return task1.endDate ?? Date.distantFuture < task2.endDate ?? Date.distantFuture
                        }
                    }
                    return task1.name ?? "" < task2.name ?? ""
                } else if task1.isCompleted ?? false && task2.isCompleted ?? false {
                    if task1.completedDate ?? 0 == task2.completedDate ?? 0 {
                        return task1.name ?? "" < task2.name ?? ""
                    }
                    return Int(truncating: task1.completedDate ?? 0) > Int(truncating: task2.completedDate ?? 0)
                }
                return !(task1.isCompleted ?? false)
            }
        }
    }
}

extension ListsViewController: UITableViewDataSource, UITableViewDelegate {
    
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
        if lists.count == 0 && filteredTasks.isEmpty {
            checkIfThereAreAnyResults(isEmpty: true)
        } else {
            checkIfThereAreAnyResults(isEmpty: false)
        }
        if lists.count > 0 {
            return lists.count
        } else {
            return filteredTasks.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let section = sections[indexPath.section]
        let cell = tableView.dequeueReusableCell(withIdentifier: listCellID, for: indexPath) as? ListCell ?? ListCell()
        if let filteredLists = filteredLists[section] {
            let list = filteredLists[indexPath.row]
            cell.configureCell(for: indexPath, list: list, taskNumber: taskList[list]?.filter({ !($0.isCompleted ?? false) }).count ?? 0)
            return cell
        } else if !filteredTasks.isEmpty {
            let task = filteredTasks[indexPath.row]
            let cell = tableView.dequeueReusableCell(withIdentifier: taskCellID, for: indexPath) as? TaskCell ?? TaskCell()
            if let listID = task.listID, let list = networkController.activityService.listIDs[listID], let color = list.color {
                cell.activityTypeButton.tintColor = UIColor(ciColor: CIColor(string: color))
            } else if let list = networkController.activityService.lists[ListSourceOptions.plot.name]?.first(where: { $0.defaultList ?? false }), let color = list.color {
                cell.activityTypeButton.tintColor = UIColor(ciColor: CIColor(string: color))
            }
            cell.configureCell(for: indexPath, task: task)
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
            let task = filteredTasks[indexPath.row]
            showTaskDetailPresent(task: task, updateDiscoverDelegate: nil, delegate: nil, event: nil, transaction: nil, workout: nil, mindfulness: nil, template: nil, users: nil, container: nil, list: nil, startDateTime: nil, endDateTime: nil)

        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }

}

extension ListsViewController: UpdateFilter {
    func updateFilter(filterDictionary : [String: [String]]) {
        self.filterDictionary = filterDictionary
        updateTableViewWFilters()
    }
    
    func updateTableViewWFilters() {
        sections = [.tasks]
        filteredLists = [:]
        if filterDictionary.isEmpty {
            sortandreload()
        } else {
            let dispatchGroup = DispatchGroup()
            if let value = filterDictionary["showRecurringTasks"] {
                dispatchGroup.enter()
                let bool = value[0].lowercased()
                if bool == "yes" {
                    tasks = networkTasks
                    self.showRecurringTasks = true
                } else {
                    tasks = []
                    for task in networkTasks {
                        if !tasks.contains(where: {$0.activityID == task.activityID}) {
                            tasks.append(task)
                        }
                    }
                    self.showRecurringTasks = false
                }
                dispatchGroup.leave()
            }
            if let value = filterDictionary["showCompletedTasks"] {
                dispatchGroup.enter()
                let bool = value[0].lowercased()
                if bool == "yes" {
                    filteredTasks = tasks
                    self.showCompletedTasks = true
                } else {
                    filteredTasks = tasks.filter({ !($0.isCompleted ?? false) })
                    self.showCompletedTasks = false
                }
                dispatchGroup.leave()
            }
            if let value = filterDictionary["search"] {
                dispatchGroup.enter()
                let searchText = value[0]
                filteredTasks = filteredTasks.filter({ (task) -> Bool in
                    if let name = task.name {
                        return name.lowercased().contains(searchText.lowercased())
                    }
                    return ("").lowercased().contains(searchText.lowercased())
                })
                dispatchGroup.leave()
            }
            if let categories = filterDictionary["taskCategory"] {
                dispatchGroup.enter()
                filteredTasks = filteredTasks.filter({ (task) -> Bool in
                    if let category = task.category {
                        return categories.contains(category)
                    }
                    return false
                })
                dispatchGroup.leave()
            }
            if let value = filterDictionary["taskSort"] {
                let sort = value[0]
                self.taskSort = sort
            }
            
            dispatchGroup.notify(queue: .main) {
                self.sortTasks()
                self.tableView.reloadData()
                self.tableView.layoutIfNeeded()
                self.saveUserDefaults()
            }
        }
    }
}

extension ListsViewController: GIDSignInDelegate {
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

