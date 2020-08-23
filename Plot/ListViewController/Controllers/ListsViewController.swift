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
    func getParticipants(grocerylist: Grocerylist?, checklist: Checklist?, activitylist: Activitylist?, packinglist: Packinglist?, completion: @escaping ([User])->())
}

protocol HomeBaseLists: class {
    func sendLists(lists: [ListContainer])
}

class ListsViewController: UIViewController {
    
    weak var delegate: HomeBaseLists?
    
    var activities = [Activity]()
    
    weak var activityViewController: ActivityViewController?
    
    let tableView = UITableView()
    
    let listCellID = "listCellID"
    
    var listListCopy = [ListContainer]()
    var listList = [ListContainer]()
    var filteredlistList = [ListContainer]()
    var checklists = [Checklist]()
    var activitylists = [Activitylist]()
    var grocerylists = [Grocerylist]()
    var packinglists = [Packinglist]()
    var users = [User]()
    var filteredUsers = [User]()
    var conversations = [Conversation]()
    
    let checklistFetcher = ChecklistFetcher()
    let activitylistFetcher = ActivitylistFetcher()
    let grocerylistFetcher = GrocerylistFetcher()
    //    let packinglistFetcher = PackinglistFetcher()
    
    var chatLogController: ChatLogController? = nil
    var messagesFetcher: MessagesFetcher? = nil
    
    var searchBar: UISearchBar?
    var searchController: UISearchController?
    
    let viewPlaceholder = ViewPlaceholder()
        
    var listIndex: Int = 0
    
    var participants: [String: [User]] = [:]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        fetchLists()
        
        let theme = ThemeManager.currentTheme()
        view.backgroundColor = theme.generalBackgroundColor
        
