//
//  MasterActivityContainerController+StartupMethods.swift
//  Plot
//
//  Created by Cory McHattie on 7/1/22.
//  Copyright © 2022 Immature Creations. All rights reserved.
//

import Foundation
import Firebase

extension NSNotification.Name {
    static let oldUserLoggedIn = NSNotification.Name(Bundle.main.bundleIdentifier! + ".oldUserLoggedIn")
}

extension MasterActivityContainerController {
    
    func loadVariables() {
        isNewUser = Auth.auth().currentUser == nil
        networkController.askPermissionToTrack()
        let currentAppVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
//        let previousVersion = UserDefaults.standard.string(forKey: kAppVersionKey)
        UserDefaults.standard.setValue(currentAppVersion, forKey: kAppVersionKey)
        //if new user, do nothing; if existing user with old version of app, load other variables
        //if existing user with current version, load everything
        self.setupData()
        if !isNewUser {
            networkController.setupKeyVariables {
                self.manageAppearanceHome(didFinishLoadingWith: true)
                self.collectionView.reloadData()
                self.removeLaunchScreenView()
                self.networkController.setupOtherVariables()
                self.openNotification()
            }
        } else {
            self.manageAppearanceHome(didFinishLoadingWith: true)
            self.removeLaunchScreenView()
            self.presentOnboardingController()
        }
    }
    
    @objc func reloadVariables() {
        networkController.setupKeyVariables {
            self.collectionView.reloadData()
            self.networkController.setupOtherVariables()
        }
    }
    
    
    @objc func refreshControlAction(_ refreshControl: UIRefreshControl) {
        networkController.reloadKeyVariables {
            DispatchQueue.main.async {
                self.collectionView.reloadData()
                self.refreshControl.endRefreshing()
            }
        }
    }
    
    func presentOnboardingController() {
        let destination = OnboardingController()
        let newNavigationController = UINavigationController(rootViewController: destination)
        newNavigationController.navigationBar.shadowImage = UIImage()
        newNavigationController.navigationBar.setBackgroundImage(UIImage(), for: .default)
        newNavigationController.modalTransitionStyle = .crossDissolve
        newNavigationController.modalPresentationStyle = .fullScreen
        self.removeLaunchScreenView()
        present(newNavigationController, animated: false, completion: nil)
    }
    
    func showLaunchScreen() {
        launchScreenView.backgroundColor = .systemGroupedBackground
        navigationController?.view.addSubview(launchScreenView)
        launchScreenView.fillSuperview()
        launchScreenView.addSubview(plotLogoView)
        plotLogoView.heightAnchor.constraint(equalToConstant: 310).isActive = true
        plotLogoView.widthAnchor.constraint(equalToConstant: 310).isActive = true
        plotLogoView.centerXAnchor.constraint(equalTo: launchScreenView.centerXAnchor).isActive = true
        plotLogoView.centerYAnchor.constraint(equalTo: launchScreenView.centerYAnchor).isActive = true
    }
    
    func removeLaunchScreenView() {
        DispatchQueue.main.async {
            self.launchScreenView.removeFromSuperview()
        }
    }
    
    func manageAppearanceHome(didFinishLoadingWith state: Bool) {
        guard !isAppLoaded else { return }
        isAppLoaded = true
        let isBiometricalAuthEnabled = userDefaults.currentBoolObjectState(for: userDefaults.biometricalAuth)
        guard state else { return }
        if isBiometricalAuthEnabled {
            splashContainer.authenticationWithTouchID()
        } else {
            splashContainer.showSecuredData()
        }
    }
    
