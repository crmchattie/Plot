//
//  NotificationsViewController.swift
//  Plot
//
//  Created by Hafiz Usama on 2019-11-24.
//  Copyright © 2019 Immature Creations. All rights reserved.
//

import UIKit
import Firebase
import CodableFirebase

class NotificationsViewController: UIViewController {
    
    let invitationsText = NSLocalizedString("Invitations", comment: "")
    let notificationsText = NSLocalizedString("Notifications", comment: "")

    var segmentedControl: UISegmentedControl!
    var invitedActivities: [Activity] = []
    var filteredInvitedActivities: [Activity] = []
    var notificationActivities: [Activity] = []
    var listList = [ListContainer]()
    var chatLogController: ChatLogController? = nil
    var messagesFetcher: MessagesFetcher? = nil
    let invitationsFetcher = InvitationsFetcher()
    var networkController = NetworkController()
    
    var invitations = [String: Invitation]()
    var users = [User]()
    var filteredUsers = [User]()
    var conversations = [Conversation]()
    
    var participants: [String: [User]] = [:]
    var activitiesParticipants: [String: [User]] = [:]
    
    let tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        return tableView
    }()
    
    let viewPlaceholder = ViewPlaceholder()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.largeTitleDisplayMode = .never
                        
        self.title = notificationsText
        
        let theme = ThemeManager.currentTheme()
        view.backgroundColor = theme.generalBackgroundColor
        navigationController?.navigationBar.backgroundColor = theme.barBackgroundColor
        
        let segmentTextContent = [
            notificationsText,
            invitationsText
        ]
        
        // Segmented control as the custom title view.
        segmentedControl = UISegmentedControl(items: segmentTextContent)
        if #available(iOS 13.0, *) {
            segmentedControl.overrideUserInterfaceStyle = theme.userInterfaceStyle
        } else {
            // Fallback on earlier versions
        }
        
        segmentedControl.selectedSegmentIndex = 0
        segmentedControl.autoresizingMask = .flexibleWidth
        segmentedControl.addTarget(self, action: #selector(action(_:)), for: .valueChanged)
        view.addSubview(segmentedControl)
        
        let doneBarButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(done))
        
        navigationItem.rightBarButtonItem = doneBarButton
        
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(ActivityCell.self, forCellReuseIdentifier: activityCellID)
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: notificationCellID)
        tableView.isUserInteractionEnabled = true
        tableView.indicatorStyle = ThemeManager.currentTheme().scrollBarStyle
        tableView.sectionIndexBackgroundColor = ThemeManager.currentTheme().generalBackgroundColor
        tableView.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
        tableView.separatorColor = .clear
        tableView.sectionHeaderHeight = 0
        tableView.rowHeight = UITableView.automaticDimension
        view.addSubview(tableView)
        tableView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 0).isActive = true
        tableView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: 0).isActive = true
                
        addObservers()
                        
    }
    
    fileprivate func addObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(changeTheme), name: .themeUpdated, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(userNotification(notification:)), name: .userNotification, object: nil)
    }
    
    @objc fileprivate func changeTheme() {
        view.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
        if #available(iOS 13.0, *) {
            segmentedControl.overrideUserInterfaceStyle = ThemeManager.currentTheme().userInterfaceStyle
        } else {
            // Fallback on earlier versions
        }
        tableView.indicatorStyle = ThemeManager.currentTheme().scrollBarStyle
        tableView.sectionIndexBackgroundColor = ThemeManager.currentTheme().generalBackgroundColor
        tableView.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
        tableView.reloadData()
    }
    
    func sortInvitedActivities() {
        var invitationValues = Array(invitations.values)
        invitationValues = invitationValues.filter { ($0.status == .pending)}
        invitationValues.sort { (invitation1, invitation2) -> Bool in
            return invitation1.dateInvited > invitation2.dateInvited
        }
        let invitationActivityIDs = invitationValues.map({ $0.activityID})
        filteredInvitedActivities = invitedActivities.filter({ invitationActivityIDs.contains($0.activityID ?? "") })
        tableView.reloadData()
    }
    
    @objc func userNotification(notification: NSNotification) {
         if segmentedControl.selectedSegmentIndex == 0 {
             self.tableView.reloadData()
         }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        segmentedControl.frame = CGRect(x: view.frame.width * 0.125, y: 10, width: view.frame.width * 0.75, height: 30)
        var frame = view.frame
        frame.origin.y = segmentedControl.frame.maxY + 10
        frame.size.height -= frame.origin.y
        tableView.frame = frame
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: .userNotification, object: nil)
    }
    
    /// IBAction for the segmented control.
    @IBAction func action(_ sender: UISegmentedControl) {
        if sender.selectedSegmentIndex == 0 {
            self.title = notificationsText
        } else {
            self.title = invitationsText
        }
        
        self.tableView.reloadData()
    }
    
    @IBAction func done(_ sender: AnyObject) {
        self.dismiss(animated: true, completion: nil)
    }
    
    func checkIfThereAnyActivities(isEmpty: Bool) {
        guard isEmpty else {
            viewPlaceholder.remove(from: tableView, priority: .medium)
            return
        }
        if invitedActivities.isEmpty {
            viewPlaceholder.add(for: tableView, title: .emptyInvitedActivities, subtitle: .emptyInvitedActivities, priority: .medium, position: .top)
        } else {
            viewPlaceholder.add(for: tableView, title: .emptyFilteredInvitedActivities, subtitle: .emptyFilteredInvitedActivities, priority: .medium, position: .top)
        }
    }
    
    func checkIfThereAnyNotifications(isEmpty: Bool) {
        guard isEmpty else {
            viewPlaceholder.remove(from: tableView, priority: .medium)
            return
        }
        viewPlaceholder.add(for: tableView, title: .emptyNotifications, subtitle: .empty, priority: .medium, position: .top)
    }
}


