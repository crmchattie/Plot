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

let taskCellID = "taskCellID"
let eventCellID = "eventCellID"
let healthMetricCellID = "HealthMetricCellID"
let healthMetricSectionHeaderID = "HealthMetricSectionHeaderID"
let kHeaderCell = "HeaderCell"
let kFinanceCollectionViewCell = "FinanceCollectionViewCell"
let kFinanceCollectionViewComparisonCell = "FinanceCollectionViewComparisonCell"
let kFinanceCollectionViewMemberCell = "FinanceCollectionViewMemberCell"
let setupCell = "SetupCell"
let headerContainerCell = "HeaderCellDelegate"


enum Mode {
    case small, fullscreen
}

protocol ManageAppearanceHome: AnyObject {
    func manageAppearanceHome(_ homeController: MasterActivityContainerController, didFinishLoadingWith state: Bool )
}

class MasterActivityContainerController: UIViewController, ObjectDetailShowing {
    init(networkController: NetworkController) {
        self.networkController = networkController
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    let networkController: NetworkController

    let collectionView:UICollectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout: UICollectionViewFlowLayout.init())
    let layout:UICollectionViewFlowLayout = UICollectionViewFlowLayout.init()
        
    let navigationItemActivityIndicator = NavigationItemActivityIndicator()
        
    weak var delegate: ManageAppearanceHome?
            
    var sections: [SectionType] = [.time, .health, .finances]
    var groups = [AnyHashable]()
    
    var activitiesSections = [SectionType]()
    var activities = [SectionType: [Activity]]()
    var sortedEvents = [Activity]()
    var sortedTasks = [Activity]()
    var invitations: [String: Invitation] {
        return networkController.activityService.invitations
    }
    
    var updatingTasks = true
    var updatingEvents = true
    var updatingHealth = true
    var updatingFinances = true
    
    var healthMetricSections: [HealthMetricCategory] {
        var healthMetricSections = Array(healthMetrics.keys)
        healthMetricSections.sort(by: { (v1, v2) -> Bool in
            return v1.rank < v2.rank
        })
        return healthMetricSections
    }
    var healthMetrics: [HealthMetricCategory: [HealthMetric]] {
        var metrics = networkController.healthService.healthMetrics
        if let generalMetrics = metrics[.general] {
            metrics[.general] = generalMetrics.filter({ $0.type == .steps || $0.type == .sleep || $0.type == .flightsClimbed || $0.type == .mindfulness })
        }
        if let workoutMetrics = metrics[.workouts] {
            metrics[.general]?.append(contentsOf: workoutMetrics.filter({ $0.type == .activeEnergy || $0.type == .workoutMinutes}))
            metrics[.workouts] = nil
        }
        if let nutritionMetrics = metrics[.nutrition] {
            metrics[.general]?.append(contentsOf: nutritionMetrics.filter({ $0.type.name == HKQuantityTypeIdentifier.dietaryEnergyConsumed.name }))
            metrics[.nutrition] = nil
        }
        if metrics[.general] == [] {
            metrics[.general] = nil
        }
        return metrics
    }
    var financeSections = [SectionType]()
    var financeGroups = [SectionType: [AnyHashable]]()
    var transactionsDictionary = [TransactionDetails: [Transaction]]()
    var accountsDictionary = [AccountDetails: [MXAccount]]()
    
    var notification: PLNotification?
    
    var participants: [String: [User]] = [:]
    
    var isNewUser: Bool = true
        
    var isAppLoaded = false
            
