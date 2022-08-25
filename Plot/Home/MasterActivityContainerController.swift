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
    var networkController = NetworkController()

    let collectionView:UICollectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout: UICollectionViewFlowLayout.init())
    let layout:UICollectionViewFlowLayout = UICollectionViewFlowLayout.init()
        
    let navigationItemActivityIndicator = NavigationItemActivityIndicator()
        
    weak var delegate: ManageAppearanceHome?
            
    var sections: [SectionType] = [.time, .health, .finances]
    
    var activitiesSections = [SectionType]()
    var activities = [SectionType: [Activity]]()
    var sortedEvents = [Activity]()
    var sortedTasks = [Activity]()
    
    var updatingTasks = true
    var updatingEvents = true
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
            metrics[HealthMetricCategory.general.rawValue] = generalMetrics.filter({ $0.type.name == HealthMetricType.steps.name || $0.type.name == HealthMetricType.sleep.name || $0.type.name == HealthMetricType.heartRate.name || $0.type.name == HealthMetricType.flightsClimbed.name })
            if metrics[HealthMetricCategory.general.rawValue] == [] {
                metrics[HealthMetricCategory.general.rawValue] = nil
            }
        }
        if let workoutMetrics = metrics[HealthMetricCategory.workouts.rawValue] {
            metrics[HealthMetricCategory.general.rawValue]?.append(contentsOf: workoutMetrics.filter({ $0.type.name == HealthMetricType.activeEnergy.name || $0.type.name == HealthMetricType.workoutMinutes.name}))
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
    
    var participants: [String: [User]] = [:]
    
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
        NotificationCenter.default.addObserver(self, selector: #selector(eventsUpdated), name: .eventsUpdated, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(tasksUpdated), name: .tasksUpdated, object: nil)
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
    
    @objc fileprivate func tasksUpdated() {
        self.updatingTasks = false
        scrollToFirstTask({ (tasks) in
            if self.sortedTasks != tasks {
                self.sortedTasks = tasks
                if !tasks.isEmpty {
                    if self.activitiesSections.firstIndex(of: .tasks) == nil {
                        self.activitiesSections.insert(.tasks, at: 0)
                    }
                    self.activities[.tasks] = tasks
                } else {
                    if let index = self.activitiesSections.firstIndex(of: .tasks) {
                        self.activitiesSections.remove(at: index)
                    }
                    self.activities[.tasks] = nil
                }
                DispatchQueue.main.async {
                    self.collectionView.reloadData()
                }
            }
        })
    }
    
    @objc fileprivate func eventsUpdated() {
        self.updatingEvents = false
        scrollToFirstActivityWithDate({ (events) in
            if self.sortedEvents != events {
                self.sortedEvents = events
                if !events.isEmpty {
                    if self.activitiesSections.firstIndex(of: .calendar) == nil {
                        self.activitiesSections.append(.calendar)
                    }
                    self.activities[.calendar] = events
                } else {
                    if let index = self.activitiesSections.firstIndex(of: .calendar) {
                        self.activitiesSections.remove(at: index)
                    }
                    self.activities[.calendar] = nil
                }
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
    
    func scrollToFirstTask(_ completion: @escaping ([Activity]) -> Void) {
        let allTasks = networkController.activityService.tasks
        var tasks = Array(allTasks.filter { !($0.isCompleted ?? false) }.prefix(3))
        tasks = tasks.sorted(by: { task1, task2 in
            if let task1Date = task1.endDate, let task2Date = task2.endDate, task1Date == task2Date {
                return task1.name ?? "" < task2.name ?? ""
            }
            return task1.endDate ?? Date.distantPast < task2.endDate ?? Date.distantPast
        })
        completion(tasks)
    }
    
    func scrollToFirstActivityWithDate(_ completion: @escaping ([Activity]) -> Void) {
        let allActivities = networkController.activityService.events
        let totalNumberOfActivities = allActivities.count
        let numberOfActivities = 3
        if totalNumberOfActivities < numberOfActivities {
            completion(allActivities)
            return
        }
        var index = 0
        var events = [Activity]()
        let currentDate = Date().localTime
        var calendar = Calendar.current
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        for activity in allActivities {
            if let endDate = activity.endDateWTZ {
                if (currentDate < endDate) || (activity.allDay ?? false && calendar.compare(currentDate, to: endDate, toGranularity: .day) != .orderedDescending) {
                    if index < totalNumberOfActivities - (numberOfActivities - 1) {
                        if events.count < numberOfActivities {
                            events.append(allActivities[index])
                        } else {
                            completion(events)
                            return
                        }
                    } else {
                        break
                    }
                }
                index += 1
            }
        }
        
        events = []
        for i in 1...numberOfActivities {
            events.insert(allActivities[totalNumberOfActivities - i], at: 0)
        }
        completion(events)
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
                    categorizeTransactions(transactions: transactions, start: Date().localTime.startOfMonth, end: Date().localTime.endOfMonth, level: transactionLevel, accounts: nil) { (transactionsList, transactionsDict) in
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
        if section == .tasks, !sortedTasks.isEmpty {
            let destination = ListsViewController(networkController: networkController)
            destination.hidesBottomBarWhenPushed = true
            navigationController?.pushViewController(destination, animated: true)
        } else if section == .calendar, !sortedEvents.isEmpty {
            let destination = CalendarViewController(networkController: networkController)
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
        destination.notificationActivities = networkController.activityService.events
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
    func newListItem() {
        if !networkController.activityService.lists.keys.contains(ListOptions.apple.name) || !networkController.activityService.lists.keys.contains(ListOptions.google.name) {
            let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            
            alert.addAction(UIAlertAction(title: "Task", style: .default, handler: { (_) in
                let destination = EventViewController(networkController: self.networkController)
                let navigationViewController = UINavigationController(rootViewController: destination)
                self.present(navigationViewController, animated: true, completion: nil)
            }))
            
            alert.addAction(UIAlertAction(title: "List", style: .default, handler: { (_) in
                self.newList()
            }))
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (_) in
                print("User click Dismiss button")
            }))
            
            self.present(alert, animated: true, completion: {
                print("completion block")
            })
        } else {
            let destination = TaskViewController(networkController: networkController)
            let navigationViewController = UINavigationController(rootViewController: destination)
            self.present(navigationViewController, animated: true, completion: nil)
        }
    }
    
    func newCalendarItem() {
        if !networkController.activityService.calendars.keys.contains(CalendarOptions.apple.name) || !networkController.activityService.calendars.keys.contains(CalendarOptions.google.name) {
            let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            
            alert.addAction(UIAlertAction(title: "Event", style: .default, handler: { (_) in
                let destination = EventViewController(networkController: self.networkController)
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
            let destination = EventViewController(networkController: networkController)
            let navigationViewController = UINavigationController(rootViewController: destination)
            self.present(navigationViewController, animated: true, completion: nil)
        }
    }
    
    func newList() {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        if !networkController.activityService.lists.keys.contains(ListOptions.apple.name) {
            alert.addAction(UIAlertAction(title: ListOptions.apple.name, style: .default, handler: { (_) in
                self.networkController.activityService.updatePrimaryList(value: ListOptions.apple.name)
            }))
        }
        
        if !networkController.activityService.lists.keys.contains(ListOptions.google.name) {
            alert.addAction(UIAlertAction(title: ListOptions.google.name, style: .default, handler: { (_) in
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
    
    func newCalendar() {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        if !networkController.activityService.calendars.keys.contains(CalendarOptions.apple.name) {
            alert.addAction(UIAlertAction(title: CalendarOptions.apple.name, style: .default, handler: { (_) in
                self.networkController.activityService.updatePrimaryCalendar(value: CalendarOptions.apple.name)
                self.collectionView.reloadData()
            }))
        }
        
        if !networkController.activityService.calendars.keys.contains(CalendarOptions.google.name) {
            alert.addAction(UIAlertAction(title: CalendarOptions.google.name, style: .default, handler: { (_) in
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
            self.networkController.activityService.updatePrimaryCalendar(value: CalendarOptions.google.name)
            self.collectionView.reloadData()
        } else {
          print("\(error.localizedDescription)")
        }
    }
}

// MARK: - TasksControllerCellDelegate

extension MasterActivityContainerController: TasksControllerCellDelegate {
    func cellTapped(task: Activity) {
        showTaskDetail(task: task)
    }
}

// MARK: - ActivitiesControllerCellDelegate

extension MasterActivityContainerController: ActivitiesControllerCellDelegate {
    func headerTapped(sectionType: SectionType) {
        if sectionType == .tasks {
            let destination = ListsViewController(networkController: networkController)
            destination.hidesBottomBarWhenPushed = true
            navigationController?.pushViewController(destination, animated: true)
        } else if sectionType == .calendar {
            let destination = CalendarViewController(networkController: networkController)
            destination.hidesBottomBarWhenPushed = true
            navigationController?.pushViewController(destination, animated: true)
        }
    }
    
    func cellTapped(activity: Activity) {
        if activity.isTask ?? false {
            showTaskDetail(task: activity)
        } else {
            showEventDetail(event: activity)
        }
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
        let healthDetailViewController = HealthDetailViewController(viewModel: healthDetailViewModel, networkController: networkController)
        healthDetailViewController.segmentedControl.selectedSegmentIndex = metric.grabSegment()
        healthDetailViewController.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(healthDetailViewController, animated: true)
    }
}

extension MasterActivityContainerController: FinanceControllerCellDelegate {
    func openTransactionDetails(transactionDetails: TransactionDetails) {
        let financeDetailViewModel = FinanceDetailViewModel(accountDetails: nil, allAccounts: nil, accounts: nil, transactionDetails: transactionDetails, allTransactions: networkController.financeService.transactions, transactions: transactionsDictionary[transactionDetails], filterAccounts: nil, financeDetailService: FinanceDetailService())
        let financeDetailViewController = FinanceBarChartViewController(viewModel: financeDetailViewModel, networkController: networkController)
//        financeDetailViewController.delegate = self
        financeDetailViewController.hidesBottomBarWhenPushed = true
        self.navigationController?.pushViewController(financeDetailViewController, animated: true)
    }
    
    func openAccountDetails(accountDetails: AccountDetails) {
        let financeDetailViewModel = FinanceDetailViewModel(accountDetails: accountDetails, allAccounts: networkController.financeService.accounts, accounts: accountsDictionary[accountDetails], transactionDetails: nil, allTransactions: nil, transactions: nil, filterAccounts: nil, financeDetailService: FinanceDetailService())
        let financeDetailViewController = FinanceLineChartDetailViewController(viewModel: financeDetailViewModel, networkController: networkController)
//        financeDetailViewController.delegate = self
        financeDetailViewController.hidesBottomBarWhenPushed = true
        self.navigationController?.pushViewController(financeDetailViewController, animated: true)
    }
    
    func openHolding(holding: MXHolding) {
        let destination = FinanceHoldingViewController(networkController: networkController)
        destination.holding = holding
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
//        let eventsArray = section == 0 ? filteredPinnedActivities : filteredActivities
//        guard let index = eventsArray.firstIndex(where: { (activity) -> Bool in
//            guard let activityID = activity.activityID else { return false }
//            return activityID == otherActivityID
//        }) else { return nil }
//        return index
        return nil
    }
}

