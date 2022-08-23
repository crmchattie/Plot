//
//  ListViewController.swift
//  Plot
//
//  Created by Cory McHattie on 4/21/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import UIKit
import Firebase

protocol ListDataStore: AnyObject {
    func getParticipants(forList list: ListType, completion: @escaping ([User])->())
}

class ListsViewController: UIViewController, ActivityDetailShowing {
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
    
    var filters: [filter] = [.search, .taskCategory]
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
    
    fileprivate func setupMainView() {
        navigationItem.largeTitleDisplayMode = .never
        navigationItem.title = "Lists"
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
    
    func checkIfThereAreAnyResults(isEmpty: Bool) {
        guard isEmpty else {
            viewPlaceholder.remove(from: tableView, priority: .medium)
            return
        }
        viewPlaceholder.add(for: tableView, title: .emptyLists, subtitle: .emptyLists, priority: .medium, position: .top)
    }
    
    func sortandreload() {
        filteredTasks = []
        lists = [:]
        taskList = [:]
        
        sections = [.tasks]
        let dailyList = ListType(id: "", name: "Today", color: "", source: "")
        let dailyTasks = tasks.filter {
            if let endDate = $0.endDate {
                return NSCalendar.current.isDateInToday(endDate)
            }
            return false
        }
        taskList[dailyList] = dailyTasks
        
        let scheduledList = ListType(id: "", name: "Scheduled", color: "", source: "")
        let scheduledTasks = tasks.filter {
            if let _ = $0.endDate {
                return true
            }
            return false
        }
        taskList[scheduledList] = scheduledTasks
        
        let flaggedList = ListType(id: "", name: "Flagged", color: "", source: "")
        let flaggedTasks = tasks.filter {
            if $0.flagged ?? false {
                return true
            }
            return false
        }
        taskList[flaggedList] = flaggedTasks
        
        let allList = ListType(id: "", name: "All", color: "", source: "")
        let allTasks = tasks
        taskList[allList] = allTasks
        
        let listOfLists = [dailyList, scheduledList, flaggedList, allList]
        lists[.tasks, default: []].append(contentsOf: listOfLists)
        
        for (_, currentLists) in networkController.activityService.lists {
            for list in currentLists {
                let currentTaskList = tasks.filter { $0.listID == list.id }
                if !currentTaskList.isEmpty {
                    sections.insert(.lists, at: 1)
                    lists[.lists, default: []].append(list)
                    taskList[list, default: []].append(contentsOf: currentTaskList)
                }
            }
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
        if !networkController.activityService.lists.keys.contains(ListOptions.apple.name) {
            let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            
            alert.addAction(UIAlertAction(title: "Task", style: .default, handler: { (_) in
                let destination = TaskViewController(networkController: self.networkController)
                let cancelBarButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: destination, action: nil)
                destination.navigationItem.leftBarButtonItem = cancelBarButton
                let navigationViewController = UINavigationController(rootViewController: destination)
                self.present(navigationViewController, animated: true, completion: nil)
            }))
            
            alert.addAction(UIAlertAction(title: "List", style: .default, handler: { (_) in
                self.newList()
            }))
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (_) in
                print("User click Dismiss button")
            }))
            
            self.present(alert, animated: true, completion: {
                print("completion block")
            })
        } else {
            let destination = TaskViewController(networkController: self.networkController)
            let cancelBarButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: destination, action: nil)
            destination.navigationItem.leftBarButtonItem = cancelBarButton
            let navigationViewController = UINavigationController(rootViewController: destination)
            self.present(navigationViewController, animated: true, completion: nil)
        }
    }
    
    @objc func newList() {
        let destination = ListDetailViewController()
        destination.delegate = self
        let navigationViewController = UINavigationController(rootViewController: destination)
        self.present(navigationViewController, animated: true, completion: nil)
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
        if section == .lists {
            header.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
            header.titleLabel.text = section.name
            header.subTitleLabel.isHidden = true
            header.sectionType = section
        }
        return header

    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if sections[section] == .lists {
            return 40
        }
        return 0
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
            cell.configureCell(for: indexPath, list: list)
            return cell
        } else if !filteredTasks.isEmpty {
            let task = filteredTasks[indexPath.row]
            let cell = tableView.dequeueReusableCell(withIdentifier: taskCellID, for: indexPath) as? TaskCell ?? TaskCell()
            cell.activityDataStore = self
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
            showTaskDetail(task: task)
        }
    }
}

extension ListsViewController: ActivityDataStore {
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
    
    func getParticipants(forActivity activity: Activity, completion: @escaping ([User])->()) {
        guard let activityID = activity.activityID, let participantsIDs = activity.participantsIDs, let currentUserID = Auth.auth().currentUser?.uid else {
            return
        }
        
        
        let group = DispatchGroup()
        let olderParticipants = self.participants[activityID]
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
            self.participants[activityID] = participants
            completion(participants)
        }
    }
}

extension ListsViewController: ListDataStore {
    func getParticipants(forList list: ListType, completion: @escaping ([User])->()) {
        guard let id = list.id, let participantsIDs = list.participantsIDs, let currentUserID = Auth.auth().currentUser?.uid else {
            return
        }
        
        
        let group = DispatchGroup()
        let olderParticipants = self.participants[id]
        var participants: [User] = []
        for id in participantsIDs {
            // Only if the current user is created this activity
            if list.admin == currentUserID && id == currentUserID {
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
            self.participants[id] = participants
            completion(participants)
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

extension ListsViewController: ListDetailDelegate {
    func update() {
        
    }
}