        setupMainView()
        setupTableView()
        
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
            navigationController?.navigationBar.prefersLargeTitles = false
        }
        navigationItem.title = "Lists"
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
    
    func fetchLists() {
        checklistFetcher.fetchChecklists { (checklists) in
            for checklist in checklists {
                if checklist.name == "nothing" { continue }
                if let items = checklist.items, Array(items.keys)[0] == "name" { continue }
                self.checklists.append(checklist)
            }
            self.observeChecklistsForCurrentUser()
        }
        activitylistFetcher.fetchActivitylists { (activitylists) in
            for activitylist in activitylists {
                if activitylist.name == "nothing" { continue }
                if let items = activitylist.items, Array(items.keys)[0] == "name" { continue }
                self.activitylists.append(activitylist)
            }
            self.observeActivitylistsForCurrentUser()
        }
        grocerylistFetcher.fetchGrocerylists { (grocerylists) in
            for grocerylist in grocerylists {
                if grocerylist.name == "nothing" { continue }
                self.grocerylists.append(grocerylist)
            }
            self.observeGrocerylistsForCurrentUser()
        }
        
        sortandreload()
    }
    
    func observeChecklistsForCurrentUser() {
        self.checklistFetcher.observeChecklistForCurrentUser(checklistsAdded: { [weak self] checklistsAdded in
                for checklist in checklistsAdded {
                    if let index = self!.checklists.firstIndex(where: {$0 == checklist}) {
                        self!.checklists[index] = checklist
                        if let ID = checklist.ID {
                            self!.updateCellForCLID(ID: ID, checklist: checklist)
                            self!.sortandreload()
                        }
                    } else {
                        self!.checklists.append(checklist)
                        self!.sortandreload()
                    }
                }
            }, checklistsRemoved: { [weak self] checklistsRemoved in
                for checklist in checklistsRemoved {
                    if let index = self!.checklists.firstIndex(where: {$0 == checklist}) {
                        self!.checklists.remove(at: index)
                        self!.sortandreload()
                    }
                }
            }, checklistsChanged: { [weak self] checklistsChanged in
                for checklist in checklistsChanged {
                    if let index = self!.checklists.firstIndex(where: {$0 == checklist}) {
                        self!.checklists[index] = checklist
                        if let ID = checklist.ID {
                            self!.updateCellForCLID(ID: ID, checklist: checklist)
                            self!.sortandreload()
                        }
                    }
                }
            }
        )
    }
    
    func observeActivitylistsForCurrentUser() {
        self.activitylistFetcher.observeActivitylistForCurrentUser(activitylistsAdded: { [weak self] activitylistsAdded in
                for activitylist in activitylistsAdded {
                    if let index = self!.activitylists.firstIndex(where: {$0 == activitylist}) {
                        self!.activitylists[index] = activitylist
                        if let ID = activitylist.ID {
                            self!.updateCellForALID(ID: ID, activitylist: activitylist)
                            self!.sortandreload()
                        }
                    } else {
                        self!.activitylists.append(activitylist)
                        self!.sortandreload()
                    }
                }
            }, activitylistsRemoved: { [weak self] activitylistsRemoved in
                for activitylist in activitylistsRemoved {
                    if let index = self!.activitylists.firstIndex(where: {$0 == activitylist}) {
                        self!.activitylists.remove(at: index)
                        self!.sortandreload()
                    }
                }
            }, activitylistsChanged: { [weak self] activitylistsChanged in
                for activitylist in activitylistsChanged {
                    if let index = self!.activitylists.firstIndex(where: {$0 == activitylist}) {
                        self!.activitylists[index] = activitylist
                        if let ID = activitylist.ID {
                            self!.updateCellForALID(ID: ID, activitylist: activitylist)
                            self!.sortandreload()
                        }
                    }
                }
            }
        )
    }
    
    func observeGrocerylistsForCurrentUser() {
        self.grocerylistFetcher.observeGrocerylistForCurrentUser(grocerylistsAdded: { [weak self] grocerylistsAdded in
            for grocerylist in grocerylistsAdded {
                if let index = self!.grocerylists.firstIndex(where: {$0 == grocerylist}) {
                    self!.grocerylists[index] = grocerylist
                    if let ID = grocerylist.ID {
                        self!.updateCellForGLID(ID: ID, grocerylist: grocerylist)
                        self!.sortandreload()
                    }
                } else {
                    self!.grocerylists.append(grocerylist)
                    self!.sortandreload()
                }
            }
            }, grocerylistsRemoved: { [weak self] grocerylistsRemoved in
                for grocerylist in grocerylistsRemoved {
                    if let index = self!.grocerylists.firstIndex(where: {$0 == grocerylist}) {
                        self!.grocerylists.remove(at: index)
                        self!.sortandreload()
                    }
                }
            }, grocerylistsChanged: { [weak self] grocerylistsChanged in
                for grocerylist in grocerylistsChanged {
                    if let index = self!.grocerylists.firstIndex(where: {$0 == grocerylist}) {
                        self!.grocerylists[index] = grocerylist
                        if let ID = grocerylist.ID {
                            self!.updateCellForGLID(ID: ID, grocerylist: grocerylist)
                            self!.sortandreload()
                        }
                    }
                }
            }
        )
    }
    
    func updateCellForCLID(ID: String, checklist: Checklist) {
        if let index = listList.firstIndex(where: {$0.ID == ID}) {
            listList[index].checklist = checklist
            let indexPath = IndexPath(row: index, section: 0)
            updateCell(at: indexPath)
        }
    }
    
    func updateCellForALID(ID: String, activitylist: Activitylist) {
        if let index = listList.firstIndex(where: {$0.ID == ID}) {
            listList[index].activitylist = activitylist
            let indexPath = IndexPath(row: index, section: 0)
            updateCell(at: indexPath)
        }
    }
    
    func updateCellForGLID(ID: String, grocerylist: Grocerylist) {
        if let index = listList.firstIndex(where: {$0.ID == ID}) {
            listList[index].grocerylist = grocerylist
            let indexPath = IndexPath(row: index, section: 0)
            updateCell(at: indexPath)
        }
    }
    
    fileprivate func updateCell(at indexPath: IndexPath) {
        tableView.beginUpdates()
        tableView.reloadRows(at: [indexPath], with: .none)
        tableView.endUpdates()
    }
    
    fileprivate func deleteCell(at indexPath: IndexPath) {
        tableView.beginUpdates()
        tableView.deleteRows(at: [indexPath], with: .none)
        tableView.endUpdates()
    }
    
    func checkIfThereAreAnyResults(isEmpty: Bool) {
        guard isEmpty else {
            viewPlaceholder.remove(from: tableView, priority: .medium)
            return
        }
        viewPlaceholder.add(for: tableView, title: .emptyLists, subtitle: .emptyLists, priority: .medium, position: .top)
    }
    
    func sortandreload() {
        listList = (checklists.map { ListContainer(grocerylist: nil, checklist: $0, activitylist: nil, packinglist: nil) } + activitylists.map { ListContainer(grocerylist: nil, checklist: nil, activitylist: $0, packinglist: nil) } + grocerylists.map { ListContainer(grocerylist: $0, checklist: nil, activitylist: nil, packinglist: nil) }).sorted { $0.lastModifiedDate > $1.lastModifiedDate }
        delegate?.sendLists(lists: listList)
        listListCopy = listList
        tableView.reloadData()
    }
    
    func handleReloadTableAfterSearch() {
        filteredlistList.sort { (list1, list2) -> Bool in
            return list1.lastModifiedDate > list2.lastModifiedDate
        }
        listList = filteredlistList
        tableView.reloadData()
        
    }
    
}

