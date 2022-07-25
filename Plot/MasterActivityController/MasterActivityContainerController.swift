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
import HealthKit
import GoogleSignIn

let activitiesControllerCell = "ActivitiesControllerCell"
let healthControllerCell = "HealthControllerCell"
let financeControllerCell = "FinanceControllerCell"
let setupCell = "SetupCell"
let headerContainerCell = "HeaderCellDelegate"


enum Mode {
    case small, fullscreen
}

protocol ManageAppearanceHome: AnyObject {
    func manageAppearanceHome(_ homeController: MasterActivityContainerController, didFinishLoadingWith state: Bool )
}

class MasterActivityContainerController: UIViewController, ActivityDetailShowing {
    
    var networkController = NetworkController() {
        didSet {
            print("didSet")
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
    
    var updatingActivities = true
    var updatingHealth = true
    var updatingFinances = true
    
    var healthMetricSections: [String] {
        var healthMetricSections = Array(healthMetrics.keys)
        healthMetricSections.sort(by: { (v1, v2) -> Bool in
            if let cat1 = HealthMetricCategory(rawValue: v1), let cat2 = HealthMetricCategory(rawValue: v2) {
                return cat1.rank < cat2.rank
            }
            return false
        })
        return healthMetricSections
    }
    var healthMetrics: [String: [HealthMetric]] {
        var metrics = networkController.healthService.healthMetrics
        if let generalMetrics = metrics[HealthMetricCategory.general.rawValue] {
            metrics[HealthMetricCategory.general.rawValue] = generalMetrics.filter({ $0.type.name == HealthMetricType.steps.name || $0.type.name == HealthMetricType.sleep.name || $0.type.name == HealthMetricType.heartRate.name })
            if metrics[HealthMetricCategory.general.rawValue] == [] {
                metrics[HealthMetricCategory.general.rawValue] = nil
            }
        }
        if let workoutMetrics = metrics[HealthMetricCategory.workouts.rawValue] {
            metrics[HealthMetricCategory.general.rawValue]?.append(contentsOf: workoutMetrics.filter({ $0.type.name == HealthMetricType.activeEnergy.name}))
            metrics[HealthMetricCategory.workouts.rawValue] = nil
        }
        if let nutritionMetrics = metrics[HealthMetricCategory.nutrition.rawValue] {
            metrics[HealthMetricCategory.general.rawValue]?.append(contentsOf: nutritionMetrics.filter({ $0.type.name == HKQuantityTypeIdentifier.dietaryEnergyConsumed.name}))
            metrics[HealthMetricCategory.nutrition.rawValue] = nil
        }
        return metrics
    }
    var financeSections = [SectionType]()
    var financeGroups = [SectionType: [AnyHashable]]()
    var transactionsDictionary = [TransactionDetails: [Transaction]]()
    var accountsDictionary = [AccountDetails: [MXAccount]]()
    
    var chatLogController: ChatLogController? = nil
    var messagesFetcher: MessagesFetcher? = nil
    
    var activitiesParticipants: [String: [User]] = [:]
    
    var isNewUser: Bool = true
    
    var onceToken = 0
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    var isAppLoaded = false
        
    var window: UIWindow?
    
    let splashContainer: SplashScreenContainer = {
        let splashContainer = SplashScreenContainer()
        splashContainer.translatesAutoresizingMaskIntoConstraints = false
        return splashContainer
    }()
    
    let launchScreenView: UIView = {
        let launchScreenView = UIView()
        launchScreenView.translatesAutoresizingMaskIntoConstraints = false
        return launchScreenView
    }()
    
    let plotLogoView: UIImageView = {
        let plotLogoView = UIImageView()
        plotLogoView.translatesAutoresizingMaskIntoConstraints = false
        plotLogoView.layer.masksToBounds = true
        plotLogoView.image = UIImage(named: "plotLogo")
        return plotLogoView
    }()
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return ThemeManager.currentTheme().statusBarStyle
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if self.traitCollection.userInterfaceStyle == .dark {
            let theme = Theme.Dark
            ThemeManager.applyTheme(theme: theme)
        } else {
            let theme = Theme.Default
            ThemeManager.applyTheme(theme: theme)
        }
        
        appDelegate.loadNotifications()
        showLaunchScreen()
        setOnlineStatus()
        loadVariables()
        setupViews()
        setNavBar()
        addObservers()
        manageAppearanceHome(didFinishLoadingWith: true)
        setApplicationBadge()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if onceToken == 0 {
            splashContainer.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
            view.addSubview(splashContainer)
            splashContainer.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
            splashContainer.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
            splashContainer.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
            splashContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        }
        onceToken = 1
        managePresense()
        
        //for when a new user signs on and onboarding screen is dismissed
        if isNewUser {
            collectionView.reloadData()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if isNewUser {
            isNewUser = false
            self.networkController.userService.grabContacts()
        }
    }

    func setupViews() {
        navigationController?.navigationBar.backgroundColor = ThemeManager.currentTheme().barBackgroundColor
        navigationController?.navigationBar.layoutIfNeeded()
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationController?.navigationItem.largeTitleDisplayMode = .always

        view.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
        collectionView.indicatorStyle = ThemeManager.currentTheme().scrollBarStyle
        collectionView.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
        
        extendedLayoutIncludesOpaqueBars = true
        definesPresentationContext = true
        
        layout.scrollDirection = UICollectionView.ScrollDirection.vertical
        collectionView.setCollectionViewLayout(layout, animated: true)
        collectionView.dataSource = self
        collectionView.delegate = self
        
        view.addSubview(collectionView)
        collectionView.fillSuperviewSafeAreaLayoutGuide()
        collectionView.anchor(top: view.safeAreaLayoutGuide.topAnchor, leading: view.leadingAnchor, bottom: view.bottomAnchor, trailing: view.trailingAnchor, padding: .init(top: 0, left: 0, bottom: 0, right: 0))
        
        collectionView.register(ActivitiesControllerCell.self, forCellWithReuseIdentifier: activitiesControllerCell)
        collectionView.register(HealthControllerCell.self, forCellWithReuseIdentifier: healthControllerCell)
        collectionView.register(FinanceControllerCell.self, forCellWithReuseIdentifier: financeControllerCell)
        collectionView.register(SetupCell.self, forCellWithReuseIdentifier: setupCell)
        collectionView.register(HeaderContainerCell.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: headerContainerCell)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    fileprivate func addObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(changeTheme), name: .themeUpdated, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(activitiesUpdated), name: .activitiesUpdated, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(invitationsUpdated), name: .invitationsUpdated, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(healthUpdated), name: .healthUpdated, object: nil)
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

        collectionView.indicatorStyle = ThemeManager.currentTheme().scrollBarStyle
        collectionView.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
        collectionView.reloadData()
        
    }
    
    @objc fileprivate func activitiesUpdated() {
        self.updatingActivities = false
        scrollToFirstActivityWithDate({ (activities) in
            if self.sortedActivities != activities {
                self.sortedActivities = activities
                DispatchQueue.main.async {
                    self.collectionView.reloadData()
                }
            }
        })
    }
    
    @objc fileprivate func invitationsUpdated() {
        DispatchQueue.main.async {
            self.collectionView.reloadData()
        }
    }
    
    @objc fileprivate func healthUpdated() {
        self.updatingHealth = false
        DispatchQueue.main.async {
            self.collectionView.reloadData()
        }
    }
    
    @objc fileprivate func financeUpdated() {
        self.grabFinancialItems { (sections, groups) in
            self.updatingFinances = false
            if self.financeSections != sections || self.financeGroups != groups {
                self.financeSections = sections
                self.financeGroups = groups
                DispatchQueue.main.async {
                    self.collectionView.reloadData()
                }
            }
        }
    }
    
    func setNavBar() {
        navigationItem.title = {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "EEEE, MMM d"
            return dateFormatter.string(from: Date())
        }()
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "settings"),
                                                           style: .plain,
                                                           target: self,
                                                           action: #selector(goToSettings))
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add,
                                                            target: self,
                                                            action: #selector(newItem))
    }
    
