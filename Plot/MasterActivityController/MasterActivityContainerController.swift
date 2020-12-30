//
//  MasterActivityController.swift
//  Plot
//
//  Created by Cory McHattie on 4/21/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import UIKit
import Contacts
import Firebase
import CodableFirebase
import LBTATools

fileprivate let activitiesControllerCell = "ActivitiesControllerCell"
fileprivate let healthControllerCell = "HealthControllerCell"
fileprivate let financeControllerCell = "FinanceControllerCell"
fileprivate let setupCell = "SetupCell"
fileprivate let headerContainerCell = "HeaderCellDelegate"


enum Mode {
    case small, fullscreen
}

protocol ManageAppearanceHome: class {
    func manageAppearanceHome(_ homeController: MasterActivityContainerController, didFinishLoadingWith state: Bool )
}

class MasterActivityContainerController: UIViewController {
    var networkController = NetworkController() {
        didSet {
            scrollToFirstActivityWithDate({ (activities) in
                self.sortedActivities = activities
                self.grabFinancialItems { (sections, groups) in
                    self.financeSections = sections
                    self.financeGroups = groups
                    self.collectionView.reloadData()
                }
            })
        }
    }

    let collectionView:UICollectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout: UICollectionViewFlowLayout.init())
    let layout:UICollectionViewFlowLayout = UICollectionViewFlowLayout.init()
        
    let navigationItemActivityIndicator = NavigationItemActivityIndicator()
        
    weak var delegate: ManageAppearanceHome?
            
    var sections: [SectionType] = [.calendar, .health, .finances]
    
    var sortedActivities = [Activity]()
    var financeSections = [SectionType]()
    var financeGroups = [SectionType: [AnyHashable]]()
    
    var chatLogController: ChatLogController? = nil
    var messagesFetcher: MessagesFetcher? = nil
    
    var activitiesParticipants: [String: [User]] = [:]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        setNavBar()
        addObservers()
        delegate?.manageAppearanceHome(self, didFinishLoadingWith: true)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        managePresense()
    }

    func setupViews() {
        navigationItem.largeTitleDisplayMode = .always
        navigationController?.navigationBar.prefersLargeTitles = true
        
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for:.default)
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.navigationBar.layoutIfNeeded()
        
        tabBarController?.tabBar.barTintColor = ThemeManager.currentTheme().barBackgroundColor
        tabBarController?.tabBar.barStyle = ThemeManager.currentTheme().barStyle
        
        view.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
        collectionView.indicatorStyle = ThemeManager.currentTheme().scrollBarStyle
        collectionView.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
        
        extendedLayoutIncludesOpaqueBars = true
        definesPresentationContext = true
        edgesForExtendedLayout = UIRectEdge.top
        
        layout.scrollDirection = UICollectionView.ScrollDirection.vertical
        collectionView.setCollectionViewLayout(layout, animated: true)
        collectionView.dataSource = self
        collectionView.delegate = self
        
        view.addSubview(collectionView)
        collectionView.fillSuperview()
        
        collectionView.register(ActivitiesControllerCell.self, forCellWithReuseIdentifier: activitiesControllerCell)
        collectionView.register(HealthControllerCell.self, forCellWithReuseIdentifier: healthControllerCell)
        collectionView.register(FinanceControllerCell.self, forCellWithReuseIdentifier: financeControllerCell)
        collectionView.register(SetupCell.self, forCellWithReuseIdentifier: setupCell)
        collectionView.register(HeaderContainerCell.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: headerContainerCell)
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return ThemeManager.currentTheme().statusBarStyle
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    fileprivate func addObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(changeTheme), name: .themeUpdated, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(activitiesUpdated), name: .activitiesUpdated, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(financeUpdated), name: .financeUpdated, object: nil)
    }
    
    @objc fileprivate func changeTheme() {
        view.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
        navigationController?.navigationBar.barStyle = ThemeManager.currentTheme().barStyle
        navigationController?.navigationBar.barTintColor = ThemeManager.currentTheme().barBackgroundColor
        let textAttributes = [NSAttributedString.Key.foregroundColor: ThemeManager.currentTheme().generalTitleColor]
        navigationController?.navigationBar.titleTextAttributes = textAttributes
        navigationController?.navigationBar.largeTitleTextAttributes = textAttributes
        navigationController?.navigationBar.backgroundColor = ThemeManager.currentTheme().barBackgroundColor
        
        tabBarController?.tabBar.barTintColor = ThemeManager.currentTheme().barBackgroundColor
        tabBarController?.tabBar.barStyle = ThemeManager.currentTheme().barStyle
        
        collectionView.indicatorStyle = ThemeManager.currentTheme().scrollBarStyle
        collectionView.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
        collectionView.reloadData()
        
    }
    
    @objc fileprivate func activitiesUpdated() {
        scrollToFirstActivityWithDate({ (activities) in
            if self.sortedActivities != activities {
                self.sortedActivities = activities
                self.collectionView.reloadData()
            }
        })
    }
    
    @objc fileprivate func financeUpdated() {
        self.grabFinancialItems { (sections, groups) in
            if self.financeSections != sections || self.financeGroups != groups {
                self.financeSections = sections
                self.financeGroups = groups
                self.collectionView.reloadData()
            }
        }
    }
    
    func setNavBar() {
        let notificationsBarButton = UIBarButtonItem(image: UIImage(named: "notification-bell"), style: .plain, target: self, action: #selector(goToNotifications))
        navigationItem.leftBarButtonItem = notificationsBarButton
        
        let newItemBarButton =  UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(newItem))
        navigationItem.rightBarButtonItem = newItemBarButton
        
    }
    
    func configureTabBarBadge() {
//        guard let tabItems = tabBarController?.tabBar.items as NSArray? else { return }
//        guard let tabItem = tabItems[Tabs.home.rawValue] as? UITabBarItem else { return }
//        guard !listList.isEmpty, !activities.isEmpty, !conversations.isEmpty, let uid = Auth.auth().currentUser?.uid else { return }
//        var badge = 0
//        
//        for activity in activities {
//            guard let activityBadge = activity.badge else { continue }
//            badge += activityBadge
//        }
//        
//        for conversation in conversations {
//            guard let lastMessage = conversation.lastMessage, let conversationBadge = conversation.badge, lastMessage.fromId != uid  else { continue }
//            badge += conversationBadge
//        }
//        
//        for list in listList {
//            badge += list.badge
//        }
//        
//        guard badge > 0 else {
//            tabItem.badgeValue = nil
//            setApplicationBadge()
//            return
//        }
//        tabItem.badgeValue = badge.toString()
//        setApplicationBadge()
    }
    
    func setApplicationBadge() {
        guard let tabItems = tabBarController?.tabBar.items as NSArray? else { return }
        var badge = 0
        
        for tab in 0...tabItems.count - 1 {
            guard let tabItem = tabItems[tab] as? UITabBarItem else { return }
            if let tabBadge = tabItem.badgeValue?.toInt() {
                badge += tabBadge
            }
        }
        UIApplication.shared.applicationIconBadgeNumber = badge
        if let uid = Auth.auth().currentUser?.uid {
            let ref = Database.database().reference().child("users").child(uid)
            ref.updateChildValues(["badge": badge])
        }
    }
    
    fileprivate func managePresense() {
        if currentReachabilityStatus == .notReachable {
            navigationItemActivityIndicator.showActivityIndicator(for: navigationItem, with: .connecting,
                                                                  activityPriority: .high,
                                                                  color: ThemeManager.currentTheme().generalTitleColor)
        }
        
        let connectedReference = Database.database().reference(withPath: ".info/connected")
        connectedReference.observe(.value, with: { (snapshot) in
            
            if self.currentReachabilityStatus != .notReachable {
                self.navigationItemActivityIndicator.hideActivityIndicator(for: self.navigationItem, activityPriority: .crazy)
            } else {
                self.navigationItemActivityIndicator.showActivityIndicator(for: self.navigationItem, with: .noInternet, activityPriority: .crazy, color: ThemeManager.currentTheme().generalTitleColor)
            }
        })
    }
    
    func scrollToFirstActivityWithDate(_ completion: @escaping ([Activity]) -> Void) {
        let allActivities = networkController.activityService.activities
        var activities = [Activity]()
        let currentDate = Date().stripTime()
        var index = 0
        var activityFound = false
        if allActivities.count < 2 {
            completion(allActivities)
            return
        }
        for activity in allActivities {
            if let startInterval = activity.startDateTime?.doubleValue, let endInterval = activity.endDateTime?.doubleValue {
                let startDate = Date(timeIntervalSince1970: startInterval)
                let endDate = Date(timeIntervalSince1970: endInterval)
                if currentDate < startDate || currentDate < endDate {
                    activityFound = true
                    break
                }
                index += 1
                
            }
        }
                                
        if activityFound {
            let numberOfActivities = networkController.activityService.activities.count
            if index < numberOfActivities {
                activities.append(allActivities[index])
                for i in 0...1 {
                    activities.append(allActivities[index + i + 1])
                }
                completion(activities)
            }
        } else {
            let numberOfRows = networkController.activityService.activities.count
            activities.append(allActivities[numberOfRows - 3])
            activities.append(allActivities[numberOfRows - 2])
            activities.append(allActivities[numberOfRows - 1])
            completion(activities)
        }
    }
    
    func grabFinancialItems(_ completion: @escaping ([SectionType], [SectionType: [AnyHashable]]) -> Void) {
        guard currentReachabilityStatus != .notReachable else {
            return
        }
        var accountLevel: AccountCatLevel!
        var transactionLevel: TransactionCatLevel!
        accountLevel = .bs_type
        transactionLevel = .group
        
        let setSections: [SectionType] = [.financialIssues, .balanceSheet, .incomeStatement]
        
        let members = networkController.financeService.members
        let accounts = networkController.financeService.accounts
        let transactions = networkController.financeService.transactions
                
        var sections: [SectionType] = []
        var groups = [SectionType: [AnyHashable]]()
                        
        let dispatchGroup = DispatchGroup()
        
        for section in setSections {
            dispatchGroup.enter()
            if section.type == "Issues" {
                dispatchGroup.enter()
                if !members.isEmpty {
                    sections.append(.financialIssues)
                    groups[section] = members
                    dispatchGroup.leave()
                } else {
                    dispatchGroup.leave()
                }
            } else if section.type == "Accounts" {
                if section.subType == "Balance Sheet" {
                    dispatchGroup.enter()
                    categorizeAccounts(accounts: accounts, level: accountLevel) { (accountsList, _) in
                        if !accountsList.isEmpty {
                            sections.append(.balanceSheet)
                            groups[section] = accountsList
                        }
                        dispatchGroup.leave()
                    }
                }
            } else if section.type == "Transactions" {
                if section.subType == "Income Statement" {
                    dispatchGroup.enter()
                    categorizeTransactions(transactions: transactions, start: Date().startOfMonth, end: Date().endOfMonth, level: transactionLevel) { (transactionsList, _) in
                        if !transactionsList.isEmpty {
                            sections.append(.incomeStatement)
                            groups[section] = transactionsList
                        }
                        dispatchGroup.leave()
                    }
                }
            }
            dispatchGroup.leave()
        }
        
        completion(sections, groups)
    }
    
    func goToVC(section: SectionType) {
        if section == .calendar {
            let destination = ActivityViewController(networkController: networkController)
            destination.hidesBottomBarWhenPushed = true
            navigationController?.pushViewController(destination, animated: true)
        } else if section == .health {
            let destination = HealthViewController(networkController: networkController)
            destination.hidesBottomBarWhenPushed = true
            navigationController?.pushViewController(destination, animated: true)
        } else {
            let destination = FinanceViewController(networkController: networkController)
            destination.hidesBottomBarWhenPushed = true
            navigationController?.pushViewController(destination, animated: true)
        }
    }
}