extension ListsViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        
        let delete = setupDeleteAction(at: indexPath)
        let mute = setupMuteAction(at: indexPath)
        
        return [delete, mute]
    }
    
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
        cell.listViewControllerDataStore = self
        cell.selectionStyle = .none
        let list = listList[indexPath.row]
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
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let list = listList[indexPath.row]
        if let grocerylist = list.grocerylist {
            let destination = GrocerylistViewController()
            destination.hidesBottomBarWhenPushed = true
            destination.grocerylist = grocerylist
            destination.comingFromLists = true
            destination.connectedToAct = grocerylist.activityID != nil
            destination.users = self.users
            destination.filteredUsers = self.filteredUsers
            destination.activities = self.activities
            destination.conversations = self.conversations
            self.getParticipants(grocerylist: grocerylist, checklist: nil, activitylist: nil, packinglist: nil) { (participants) in
                destination.selectedFalconUsers = participants
                self.navigationController?.pushViewController(destination, animated: true)
            }
        } else if let checklist = list.checklist {
            let destination = ChecklistViewController()
            destination.hidesBottomBarWhenPushed = true
            destination.checklist = checklist
            destination.comingFromLists = true
            destination.connectedToAct = checklist.activityID != nil
            destination.users = self.users
            destination.filteredUsers = self.filteredUsers
            destination.activities = self.activities
            destination.conversations = self.conversations
            self.getParticipants(grocerylist: nil, checklist: checklist, activitylist: nil, packinglist: nil) { (participants) in
                destination.selectedFalconUsers = participants
                self.navigationController?.pushViewController(destination, animated: true)
            }
        } else if let activitylist = list.activitylist {
            let destination = ActivitylistViewController()
            destination.hidesBottomBarWhenPushed = true
            destination.activitylist = activitylist
            destination.comingFromLists = true
            destination.connectedToAct = activitylist.activityID != nil
            destination.users = self.users
            destination.filteredUsers = self.filteredUsers
            destination.activities = self.activities
            destination.conversations = self.conversations
            self.getParticipants(grocerylist: nil, checklist: nil, activitylist: activitylist, packinglist: nil) { (participants) in
                destination.selectedFalconUsers = participants
                self.navigationController?.pushViewController(destination, animated: true)
            }
        } else if let packinglist = list.packinglist {
            let destination = PackinglistViewController()
            destination.hidesBottomBarWhenPushed = true
            destination.packinglist = packinglist
            destination.comingFromLists = true
            destination.connectedToAct = packinglist.activityID != nil
            destination.users = self.users
            destination.filteredUsers = self.filteredUsers
            destination.activities = self.activities
            destination.conversations = self.conversations
            self.getParticipants(grocerylist: nil, checklist: nil, activitylist: nil, packinglist: packinglist) { (participants) in
                destination.selectedFalconUsers = participants
                self.navigationController?.pushViewController(destination, animated: true)
            }
        }
    }
    
    
}

