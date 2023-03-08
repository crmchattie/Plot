//
//  GoalListViewController.swift
//  Plot
//
//  Created by Cory McHattie on 2/15/23.
//  Copyright © 2023 Immature Creations. All rights reserved.
//

import UIKit
import Firebase

class GoalListViewController: UIViewController, ObjectDetailShowing {
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
            
    var participants: [String: [User]] = [:]
    
    var showCompletedGoals: Bool = true
    var showRecurringGoals: Bool = true
    var goalSort: String = "Due Date"
    var filters: [filter] = [.search, .goalSort, .showCompletedGoals, .showRecurringGoals, .goalCategory]
    var filterDictionary = [String: [String]]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
                
        view.backgroundColor = .systemBackground
        
        showRecurringGoals = getShowRecurringGoalsBool()
        showCompletedGoals = getShowCompletedGoalsBool()
        goalSort = getSortGoals()
        
        setupMainView()
        setupTableView()
        addObservers()
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
    
    func sortandreload() {
        if showRecurringGoals {
            goals = networkGoals
        } else {
            goals = []
            for goal in networkGoals {
                if !goals.contains(where: {$0.activityID == goal.activityID}) {
                    goals.append(goal)
                }
            }
        }
        
        switch ListOptions(rawValue: list.name ?? "") {
        case .allList:
            break
        case .flaggedList:
            let flaggedGoals = goals.filter {
                if $0.flagged ?? false {
                    return true
                }
                return false
            }
            filteredGoals = flaggedGoals
        case .scheduledList:
            let scheduledGoals = goals.filter {
                if let _ = $0.endDate {
                    return true
                }
                return false
            }
            filteredGoals = scheduledGoals
        case .todayList:
            let dailyGoals = goals.filter {
                if let endDate = $0.endDate {
                    return NSCalendar.current.isDateInToday(endDate)
                }
                return false
            }
            filteredGoals = dailyGoals
        case .goalList:
            let goalGoals = goals.filter {
                if $0.isGoal ?? false {
                    return true
                }
                return false
            }
            filteredGoals = goalGoals
        default:
            filteredGoals = goals.filter { $0.listID == list.id }
        }
        
        if !showCompletedGoals {
            filteredGoals = filteredGoals.filter({ !($0.isCompleted ?? false) })
        }
        
        sortGoals()
        
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
        navigationItem.title = list.name
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
        if !showCompletedGoals {
            filteredGoals = goals.filter({ !($0.isCompleted ?? false)  })
        } else {
            filteredGoals = goals
        }
        sortGoals()
        tableView.reloadData()
    }
    
    func handleReloadTableAfterSearch() {
        sortGoals()
        tableView.reloadData()
    }
    
