//
//  UIViewController+Navigation.swift
//  Plot
//
//  Created by Botond Magyarosi on 06.04.2021.
//  Copyright © 2021 Immature Creations. All rights reserved.
//

import UIKit
import Firebase
import CodableFirebase

protocol ObjectDetailShowing: UIViewController {
    var networkController: NetworkController { get }
    var participants: [String: [User]] { get set }
}

extension ObjectDetailShowing {
    
    func showTaskDetailPush(task: Activity?, updateDiscoverDelegate: UpdateDiscover?, delegate: UpdateTaskDelegate?, event: Activity?, transaction: Transaction?, workout: Workout?, mindfulness: Mindfulness?, template: Template?, users: [User]?, container: Container?, list: ListType?, startDateTime: Date?, endDateTime: Date?) {
        let destination = TaskViewController(networkController: networkController)
        destination.task = task
        destination.updateDiscoverDelegate = updateDiscoverDelegate
        destination.delegate = delegate
        destination.event = event
        destination.transaction = transaction
        destination.workout = workout
        destination.mindfulness = mindfulness
        destination.template = template
        destination.container = container
        destination.list = list
        destination.startDateTime = startDateTime
        destination.endDateTime = endDateTime
        if let users = users {
            destination.users = users
            destination.filteredUsers = users
        }
        ParticipantsFetcher.getParticipants(forActivity: task) { (participants) in
            destination.selectedFalconUsers = participants
            destination.hidesBottomBarWhenPushed = true
            self.navigationController?.pushViewController(destination, animated: true)
        }
    }
    
    func showGoalDetailPush(task: Activity?, updateDiscoverDelegate: UpdateDiscover?, delegate: UpdateTaskDelegate?, event: Activity?, transaction: Transaction?, workout: Workout?, mindfulness: Mindfulness?, template: Template?, users: [User]?, container: Container?, list: ListType?, startDateTime: Date?, endDateTime: Date?) {
        let destination = GoalViewController(networkController: networkController)
        destination.task = task
        destination.updateDiscoverDelegate = updateDiscoverDelegate
        destination.delegate = delegate
        destination.event = event
        destination.transaction = transaction
        destination.workout = workout
        destination.mindfulness = mindfulness
        destination.template = template
        destination.container = container
        destination.list = list
        destination.startDateTime = startDateTime
        destination.endDateTime = endDateTime
        if let users = users {
            destination.users = users
            destination.filteredUsers = users
        }
        ParticipantsFetcher.getParticipants(forActivity: task) { (participants) in
            destination.selectedFalconUsers = participants
            destination.hidesBottomBarWhenPushed = true
            self.navigationController?.pushViewController(destination, animated: true)
        }
    }
    
    func showSubtaskDetailPush(subtask: Activity?, task: Activity?, delegate: UpdateTaskDelegate?, users: [User]) {
        let destination = SubtaskViewController()
        destination.subtask = subtask
        destination.task = task
        destination.users = users
        destination.filteredUsers = users
        destination.delegate = delegate
        destination.hidesBottomBarWhenPushed = true
        self.navigationController?.pushViewController(destination, animated: true)
    }
    
    func showChooseTaskDetailPush(needDelegate: Bool, movingBackwards: Bool, delegate: ChooseTaskDelegate, tasks: [Activity], existingTasks: [Activity]) {
        let destination = ChooseTaskTableViewController(networkController: self.networkController)
        destination.needDelegate = needDelegate
        destination.movingBackwards = movingBackwards
        destination.delegate = delegate
        destination.tasks = tasks
        destination.existingTasks = existingTasks
        destination.hidesBottomBarWhenPushed = true
        self.navigationController?.pushViewController(destination, animated: true)
    }
    
    func showEventDetailPush(event: Activity?, updateDiscoverDelegate: UpdateDiscover?, delegate: UpdateActivityDelegate?, task: Activity?, transaction: Transaction?, workout: Workout?, mindfulness: Mindfulness?, template: Template?, users: [User]?, container: Container?, startDateTime: Date?, endDateTime: Date?) {
        let destination = EventViewController(networkController: networkController)
        destination.activity = event
        destination.updateDiscoverDelegate = updateDiscoverDelegate
        destination.delegate = delegate
        destination.task = task
        destination.transaction = transaction
        destination.workout = workout
        destination.mindfulness = mindfulness
        destination.template = template
        destination.container = container
        destination.startDateTime = startDateTime
        destination.endDateTime = endDateTime
        if let users = users {
            destination.users = users
            destination.filteredUsers = users
        }
        destination.invitation = self.networkController.activityService.invitations[event?.activityID ?? ""]
        ParticipantsFetcher.getParticipants(forActivity: event) { (participants) in
            ParticipantsFetcher.getAcceptedParticipant(forActivity: event, allParticipants: participants) { acceptedParticipant in
                destination.acceptedParticipant = acceptedParticipant
                destination.selectedFalconUsers = participants
                destination.hidesBottomBarWhenPushed = true
                self.navigationController?.pushViewController(destination, animated: true)
            }
        }
    }
    
