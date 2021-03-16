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

// Update this file to update nav bar
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
    
    fileprivate var isNewUser = false
    
    let homeController = MasterActivityContainerController()
    let discoverController = DiscoverViewController()
    let settingsController = AccountSettingsController()
    
    lazy var analyticsController: AnalyticsViewController = {
        AnalyticsViewController(viewModel: .init(networkController: networkController))
    }()
    
    var window: UIWindow?
    
    let splashContainer: SplashScreenContainer = {
        let splashContainer = SplashScreenContainer()
        splashContainer.translatesAutoresizingMaskIntoConstraints = false
        return splashContainer
    }()
    
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
        
        homeController.delegate = self
        setOnlineStatus()
        loadVariables()
        configureTabBar()
    }
    
    fileprivate func configureTabBar(){
        UITabBarItem.appearance().setTitleTextAttributes([NSAttributedString.Key.foregroundColor: ThemeManager.currentTheme().generalSubtitleColor], for: .normal)
        tabBar.unselectedItemTintColor = ThemeManager.currentTheme().generalSubtitleColor
        tabBar.barTintColor = ThemeManager.currentTheme().generalTitleColor
        tabBar.isTranslucent = false
        tabBar.layer.borderWidth = 0.50
        tabBar.layer.borderColor = UIColor.clear.cgColor
        tabBar.clipsToBounds = true
        setTabs()
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
    }
    
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
    
    fileprivate func loadVariables() {
        isNewUser = Auth.auth().currentUser == nil
        homeController.isNewUser = isNewUser
        
        let currentAppVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
        let previousVersion = UserDefaults.standard.string(forKey: kAppVersionKey)
                   
        //if new user, do nothing; if existing user with old version of app, load other variables
        //if existing user with current version, load everything
        if !isNewUser {
            if let previousVersion = previousVersion, let currentAppVersion = currentAppVersion, currentAppVersion.compare(previousVersion, options: .numeric) != .orderedDescending {
                networkController.setupKeyVariables {
                    self.homeController.networkController = self.networkController
                    self.discoverController.networkController = self.networkController
                    self.settingsController.networkController = self.networkController
                    self.networkController.setupOtherVariables()
                }
            } else {
                UserDefaults.standard.setValue(currentAppVersion, forKey: kAppVersionKey)
                self.networkController.setupOtherVariables()
            }
        } else {
            UserDefaults.standard.setValue(currentAppVersion, forKey: kAppVersionKey)
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
        
        homeNavigationController.navigationBar.prefersLargeTitles = true
        homeNavigationController.navigationItem.largeTitleDisplayMode = .always
        settingsNavigationController.navigationBar.prefersLargeTitles = true
        settingsNavigationController.navigationItem.largeTitleDisplayMode = .always
        discoverNavigationController.navigationBar.prefersLargeTitles = true
        discoverNavigationController.navigationItem.largeTitleDisplayMode = .always
                
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
        
        let analyticsNavigationController = UINavigationController(rootViewController: analyticsController)
        analyticsNavigationController.navigationBar.prefersLargeTitles = true
        analyticsNavigationController.tabBarItem = UITabBarItem(title: nil,
                                                                image: UIImage(systemName: "chart.pie"),
                                                                selectedImage: UIImage(systemName: "chart.pie.fill"))
        
        let tabBarControllers = [discoverNavigationController,
                                 homeNavigationController,
                                 settingsNavigationController,
                                 analyticsNavigationController]
        viewControllers = tabBarControllers
        selectedIndex = Tabs.home.rawValue
    }
    
    func presentOnboardingController() {
        guard isNewUser else { return }
        let destination = OnboardingController()
        let newNavigationController = UINavigationController(rootViewController: destination)
        newNavigationController.navigationBar.shadowImage = UIImage()
        newNavigationController.navigationBar.setBackgroundImage(UIImage(), for: .default)
        newNavigationController.modalTransitionStyle = .crossDissolve
        newNavigationController.modalPresentationStyle = .fullScreen
        present(newNavigationController, animated: false, completion: nil)
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
    }
}
