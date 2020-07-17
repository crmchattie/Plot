//
//  ChooseListTableViewController.swift
//  Plot
//
//  Created by Cory McHattie on 7/16/20.
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

class ChooseListTableViewController: UITableViewController {
    
    let listCellID = "listCellID"
    
    fileprivate var isAppLoaded = false
    
    var searchBar: UISearchBar?
    var searchActivityController: UISearchController?
    
    var lists = [ListContainer]()
    var filteredLists = [ListContainer]()
    
    var list: ListContainer?
    var listID: String?
    var recipe: Recipe!
    var event: Event!
    var workout: Workout!
    var fsVenue: FSVenue!
    var sygicPlace: SygicPlace!
    
    var users = [User]()
    var filteredUsers = [User]()
    var participants: [String: [User]] = [:]
    
    let navigationItemActivityIndicator = NavigationItemActivityIndicator()
        
    let listCreatingGroup = DispatchGroup()
    let informationMessageSender = InformationMessageSender()
    
    let viewPlaceholder = ViewPlaceholder()
    
    // [chatID: Participants]
    var listParticipants: [String: [User]] = [:]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if recipe != nil {
            lists = lists.filter({ (list) in
                return list.checklist == nil && list.packinglist == nil
            })
            filteredLists = lists
        } else {
            lists = lists.filter({ (list) in
                return list.checklist == nil && list.grocerylist == nil && list.packinglist == nil
            })
            filteredLists = lists
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
        tableView.register(ListCell.self, forCellReuseIdentifier: listCellID)
        tableView.allowsMultipleSelectionDuringEditing = false
        view.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
        tableView.indicatorStyle = ThemeManager.currentTheme().scrollBarStyle
        tableView.backgroundColor = view.backgroundColor
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(closeList))
        
        let rightBarButton = UIButton(type: .system)
        rightBarButton.setTitle("New List", for: .normal)
        rightBarButton.titleLabel?.font = UIFont.preferredFont(forTextStyle: .body)
        rightBarButton.titleLabel?.adjustsFontForContentSizeCategory = true
        rightBarButton.addTarget(self, action: #selector(newList), for: .touchUpInside)
        
        extendedLayoutIncludesOpaqueBars = true
        edgesForExtendedLayout = UIRectEdge.top
        tableView.separatorStyle = .none
        definesPresentationContext = true
        navigationItem.title = "Choose List"
    }
    
    @objc fileprivate func closeList() {
        dismiss(animated: true, completion: nil)
    }
    
