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
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard UIApplication.shared.applicationState == .inactive else {
            return
        }
        
        if self.traitCollection.userInterfaceStyle == .dark {
            let theme = Theme.Dark
            ThemeManager.applyTheme(theme: theme)
        } else if self.traitCollection.userInterfaceStyle == .light {
            let theme = Theme.Default
            ThemeManager.applyTheme(theme: theme)
        }
    }
    
    func loadVariables() {
        isNewUser = Auth.auth().currentUser == nil
        
        networkController.askPermissionToTrack()
        
        let currentAppVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
//        let previousVersion = UserDefaults.standard.string(forKey: kAppVersionKey)
        //if new user, do nothing; if existing user with old version of app, load other variables
        //if existing user with current version, load everything
        if !isNewUser {
            UserDefaults.standard.setValue(currentAppVersion, forKey: kAppVersionKey)
            networkController.setupKeyVariables {
                self.networkController.setupOtherVariables()
                self.collectionView.reloadData()
                self.removeLaunchScreenView()
            }
        } else {
            UserDefaults.standard.setValue(currentAppVersion, forKey: kAppVersionKey)
            self.removeLaunchScreenView()
            self.presentOnboardingController()
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
        launchScreenView.backgroundColor = ThemeManager.currentTheme().launchBackgroundColor
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
