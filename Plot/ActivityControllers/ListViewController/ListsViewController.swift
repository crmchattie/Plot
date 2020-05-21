//
//  ListViewController.swift
//  Plot
//
//  Created by Cory McHattie on 4/21/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import UIKit
import Firebase

protocol ListViewControllerDataStore: class {
    func getParticipants(grocerylist: Grocerylist?, checklist: Checklist?, packinglist: Packinglist?, completion: @escaping ([User])->())
}

class ListsViewController: UIViewController {
        
    var activities = [Activity]() {
        didSet {
            for activity in activities {
                if let grocerylist = activity.grocerylist {
                    grocerylist.activity = activity
                    listList.append(grocerylist)
                }
                if activity.packinglist != nil {
                    for packinglist in activity.packinglist! {
                        if packinglist.name == "nothing" { continue }
                        packinglist.activity = activity
                        listList.append(packinglist)
                    }
                }
                if activity.checklist != nil {
                    for checklist in activity.checklist! {
                        if checklist.name == "nothing" { continue }
                        if let items = checklist.items, Array(items.keys)[0] == "name" { continue }
                        checklist.activity = activity
                        listList.append(checklist)
                    }
                }
            }
            tableView.reloadData()
        }
    }
    
    weak var activityViewController: ActivityViewController?
    
    let tableView = UITableView()
    
    let listCellID = "listCellID"
    
    var listList = [Any]()
    var users = [User]()
    var filteredUsers = [User]()
    var conversations = [Conversation]()
    
    var searchBar: UISearchBar?
    var searchController: UISearchController?
    
    let viewPlaceholder = ViewPlaceholder()
    
    var listIndex: Int = 0
    
    var participants: [String: [User]] = [:]
    
    override func viewDidLoad() {
        super.viewDidLoad()
                
        let theme = ThemeManager.currentTheme()
        view.backgroundColor = theme.generalBackgroundColor
        
        setupMainView()
        setupTableView()
        setupSearchController()

        addObservers()
                
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    fileprivate func addObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(changeTheme), name: .themeUpdated, object: nil)
    }
    
    @objc fileprivate func changeTheme() {
        let theme = ThemeManager.currentTheme()
        view.backgroundColor = theme.generalBackgroundColor
        
        tableView.indicatorStyle = theme.scrollBarStyle
        tableView.sectionIndexBackgroundColor = theme.generalBackgroundColor
        tableView.backgroundColor = theme.generalBackgroundColor
        tableView.reloadData()

    }
    
    fileprivate func setupMainView() {
        if #available(iOS 11.0, *) {
            navigationItem.largeTitleDisplayMode = .never
        }
        navigationItem.title = "Ingredient"
        view.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
    }
    
    fileprivate func setupTableView() {

        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        
        if #available(iOS 11.0, *) {
            tableView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 0).isActive = true
            tableView.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: 0).isActive = true
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: 0).isActive = true
        } else {
            tableView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 0).isActive = true
            tableView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: 0).isActive = true
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0).isActive = true
        }
        tableView.delegate = self
        tableView.dataSource = self
        tableView.indicatorStyle = ThemeManager.currentTheme().scrollBarStyle
        tableView.register(ListCell.self, forCellReuseIdentifier: listCellID)

        tableView.sectionIndexBackgroundColor = view.backgroundColor
        tableView.backgroundColor = view.backgroundColor
        tableView.separatorStyle = .none
        tableView.keyboardDismissMode = .onDrag

    }
    
    fileprivate func setupSearchController() {
        
        if #available(iOS 11.0, *) {
            searchController = UISearchController(searchResultsController: nil)
            searchController?.searchResultsUpdater = self
            searchController?.obscuresBackgroundDuringPresentation = false
            searchController?.searchBar.delegate = self
            searchController?.definesPresentationContext = true
            navigationItem.searchController = searchController
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
    
    func checkIfThereAreAnyResults(isEmpty: Bool) {
        guard isEmpty else {
            viewPlaceholder.remove(from: tableView, priority: .medium)
            return
        }
        viewPlaceholder.add(for: tableView, title: .emptyLists, subtitle: .empty, priority: .medium, position: .top)
    }
    
    func handleReloadTableAftersearchBarCancelButtonClicked() {
//        handleReloadActivities()
        tableView.reloadData()
    }
    
    func handleReloadTableAfterSearch() {
//        filteredActivities.sort { (activity1, activity2) -> Bool in
//            return activity1.startDateTime?.int64Value < activity2.startDateTime?.int64Value
//        }
        
        tableView.reloadData()
    }
    
}