extension NotificationsViewController: UITableViewDataSource, UITableViewDelegate {
        
    var notifications: [PLNotification] {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        return appDelegate.notifications
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return UIView()
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0
    }
        
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if segmentedControl.selectedSegmentIndex == 0 {
            if notifications.isEmpty {
                checkIfThereAnyNotifications(isEmpty: true)
            } else {
                checkIfThereAnyNotifications(isEmpty: false)
            }
            return notifications.count
        } else {
            if filteredInvitedActivities.isEmpty {
                checkIfThereAnyActivities(isEmpty: true)
            } else {
                checkIfThereAnyActivities(isEmpty: false)
            }
            return filteredInvitedActivities.count
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if segmentedControl.selectedSegmentIndex == 0 {
            let theme = ThemeManager.currentTheme()
            let cell = tableView.dequeueReusableCell(withIdentifier: notificationCellID, for: indexPath)
            cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
            let notification = notifications[indexPath.row]
            cell.textLabel?.text = notification.description
            cell.textLabel?.sizeToFit()
            cell.textLabel?.numberOfLines = 0
            cell.textLabel?.lineBreakMode = .byWordWrapping
            cell.textLabel?.textColor = theme.generalTitleColor
            let button = UIButton(type: .system)
            button.isUserInteractionEnabled = true
            button.addTarget(self, action: #selector(NotificationsViewController.notificationButtonTapped(_:)), for: .touchUpInside)
            button.tag = indexPath.row
            cell.accessoryView = button
            if notification.aps.category == Identifiers.chatCategory {
                button.setImage(UIImage(named: "chat"), for: .normal)
                cell.accessoryView?.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
            } else if notification.aps.category == Identifiers.activityCategory {
                button.setImage(UIImage(named: "activity"), for: .normal)
                cell.accessoryView?.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
            } else if notification.aps.category == Identifiers.checklistCategory {
                button.setImage(UIImage(named: "list"), for: .normal)
                cell.accessoryView?.frame = CGRect(x: 0, y: 0, width: 36, height: 30)
            } else if notification.aps.category == Identifiers.grocerylistCategory {
                button.setImage(UIImage(named: "list"), for: .normal)
                cell.accessoryView?.frame = CGRect(x: 0, y: 0, width: 36, height: 30)
            } else if notification.aps.category == Identifiers.activitylistCategory {
                button.setImage(UIImage(named: "list"), for: .normal)
                cell.accessoryView?.frame = CGRect(x: 0, y: 0, width: 36, height: 30)
            }
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: activityCellID, for: indexPath)
            cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
            if let activityCell = cell as? ActivityCell {
                activityCell.updateInvitationDelegate = self
                activityCell.activityViewControllerDataStore = self
                let activity = filteredInvitedActivities[indexPath.row]
                var invitation: Invitation?
                if let activityID = activity.activityID, let value = invitations[activityID] {
                    invitation = value
                }
                activityCell.configureCell(for: indexPath, activity: activity, withInvitation: invitation)
            }
            return cell
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if segmentedControl.selectedSegmentIndex == 0 {
            let notification = notifications[indexPath.row]
            if notification.aps.category == Identifiers.chatCategory {
                if let chatID = notification.chatID, let chat = conversations.first(where: { (chat) -> Bool in
                    chat.chatID == chatID
                }) {
                    openChatDetailView(forChat: chat)
                }
            } else if notification.aps.category == Identifiers.activityCategory {
                if let activityID = notification.activityID {
                    if let activity = notificationActivities.first(where: { (activity) -> Bool in
                        activity.activityID == activityID
                    }) {
                        openActivityDetailView(forActivity: activity)
                    }
                }
            } else if notification.aps.category == Identifiers.checklistCategory {
                if let checklistID = notification.checklistID {
                    if let list = listList.first(where: { (list) -> Bool in
                        list.ID == checklistID
                    }) {
                        if let checklist = list.checklist {
                            let destination = ChecklistViewController()
                            destination.hidesBottomBarWhenPushed = true
                            destination.checklist = checklist
                            destination.comingFromLists = true
                            destination.connectedToAct = checklist.activityID != nil
                            destination.users = self.users
                            destination.filteredUsers = self.filteredUsers
                            destination.activities = self.notificationActivities
                            destination.conversations = self.conversations
                            self.getParticipants(grocerylist: nil, checklist: checklist, packinglist: nil) { (participants) in
                                destination.selectedFalconUsers = participants
                                self.navigationController?.pushViewController(destination, animated: true)
                            }
                        }
                    }
                }
            } else if notification.aps.category == Identifiers.grocerylistCategory {
                if let grocerylistID = notification.grocerylistID {
                    if let list = listList.first(where: { (list) -> Bool in
                        list.ID == grocerylistID
                    }) {
                        if let grocerylist = list.grocerylist {
                            let destination = GrocerylistViewController()
                            destination.hidesBottomBarWhenPushed = true
                            destination.grocerylist = grocerylist
                            destination.comingFromLists = true
                            destination.connectedToAct = grocerylist.activityID != nil
                            destination.users = self.users
                            destination.filteredUsers = self.filteredUsers
                            destination.activities = self.notificationActivities
                            destination.conversations = self.conversations
                            self.getParticipants(grocerylist: grocerylist, checklist: nil, packinglist: nil) { (participants) in
                                destination.selectedFalconUsers = participants
                                self.navigationController?.pushViewController(destination, animated: true)
                            }
                        }
                    }
                }
            }
        } else {
            let activity = filteredInvitedActivities[indexPath.row]
            openActivityDetailView(forActivity: activity)
            
        }
        tableView.deselectRow(at: indexPath, animated: false)
    }
    
    func openChatDetailView(forChat chat: Conversation) {
        chatLogController = ChatLogController(collectionViewLayout: AutoSizingCollectionViewFlowLayout())
        messagesFetcher = MessagesFetcher()
        messagesFetcher?.delegate = self
        messagesFetcher?.loadMessagesData(for: chat)
    }
    
    func openActivityDetailView(forActivity activity: Activity) {
        loadActivity(activity: activity)
        
    }
    
    @objc func notificationButtonTapped(_ sender: UIButton) {
        if segmentedControl.selectedSegmentIndex == 0 {
            if sender.tag >= 0 && sender.tag < notifications.count {
                let notification = notifications[sender.tag]
                if notification.aps.category == Identifiers.chatCategory {
                    print("Identifiers.chatCategory")
                    if let chatID = notification.chatID, let chat = conversations.first(where: { (chat) -> Bool in
                        chat.chatID == chatID
                    }) {
                        print("openChatDetailView")
                        openChatDetailView(forChat: chat)
                    }
                }
                else if notification.aps.category == Identifiers.activityCategory {
                    if let activityID = notification.activityID {
                        if let activity = notificationActivities.first(where: { (activity) -> Bool in
                            activity.activityID == activityID
                        }) {
                            openActivityDetailView(forActivity: activity)
                        }
                    }
                } else if notification.aps.category == Identifiers.checklistCategory {
                    if let checklistID = notification.checklistID {
                        if let list = listList.first(where: { (list) -> Bool in
                            list.ID == checklistID
                        }) {
                            if let checklist = list.checklist {
                                let destination = ChecklistViewController()
                                destination.hidesBottomBarWhenPushed = true
                                destination.checklist = checklist
                                destination.comingFromLists = true
                                destination.connectedToAct = checklist.activityID != nil
                                destination.users = self.users
                                destination.filteredUsers = self.filteredUsers
                                destination.activities = self.notificationActivities
                                destination.conversations = self.conversations
                                self.getParticipants(grocerylist: nil, checklist: checklist, packinglist: nil) { (participants) in
                                    destination.selectedFalconUsers = participants
                                    self.navigationController?.pushViewController(destination, animated: true)
                                }
                            }
                        }
                    }
                } else if notification.aps.category == Identifiers.grocerylistCategory {
                    if let grocerylistID = notification.grocerylistID {
                        if let list = listList.first(where: { (list) -> Bool in
                            list.ID == grocerylistID
                        }) {
                            if let grocerylist = list.grocerylist {
                                let destination = GrocerylistViewController()
                                destination.hidesBottomBarWhenPushed = true
                                destination.grocerylist = grocerylist
                                destination.comingFromLists = true
                                destination.connectedToAct = grocerylist.activityID != nil
                                destination.users = self.users
                                destination.filteredUsers = self.filteredUsers
                                destination.activities = self.notificationActivities
                                destination.conversations = self.conversations
                                self.getParticipants(grocerylist: grocerylist, checklist: nil, packinglist: nil) { (participants) in
                                    destination.selectedFalconUsers = participants
                                    self.navigationController?.pushViewController(destination, animated: true)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    func loadActivity(activity: Activity) {
        let destination = EventViewController(networkController: networkController)
        destination.hidesBottomBarWhenPushed = true
        destination.activity = activity
        destination.invitation = invitations[activity.activityID ?? ""]
        self.getParticipants(forActivity: activity) { (participants) in
            InvitationsFetcher.getAcceptedParticipant(forActivity: activity, allParticipants: participants) { acceptedParticipant in
                destination.acceptedParticipant = acceptedParticipant
                destination.selectedFalconUsers = participants
                self.navigationController?.pushViewController(destination, animated: true)
            }
        }
    }
    
    func getParticipants(grocerylist: Grocerylist?, checklist: Checklist?, packinglist: Packinglist?, completion: @escaping ([User])->()) {
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
    
    func showActivityIndicator() {
        if let tabController = self.tabBarController {
            self.showSpinner(onView: tabController.view)
        }
        self.navigationController?.view.isUserInteractionEnabled = false
    }
    
    func hideActivityIndicator() {
        self.navigationController?.view.isUserInteractionEnabled = true
        self.removeSpinner()
    }
}

extension NotificationsViewController: MessagesDelegate {
    
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

extension NotificationsViewController: UpdateInvitationDelegate {
    func updateInvitation(invitation: Invitation) {
        InvitationsFetcher.update(invitation: invitation) { result in
            if result {
                self.invitations[invitation.activityID] = invitation
            }
        }
    }
}

extension NotificationsViewController: ActivityViewControllerDataStore {
    func getParticipants(forActivity activity: Activity, completion: @escaping ([User])->()) {
        guard let activityID = activity.activityID, let participantsIDs = activity.participantsIDs, let currentUserID = Auth.auth().currentUser?.uid else {
            return
        }
        
        
        let group = DispatchGroup()
        let olderParticipants = self.activitiesParticipants[activityID]
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
            self.activitiesParticipants[activityID] = participants
            completion(participants)
        }
    }
}

extension NotificationsViewController: ChooseChatDelegate {
    func chosenChat(chatID: String, activityID: String?, grocerylistID: String?, checklistID: String?, packinglistID: String?, activitylistID: String?) {

    }
}
