//
//  ListViewController.swift
//  Plot
//
//  Created by Cory McHattie on 8/23/22.
//  Copyright © 2022 Immature Creations. All rights reserved.
//

import UIKit
import Firebase

class ListViewController: UIViewController, ObjectDetailShowing {
    var networkController: NetworkController
    
    init(networkController: NetworkController) {
        self.networkController = networkController
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
            
    let tableView = UITableView(frame: .zero, style: .insetGrouped)
    
    let newTaskCellID = "newTaskCellID"
    
    var list: ListType!
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
            
    var participants: [String: [User]] = [:]
    
    var showCompletedTasks: Bool = true
    var showRecurringTasks: Bool = true
    var taskSort: String = "Due Date"
    var filters: [filter] = [.search, .taskSort, .showCompletedTasks, .showRecurringTasks, .taskCategory]
    var filterDictionary = [String: [String]]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
                
        view.backgroundColor = .systemBackground
        
        showRecurringTasks = getShowRecurringTasksBool()
        showCompletedTasks = getShowCompletedTasksBool()
        taskSort = getSortTasks()
        
        setupMainView()
        setupTableView()
        addObservers()
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
    
    func sortandreload() {
        if showRecurringTasks {
            tasks = networkTasks
        } else {
            tasks = []
            for task in networkTasks {
                if !tasks.contains(where: {$0.activityID == task.activityID}) {
                    tasks.append(task)
                }
            }
        }
        
        switch ListOptions(rawValue: list.name ?? "") {
        case .allList:
            break
        case .flaggedList:
            let flaggedTasks = tasks.filter {
                if $0.flagged ?? false {
                    return true
                }
                return false
            }
            filteredTasks = flaggedTasks
        case .scheduledList:
            let scheduledTasks = tasks.filter {
                if let _ = $0.endDate {
                    return true
                }
                return false
            }
            filteredTasks = scheduledTasks
        case .todayList:
            let dailyTasks = tasks.filter {
                if let endDate = $0.endDate {
                    return NSCalendar.current.isDateInToday(endDate)
                }
                return false
            }
            filteredTasks = dailyTasks
        case .goalList:
            let goalTasks = tasks.filter {
                if $0.isGoal ?? false {
                    return true
                }
                return false
            }
            filteredTasks = goalTasks
        default:
            filteredTasks = tasks.filter { $0.listID == list.id }
        }
        
        if !showCompletedTasks {
            filteredTasks = filteredTasks.filter({ !($0.isCompleted ?? false) })
        }
        sortTasks()
        
        tableView.reloadData()
    }
    
    @objc fileprivate func listsUpdated() {
        if let id = list.id, let list = networkController.activityService.listIDs[id] {
            self.list = list
        }
        tableView.reloadData()
    }
    
    fileprivate func setupMainView() {
        navigationItem.largeTitleDisplayMode = .never
        navigationItem.title = "Tasks"
        view.backgroundColor = .systemGroupedBackground
        
        let filterBarButton = UIBarButtonItem(image: UIImage(named: "filter"), style: .plain, target: self, action: #selector(filter))
        if let id = list.id, id != "" {
            let newItemBarButton = UIBarButtonItem(image: UIImage(systemName:  "info.circle"),
                                                               style: .plain,
                                                               target: self,
                                                               action: #selector(listInfo))
            navigationItem.rightBarButtonItems = [newItemBarButton, filterBarButton]
        }
        else {
            navigationItem.rightBarButtonItem = filterBarButton
        }
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
        tableView.register(TaskCell.self, forCellReuseIdentifier: taskCellID)
        tableView.register(NewTaskCell.self, forCellReuseIdentifier: newTaskCellID)
        
        tableView.backgroundColor = .systemGroupedBackground
        tableView.separatorStyle = .none
        tableView.keyboardDismissMode = .onDrag
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 100
        
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

    func handleReloadTableAftersearchBarCancelButtonClicked() {
        if !showCompletedTasks {
            filteredTasks = tasks.filter({ !($0.isCompleted ?? false) })
        } else {
            filteredTasks = tasks
        }
        sortTasks()
        tableView.reloadData()
    }
    
    func handleReloadTableAfterSearch() {
        sortTasks()
        tableView.reloadData()
    }
    
    @objc fileprivate func newItem() {
        if let id = list.id, id != "" {
            self.showTaskDetailPresent(task: nil, updateDiscoverDelegate: nil, delegate: nil, event: nil, transaction: nil, workout: nil, mindfulness: nil, template: nil, users: nil, container: nil, list: list, startDateTime: nil, endDateTime: nil)
        } else {
            self.showTaskDetailPresent(task: nil, updateDiscoverDelegate: nil, delegate: nil, event: nil, transaction: nil, workout: nil, mindfulness: nil, template: nil, users: nil, container: nil, list: nil, startDateTime: nil, endDateTime: nil)
        }
    }
    
    @objc fileprivate func listInfo() {
        showListDetailPresent(list: list, updateDiscoverDelegate: nil)
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

extension ListViewController: UITableViewDataSource, UITableViewDelegate {
    // MARK: - Table view data source
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return false
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return ""
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = UIView()
        view.tintColor = .systemGroupedBackground
        return view
        
    }
    
    // MARK: - Table view data source
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if filteredTasks.count == 0 {
            viewPlaceholder.add(for: tableView, title: .emptyTasks, subtitle: .emptyTasksEvents, priority: .medium, position: .fill)
        } else {
            viewPlaceholder.remove(from: tableView, priority: .medium)
        }
        if filteredTasks.count > 9 {
            return filteredTasks.count + 2
        } else {
            return filteredTasks.count + 1
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if filteredTasks.count > 9 {
            if indexPath.row == 0 {
                let cell = tableView.dequeueReusableCell(withIdentifier: newTaskCellID, for: indexPath) as? NewTaskCell ?? NewTaskCell()
                return cell
            }
            if filteredTasks.indices.contains(indexPath.row - 1) {
                let cell = tableView.dequeueReusableCell(withIdentifier: taskCellID, for: indexPath) as? TaskCell ?? TaskCell()
                let task = filteredTasks[indexPath.row - 1]
                if let listID = task.listID, let list = networkController.activityService.listIDs[listID], let color = list.color {
                    cell.activityTypeButton.tintColor = UIColor(ciColor: CIColor(string: color))
                } else if let list = networkController.activityService.lists[ListSourceOptions.plot.name]?.first(where: { $0.defaultList ?? false }), let color = list.color {
                    cell.activityTypeButton.tintColor = UIColor(ciColor: CIColor(string: color))
                }
                cell.configureCell(for: indexPath, task: task)
                return cell
            } else {
                let cell = tableView.dequeueReusableCell(withIdentifier: newTaskCellID, for: indexPath) as? NewTaskCell ?? NewTaskCell()
                return cell
            }
        } else {
            if filteredTasks.indices.contains(indexPath.row) {
                let cell = tableView.dequeueReusableCell(withIdentifier: taskCellID, for: indexPath) as? TaskCell ?? TaskCell()
                let task = filteredTasks[indexPath.row]
                if let listID = task.listID, let list = networkController.activityService.listIDs[listID], let color = list.color {
                    cell.activityTypeButton.tintColor = UIColor(ciColor: CIColor(string: color))
                } else if let list = networkController.activityService.lists[ListSourceOptions.plot.name]?.first(where: { $0.defaultList ?? false }), let color = list.color {
                    cell.activityTypeButton.tintColor = UIColor(ciColor: CIColor(string: color))
                }
                cell.configureCell(for: indexPath, task: task)
                return cell
            } else {
                let cell = tableView.dequeueReusableCell(withIdentifier: newTaskCellID, for: indexPath) as? NewTaskCell ?? NewTaskCell()
                return cell
            }
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if filteredTasks.count > 9 {
            if indexPath.row == 0 {
                newItem()
            } else if filteredTasks.indices.contains(indexPath.row - 1) {
                let task = filteredTasks[indexPath.row - 1]
                showTaskDetailPresent(task: task, updateDiscoverDelegate: nil, delegate: nil, event: nil, transaction: nil, workout: nil, mindfulness: nil, template: nil, users: nil, container: nil, list: nil, startDateTime: nil, endDateTime: nil)
            } else {
                newItem()
            }
        } else {
            if filteredTasks.indices.contains(indexPath.row) {
                let task = filteredTasks[indexPath.row]
                showTaskDetailPresent(task: task, updateDiscoverDelegate: nil, delegate: nil, event: nil, transaction: nil, workout: nil, mindfulness: nil, template: nil, users: nil, container: nil, list: nil, startDateTime: nil, endDateTime: nil)
            } else {
                newItem()
            }
        }
    }
}

extension ListViewController: UpdateFilter {
    func updateFilter(filterDictionary : [String: [String]]) {
        self.filterDictionary = filterDictionary
        updateTableViewWFilters()
    }
    
    func updateTableViewWFilters() {
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
        
        switch ListOptions(rawValue: list.name ?? "") {
        case .allList:
            break
        case .flaggedList:
            let flaggedTasks = filteredTasks.filter {
                if $0.flagged ?? false {
                    return true
                }
                return false
            }
            filteredTasks = flaggedTasks
        case .scheduledList:
            let scheduledTasks = filteredTasks.filter {
                if let _ = $0.endDate {
                    return true
                }
                return false
            }
            filteredTasks = scheduledTasks
        case .todayList:
            let dailyTasks = filteredTasks.filter {
                if let endDate = $0.endDate {
                    return NSCalendar.current.isDateInToday(endDate)
                }
                return false
            }
            filteredTasks = dailyTasks
        case .goalList:
            let goalTasks = tasks.filter {
                if $0.isGoal ?? false {
                    return true
                }
                return false
            }
            filteredTasks = goalTasks
        default:
            filteredTasks = filteredTasks.filter { $0.listID == list.id }
        }
        
        dispatchGroup.notify(queue: .main) {
            self.sortTasks()
            self.tableView.reloadData()
            self.tableView.layoutIfNeeded()
            self.saveUserDefaults()
        }
    }
}

extension ListViewController: UISearchBarDelegate, UISearchControllerDelegate, UISearchResultsUpdating {
    
    func updateSearchResults(for searchController: UISearchController) {}
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        tableView.tableHeaderView = nil
        searchBar.setShowsCancelButton(false, animated: true)
        searchBar.resignFirstResponder()
        handleReloadTableAftersearchBarCancelButtonClicked()
        return
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        filteredTasks = searchText.isEmpty ? tasks :
            tasks.filter({ (activity) -> Bool in
                if let name = activity.name {
                    return name.lowercased().contains(searchText.lowercased())
                }
                return ("").lowercased().contains(searchText.lowercased())
            })
        handleReloadTableAfterSearch()
    }
    
    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        searchBar.keyboardAppearance = .default
        searchBar.setShowsCancelButton(true, animated: true)
        return true
    }
}

extension ListViewController { /* hiding keyboard */
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        self.searchBar?.endEditing(true)
        if let cancelButton : UIButton = searchBar?.value(forKey: "cancelButton") as? UIButton {
            cancelButton.isEnabled = true
        }
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        setNeedsStatusBarAppearanceUpdate()
        self.searchBar?.endEditing(true)
        if let cancelButton : UIButton = searchBar.value(forKey: "cancelButton") as? UIButton {
            cancelButton.isEnabled = true
        }
    }
}
