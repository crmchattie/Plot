//
//  ContactsController.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 8/2/17.
//  Copyright © 2017 Roman Mizin. All rights reserved.
//

import UIKit
import Contacts
import Firebase
import PhoneNumberKit
import SDWebImage

var localPhones = [String]()

private let falconUsersCellID = "falconUsersCellID"
private let currentUserCellID = "currentUserCellID"
private let contactsCellID = "contactsCellID"

class ContactsController: UITableViewController {
    
    var contacts = [CNContact]()
    var filteredContacts = [CNContact]()
    var users = [User]()
    var filteredUsers = [User]()
    var conversations = [Conversation]()
    let newGroupCellID = "newGroupCellID"
    let newGroupAction = "New Group"
    var actions = ["New Group"]
    
    var searchBar: UISearchBar?
    var searchContactsController: UISearchController?
    
    let viewPlaceholder = ViewPlaceholder()
    
    var activityObject: ActivityObject?
    
    override func viewDidLoad() {
        super.viewDidLoad()
                
        configureViewController()
        setupSearchController()
        
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .default
    }

    
    fileprivate func configureViewController() {
        navigationItem.title = "New Chat"
        
        navigationItem.largeTitleDisplayMode = .never
        extendedLayoutIncludesOpaqueBars = true
        definesPresentationContext = true
        edgesForExtendedLayout = UIRectEdge.top
        view.backgroundColor = .systemGroupedBackground
        tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.indicatorStyle = .default
        tableView.sectionIndexBackgroundColor = .systemGroupedBackground
        tableView.backgroundColor = .systemGroupedBackground
        tableView.register(ContactsTableViewCell.self, forCellReuseIdentifier: contactsCellID)
        tableView.register(FalconUsersTableViewCell.self, forCellReuseIdentifier: falconUsersCellID)
        tableView.register(CurrentUserTableViewCell.self, forCellReuseIdentifier: currentUserCellID)
        tableView.separatorStyle = .none
    }
    