extension ListsViewController: ListViewControllerDataStore {
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

extension ListsViewController: ListCellDelegate {
    func openActivity(activityID: String) {
        if let index = self.activities.firstIndex(where: {$0.activityID == activityID}) {
            activityViewController!.loadActivity(activity: activities[index])
        }
    }
    
    func openChat(forConversation conversationID: String?, grocerylist: Grocerylist?, checklist: Checklist?, packinglist: Packinglist?, activitylist: Activitylist?) {
        if conversationID == nil {
            let destination = ChooseChatTableViewController()
            let navController = UINavigationController(rootViewController: destination)
            destination.delegate = self
            if let grocerylist = grocerylist {
                destination.grocerylist = grocerylist
            } else if let checklist = checklist {
                destination.checklist = checklist
            } else if let activitylist = activitylist {
                destination.activitylist = activitylist
            } else if let packinglist = packinglist {
                destination.packinglist = packinglist
            }
            destination.conversations = conversations
            destination.pinnedConversations = conversations
            destination.filteredConversations = conversations
            destination.filteredPinnedConversations = conversations
            present(navController, animated: true, completion: nil)
        } else {
            let groupChatDataReference = Database.database().reference().child("groupChats").child(conversationID!).child(messageMetaDataFirebaseFolder)
            groupChatDataReference.observeSingleEvent(of: .value, with: { (snapshot) in
                guard var dictionary = snapshot.value as? [String: AnyObject] else { return }
                dictionary.updateValue(conversationID as AnyObject, forKey: "id")
                
                if let membersIDs = dictionary["chatParticipantsIDs"] as? [String:AnyObject] {
                    dictionary.updateValue(Array(membersIDs.values) as AnyObject, forKey: "chatParticipantsIDs")
                }
                
                let conversation = Conversation(dictionary: dictionary)
                
                if conversation.chatName == nil {
                    if let grocerylist = grocerylist, let ID = grocerylist.ID {
                        if let participants = self.participants[ID], participants.count > 0 {
                            let user = participants[0]
                            conversation.chatName = user.name
                            conversation.chatPhotoURL = user.photoURL
                            conversation.chatThumbnailPhotoURL = user.thumbnailPhotoURL
                        }
                    } else if let checklist = checklist, let ID = checklist.ID {
                        if let participants = self.participants[ID], participants.count > 0 {
                            let user = participants[0]
                            conversation.chatName = user.name
                            conversation.chatPhotoURL = user.photoURL
                            conversation.chatThumbnailPhotoURL = user.thumbnailPhotoURL
                        }
                    } else if let packinglist = packinglist, let ID = packinglist.ID {
                        if let participants = self.participants[ID], participants.count > 0 {
                            let user = participants[0]
                            conversation.chatName = user.name
                            conversation.chatPhotoURL = user.photoURL
                            conversation.chatThumbnailPhotoURL = user.thumbnailPhotoURL
                        }
                    }
                }
                
                self.chatLogController = ChatLogController(collectionViewLayout: AutoSizingCollectionViewFlowLayout())
                self.messagesFetcher = MessagesFetcher()
                self.messagesFetcher?.delegate = self
                self.messagesFetcher?.loadMessagesData(for: conversation)
            })
        }
    }
}

extension ListsViewController: MessagesDelegate {
    
    func messages(shouldChangeMessageStatusToReadAt reference: DatabaseReference) {
        chatLogController?.updateMessageStatus(messageRef: reference)
    }
    
