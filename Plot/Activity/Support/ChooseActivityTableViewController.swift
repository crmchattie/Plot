//
//  ChooseActivityTableViewController.swift
//  Plot
//
//  Created by Cory McHattie on 4/10/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
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

protocol ChooseActivityDelegate: AnyObject {
    func chosenActivity(mergeActivity: Activity)
}


class ChooseActivityTableViewController: UITableViewController {
    
    let activityCellID = "activityCellID"
    
    var needDelegate = false
    
    var searchBar: UISearchBar?
    var searchActivityController: UISearchController?
    
    var activities = [Activity]()
    var filteredActivities = [Activity]()
    var existingActivities = [Activity]()
    
    var activity: Activity?
    var activityID: String?
    var grocerylist: Grocerylist?
    var checklist: Checklist?
    var activitylist: Activitylist?
    var packinglist: Packinglist?
    var users = [User]()
    var filteredUsers = [User]()
    
    let navigationItemActivityIndicator = NavigationItemActivityIndicator()
    
    weak var delegate : ChooseActivityDelegate?
    
    let activityCreatingGroup = DispatchGroup()
    let informationMessageSender = InformationMessageSender()
    
    let viewPlaceholder = ViewPlaceholder()
    
    // [chatID: Participants]
    var activityParticipants: [String: [User]] = [:]
    
    var movingBackwards = false
    
    let currentDate = NSNumber(value: Int((Date().localTime).timeIntervalSince1970)).int64Value
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = "Choose Activity"
        
        activities = activities.filter { $0.containerID == nil }
        if let activity = activity {
            if let index = activities.firstIndex(of: activity) {
                activities.remove(at: index)
            }
        } else if let activityID = activityID {
            if let index = activities.firstIndex(where: {$0.activityID == activityID}) {
                activities.remove(at: index)
            }
        } else if !existingActivities.isEmpty {
            activities = activities.filter { !existingActivities.contains($0) }
        }
        filteredActivities = activities
        