    fileprivate func setupSearchController() {
        if #available(iOS 11.0, *) {
            searchContactsController = UISearchController(searchResultsController: nil)
            searchContactsController?.searchResultsUpdater = self
            searchContactsController?.obscuresBackgroundDuringPresentation = false
            searchContactsController?.searchBar.delegate = self
            navigationItem.searchController = searchContactsController
        } else {
            searchBar = UISearchBar()
            searchBar?.delegate = self
            searchBar?.placeholder = "Search"
            searchBar?.searchBarStyle = .minimal
            searchBar?.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: 50)
            tableView.tableHeaderView = searchBar
        }
    }
    
    fileprivate func reloadTableView(updatedUsers: [User]) {
        
        self.users = updatedUsers
        //      self.users = falconUsersFetcher.rearrangeUsers(users: self.users)
        
        let searchBar = correctSearchBarForCurrentIOSVersion()
        let isSearchInProgress = searchBar.text != ""
        let isSearchControllerEmpty = self.filteredUsers.count == 0
        
        if isSearchInProgress && !isSearchControllerEmpty {
            return
        } else {
            self.filteredUsers = self.users
            guard self.filteredUsers.count != 0 else { return }
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }
    
    fileprivate func correctSearchBarForCurrentIOSVersion() -> UISearchBar {
        var searchBar: UISearchBar!
        if #available(iOS 11.0, *) {
            searchBar = self.searchContactsController?.searchBar
        } else {
            searchBar = self.searchBar
        }
        return searchBar
    }
    
    // MARK: - Table view data source
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return UIView()
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if section == 0 {
            return actions.count
        } else if section == 1 {
            return filteredUsers.count
        } else {
            return filteredContacts.count
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        
        if section == 0 {
            return "New Group"
        } else if section == 1 {
            if filteredUsers.count == 0 {
                return ""
            } else {
                return "Contacts"
            }
        } else {
            return "Invite to Plot"
        }
    }
    
    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        view.tintColor = .systemGroupedBackground
        
        if let headerTitle = view as? UITableViewHeaderFooterView {
            headerTitle.textLabel?.textColor = .label
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return selectCell(for: indexPath)
    }
    
    func selectCell(for indexPath: IndexPath) -> UITableViewCell {
        let headerSection = 0
        if indexPath.section == headerSection {
            let cell = tableView.dequeueReusableCell(withIdentifier: newGroupCellID) ?? UITableViewCell(style: .default, reuseIdentifier: newGroupCellID)
            cell.heightAnchor.constraint(greaterThanOrEqualToConstant: 65).isActive = true
            cell.backgroundColor = .secondarySystemGroupedBackground
            cell.imageView?.image = UIImage(named: "groupChat")
            cell.imageView?.contentMode = .scaleAspectFit
            cell.textLabel?.font = .preferredFont(forTextStyle: .body)
            cell.textLabel?.text = actions[indexPath.row]
            cell.textLabel?.textColor = FalconPalette.defaultBlue
            return cell
        } else if indexPath.section == 1 {
            let cell = tableView.dequeueReusableCell(withIdentifier: falconUsersCellID,
                                                     for: indexPath) as? FalconUsersTableViewCell ?? FalconUsersTableViewCell()
            cell.backgroundColor = .secondarySystemGroupedBackground
            let user = filteredUsers[indexPath.row]
            cell.configureCell(for: user)
            return cell
            
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: contactsCellID,
                                                     for: indexPath) as? ContactsTableViewCell ?? ContactsTableViewCell()
            cell.backgroundColor = .secondarySystemGroupedBackground
            cell.icon.image = UIImage(named: "UserpicIcon")
            cell.title.text = filteredContacts[indexPath.row].givenName + " " + filteredContacts[indexPath.row].familyName
            return cell
        }
    }
    
    var chatLogController: ChatLogController? = nil
    var messagesFetcher: MessagesFetcher? = nil
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0 {
            let destination = SelectGroupMembersController()
            destination.activityObject = activityObject
            destination.users = users
            destination.filteredUsers = filteredUsers
            destination.conversations = conversations
            // destination.setUpCollation()
            self.navigationController?.pushViewController(destination, animated: true)
        } else if indexPath.section == 1 {
            guard let currentUserID = Auth.auth().currentUser?.uid else { return }
            let membersIDs = [currentUserID, filteredUsers[indexPath.row].id]
            for conversation in conversations {
                if conversation.isGroupChat! {
                    let conversationSet = Set(conversation.chatParticipantsIDs!)
                    let membersSet = Set(membersIDs)
                    if membersSet == conversationSet {
                        if let activityObject = activityObject {
                            let messageSender = MessageSender(conversation, text: activityObject.activityName, media: nil, activity: activityObject)
                            messageSender.sendMessage()
                            self.messageSentAlert()
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
            let chatID = Database.database().reference().child("user-messages").child(currentUserID).childByAutoId().key ?? ""
            let conversationDictionary: [String: AnyObject] = ["chatID": chatID as AnyObject, "chatName": filteredUsers[indexPath.row].name as AnyObject,
                                                               "isGroupChat": true  as AnyObject,
                                                               "admin": currentUserID  as AnyObject,
                                                               "adminNeeded": false  as AnyObject,
                                                               "chatOriginalPhotoURL": filteredUsers[indexPath.row].photoURL as AnyObject,
                                                               "chatThumbnailPhotoURL": filteredUsers[indexPath.row].thumbnailPhotoURL as AnyObject,
                                                               "chatParticipantsIDs": [filteredUsers[indexPath.row].id, currentUserID] as AnyObject]
            
            let conversation = Conversation(dictionary: conversationDictionary)
            if let activityObject = activityObject {
                let messageSender = MessageSender(conversation, text: activityObject.activityName, media: nil, activity: activityObject)
                messageSender.sendMessage()
                self.messageSentAlert()
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: {
                    self.removeMessageAlert()
                    self.dismiss(animated: true, completion: nil)
                })
                return
            }
            chatLogController = ChatLogController(collectionViewLayout: AutoSizingCollectionViewFlowLayout())
            chatLogController?.chatExists = false
            messagesFetcher = MessagesFetcher()
            messagesFetcher?.delegate = self
            messagesFetcher?.loadMessagesData(for: conversation)
        } else {
            let destination = ContactsDetailController()
            destination.contactName = filteredContacts[indexPath.row].givenName + " " + filteredContacts[indexPath.row].familyName
            destination.contactPhoneNumbers.removeAll()
            destination .hidesBottomBarWhenPushed = true
            for phoneNumber in filteredContacts[indexPath.row].phoneNumbers {
                destination.contactPhoneNumbers.append(phoneNumber.value.stringValue)
            }
            self.navigationController?.pushViewController(destination, animated: true)
        }
    }
    func checkContactsAuthorizationStatus() -> Bool {
        let contactsAuthorityCheck = CNContactStore.authorizationStatus(for: CNEntityType.contacts)
        
        switch contactsAuthorityCheck {
        case .denied, .notDetermined, .restricted:
            viewPlaceholder.add(for: view, title: .denied, subtitle: .denied, priority: .high, position: .center)
            return false
        case .authorized:
            viewPlaceholder.remove(from: view, priority: .high)
            return true
        @unknown default:
            fatalError()
        }
    }
}

extension ContactsController: MessagesDelegate {
    
    func messages(shouldChangeMessageStatusToReadAt reference: DatabaseReference) {
        chatLogController?.updateMessageStatus(messageRef: reference)
    }
    
    func messages(shouldBeUpdatedTo messages: [Message], conversation: Conversation) {
        
        chatLogController?.hidesBottomBarWhenPushed = true
        chatLogController?.messagesFetcher = messagesFetcher
        chatLogController?.messages = messages
        chatLogController?.conversation = conversation
        chatLogController?.observeTypingIndicator()
        chatLogController?.configureTitleViewWithOnlineStatus()
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

