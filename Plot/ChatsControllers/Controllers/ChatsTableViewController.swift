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

//update to change first controller shown
//protocol ManageAppearanceChat: class {
//  func manageAppearanceChat(_ chatsController: ChatsTableViewController, didFinishLoadingWith state: Bool )
//}

protocol ChatsViewControllerDataStore: class {
    func getParticipants(forConversation conversation: Conversation, completion: @escaping ([User])->())
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
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for:.default)
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.navigationBar.layoutIfNeeded()
        
        print("chat view did load")
        configureTableView()
        addObservers()
        handleReloadTable()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    fileprivate func addObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(changeTheme), name: .themeUpdated, object: nil)
    }
    
    @objc fileprivate func changeTheme() {
        view.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
        
        tableView.indicatorStyle = ThemeManager.currentTheme().scrollBarStyle
        tableView.sectionIndexBackgroundColor = ThemeManager.currentTheme().generalBackgroundColor
        tableView.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
        tableView.reloadData()
    }
    
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return ThemeManager.currentTheme().statusBarStyle
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        guard tableView.isEditing else { return }
        tableView.endEditing(true)
        tableView.reloadData()
    }
    
    fileprivate func configureTableView() {
        tableView.register(UserCell.self, forCellReuseIdentifier: userCellID)
        tableView.allowsMultipleSelectionDuringEditing = false
        view.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
        tableView.indicatorStyle = ThemeManager.currentTheme().scrollBarStyle
        tableView.backgroundColor = view.backgroundColor
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 105
        
        let cancelBarButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancel))
        navigationItem.leftBarButtonItem = cancelBarButton
        
        let searchBarButton =  UIBarButtonItem(barButtonSystemItem: .search, target: self, action: #selector(search))
        let newChatBarButton =  UIBarButtonItem(barButtonSystemItem: .compose, target: self, action: #selector(newChat))
        navigationItem.rightBarButtonItems = [newChatBarButton, searchBarButton]
        extendedLayoutIncludesOpaqueBars = true
        edgesForExtendedLayout = UIRectEdge.top
        tableView.separatorStyle = .none
        definesPresentationContext = true        
    }
    
    @IBAction func cancel(_ sender: AnyObject) {
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
        return true
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            if filteredPinnedConversations.count == 0 {
                return ""
            }
            return " " //Pinned
        } else {
            return " "
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0 {
            return 8
        } else {
            if self.filteredPinnedConversations.count == 0 {
                return 0
            }
            return 8
        }
    }
    
    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        view.tintColor = ThemeManager.currentTheme().inputTextViewColor
        
        //    if section == 0 {
        //      view.tintColor = ThemeManager.currentTheme().generalBackgroundColor
        //    } else {
        //      view.tintColor = ThemeManager.currentTheme().inputTextViewColor
        //    }
        
        if let headerTitle = view as? UITableViewHeaderFooterView {
            headerTitle.textLabel?.textColor = FalconPalette.defaultBlue
            //      headerTitle.textLabel?.font = UIFont.systemFont(ofSize: 10)
            headerTitle.textLabel?.font = UIFont.preferredFont(forTextStyle: .subheadline)
            headerTitle.textLabel?.adjustsFontForContentSizeCategory = true
            headerTitle.textLabel?.minimumScaleFactor = 0.1
            headerTitle.textLabel?.adjustsFontSizeToFitWidth = true
        }
    }
    
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        
        let delete = setupDeleteAction(at: indexPath)
        //    let pin = setupPinAction(at: indexPath)
        let mute = setupMuteAction(at: indexPath)
        
        return [delete, mute]
    }
    
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
        cell.selectionStyle = .none
        cell.chatsViewControllerDataStore = self
        
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
        } else {
            let unpinnedConversation = filteredConversations[indexPath.row]
            conversation = unpinnedConversation
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

extension ChatsTableViewController: ChatsViewControllerDataStore {
    func getParticipants(forConversation conversation: Conversation, completion: @escaping ([User])->()) {
        guard let chatID = conversation.chatID, let participantsIDs = conversation.chatParticipantsIDs, let currentUserID = Auth.auth().currentUser?.uid else {
            return
        }
        
        let group = DispatchGroup()
        let olderParticipants = self.chatParticipants[chatID]
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
            self.chatParticipants[chatID] = participants
            completion(participants)
        }
    }
}

extension ChatsTableViewController: ChatCellDelegate {
    @objc func getInfo(forConversation conversation: Conversation) {
        
        if let isGroupChat = conversation.isGroupChat, isGroupChat {
            
            let destination = GroupAdminControlsTableViewController()
            destination.hidesBottomBarWhenPushed = true
            destination.chatID = conversation.chatID ?? ""
            destination.conversation = conversation
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
                let activityDataReference = Database.database().reference().child("activities").child(activityID).child(messageMetaDataFirebaseFolder)
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
