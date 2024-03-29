//
//  ChatsTableViewController.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 3/13/18.
//  Copyright © 2018 Roman Mizin. All rights reserved.
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

class ChatsTableViewController: UITableViewController {
    
    fileprivate let userCellID = "userCellID"
    fileprivate var isAppLoaded = false
        
    var searchBar: UISearchBar?
    var searchController: UISearchController?
    
    var conversations = [Conversation]()
    var filteredConversations = [Conversation]()
    var pinnedConversations = [Conversation]()
    var filteredPinnedConversations = [Conversation]()
    
    var contacts = [CNContact]()
    var filteredContacts = [CNContact]()
    var users = [User]()
    var filteredUsers = [User]()
        
    let viewPlaceholder = ViewPlaceholder()
    let navigationItemActivityIndicator = NavigationItemActivityIndicator()
    
    // [chatID: Participants]
    var chatParticipants: [String: [User]] = [:]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Chats"
        
        
        print("chat view did load")
        configureTableView()
        handleReloadTable()
    }
    
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .default
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        guard tableView.isEditing else { return }
        tableView.endEditing(true)
        tableView.reloadData()
    }
    
    fileprivate func configureTableView() {
        tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.register(UserCell.self, forCellReuseIdentifier: userCellID)
        tableView.allowsMultipleSelectionDuringEditing = false
        view.backgroundColor = .systemGroupedBackground
        tableView.indicatorStyle = .default
        tableView.backgroundColor = view.backgroundColor
        tableView.rowHeight = UITableView.automaticDimension
        
        let doneBarButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(done))
        navigationItem.leftBarButtonItem = doneBarButton
        
        let searchBarButton =  UIBarButtonItem(barButtonSystemItem: .search, target: self, action: #selector(search))
        let newChatBarButton =  UIBarButtonItem(barButtonSystemItem: .compose, target: self, action: #selector(newChat))
        navigationItem.rightBarButtonItems = [newChatBarButton, searchBarButton]
        extendedLayoutIncludesOpaqueBars = true
        edgesForExtendedLayout = UIRectEdge.top
        tableView.separatorStyle = .none
        definesPresentationContext = true        
    }
    
    @IBAction func done(_ sender: AnyObject) {
        self.dismiss(animated: true, completion: nil)
    }
    
    
    @objc fileprivate func newChat() {
        let destination = ContactsController()
        destination.hidesBottomBarWhenPushed = true
        let isContactsAccessGranted = destination.checkContactsAuthorizationStatus()
        if isContactsAccessGranted {
            destination.users = users
            destination.filteredUsers = filteredUsers
            destination.contacts = contacts
            destination.filteredContacts = filteredContacts
            destination.conversations = conversations
        } else {
            destination.users = users
            destination.filteredUsers = filteredUsers
            destination.conversations = conversations
        }
        navigationController?.pushViewController(destination, animated: true)
    }
    
    @objc fileprivate func search() {
        setupSearchController()
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
    
    func checkIfThereAnyActiveChats(isEmpty: Bool) {
        guard isEmpty else {
            viewPlaceholder.remove(from: view, priority: .medium)
            return
        }
        viewPlaceholder.add(for: view, title: .emptyChat, subtitle: .emptyChat, priority: .medium, position: .top)
    }
    
    fileprivate func updateCell(at indexPath: IndexPath) {
        tableView.beginUpdates()
        tableView.reloadRows(at: [indexPath], with: .none)
        tableView.endUpdates()
    }
    
    func handleReloadTable() {
        conversations.sort { (conversation1, conversation2) -> Bool in
            return conversation1.lastMessage?.timestamp?.int64Value > conversation2.lastMessage?.timestamp?.int64Value
        }
        
        pinnedConversations.sort { (conversation1, conversation2) -> Bool in
            return conversation1.lastMessage?.timestamp?.int64Value > conversation2.lastMessage?.timestamp?.int64Value
        }
        
        filteredPinnedConversations = pinnedConversations
        filteredConversations = conversations
        let allConversations = conversations + pinnedConversations
                
        if !isAppLoaded {
            tableView.reloadData()
        } else {
            tableView.reloadData()
        }
        
        if filteredConversations.count == 0 && filteredPinnedConversations.count == 0 {
            checkIfThereAnyActiveChats(isEmpty: true)
        } else {
            checkIfThereAnyActiveChats(isEmpty: false)
        }
        
        guard !isAppLoaded else { return }
        //    delegate?.manageAppearanceChat(self, didFinishLoadingWith: true)
        isAppLoaded = true
        checkForDataMigration(forConversations: allConversations)
    }
    
    func handleReloadTableAfterSearch() {
        filteredConversations.sort { (conversation1, conversation2) -> Bool in
            return conversation1.lastMessage?.timestamp?.int64Value > conversation2.lastMessage?.timestamp?.int64Value
        }
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    
    // MARK: - Table view data source
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return false
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return UIView()
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0
    }
    
//    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        
//        let delete = setupDeleteAction(at: indexPath)
//    let pin = setupPinAction(at: indexPath)
//        let mute = setupMuteAction(at: indexPath)
        
//        return [delete, mute]
//    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if filteredPinnedConversations.count == 0 && filteredConversations.count == 0 {
            checkIfThereAnyActiveChats(isEmpty: true)
        } else {
            checkIfThereAnyActiveChats(isEmpty: false)
        }
        if section == 0 {
            return filteredPinnedConversations.count
        } else {
            return filteredConversations.count
        }
        
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: userCellID, for: indexPath) as? UserCell ?? UserCell()
        
        cell.delegate = self
                
        if indexPath.section == 0 {
            cell.configureCell(for: indexPath, conversations: filteredPinnedConversations)
        } else {
            cell.configureCell(for: indexPath, conversations: filteredConversations)
        }
        
        return cell
    }
    
    var chatLogController: ChatLogController? = nil
    var messagesFetcher: MessagesFetcher? = nil
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        var conversation: Conversation!
        if indexPath.section == 0 {
            let pinnedConversation = filteredPinnedConversations[indexPath.row]
            conversation = pinnedConversation
            filteredPinnedConversations[indexPath.row].badge = 0
            tableView.reloadRows(at: [indexPath], with: .none)
        } else {
            let unpinnedConversation = filteredConversations[indexPath.row]
            conversation = unpinnedConversation
            filteredConversations[indexPath.row].badge = 0
            tableView.reloadRows(at: [indexPath], with: .none)
        }
        chatLogController = ChatLogController(collectionViewLayout: AutoSizingCollectionViewFlowLayout())
        messagesFetcher = MessagesFetcher()
        messagesFetcher?.delegate = self
        messagesFetcher?.loadMessagesData(for: conversation)
    }
}

