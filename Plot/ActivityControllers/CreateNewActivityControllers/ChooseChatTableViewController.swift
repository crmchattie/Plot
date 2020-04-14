//
//  ChooseChatTableViewController.swift
//  Plot
//
//  Created by Cory McHattie on 11/24/19.
//  Copyright © 2019 Immature Creations. All rights reserved.
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

protocol ChooseChatDelegate: class {
    func chosenChat(chatID: String, activityID: String?)
}


class ChooseChatTableViewController: UITableViewController {
  
    fileprivate let newGroupCellID = "newGroupCellID"
    fileprivate let userCellID = "userCellID"
    fileprivate var isAppLoaded = false
    
    var searchBar: UISearchBar?
    var searchChatsController: UISearchController?

    var conversations = [Conversation]()
    var filteredConversations = [Conversation]()
    var pinnedConversations = [Conversation]()
    var filteredPinnedConversations = [Conversation]()
    
    var activity: Activity?
    var users = [User]()
    var filteredUsers = [User]()

    let viewPlaceholder = ViewPlaceholder()
    let navigationItemActivityIndicator = NavigationItemActivityIndicator()
    
    weak var delegate : ChooseChatDelegate?
    
    let activityCreatingGroup = DispatchGroup()
    let informationMessageSender = InformationMessageSender()
        
    // [chatID: Participants]
    var chatParticipants: [String: [User]] = [:]
    
    var activityObject: ActivityObject?
    
  override func viewDidLoad() {
    super.viewDidLoad()
   
    configureTableView()
    setupSearchController()
    
    tableView.rowHeight = UITableView.automaticDimension
    tableView.estimatedRowHeight = 105
  }
    
  
  override var preferredStatusBarStyle: UIStatusBarStyle {
    return ThemeManager.currentTheme().statusBarStyle
  }

  fileprivate func configureTableView() {
    tableView.register(UserCell.self, forCellReuseIdentifier: userCellID)
    tableView.allowsMultipleSelectionDuringEditing = false
    view.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
    tableView.indicatorStyle = ThemeManager.currentTheme().scrollBarStyle
    tableView.backgroundColor = view.backgroundColor
    navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(closeChat))

    let rightBarButton = UIButton(type: .system)
    rightBarButton.setTitle("New Chat", for: .normal)
    rightBarButton.titleLabel?.font = UIFont.preferredFont(forTextStyle: .body)
    rightBarButton.titleLabel?.adjustsFontForContentSizeCategory = true
    rightBarButton.addTarget(self, action: #selector(newChat), for: .touchUpInside)
    
    navigationItem.rightBarButtonItem = UIBarButtonItem(customView: rightBarButton)
    extendedLayoutIncludesOpaqueBars = true
    edgesForExtendedLayout = UIRectEdge.top
    tableView.separatorStyle = .none
    definesPresentationContext = true
    navigationItem.title = "Choose Chat"
  }
  
    @objc fileprivate func closeChat() {
        dismiss(animated: true, completion: nil)
    }
    
    @objc fileprivate func newChat() {
        if let currentUserID = Auth.auth().currentUser?.uid {
            if let activity = activity {
                let chatID = Database.database().reference().child("user-messages").child(currentUserID).childByAutoId().key ?? ""
                let membersIDs = fetchMembersIDs(activity: activity)
                createChatwActivity(chatID: chatID, membersIDs: membersIDs, activity: activity)
                delegate?.chosenChat(chatID: chatID, activityID: activity.activityID!)
            } else if let activityObject = activityObject {
                let destination = ContactsController()
                destination.activityObject = activityObject
                destination.hidesBottomBarWhenPushed = true
                let isContactsAccessGranted = destination.checkContactsAuthorizationStatus()
                if isContactsAccessGranted {
                    destination.users = users
                    destination.filteredUsers = filteredUsers
                    destination.conversations = conversations
                }
                navigationController?.pushViewController(destination, animated: true)
            }
        }
    }
    
    func createChatwActivity(chatID: String, membersIDs: ([String], [String:AnyObject]), activity: Activity) {
        if let currentUserID = Auth.auth().currentUser?.uid {
            let activities: [String] = [activity.activityID!]
            let groupChatsReference = Database.database().reference().child("groupChats").child(chatID).child(messageMetaDataFirebaseFolder)
            let childValues: [String: AnyObject] = ["chatID": chatID as AnyObject, "activities": activities as AnyObject, "chatName": activity.name as AnyObject, "chatParticipantsIDs": membersIDs.1 as AnyObject, "admin": currentUserID as AnyObject, "adminNeeded": false as AnyObject, "isGroupChat": true as AnyObject]
            activityCreatingGroup.enter()
            activityCreatingGroup.enter()
            activityCreatingGroup.enter()
            createGroupChatNode(reference: groupChatsReference, childValues: childValues)
            connectMembersToGroupChat(memberIDs: membersIDs.0, chatID: chatID)
            self.informationMessageSender.sendInformatoinMessage(chatID: chatID, membersIDs: membersIDs.0, text: "New group has been created")
            dismiss(animated: true, completion: nil)
        }
    }
    
    func fetchMembersIDs(activity: Activity) -> ([String], [String:AnyObject]) {
        var membersIDs = [String]()
        var membersIDsDictionary = [String:AnyObject]()

        guard let currentUserID = Auth.auth().currentUser?.uid else { return (membersIDs, membersIDsDictionary) }

        membersIDsDictionary.updateValue(currentUserID as AnyObject, forKey: currentUserID)
        membersIDs.append(currentUserID)
        
        if let participants = activity.participantsIDs {
            for participant in participants {
                membersIDsDictionary.updateValue(participant as AnyObject, forKey: participant)
                membersIDs.append(participant)
            }
        }

        return (membersIDs, membersIDsDictionary)
    }
    