    func setApplicationBadge() {
        let badge = 0
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
        let totalNumberOfActivities = allActivities.count
        let numberOfActivities = 4
        if totalNumberOfActivities < numberOfActivities {
            completion(allActivities)
            return
        }
        var index = 0
        var activities = [Activity]()
        let currentDate = Date().localTime
        var calendar = Calendar.current
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        for activity in allActivities {
            if let endDate = activity.endDateWTZ {
                if (currentDate < endDate) || (activity.allDay ?? false && calendar.compare(currentDate, to: endDate, toGranularity: .day) != .orderedDescending) {
                    if index < totalNumberOfActivities - (numberOfActivities - 1) {
                        if activities.count < numberOfActivities {
                            activities.append(allActivities[index])
                        } else {
                            completion(activities)
                            return
                        }
                    } else {
                        break
                    }
                }
                index += 1
            }
        }
        
        activities = []
        for i in 1...numberOfActivities {
            activities.insert(allActivities[totalNumberOfActivities - i], at: 0)
        }
        completion(activities)
    }
    
    func grabFinancialItems(_ completion: @escaping ([SectionType], [SectionType: [AnyHashable]]) -> Void) {
        var accountLevel: AccountCatLevel!
        var transactionLevel: TransactionCatLevel!
        accountLevel = .bs_type
        transactionLevel = .group
        
        let setSections: [SectionType] = [.financialIssues, .incomeStatement, .balanceSheet, .investments]
        
        let members = networkController.financeService.members
        let accounts = networkController.financeService.accounts
        let transactions = networkController.financeService.transactions
        let holdings = networkController.financeService.holdings
                
        var sections: [SectionType] = []
        var groups = [SectionType: [AnyHashable]]()
                                
        for section in setSections {
            if section.type == "Issues" {
                var challengedMembers = [MXMember]()
                for member in members {
                    if member.connection_status != .connected && member.connection_status != .created && member.connection_status != .updated && member.connection_status != .delayed && member.connection_status != .resumed && member.connection_status != .pending {
                        challengedMembers.append(member)
                    }
                }
                if !challengedMembers.isEmpty {
                    sections.append(section)
                    groups[section] = challengedMembers
                }
            } else if section.type == "Accounts" {
                if section.subType == "Balance Sheet" {
                    categorizeAccounts(accounts: accounts, level: accountLevel) { (accountsList, accountsDict) in
                        if !accountsList.isEmpty {
                            sections.append(section)
                            groups[section] = accountsList
                            self.accountsDictionary = accountsDict
                        }
                    }
                }
            } else if section.type == "Transactions" {
                if section.subType == "Income Statement" {
                    let accounts = transactions.compactMap({ $0.account_guid })
                    categorizeTransactions(transactions: transactions, start: Date().localTime.startOfMonth, end: Date().localTime.endOfMonth, level: transactionLevel, accounts: accounts) { (transactionsList, transactionsDict) in
                        if !transactionsList.isEmpty {
                            sections.append(section)
                            groups[section] = transactionsList
                            self.transactionsDictionary = transactionsDict
                        }
                    }
                }
            } else if section.type == "Investments" {
                let filteredHoldings = holdings.filter({$0.should_link ?? true})
                if !filteredHoldings.isEmpty {
                    sections.append(section)
                    groups[section] = filteredHoldings
                }
            }
        }
        completion(sections, groups)
    }
    