extension ListsViewController: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if listList.count == 0 {
            checkIfThereAreAnyResults(isEmpty: true)
        } else {
            checkIfThereAreAnyResults(isEmpty: false)
        }
        return listList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: listCellID, for: indexPath) as? ListCell ?? ListCell()
        cell.delegate = self
        cell.activityViewControllerDataStore = self
        cell.listViewControllerDataStore = self
        cell.selectionStyle = .none
        let list = listList[indexPath.row]
        if let grocerylist = list as? Grocerylist {
            if let activity = grocerylist.activity {
                cell.configureCell(for: indexPath, grocerylist: grocerylist, checklist: nil, packinglist: nil, activity: activity)
            } else {
                cell.configureCell(for: indexPath, grocerylist: grocerylist, checklist: nil, packinglist: nil, activity: nil)
            }
        } else if let checklist = list as? Checklist {
            if let activity = checklist.activity {
                cell.configureCell(for: indexPath, grocerylist: nil, checklist: checklist, packinglist: nil, activity: activity)
            } else {
                cell.configureCell(for: indexPath, grocerylist: nil, checklist: checklist, packinglist: nil, activity: nil)
            }
        } else if let packinglist = list as? Packinglist {
            if let activity = packinglist.activity {
                cell.configureCell(for: indexPath, grocerylist: nil, checklist: nil, packinglist: packinglist, activity: activity)
            } else {
                cell.configureCell(for: indexPath, grocerylist: nil, checklist: nil, packinglist: packinglist, activity: nil)
            }
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let list = listList[indexPath.row]
        if let grocerylist = list as? Grocerylist {
            let destination = GrocerylistViewController()
            destination.grocerylist = grocerylist
            destination.delegate = self
            self.navigationController?.pushViewController(destination, animated: true)
        } else if let checklist = list as? Checklist {
            let destination = ChecklistViewController()
            destination.checklist = checklist
            destination.delegate = self
            self.navigationController?.pushViewController(destination, animated: true)
        } else if let packinglist = list as? Packinglist {
            let destination = PackinglistViewController()
            destination.packinglist = packinglist
            destination.delegate = self
            self.navigationController?.pushViewController(destination, animated: true)
        }
    }
    

}

extension ListsViewController: UISearchBarDelegate, UISearchControllerDelegate, UISearchResultsUpdating {
    
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
        
//        filteredLists = searchText.isEmpty ? activities :
//            lists.filter({ (list) -> Bool in
//                if let name = list.name {
//                    return name.lowercased().contains(searchText.lowercased())
//                }
//                return ("").lowercased().contains(searchText.lowercased())
//            })
        
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

extension ListsViewController { /* hiding keyboard */
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        
        if #available(iOS 11.0, *) {
            searchController?.searchBar.endEditing(true)
        } else {
            self.searchBar?.endEditing(true)
        }
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        setNeedsStatusBarAppearanceUpdate()
        if #available(iOS 11.0, *) {
            searchController?.searchBar.endEditing(true)
        } else {
            self.searchBar?.endEditing(true)
        }
    }
}

extension ListsViewController: UpdateChecklistDelegate {
    func updateChecklist(checklist: Checklist) {
        if listList.indices.contains(listIndex) {
            listList[listIndex] = checklist
        } else {
            listList.append(checklist)
        }
    }
}

extension ListsViewController: UpdatePackinglistDelegate {
    func updatePackinglist(packinglist: Packinglist) {
        if listList.indices.contains(listIndex) {
            listList[listIndex] = packinglist
        } else {
            listList.append(packinglist)
        }
    }
}

extension ListsViewController: UpdateGrocerylistDelegate {
    func updateGrocerylist(grocerylist: Grocerylist) {
        if listList.indices.contains(listIndex) {
            listList[listIndex] = grocerylist
        } else {
            listList.append(grocerylist)
        }
    }
}

extension ListsViewController: ListViewControllerDataStore {
    func getParticipants(grocerylist: Grocerylist?, checklist: Checklist?, packinglist: Packinglist?, completion: @escaping ([User])->()) {
        if let grocerylist = grocerylist, let ID = grocerylist.ID, let participantsIDs = grocerylist.participantsIDs, let currentUserID = Auth.auth().currentUser?.uid {
            let group = DispatchGroup()
            let olderParticipants = self.participants[ID]
            var participants: [User] = []
            for id in participantsIDs {
                if id == currentUserID {
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
                self.participants[ID] = participants
                completion(participants)
            }
        } else if let checklist = checklist, let ID = checklist.ID, let participantsIDs = checklist.participantsIDs, let currentUserID = Auth.auth().currentUser?.uid {
            let group = DispatchGroup()
            let olderParticipants = self.participants[ID]
            var participants: [User] = []
            for id in participantsIDs {
                if id == currentUserID {
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
                self.participants[ID] = participants
                completion(participants)
            }
        } else if let packinglist = packinglist, let ID = packinglist.ID, let participantsIDs = packinglist.participantsIDs, let currentUserID = Auth.auth().currentUser?.uid {
            let group = DispatchGroup()
            let olderParticipants = self.participants[ID]
            var participants: [User] = []
            for id in participantsIDs {
                if id == currentUserID {
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
                self.participants[ID] = participants
                completion(participants)
            }
        } else {
            return
        }
    }
}

extension ListsViewController: ActivityViewControllerDataStore {
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

extension ListsViewController: ListCellDelegate {
    func getInfo(grocerylist: Grocerylist?, checklist: Checklist?, packinglist: Packinglist?) {
        
    }
    
    
    func openActivity(activity: Activity) {
        activityViewController!.loadActivity(activity: activity)
    }
}
