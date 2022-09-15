//
//  ChooseEventTableViewController.swift
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


class ChooseEventTableViewController: UITableViewController {
    var networkController: NetworkController
    
    init(networkController: NetworkController) {
        self.networkController = networkController
        super.init(style: .insetGrouped)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    let eventCellID = "eventCellID"
    
    var needDelegate = false
    
    var searchBar: UISearchBar?
    var searchEventController: UISearchController?
    
    var events = [Activity]()
    var filteredEvents = [Activity]()
    var existingEvents = [Activity]()
    
    var event: Activity?
    var activityID: String?
        
    weak var delegate : ChooseActivityDelegate?
    
    let eventCreatingGroup = DispatchGroup()
    let informationMessageSender = InformationMessageSender()
    
    let viewPlaceholder = ViewPlaceholder()
    
    // [chatID: Participants]
    var eventParticipants: [String: [User]] = [:]
    
    var movingBackwards = false
    
    let currentDate = NSNumber(value: Int((Date().localTime).timeIntervalSince1970)).int64Value
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = "Choose Event"
        
        events = events.filter { $0.containerID == nil }
        if let event = event {
            if let index = events.firstIndex(of: event) {
                events.remove(at: index)
            }
        } else if let activityID = activityID {
            if let index = events.firstIndex(where: {$0.activityID == activityID}) {
                events.remove(at: index)
            }
        } else if !existingEvents.isEmpty {
            events = events.filter { !existingEvents.contains($0) }
        }
        filteredEvents = events
        
        configureTableView()
        setupSearchController()
        scrollToFirstEventWithDate(animated: false)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        if needDelegate && movingBackwards {
            let event = Activity(dictionary: ["activityID": "" as AnyObject])
            delegate?.chosenActivity(mergeActivity: event)
        }
    }
    
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .default
    }
    
    fileprivate func configureTableView() {        
        tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 105
        tableView.register(EventCell.self, forCellReuseIdentifier: eventCellID)
        tableView.allowsMultipleSelectionDuringEditing = false
        view.backgroundColor = .systemGroupedBackground
        tableView.indicatorStyle = .default
        tableView.backgroundColor = view.backgroundColor
        if navigationItem.leftBarButtonItem != nil {
            navigationItem.leftBarButtonItem?.action = #selector(cancel)
        }
        extendedLayoutIncludesOpaqueBars = true
        edgesForExtendedLayout = UIRectEdge.top
        tableView.separatorStyle = .none
        definesPresentationContext = true
    }
    
    @objc fileprivate func cancel() {
        if needDelegate {
            let event = Activity(dictionary: ["activityID": "" as AnyObject])
            delegate?.chosenActivity(mergeActivity: event)
        }
        movingBackwards = false
        dismiss(animated: true, completion: nil)
    }
    
    @objc fileprivate func search() {
        setupSearchController()
    }
    
    fileprivate func setupSearchController() {
        if #available(iOS 11.0, *) {
            searchEventController = UISearchController(searchResultsController: nil)
            searchEventController?.searchResultsUpdater = self
            searchEventController?.obscuresBackgroundDuringPresentation = false
            searchEventController?.searchBar.delegate = self
            searchEventController?.definesPresentationContext = true
            searchEventController?.searchBar.becomeFirstResponder()
            navigationItem.searchController = searchEventController
            navigationItem.hidesSearchBarWhenScrolling = false
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
    
    func scrollToFirstEventWithDate(animated: Bool) {
        let date = Date().localTime
        var index = 0
        var eventFound = false
        var calendar = Calendar.current
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        for event in self.filteredEvents {
            if let endDate = event.endDateWTZ {
                if (date < endDate) || (event.allDay ?? false && calendar.compare(date, to: endDate, toGranularity: .day) != .orderedDescending) {
                    eventFound = true
                    break
                }
                index += 1
            }
        }
        
        if eventFound {
            let numberOfRows = self.tableView.numberOfRows(inSection: 0)
            if index < numberOfRows {
                let indexPath = IndexPath(row: index, section: 0)
                self.tableView.scrollToRow(at: indexPath, at: .top, animated: animated)
                if !animated {
                    self.tableView.reloadData()
                }
            }
        } else if !eventFound {
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
        return false
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return ""
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0
    }
    
    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        view.tintColor = .systemGroupedBackground
        
        if let headerTitle = view as? UITableViewHeaderFooterView {
            headerTitle.textLabel?.textColor = .label
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
        return filteredEvents.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: eventCellID, for: indexPath) as? EventCell ?? EventCell()
        let event = filteredEvents[indexPath.row]
        if let calendarID = event.calendarID, let calendar = networkController.activityService.calendarIDs[calendarID], let color = calendar.color {
            event.calendarColor = color
        }
        cell.configureCell(for: indexPath, activity: event, withInvitation: nil)
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let event = filteredEvents[indexPath.row]
        delegate?.chosenActivity(mergeActivity: event)
        movingBackwards = false
        if navigationItem.leftBarButtonItem != nil {
            self.dismiss(animated: true, completion: nil)
        } else {
            self.navigationController?.popViewController(animated: true)
        }
    }
}

extension ChooseEventTableViewController: UISearchBarDelegate, UISearchControllerDelegate, UISearchResultsUpdating {
    
    func updateSearchResults(for searchController: UISearchController) {}
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = nil
        searchBar.resignFirstResponder()
        filteredEvents = events
        tableView.reloadData()
        scrollToFirstEventWithDate(animated: false)
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        filteredEvents = searchText.isEmpty ? events :
            events.filter({ (event) -> Bool in
                if let name = event.name {
                    return name.lowercased().contains(searchText.lowercased())
                }
                return ("").lowercased().contains(searchText.lowercased())
            })
        
        tableView.reloadData()
        tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: false)
    }
    
    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        searchBar.keyboardAppearance = .default
        return true
    }
}

extension ChooseEventTableViewController { /* hiding keyboard */
    
    override func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        
        if #available(iOS 11.0, *) {
            searchEventController?.searchBar.endEditing(true)
        } else {
            self.searchBar?.endEditing(true)
        }
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        setNeedsStatusBarAppearanceUpdate()
        if #available(iOS 11.0, *) {
            searchEventController?.searchBar.endEditing(true)
        } else {
            self.searchBar?.endEditing(true)
        }
    }
}
