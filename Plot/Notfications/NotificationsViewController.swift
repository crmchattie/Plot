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

class NotificationsViewController: UIViewController, ObjectDetailShowing {
    
    let invitationsText = NSLocalizedString("Invitations", comment: "")
    let notificationsText = NSLocalizedString("Notifications", comment: "")

    var segmentedControl: UISegmentedControl!
    
    var networkController = NetworkController()
    
    var invitedActivities: [Activity] = []
    var filteredInvitedActivities: [Activity] = []
    var notificationActivities: [Activity] = []
    let invitationsFetcher = InvitationsFetcher()
    
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
        
//        let segmentTextContent = [
//            notificationsText,
//            invitationsText
//        ]
//
//        // Segmented control as the custom title view.
//        segmentedControl = UISegmentedControl(items: segmentTextContent)
//        if #available(iOS 13.0, *) {
//            segmentedControl.overrideUserInterfaceStyle = theme.userInterfaceStyle
//        } else {
//            // Fallback on earlier versions
//        }
//
//        segmentedControl.selectedSegmentIndex = 0
//        segmentedControl.autoresizingMask = .flexibleWidth
//        segmentedControl.addTarget(self, action: #selector(action(_:)), for: .valueChanged)
//        view.addSubview(segmentedControl)
        
        let doneBarButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(done))
        
        navigationItem.rightBarButtonItem = doneBarButton
        
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(EventCell.self, forCellReuseIdentifier: eventCellID)
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: notificationCellID)
        tableView.isUserInteractionEnabled = true
        tableView.indicatorStyle = ThemeManager.currentTheme().scrollBarStyle
        tableView.sectionIndexBackgroundColor = ThemeManager.currentTheme().generalBackgroundColor
        tableView.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
        tableView.separatorColor = .clear
        tableView.sectionHeaderHeight = 0
        tableView.rowHeight = UITableView.automaticDimension
        view.addSubview(tableView)

        tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 0).isActive = true
        tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0).isActive = true
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
//        if #available(iOS 13.0, *) {
//            segmentedControl.overrideUserInterfaceStyle = ThemeManager.currentTheme().userInterfaceStyle
//        } else {
//            // Fallback on earlier versions
//        }
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
//         if segmentedControl.selectedSegmentIndex == 0 {
//             self.tableView.reloadData()
//         }
        self.tableView.reloadData()
    }
    
//    override func viewDidLayoutSubviews() {
//        super.viewDidLayoutSubviews()
//        segmentedControl.frame = CGRect(x: view.frame.width * 0.125, y: 10, width: view.frame.width * 0.75, height: 30)
//        var frame = view.frame
//        frame.origin.y = segmentedControl.frame.maxY + 10
//        frame.size.height -= frame.origin.y
//        tableView.frame = frame
//    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: .userNotification, object: nil)
    }
    
    /// IBAction for the segmented control.
//    @IBAction func action(_ sender: UISegmentedControl) {
//        if sender.selectedSegmentIndex == 0 {
//            self.title = notificationsText
//        } else {
//            self.title = invitationsText
//        }
//
//        self.tableView.reloadData()
//    }
    
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
//        if segmentedControl.selectedSegmentIndex == 0 {
//            if notifications.isEmpty {
//                checkIfThereAnyNotifications(isEmpty: true)
//            } else {
//                checkIfThereAnyNotifications(isEmpty: false)
//            }
//            return notifications.count
//        } else {
//            if filteredInvitedActivities.isEmpty {
//                checkIfThereAnyActivities(isEmpty: true)
//            } else {
//                checkIfThereAnyActivities(isEmpty: false)
//            }
//            return filteredInvitedActivities.count
//        }
        
        if notifications.isEmpty {
            checkIfThereAnyNotifications(isEmpty: true)
        } else {
            checkIfThereAnyNotifications(isEmpty: false)
        }
        return notifications.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//        if segmentedControl.selectedSegmentIndex == 0 {