        configureTableView()
        scrollToFirstActivityWithDate(animated: false)
        
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        if needDelegate && movingBackwards {
            let activity = Activity(dictionary: ["activityID": "" as AnyObject])
            delegate?.chosenActivity(mergeActivity: activity)
        }
    }
    
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return ThemeManager.currentTheme().statusBarStyle
    }
    
    fileprivate func configureTableView() {        
        tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 105
        tableView.register(ActivityCell.self, forCellReuseIdentifier: activityCellID)
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
            let activity = Activity(dictionary: ["activityID": "" as AnyObject])
            delegate?.chosenActivity(mergeActivity: activity)
        }
        movingBackwards = false
        dismiss(animated: true, completion: nil)
    }
    
    @objc fileprivate func search() {
        setupSearchController()
    }
    
    fileprivate func setupSearchController() {
        if #available(iOS 11.0, *) {
            searchActivityController = UISearchController(searchResultsController: nil)
            searchActivityController?.searchResultsUpdater = self
            searchActivityController?.obscuresBackgroundDuringPresentation = false
            searchActivityController?.searchBar.delegate = self
            searchActivityController?.definesPresentationContext = true
            searchActivityController?.searchBar.becomeFirstResponder()
            navigationItem.searchController = searchActivityController
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
        filteredActivities = activities
        filteredActivities.sort { (activity1, activity2) -> Bool in
            if currentDate.isBetween(activity1.startDateTime?.int64Value ?? 0, and: activity1.endDateTime?.int64Value ?? 0) && currentDate.isBetween(activity2.startDateTime?.int64Value ?? 0, and: activity2.endDateTime?.int64Value ?? 0) {
                return activity1.startDateTime?.int64Value ?? 0 < activity2.startDateTime?.int64Value ?? 0
            } else if currentDate.isBetween(activity1.startDateTime?.int64Value ?? 0, and: activity1.endDateTime?.int64Value ?? 0) {
                return currentDate < activity2.startDateTime?.int64Value ?? 0
            } else if currentDate.isBetween(activity2.startDateTime?.int64Value ?? 0, and: activity2.endDateTime?.int64Value ?? 0) {
                return activity1.startDateTime?.int64Value ?? 0 < currentDate
            }
            return activity1.startDateTime?.int64Value ?? 0 < activity2.startDateTime?.int64Value ?? 0
        }
        scrollToFirstActivityWithDate(animated: true)
    }
    
    func handleReloadTableAfterSearch() {
        filteredActivities.sort { (activity1, activity2) -> Bool in
            if currentDate.isBetween(activity1.startDateTime?.int64Value ?? 0, and: activity1.endDateTime?.int64Value ?? 0) && currentDate.isBetween(activity2.startDateTime?.int64Value ?? 0, and: activity2.endDateTime?.int64Value ?? 0) {
                return activity1.startDateTime?.int64Value ?? 0 < activity2.startDateTime?.int64Value ?? 0
            } else if currentDate.isBetween(activity1.startDateTime?.int64Value ?? 0, and: activity1.endDateTime?.int64Value ?? 0) {
                return currentDate < activity2.startDateTime?.int64Value ?? 0
            } else if currentDate.isBetween(activity2.startDateTime?.int64Value ?? 0, and: activity2.endDateTime?.int64Value ?? 0) {
                return activity1.startDateTime?.int64Value ?? 0 < currentDate
            }
            return activity1.startDateTime?.int64Value ?? 0 < activity2.startDateTime?.int64Value ?? 0
        }
        scrollToFirstActivityWithDate(animated: true)
    }
    
    func scrollToFirstActivityWithDate(animated: Bool) {
        let date = Date().localTime
        var index = 0
        var activityFound = false
        var calendar = Calendar.current
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        for activity in self.filteredActivities {
            if let endDate = activity.endDateWTZ {
                if (date < endDate) || (activity.allDay ?? false && calendar.compare(date, to: endDate, toGranularity: .day) != .orderedDescending) {
                    activityFound = true
                    break
                }
                index += 1
            }
        }
        
        if activityFound {
            let numberOfRows = self.tableView.numberOfRows(inSection: 0)
            if index < numberOfRows {
                let indexPath = IndexPath(row: index, section: 0)
                self.tableView.scrollToRow(at: indexPath, at: .top, animated: animated)
                if !animated {
                    self.tableView.reloadData()
                }
            }
        } else if !activityFound {
            let numberOfRows = self.tableView.numberOfRows(inSection: 0)
            if numberOfRows > 0 {
                let indexPath = IndexPath(row: numberOfRows - 1, section: 0)
                self.tableView.scrollToRow(at: indexPath, at: .top, animated: animated)
                if !animated {
                    self.tableView.reloadData()
                }
            }
        }
    }
    
    // MARK: - Table view data source
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
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
        return filteredActivities.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: activityCellID, for: indexPath) as? ActivityCell ?? ActivityCell()
        
        cell.activityDataStore = self
        
        let activity = filteredActivities[indexPath.row]
        
        cell.configureCell(for: indexPath, activity: activity, withInvitation: nil)
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let activity = filteredActivities[indexPath.row]
        delegate?.chosenActivity(mergeActivity: activity)
        movingBackwards = false
        if navigationItem.leftBarButtonItem != nil {
            self.dismiss(animated: true, completion: nil)
        } else {
            self.navigationController?.popViewController(animated: true)
        }
    }
}

extension ChooseActivityTableViewController: UISearchBarDelegate, UISearchControllerDelegate, UISearchResultsUpdating {
    
    func updateSearchResults(for searchController: UISearchController) {}
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = nil
        searchBar.setShowsCancelButton(false, animated: true)
        searchBar.resignFirstResponder()
        handleReloadTableAftersearchBarCancelButtonClicked()
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        
        filteredActivities = searchText.isEmpty ? activities :
            activities.filter({ (activity) -> Bool in
                if let name = activity.name {
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

extension ChooseActivityTableViewController { /* hiding keyboard */
    
    override func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        
        if #available(iOS 11.0, *) {
            searchActivityController?.searchBar.endEditing(true)
        } else {
            self.searchBar?.endEditing(true)
        }
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        setNeedsStatusBarAppearanceUpdate()
        if #available(iOS 11.0, *) {
            searchActivityController?.searchBar.endEditing(true)
        } else {
            self.searchBar?.endEditing(true)
        }
    }
}

extension ChooseActivityTableViewController: ActivityDataStore {
    func getParticipants(forActivity activity: Activity, completion: @escaping ([User])->()) {
        
    }
}