    func goToVC(section: SectionType) {
        if section == .calendar, !sortedActivities.isEmpty {
            let destination = ActivityViewController(networkController: networkController)
            destination.hidesBottomBarWhenPushed = true
            navigationController?.pushViewController(destination, animated: true)
        } else if section == .health, !healthMetrics.isEmpty {
            let destination = HealthViewController(networkController: networkController)
            destination.hidesBottomBarWhenPushed = true
            navigationController?.pushViewController(destination, animated: true)
        } else if !financeSections.isEmpty {
            let destination = FinanceViewController(networkController: networkController)
            destination.hidesBottomBarWhenPushed = true
            navigationController?.pushViewController(destination, animated: true)
        }
    }
}

extension MasterActivityContainerController {
    @objc func goToSettings() {
        let destination = AccountSettingsController()
        destination.networkController = networkController
        let navigationViewController = UINavigationController(rootViewController: destination)
        self.present(navigationViewController, animated: true, completion: nil)
    }
    
    @objc func goToNotifications() {
        let destination = NotificationsViewController()
        destination.notificationActivities = networkController.activityService.activities
        destination.invitedActivities = networkController.activityService.invitedActivities
        destination.invitations = networkController.activityService.invitations
        destination.users = networkController.userService.users
        destination.filteredUsers = networkController.userService.users
        destination.conversations = networkController.conversationService.conversations
        destination.listList = networkController.listService.listList
        destination.sortInvitedActivities()
        let navigationViewController = UINavigationController(rootViewController: destination)
        self.present(navigationViewController, animated: true, completion: nil)
    }
    