    func messages(shouldBeUpdatedTo messages: [Message], conversation: Conversation) {
        
        chatLogController?.hidesBottomBarWhenPushed = true
        chatLogController?.messagesFetcher = messagesFetcher
        chatLogController?.messages = messages
        chatLogController?.conversation = conversation
        //chatLogController?.activityID = activityID
        
        if let membersIDs = conversation.chatParticipantsIDs, let uid = Auth.auth().currentUser?.uid, membersIDs.contains(uid) {
            chatLogController?.observeTypingIndicator()
            chatLogController?.configureTitleViewWithOnlineStatus()
        }
        
        chatLogController?.messagesFetcher.collectionDelegate = chatLogController
        guard let destination = chatLogController else { return }
        
        self.chatLogController?.startCollectionViewAtBottom()
        
        
        // If we're presenting a modal sheet
        if let presentedViewController = presentedViewController as? UINavigationController {
            presentedViewController.pushViewController(destination, animated: true)
        } else {
            navigationController?.pushViewController(destination, animated: true)
        }
        
        chatLogController = nil
        messagesFetcher?.delegate = nil
        messagesFetcher = nil
    }
}

extension ListsViewController: ChooseChatDelegate {
    func chosenChat(chatID: String, activityID: String?, grocerylistID: String?, checklistID: String?, packinglistID: String?, activitylistID: String?) {
        if let grocerylistID = grocerylistID {
            let updatedConversationID = ["conversationID": chatID as AnyObject]
            Database.database().reference().child(grocerylistsEntity).child(grocerylistID).updateChildValues(updatedConversationID)
            if let conversation = conversations.first(where: {$0.chatID == chatID}) {
                if conversation.grocerylists != nil {
                    var grocerylists = conversation.grocerylists!
                    grocerylists.append(grocerylistID)
                    let updatedGrocerylists = [grocerylistsEntity: grocerylists as AnyObject]
                    Database.database().reference().child("groupChats").child(conversation.chatID!).child(messageMetaDataFirebaseFolder).updateChildValues(updatedGrocerylists)
                } else {
                    let updatedGrocerylists = [grocerylistsEntity: [grocerylistID] as AnyObject]
                    Database.database().reference().child("groupChats").child(conversation.chatID!).child(messageMetaDataFirebaseFolder).updateChildValues(updatedGrocerylists)
                }
                if let activityID = activityID {
                    Database.database().reference().child("activities").child(activityID).child(messageMetaDataFirebaseFolder).updateChildValues(updatedConversationID)
                    if conversation.activities != nil {
                        var activities = conversation.activities!
                        activities.append(activityID)
                        let updatedActivities = ["activities": activities as AnyObject]
                        Database.database().reference().child("groupChats").child(conversation.chatID!).child(messageMetaDataFirebaseFolder).updateChildValues(updatedActivities)
                    } else {
                        let updatedActivities = ["activities": [activityID] as AnyObject]
                        Database.database().reference().child("groupChats").child(conversation.chatID!).child(messageMetaDataFirebaseFolder).updateChildValues(updatedActivities)
                    }
                    Database.database().reference().child("activities").child(activityID).updateChildValues(updatedConversationID)
                }
            }
            self.connectedToChatAlert()
            self.dismiss(animated: true, completion: nil)
        } else if let checklistID = checklistID {
            let updatedConversationID = ["conversationID": chatID as AnyObject]
            Database.database().reference().child(checklistsEntity).child(checklistID).updateChildValues(updatedConversationID)
            if let conversation = conversations.first(where: {$0.chatID == chatID}) {
                if conversation.checklists != nil {
                    var checklists = conversation.checklists!
                    checklists.append(checklistID)
                    let updatedChecklists = [checklistsEntity: checklists as AnyObject]
                    Database.database().reference().child("groupChats").child(conversation.chatID!).child(messageMetaDataFirebaseFolder).updateChildValues(updatedChecklists)
                } else {
                    let updatedChecklists = [checklistsEntity: [checklistID] as AnyObject]
                    Database.database().reference().child("groupChats").child(conversation.chatID!).child(messageMetaDataFirebaseFolder).updateChildValues(updatedChecklists)
                }
                if let activityID = activityID {
                    Database.database().reference().child("activities").child(activityID).child(messageMetaDataFirebaseFolder).updateChildValues(updatedConversationID)
                    if conversation.activities != nil {
                        var activities = conversation.activities!
                        activities.append(activityID)
                        let updatedActivities = ["activities": activities as AnyObject]
                        Database.database().reference().child("groupChats").child(conversation.chatID!).child(messageMetaDataFirebaseFolder).updateChildValues(updatedActivities)
                    } else {
                        let updatedActivities = ["activities": [activityID] as AnyObject]
                        Database.database().reference().child("groupChats").child(conversation.chatID!).child(messageMetaDataFirebaseFolder).updateChildValues(updatedActivities)
                    }
                    Database.database().reference().child("activities").child(activityID).updateChildValues(updatedConversationID)
                }
            }
            self.connectedToChatAlert()
            self.dismiss(animated: true, completion: nil)
        } else if let activitylistID = activitylistID {
            let updatedConversationID = ["conversationID": chatID as AnyObject]
            Database.database().reference().child(activitylistsEntity).child(activitylistID).updateChildValues(updatedConversationID)
            if let conversation = conversations.first(where: {$0.chatID == chatID}) {
                if conversation.activitylists != nil {
                    var activitylists = conversation.activitylists!
                    activitylists.append(activitylistID)
                    let updatedActivitylists = [activitylistsEntity: activitylists as AnyObject]
                    Database.database().reference().child("groupChats").child(conversation.chatID!).child(messageMetaDataFirebaseFolder).updateChildValues(updatedActivitylists)
                } else {
                    let updatedActivitylists = [activitylistsEntity: [activitylistID] as AnyObject]
                    Database.database().reference().child("groupChats").child(conversation.chatID!).child(messageMetaDataFirebaseFolder).updateChildValues(updatedActivitylists)
                }
                if let activityID = activityID {
                    Database.database().reference().child("activities").child(activityID).child(messageMetaDataFirebaseFolder).updateChildValues(updatedConversationID)
                    if conversation.activities != nil {
                        var activities = conversation.activities!
                        activities.append(activityID)
                        let updatedActivities = ["activities": activities as AnyObject]
                        Database.database().reference().child("groupChats").child(conversation.chatID!).child(messageMetaDataFirebaseFolder).updateChildValues(updatedActivities)
                    } else {
                        let updatedActivities = ["activities": [activityID] as AnyObject]
                        Database.database().reference().child("groupChats").child(conversation.chatID!).child(messageMetaDataFirebaseFolder).updateChildValues(updatedActivities)
                    }
                    Database.database().reference().child("activities").child(activityID).updateChildValues(updatedConversationID)
                }
            }
            self.connectedToChatAlert()
            self.dismiss(animated: true, completion: nil)
        } else if let packinglistID = packinglistID {
            let updatedConversationID = ["conversationID": chatID as AnyObject]
            Database.database().reference().child(packinglistsEntity).child(packinglistID).updateChildValues(updatedConversationID)

            if let conversation = conversations.first(where: {$0.chatID == chatID}) {
                if conversation.packinglists != nil {
                    var packinglists = conversation.packinglists!
                    packinglists.append(packinglistID)
                    let updatedPackinglists = [packinglistsEntity: packinglists as AnyObject]
                    Database.database().reference().child("groupChats").child(conversation.chatID!).child(messageMetaDataFirebaseFolder).updateChildValues(updatedPackinglists)
                } else {
                    let updatedPackinglists = [packinglistsEntity: [packinglistID] as AnyObject]
                    Database.database().reference().child("groupChats").child(conversation.chatID!).child(messageMetaDataFirebaseFolder).updateChildValues(updatedPackinglists)
                }
                if let activityID = activityID {
                Database.database().reference().child("activities").child(activityID).child(messageMetaDataFirebaseFolder).updateChildValues(updatedConversationID)
                    if conversation.activities != nil {
                        var activities = conversation.activities!
                        activities.append(activityID)
                        let updatedActivities = ["activities": activities as AnyObject]
                        Database.database().reference().child("groupChats").child(conversation.chatID!).child(messageMetaDataFirebaseFolder).updateChildValues(updatedActivities)
                    } else {
                        let updatedActivities = ["activities": [activityID] as AnyObject]
                        Database.database().reference().child("groupChats").child(conversation.chatID!).child(messageMetaDataFirebaseFolder).updateChildValues(updatedActivities)
                    }
                    Database.database().reference().child("activities").child(activityID).updateChildValues(updatedConversationID)
                }
            }
            self.connectedToChatAlert()
            self.dismiss(animated: true, completion: nil)
        }
    }
}