    @objc fileprivate func newItem() {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        if let id = self.list.id, id != "" {
            self.showGoalDetailPresent(task: nil, updateDiscoverDelegate: nil, delegate: nil, event: nil, transaction: nil, workout: nil, mindfulness: nil, template: nil, users: nil, container: nil, list: self.list, startDateTime: nil, endDateTime: nil)
        } else {
            self.showGoalDetailPresent(task: nil, updateDiscoverDelegate: nil, delegate: nil, event: nil, transaction: nil, workout: nil, mindfulness: nil, template: nil, users: nil, container: nil, list: nil, startDateTime: nil, endDateTime: nil)
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (_) in
            print("User click Dismiss button")
        }))
        
        self.present(alert, animated: true, completion: {
            print("completion block")
        })
    }
    
    @objc fileprivate func listInfo() {
        showListDetailPresent(list: list, updateDiscoverDelegate: nil)
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

extension GoalListViewController: UITableViewDataSource, UITableViewDelegate {
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
        if filteredGoals.count == 0 {
            viewPlaceholder.add(for: tableView, title: .emptyGoals, subtitle: .emptyTasksEvents, priority: .medium, position: .fill)
        } else {
            viewPlaceholder.remove(from: tableView, priority: .medium)
        }
        if filteredGoals.count > 9 {
            return filteredGoals.count + 2
        } else {
            return filteredGoals.count + 1
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if filteredGoals.count > 9 {
            if indexPath.row == 0 {
                let cell = tableView.dequeueReusableCell(withIdentifier: newTaskCellID, for: indexPath) as? NewTaskCell ?? NewTaskCell()
                return cell
            }
            if filteredGoals.indices.contains(indexPath.row - 1) {
                let cell = tableView.dequeueReusableCell(withIdentifier: taskCellID, for: indexPath) as? TaskCell ?? TaskCell()
                let goal = filteredGoals[indexPath.row - 1]
                if let listID = goal.listID, let list = networkController.activityService.listIDs[listID], let color = list.color {
                    cell.activityTypeButton.tintColor = UIColor(ciColor: CIColor(string: color))
                } else if let list = networkController.activityService.lists[ListSourceOptions.plot.name]?.first(where: { $0.defaultList ?? false }), let color = list.color {
                    cell.activityTypeButton.tintColor = UIColor(ciColor: CIColor(string: color))
                }
                cell.configureCell(for: indexPath, task: goal)
                cell.updateCompletionDelegate = self
                return cell
            } else {
                let cell = tableView.dequeueReusableCell(withIdentifier: newTaskCellID, for: indexPath) as? NewTaskCell ?? NewTaskCell()
                return cell
            }
        } else {
            if filteredGoals.indices.contains(indexPath.row) {
                let cell = tableView.dequeueReusableCell(withIdentifier: taskCellID, for: indexPath) as? TaskCell ?? TaskCell()
                let goal = filteredGoals[indexPath.row]
                if let listID = goal.listID, let list = networkController.activityService.listIDs[listID], let color = list.color {
                    cell.activityTypeButton.tintColor = UIColor(ciColor: CIColor(string: color))
                } else if let list = networkController.activityService.lists[ListSourceOptions.plot.name]?.first(where: { $0.defaultList ?? false }), let color = list.color {
                    cell.activityTypeButton.tintColor = UIColor(ciColor: CIColor(string: color))
                }
                cell.updateCompletionDelegate = self
                cell.configureCell(for: indexPath, task: goal)
                return cell
            } else {
                let cell = tableView.dequeueReusableCell(withIdentifier: newTaskCellID, for: indexPath) as? NewTaskCell ?? NewTaskCell()
                return cell
            }
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if filteredGoals.count > 9 {
            if indexPath.row == 0 {
                newItem()
            } else if filteredGoals.indices.contains(indexPath.row - 1) {
                let goal = filteredGoals[indexPath.row - 1]
                showGoalDetailPresent(task: goal, updateDiscoverDelegate: nil, delegate: nil, event: nil, transaction: nil, workout: nil, mindfulness: nil, template: nil, users: nil, container: nil, list: nil, startDateTime: nil, endDateTime: nil)

            } else {
                newItem()
            }
        } else {
            if filteredGoals.indices.contains(indexPath.row) {
                let goal = filteredGoals[indexPath.row]
                showGoalDetailPresent(task: goal, updateDiscoverDelegate: nil, delegate: nil, event: nil, transaction: nil, workout: nil, mindfulness: nil, template: nil, users: nil, container: nil, list: nil, startDateTime: nil, endDateTime: nil)

            } else {
                newItem()
            }
        }
    }
}

extension GoalListViewController: UpdateFilter {
    func updateFilter(filterDictionary : [String: [String]]) {
        self.filterDictionary = filterDictionary
        updateTableViewWFilters()
    }
    
    func updateTableViewWFilters() {
        let dispatchGroup = DispatchGroup()
        if let value = filterDictionary["showRecurringGoals"] {
            dispatchGroup.enter()
            let bool = value[0].lowercased()
            if bool == "yes" {
                goals = networkGoals
                self.showRecurringGoals = true
            } else {
                goals = []
                for goal in networkGoals {
                    if !goals.contains(where: {$0.activityID == goal.activityID}) {
                        goals.append(goal)
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
            filteredGoals = filteredGoals.filter({ (goal) -> Bool in
                if let name = goal.name {
                    return name.lowercased().contains(searchText.lowercased())
                }
                return ("").lowercased().contains(searchText.lowercased())
            })
            dispatchGroup.leave()
        }
        if let categories = filterDictionary["goalCategory"] {
            dispatchGroup.enter()
            filteredGoals = filteredGoals.filter({ (goal) -> Bool in
                if let category = goal.category {
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
        
        switch ListOptions(rawValue: list.name ?? "") {
        case .allList:
            break
        case .flaggedList:
            let flaggedGoals = filteredGoals.filter {
                if $0.flagged ?? false {
                    return true
                }
                return false
            }
            filteredGoals = flaggedGoals
        case .scheduledList:
            let scheduledGoals = filteredGoals.filter {
                if let _ = $0.endDate {
                    return true
                }
                return false
            }
            filteredGoals = scheduledGoals
        case .todayList:
            let dailyGoals = filteredGoals.filter {
                if let endDate = $0.endDate {
                    return NSCalendar.current.isDateInToday(endDate)
                }
                return false
            }
            filteredGoals = dailyGoals
        case .goalList:
            let goalGoals = goals.filter {
                if $0.isGoal ?? false {
                    return true
                }
                return false
            }
            filteredGoals = goalGoals
        default:
            filteredGoals = filteredGoals.filter { $0.listID == list.id }
        }
        
        dispatchGroup.notify(queue: .main) {
            self.sortGoals()
            self.tableView.reloadData()
            self.tableView.layoutIfNeeded()
            self.saveUserDefaults()
        }
    }
}

extension GoalListViewController: UISearchBarDelegate, UISearchControllerDelegate, UISearchResultsUpdating {
    
    func updateSearchResults(for searchController: UISearchController) {}
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        tableView.tableHeaderView = nil
        searchBar.setShowsCancelButton(false, animated: true)
        searchBar.resignFirstResponder()
        handleReloadTableAftersearchBarCancelButtonClicked()
        return
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        filteredGoals = searchText.isEmpty ? goals :
            goals.filter({ (activity) -> Bool in
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

extension GoalListViewController { /* hiding keyboard */
    
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

extension GoalListViewController: UpdateCompletionDelegate {
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