//            let theme = ThemeManager.currentTheme()
//            let cell = tableView.dequeueReusableCell(withIdentifier: notificationCellID, for: indexPath)
//            cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
//            let notification = notifications[indexPath.row]
//            cell.textLabel?.text = notification.description
//            cell.textLabel?.adjustsFontForContentSizeCategory = true
//            cell.textLabel?.numberOfLines = 0
//            cell.textLabel?.lineBreakMode = .byWordWrapping
//            cell.textLabel?.textColor = theme.generalTitleColor
//            let button = UIButton(type: .system)
//            cell.accessoryView = button
//            if notification.aps.category == Identifiers.eventCategory {
//                button.setImage(UIImage(named: "activity"), for: .normal)
//                cell.accessoryView?.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
//            }
//            return cell
//        } else {
//            let cell = tableView.dequeueReusableCell(withIdentifier: eventCellID, for: indexPath)
//            cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
//            if let eventCell = cell as? EventCell {
//                eventCell.updateInvitationDelegate = self
//                let activity = filteredInvitedActivities[indexPath.row]
//                var invitation: Invitation?
//                if let activityID = activity.activityID, let value = invitations[activityID] {
//                    invitation = value
//                }
//                eventCell.configureCell(for: indexPath, activity: activity, withInvitation: invitation)
//            }
//            return cell
//        }
        let theme = ThemeManager.currentTheme()
        let cell = tableView.dequeueReusableCell(withIdentifier: notificationCellID, for: indexPath)
        cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
        let notification = notifications[indexPath.row]
        cell.textLabel?.text = notification.description
        cell.textLabel?.adjustsFontForContentSizeCategory = true
        cell.textLabel?.numberOfLines = 0
        cell.textLabel?.lineBreakMode = .byWordWrapping
        cell.textLabel?.textColor = theme.generalTitleColor
        let button = UIButton(type: .system)
        cell.accessoryView = button
        if notification.aps.category == Identifiers.eventCategory {
            button.setImage(UIImage(named: "activity"), for: .normal)
            cell.accessoryView?.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        if segmentedControl.selectedSegmentIndex == 0 {
//            let notification = notifications[indexPath.row]
//            openNotification(forNotification: notification)
//        } else {
//            let activity = filteredInvitedActivities[indexPath.row]
//            openActivityDetailView(forActivity: activity)
//
//        }
        let notification = notifications[indexPath.row]
        openNotification(forNotification: notification)
        tableView.deselectRow(at: indexPath, animated: false)
    }
    
    func loadActivity(activity: Activity) {
        let destination = EventViewController(networkController: networkController)
        destination.hidesBottomBarWhenPushed = true
        destination.activity = activity
        destination.invitation = invitations[activity.activityID ?? ""]
        ParticipantsFetcher.getParticipants(forActivity: activity) { (participants) in
            ParticipantsFetcher.getAcceptedParticipant(forActivity: activity, allParticipants: participants) { acceptedParticipant in
                destination.acceptedParticipant = acceptedParticipant
                destination.selectedFalconUsers = participants
                self.navigationController?.pushViewController(destination, animated: true)
            }
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
    
    func openActivityDetailView(forActivity activity: Activity) {
        loadActivity(activity: activity)
    }
    
    func openNotification(forNotification notification: PLNotification) {
        let category = notification.aps.category
        if let ID = notification.objectID {
            if category == Identifiers.eventCategory {
                ActivitiesFetcher.getDataFromSnapshot(ID: ID) { fetched in
                    if let fetch = fetched.first {
                        ParticipantsFetcher.getParticipants(forActivity: fetch) { (participants) in
                            ParticipantsFetcher.getAcceptedParticipant(forActivity: fetch, allParticipants: participants) { acceptedParticipant in
                                self.showEventDetailPush(event: fetch)
                            }
                        }
                    }
                }
            } else if category == Identifiers.taskCategory {
                ActivitiesFetcher.getDataFromSnapshot(ID: ID) { fetched in
                    if let fetch = fetched.first {
                        ParticipantsFetcher.getParticipants(forActivity: fetch) { (participants) in
                            self.showTaskDetailPush(task: fetch)
                        }
                    }
                }
            } else if category == Identifiers.transactionCategory {
                FinancialTransactionFetcher.getDataFromSnapshot(ID: ID) { fetched in
                    if let fetch = fetched.first {
                        ParticipantsFetcher.getParticipants(forTransaction: fetch) { (participants) in
                            self.showTransactionDetailPush(transaction: fetch)
                        }
                    }
                }
            } else if category == Identifiers.accountCategory {
                FinancialAccountFetcher.getDataFromSnapshot(ID: ID) { fetched in
                    if let fetch = fetched.first {
                        ParticipantsFetcher.getParticipants(forAccount: fetch) { (participants) in
                            self.showAccountDetailPush(account: fetch)
                        }
                    }
                }
            } else if category == Identifiers.workoutCategory {
                WorkoutFetcher.getDataFromSnapshot(ID: ID) { fetched in
                    if let fetch = fetched.first {
                        ParticipantsFetcher.getParticipants(forWorkout: fetch) { (participants) in
                            self.showWorkoutDetailPush(workout: fetch)
                        }
                    }
                }
            } else if category == Identifiers.mindfulnessCategory {
                MindfulnessFetcher.getDataFromSnapshot(ID: ID) { fetched in
                    if let fetch = fetched.first {
                        ParticipantsFetcher.getParticipants(forMindfulness: fetch) { (participants) in
                            self.showMindfulnessDetailPush(mindfulness: fetch)
                        }
                    }
                }
            } else if category == Identifiers.listCategory {
                ListFetcher.getDataFromSnapshot(ID: ID) { fetched in
                    if let fetch = fetched.first {
                        ParticipantsFetcher.getParticipants(forList: fetch) { (participants) in
                            self.showListDetailPush(list: fetch)
                        }
                    }
                }
            } else if category == Identifiers.calendarCategory {
                CalendarFetcher.getDataFromSnapshot(ID: ID) { fetched in
                    if let fetch = fetched.first {
                        ParticipantsFetcher.getParticipants(forCalendar: fetch) { (participants) in
                            self.showCalendarDetailPush(calendar: fetch)
                        }
                    }
                }
            }
        }
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