extension MasterActivityContainerController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return sections.count
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let section = sections[indexPath.section]
        if section == .calendar {
            if !sortedActivities.isEmpty {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: activitiesControllerCell, for: indexPath) as! ActivitiesControllerCell
                cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                cell.activities = sortedActivities
                cell.invitations = networkController.activityService.invitations
                cell.delegate = self
                return cell
            } else {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: setupCell, for: indexPath) as! SetupCell
                cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                cell.intColor = (indexPath.section % 5)
                cell.sectionType = section
                return cell
            }
        } else if section == .health {
            let healthMetricSections = networkController.healthService.healthMetricSections
            let healthMetrics = networkController.healthService.healthMetrics
            if !healthMetrics.isEmpty {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: healthControllerCell, for: indexPath) as! HealthControllerCell
                cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                cell.healthMetricSections = healthMetricSections
                cell.healthMetrics = healthMetrics
                cell.delegate = self
                return cell
            } else {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: setupCell, for: indexPath) as! SetupCell
                cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                cell.intColor = (indexPath.section % 5)
                cell.sectionType = section
                return cell
            }
        } else {
            if !financeSections.isEmpty {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: financeControllerCell, for: indexPath) as! FinanceControllerCell
                cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                cell.institutionDict = networkController.financeService.institutionDict
                cell.sections = financeSections
                cell.groups = financeGroups
                cell.delegate = self
                return cell
            } else {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: setupCell, for: indexPath) as! SetupCell
                cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                cell.intColor = (indexPath.section % 5)
                cell.sectionType = section
                return cell
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        var height: CGFloat = 0
        let section = sections[indexPath.section]
        if section == .calendar {
            if !sortedActivities.isEmpty {
                for activity in sortedActivities {
                    if let activityID = activity.activityID, let _ = self.networkController.activityService.invitations[activityID] {
                        height = CGFloat(sortedActivities.count * 172)
                    } else {
                        height = CGFloat(sortedActivities.count * 132)
                    }
                }
            } else {
                height = 300
            }
        } else if section == .health {
            let healthMetricSections = networkController.healthService.healthMetricSections
            let healthMetrics = networkController.healthService.healthMetrics
            if !healthMetrics.isEmpty {
                height += CGFloat(healthMetricSections.count * 50)
                for key in healthMetricSections {
                    if let metrics = healthMetrics[key] {
                        height += CGFloat(metrics.count * 75)
                    }
                }
                height += 25
            } else {
                height = 300
            }
        } else {
            if !financeSections.isEmpty {
                height += CGFloat(financeSections.count * 60)
                for section in financeSections {
                    if section == .financialIssues {
                        if let group = financeGroups[section] as? [MXMember] {
                            height += CGFloat(group.count * 80)
                        }
                    } else {
                        if let group = financeGroups[section] as? [AccountDetails] {
                            height += CGFloat(group.count * 25)
                        } else if let group = financeGroups[section] as? [TransactionDetails] {
                            height += CGFloat(group.count * 25)
                        }
                    }
                }
                height += 20
            } else {
                height = 300
            }
        }
        return CGSize(width: self.collectionView.frame.size.width - 40, height: height)
        
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return .init(top: 15, left: 0, bottom: 15, right: 0)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: view.frame.width, height: 30)
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionView.elementKindSectionHeader {
            let sectionHeader = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: headerContainerCell, for: indexPath) as! HeaderContainerCell
            let section = sections[indexPath.section]
            sectionHeader.titleLabel.text = section.name
            sectionHeader.sectionType = section
            if section == .calendar {
                if !sortedActivities.isEmpty {
                    sectionHeader.subTitleLabel.isHidden = false
                    sectionHeader.delegate = self
                } else {
                    sectionHeader.subTitleLabel.isHidden = true
                    sectionHeader.delegate = nil
                }
            } else if section == .health {
                let healthMetrics = networkController.healthService.healthMetrics
                if !healthMetrics.isEmpty {
                    sectionHeader.subTitleLabel.isHidden = false
                    sectionHeader.delegate = self
                } else {
                    sectionHeader.subTitleLabel.isHidden = true
                    sectionHeader.delegate = nil
                }
            } else {
                if !financeSections.isEmpty {
                    sectionHeader.subTitleLabel.isHidden = false
                    sectionHeader.delegate = self
                } else {
                    sectionHeader.subTitleLabel.isHidden = true
                    sectionHeader.delegate = nil
                }
            }
            return sectionHeader
        } else { //No footer in this case but can add option for that
            return UICollectionReusableView()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let section = sections[indexPath.section]
        if let _ = collectionView.cellForItem(at: indexPath) as? SetupCell {
            
        } else {
            goToVC(section: section)
        }
    }
}

