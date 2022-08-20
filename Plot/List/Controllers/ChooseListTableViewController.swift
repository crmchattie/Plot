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

protocol ChooseListDelegate: AnyObject {
    func chosenList(list: ListContainer)
}

class ChooseListTableViewController: UITableViewController {
    
    let checklistFetcher = ChecklistFetcher()
    let activitylistFetcher = ActivitylistFetcher()
    let grocerylistFetcher = GrocerylistFetcher()
    var checklists = [Checklist]()
    var activitylists = [Activitylist]()
    var grocerylists = [Grocerylist]()
    var packinglists = [Packinglist]()
    
    weak var delegate : ChooseListDelegate?
    
    let listCellID = "listCellID"
    var needDelegate = false
    var grocerylistExists = false
    
    var searchBar: UISearchBar?
    var searchActivityController: UISearchController?
    
    var lists = [ListContainer]()
    var filteredLists = [ListContainer]()
    var listList = [ListContainer]()
    
    var list: ListContainer?
    var listID: String?
    var recipe: Recipe!
    var event: TicketMasterEvent!
    var workout: PreBuiltWorkout!
    var fsVenue: FSVenue!
    var sygicPlace: SygicPlace!
    var activityType: String!
    
    var users = [User]()
    var filteredUsers = [User]()
    var participants: [String: [User]] = [:]
    
    let navigationItemActivityIndicator = NavigationItemActivityIndicator()
        
    let listCreatingGroup = DispatchGroup()
    let informationMessageSender = InformationMessageSender()
    
    let viewPlaceholder = ViewPlaceholder()
    
    // [chatID: Participants]
    var listParticipants: [String: [User]] = [:]
    
    var movingBackwards = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureTableView()
        setupSearchController()
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        if needDelegate && movingBackwards {
            let newList = ListContainer()
            delegate?.chosenList(list: newList)
        }
    }
    
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return ThemeManager.currentTheme().statusBarStyle
    }
    
    fileprivate func configureTableView() {
        
        
        tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 105
        tableView.register(ListCell.self, forCellReuseIdentifier: listCellID)
        tableView.allowsMultipleSelectionDuringEditing = false
        view.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
        tableView.indicatorStyle = ThemeManager.currentTheme().scrollBarStyle
        tableView.backgroundColor = view.backgroundColor
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(closeList))
        
        
        if !needDelegate {
            let rightBarButton = UIButton(type: .system)
            rightBarButton.setTitle("New List", for: .normal)
            rightBarButton.addTarget(self, action: #selector(newList), for: .touchUpInside)
        }
        
        extendedLayoutIncludesOpaqueBars = true
        edgesForExtendedLayout = UIRectEdge.top
        tableView.separatorStyle = .none
        definesPresentationContext = true
        navigationItem.title = "Choose List"
    }
    
    @objc fileprivate func closeList() {
        if needDelegate {
            let newList = ListContainer()
            delegate?.chosenList(list: newList)
        }
        movingBackwards = false
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
        if recipe != nil {
            lists = lists.filter({ (list) in
                return list.checklist == nil && list.packinglist == nil
            })
            filteredLists = lists
        } else if needDelegate {
            if grocerylistExists {
                filteredLists = lists.filter{ !listList.contains($0) }
                filteredLists = filteredLists.filter({ (list) -> Bool in
                    list.grocerylist == nil
                })
            } else {
                filteredLists = lists.filter{ !listList.contains($0) }
            }
        } else {
            lists = lists.filter({ (list) in
                return list.checklist == nil && list.grocerylist == nil && list.packinglist == nil
            })
            filteredLists = lists
        }
        
        filteredLists.sort { (list1, list2) -> Bool in
            return list1.lastModifiedDate < list2.lastModifiedDate
        }
        
        self.tableView.reloadData()
    }
    
    func handleReloadTableAftersearchBarCancelButtonClicked() {
        handleReloadLists()
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
        let list = filteredLists[indexPath.row]
        if needDelegate {
            delegate?.chosenList(list: list)
            movingBackwards = false
            dismiss(animated: true, completion: nil)
        } else if let grocerylist = list.grocerylist {
            if recipe.extendedIngredients != nil {
                print("extendedIngredients does not equal nil")
                updateGrocerylist(grocerylist: grocerylist, recipe: recipe, active: true)
            } else {
                print("extendedIngredients does equal nil")
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
                grocerylist.ingredients = glIngredients
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
            self.recAddAlert()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: {
                self.removeRecAddAlert()
                self.dismiss(animated: true, completion: nil)
                return
            })
        }
    }
    
    func updateActivitylist(activitylist: Activitylist, active: Bool) {
        if let object = recipe, let activityType = activityType {
            if activitylist.items != nil && activitylist.IDTypeDictionary != nil {
                activitylist.items!["\(object.title)"] = false
                activitylist.IDTypeDictionary!["\(object.title)"] = ["\(object.id)":"\(activityType)"]
            } else {
                activitylist.items = ["\(object.title)": false]
                activitylist.IDTypeDictionary = ["\(object.title)": ["\(object.id)":"\(activityType)"]]
            }
        } else if let object = workout, let activityType = activityType {
            if activitylist.items != nil && activitylist.IDTypeDictionary != nil {
                activitylist.items!["\(object.title)"] = false
                activitylist.IDTypeDictionary!["\(object.title)"] = ["\(object.identifier)":"\(activityType)"]
            } else {
                activitylist.items = ["\(object.title)": false]
                activitylist.IDTypeDictionary = ["\(object.title)": ["\(object.identifier)":"\(activityType)"]]
            }
        } else if let object = event, let activityType = activityType {
            if activitylist.items != nil && activitylist.IDTypeDictionary != nil {
                activitylist.items!["\(object.name)"] = false
                activitylist.IDTypeDictionary!["\(object.name)"] = ["\(object.id)":"\(activityType)"]
            } else {
                activitylist.items = ["\(object.name)": false]
                activitylist.IDTypeDictionary = ["\(object.name)": ["\(object.id)":"\(activityType)"]]
            }
        } else if let object = fsVenue, let activityType = activityType {
            if activitylist.items != nil && activitylist.IDTypeDictionary != nil {
                activitylist.items!["\(object.name)"] = false
                activitylist.IDTypeDictionary!["\(object.name)"] = ["\(object.id)":"\(activityType)"]
            } else {
                activitylist.items = ["\(object.name)": false]
                activitylist.IDTypeDictionary = ["\(object.name)": ["\(object.id)":"\(activityType)"]]
            }
        } else {
            print("object not found")
            return
        }
        
        
        print("updating participants")
        
        self.getParticipants(grocerylist: nil, checklist: nil, activitylist: activitylist, packinglist: nil) { (participants) in
            let createActivitylist = ActivitylistActions(activitylist: activitylist, active: active, selectedFalconUsers: participants)
            createActivitylist.createNewActivitylist()
            self.actAddAlert()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: {
                self.removeActAddAlert()
                self.dismiss(animated: true, completion: nil)
                return
            })
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
        } else if let activitylist = activitylist, let ID = activitylist.ID, let participantsIDs = activitylist.participantsIDs, let currentUserID = Auth.auth().currentUser?.uid {
            let group = DispatchGroup()
            let olderParticipants = self.participants[ID]
            var participants: [User] = []
            for id in participantsIDs {
                if activitylist.admin == currentUserID && id == currentUserID {
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