extension ChatsTableViewController: DeleteAndExitDelegate {
    
    func deleteAndExit(from conversationID: String) {
        
        let pinnedIDs = pinnedConversations.map({$0.chatID ?? ""})
        let section = pinnedIDs.contains(conversationID) ? 0 : 1
        guard let row = conversationIndex(for: conversationID, at: section) else { return }
        
        let indexPath = IndexPath(row: row, section: section)
        section == 0 ? deletePinnedConversation(at: indexPath) : deleteUnPinnedConversation(at: indexPath)
    }
    
    func conversationIndex(for conversationID: String, at section: Int) -> Int? {
        let conversationsArray = section == 0 ? filteredPinnedConversations : filteredConversations
        guard let index = conversationsArray.firstIndex(where: { (conversation) -> Bool in
            guard let chatID = conversation.chatID else { return false }
            return chatID == conversationID
        }) else { return nil }
        return index
    }
}

extension ChatsTableViewController: MessagesDelegate {
    
    func messages(shouldChangeMessageStatusToReadAt reference: DatabaseReference) {
        chatLogController?.updateMessageStatus(messageRef: reference)
    }
    
    func messages(shouldBeUpdatedTo messages: [Message], conversation: Conversation) {
        
        chatLogController?.hidesBottomBarWhenPushed = true
        chatLogController?.messagesFetcher = messagesFetcher
        chatLogController?.messages = messages
        chatLogController?.conversation = conversation
        chatLogController?.deleteAndExitDelegate = self
        
        if let membersIDs = conversation.chatParticipantsIDs, let uid = Auth.auth().currentUser?.uid, membersIDs.contains(uid) {
            chatLogController?.observeTypingIndicator()
            chatLogController?.configureTitleViewWithOnlineStatus()
        }
        
        chatLogController?.messagesFetcher.collectionDelegate = chatLogController
        guard let destination = chatLogController else { return }
        
        if #available(iOS 11.0, *) {
        } else {
            self.chatLogController?.startCollectionViewAtBottom()
        }
        