    @objc func goToChat() {
        let destination = ChatsTableViewController()
        destination.conversations = networkController.conversationService.conversations
        destination.contacts = networkController.userService.contacts
        destination.filteredContacts = networkController.userService.contacts
        destination.users = networkController.userService.users
        destination.filteredUsers = networkController.userService.users
        destination.conversations = networkController.conversationService.conversations
        let navigationViewController = UINavigationController(rootViewController: destination)
        self.present(navigationViewController, animated: true, completion: nil)
    }
    
    @objc fileprivate func newItem() {
        let discoverController = DiscoverViewController()
        discoverController.networkController = networkController
        present(UINavigationController(rootViewController: discoverController), animated: true)
    }
}

extension MasterActivityContainerController: HeaderContainerCellDelegate {
    func viewTapped(sectionType: SectionType) {
        goToVC(section: sectionType)
    }
}

extension MasterActivityContainerController: GIDSignInDelegate {
    func newCalendarItem() {
        if !networkController.activityService.calendars.keys.contains(icloudString) || !networkController.activityService.calendars.keys.contains(googleString) {
            let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            
            alert.addAction(UIAlertAction(title: "Event", style: .default, handler: { (_) in
                let destination = CreateActivityViewController()
                destination.users = self.networkController.userService.users
                destination.filteredUsers = self.networkController.userService.users
                let navigationViewController = UINavigationController(rootViewController: destination)
                self.present(navigationViewController, animated: true, completion: nil)
            }))
            
            alert.addAction(UIAlertAction(title: "Calendar", style: .default, handler: { (_) in
                self.newCalendar()
            }))
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (_) in
                print("User click Dismiss button")
            }))
            
            self.present(alert, animated: true, completion: {
                print("completion block")
            })
        } else {
            let destination = CreateActivityViewController()
            destination.users = self.networkController.userService.users
            destination.filteredUsers = self.networkController.userService.users
            let navigationViewController = UINavigationController(rootViewController: destination)
            self.present(navigationViewController, animated: true, completion: nil)
        }
    }
    
    func newCalendar() {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        if !networkController.activityService.calendars.keys.contains(icloudString) {
            alert.addAction(UIAlertAction(title: icloudString, style: .default, handler: { (_) in
                self.networkController.activityService.updatePrimaryCalendar(value: icloudString)
                self.collectionView.reloadData()
            }))
        }
        
        if !networkController.activityService.calendars.keys.contains(googleString) {
            alert.addAction(UIAlertAction(title: googleString, style: .default, handler: { (_) in
                GIDSignIn.sharedInstance().delegate = self
                GIDSignIn.sharedInstance()?.presentingViewController = self
                GIDSignIn.sharedInstance()?.signIn()
            }))
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (_) in
            print("User click Dismiss button")
        }))
        
        self.present(alert, animated: true, completion: {
            print("completion block")
        })
    }
    
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        if (error == nil) {
            self.networkController.activityService.updatePrimaryCalendar(value: googleString)
            self.collectionView.reloadData()
        } else {
          print("\(error.localizedDescription)")
        }
    }
}

// MARK: - ActivitiesControllerCellDelegate

extension MasterActivityContainerController: ActivitiesControllerCellDelegate {
    
    func cellTapped(activity: Activity) {
        showActivityDetail(activity: activity)
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
                self.invitationsUpdated()
            }
        }
    }
}

extension MasterActivityContainerController: HealthControllerCellDelegate {
    func cellTapped(metric: HealthMetric) {
        let healthDetailViewModel = HealthDetailViewModel(healthMetric: metric, healthDetailService: HealthDetailService())
        let healthDetailViewController = HealthDetailViewController(viewModel: healthDetailViewModel)
        healthDetailViewController.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(healthDetailViewController, animated: true)
    }
}

extension MasterActivityContainerController: FinanceControllerCellDelegate {
    func openTransactionDetails(transactionDetails: TransactionDetails) {
        let accounts = networkController.financeService.transactions.compactMap({ $0.account_guid })
        let financeDetailViewModel = FinanceDetailViewModel(accountDetails: nil, allAccounts: nil, accounts: nil, transactionDetails: transactionDetails, allTransactions: networkController.financeService.transactions, transactions: transactionsDictionary[transactionDetails], filterAccounts: accounts, financeDetailService: FinanceDetailService())
        let financeDetailViewController = FinanceBarChartViewController(viewModel: financeDetailViewModel)
//        financeDetailViewController.delegate = self
        financeDetailViewController.users = networkController.userService.users
        financeDetailViewController.filteredUsers = networkController.userService.users
        financeDetailViewController.hidesBottomBarWhenPushed = true
        self.navigationController?.pushViewController(financeDetailViewController, animated: true)
    }
    
