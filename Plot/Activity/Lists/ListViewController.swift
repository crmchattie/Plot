//
//  ListViewController.swift
//  Plot
//
//  Created by Cory McHattie on 8/23/22.
//  Copyright © 2022 Immature Creations. All rights reserved.
//

import UIKit
import Firebase

class ListViewController: UIViewController, ActivityDetailShowing {
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
    
    var list: ListType!
    var tasks = [Activity]()
    var filteredTasks = [Activity]()
    lazy var networkTasks = networkController.activityService.tasks
    
    lazy var users: [User] = networkController.userService.users
    lazy var filteredUsers: [User] = networkController.userService.users
    lazy var conversations: [Conversation] = networkController.conversationService.conversations
    
    var searchBar: UISearchBar?
    var searchController: UISearchController?
    
    let viewPlaceholder = ViewPlaceholder()
            
    var participants: [String: [User]] = [:]
    
    var filters: [filter] = [.search, .taskCategory]
    var filterDictionary = [String: [String]]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
                
        let theme = ThemeManager.currentTheme()
        view.backgroundColor = theme.generalBackgroundColor
        
        setupMainView()
        setupTableView()
        addObservers()
        
        filteredTasks = tasks
        
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
        tasks = networkTasks.filter { $0.listID ?? "" == list.id }
        handleReloadTableAftersearchBarCancelButtonClicked()
    }
    
    fileprivate func setupMainView() {
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
        viewPlaceholder.add(for: tableView, title: .emptyTasks, subtitle: .emptyTasks, priority: .medium, position: .top)
    }
    
    func handleReloadTableAftersearchBarCancelButtonClicked() {
        filteredTasks = tasks
        filteredTasks.sort { task1, task2 in
            if let task1Date = task1.endDate, let task2Date = task2.endDate, task1Date == task2Date {
                return task1.name ?? "" < task2.name ?? ""
            }
            return task1.endDate ?? Date.distantPast < task2.endDate ?? Date.distantPast
        }
    }
    
    func handleReloadTableAfterSearch() {
        filteredTasks.sort { task1, task2 in
            if let task1Date = task1.endDate, let task2Date = task2.endDate, task1Date == task2Date {
                return task1.name ?? "" < task2.name ?? ""
            }
            return task1.endDate ?? Date.distantPast < task2.endDate ?? Date.distantPast
        }
    }
    
    @objc fileprivate func newItem() {
        let destination = TaskViewController(networkController: self.networkController)
        let cancelBarButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: destination, action: nil)
        destination.navigationItem.leftBarButtonItem = cancelBarButton
        destination.list = list
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
        view.tintColor = ThemeManager.currentTheme().generalBackgroundColor
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
            viewPlaceholder.add(for: tableView, title: .emptyTasks, subtitle: .emptyTasks, priority: .medium, position: .fill)
        } else {
            viewPlaceholder.remove(from: tableView, priority: .medium)
        }
        return filteredTasks.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: taskCellID, for: indexPath) as? TaskCell ?? TaskCell()
        cell.activityDataStore = self
        let task = filteredTasks[indexPath.row]
        cell.configureCell(for: indexPath, task: task)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let task = filteredTasks[indexPath.row]
        showTaskDetail(task: task)
    }
}

extension ListViewController: ActivityDataStore {
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

extension ListViewController: UpdateFilter {
    func updateFilter(filterDictionary : [String: [String]]) {
        self.filterDictionary = filterDictionary
        updateTableViewWFilters()
    }
    
    func updateTableViewWFilters() {
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
        if filterDictionary.isEmpty {
            handleReloadTableAftersearchBarCancelButtonClicked()
        }
        
        dispatchGroup.notify(queue: .main) {
            self.tableView.reloadData()
            self.tableView.layoutIfNeeded()
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
        searchBar.keyboardAppearance = ThemeManager.currentTheme().keyboardAppearance
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
