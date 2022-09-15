//
//  ListViewController.swift
//  Plot
//
//  Created by Cory McHattie on 8/23/22.
//  Copyright © 2022 Immature Creations. All rights reserved.
//

import UIKit
import Firebase

let kShowCompletedTasks = "showCompletedTasks"

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
    
    let taskCellID = "taskCellID"
    let newTaskCellID = "newTaskCellID"
    
    var list: ListType!
    var tasks = [Activity]()
    var filteredTasks = [Activity]()
    
    var networkTasks: [Activity] {
        return networkController.activityService.tasks
    }
    lazy var users: [User] = networkController.userService.users
    lazy var filteredUsers: [User] = networkController.userService.users
    lazy var conversations: [Conversation] = networkController.conversationService.conversations
    
    var searchBar: UISearchBar?
    var searchController: UISearchController?
    
    let viewPlaceholder = ViewPlaceholder()
            
    var participants: [String: [User]] = [:]
    
    var showCompletedTasks: Bool = true
    var filters: [filter] = [.search, .showCompletedTasks, .taskCategory]
    var filterDictionary = [String: [String]]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
                
        view.backgroundColor = .systemBackground
        
        showCompletedTasks = getShowCompletedTasksBool()
        
        setupMainView()
        setupTableView()
        addObservers()
        
        if !showCompletedTasks {
            filteredTasks = tasks.filter({ !($0.isCompleted ?? false) })
        } else {
            filteredTasks = tasks
        }
        
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    fileprivate func addObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(tasksUpdated), name: .tasksUpdated, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(listsUpdated), name: .listsUpdated, object: nil)
    }
    
    @objc fileprivate func tasksUpdated() {
        if !showCompletedTasks {
            tasks = networkTasks.filter({ !($0.isCompleted ?? false) })
        } else {
            tasks = networkTasks
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
            tasks = flaggedTasks
        case .scheduledList:
            let scheduledTasks = tasks.filter {
                if let _ = $0.endDate {
                    return true
                }
                return false
            }
            tasks = scheduledTasks
        case .todayList:
            let dailyTasks = tasks.filter {
                if let endDate = $0.endDate {
                    return NSCalendar.current.isDateInToday(endDate)
                }
                return false
            }
            tasks = dailyTasks
        default:
            tasks = tasks.filter { $0.listID == list.id }
        }
        
        handleReloadTableAftersearchBarCancelButtonClicked()
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
        filteredTasks.sort { task1, task2 in
            if !(task1.isCompleted ?? false) && !(task2.isCompleted ?? false) {
                if task1.endDate ?? Date.distantPast == task2.endDate ?? Date.distantPast {
                    return task1.name ?? "" < task2.name ?? ""
                }
                return task1.endDate ?? Date.distantPast < task2.endDate ?? Date.distantPast
            } else if task1.isCompleted ?? false && task2.isCompleted ?? false {
                if task1.completedDate ?? 0 == task2.completedDate ?? 0 {
                    return task1.name ?? "" < task2.name ?? ""
                }
                return Int(truncating: task1.completedDate ?? 0) < Int(truncating: task2.completedDate ?? 0)
            }
            return !(task1.isCompleted ?? false)
        }
        tableView.reloadData()
    }
    
    func handleReloadTableAfterSearch() {
        filteredTasks.sort { task1, task2 in
            if !(task1.isCompleted ?? false) && !(task2.isCompleted ?? false) {
                if task1.endDate ?? Date.distantPast == task2.endDate ?? Date.distantPast {
                    return task1.name ?? "" < task2.name ?? ""
                }
                return task1.endDate ?? Date.distantPast < task2.endDate ?? Date.distantPast
            } else if task1.isCompleted ?? false && task2.isCompleted ?? false {
                if task1.completedDate ?? 0 == task2.completedDate ?? 0 {
                    return task1.name ?? "" < task2.name ?? ""
                }
                return Int(truncating: task1.completedDate ?? 0) < Int(truncating: task2.completedDate ?? 0)
            }
            return !(task1.isCompleted ?? false)
        }
        tableView.reloadData()
    }
    
    @objc fileprivate func newItem() {
        let destination = TaskViewController(networkController: self.networkController)
        let cancelBarButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: destination, action: nil)
        destination.navigationItem.leftBarButtonItem = cancelBarButton
        destination.list = list
        let navigationViewController = UINavigationController(rootViewController: destination)
        self.present(navigationViewController, animated: true, completion: nil)
    }
    
    @objc fileprivate func listInfo() {
        let destination = ListDetailViewController(networkController: self.networkController)
        destination.list = list
        ParticipantsFetcher.getParticipants(forList: list) { (participants) in
            destination.selectedFalconUsers = participants
            let cancelBarButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: destination, action: nil)
            destination.navigationItem.leftBarButtonItem = cancelBarButton
            let navigationViewController = UINavigationController(rootViewController: destination)
            self.present(navigationViewController, animated: true, completion: nil)
        }
    }
    
    @objc fileprivate func filter() {
        filterDictionary["showCompletedTasks"] = showCompletedTasks ? ["Yes"] : ["No"]
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
    
    func saveShowCompletedTasks() {
        UserDefaults.standard.setValue(showCompletedTasks, forKey: kShowCompletedTasks)
    }
    
    func getShowCompletedTasksBool() -> Bool {
        if let value = UserDefaults.standard.value(forKey: kShowCompletedTasks) as? Bool {
            return value
        } else {
            return true
        }
    }
    
    func showActivityIndicator() {
        
    }
    
    func hideActivityIndicator() {
        
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
        if filteredTasks.indices.contains(indexPath.row) {
            return UITableView.automaticDimension
        } else {
            return 72.66
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if filteredTasks.count == 0 {
            viewPlaceholder.add(for: tableView, title: .emptyTasks, subtitle: .emptyTasks, priority: .medium, position: .fill)
        } else {
            viewPlaceholder.remove(from: tableView, priority: .medium)
        }
        return filteredTasks.count + 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if filteredTasks.indices.contains(indexPath.row) {
            let cell = tableView.dequeueReusableCell(withIdentifier: taskCellID, for: indexPath) as? TaskCell ?? TaskCell()
            let task = filteredTasks[indexPath.row]
            if let listID = task.listID, let list = networkController.activityService.listIDs[listID], let color = list.color {
                task.listColor = color
            }
            cell.configureCell(for: indexPath, task: task)
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: newTaskCellID, for: indexPath) as? NewTaskCell ?? NewTaskCell()
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if filteredTasks.indices.contains(indexPath.row) {
            let task = filteredTasks[indexPath.row]
            showTaskDetailPush(task: task)
        } else {
            newItem()
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
        
        if filterDictionary.isEmpty {
            if !showCompletedTasks {
                filteredTasks = tasks.filter({ !($0.isCompleted ?? false) })
            } else {
                filteredTasks = tasks
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            self.tableView.reloadData()
            self.tableView.layoutIfNeeded()
            self.saveShowCompletedTasks()
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