    func showScheduleDetailPush(schedule: Activity?, event: Activity?, delegate: UpdateActivityDelegate?, users: [User]) {
        let destination = ScheduleViewController()
        destination.schedule = schedule
        destination.event = event
        destination.users = users
        destination.filteredUsers = users
        destination.delegate = delegate
        destination.hidesBottomBarWhenPushed = true
        self.navigationController?.pushViewController(destination, animated: true)
    }
    
    func showChooseEventDetailPush(needDelegate: Bool, movingBackwards: Bool, delegate: ChooseActivityDelegate, events: [Activity], existingEvents: [Activity]) {
        let destination = ChooseEventTableViewController(networkController: self.networkController)
        destination.needDelegate = needDelegate
        destination.movingBackwards = movingBackwards
        destination.delegate = delegate
        destination.events = events
        destination.existingEvents = existingEvents
        destination.hidesBottomBarWhenPushed = true
        self.navigationController?.pushViewController(destination, animated: true)
    }
    
    func showTransactionDetailPush(transaction: Transaction?, updateDiscoverDelegate: UpdateDiscover?, delegate: UpdateTransactionDelegate?, template: Template?, users: [User]?, container: Container?, movingBackwards: Bool?) {
        let destination = FinanceTransactionViewController(networkController: self.networkController)
        destination.transaction = transaction
        destination.updateDiscoverDelegate = updateDiscoverDelegate
        destination.delegate = delegate
        destination.container = container
        destination.movingBackwards = movingBackwards ?? false
        if let users = users {
            destination.users = users
            destination.filteredUsers = users
        }
        ParticipantsFetcher.getParticipants(forTransaction: transaction) { (participants) in
            destination.selectedFalconUsers = participants
            destination.hidesBottomBarWhenPushed = true
            self.navigationController?.pushViewController(destination, animated: true)
        }
    }
    
    func showChooseTransactionDetailPush(movingBackwards: Bool, delegate: ChooseTransactionDelegate, transactions: [Transaction], existingTransactions: [Transaction]) {
        let destination = ChooseTransactionTableViewController(networkController: self.networkController)
        destination.movingBackwards = movingBackwards
        destination.delegate = delegate
        destination.transactions = transactions
        destination.existingTransactions = existingTransactions
        destination.hidesBottomBarWhenPushed = true
        self.navigationController?.pushViewController(destination, animated: true)
    }
    
    func showTransactionRuleDetailPush(transactionRule: TransactionRule?, transaction: Transaction?, updateDiscoverDelegate: UpdateDiscover?) {
        let destination = FinanceTransactionRuleViewController(networkController: self.networkController)
        destination.transactionRule = transactionRule
        destination.transaction = transaction
        destination.updateDiscoverDelegate = updateDiscoverDelegate
        destination.hidesBottomBarWhenPushed = true
        self.navigationController?.pushViewController(destination, animated: true)
    }
    
    func showAccountDetailPush(account: MXAccount?, updateDiscoverDelegate: UpdateDiscover?) {
        let destination = FinanceAccountViewController(networkController: self.networkController)
        destination.account = account
        destination.updateDiscoverDelegate = updateDiscoverDelegate
        ParticipantsFetcher.getParticipants(forAccount: account) { (participants) in
            destination.selectedFalconUsers = participants
            destination.hidesBottomBarWhenPushed = true
            self.navigationController?.pushViewController(destination, animated: true)
        }
    }
    
    func showHoldingDetailPush(holding: MXHolding?, updateDiscoverDelegate: UpdateDiscover?) {
        let destination = FinanceHoldingViewController(networkController: self.networkController)
        destination.holding = holding
        destination.updateDiscoverDelegate = updateDiscoverDelegate
        ParticipantsFetcher.getParticipants(forHolding: holding) { (participants) in
            destination.selectedFalconUsers = participants
            destination.hidesBottomBarWhenPushed = true
            self.navigationController?.pushViewController(destination, animated: true)
        }
    }
    