extension MasterActivityContainerController {
    @objc func goToNotifications() {
        let destination = NotificationsViewController()
        destination.notificationActivities = networkController.activityService.activities
        destination.invitedActivities = self.networkController.activityService.invitedActivities
        destination.invitations = self.networkController.activityService.invitations
        destination.users = networkController.userService.users
        destination.filteredUsers = networkController.userService.users
        destination.conversations = networkController.conversationService.conversations
        destination.listList = networkController.listService.listList
        destination.sortInvitedActivities()
        let navigationViewController = UINavigationController(rootViewController: destination)
        self.present(navigationViewController, animated: true, completion: nil)
    }
    
    @objc fileprivate func newItem() {
        tabBarController?.selectedIndex = 0
    }
}

extension MasterActivityContainerController: HeaderContainerCellDelegate {
    func viewTapped(sectionType: SectionType) {
        goToVC(section: sectionType)
    }
}

extension MasterActivityContainerController: ActivitiesControllerCellDelegate {
    func cellTapped(activity: Activity) {
        loadActivity(activity: activity)
    }
    
    func openMap(forActivity activity: Activity) {
        openVCMap(forActivity: activity)
    }
    
    func openChat(forConversation conversationID: String?, activityID: String?) {
        openVCChat(forConversation: conversationID, activityID: activityID)
    }
    
