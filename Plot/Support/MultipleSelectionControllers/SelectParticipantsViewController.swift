//
//  SelectParticipantsViewController.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 3/6/18.
//  Copyright © 2018 Roman Mizin. All rights reserved.
//

import UIKit
import Firebase

class SelectParticipantsViewController: UIViewController {
    
    let falconUsersCellID = "falconUsersCellID"
    
    var filteredUsers = [User]()
    var userInvitationStatus: [String: Status] = [:]
    var priorSelectedUsers = [User]()
    
    var chatLogController: ChatLogController? = nil
    var messagesFetcher: MessagesFetcher? = nil
    var ownerID: String?
    
    var users = [User]()
    var sortedFirstLetters = [String]()
    var sections = [[User]]()
    var selectedFalconUsers = [User]()
    var conversations = [Conversation]()
    var searchBar: UISearchBar?
    let tableView = UITableView(frame: .zero, style: .insetGrouped)
    let viewPlaceholder = ViewPlaceholder()
    
    var activityObject: ActivityObject?
        
    override func viewDidLoad() {
        super.viewDidLoad()
        setupSearchController()
        setupMainView()
        setupTableView()
        checkIfThereAnyUsers()
        configureSections()

    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if navigationController?.visibleViewController is GroupProfileTableViewController { return }
        deselectAll()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    
    deinit {
        print("select participants deinit")
    }
    
    fileprivate func deselectAll() {
        guard users.count > 0 else { return }
        _ = users.map { $0.isSelected = false }
        filteredUsers = users
        sections = [users]
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    
    fileprivate var isInitialLoad = true
    
    func configureSections() {
        if isInitialLoad {
            _ = filteredUsers.map { $0.isSelected = false }
            selectPriorUsers(priorSelectedUsers: priorSelectedUsers)
            isInitialLoad = false
        }
                
        if userInvitationStatus.count > 0 {
            sortedFirstLetters = [Status.accepted.description, Status.pending.description, Status.declined.description, Status.uninvited.description]
            sections = sortedFirstLetters.map { status in
                return self.filteredUsers
                    .filter {
                        if $0.titleFirstLetter == "" {
                            return false
                        }
                        else if let id = $0.id, let userStatus = userInvitationStatus[id]?.description {
                            return userStatus == status
                        }
                        else if status == Status.uninvited.description {
                            return true
                        } else {
                            return false
                        }
                    }
                    .sorted { $0.name ?? "" < $1.name ?? "" }
            }
            for section in sections {
                if section.isEmpty {
                    if let index = sections.firstIndex(of: section) {
                        sortedFirstLetters.remove(at: index)
                        sections.remove(at: index)
                    }
                }
            }
        }
        else {
            sortedFirstLetters = [Status.participating.description, Status.uninvited.description]
            sections = sortedFirstLetters.map { status in
                return self.filteredUsers
                    .filter {
                        if $0.titleFirstLetter == "" {
                            return false
                        }
                        else if selectedFalconUsers.contains($0) && status == Status.participating.description {
                            return true
                        }
                        else if !selectedFalconUsers.contains($0) && status == Status.uninvited.description {
                            return true
                        } else {
                            return false
                        }
                    }
                    .sorted { $0.name ?? "" < $1.name ?? "" }
            }
            for section in sections {
                if section.isEmpty {
                    if let index = sections.firstIndex(of: section) {
                        sortedFirstLetters.remove(at: index)
                        sections.remove(at: index)
                    }
                }
            }
//            let firstLetters = filteredUsers.map { $0.titleFirstLetter }
//            let uniqueFirstLetters = Array(Set(firstLetters))
//            sortedFirstLetters = uniqueFirstLetters.sorted()
//            sections = sortedFirstLetters.map { firstLetter in
//                 return self.filteredUsers
//                    .filter { $0.titleFirstLetter == firstLetter && $0.titleFirstLetter != "" }

        }
        
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    
    func checkIfThereAnyUsers() {
        if filteredUsers.count > 0 {
            viewPlaceholder.remove(from: tableView, priority: .medium)
        } else {
            viewPlaceholder.add(for: tableView, title: .emptyUsers, subtitle: .empty, priority: .medium, position: .top)
        }
        tableView.reloadData()
    }
    
    fileprivate func setupMainView() {
        extendedLayoutIncludesOpaqueBars = true
        definesPresentationContext = true
        view.backgroundColor = .systemGroupedBackground
    }
    
    func setupNavigationItemTitle(title: String) {
        navigationItem.title = title
    }
    
    func setupRightBarButton(with title: String) {
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(rightBarButtonTapped))
        navigationItem.rightBarButtonItem?.isEnabled = false
    }
    
    @objc func rightBarButtonTapped() {
        
    }
    
    func createGroup() {
        let membersIDs = fetchMembersIDs()
        for conversation in conversations {
            if conversation.isGroupChat! {
                let conversationSet = Set(conversation.chatParticipantsIDs!)
                let membersSet = Set(membersIDs)
                if membersSet == conversationSet {
                    if let activityObject = activityObject {
                        let messageSender = MessageSender(conversation, text: activityObject.activityName, media: nil, activity: activityObject)
                        messageSender.sendMessage()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: {
                            self.removeMessageAlert()
                            self.dismiss(animated: true, completion: nil)
                        })
                        return
                    }
                    self.chatLogController = ChatLogController(collectionViewLayout: AutoSizingCollectionViewFlowLayout())
                    self.messagesFetcher = MessagesFetcher()
                    self.messagesFetcher?.delegate = self
                    self.messagesFetcher?.loadMessagesData(for: conversation)
                    return
                }
            }
        }
        let destination = GroupProfileTableViewController()
        destination.activityObject = activityObject
        destination.selectedFlaconUsers = selectedFalconUsers
        navigationController?.pushViewController(destination, animated: true)
    }
    
    
    var chatIDForUsersUpdate = String()
    var informationMessageSender = InformationMessageSender()
    
    func addNewMembers() {
        
        //    ARSLineProgress.ars_showOnView(view)
        if let navController = self.navigationController {
             self.showSpinner(onView: navController.view)
         } else {
             self.showSpinner(onView: self.view)
         }
        navigationController?.view.isUserInteractionEnabled = false
        
        let reference = Database.database().reference().child("groupChats").child(chatIDForUsersUpdate).child(messageMetaDataFirebaseFolder).child("chatParticipantsIDs")
        reference.observeSingleEvent(of: .value) { (snapshot) in
            
            guard let dictionary = snapshot.value as? [String: AnyObject] else { return }
            guard var membersIDs = Array(dictionary.values) as? [String] else { return }
            
            var values = [String: AnyObject]()
            var selectedUserNames = [String]()
            
            for selectedUser in self.selectedFalconUsers {
                guard let selectedID = selectedUser.id, let selectedUserName = selectedUser.name else { continue }
                values.updateValue(selectedID as AnyObject, forKey: selectedID)
                selectedUserNames.append(selectedUserName)
                membersIDs.append(selectedID)
            }
            
            reference.updateChildValues(values, withCompletionBlock: { (_, _) in
                let userNamesString = selectedUserNames.joined(separator: ", ")
                let usersTitleString = selectedUserNames.count > 1 ? "were" : "was"
                let text = "\(userNamesString) \(usersTitleString) added to the group"
                self.informationMessageSender.sendInformatoinMessage(chatID: self.chatIDForUsersUpdate, membersIDs: membersIDs, text: text)
                
                self.removeSpinner()
                self.navigationController?.view.isUserInteractionEnabled = true
                self.navigationController?.popViewController(animated: true)
            })
        }
    }
    
    fileprivate func setupTableView() {
        
        if #available(iOS 11.0, *) {
            navigationItem.largeTitleDisplayMode = .never
        }
        
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
        
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
        tableView.sectionIndexBackgroundColor = .systemGroupedBackground
        tableView.backgroundColor = .systemGroupedBackground
        tableView.allowsMultipleSelection = true
        tableView.allowsSelection = true
        tableView.allowsSelectionDuringEditing = true
        tableView.allowsMultipleSelectionDuringEditing = true
        tableView.setEditing(true, animated: false)
        tableView.register(ParticipantTableViewCell.self, forCellReuseIdentifier: falconUsersCellID)
        tableView.separatorStyle = .none
        tableView.estimatedRowHeight = UITableView.automaticDimension
    }
    