    func showListDetailPush(list: ListType?, updateDiscoverDelegate: UpdateDiscover?) {
        let destination = ListDetailViewController(networkController: self.networkController)
        destination.list = list
        destination.updateDiscoverDelegate = updateDiscoverDelegate
        ParticipantsFetcher.getParticipants(forList: list) { (participants) in
            destination.selectedFalconUsers = participants
            destination.hidesBottomBarWhenPushed = true
            self.navigationController?.pushViewController(destination, animated: true)
        }
    }
    
    func showCalendarDetailPush(calendar: CalendarType?, updateDiscoverDelegate: UpdateDiscover?) {
        let destination = CalendarDetailViewController(networkController: self.networkController)
        destination.calendar = calendar
        destination.updateDiscoverDelegate = updateDiscoverDelegate
        ParticipantsFetcher.getParticipants(forCalendar: calendar) { (participants) in
            destination.selectedFalconUsers = participants
            destination.hidesBottomBarWhenPushed = true
            self.navigationController?.pushViewController(destination, animated: true)
        }
    }
    
    func showWorkoutDetailPush(workout: Workout?, updateDiscoverDelegate: UpdateDiscover?, delegate: UpdateWorkoutDelegate?, template: Template?, users: [User]?, container: Container?, movingBackwards: Bool?) {
        let destination = WorkoutViewController(networkController: self.networkController)
        destination.workout = workout
        destination.template = template
        destination.updateDiscoverDelegate = updateDiscoverDelegate
        destination.delegate = delegate
        destination.container = container
        destination.movingBackwards = movingBackwards ?? false
        if let users = users {
            destination.users = users
            destination.filteredUsers = users
        }
        ParticipantsFetcher.getParticipants(forWorkout: workout) { (participants) in
            destination.selectedFalconUsers = participants
            destination.hidesBottomBarWhenPushed = true
            self.navigationController?.pushViewController(destination, animated: true)
        }
    }
    
    func showMindfulnessDetailPush(mindfulness: Mindfulness?, updateDiscoverDelegate: UpdateDiscover?, delegate: UpdateMindfulnessDelegate?, template: Template?, users: [User]?, container: Container?, movingBackwards: Bool?) {
        let destination = MindfulnessViewController(networkController: self.networkController)
        destination.mindfulness = mindfulness
        destination.template = template
        destination.updateDiscoverDelegate = updateDiscoverDelegate
        destination.delegate = delegate
        destination.container = container
        destination.movingBackwards = movingBackwards ?? false
        if let users = users {
            destination.users = users
            destination.filteredUsers = users
        }
        ParticipantsFetcher.getParticipants(forMindfulness: mindfulness) { (participants) in
            destination.selectedFalconUsers = participants
            destination.hidesBottomBarWhenPushed = true
            self.navigationController?.pushViewController(destination, animated: true)
        }
    }
    
    func showHealthMetricDetailPush(healthMetric: HealthMetric) {
        let healthDetailService = HealthDetailService()
        let healthDetailViewModel = HealthDetailViewModel(healthMetric: healthMetric, healthDetailService: healthDetailService)
        let healthDetailViewController = HealthDetailViewController(viewModel: healthDetailViewModel, networkController: networkController)
        healthDetailViewController.segmentedControl.selectedSegmentIndex = healthMetric.grabSegment()
        healthDetailViewController.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(healthDetailViewController, animated: true)
    }
    
    
    func showTransactionDetailDetailPush(transactionDetails: TransactionDetails, allTransactions: [Transaction], transactions: [Transaction], filterDictionary: [String]?, selectedIndex: Int?) {
        let financeDetailViewModel = FinanceDetailViewModel(accountDetails: nil, allAccounts: nil, accounts: nil, transactionDetails: transactionDetails, allTransactions: allTransactions, transactions: transactions, filterAccounts: filterDictionary,  financeDetailService: FinanceDetailService())
        let financeDetailViewController = FinanceBarChartDetailViewController(viewModel: financeDetailViewModel, networkController: networkController)
        financeDetailViewController.selectedIndex = selectedIndex ?? 2
        financeDetailViewController.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(financeDetailViewController, animated: true)
    }
    
    func showAccountDetailDetailPush(accountDetails: AccountDetails, allAccounts: [MXAccount], accounts: [MXAccount], selectedIndex: Int?) {
        let financeDetailViewModel = FinanceDetailViewModel(accountDetails: accountDetails, allAccounts: allAccounts, accounts: accounts, transactionDetails: nil, allTransactions: nil, transactions: nil, filterAccounts: nil, financeDetailService: FinanceDetailService())
        let financeDetailViewController = FinanceLineChartDetailViewController(viewModel: financeDetailViewModel, networkController: networkController)
        financeDetailViewController.selectedIndex = selectedIndex ?? 2
        financeDetailViewController.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(financeDetailViewController, animated: true)
    }
    