    func openAccountDetails(accountDetails: AccountDetails) {
        let financeDetailViewModel = FinanceDetailViewModel(accountDetails: accountDetails, allAccounts: networkController.financeService.accounts, accounts: accountsDictionary[accountDetails], transactionDetails: nil, allTransactions: nil, transactions: nil, filterAccounts: nil, financeDetailService: FinanceDetailService())
        let financeDetailViewController = FinanceLineChartDetailViewController(viewModel: financeDetailViewModel)
//        financeDetailViewController.delegate = self
        financeDetailViewController.users = networkController.userService.users
        financeDetailViewController.filteredUsers = networkController.userService.users
        financeDetailViewController.hidesBottomBarWhenPushed = true
        self.navigationController?.pushViewController(financeDetailViewController, animated: true)
    }
    
    func openHolding(holding: MXHolding) {
        let destination = FinanceHoldingViewController()
        destination.holding = holding
        destination.users = networkController.userService.users
        destination.filteredUsers = networkController.userService.users
        destination.hidesBottomBarWhenPushed = true
        self.getParticipants(transaction: nil, account: nil, holding: holding) { (participants) in
            destination.selectedFalconUsers = participants
            self.navigationController?.pushViewController(destination, animated: true)
        }
    }
    
    func openMember(member: MXMember) {
        openMXConnect(current_member_guid: member.guid)
    }
    
    func openMXConnect(current_member_guid: String?) {
        let destination = WebViewController()
        destination.current_member_guid = current_member_guid
        destination.controllerTitle = ""
        destination.delegate = self
        let navigationViewController = UINavigationController(rootViewController: destination)
        navigationViewController.modalPresentationStyle = .fullScreen
        self.present(navigationViewController, animated: true, completion: nil)
    }
    
}

//extension MasterActivityContainerController: UpdateFinancialsDelegate {
//    func updateTransactions(transactions: [Transaction]) {
//        for transaction in transactions {
//            if let index = networkController.financeService.transactions.firstIndex(of: transaction) {
//                networkController.financeService.transactions[index] = transaction
//            }
//        }
//    }
//    func updateAccounts(accounts: [MXAccount]) {
//        for account in accounts {
//            if let index = networkController.financeService.accounts.firstIndex(where: {$0.guid == account.guid}) {
//                networkController.financeService.accounts[index] = account
//            }
//        }
//    }
//}

extension MasterActivityContainerController: EndedWebViewDelegate {
    func updateMXMembers() {
        self.financeSections.removeAll(where: { $0 == .financialIssues })
        self.financeGroups[.financialIssues] = nil
        DispatchQueue.main.async {
            self.collectionView.reloadData()
        }
        networkController.financeService.triggerUpdateMXUser()
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
    
    func getParticipants(transaction: Transaction?, account: MXAccount?, holding: MXHolding?, completion: @escaping ([User])->()) {
        if let transaction = transaction, let participantsIDs = transaction.participantsIDs, let currentUserID = Auth.auth().currentUser?.uid {
            let group = DispatchGroup()
            var participants: [User] = []
            for id in participantsIDs {
                if transaction.admin == currentUserID && id == currentUserID {
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
                completion(participants)
            }
        } else if let account = account, let participantsIDs = account.participantsIDs, let currentUserID = Auth.auth().currentUser?.uid {
            let group = DispatchGroup()
            var participants: [User] = []
            
            for id in participantsIDs {
                if account.admin == currentUserID && id == currentUserID {
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
                completion(participants)
            }
        } else if let holding = holding, let participantsIDs = holding.participantsIDs, let currentUserID = Auth.auth().currentUser?.uid {
            let group = DispatchGroup()
            var participants: [User] = []
            
            for id in participantsIDs {
                if holding.admin == currentUserID && id == currentUserID {
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
                completion(participants)
            }
        } else {
            let participants: [User] = []
            completion(participants)
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

