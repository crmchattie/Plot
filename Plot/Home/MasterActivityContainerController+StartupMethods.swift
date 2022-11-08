//
//  MasterActivityContainerController+StartupMethods.swift
//  Plot
//
//  Created by Cory McHattie on 7/1/22.
//  Copyright © 2022 Immature Creations. All rights reserved.
//

import Foundation
import Firebase

extension MasterActivityContainerController {
    
    
//    func showLaunchScreen() {
//        launchController.modalPresentationStyle = .fullScreen
//        launchController.hidesBottomBarWhenPushed = true
//        self.present(launchController, animated: false, completion: nil)
//    }
//
//    func removeLaunchScreenView(animated: Bool, _ completion: @escaping () -> Void) {
//        DispatchQueue.main.async {
//            self.launchController.dismiss(animated: animated, completion: completion)
//        }
//    }
    
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
                self.networkController.setupOtherVariables()
                self.removeLaunchScreenView()
                self.openNotification()
            }
        } else {
            self.presentOnboardingController()
            self.manageAppearanceHome(didFinishLoadingWith: true)
        }
    }
    
    @objc func reloadVariables() {
        networkController.setupKeyVariables {
            self.collectionView.reloadData()
            self.networkController.setupOtherVariables()
        }
    }

    func presentOnboardingController() {
        let destination = OnboardingController()
        let newNavigationController = UINavigationController(rootViewController: destination)
        newNavigationController.modalTransitionStyle = .crossDissolve
        newNavigationController.modalPresentationStyle = .fullScreen
        self.removeLaunchScreenView()
        present(newNavigationController, animated: false, completion: nil)
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
    
    @objc func refreshControlAction(_ refreshControl: UIRefreshControl) {
        networkController.reloadKeyVariables {
            DispatchQueue.main.async {
                self.collectionView.reloadData()
                self.refreshControl.endRefreshing()
            }
        }
    }
    
    func openNotification() {
        print("openNotification")
        //remove to open notifications
        if let notification = notification {
            self.notification = nil
            openNotification(forNotification: notification)
            print(notification)
        }
    }
}
