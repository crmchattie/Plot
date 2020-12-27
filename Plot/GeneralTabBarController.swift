//
//  GeneralTabBarController.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 8/2/17.
//  Copyright © 2017 Roman Mizin. All rights reserved.
//

import UIKit
import Firebase
import Contacts

//update this file to update nav bar

enum Tabs: Int {
    case discover = 0
    case home = 1
    case settings = 2
}

class GeneralTabBarController: UITabBarController {
    
    var onceToken = 0
    let networkController = NetworkController()
    
    fileprivate let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    fileprivate var isAppLoaded = false
    
    let homeController = MasterActivityContainerController()
    let discoverController = DiscoverViewController()
    let settingsController = AccountSettingsController()
    
    var window: UIWindow?
    
    let splashContainer: SplashScreenContainer = {
        let splashContainer = SplashScreenContainer()
        splashContainer.translatesAutoresizingMaskIntoConstraints = false
        return splashContainer
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if #available(iOS 12.0, *) {
            if self.traitCollection.userInterfaceStyle == .dark {
                let theme = Theme.Dark
                ThemeManager.applyTheme(theme: theme)
            } else {
                let theme = Theme.Default
                ThemeManager.applyTheme(theme: theme)
            }
        } else {
            // Fallback on earlier versions
        }
        
        appDelegate.loadNotifications()
        
        homeController.delegate = self
        setOnlineStatus()
        
        networkController.setupVariables {
            print("variables setup")
            self.homeController.networkController = self.networkController
            self.discoverController.networkController = self.networkController
            self.settingsController.networkController = self.networkController
        }
        configureTabBar()
    }
    
    fileprivate func configureTabBar(){
        UITabBarItem.appearance().setTitleTextAttributes([NSAttributedString.Key.foregroundColor: ThemeManager.currentTheme().generalSubtitleColor], for: .normal)
        tabBar.unselectedItemTintColor = ThemeManager.currentTheme().generalSubtitleColor
        tabBar.isTranslucent = false
        tabBar.layer.borderWidth = 0.50
        tabBar.layer.borderColor = UIColor.clear.cgColor
        tabBar.clipsToBounds = true
        setTabs()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if onceToken == 0 {
            print("token equals 0")
            splashContainer.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
            splashContainer.navigationBar.barTintColor = ThemeManager.currentTheme().generalBackgroundColor
            splashContainer.viewForSatausbarSafeArea.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
            view.addSubview(splashContainer)
            splashContainer.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
            splashContainer.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
            splashContainer.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
            splashContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        }
        print("token equals 1")
        onceToken = 1
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard UIApplication.shared.applicationState == .inactive else {
            return
        }
        
        if #available(iOS 12.0, *) {
            if self.traitCollection.userInterfaceStyle == .dark {
                let theme = Theme.Dark
                ThemeManager.applyTheme(theme: theme)
            } else if self.traitCollection.userInterfaceStyle == .light {
                let theme = Theme.Default
                ThemeManager.applyTheme(theme: theme)
            }
        } else {
            // Fallback on earlier versions
        }
    }
    
    fileprivate func setTabs() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE, MMM d"
        let dateString = dateFormatter.string(from: Date())
        
        homeController.title = dateString
        discoverController.title = "Discover"
        settingsController.title = "Settings"
                
        let homeNavigationController = UINavigationController(rootViewController: homeController)
        let discoverNavigationController = UINavigationController(rootViewController: discoverController)
        let settingsNavigationController = UINavigationController(rootViewController: settingsController)
        
        if #available(iOS 11.0, *) {
            homeNavigationController.navigationBar.prefersLargeTitles = true
            settingsNavigationController.navigationBar.prefersLargeTitles = true
            discoverNavigationController.navigationBar.prefersLargeTitles = true
        }
        
        let homeImage = UIImage(named: "home")
        let discoverImage = UIImage(named: "discover")
        let settingsImage = UIImage(named: "settings")
        
        let homeTabItem = UITabBarItem(title: nil, image: homeImage, selectedImage: nil)
        homeTabItem.imageInsets = UIEdgeInsets(top: 6, left: 0, bottom: -6, right: 0)
        
        let discoverTabItem = UITabBarItem(title: nil, image: discoverImage, selectedImage: nil)
        discoverTabItem.imageInsets = UIEdgeInsets(top: 6, left: 0, bottom: -6, right: 0)
        
        let settingsTabItem = UITabBarItem(title: nil, image: settingsImage, selectedImage: nil)
        settingsTabItem.imageInsets = UIEdgeInsets(top: 6, left: 0, bottom: -6, right: 0)
        
        homeController.tabBarItem = homeTabItem
        discoverController.tabBarItem = discoverTabItem
        settingsController.tabBarItem = settingsTabItem
        
        let tabBarControllers = [discoverNavigationController, homeNavigationController as UIViewController,  settingsNavigationController]
        viewControllers = tabBarControllers
        selectedIndex = Tabs.home.rawValue
    }
    
    func presentOnboardingController() {
        guard Auth.auth().currentUser == nil else { return }
        let destination = OnboardingController()
        let newNavigationController = UINavigationController(rootViewController: destination)
        newNavigationController.navigationBar.shadowImage = UIImage()
        newNavigationController.navigationBar.setBackgroundImage(UIImage(), for: .default)
        newNavigationController.modalTransitionStyle = .crossDissolve
        newNavigationController.modalPresentationStyle = .fullScreen
        present(newNavigationController, animated: false, completion: nil)
    }
    
    fileprivate func addNewUserItems() {
        if let isNewUser = appDelegate.additionalUserInfo?.isNewUser, isNewUser {
            networkController.createNewUserActivities()
            networkController.sendWelcomeMessage()
        }
    }
}

extension GeneralTabBarController: ManageAppearanceHome {
    func manageAppearanceHome(_ homeController: MasterActivityContainerController, didFinishLoadingWith state: Bool) {
        guard !isAppLoaded else { return }
        isAppLoaded = true
        print("manageAppearanceHome")
        let isBiometricalAuthEnabled = userDefaults.currentBoolObjectState(for: userDefaults.biometricalAuth)
        _ = discoverController.view
        _ = settingsController.view
        guard state else { return }
        if isBiometricalAuthEnabled {
            splashContainer.authenticationWithTouchID()
        } else {
            splashContainer.showSecuredData()
        }
        addNewUserItems()
    }
}