    func showTaskDetailPresent(task: Activity?, updateDiscoverDelegate: UpdateDiscover?, delegate: UpdateTaskDelegate?, event: Activity?, transaction: Transaction?, workout: Workout?, mindfulness: Mindfulness?, template: Template?, users: [User]?, container: Container?, list: ListType?, startDateTime: Date?, endDateTime: Date?) {
        let destination = TaskViewController(networkController: networkController)
        destination.task = task
        destination.updateDiscoverDelegate = updateDiscoverDelegate
        destination.delegate = delegate
        destination.event = event
        destination.transaction = transaction
        destination.workout = workout
        destination.mindfulness = mindfulness
        destination.template = template
        destination.container = container
        destination.list = list
        destination.startDateTime = startDateTime
        destination.endDateTime = endDateTime
        if let users = users {
            destination.users = users
            destination.filteredUsers = users
        }
        ParticipantsFetcher.getParticipants(forActivity: task) { (participants) in
            destination.selectedFalconUsers = participants
            let cancelBarButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: destination, action: nil)
            destination.navigationItem.leftBarButtonItem = cancelBarButton
            destination.hidesBottomBarWhenPushed = true
            let navigationViewController = UINavigationController(rootViewController: destination)
            self.present(navigationViewController, animated: true, completion: nil)
        }
    }
    
    func showGoalDetailPresent(task: Activity?, updateDiscoverDelegate: UpdateDiscover?, delegate: UpdateTaskDelegate?, event: Activity?, transaction: Transaction?, workout: Workout?, mindfulness: Mindfulness?, template: Template?, users: [User]?, container: Container?, list: ListType?, startDateTime: Date?, endDateTime: Date?) {
        let destination = GoalViewController(networkController: networkController)
        destination.task = task
        destination.updateDiscoverDelegate = updateDiscoverDelegate
        destination.delegate = delegate
        destination.event = event
        destination.transaction = transaction
        destination.workout = workout
        destination.mindfulness = mindfulness
        destination.template = template
        destination.container = container
        destination.list = list
        destination.startDateTime = startDateTime
        destination.endDateTime = endDateTime
        if let users = users {
            destination.users = users
            destination.filteredUsers = users
        }
        ParticipantsFetcher.getParticipants(forActivity: task) { (participants) in
            destination.selectedFalconUsers = participants
            let cancelBarButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: destination, action: nil)
            destination.navigationItem.leftBarButtonItem = cancelBarButton
            destination.hidesBottomBarWhenPushed = true
            let navigationViewController = UINavigationController(rootViewController: destination)
            self.present(navigationViewController, animated: true, completion: nil)
        }
    }
    
    func showSubtaskDetailPresent(subtask: Activity?, task: Activity?, delegate: UpdateTaskDelegate?, users: [User]) {
        let destination = SubtaskViewController()
        destination.subtask = subtask
        destination.task = task
        destination.users = users
        destination.filteredUsers = users
        destination.delegate = delegate
        let cancelBarButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: destination, action: nil)
        destination.navigationItem.leftBarButtonItem = cancelBarButton
        destination.hidesBottomBarWhenPushed = true
        let navigationViewController = UINavigationController(rootViewController: destination)
        self.present(navigationViewController, animated: true, completion: nil)
    }
    
    func showChooseTaskDetailPresent(needDelegate: Bool, movingBackwards: Bool, delegate: ChooseTaskDelegate, tasks: [Activity], existingTasks: [Activity]) {
        let destination = ChooseTaskTableViewController(networkController: self.networkController)
        destination.needDelegate = needDelegate
        destination.movingBackwards = movingBackwards
        destination.delegate = delegate
        destination.tasks = tasks
        destination.existingTasks = existingTasks
        let cancelBarButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: destination, action: nil)
        destination.navigationItem.leftBarButtonItem = cancelBarButton
        destination.hidesBottomBarWhenPushed = true
        let navigationViewController = UINavigationController(rootViewController: destination)
        self.present(navigationViewController, animated: true, completion: nil)
    }
    
    func showEventDetailPresent(event: Activity?, updateDiscoverDelegate: UpdateDiscover?, delegate: UpdateActivityDelegate?, task: Activity?, transaction: Transaction?, workout: Workout?, mindfulness: Mindfulness?, template: Template?, users: [User]?, container: Container?, startDateTime: Date?, endDateTime: Date?) {
        let destination = EventViewController(networkController: networkController)
        destination.activity = event
        destination.updateDiscoverDelegate = updateDiscoverDelegate
        destination.delegate = delegate
        destination.task = task
        destination.transaction = transaction
        destination.workout = workout
        destination.mindfulness = mindfulness
        destination.template = template
        destination.container = container
        destination.startDateTime = startDateTime
        destination.endDateTime = endDateTime
        if let users = users {
            destination.users = users
            destination.filteredUsers = users
        }
        destination.invitation = self.networkController.activityService.invitations[event?.activityID ?? ""]
        ParticipantsFetcher.getParticipants(forActivity: event) { (participants) in
            ParticipantsFetcher.getAcceptedParticipant(forActivity: event, allParticipants: participants) { acceptedParticipant in
                destination.acceptedParticipant = acceptedParticipant
                destination.selectedFalconUsers = participants
                let cancelBarButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: destination, action: nil)
                destination.navigationItem.leftBarButtonItem = cancelBarButton
                destination.hidesBottomBarWhenPushed = true
                let navigationViewController = UINavigationController(rootViewController: destination)
                self.present(navigationViewController, animated: true, completion: nil)
            }
        }
    }
    
    func showScheduleDetailPresent(schedule: Activity?, event: Activity?, delegate: UpdateActivityDelegate?, users: [User]) {
        let destination = ScheduleViewController()
        destination.schedule = schedule
        destination.event = event
        destination.users = users
        destination.filteredUsers = users
        destination.delegate = delegate
        let cancelBarButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: destination, action: nil)
        destination.navigationItem.leftBarButtonItem = cancelBarButton
        destination.hidesBottomBarWhenPushed = true
        let navigationViewController = UINavigationController(rootViewController: destination)
        self.present(navigationViewController, animated: true, completion: nil)
    }
    
    func showChooseEventDetailPresent(needDelegate: Bool, movingBackwards: Bool, delegate: ChooseActivityDelegate, events: [Activity], existingEvents: [Activity]) {
        let destination = ChooseEventTableViewController(networkController: self.networkController)
        destination.needDelegate = needDelegate
        destination.movingBackwards = movingBackwards
        destination.delegate = delegate
        destination.events = events
        destination.existingEvents = existingEvents
        let cancelBarButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: destination, action: nil)
        destination.navigationItem.leftBarButtonItem = cancelBarButton
        destination.hidesBottomBarWhenPushed = true
        let navigationViewController = UINavigationController(rootViewController: destination)
        self.present(navigationViewController, animated: true, completion: nil)
    }
    
    func showTransactionDetailPresent(transaction: Transaction?, updateDiscoverDelegate: UpdateDiscover?, delegate: UpdateTransactionDelegate?, users: [User]?, container: Container?, movingBackwards: Bool?) {
        let destination = FinanceTransactionViewController(networkController: self.networkController)
        destination.transaction = transaction
        destination.updateDiscoverDelegate = updateDiscoverDelegate
        destination.delegate = delegate
        destination.container = container
        destination.movingBackwards = movingBackwards ?? false
        if let users = users {
            destination.users = users
            destination.filteredUsers = users
        }
        ParticipantsFetcher.getParticipants(forTransaction: transaction) { (participants) in
            destination.selectedFalconUsers = participants
            let cancelBarButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: destination, action: nil)
            destination.navigationItem.leftBarButtonItem = cancelBarButton
            destination.hidesBottomBarWhenPushed = true
            let navigationViewController = UINavigationController(rootViewController: destination)
            self.present(navigationViewController, animated: true, completion: nil)
        }
    }
    
    func showChooseTransactionDetailPresent(movingBackwards: Bool, delegate: ChooseTransactionDelegate, transactions: [Transaction], existingTransactions: [Transaction]) {
        let destination = ChooseTransactionTableViewController(networkController: self.networkController)
        destination.movingBackwards = movingBackwards
        destination.delegate = delegate
        destination.transactions = transactions
        destination.existingTransactions = existingTransactions
        let cancelBarButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: destination, action: nil)
        destination.navigationItem.leftBarButtonItem = cancelBarButton
        destination.hidesBottomBarWhenPushed = true
        let navigationViewController = UINavigationController(rootViewController: destination)
        self.present(navigationViewController, animated: true, completion: nil)
    }
    
    func showTransactionRuleDetailPresent(transactionRule: TransactionRule?, transaction: Transaction?, updateDiscoverDelegate: UpdateDiscover?) {
        let destination = FinanceTransactionRuleViewController(networkController: self.networkController)
        destination.transactionRule = transactionRule
        destination.transaction = transaction
        destination.updateDiscoverDelegate = updateDiscoverDelegate
        let cancelBarButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: destination, action: nil)
        destination.navigationItem.leftBarButtonItem = cancelBarButton
        destination.hidesBottomBarWhenPushed = true
        let navigationViewController = UINavigationController(rootViewController: destination)
        self.present(navigationViewController, animated: true, completion: nil)
    }
    
    func showAccountDetailPresent(account: MXAccount?, updateDiscoverDelegate: UpdateDiscover?) {
        let destination = FinanceAccountViewController(networkController: self.networkController)
        destination.account = account
        destination.updateDiscoverDelegate = updateDiscoverDelegate
        ParticipantsFetcher.getParticipants(forAccount: account) { (participants) in
            destination.selectedFalconUsers = participants
            let cancelBarButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: destination, action: nil)
            destination.navigationItem.leftBarButtonItem = cancelBarButton
            destination.hidesBottomBarWhenPushed = true
            let navigationViewController = UINavigationController(rootViewController: destination)
            self.present(navigationViewController, animated: true, completion: nil)
        }
    }
    
    func showHoldingDetailPresent(holding: MXHolding?, updateDiscoverDelegate: UpdateDiscover?) {
        let destination = FinanceHoldingViewController(networkController: self.networkController)
        destination.holding = holding
        destination.updateDiscoverDelegate = updateDiscoverDelegate
        ParticipantsFetcher.getParticipants(forHolding: holding) { (participants) in
            destination.selectedFalconUsers = participants
            let cancelBarButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: destination, action: nil)
            destination.navigationItem.leftBarButtonItem = cancelBarButton
            destination.hidesBottomBarWhenPushed = true
            let navigationViewController = UINavigationController(rootViewController: destination)
            self.present(navigationViewController, animated: true, completion: nil)
        }
    }
    
    func showListDetailPresent(list: ListType?, updateDiscoverDelegate: UpdateDiscover?) {
        let destination = ListDetailViewController(networkController: self.networkController)
        destination.list = list
        destination.updateDiscoverDelegate = updateDiscoverDelegate
        ParticipantsFetcher.getParticipants(forList: list) { (participants) in
            destination.selectedFalconUsers = participants
            let cancelBarButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: destination, action: nil)
            destination.navigationItem.leftBarButtonItem = cancelBarButton
            destination.hidesBottomBarWhenPushed = true
            let navigationViewController = UINavigationController(rootViewController: destination)
            self.present(navigationViewController, animated: true, completion: nil)
        }
    }
    
    func showCalendarDetailPresent(calendar: CalendarType?, updateDiscoverDelegate: UpdateDiscover?) {
        let destination = CalendarDetailViewController(networkController: self.networkController)
        destination.calendar = calendar
        destination.updateDiscoverDelegate = updateDiscoverDelegate
        ParticipantsFetcher.getParticipants(forCalendar: calendar) { (participants) in
            destination.selectedFalconUsers = participants
            let cancelBarButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: destination, action: nil)
            destination.navigationItem.leftBarButtonItem = cancelBarButton
            destination.hidesBottomBarWhenPushed = true
            let navigationViewController = UINavigationController(rootViewController: destination)
            self.present(navigationViewController, animated: true, completion: nil)
        }
    }
    
    func showWorkoutDetailPresent(workout: Workout?, updateDiscoverDelegate: UpdateDiscover?, delegate: UpdateWorkoutDelegate?, template: Template?, users: [User]?, container: Container?, movingBackwards: Bool?) {
        let destination = WorkoutViewController(networkController: self.networkController)
        destination.workout = workout
        destination.template = template
        destination.updateDiscoverDelegate = updateDiscoverDelegate
        destination.delegate = delegate
        destination.container = container
        destination.movingBackwards = movingBackwards ?? false
        if let users = users {
            destination.users = users
            destination.filteredUsers = users
        }
        ParticipantsFetcher.getParticipants(forWorkout: workout) { (participants) in
            destination.selectedFalconUsers = participants
            let cancelBarButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: destination, action: nil)
            destination.navigationItem.leftBarButtonItem = cancelBarButton
            destination.hidesBottomBarWhenPushed = true
            let navigationViewController = UINavigationController(rootViewController: destination)
            self.present(navigationViewController, animated: true, completion: nil)
        }
    }
    
    func showMindfulnessDetailPresent(mindfulness: Mindfulness?, updateDiscoverDelegate: UpdateDiscover?, delegate: UpdateMindfulnessDelegate?, template: Template?, users: [User]?, container: Container?, movingBackwards: Bool?) {
        let destination = MindfulnessViewController(networkController: self.networkController)
        destination.mindfulness = mindfulness
        destination.template = template
        destination.updateDiscoverDelegate = updateDiscoverDelegate
        destination.delegate = delegate
        destination.container = container
        destination.movingBackwards = movingBackwards ?? false
        if let users = users {
            destination.users = users
            destination.filteredUsers = users
        }
        ParticipantsFetcher.getParticipants(forMindfulness: mindfulness) { (participants) in
            destination.selectedFalconUsers = participants
            let cancelBarButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: destination, action: nil)
            destination.navigationItem.leftBarButtonItem = cancelBarButton
            destination.hidesBottomBarWhenPushed = true
            let navigationViewController = UINavigationController(rootViewController: destination)
            self.present(navigationViewController, animated: true, completion: nil)
        }
    }
    
    func showHealthMetricDetailPresent(healthMetric: HealthMetric) {
        let healthDetailService = HealthDetailService()
        let healthDetailViewModel = HealthDetailViewModel(healthMetric: healthMetric, healthDetailService: healthDetailService)
        let healthDetailViewController = HealthDetailViewController(viewModel: healthDetailViewModel, networkController: networkController)
        healthDetailViewController.segmentedControl.selectedSegmentIndex = healthMetric.grabSegment()
        let cancelBarButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: healthDetailViewController, action: nil)
        healthDetailViewController.navigationItem.leftBarButtonItem = cancelBarButton
        healthDetailViewController.hidesBottomBarWhenPushed = true
        let navigationViewController = UINavigationController(rootViewController: healthDetailViewController)
        self.present(navigationViewController, animated: true, completion: nil)
    }
    
    func showTransactionDetailDetailPresent(transactionDetails: TransactionDetails, allTransactions: [Transaction], transactions: [Transaction], filterDictionary: [String]?, selectedIndex: Int?) {
        let financeDetailViewModel = FinanceDetailViewModel(accountDetails: nil, allAccounts: nil, accounts: nil, transactionDetails: transactionDetails, allTransactions: allTransactions, transactions: transactions, filterAccounts: filterDictionary,  financeDetailService: FinanceDetailService())
        let financeDetailViewController = FinanceBarChartDetailViewController(viewModel: financeDetailViewModel, networkController: networkController)
        financeDetailViewController.selectedIndex = selectedIndex ?? 2
        let cancelBarButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: financeDetailViewController, action: nil)
        financeDetailViewController.navigationItem.leftBarButtonItem = cancelBarButton
        financeDetailViewController.hidesBottomBarWhenPushed = true
        let navigationViewController = UINavigationController(rootViewController: financeDetailViewController)
        self.present(navigationViewController, animated: true, completion: nil)
    }
    
    func showAccountDetailDetailPresent(accountDetails: AccountDetails, allAccounts: [MXAccount], accounts: [MXAccount], selectedIndex: Int?) {
        let financeDetailViewModel = FinanceDetailViewModel(accountDetails: accountDetails, allAccounts: allAccounts, accounts: accounts, transactionDetails: nil, allTransactions: nil, transactions: nil, filterAccounts: nil, financeDetailService: FinanceDetailService())
        let financeDetailViewController = FinanceLineChartDetailViewController(viewModel: financeDetailViewModel, networkController: networkController)
        financeDetailViewController.selectedIndex = selectedIndex ?? 2
        financeDetailViewController.hidesBottomBarWhenPushed = true
        let cancelBarButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: financeDetailViewController, action: nil)
        financeDetailViewController.navigationItem.leftBarButtonItem = cancelBarButton
        financeDetailViewController.hidesBottomBarWhenPushed = true
        let navigationViewController = UINavigationController(rootViewController: financeDetailViewController)
        self.present(navigationViewController, animated: true, completion: nil)
    }
    
    func openMXConnect(current_member_guid: String?, delegate: EndedWebViewDelegate) {
        let destination = WebViewController()
        destination.controllerTitle = ""
        destination.current_member_guid = current_member_guid
        destination.delegate = delegate
        destination.hidesBottomBarWhenPushed = true
        let navigationViewController = UINavigationController(rootViewController: destination)
        navigationViewController.modalPresentationStyle = .fullScreen
        self.present(navigationViewController, animated: true, completion: nil)
    }
    
    func openNotification(forNotification notification: PLNotification) {
        let aps = notification.aps
        if let ID = notification.objectID {
            let category = aps.category
            if category == Identifiers.eventCategory {
                if let date = aps.date, let activity = networkController.activityService.events.first(where: { $0.instanceID == ID && Int(truncating: $0.startDateTime ?? 0) == date }) {
                    showEventDetailPresent(event: activity, updateDiscoverDelegate: nil, delegate: nil, task: nil, transaction: nil, workout: nil, mindfulness: nil, template: nil, users: nil, container: nil, startDateTime: nil, endDateTime: nil)
                } else if let activity = networkController.activityService.eventsNoRepeats.first(where: { $0.activityID == ID }) {
                    showEventDetailPresent(event: activity, updateDiscoverDelegate: nil, delegate: nil, task: nil, transaction: nil, workout: nil, mindfulness: nil, template: nil, users: nil, container: nil, startDateTime: nil, endDateTime: nil)
                }
            } else if category == Identifiers.taskCategory {
                if let date = aps.date, let activity = networkController.activityService.tasks.first(where: {$0.instanceID == ID && Int(truncating: $0.endDateTime ?? 0) == date }) {
                    showTaskDetailPresent(task: activity, updateDiscoverDelegate: nil, delegate: nil, event: nil, transaction: nil, workout: nil, mindfulness: nil, template: nil, users: nil, container: nil, list: nil, startDateTime: nil, endDateTime: nil)
                } else if let activity = networkController.activityService.tasksNoRepeats.first(where: {$0.activityID == ID }) {
                    showTaskDetailPresent(task: activity, updateDiscoverDelegate: nil, delegate: nil, event: nil, transaction: nil, workout: nil, mindfulness: nil, template: nil, users: nil, container: nil, list: nil, startDateTime: nil, endDateTime: nil)
                }
            } else if category == Identifiers.goalCategory {
                if let date = aps.date, let activity = networkController.activityService.tasks.first(where: {$0.instanceID == ID && Int(truncating: $0.endDateTime ?? 0) == date }) {
                    showGoalDetailPresent(task: activity, updateDiscoverDelegate: nil, delegate: nil, event: nil, transaction: nil, workout: nil, mindfulness: nil, template: nil, users: nil, container: nil, list: nil, startDateTime: nil, endDateTime: nil)
                } else if let activity = networkController.activityService.tasksNoRepeats.first(where: {$0.activityID == ID }) {
                    showGoalDetailPresent(task: activity, updateDiscoverDelegate: nil, delegate: nil, event: nil, transaction: nil, workout: nil, mindfulness: nil, template: nil, users: nil, container: nil, list: nil, startDateTime: nil, endDateTime: nil)
                }
            } else if category == Identifiers.workoutCategory {
                if let workout = networkController.healthService.workouts.first(where: {$0.id == ID }) {
                    showWorkoutDetailPresent(workout: workout, updateDiscoverDelegate: nil, delegate: nil, template: nil, users: nil, container: nil, movingBackwards: nil)
                }
            } else if category == Identifiers.mindfulnessCategory {
                if let mindfulness = networkController.healthService.mindfulnesses.first(where: {$0.id == ID }) {
                    showMindfulnessDetailPresent(mindfulness: mindfulness, updateDiscoverDelegate: nil, delegate: nil, template: nil, users: nil, container: nil, movingBackwards: nil)
                }
            } else if category == Identifiers.transactionCategory {
                if let transaction = networkController.financeService.transactions.first(where: {$0.guid == ID }) {
                    showTransactionDetailPresent(transaction: transaction, updateDiscoverDelegate: nil, delegate: nil, users: nil, container: nil, movingBackwards: nil)
                }
            } else if category == Identifiers.accountCategory {
                if let account = networkController.financeService.accounts.first(where: {$0.guid == ID }) {
                    showAccountDetailPresent(account: account, updateDiscoverDelegate: nil)
                }
            } else if category == Identifiers.listCategory {
                if let list = networkController.activityService.lists[ListSourceOptions.plot.name]?.first(where: { $0.id == ID }) {
                    showListDetailPresent(list: list, updateDiscoverDelegate: nil)
                }
            } else if category == Identifiers.calendarCategory {
                if let calendar = networkController.activityService.calendars[CalendarSourceOptions.plot.name]?.first(where: { $0.id == ID }) {
                    showCalendarDetailPresent(calendar: calendar, updateDiscoverDelegate: nil)
                }
            }
        }
    }
}
