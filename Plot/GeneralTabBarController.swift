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
    let settingsController = AccountSettingsController()
    let analyticsController = AnalyticsViewController()
    
    let splashContainer: SplashScreenContainer = {
        let splashContainer = SplashScreenContainer()
        splashContainer.translatesAutoresizingMaskIntoConstraints = false
        return splashContainer
    }()
    
    let launchScreenView: UIView = {
        let launchScreenView = UIView()
        launchScreenView.translatesAutoresizingMaskIntoConstraints = false
        launchScreenView.layer.masksToBounds = true
        return launchScreenView
    }()
    
    let plotLogoView: UIImageView = {
        let plotLogoView = UIImageView()
        plotLogoView.translatesAutoresizingMaskIntoConstraints = false
        plotLogoView.layer.masksToBounds = true
        plotLogoView.image = UIImage(named: "plotLogo")
        return plotLogoView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        appDelegate.loadNotifications()
        
        homeController.delegate = self
        setOnlineStatus()
        loadVariables()
        configureTabBar()
        setTabs()
    }
    
    fileprivate func configureTabBar(){
        UITabBarItem.appearance().setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.secondaryLabel], for: .normal)
        tabBar.unselectedItemTintColor = .secondaryLabel
        tabBar.barTintColor = .systemGroupedBackground
        tabBar.barStyle = .default
        tabBar.isTranslucent = false
        tabBar.layer.borderWidth = 0.50
        tabBar.layer.borderColor = UIColor.clear.cgColor
        tabBar.clipsToBounds = true
        
        if #available(iOS 15, *) {
            let tabBarApperance = UITabBarAppearance()
            tabBarApperance.configureWithOpaqueBackground()
            tabBarApperance.backgroundColor = .systemGroupedBackground
            UITabBar.appearance().barTintColor = .systemGroupedBackground
            UITabBar.appearance().scrollEdgeAppearance = tabBarApperance
            UITabBar.appearance().standardAppearance = tabBarApperance
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if onceToken == 0 {
            splashContainer.backgroundColor = .systemGroupedBackground
            view.addSubview(splashContainer)
            splashContainer.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
            splashContainer.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
            splashContainer.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
            splashContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        }
        onceToken = 1
    }
    
    fileprivate func loadVariables() {
        isNewUser = Auth.auth().currentUser == nil
        homeController.isNewUser = isNewUser
        
        networkController.askPermissionToTrack()
        
        let currentAppVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
//        let previousVersion = UserDefaults.standard.string(forKey: kAppVersionKey)
        //if new user, do nothing; if existing user with old version of app, load other variables
        //if existing user with current version, load everything
        if !isNewUser {
            UserDefaults.standard.setValue(currentAppVersion, forKey: kAppVersionKey)
            networkController.setupKeyVariables {
                self.homeController.networkController = self.networkController
                self.settingsController.networkController = self.networkController
                self.analyticsController.viewModel = .init(networkController: self.networkController)
                self.networkController.setupOtherVariables()
                self.removeLaunchScreenView()
            }
        } else {
            UserDefaults.standard.setValue(currentAppVersion, forKey: kAppVersionKey)
            self.removeLaunchScreenView()
        }
    }
    
    private func wrapInNavigationController(
        _ viewController: UIViewController,
        icon: UIImage,
        selectedIcon: UIImage? = nil
    ) -> UINavigationController {
        let controller = UINavigationController(rootViewController: viewController)
        controller.navigationBar.prefersLargeTitles = true
        controller.navigationItem.largeTitleDisplayMode = .always
        controller.navigationBar.backgroundColor = .systemGroupedBackground
        let tabBarItem = UITabBarItem(title: nil, image: icon, selectedImage: selectedIcon)
        tabBarItem.imageInsets = UIEdgeInsets(top: 6, left: 0, bottom: -6, right: 0)
        controller.tabBarItem = tabBarItem
        return controller
    }
    
    fileprivate func setTabs() {
        let tabBarControllers = [
            wrapInNavigationController(analyticsController,
                                       icon: UIImage(named: "chart")!),
            wrapInNavigationController(homeController, icon: UIImage(named: "home")!),
            wrapInNavigationController(settingsController, icon: UIImage(named: "settings")!)
        ]
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
        self.removeLaunchScreenView()
        present(newNavigationController, animated: false, completion: nil)
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .default
    }
    
    func showLaunchScreen() {
        launchScreenView.backgroundColor = .secondarySystemGroupedBackground
        view.addSubview(launchScreenView)
        launchScreenView.fillSuperview()
        launchScreenView.addSubview(plotLogoView)
        plotLogoView.heightAnchor.constraint(equalToConstant: 310).isActive = true
        plotLogoView.widthAnchor.constraint(equalToConstant: 310).isActive = true
        plotLogoView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        plotLogoView.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
    }
    
    func removeLaunchScreenView() {
        DispatchQueue.main.async {
            self.launchScreenView.removeFromSuperview()
        }
    }
}

extension GeneralTabBarController: ManageAppearanceHome {
    func manageAppearanceHome(_ homeController: MasterActivityContainerController, didFinishLoadingWith state: Bool) {
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
