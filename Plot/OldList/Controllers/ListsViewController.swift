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
    let taskCellID = "taskCellID"
    
    var sections = [SectionType]()
    var lists = [SectionType: [ListType]]()
    var taskList = [ListType: [Activity]]()
    var filteredLists = [SectionType: [ListType]]()
    var tasks: [Activity] {
        return networkController.activityService.tasks
    }
    var filteredTasks = [Activity]()
    
    lazy var users: [User] = networkController.userService.users
    lazy var filteredUsers: [User] = networkController.userService.users
    lazy var conversations: [Conversation] = networkController.conversationService.conversations
    
    var searchBar: UISearchBar?
    var searchController: UISearchController?
    
    let viewPlaceholder = ViewPlaceholder()
        
    var listIndex: Int = 0
    
    var participants: [String: [User]] = [:]
    
    var filters: [filter] = [.search, .showCompletedTasks, .taskCategory]
    var filterDictionary = [String: [String]]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let theme = ThemeManager.currentTheme()
        view.backgroundColor = theme.generalBackgroundColor
        
        setupMainView()
        setupTableView()
        sortandreload()
        addObservers()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: false)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    fileprivate func addObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(changeTheme), name: .themeUpdated, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(tasksUpdated), name: .tasksUpdated, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(listsUpdated), name: .listsUpdated, object: nil)

    }
    
    @objc fileprivate func changeTheme() {
        let theme = ThemeManager.currentTheme()
        view.backgroundColor = theme.generalBackgroundColor
        tableView.indicatorStyle = theme.scrollBarStyle
        tableView.sectionIndexBackgroundColor = theme.generalBackgroundColor
        tableView.backgroundColor = theme.generalBackgroundColor
        tableView.reloadData()
        
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
        view.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
        
        let newItemBarButton =  UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(newItem))
        let filterBarButton = UIBarButtonItem(image: UIImage(named: "filter"), style: .plain, target: self, action: #selector(filter))
        navigationItem.rightBarButtonItems = [newItemBarButton, filterBarButton]
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
        tableView.indicatorStyle = ThemeManager.currentTheme().scrollBarStyle
        tableView.register(TableViewHeader.self,
                           forHeaderFooterViewReuseIdentifier: headerCellID)
        tableView.register(ListCell.self, forCellReuseIdentifier: listCellID)
        tableView.register(TaskCell.self, forCellReuseIdentifier: taskCellID)
        
        tableView.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
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
        if filterDictionary.isEmpty {
            viewPlaceholder.add(for: tableView, title: .emptyLists, subtitle: .emptyLists, priority: .medium, position: .top)
        } else {
            viewPlaceholder.add(for: tableView, title: .emptyTasks, subtitle: .emptyTasks, priority: .medium, position: .top)
        }
    }
    
    func sortandreload() {
        filteredTasks = []
        sections = []
        lists = [:]
        taskList = [:]
        
        var listOfLists = [ListType]()
        
        let flaggedTasks = tasks.filter {
            if $0.flagged ?? false {
                return true
            }
            return false
        }
        if !flaggedTasks.isEmpty {
            let flaggedList = ListType(id: "", name: ListOptions.flaggedList.rawValue, color: "", source: "", admin: nil)
            taskList[flaggedList] = flaggedTasks
            listOfLists.insert(flaggedList, at: 0)
        }
        
        let scheduledTasks = tasks.filter {
            if let _ = $0.endDate {
                return true
            }
            return false
        }
        if !scheduledTasks.isEmpty {
            let scheduledList = ListType(id: "", name: ListOptions.scheduledList.rawValue, color: "", source: "", admin: nil)
            taskList[scheduledList] = scheduledTasks
            listOfLists.insert(scheduledList, at: 0)
        }
        
        let dailyTasks = tasks.filter {
            if let endDate = $0.endDate {
                return NSCalendar.current.isDateInToday(endDate)
            }
            return false
        }
        if !dailyTasks.isEmpty {
            let dailyList = ListType(id: "", name: ListOptions.todayList.rawValue, color: "", source: "", admin: nil)
            taskList[dailyList] = dailyTasks
            listOfLists.insert(dailyList, at: 0)
        }
        
        if !listOfLists.isEmpty {
            sections.append(.presetLists)
            lists[.presetLists, default: []].append(contentsOf: listOfLists)
        }
        
        listOfLists = []
        
        for (id, list) in networkController.activityService.listIDs {
            let currentTaskList = tasks.filter { $0.listID == id }
            if !currentTaskList.isEmpty {
                listOfLists.append(list)
                taskList[list] = currentTaskList
            }
        }
        
        if !listOfLists.isEmpty {
            sections.insert(.myLists, at: 1)
            lists[.myLists, default: []].append(contentsOf: listOfLists.sorted(by: {$0.name ?? "" < $1.name ?? "" }))
        }
        
        if !tasks.isEmpty {
            sections.append(.tasks)
            filteredTasks = tasks
        }
                
        filteredLists = lists
        tableView.reloadData()
    }
    
    func openList(list: ListType) {
        let destination = ListViewController(networkController: self.networkController)
        destination.list = list
        destination.tasks = taskList[list] ?? []
        navigationController?.pushViewController(destination, animated: true)
    }
    
    @objc fileprivate func newItem() {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "Task", style: .default, handler: { (_) in
            let destination = TaskViewController(networkController: self.networkController)
            let cancelBarButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: destination, action: nil)
            destination.navigationItem.leftBarButtonItem = cancelBarButton
            let navigationViewController = UINavigationController(rootViewController: destination)
            self.present(navigationViewController, animated: true, completion: nil)
        }))
        
        alert.addAction(UIAlertAction(title: "List", style: .default, handler: { (_) in
            let destination = ListDetailViewController(networkController: self.networkController)
            let cancelBarButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: destination, action: nil)
            destination.navigationItem.leftBarButtonItem = cancelBarButton
            let navigationViewController = UINavigationController(rootViewController: destination)
            self.present(navigationViewController, animated: true, completion: nil)
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (_) in
            print("User click Dismiss button")
        }))
        
        self.present(alert, animated: true, completion: {
            print("completion block")
        })
    }
    
    @objc fileprivate func filter() {
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
    
    func showActivityIndicator() {
        
    }
    
    func hideActivityIndicator() {
        
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
        header.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
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
                task.listColor = color
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
            showTaskDetailPush(task: task)
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let section = sections[indexPath.section]
        if let filteredLists = filteredLists[section], filteredLists.indices.contains(indexPath.row) {
            return 65
        } else {
            return UITableView.automaticDimension
        }
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
        let dispatchGroup = DispatchGroup()
        if let value = filterDictionary["search"] {
            dispatchGroup.enter()
            let searchText = value[0]
            filteredTasks = tasks.filter({ (task) -> Bool in
                if let name = task.name {
                    return name.lowercased().contains(searchText.lowercased())
                }
                return ("").lowercased().contains(searchText.lowercased())
            })
            dispatchGroup.leave()
        }
        if let categories = filterDictionary["taskCategory"] {
            dispatchGroup.enter()
            filteredTasks = tasks.filter({ (task) -> Bool in
                if let category = task.category {
                    return categories.contains(category)
                }
                return false
            })
            dispatchGroup.leave()
        }
        if filterDictionary.isEmpty {
            sortandreload()
        }
        
        dispatchGroup.notify(queue: .main) {
            self.tableView.reloadData()
            self.tableView.layoutIfNeeded()
        }
    }
}

extension ListsViewController: GIDSignInDelegate {
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        if (error == nil) {
            self.networkController.activityService.updatePrimaryCalendar(value: CalendarSourceOptions.google.name)
            self.networkController.activityService.updatePrimaryList(value: ListSourceOptions.google.name)
        } else {
          print("\(error.localizedDescription)")
        }
    }
}