    @objc fileprivate func newList() {
        let alertController = UIAlertController(title: "Type of List", message: nil, preferredStyle: .alert)
        let groceryList = UIAlertAction(title: "Grocery List", style: .default) { (action:UIAlertAction) in
            if let currentUserID = Auth.auth().currentUser?.uid {
                let ID = Database.database().reference().child(userGrocerylistsEntity).child(currentUserID).childByAutoId().key ?? ""
                let grocerylist = Grocerylist(dictionary: ["ID": ID as AnyObject])
                grocerylist.createdDate = Date()
                grocerylist.name = "Grocery List"
                
                if self.recipe.extendedIngredients != nil {
                    self.updateGrocerylist(grocerylist: grocerylist, recipe: self.recipe, active: false)
                } else {
                    self.lookupRecipe(grocerylist: grocerylist, recipeID: self.recipe.id, active: false)
                }
            }
        }
        let activityList = UIAlertAction(title: "Activity List", style: .default) { (action:UIAlertAction) in
            if let currentUserID = Auth.auth().currentUser?.uid {
                let ID = Database.database().reference().child(userActivitylistsEntity).child(currentUserID).childByAutoId().key ?? ""
                let activitylist = Activitylist(dictionary: ["ID": ID as AnyObject])
                activitylist.name = "Activity List"
                activitylist.createdDate = Date()
                self.updateActivitylist(activitylist: activitylist, active: false)

            }
        }
        let cancelAlert = UIAlertAction(title: "Cancel", style: .cancel) { (action:UIAlertAction) in
            print("You've pressed cancel")
            
        }
        if recipe != nil {
            alertController.addAction(groceryList)
            alertController.addAction(activityList)
            alertController.addAction(cancelAlert)
        } else {
            alertController.addAction(activityList)
            alertController.addAction(cancelAlert)
        }
        self.present(alertController, animated: true, completion: nil)
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
    
    
    func handleReloadLists() {
        lists.sort { (list1, list2) -> Bool in
            return list1.lastModifiedDate < list2.lastModifiedDate
        }
        
        filteredLists = lists
    }
    
    func handleReloadTableAftersearchBarCancelButtonClicked() {
        handleReloadLists()
        self.tableView.reloadData()
    }
    
    func handleReloadTableAfterSearch() {
        filteredLists.sort { (list1, list2) -> Bool in
            return list1.lastModifiedDate < list2.lastModifiedDate
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
        return filteredLists.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: listCellID, for: indexPath) as? ListCell ?? ListCell()
        cell.delegate = self
        cell.listViewControllerDataStore = self
        cell.selectionStyle = .none
        let list = filteredLists[indexPath.row]
        if let grocerylist = list.grocerylist {
            cell.configureCell(for: indexPath, grocerylist: grocerylist, checklist: nil, packinglist: nil, activitylist: nil)
        } else if let checklist = list.checklist {
            cell.configureCell(for: indexPath, grocerylist: nil, checklist: checklist, packinglist: nil, activitylist: nil)
        } else if let activitylist = list.activitylist {
            cell.configureCell(for: indexPath, grocerylist: nil, checklist: nil, packinglist: nil, activitylist: activitylist)
        } else if let packinglist = list.packinglist {
            cell.configureCell(for: indexPath, grocerylist: nil, checklist: nil, packinglist: packinglist, activitylist: nil)
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.navigationItem.searchController?.isActive = false
        let list = filteredLists[indexPath.row]
        
        if let grocerylist = list.grocerylist {
            if recipe.extendedIngredients != nil {
                updateGrocerylist(grocerylist: grocerylist, recipe: recipe, active: true)
            } else {
                lookupRecipe(grocerylist: grocerylist, recipeID: recipe.id, active: true)
            }
        } else if let activitylist = list.activitylist {
            updateActivitylist(activitylist: activitylist, active: true)
        }
                
    }
    
    fileprivate func lookupRecipe(grocerylist: Grocerylist, recipeID: Int, active: Bool) {
        guard currentReachabilityStatus != .notReachable else {
            basicErrorAlertWith(title: basicErrorTitleForAlert, message: noInternetError, controller: self)
            return
        }
        
        let dispatchGroup = DispatchGroup()
        dispatchGroup.enter()
        Service.shared.fetchRecipesInfo(id: recipeID) { (search, err) in
            dispatchGroup.leave()
            dispatchGroup.notify(queue: .main) {
                if let recipe = search {
                    self.updateGrocerylist(grocerylist: grocerylist, recipe: recipe, active: active)
                }
            }
        }
    }
    
    fileprivate func updateGrocerylist(grocerylist: Grocerylist, recipe: Recipe, active: Bool) {
        print("updating grocery list")
        if grocerylist.ingredients != nil, let recipeIngredients = recipe.extendedIngredients {
            var glIngredients = grocerylist.ingredients!
            if let grocerylistServings = grocerylist.servings!["\(recipe.id)"], grocerylistServings != recipe.servings {
                grocerylist.servings!["\(recipe.id)"] = recipe.servings
                for recipeIngredient in recipeIngredients {
                    if let index = glIngredients.firstIndex(where: {$0 == recipeIngredient}) {
                        glIngredients[index].recipe![recipe.title] = recipeIngredient.amount ?? 0.0
                            if glIngredients[index].amount != nil && recipeIngredient.amount != nil  {
                                glIngredients[index].amount! +=  recipeIngredient.amount! - recipeIngredient.amount! * Double(grocerylistServings) / Double(recipe.servings!)
                            }
                    }
                }
            } else if grocerylist.recipes!["\(recipe.id)"] == nil {
                if grocerylist.recipes != nil {
                    grocerylist.recipes!["\(recipe.id)"] = recipe.title
                    grocerylist.servings!["\(recipe.id)"] = recipe.servings
                } else {
                    grocerylist.recipes = ["\(recipe.id)": recipe.title]
                    grocerylist.servings = ["\(recipe.id)": recipe.servings!]
                }
                for recipeIngredient in recipeIngredients {
                    if let index = glIngredients.firstIndex(where: {$0 == recipeIngredient}) {
                        glIngredients[index].recipe![recipe.title] = recipeIngredient.amount ?? 0.0
                        if glIngredients[index].amount != nil {
                            glIngredients[index].amount! += recipeIngredient.amount ?? 0.0
                        }
                    } else {
                        var recIngredient = recipeIngredient
                        recIngredient.recipe = [recipe.title: recIngredient.amount ?? 0.0]
                        glIngredients.append(recIngredient)
                    }
                }
            } else {
                self.dupeRecAlert()
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: {
                    self.removeDupeRecAlert()
                    self.dismiss(animated: true, completion: nil)
                    return
                })
            }
        } else if let recipeIngredients = recipe.extendedIngredients {
            grocerylist.ingredients = recipeIngredients
            for index in 0...grocerylist.ingredients!.count - 1 {
                grocerylist.ingredients![index].recipe = [recipe.title: grocerylist.ingredients![index].amount ?? 0.0]
            }
            grocerylist.recipes = ["\(recipe.id)": recipe.title]
            grocerylist.servings = ["\(recipe.id)": recipe.servings!]
        }
        
        self.getParticipants(grocerylist: grocerylist, checklist: nil, activitylist: nil, packinglist: nil) { (participants) in
            let createGrocerylist = GrocerylistActions(grocerylist: grocerylist, active: active, selectedFalconUsers: participants)
            createGrocerylist.createNewGrocerylist()
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    func updateActivitylist(activitylist: Activitylist, active: Bool) {
        if let object = recipe {
            let updatedTitle = object.title.removeCharacters()
            if activitylist.items != nil && activitylist.IDTypeDictionary != nil {
                activitylist.items!["\(updatedTitle)"] = false
                activitylist.IDTypeDictionary!["\(updatedTitle)"] = ["\(object.id)":"recipe"]
            } else {
                activitylist.items = ["\(updatedTitle)": false]
                activitylist.IDTypeDictionary = ["\(updatedTitle)": ["\(object.id)":"recipe"]]
            }
        } else if let object = workout {
            let updatedTitle = object.title.removeCharacters()
            if activitylist.items != nil && activitylist.IDTypeDictionary != nil {
                activitylist.items!["\(updatedTitle)"] = false
                activitylist.IDTypeDictionary!["\(updatedTitle)"] = ["\(object.identifier)":"workout"]
            } else {
                activitylist.items = ["\(updatedTitle)": false]
                activitylist.IDTypeDictionary = ["\(updatedTitle)": ["\(object.identifier)":"workout"]]
            }
        } else if let object = event {
            let updatedTitle = object.name.removeCharacters()
            if activitylist.items != nil && activitylist.IDTypeDictionary != nil {
                activitylist.items!["\(updatedTitle)"] = false
                activitylist.IDTypeDictionary!["\(updatedTitle)"] = ["\(object.id)":"event"]
            } else {
                activitylist.items = ["\(updatedTitle)": false]
                activitylist.IDTypeDictionary = ["\(updatedTitle)": ["\(object.id)":"event"]]
            }
        } else if let object = fsVenue {
            let updatedTitle = object.name.removeCharacters()
            if activitylist.items != nil && activitylist.IDTypeDictionary != nil {
                activitylist.items!["\(updatedTitle)"] = false
                activitylist.IDTypeDictionary!["\(updatedTitle)"] = ["\(object.id)":"place"]
            } else {
                activitylist.items = ["\(updatedTitle)": false]
                activitylist.IDTypeDictionary = ["\(updatedTitle)": ["\(object.id)":"place"]]
            }
        }
        
        self.getParticipants(grocerylist: nil, checklist: nil, activitylist: activitylist, packinglist: nil) { (participants) in
            let createActivitylist = ActivitylistActions(activitylist: activitylist, active: active, selectedFalconUsers: participants)
            createActivitylist.createNewActivitylist()
            self.dismiss(animated: true, completion: nil)
        }
    }
}

extension ChooseListTableViewController: UISearchBarDelegate, UISearchControllerDelegate, UISearchResultsUpdating {
    
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
        
        filteredLists = searchText.isEmpty ? lists :
            lists.filter({ (list) -> Bool in
                return list.name.lowercased().contains(searchText.lowercased())
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

extension ChooseListTableViewController { /* hiding keyboard */
    
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

extension ChooseListTableViewController: ListViewControllerDataStore {
    func getParticipants(grocerylist: Grocerylist?, checklist: Checklist?, activitylist: Activitylist?, packinglist: Packinglist?, completion: @escaping ([User])->()) {
        if let grocerylist = grocerylist, let ID = grocerylist.ID, let participantsIDs = grocerylist.participantsIDs, let currentUserID = Auth.auth().currentUser?.uid {
            let group = DispatchGroup()
            let olderParticipants = self.participants[ID]
            var participants: [User] = []
            for id in participantsIDs {
                if grocerylist.admin == currentUserID && id == currentUserID {
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
                if checklist.admin == currentUserID && id == currentUserID {
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
                if packinglist.admin == currentUserID && id == currentUserID {
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

extension ChooseListTableViewController: ListCellDelegate {
    func openActivity(activityID: String) {
        
    }
    
    func openChat(forConversation conversationID: String?, grocerylist: Grocerylist?, checklist: Checklist?, packinglist: Packinglist?, activitylist: Activitylist?) {
        
    }

}