    fileprivate func setupSearchController() {
        searchBar = UISearchBar()
        searchBar?.delegate = self
        searchBar?.searchBarStyle = .minimal
        searchBar?.placeholder = "Search"
        searchBar?.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: 50)
        tableView.tableHeaderView = searchBar
    }
    
    func didSelectUser(at indexPath: IndexPath) {
        let user = sections[indexPath.section][indexPath.row]
        
        if let filteredUsersIndex = filteredUsers.firstIndex(of: user) {
            filteredUsers[filteredUsersIndex].isSelected = true
        }
        
        if let usersIndex = users.firstIndex(of: user) {
            users[usersIndex].isSelected = true
        }
        
        sections[indexPath.section][indexPath.row].isSelected = true
        
        selectedFalconUsers.append(sections[indexPath.section][indexPath.row])
                
        let set1 = Set(selectedFalconUsers)
        let set2 = Set(priorSelectedUsers)

        if (set1.count == set2.count && set1 == set2) {
            navigationItem.rightBarButtonItem?.isEnabled = false
        } else {
            navigationItem.rightBarButtonItem?.isEnabled = true
        }
    }
    
    func didDeselectUser(at indexPath: IndexPath) {
        let user = sections[indexPath.section][indexPath.row]
        
        if let index = filteredUsers.firstIndex(of: user) {
            filteredUsers[index].isSelected = false
        }
        
        if let index = users.firstIndex(of: user) {
            users[index].isSelected = false
        }
        
        if let index = selectedFalconUsers.firstIndex(of: user) {
            selectedFalconUsers[index].isSelected = false
            selectedFalconUsers.remove(at: index)
        }
        
        sections[indexPath.section][indexPath.row].isSelected = false
                
        let set1 = Set(selectedFalconUsers)
        let set2 = Set(priorSelectedUsers)

        if (set1.count == set2.count && set1 == set2) {
            navigationItem.rightBarButtonItem?.isEnabled = false
        } else {
            navigationItem.rightBarButtonItem?.isEnabled = true
        }
    }
    
    func selectPriorUsers(priorSelectedUsers: [User]) {
        for user in priorSelectedUsers {
            if let filteredUsersIndex = filteredUsers.firstIndex(of: user) {
                filteredUsers[filteredUsersIndex].isSelected = true
            }
            
            if let usersIndex = users.firstIndex(of: user) {
                users[usersIndex].isSelected = true
            }
            
            if let index = priorSelectedUsers.firstIndex(of: user) {
                priorSelectedUsers[index].isSelected = true
                selectedFalconUsers.append(user)
            }
                        
        }        
    }
    
    func fetchMembersIDs() -> ([String]) {
        var membersIDs = [String]()
        
        guard let currentUserID = Auth.auth().currentUser?.uid else { return (membersIDs) }
        
        membersIDs.append(currentUserID)
        
        for selectedUser in selectedFalconUsers {
            guard let id = selectedUser.id else { continue }
            membersIDs.append(id)
        }
        
        return (membersIDs)
    }
}

extension SelectParticipantsViewController: MessagesDelegate {
    
    func messages(shouldChangeMessageStatusToReadAt reference: DatabaseReference) {
        chatLogController?.updateMessageStatus(messageRef: reference)
    }
    
    func messages(shouldBeUpdatedTo messages: [Message], conversation: Conversation) {
        
        chatLogController?.hidesBottomBarWhenPushed = true
        chatLogController?.messagesFetcher = messagesFetcher
        chatLogController?.messages = messages
        chatLogController?.conversation = conversation
        
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
        
        navigationController?.pushViewController(destination, animated: true)
        chatLogController = nil
        messagesFetcher?.delegate = nil
        messagesFetcher = nil
    }
}