    func updateInvitation(invitation: Invitation) {
        InvitationsFetcher.update(invitation: invitation) { result in
            if result {
                self.networkController.activityService.invitations[invitation.activityID] = invitation
                self.activitiesUpdated()
            }
        }
    }
}

extension MasterActivityContainerController: HealthControllerCellDelegate {
    func cellTapped(metric: HealthMetric) {
        let healthDetailViewModel = HealthDetailViewModel(healthMetric: metric, healthDetailService: HealthDetailService())
        let healthDetailViewController = HealthDetailViewController(viewModel: healthDetailViewModel)
        navigationController?.pushViewController(healthDetailViewController, animated: true)
    }
}

extension MasterActivityContainerController: FinanceControllerCellDelegate {
    func openTransactionDetails(transactionDetails: TransactionDetails) {
        let financeDetailViewModel = FinanceDetailViewModel(accountDetails: nil, accounts: nil, transactionDetails: transactionDetails, transactions: networkController.financeService.transactions, financeDetailService: FinanceDetailService())
        let financeDetailViewController = FinanceBarChartViewController(viewModel: financeDetailViewModel)
        financeDetailViewController.delegate = self
        financeDetailViewController.users = networkController.userService.users
        financeDetailViewController.filteredUsers = networkController.userService.users
        financeDetailViewController.hidesBottomBarWhenPushed = true
        self.navigationController?.pushViewController(financeDetailViewController, animated: true)
    }
    
