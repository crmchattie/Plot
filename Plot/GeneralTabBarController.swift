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

extension NSNotification.Name {
    static let oldUserLoggedIn = NSNotification.Name(Bundle.main.bundleIdentifier! + ".oldUserLoggedIn")
}

class GeneralTabBarController: UITabBarController {
    
    var onceToken = 0
    static let networkController = NetworkController()
    
    fileprivate let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    fileprivate var isAppLoaded = false
    
    fileprivate var isNewUser = false
    fileprivate var isOldUser = false
    
    let homeController = MasterActivityContainerController(networkController: GeneralTabBarController.networkController)
    let discoverController = LibraryViewController(networkController: GeneralTabBarController.networkController)
    let analyticsController = AnalyticsViewController()
    
    let splashContainer: SplashScreenContainer = {
        let splashContainer = SplashScreenContainer()
        splashContainer.translatesAutoresizingMaskIntoConstraints = false
        return splashContainer
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        homeController.delegate = self
        loadVariables()
        configureTabBar()
        setTabs()
        addObservers()
        appDelegate.loadNotifications()
        setApplicationBadge()
        setOnlineStatus()
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
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if isNewUser && Auth.auth().currentUser != nil {
            //has to be here given currentUserID = nil on app start
            GeneralTabBarController.networkController.setupFirebase()
            GeneralTabBarController.networkController.setupOtherVariables()
//            discoverController.fetchTemplates()
            analyticsController.viewModel = .init(networkController: GeneralTabBarController.networkController)
            //change to stop from running
            isNewUser = false
        } else if isOldUser {
            reloadVariables()
        }
    }
    
    @objc fileprivate func oldUserLoggedIn() {
        isOldUser = true
        homeController.isOldUser = isOldUser
    }
    
    fileprivate func loadVariables() {
        isNewUser = Auth.auth().currentUser == nil
        homeController.isNewUser = isNewUser
        homeController.addObservers()
        GeneralTabBarController.networkController.askPermissionToTrack()
        let currentAppVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
//        let previousAppVersion = UserDefaults.standard.string(forKey: kAppVersionKey)
        //if new user, do nothing; if existing user with old version of app, load other variables
        //if existing user with current version, load everything
        if !isNewUser {
            UserDefaults.standard.setValue(currentAppVersion, forKey: kAppVersionKey)
            GeneralTabBarController.networkController.setupKeyVariables {
                self.analyticsController.viewModel = .init(networkController: GeneralTabBarController.networkController)
                self.homeController.removeLaunchScreenView(animated: true) {
                    self.homeController.openNotification()
                    GeneralTabBarController.networkController.setupOtherVariables()
                    GeneralTabBarController.networkController.setupInitialGoals()
                    
//                    if let currentAppVersion = currentAppVersion, let previousAppVersion = previousAppVersion, previousAppVersion.compare(currentAppVersion) == .orderedAscending {
//                        GeneralTabBarController.networkController.setupInitialGoals()
//                    }
                }
            }
        } else {
            UserDefaults.standard.setValue(currentAppVersion, forKey: kAppVersionKey)
            self.presentOnboardingController()
        }
    }
    
    @objc func reloadVariables() {
        GeneralTabBarController.networkController.setupKeyVariables {
            GeneralTabBarController.networkController.setupOtherVariables()
            GeneralTabBarController.networkController.setupInitialGoals()
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    fileprivate func addObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(oldUserLoggedIn), name: .oldUserLoggedIn, object: nil)
    }
    
    func setApplicationBadge() {
        let badge = 0
        UIApplication.shared.applicationIconBadgeNumber = badge
        if let uid = Auth.auth().currentUser?.uid {
            let ref = Database.database().reference().child("users").child(uid)
            ref.updateChildValues(["badge": badge])
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
    
    fileprivate func setTabs() {
        let tabBarControllers = [
            wrapInNavigationController(analyticsController,
                                       icon: UIImage(named: "chart")!),
            wrapInNavigationController(homeController, icon: UIImage(named: "home")!),
            wrapInNavigationController(discoverController, icon: UIImage(named: "plusTab")!)
        ]
        viewControllers = tabBarControllers
        selectedIndex = Tabs.home.rawValue
    }
    
    func presentOnboardingController() {
        let destination = OnboardingController()
        let newNavigationController = UINavigationController(rootViewController: destination)
        newNavigationController.navigationBar.shadowImage = UIImage()
        newNavigationController.navigationBar.setBackgroundImage(UIImage(), for: .default)
        newNavigationController.modalTransitionStyle = .crossDissolve
        newNavigationController.modalPresentationStyle = .fullScreen
        homeController.removeLaunchScreenView(animated: false) {
            self.present(newNavigationController, animated: false, completion: nil)
        }
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .default
    }
}

extension GeneralTabBarController: ManageAppearanceHome {
    func manageAppearanceHome(_ homeController: MasterActivityContainerController, didFinishLoadingWith state: Bool) {
        guard !isAppLoaded else { return }
        isAppLoaded = true
        let isBiometricalAuthEnabled = userDefaults.currentBoolObjectState(for: userDefaults.biometricalAuth)
        _ = discoverController.view
        guard state else { return }
        if isBiometricalAuthEnabled {
            splashContainer.authenticationWithTouchID()
        } else {
            splashContainer.showSecuredData()
        }
    }
}