    let refreshControl = UIRefreshControl()
        
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        setNavBar()
        delegate?.manageAppearanceHome(self, didFinishLoadingWith: true)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        managePresense()
    }
    
    func setupViews() {
        navigationController?.navigationBar.backgroundColor = .systemGroupedBackground
        navigationController?.navigationBar.layoutIfNeeded()
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationController?.navigationItem.largeTitleDisplayMode = .always

        view.backgroundColor = .systemGroupedBackground
        collectionView.indicatorStyle = .default
        collectionView.backgroundColor = .systemGroupedBackground
        
        definesPresentationContext = true
        layout.scrollDirection = UICollectionView.ScrollDirection.vertical
        collectionView.setCollectionViewLayout(layout, animated: true)
        collectionView.dataSource = self
        collectionView.delegate = self
        
        view.addSubview(collectionView)
        collectionView.fillSuperview()
        collectionView.register(TaskCollectionCell.self, forCellWithReuseIdentifier: taskCellID)
        collectionView.register(EventCollectionCell.self, forCellWithReuseIdentifier: eventCellID)
        collectionView.register(HealthMetricCell.self, forCellWithReuseIdentifier: healthMetricCellID)
        collectionView.register(FinanceCollectionViewCell.self, forCellWithReuseIdentifier: kFinanceCollectionViewCell)
        collectionView.register(FinanceCollectionViewComparisonCell.self, forCellWithReuseIdentifier: kFinanceCollectionViewComparisonCell)
        collectionView.register(FinanceCollectionViewMemberCell.self, forCellWithReuseIdentifier: kFinanceCollectionViewMemberCell)
        collectionView.register(InterSectionHeader.self, forCellWithReuseIdentifier: kHeaderCell)
        collectionView.register(SetupCell.self, forCellWithReuseIdentifier: setupCell)
        collectionView.register(HeaderContainerCell.self, forCellWithReuseIdentifier: headerContainerCell)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func addObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(calendarActivitiesUpdated), name: .calendarActivitiesUpdated, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(tasksUpdated), name: .tasksUpdated, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(invitationsUpdated), name: .invitationsUpdated, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(healthUpdated), name: .healthUpdated, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(financeUpdated), name: .financeUpdated, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(listsUpdated), name: .listsUpdated, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(calendarsUpdated), name: .calendarsUpdated, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(hasLoadedCalendarEventActivities), name: .hasLoadedCalendarEventActivities, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(hasLoadedListTaskActivities), name: .hasLoadedListTaskActivities, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(hasLoadedHealth), name: .hasLoadedHealth, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(hasLoadedFinancials), name: .hasLoadedFinancials, object: nil)
    }
    
    func setupData() {
        groups = []
        var list = [AnyHashable]()
        list.append(SectionType.time)
        if activitiesSections.isEmpty {
            list.append(CustomType.time)
        } else {
            for section in activitiesSections {
                if activitiesSections.count > 1 {
                    list.append(section)
                }
                list.append(contentsOf: activities[section] ?? [])
            }
        }
        
        list.append(SectionType.health)
        if healthMetricSections.isEmpty {
            list.append(CustomType.health)
        } else {
            for section in healthMetricSections {
                list.append(SectionType.generalHealth)
                list.append(contentsOf: healthMetrics[section] ?? [])
            }
        }
        
        list.append(SectionType.finances)
        if financeSections.isEmpty {
            list.append(CustomType.finances)
        } else {
            for section in financeSections {
                list.append(section)
                list.append(contentsOf: financeGroups[section] ?? [])
            }
        }
        
        groups = list
        
        DispatchQueue.main.async {
            self.collectionView.reloadData()
        }
    }
    
    @objc fileprivate func tasksUpdated() {
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
                    self.setupData()
                }
            }
        })
    }
    
    @objc fileprivate func calendarActivitiesUpdated() {
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
                    self.setupData()
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
        DispatchQueue.main.async {
            self.setupData()
        }
    }
    
    @objc fileprivate func financeUpdated() {
        self.grabFinancialItems { (sections, groups) in
            if self.financeSections != sections || self.financeGroups != groups {
                self.financeSections = sections
                self.financeGroups = groups
                DispatchQueue.main.async {
                    self.setupData()
                }
            }
        }
    }
    
    @objc fileprivate func listsUpdated() {
        DispatchQueue.main.async {
            self.collectionView.reloadData()
        }
    }
    
    @objc fileprivate func calendarsUpdated() {
        DispatchQueue.main.async {
            self.collectionView.reloadData()
        }
    }
    
    @objc fileprivate func hasLoadedCalendarEventActivities() {
        self.updatingEvents = !networkController.activityService.hasLoadedCalendarEventActivities
        DispatchQueue.main.async {
            self.collectionView.reloadData()
        }
    }
    
    @objc fileprivate func hasLoadedListTaskActivities() {
        self.updatingTasks = !networkController.activityService.hasLoadedListTaskActivities
        DispatchQueue.main.async {
            self.collectionView.reloadData()
        }
    }
    
    @objc fileprivate func hasLoadedHealth() {
        self.updatingHealth = !networkController.healthService.hasLoadedHealth
        DispatchQueue.main.async {
            self.collectionView.reloadData()
        }
    }
    
    @objc fileprivate func hasLoadedFinancials() {
        self.updatingFinances = !networkController.financeService.hasLoadedFinancials
        DispatchQueue.main.async {
            self.collectionView.reloadData()
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
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "notification-bell"),
                                                            style: .plain,
                                                            target: self,
                                                            action: #selector(goToNotifications))

        if !isNewUser {
            refreshControl.addTarget(self, action: #selector(refreshControlAction(_:)), for: UIControl.Event.valueChanged)
            collectionView.refreshControl = refreshControl
        }
    }
    
    fileprivate func managePresense() {
        if currentReachabilityStatus == .notReachable {
            navigationItemActivityIndicator.showActivityIndicator(for: navigationItem, with: .connecting,
                                                                  activityPriority: .high,
                                                                  color: .label)
        }
        
        let connectedReference = Database.database().reference(withPath: ".info/connected")
        connectedReference.observe(.value, with: { (snapshot) in
            
            if self.currentReachabilityStatus != .notReachable {
                self.navigationItemActivityIndicator.hideActivityIndicator(for: self.navigationItem, activityPriority: .crazy)
            } else {
                self.navigationItemActivityIndicator.showActivityIndicator(for: self.navigationItem, with: .noInternet, activityPriority: .crazy, color: .label)
            }
        })
    }
    
    func scrollToFirstTask(_ completion: @escaping ([Activity]) -> Void) {
        let allTasks = networkController.activityService.tasks
        let numberOfActivities = 3
        if allTasks.count < numberOfActivities {
            completion(allTasks)
            return
        } else {
            var index = 0
            var tasks = [Activity]()
            for task in allTasks {
                if index < numberOfActivities {
                    if !tasks.contains(where: {$0.activityID == task.activityID}) && !(task.isCompleted ?? false) {
                        tasks.append(task)
                        index += 1
                    }
                } else {
                    break
                }
            }
            completion(tasks)
        }
    }
    
    func scrollToFirstActivityWithDate(_ completion: @escaping ([Activity]) -> Void) {
        let allActivities = networkController.activityService.calendarActivities
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
            if let endDate = activity.endDate?.localTime {
                if currentDate < endDate {
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
        
        let setSections: [SectionType] = [.financialIssues, .cashFlow, .balancesFinances, .investments, .transactions]
        
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
                if section.subType == "Balances" {
                    categorizeAccounts(accounts: accounts, timeSegment: .month, level: accountLevel, date: nil) { (accountsList, accountsDict) in
                        if !accountsList.isEmpty {
                            sections.append(section)
                            groups[section] = accountsList
                            self.accountsDictionary = accountsDict
                        }
                    }
                }
            } else if section.type == "Transactions" {
                if section.subType == "Cash Flow" {
                    categorizeTransactions(transactions: transactions, start: Date().localTime.startOfMonth, end: Date().localTime.endOfMonth, level: transactionLevel, accounts: nil) { (transactionsList, transactionsDict) in
                        if !transactionsList.isEmpty {
                            categorizeTransactions(transactions: transactions, start: Date().localTime.startOfMonth.monthBefore, end: Date().localTime.endOfMonth.monthBefore, level: .group, accounts: nil) { (transactionsListPrior, _) in
                                if !transactionsListPrior.isEmpty {
                                    addPriorTransactionDetails(currentDetailsList: transactionsList, currentDetailsDict: transactionsDict, priorDetailsList: transactionsListPrior) { (finalTransactionList, finalTransactionsDict) in
                                        sections.append(section)
                                        groups[section] = finalTransactionList
                                        self.transactionsDictionary = finalTransactionsDict
                                    }
                                } else {
                                    sections.append(section)
                                    groups[section] = transactionsList
                                    self.transactionsDictionary = transactionsDict
                                }
                            }
                        }
                    }
                } else if section.subType == "Transactions" {
                    let filteredTransactions = transactions.filter({$0.should_link ?? true && !($0.plot_created ?? false)})
                    if !filteredTransactions.isEmpty {
                        sections.append(section)
                        if filteredTransactions.count < 3 {
                            groups[section] = filteredTransactions
                        } else {
                            var finalTransactions = [Transaction]()
                            for index in 0...2 {
                                finalTransactions.append(filteredTransactions[index])
                            }
                            groups[section] = finalTransactions
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
        } else if section == .time {
            if !sortedTasks.isEmpty {
                let destination = ListsViewController(networkController: networkController)
                destination.hidesBottomBarWhenPushed = true
                navigationController?.pushViewController(destination, animated: true)
            } else if !sortedEvents.isEmpty {
                let destination = CalendarViewController(networkController: networkController)
                destination.hidesBottomBarWhenPushed = true
                navigationController?.pushViewController(destination, animated: true)
            }
        } else if section == .health, !healthMetrics.isEmpty {
            let destination = HealthViewController(networkController: networkController)
            destination.hidesBottomBarWhenPushed = true
            navigationController?.pushViewController(destination, animated: true)
        } else if section == .transactions, let transactions = financeGroups[.transactions], transactions.count > 3 {
            let destination = FinanceDetailViewController(networkController: networkController)
            destination.title = SectionType.transactions.name
            destination.setSections = [.transactions]
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
        let destination = AccountSettingsController(networkController: networkController)
        let navigationViewController = UINavigationController(rootViewController: destination)
        self.present(navigationViewController, animated: true, completion: nil)
    }

    @objc func goToNotifications() {
        let destination = NotificationsViewController(networkController: networkController)
        destination.sortInvitedActivities()
        let navigationViewController = UINavigationController(rootViewController: destination)
        self.present(navigationViewController, animated: true, completion: nil)
    }
}

extension MasterActivityContainerController: GIDSignInDelegate {
    func newListItem() {
        if !networkController.activityService.lists.keys.contains(ListSourceOptions.apple.name) || !networkController.activityService.lists.keys.contains(ListSourceOptions.google.name) {
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
        if !networkController.activityService.calendars.keys.contains(CalendarSourceOptions.apple.name) || !networkController.activityService.calendars.keys.contains(CalendarSourceOptions.google.name) {
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
        
        if !networkController.activityService.lists.keys.contains(ListSourceOptions.apple.name) {
            alert.addAction(UIAlertAction(title: ListSourceOptions.apple.name, style: .default, handler: { (_) in
                self.networkController.activityService.updatePrimaryList(value: ListSourceOptions.apple.name)
            }))
        }
        
        if !networkController.activityService.lists.keys.contains(ListSourceOptions.google.name) {
            alert.addAction(UIAlertAction(title: ListSourceOptions.google.name, style: .default, handler: { (_) in
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
        let destination = SignInAppleGoogleViewController(networkController: networkController)
        destination.title = "Providers"
        let cancelBarButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: destination, action: nil)
        destination.navigationItem.leftBarButtonItem = cancelBarButton
        let doneBarButton = UIBarButtonItem(barButtonSystemItem: .done, target: destination, action: nil)
        destination.navigationItem.rightBarButtonItem = doneBarButton
        let navigationViewController = UINavigationController(rootViewController: destination)
        self.present(navigationViewController, animated: true, completion: nil)
    }
    
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        if (error == nil) {
            let grantedScopes = user?.grantedScopes as? [String]
            if let grantedScopes = grantedScopes {
                if grantedScopes.contains(googleEmailScope) && grantedScopes.contains(googleTaskScope) {
                    self.networkController.activityService.updatePrimaryCalendar(value: CalendarSourceOptions.google.name)
                    self.networkController.activityService.updatePrimaryList(value: ListSourceOptions.google.name)
                    self.collectionView.reloadData()
                } else if grantedScopes.contains(googleEmailScope) {
                    self.networkController.activityService.updatePrimaryCalendar(value: CalendarSourceOptions.google.name)
                    self.collectionView.reloadData()
                } else if grantedScopes.contains(googleTaskScope) {
                    self.networkController.activityService.updatePrimaryList(value: ListSourceOptions.google.name)
                    self.collectionView.reloadData()
                }
            }
        } else {
          print("\(error.localizedDescription)")
        }
    }
}

// MARK: - ActivitiesControllerCellDelegate

extension MasterActivityContainerController: ActivitiesControllerCellDelegate, UpdateInvitationDelegate {
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
            showTaskDetailPush(task: activity)
        } else {
            showEventDetailPush(event: activity)
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
        financeDetailViewController.hidesBottomBarWhenPushed = true
        self.navigationController?.pushViewController(financeDetailViewController, animated: true)
    }
    
    func openAccountDetails(accountDetails: AccountDetails) {
        let financeDetailViewModel = FinanceDetailViewModel(accountDetails: accountDetails, allAccounts: networkController.financeService.accounts, accounts: accountsDictionary[accountDetails], transactionDetails: nil, allTransactions: nil, transactions: nil, filterAccounts: nil, financeDetailService: FinanceDetailService())
        let financeDetailViewController = FinanceBarChartViewController(viewModel: financeDetailViewModel, networkController: networkController)
        financeDetailViewController.hidesBottomBarWhenPushed = true
        self.navigationController?.pushViewController(financeDetailViewController, animated: true)
    }
    
    func openHolding(holding: MXHolding) {
        let destination = FinanceHoldingViewController(networkController: networkController)
        destination.holding = holding
        destination.hidesBottomBarWhenPushed = true
        ParticipantsFetcher.getParticipants(forHolding: holding) { (participants) in
            destination.selectedFalconUsers = participants
            self.navigationController?.pushViewController(destination, animated: true)
        }
    }
    
    func openTransaction(transaction: Transaction) {
        let destination = FinanceTransactionViewController(networkController: self.networkController)
        destination.transaction = transaction
        destination.hidesBottomBarWhenPushed = true
        ParticipantsFetcher.getParticipants(forTransaction: transaction) { (participants) in
            destination.selectedFalconUsers = participants
            self.navigationController?.pushViewController(destination, animated: true)
        }
    }
    
    func openMember(member: MXMember) {
        openMXConnect(current_member_guid: member.guid)
    }
    
    func viewTappedFinance(sectionType: SectionType) {
        let destination = FinanceDetailViewController(networkController: networkController)
        destination.title = sectionType.name
        destination.setSections = [sectionType]
        navigationController?.pushViewController(destination, animated: true)
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


extension MasterActivityContainerController: EndedWebViewDelegate {
    func updateMXMembers() {
        self.financeSections.removeAll(where: { $0 == .financialIssues })
        self.financeGroups[.financialIssues] = nil
        DispatchQueue.main.async {
            self.collectionView.reloadData()
        }
        networkController.financeService.regrabFinances {}
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