    func openAccountDetails(accountDetails: AccountDetails) {
        let financeDetailViewModel = FinanceDetailViewModel(accountDetails: accountDetails, accounts: networkController.financeService.accounts, transactionDetails: nil, transactions: nil, financeDetailService: FinanceDetailService())
        let financeDetailViewController = FinanceLineChartDetailViewController(viewModel: financeDetailViewModel)
        financeDetailViewController.delegate = self
        financeDetailViewController.users = networkController.userService.users
        financeDetailViewController.filteredUsers = networkController.userService.users
        financeDetailViewController.hidesBottomBarWhenPushed = true
        self.navigationController?.pushViewController(financeDetailViewController, animated: true)
    }
    
    func openMember(member: MXMember) {
        openMXConnect(guid: networkController.financeService.mxUser.guid, current_member_guid: member.guid)
    }
    
    func openMXConnect(guid: String, current_member_guid: String?) {
        Service.shared.getMXConnectURL(guid: guid, current_member_guid: current_member_guid ?? nil) { (search, err) in
            if let url = search?.user?.connect_widget_url {
                DispatchQueue.main.async {
                    let destination = WebViewController()
                    destination.urlString = url
                    destination.controllerTitle = ""
                    destination.delegate = self
                    let navigationViewController = UINavigationController(rootViewController: destination)
                    navigationViewController.modalPresentationStyle = .fullScreen
                    self.present(navigationViewController, animated: true, completion: nil)
                }
            }
        }
    }
    
}

extension MasterActivityContainerController: UpdateFinancialsDelegate {
    func updateTransactions(transactions: [Transaction]) {
        for transaction in transactions {
            if let index = networkController.financeService.transactions.firstIndex(of: transaction) {
                networkController.financeService.transactions[index] = transaction
            }
        }
        financeUpdated()
    }
    func updateAccounts(accounts: [MXAccount]) {
        for account in accounts {
            if let index = networkController.financeService.accounts.firstIndex(of: account) {
                networkController.financeService.accounts[index] = account
            }
        }
        financeUpdated()
    }
}

extension MasterActivityContainerController: EndedWebViewDelegate {
    func updateMXMembers() {
        financeSections.removeAll(where: { $0 == .financialIssues })
        financeGroups[.financialIssues] = nil
        collectionView.reloadData()
        networkController.financeService.getMXData()
    }
}

extension MasterActivityContainerController {
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
    
