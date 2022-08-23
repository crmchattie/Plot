//
//  ChooseTaskTableViewController.swift
//  Plot
//
//  Created by Cory McHattie on 8/23/22.
//  Copyright © 2022 Immature Creations. All rights reserved.
//

import UIKit
import Contacts
import Firebase
import SDWebImage

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

class ChooseTaskTableViewController: UITableViewController {
    
    let taskCellID = "taskCellID"
    
    var needDelegate = false
    
    var searchBar: UISearchBar?
    var searchTaskController: UISearchController?
    
    var tasks = [Activity]()
    var filteredTasks = [Activity]()
    var existingTasks = [Activity]()
    
    var task: Activity?
    var activityID: String?
    var users = [User]()
    var filteredUsers = [User]()
        
    weak var delegate : ChooseActivityDelegate?
    
    let taskCreatingGroup = DispatchGroup()
    let informationMessageSender = InformationMessageSender()
    
    let viewPlaceholder = ViewPlaceholder()
    
    // [chatID: Participants]
    var taskParticipants: [String: [User]] = [:]
    
    var movingBackwards = false
        
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = "Choose Task"
        
        tasks = tasks.filter { $0.containerID == nil }
        if let task = task {
            if let index = tasks.firstIndex(of: task) {
                tasks.remove(at: index)
            }
        } else if let activityID = activityID {
            if let index = tasks.firstIndex(where: {$0.activityID == activityID}) {
                tasks.remove(at: index)
            }
        } else if !existingTasks.isEmpty {
            tasks = tasks.filter { !existingTasks.contains($0) }
        }
        filteredTasks = tasks
        
        configureTableView()
        
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        if needDelegate && movingBackwards {
            let task = Activity(dictionary: ["activityID": "" as AnyObject])
            delegate?.chosenActivity(mergeActivity: task)
        }
    }
    
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return ThemeManager.currentTheme().statusBarStyle
    }
    
    fileprivate func configureTableView() {
        tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 105
        tableView.register(EventCell.self, forCellReuseIdentifier: eventCellID)
        tableView.allowsMultipleSelectionDuringEditing = false
        view.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
        tableView.indicatorStyle = ThemeManager.currentTheme().scrollBarStyle
        tableView.backgroundColor = view.backgroundColor
        if navigationItem.leftBarButtonItem != nil {
            navigationItem.leftBarButtonItem?.action = #selector(cancel)
        }
//        let searchBarButton = UIBarButtonItem(barButtonSystemItem: .search, target: self, action: #selector(search))
//        navigationItem.rightBarButtonItem = searchBarButton
        extendedLayoutIncludesOpaqueBars = true
        edgesForExtendedLayout = UIRectEdge.top
        tableView.separatorStyle = .none
        definesPresentationContext = true
    }
    
    @objc fileprivate func cancel() {
        if needDelegate {
            let task = Activity(dictionary: ["activityID": "" as AnyObject])
            delegate?.chosenActivity(mergeActivity: task)
        }
        movingBackwards = false
        dismiss(animated: true, completion: nil)
    }
    
    @objc fileprivate func search() {
        setupSearchController()
    }
    
    fileprivate func setupSearchController() {
        if #available(iOS 11.0, *) {
            searchTaskController = UISearchController(searchResultsController: nil)
            searchTaskController?.searchResultsUpdater = self
            searchTaskController?.obscuresBackgroundDuringPresentation = false
            searchTaskController?.searchBar.delegate = self
            searchTaskController?.definesPresentationContext = true
            searchTaskController?.searchBar.becomeFirstResponder()
            navigationItem.searchController = searchTaskController
            navigationItem.hidesSearchBarWhenScrolling = true
        } else {
            searchBar = UISearchBar()
            searchBar?.delegate = self
            searchBar?.placeholder = "Search"
            searchBar?.searchBarStyle = .minimal
            searchBar?.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: 50)
            searchBar?.becomeFirstResponder()
            tableView.tableHeaderView = searchBar
        }
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
    
    // MARK: - Table view data source
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return false
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return ""
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0
    }
    
    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        view.tintColor = ThemeManager.currentTheme().generalBackgroundColor
        
        if let headerTitle = view as? UITableViewHeaderFooterView {
            headerTitle.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
        }
    }
    
    // MARK: - Table view data source
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredTasks.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: taskCellID, for: indexPath) as? TaskCell ?? TaskCell()
        cell.activityDataStore = self
        let task = filteredTasks[indexPath.row]
        cell.configureCell(for: indexPath, task: task)
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let task = filteredTasks[indexPath.row]
        delegate?.chosenActivity(mergeActivity: task)
        movingBackwards = false
        if navigationItem.leftBarButtonItem != nil {
            self.dismiss(animated: true, completion: nil)
        } else {
            self.navigationController?.popViewController(animated: true)
        }
    }
}

extension ChooseTaskTableViewController: UISearchBarDelegate, UISearchControllerDelegate, UISearchResultsUpdating {
    
    func updateSearchResults(for searchController: UISearchController) {}
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = nil
        searchBar.setShowsCancelButton(false, animated: true)
        searchBar.resignFirstResponder()
        handleReloadTableAftersearchBarCancelButtonClicked()
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        
        filteredTasks = searchText.isEmpty ? tasks :
            tasks.filter({ (task) -> Bool in
                if let name = task.name {
                    return name.lowercased().contains(searchText.lowercased())
                }
                return ("").lowercased().contains(searchText.lowercased())
            })
        
        handleReloadTableAfterSearch()
    }
    
    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        searchBar.keyboardAppearance = ThemeManager.currentTheme().keyboardAppearance
        guard #available(iOS 11.0, *) else {
            searchBar.setShowsCancelButton(true, animated: true)
            return true
        }
        return true
    }
}

extension ChooseTaskTableViewController { /* hiding keyboard */
    
    override func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        
        if #available(iOS 11.0, *) {
            searchTaskController?.searchBar.endEditing(true)
        } else {
            self.searchBar?.endEditing(true)
        }
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        setNeedsStatusBarAppearanceUpdate()
        if #available(iOS 11.0, *) {
            searchTaskController?.searchBar.endEditing(true)
        } else {
            self.searchBar?.endEditing(true)
        }
    }
}

extension ChooseTaskTableViewController: ActivityDataStore {
    func getParticipants(forActivity task: Activity, completion: @escaping ([User])->()) {
        
    }
}
