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

protocol ChooseActivityDelegate: class {
    func chosenActivity(mergeActivity: Activity)
}


class ChooseActivityTableViewController: UITableViewController {
    
    let activityCellID = "activityCellID"
  
    fileprivate var isAppLoaded = false
    
    var searchBar: UISearchBar?
    var searchActivityController: UISearchController?
    
    var activities = [Activity]()
    var filteredActivities = [Activity]()
    
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
        
  override func viewDidLoad() {
    super.viewDidLoad()
    
    if let activity = activity {
        if let index = activities.firstIndex(of: activity) {
            activities.remove(at: index)
            filteredActivities.remove(at: index)
        }
    } else if let activityID = activityID {
        if let index = activities.firstIndex(where: {$0.activityID == activityID}) {
            activities.remove(at: index)
            filteredActivities.remove(at: index)
        }
    } else if checklist != nil || grocerylist != nil || activitylist != nil || packinglist != nil {
        activities = activities.filter({ (activity) in
            return activity.recipeID == nil && activity.workoutID == nil && activity.eventID == nil && activity.placeID == nil
        })
        filteredActivities = activities
    }
   
    configureTableView()
    setupSearchController()
    
    tableView.rowHeight = UITableView.automaticDimension
    tableView.estimatedRowHeight = 105
  }
    
  
  override var preferredStatusBarStyle: UIStatusBarStyle {
    return ThemeManager.currentTheme().statusBarStyle
  }

  fileprivate func configureTableView() {
    tableView.register(ActivityCell.self, forCellReuseIdentifier: activityCellID)
    tableView.allowsMultipleSelectionDuringEditing = false
    view.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
    tableView.indicatorStyle = ThemeManager.currentTheme().scrollBarStyle
    tableView.backgroundColor = view.backgroundColor
    navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(closeActivity))
    extendedLayoutIncludesOpaqueBars = true
    edgesForExtendedLayout = UIRectEdge.top
    tableView.separatorStyle = .none
    definesPresentationContext = true
    navigationItem.title = "Choose Activity"
  }
  
    @objc fileprivate func closeActivity() {
        dismiss(animated: true, completion: nil)
    }

  fileprivate func setupSearchController() {
      
      if #available(iOS 11.0, *) {
          searchActivityController = UISearchController(searchResultsController: nil)
          searchActivityController?.searchResultsUpdater = self
          searchActivityController?.obscuresBackgroundDuringPresentation = false
          searchActivityController?.searchBar.delegate = self
          searchActivityController?.definesPresentationContext = true
          navigationItem.searchController = searchActivityController
          navigationItem.hidesSearchBarWhenScrolling = true
      } else {
          searchBar = UISearchBar()
          searchBar?.delegate = self
          searchBar?.placeholder = "Search"
          searchBar?.searchBarStyle = .minimal
          searchBar?.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: 50)
          tableView.tableHeaderView = searchBar
      }
  }
  
  
  func handleReloadActivities() {
      activities.sort { (activity1, activity2) -> Bool in
          return activity1.startDateTime?.int64Value < activity2.startDateTime?.int64Value
      }
      
      filteredActivities = activities
      
  }
  
  func handleReloadTableAftersearchBarCancelButtonClicked() {
      handleReloadActivities()
      self.tableView.reloadData()
  }
  
  func handleReloadTableAfterSearch() {
      filteredActivities.sort { (activity1, activity2) -> Bool in
          return activity1.startDateTime?.int64Value < activity2.startDateTime?.int64Value
      }
      
      self.tableView.reloadData()
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
      
          cell.delegate = self
          cell.activityViewControllerDataStore = self
          cell.selectionStyle = .none
        
        let activity = filteredActivities[indexPath.row]
        
        cell.configureCell(for: indexPath, activity: activity, withInvitation: nil)
      
        return cell
    }
  
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.navigationItem.searchController?.isActive = false
        let activity = filteredActivities[indexPath.row]
        delegate?.chosenActivity(mergeActivity: activity)
        self.dismiss(animated: true, completion: nil)

    }
}

extension ChooseActivityTableViewController: UISearchBarDelegate, UISearchControllerDelegate, UISearchResultsUpdating {
    
    func updateSearchResults(for searchController: UISearchController) {}
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = nil
        guard #available(iOS 11.0, *) else {
            searchBar.setShowsCancelButton(false, animated: true)
            searchBar.resignFirstResponder()
            return
        }
        
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

extension ChooseActivityTableViewController: ActivityViewControllerDataStore {
    func getParticipants(forActivity activity: Activity, completion: @escaping ([User])->()) {
        
    }
}

extension ChooseActivityTableViewController: ActivityCellDelegate {
    func openMap(forActivity activity: Activity) {
        
    }
    
    func openChat(forConversation conversationID: String?, activityID: String?) {
        
    }
        
}