    func loadActivity(activity: Activity) {
        let dispatchGroup = DispatchGroup()
        showActivityIndicator()
        
        if let recipeString = activity.recipeID, let recipeID = Int(recipeString) {
            dispatchGroup.enter()
            Service.shared.fetchRecipesInfo(id: recipeID) { (search, err) in
                if let detailedRecipe = search {
                    dispatchGroup.leave()
                    dispatchGroup.notify(queue: .main) {
                        let destination = RecipeDetailViewController()
                        destination.hidesBottomBarWhenPushed = true
                        destination.recipe = detailedRecipe
                        destination.detailedRecipe = detailedRecipe
                        destination.activity = activity
                        destination.invitation = self.networkController.activityService.invitations[activity.activityID!]
                        destination.users = self.networkController.userService.users
                        destination.filteredUsers = self.networkController.userService.users
                        destination.activities = self.networkController.activityService.activities
                        destination.conversations = self.networkController.conversationService.conversations
                        self.getParticipants(forActivity: activity) { (participants) in
                            InvitationsFetcher.getAcceptedParticipant(forActivity: activity, allParticipants: participants) { acceptedParticipant in
                                destination.acceptedParticipant = acceptedParticipant
                                destination.selectedFalconUsers = participants
                                self.hideActivityIndicator()
                                self.navigationController?.pushViewController(destination, animated: true)
                            }
                        }
                    }
                } else {
                    dispatchGroup.leave()
                    dispatchGroup.notify(queue: .main) {
                        self.hideActivityIndicator()
                        self.activityNotFoundAlert()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: {
                            self.dismiss(animated: true, completion: nil)
                        })
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
                        destination.invitation = self.networkController.activityService.invitations[activity.activityID!]
                        destination.users = self.networkController.userService.users
                        destination.filteredUsers = self.networkController.userService.users
                        destination.activities = self.networkController.activityService.activities
                        destination.conversations = self.networkController.conversationService.conversations
                        self.getParticipants(forActivity: activity) { (participants) in
                            InvitationsFetcher.getAcceptedParticipant(forActivity: activity, allParticipants: participants) { acceptedParticipant in
                                destination.acceptedParticipant = acceptedParticipant
                                destination.selectedFalconUsers = participants
                                self.hideActivityIndicator()
                                self.navigationController?.pushViewController(destination, animated: true)
                            }
                        }
                    }
                } else {
                    dispatchGroup.leave()
                    dispatchGroup.notify(queue: .main) {
                        self.hideActivityIndicator()
                        self.activityNotFoundAlert()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: {
                            self.dismiss(animated: true, completion: nil)
                        })
                    }
                }
            }
        } else if let workoutID = activity.workoutID {
            var reference = Database.database().reference()
            dispatchGroup.enter()
            reference = Database.database().reference().child("workouts").child("workouts")
            reference.child(workoutID).observeSingleEvent(of: .value, with: { (snapshot) in
                if snapshot.exists(), let workoutSnapshotValue = snapshot.value {
                    if let workout = try? FirebaseDecoder().decode(PreBuiltWorkout.self, from: workoutSnapshotValue) {
                        dispatchGroup.leave()
                        let destination = WorkoutDetailViewController()
                        destination.hidesBottomBarWhenPushed = true
                        destination.workout = workout
                        destination.intColor = 0
                        destination.activity = activity
                        destination.invitation = self.networkController.activityService.invitations[activity.activityID!]
                        destination.users = self.networkController.userService.users
                        destination.filteredUsers = self.networkController.userService.users
                        destination.activities = self.networkController.activityService.activities
                        destination.conversations = self.networkController.conversationService.conversations
                        self.getParticipants(forActivity: activity) { (participants) in
                            InvitationsFetcher.getAcceptedParticipant(forActivity: activity, allParticipants: participants) { acceptedParticipant in
                                destination.acceptedParticipant = acceptedParticipant
                                destination.selectedFalconUsers = participants
                                self.hideActivityIndicator()
                                self.navigationController?.pushViewController(destination, animated: true)
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
                if let attraction = search?.embedded?.attractions![0] {
                    dispatchGroup.leave()
                    dispatchGroup.notify(queue: .main) {
                        let destination = EventDetailViewController()
                        destination.hidesBottomBarWhenPushed = true
                        destination.attraction = attraction
                        destination.activity = activity
                        destination.invitation = self.networkController.activityService.invitations[activity.activityID!]
                        destination.users = self.networkController.userService.users
                        destination.filteredUsers = self.networkController.userService.users
                        destination.activities = self.networkController.activityService.activities
                        destination.conversations = self.networkController.conversationService.conversations
                        self.getParticipants(forActivity: activity) { (participants) in
                            InvitationsFetcher.getAcceptedParticipant(forActivity: activity, allParticipants: participants) { acceptedParticipant in
                                destination.acceptedParticipant = acceptedParticipant
                                destination.selectedFalconUsers = participants
                                self.hideActivityIndicator()
                                self.navigationController?.pushViewController(destination, animated: true)
                            }
                        }
                    }
                } else {
                    dispatchGroup.leave()
                    dispatchGroup.notify(queue: .main) {
                        self.hideActivityIndicator()
                        self.activityNotFoundAlert()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: {
                            self.dismiss(animated: true, completion: nil)
                        })
                    }
                }
            }
        } else if let placeID = activity.placeID {
            dispatchGroup.enter()
            Service.shared.fetchFSDetails(id: placeID) { (search, err) in
                if let place = search?.response?.venue {
                    dispatchGroup.leave()
                    dispatchGroup.notify(queue: .main) {
                        let destination = PlaceDetailViewController()
                        destination.hidesBottomBarWhenPushed = true
                        destination.place = place
                        destination.activity = activity
                        destination.invitation = self.networkController.activityService.invitations[activity.activityID!]
                        destination.users = self.networkController.userService.users
                        destination.filteredUsers = self.networkController.userService.users
                        destination.activities = self.networkController.activityService.activities
                        destination.conversations = self.networkController.conversationService.conversations
                        self.getParticipants(forActivity: activity) { (participants) in
                            InvitationsFetcher.getAcceptedParticipant(forActivity: activity, allParticipants: participants) { acceptedParticipant in
                                destination.acceptedParticipant = acceptedParticipant
                                destination.selectedFalconUsers = participants
                                self.hideActivityIndicator()
                                self.navigationController?.pushViewController(destination, animated: true)
                            }
                        }
                    }
                } else {
                    dispatchGroup.leave()
                    dispatchGroup.notify(queue: .main) {
                        self.hideActivityIndicator()
                        self.activityNotFoundAlert()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: {
                            self.dismiss(animated: true, completion: nil)
                        })
                    }
                }
            }
        } else {
            self.hideActivityIndicator()
            let destination = CreateActivityViewController()
            destination.hidesBottomBarWhenPushed = true
            destination.activity = activity
            destination.invitation = self.networkController.activityService.invitations[activity.activityID ?? ""]
            destination.users = networkController.userService.users
            destination.filteredUsers = networkController.userService.users
            destination.activities = self.networkController.activityService.activities
            destination.conversations = networkController.conversationService.conversations
            self.getParticipants(forActivity: activity) { (participants) in
                InvitationsFetcher.getAcceptedParticipant(forActivity: activity, allParticipants: participants) { acceptedParticipant in
                    destination.acceptedParticipant = acceptedParticipant
                    destination.selectedFalconUsers = participants
                    self.navigationController?.pushViewController(destination, animated: true)
                }
            }
        }
    }
    
    func openVCMap(forActivity activity: Activity) {
        guard currentReachabilityStatus != .notReachable else {
            basicErrorAlertWith(title: basicErrorTitleForAlert, message: noInternetError, controller: self)
            return
        }
        
        guard activity.locationAddress != nil else {
            return
        }
        
        var locations = [activity]
        
        if activity.schedule != nil {
            var scheduleList = [Activity]()
            var locationAddress = [String : [Double]]()
            locationAddress = activity.locationAddress!
            for schedule in activity.schedule! {
                if schedule.name == "nothing" { continue }
                scheduleList.append(schedule)
                guard let localAddress = schedule.locationAddress else { continue }
                for (key, value) in localAddress {
                    locationAddress[key] = value
                }
            }
            locations.append(contentsOf: scheduleList)
        }
        
        let destination = MapViewController()
        destination.hidesBottomBarWhenPushed = true
        destination.sections = [.activity]
        destination.locations = [.activity: locations]
        navigationController?.pushViewController(destination, animated: true)
    
    }
    
    func openVCChat(forConversation conversationID: String?, activityID: String?) {
        if conversationID == nil {
            let activity = networkController.activityService.activities.first(where: {$0.activityID == activityID})
            let destination = ChooseChatTableViewController()
            let navController = UINavigationController(rootViewController: destination)
            destination.delegate = self
            destination.activity = activity
            destination.conversations = networkController.conversationService.conversations
            destination.pinnedConversations = networkController.conversationService.conversations
            destination.filteredConversations = networkController.conversationService.conversations
            destination.filteredPinnedConversations = networkController.conversationService.conversations
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
                    if let activityID = activityID, let participants = self.activitiesParticipants[activityID], participants.count > 0 {
                        let user = participants[0]
                        conversation.chatName = user.name
                        conversation.chatPhotoURL = user.photoURL
                        conversation.chatThumbnailPhotoURL = user.thumbnailPhotoURL
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

extension MasterActivityContainerController: MessagesDelegate {
    
    func messages(shouldChangeMessageStatusToReadAt reference: DatabaseReference) {
        chatLogController?.updateMessageStatus(messageRef: reference)
    }
    
    func messages(shouldBeUpdatedTo messages: [Message], conversation: Conversation) {
        
        chatLogController?.hidesBottomBarWhenPushed = true
        chatLogController?.messagesFetcher = messagesFetcher
        chatLogController?.messages = messages
        chatLogController?.conversation = conversation
        chatLogController?.deleteAndExitDelegate = self
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

extension MasterActivityContainerController: ChooseChatDelegate {
    func chosenChat(chatID: String, activityID: String?, grocerylistID: String?, checklistID: String?, packinglistID: String?, activitylistID: String?) {
        if let activityID = activityID {
            let updatedConversationID = ["conversationID": chatID as AnyObject]
            Database.database().reference().child("activities").child(activityID).child(messageMetaDataFirebaseFolder).updateChildValues(updatedConversationID)

            if let conversation = networkController.conversationService.conversations.first(where: {$0.chatID == chatID}) {
                if conversation.activities != nil {
                    var activities = conversation.activities!
                    activities.append(activityID)
                    let updatedActivities = ["activities": activities as AnyObject]
                    Database.database().reference().child("groupChats").child(conversation.chatID!).child(messageMetaDataFirebaseFolder).updateChildValues(updatedActivities)
                } else {
                    let updatedActivities = ["activities": [activityID] as AnyObject]
                    Database.database().reference().child("groupChats").child(conversation.chatID!).child(messageMetaDataFirebaseFolder).updateChildValues(updatedActivities)
                }
                if let index = networkController.activityService.activities.firstIndex(where: {$0.activityID == activityID}) {
                    let activity = networkController.activityService.activities[index]
                    if activity.grocerylistID != nil {
                        if conversation.grocerylists != nil {
                            var grocerylists = conversation.grocerylists!
                            grocerylists.append(activity.grocerylistID!)
                            let updatedGrocerylists = [grocerylistsEntity: grocerylists as AnyObject]
                            Database.database().reference().child("groupChats").child(conversation.chatID!).child(messageMetaDataFirebaseFolder).updateChildValues(updatedGrocerylists)
                        } else {
                            let updatedGrocerylists = [grocerylistsEntity: [activity.grocerylistID!] as AnyObject]
                            Database.database().reference().child("groupChats").child(conversation.chatID!).child(messageMetaDataFirebaseFolder).updateChildValues(updatedGrocerylists)
                        }
                        Database.database().reference().child(grocerylistsEntity).child(activity.grocerylistID!).updateChildValues(updatedConversationID)
                    }
                    if activity.checklistIDs != nil {
                        if conversation.checklists != nil {
                            let checklists = conversation.checklists! + activity.checklistIDs!
                            let updatedChecklists = [checklistsEntity: checklists as AnyObject]
                            Database.database().reference().child("groupChats").child(conversation.chatID!).child(messageMetaDataFirebaseFolder).updateChildValues(updatedChecklists)
                        } else {
                            let updatedChecklists = [checklistsEntity: activity.checklistIDs! as AnyObject]
                            Database.database().reference().child("groupChats").child(conversation.chatID!).child(messageMetaDataFirebaseFolder).updateChildValues(updatedChecklists)
                        }
                        for ID in activity.checklistIDs! {
                            Database.database().reference().child(checklistsEntity).child(ID).updateChildValues(updatedConversationID)

                        }
                    }
                    if activity.packinglistIDs != nil {
                        if conversation.packinglists != nil {
                            let packinglists = conversation.packinglists! + activity.packinglistIDs!
                            let updatedPackinglists = [packinglistsEntity: packinglists as AnyObject]
                            Database.database().reference().child("groupChats").child(conversation.chatID!).child(messageMetaDataFirebaseFolder).updateChildValues(updatedPackinglists)
                        } else {
                            let updatedPackinglists = [packinglistsEntity: activity.packinglistIDs! as AnyObject]
                            Database.database().reference().child("groupChats").child(conversation.chatID!).child(messageMetaDataFirebaseFolder).updateChildValues(updatedPackinglists)
                        }
                       for ID in activity.packinglistIDs! {
                            Database.database().reference().child(packinglistsEntity).child(ID).updateChildValues(updatedConversationID)

                        }
                    }
                }
            }
            self.connectedToChatAlert()
            self.dismiss(animated: true, completion: nil)
        }
    }
}

extension MasterActivityContainerController: DeleteAndExitDelegate {
    
    func deleteAndExit(from otherActivityID: String) {
        
//        let pinnedIDs = pinnedActivities.map({$0.activityID ?? ""})
//        let section = pinnedIDs.contains(otherActivityID) ? 0 : 1
//        guard let row = activityIndex(for: otherActivityID, at: section) else { return }
//
//        let indexPath = IndexPath(row: row, section: section)
//        section == 0 ? deletePinnedActivity(at: indexPath) : deleteUnPinnedActivity(at: indexPath)
    }
    
    func activityIndex(for otherActivityID: String, at section: Int) -> Int? {
//        let activitiesArray = section == 0 ? filteredPinnedActivities : filteredActivities
//        guard let index = activitiesArray.firstIndex(where: { (activity) -> Bool in
//            guard let activityID = activity.activityID else { return false }
//            return activityID == otherActivityID
//        }) else { return nil }
//        return index
        return nil
    }
}