    func openNotification() {
        print("openNotification")
        if let notification = notification {
            let aps = notification.aps
            if let ID = notification.objectID {
                self.notification = nil
                let category = aps.category
                if category == Identifiers.eventCategory {
                    if let date = aps.date, let activity = networkController.activityService.events.first(where: {$0.instanceID == ID && Int(truncating: $0.startDateTime ?? 0) == date }) {
                        ParticipantsFetcher.getParticipants(forActivity: activity) { (participants) in
                            ParticipantsFetcher.getAcceptedParticipant(forActivity: activity, allParticipants: participants) { acceptedParticipant in
                                let destination = EventViewController(networkController: self.networkController)
                                destination.acceptedParticipant = acceptedParticipant
                                destination.selectedFalconUsers = participants
                                destination.activity = activity
                                destination.hidesBottomBarWhenPushed = true
                                let cancelBarButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: destination, action: nil)
                                destination.navigationItem.leftBarButtonItem = cancelBarButton
                                let navigationViewController = UINavigationController(rootViewController: destination)
                                self.present(navigationViewController, animated: true)
                            }
                        }
                    } else if let activity = networkController.activityService.events.first(where: {$0.activityID == ID }) {
                        ParticipantsFetcher.getParticipants(forActivity: activity) { (participants) in
                            ParticipantsFetcher.getAcceptedParticipant(forActivity: activity, allParticipants: participants) { acceptedParticipant in
                                let destination = EventViewController(networkController: self.networkController)
                                destination.acceptedParticipant = acceptedParticipant
                                destination.selectedFalconUsers = participants
                                destination.activity = activity
                                destination.hidesBottomBarWhenPushed = true
                                let cancelBarButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: destination, action: nil)
                                destination.navigationItem.leftBarButtonItem = cancelBarButton
                                let navigationViewController = UINavigationController(rootViewController: destination)
                                self.present(navigationViewController, animated: true)
                            }
                        }
                    }
                } else if category == Identifiers.taskCategory {
                    if let date = aps.date, let activity = networkController.activityService.tasks.first(where: {$0.instanceID == ID && Int(truncating: $0.endDateTime ?? 0) == date }) {
                        ParticipantsFetcher.getParticipants(forActivity: activity) { (participants) in
                            let destination = TaskViewController(networkController: self.networkController)
                            destination.selectedFalconUsers = participants
                            destination.task = activity
                            destination.hidesBottomBarWhenPushed = true
                            let cancelBarButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: destination, action: nil)
                            destination.navigationItem.leftBarButtonItem = cancelBarButton
                            let navigationViewController = UINavigationController(rootViewController: destination)
                            self.present(navigationViewController, animated: true)
                        }
                    } else if let activity = networkController.activityService.tasks.first(where: {$0.activityID == ID }) {
                        ParticipantsFetcher.getParticipants(forActivity: activity) { (participants) in
                            let destination = TaskViewController(networkController: self.networkController)
                            destination.selectedFalconUsers = participants
                            destination.task = activity
                            destination.hidesBottomBarWhenPushed = true
                            let cancelBarButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: destination, action: nil)
                            destination.navigationItem.leftBarButtonItem = cancelBarButton
                            let navigationViewController = UINavigationController(rootViewController: destination)
                            self.present(navigationViewController, animated: true)
                        }
                    }
                } else if category == Identifiers.workoutCategory {
                    if let workout = networkController.healthService.workouts.first(where: {$0.id == ID }) {
                        ParticipantsFetcher.getParticipants(forWorkout: workout) { (participants) in
                            let destination = WorkoutViewController(networkController: self.networkController)
                            destination.selectedFalconUsers = participants
                            destination.workout = workout
                            destination.hidesBottomBarWhenPushed = true
                            let cancelBarButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: destination, action: nil)
                            destination.navigationItem.leftBarButtonItem = cancelBarButton
                            let navigationViewController = UINavigationController(rootViewController: destination)
                            self.present(navigationViewController, animated: true)
                        }
                    }
                } else if category == Identifiers.mindfulnessCategory {
                    if let mindfulness = networkController.healthService.mindfulnesses.first(where: {$0.id == ID }) {
                        ParticipantsFetcher.getParticipants(forMindfulness: mindfulness) { (participants) in
                            let destination = MindfulnessViewController(networkController: self.networkController)
                            destination.selectedFalconUsers = participants
                            destination.mindfulness = mindfulness
                            destination.hidesBottomBarWhenPushed = true
                            let cancelBarButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: destination, action: nil)
                            destination.navigationItem.leftBarButtonItem = cancelBarButton
                            let navigationViewController = UINavigationController(rootViewController: destination)
                            self.present(navigationViewController, animated: true)
                        }
                    }
                } else if category == Identifiers.transactionCategory {
                    if let transaction = networkController.financeService.transactions.first(where: {$0.guid == ID }) {
                        ParticipantsFetcher.getParticipants(forTransaction: transaction) { (participants) in
                            let destination = FinanceTransactionViewController(networkController: self.networkController)
                            destination.selectedFalconUsers = participants
                            destination.transaction = transaction
                            destination.hidesBottomBarWhenPushed = true
                            let cancelBarButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: destination, action: nil)
                            destination.navigationItem.leftBarButtonItem = cancelBarButton
                            let navigationViewController = UINavigationController(rootViewController: destination)
                            self.present(navigationViewController, animated: true)
                        }
                    }
                } else if category == Identifiers.accountCategory {
                    if let account = networkController.financeService.accounts.first(where: {$0.guid == ID }) {
                        ParticipantsFetcher.getParticipants(forAccount: account) { (participants) in
                            let destination = FinanceAccountViewController(networkController: self.networkController)
                            destination.selectedFalconUsers = participants
                            destination.account = account
                            destination.hidesBottomBarWhenPushed = true
                            let cancelBarButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: destination, action: nil)
                            destination.navigationItem.leftBarButtonItem = cancelBarButton
                            let navigationViewController = UINavigationController(rootViewController: destination)
                            self.present(navigationViewController, animated: true)
                        }
                    }
                } else if category == Identifiers.listCategory {
                    if let list = networkController.activityService.lists[ListSourceOptions.plot.name]?.first(where: { $0.id == ID }) {
                        ParticipantsFetcher.getParticipants(forList: list) { (participants) in
                            let destination = ListDetailViewController(networkController: self.networkController)
                            destination.selectedFalconUsers = participants
                            destination.list = list
                            destination.hidesBottomBarWhenPushed = true
                            let cancelBarButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: destination, action: nil)
                            destination.navigationItem.leftBarButtonItem = cancelBarButton
                            let navigationViewController = UINavigationController(rootViewController: destination)
                            self.present(navigationViewController, animated: true)
                        }
                    }
                } else if category == Identifiers.calendarCategory {
                    if let calendar = networkController.activityService.calendars[CalendarSourceOptions.plot.name]?.first(where: { $0.id == ID }) {
                        ParticipantsFetcher.getParticipants(forCalendar: calendar) { (participants) in
                            let destination = CalendarDetailViewController(networkController: self.networkController)
                            destination.selectedFalconUsers = participants
                            destination.calendar = calendar
                            destination.hidesBottomBarWhenPushed = true
                            let cancelBarButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: destination, action: nil)
                            destination.navigationItem.leftBarButtonItem = cancelBarButton
                            let navigationViewController = UINavigationController(rootViewController: destination)
                            self.present(navigationViewController, animated: true)
                        }
                    }
                }
            }
        }
    }
}
