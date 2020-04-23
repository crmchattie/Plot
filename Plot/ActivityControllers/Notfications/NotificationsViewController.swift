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
    weak var activityViewController: ActivityViewController?
    var invitedActivities: [Activity] = []
    var notificationActivities: [Activity] = []
    var chatLogController: ChatLogController? = nil
    var messagesFetcher: MessagesFetcher? = nil
    
    var invitations = [String: Invitation]()
    var users = [User]()
    var filteredUsers = [User]()
    var conversations = [Conversation]()
    
    let tableView: UITableView = {
        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        return tableView
    }()
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: false)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: false)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print("loading updates")
        
        self.title = invitationsText
        let theme = ThemeManager.currentTheme()
        view.backgroundColor = theme.generalBackgroundColor
        
        let segmentTextContent = [
            invitationsText,
            notificationsText,
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
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 44
        view.addSubview(tableView)
        
        NotificationCenter.default.addObserver(self, selector: #selector(userNotification(notification:)), name: .userNotification, object: nil)
        
        addObservers()
                
    }
    
    fileprivate func addObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(changeTheme), name: .themeUpdated, object: nil)
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
        invitationValues.sort { (invitation1, invitation2) -> Bool in
            return invitation1.dateInvited > invitation2.dateInvited
        }
        let invitationActivityIDs = invitationValues.map({ $0.activityID})
        invitedActivities = invitedActivities.sorted { invitationActivityIDs.firstIndex(of: $0.activityID!)! < invitationActivityIDs.firstIndex(of: $1.activityID!)! }
        tableView.reloadData()
    }
    
    @objc func userNotification(notification: NSNotification) {
         if segmentedControl.selectedSegmentIndex == 1 {
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
            self.title = invitationsText
        } else {
            self.title = notificationsText
        }
        
        self.tableView.reloadData()
    }
    
    @IBAction func done(_ sender: AnyObject) {
        self.dismiss(animated: true, completion: nil)
    }
}


extension NotificationsViewController: UITableViewDataSource, UITableViewDelegate {
        
    var notifications: [PLNotification] {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        return appDelegate.notifications
    }
        
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if segmentedControl.selectedSegmentIndex == 0 {
            return invitedActivities.count
        } else {
            return notifications.count
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if segmentedControl.selectedSegmentIndex == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: activityCellID, for: indexPath)
            if let activityCell = cell as? ActivityCell {
                activityCell.delegate = activityViewController
                activityCell.updateInvitationDelegate = activityViewController
                activityCell.activityViewControllerDataStore = activityViewController
                
                let activity = invitedActivities[indexPath.row]
                var invitation: Invitation?
                if let activityID = activity.activityID, let value = invitations[activityID] {
                    invitation = value
                }
                activityCell.configureCell(for: indexPath, activity: activity, withInvitation: invitation)
            }
            