        destination.users = users
        destination.filteredUsers = filteredUsers
        destination.conversations = conversations
        navigationController?.pushViewController(destination, animated: true)
        chatLogController = nil
        messagesFetcher?.delegate = nil
        messagesFetcher = nil
    }
}

extension ChatsTableViewController: ChatCellDelegate {
    @objc func getInfo(forConversation conversation: Conversation) {
        
        if let isGroupChat = conversation.isGroupChat, isGroupChat {
            
            let destination = GroupAdminControlsTableViewController()
            destination.hidesBottomBarWhenPushed = true
            destination.chatID = conversation.chatID ?? ""
            destination.conversation = conversation
            destination.users = users
            destination.filteredUsers = filteredUsers
            if conversation.admin != Auth.auth().currentUser?.uid {
                destination.adminControls = destination.defaultAdminControlls
            }
            self.navigationController?.pushViewController(destination, animated: true)
        } else {
            // regular default chat info controller
            let destination = UserInfoTableViewController()
            destination.hidesBottomBarWhenPushed = true
            destination.conversationID = conversation.chatID ?? ""
            self.navigationController?.pushViewController(destination, animated: true)
        }
    }
    
    func openActivity(forConversation conversation: Conversation) {
        //        if conversation.activities == nil {
        //            let destination = ActivityTypeViewController()
        //            destination.hidesBottomBarWhenPushed = true
        //            destination.conversation = conversation
        //            destination.users = users
        //            destination.filteredUsers = filteredUsers
        //            var selectedFalconUsers = [User]()
        //            for ID in conversation.chatParticipantsIDs! {
        //                guard let currentUserID = Auth.auth().currentUser?.uid, currentUserID != ID else { continue }
        //                let newMemberReference = Database.database().reference().child("users").child(ID)
        //
        //                newMemberReference.observeSingleEvent(of: .value, with: { (snapshot) in
        //
        //                    guard var dictionary = snapshot.value as? [String: AnyObject] else { return }
        //                    dictionary.updateValue(snapshot.key as AnyObject, forKey: "id")
        //
        //                    let user = User(dictionary: dictionary)
        //
        //                    selectedFalconUsers.append(user)
        //                    destination.selectedFalconUsers = selectedFalconUsers
        //
        //                })
        //            }
        //            navigationController?.pushViewController(destination, animated: true)
        //
        //        }
        //        else {
        if let convoActivities = conversation.activities {
            var activities = [Activity]()
            let destination = SelectActivityTableViewController()
            destination.hidesBottomBarWhenPushed = true
            destination.conversation = conversation
            destination.users = users
            destination.filteredUsers = filteredUsers
            var selectedFalconUsers = [User]()
            for ID in conversation.chatParticipantsIDs! {
                guard let currentUserID = Auth.auth().currentUser?.uid, currentUserID != ID else { continue }
                let newMemberReference = Database.database().reference().child("users").child(ID)
                
                newMemberReference.observeSingleEvent(of: .value, with: { (snapshot) in
                    
                    guard var dictionary = snapshot.value as? [String: AnyObject] else { return }
                    dictionary.updateValue(snapshot.key as AnyObject, forKey: "id")
                    
                    let user = User(dictionary: dictionary)
                    
                    selectedFalconUsers.append(user)
                    destination.selectedFalconUsers = selectedFalconUsers
                })
            }
            for activityID in convoActivities {
                let activityDataReference = Database.database().reference().child(activitiesEntity).child(activityID).child(messageMetaDataFirebaseFolder)
                activityDataReference.observeSingleEvent(of: .value, with: { (snapshot) in
                    guard var dictionary = snapshot.value as? [String: AnyObject] else { return }
                    
                    dictionary.updateValue(activityID as AnyObject, forKey: "id")
                    
                    if let membersIDs = dictionary["participantsIDs"] as? [String:AnyObject] {
                        dictionary.updateValue(Array(membersIDs.values) as AnyObject, forKey: "participantsIDs")
                    }
                    
                    let activity = Activity(dictionary: dictionary)
                    
                    activities.append(activity)
                    destination.activities = activities
                    
                })
            }
            navigationController?.pushViewController(destination, animated: true)
        }
        
        //        }
        
    }
}