    func connectMembersToGroupChat(memberIDs: [String], chatID: String) {
        let connectingMembersGroup = DispatchGroup()
        for _ in memberIDs {
            connectingMembersGroup.enter()
        }
        connectingMembersGroup.notify(queue: DispatchQueue.main, execute: {
            self.activityCreatingGroup.leave()
        })
        for memberID in memberIDs {
            let userReference = Database.database().reference().child("user-messages").child(memberID).child(chatID).child(messageMetaDataFirebaseFolder)
            let values:[String : Any] = ["isGroupChat": true]
            userReference.updateChildValues(values, withCompletionBlock: { (error, reference) in
                connectingMembersGroup.leave()
            })
        }
    }

    func createGroupChatNode(reference: DatabaseReference, childValues: [String: Any]) {
        let nodeCreationGroup = DispatchGroup()
        nodeCreationGroup.enter()
        nodeCreationGroup.notify(queue: DispatchQueue.main, execute: {
            self.activityCreatingGroup.leave()
        })
        reference.updateChildValues(childValues) { (error, reference) in
            nodeCreationGroup.leave()
        }
    }

  fileprivate func setupSearchController() {
    
    if #available(iOS 11.0, *) {
      searchChatsController = UISearchController(searchResultsController: nil)
      searchChatsController?.searchResultsUpdater = self
      searchChatsController?.obscuresBackgroundDuringPresentation = false
      searchChatsController?.searchBar.delegate = self
      searchChatsController?.definesPresentationContext = true
      navigationItem.searchController = searchChatsController
    } else {
      searchBar = UISearchBar()
      searchBar?.delegate = self
      searchBar?.placeholder = "Search"
      searchBar?.searchBarStyle = .minimal
      searchBar?.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: 50)
      tableView.tableHeaderView = searchBar
    }
  }
  
  func checkIfThereAnyActiveChats(isEmpty: Bool) {
    guard isEmpty else {
      viewPlaceholder.remove(from: view, priority: .medium)
      return
    }
    viewPlaceholder.add(for: view, title: .emptyChat, subtitle: .emptyChat, priority: .medium, position: .top)
  }
  
  func handleReloadTable() {
    conversations.sort { (conversation1, conversation2) -> Bool in
        return conversation1.lastMessage?.timestamp?.int64Value > conversation2.lastMessage?.timestamp?.int64Value
    }
    
    
    filteredConversations = conversations

    tableView.reloadData()
    
    if filteredConversations.count == 0  {
        checkIfThereAnyActiveChats(isEmpty: true)
    } else {
        checkIfThereAnyActiveChats(isEmpty: false)
    }
    
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
  override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    return UITableView.automaticDimension
  }
  
  override func numberOfSections(in tableView: UITableView) -> Int {
    return 1
  }

  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
      return filteredConversations.count
    
  }
  
  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    
        let cell = tableView.dequeueReusableCell(withIdentifier: userCellID, for: indexPath) as? UserCell ?? UserCell()
        
        cell.delegate = self
        cell.selectionStyle = .none
        cell.chatsViewControllerDataStore = self
        cell.configureCell(for: indexPath, conversations: filteredConversations)
        return cell
    
  }
  
  var chatLogController: ChatLogController? = nil
  var messagesFetcher: MessagesFetcher? = nil

  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    let conversation = filteredConversations[indexPath.row]
    if let chatID = conversation.chatID, let activity = activity, let activityName = activity.name?.trimmingCharacters(in: .whitespaces) {
        let newActivityName = activityName
        let text = "The \(newActivityName ) activity was connected to this chat"
        informationMessageSender.sendInformatoinMessage(chatID: chatID, membersIDs: activity.participantsIDs!, text: text)
        delegate?.chosenChat(chatID: chatID, activityID: activity.activityID!)
        dismiss(animated: true, completion: nil)
    } else if let activityObject = activityObject {
        let messageSender = MessageSender(conversation, text: activityObject.activityName, media: nil, activity: activityObject)
        messageSender.sendMessage()
        self.messageSentAlert()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: {
            self.removeAlert()
            self.dismiss(animated: true, completion: nil)
        })
    }
  }
}

extension ChooseChatTableViewController: ChatsViewControllerDataStore {
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

extension ChooseChatTableViewController: ChatCellDelegate {
    func getInfo(forConversation conversation: Conversation) {
        
    }
    
    func openActivity(forConversation conversation: Conversation) {
        
    }
}

extension ChooseChatTableViewController: UISearchBarDelegate, UISearchControllerDelegate, UISearchResultsUpdating {
  
  func updateSearchResults(for searchController: UISearchController) {}
  
  func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
    searchBar.text = nil
    filteredConversations = conversations
    handleReloadTable()
    guard #available(iOS 11.0, *) else {
      searchBar.setShowsCancelButton(false, animated: true)
      searchBar.resignFirstResponder()
      return
    }
  }
  
  func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
    
    filteredConversations = searchText.isEmpty ? conversations :
      conversations.filter({ (conversation) -> Bool in
        if let chatName = conversation.chatName {
          return chatName.lowercased().contains(searchText.lowercased())
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

extension ChooseChatTableViewController { /* hiding keyboard */
  
  override func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
    
    if #available(iOS 11.0, *) {
      searchChatsController?.searchBar.endEditing(true)
    } else {
      self.searchBar?.endEditing(true)
    }
  }
  
  func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
    setNeedsStatusBarAppearanceUpdate()
    if #available(iOS 11.0, *) {
      searchChatsController?.searchBar.endEditing(true)
    } else {
      self.searchBar?.endEditing(true)
    }
  }
}