            return cell
        } else {
            let theme = ThemeManager.currentTheme()
            let cell = tableView.dequeueReusableCell(withIdentifier: notificationCellID, for: indexPath)
            let notification = notifications[indexPath.row]
            cell.textLabel?.text = notification.description
            cell.textLabel?.sizeToFit()
            cell.textLabel?.numberOfLines = 0
            cell.textLabel?.lineBreakMode = .byWordWrapping
            cell.textLabel?.textColor = theme.generalTitleColor
            let imageName = notification.aps.category == Identifiers.chatCategory ? "chat" : "activity"
            cell.backgroundColor = .clear
            let button = UIButton(type: .system)
            button.setImage(UIImage(named:imageName), for: .normal)
            button.isUserInteractionEnabled = true
            button.addTarget(self, action: #selector(NotificationsViewController.notificationButtonTapped(_:)), for: .touchUpInside)
            button.tag = indexPath.row
            cell.accessoryView = button
            cell.accessoryView?.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
            
            return cell
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if segmentedControl.selectedSegmentIndex == 0 {
            let activity = invitedActivities[indexPath.row]
            openActivityDetailView(forActivity: activity)
        } else {
            let notification = notifications[indexPath.row]
            if notification.aps.category == Identifiers.chatCategory {
                if let chatID = notification.chatID {
                    if let conversation = conversations.first(where: { (conversation) -> Bool in
                        conversation.chatID == chatID
                    }) {
                        openChatDetailView(forChat: conversation)
                    }
                }
            } else if notification.aps.category == Identifiers.activityCategory {
                if let activityID = notification.activityID {
                    if let activity = notificationActivities.first(where: { (activity) -> Bool in
                        activity.activityID == activityID
                    }) {
                        openActivityDetailView(forActivity: activity)
                    }
                }
            }
        }
    }
    
    func openChatDetailView(forChat chat: Conversation) {
        chatLogController = ChatLogController(collectionViewLayout: AutoSizingCollectionViewFlowLayout())
        messagesFetcher = MessagesFetcher()
        messagesFetcher?.delegate = self
        messagesFetcher?.loadMessagesData(for: chat)
    }
    
    func openActivityDetailView(forActivity activity: Activity) {
        if let navController = self.navigationController {
            self.showSpinner(onView: navController.view)
        } else {
            self.showSpinner(onView: self.view)
        }
        
        let dispatchGroup = DispatchGroup()
                
        if let recipeString = activity.recipeID, let recipeID = Int(recipeString) {
            dispatchGroup.enter()
            Service.shared.fetchRecipesInfo(id: recipeID) { (search, err) in
                let detailedRecipe = search
                dispatchGroup.leave()
                dispatchGroup.notify(queue: .main) {
                    let destination = MealDetailViewController()
                    destination.hidesBottomBarWhenPushed = true
                    destination.recipe = detailedRecipe
                    destination.detailedRecipe = detailedRecipe
                    destination.activity = activity
                    destination.invitation = self.invitations[activity.activityID!]
                    destination.users = self.users
                    destination.filteredUsers = self.filteredUsers
                    destination.conversations = self.conversations
                    self.activityViewController?.getParticipants(forActivity: activity) { [weak self] (participants) in
                        InvitationsFetcher.getAcceptedParticipant(forActivity: activity, allParticipants: participants) { acceptedParticipant in
                            self!.removeSpinner()
                            destination.acceptedParticipant = acceptedParticipant
                            destination.selectedFalconUsers = participants
                            self?.navigationController?.pushViewController(destination, animated: true)
                        }
                    }
                }
            }
        } else if let eventID = activity.eventID {
            dispatchGroup.enter()
            Service.shared.fetchEventsSegment(size: "50", id: eventID, keyword: "", attractionId: "", venueId: "", postalCode: "", radius: "", unit: "", startDateTime: "", endDateTime: "", city: "", stateCode: "", countryCode: "", classificationName: "", classificationId: "") { (search, err) in
                if let events = search?.embedded?.events {
                    let event = events[0]
                    dispatchGroup.leave()
                    dispatchGroup.notify(queue: .main) {
                        let destination = EventDetailViewController()
                        destination.hidesBottomBarWhenPushed = true
                        destination.event = event
                        destination.activity = activity
                        destination.invitation = self.invitations[activity.activityID!]
                        destination.users = self.users
                        destination.filteredUsers = self.filteredUsers
                        destination.conversations = self.conversations
                        self.activityViewController?.getParticipants(forActivity: activity) { [weak self] (participants) in
                            InvitationsFetcher.getAcceptedParticipant(forActivity: activity, allParticipants: participants) { acceptedParticipant in
                                self!.removeSpinner()
                                destination.acceptedParticipant = acceptedParticipant
                                destination.selectedFalconUsers = participants
                                self?.navigationController?.pushViewController(destination, animated: true)
                            }
                        }
                    }
                }
            }
        } else if let workoutID = activity.workoutID {
            var reference = Database.database().reference()
            dispatchGroup.enter()
            reference = Database.database().reference().child("workouts").child("workouts")
            reference.child(workoutID).observeSingleEvent(of: .value, with: { (snapshot) in
                if snapshot.exists(), let workoutSnapshotValue = snapshot.value {
                    if let workout = try? FirebaseDecoder().decode(Workout.self, from: workoutSnapshotValue) {
                        dispatchGroup.leave()
                        let destination = WorkoutDetailViewController()
                        destination.hidesBottomBarWhenPushed = true
                        destination.workout = workout
                        destination.intColor = 0
                        destination.activity = activity
                        destination.invitation = self.invitations[activity.activityID!]
                        destination.users = self.users
                        destination.filteredUsers = self.filteredUsers
                        destination.conversations = self.conversations
                        self.activityViewController?.getParticipants(forActivity: activity) { [weak self] (participants) in
                            InvitationsFetcher.getAcceptedParticipant(forActivity: activity, allParticipants: participants) { acceptedParticipant in
                                self!.removeSpinner()
                                destination.acceptedParticipant = acceptedParticipant
                                destination.selectedFalconUsers = participants
                                self?.navigationController?.pushViewController(destination, animated: true)
                            }
                        }
                    }
                }
              })
            { (error) in
                print(error.localizedDescription)
            }
        } else if let attractionID = activity.attractionID {
            dispatchGroup.enter()
            Service.shared.fetchAttractionsSegment(size: "50", id: attractionID, keyword: "", classificationName: "", classificationId: "") { (search, err) in
                let attraction = search?.embedded?.attractions![0]
                dispatchGroup.leave()
                dispatchGroup.notify(queue: .main) {
                    let destination = EventDetailViewController()
                    destination.hidesBottomBarWhenPushed = true
                    destination.attraction = attraction
                    destination.activity = activity
                    destination.invitation = self.invitations[activity.activityID!]
                    destination.users = self.users
                    destination.filteredUsers = self.filteredUsers
                    destination.conversations = self.conversations
                    self.activityViewController?.getParticipants(forActivity: activity) { [weak self] (participants) in
                        InvitationsFetcher.getAcceptedParticipant(forActivity: activity, allParticipants: participants) { acceptedParticipant in
                            self!.removeSpinner()
                            destination.acceptedParticipant = acceptedParticipant
                            destination.selectedFalconUsers = participants
                            self?.navigationController?.pushViewController(destination, animated: true)
                        }
                    }
                }
            }
        } else {
            self.removeSpinner()
            let destination = CreateActivityViewController()
            destination.hidesBottomBarWhenPushed = true
            destination.activity = activity
            destination.invitation = invitations[activity.activityID!]
            destination.users = users
            destination.filteredUsers = filteredUsers
            destination.conversations = conversations
            activityViewController?.getParticipants(forActivity: activity) { [weak self] (participants) in
                InvitationsFetcher.getAcceptedParticipant(forActivity: activity, allParticipants: participants) { acceptedParticipant in
                    destination.acceptedParticipant = acceptedParticipant
                    destination.selectedFalconUsers = participants
                    self?.navigationController?.pushViewController(destination, animated: true)
                }
            }
        }
    }
    
    @objc func notificationButtonTapped(_ sender: UIButton) {
        if segmentedControl.selectedSegmentIndex == 1 {
            if sender.tag >= 0 && sender.tag < notifications.count {
                let notification = notifications[sender.tag]
                if notification.aps.category == Identifiers.chatCategory {
                    if let chatID = notification.chatID {
                        self.activityViewController?.openChat(forConversation: chatID, activityID: nil)
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
                }
            }
        }
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
