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
                self.collectionView.reloadData()
                self.removeLaunchScreenView()
                self.networkController.setupOtherVariables()
            }
        } else {
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
}
