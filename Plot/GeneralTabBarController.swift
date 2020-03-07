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
    //  case contacts = 0
    case chats = 0
    case activity = 1
    case settings = 2
}

extension NSNotification.Name {
    static let usersUpdated = NSNotification.Name(Bundle.main.bundleIdentifier! + ".usersUpdated")
}

var globalUsers: [User] = [] {
    didSet {
        NotificationCenter.default.post(name: .usersUpdated, object: nil)
    }
}

class GeneralTabBarController: UITabBarController {
    
    var onceToken = 0
    let falconUsersFetcher = FalconUsersFetcher()
    let contactsFetcher = ContactsFetcher()
    let viewPlaceholder = ViewPlaceholder()
    
    fileprivate let appDelegate = UIApplication.shared.delegate as! AppDelegate

    
    fileprivate var isAppLoaded = false
    
    //  let contactsController = ContactsController()
    let activityController = ActivityViewController()
    let chatsController = ChatsTableViewController()
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

        activityController.delegate = self
        chatsController.delegate = self
        setOnlineStatus()
        configureTabBar()
        
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
    
    fileprivate func configureTabBar() {
    UITabBarItem.appearance().setTitleTextAttributes([NSAttributedString.Key.foregroundColor: ThemeManager.currentTheme().generalSubtitleColor], for: .normal)
        tabBar.unselectedItemTintColor = ThemeManager.currentTheme().generalSubtitleColor
        tabBar.isTranslucent = false
        tabBar.layer.borderWidth = 0.50
        tabBar.layer.borderColor = UIColor.clear.cgColor
        tabBar.clipsToBounds = true
        setTabs()
        falconUsersFetcher.delegate = self
        contactsFetcher.delegate = self
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
                        
        if onceToken == 0 {
            splashContainer.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
            splashContainer.navigationBar.barTintColor = ThemeManager.currentTheme().generalBackgroundColor
            splashContainer.viewForSatausbarSafeArea.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
            view.addSubview(splashContainer)
            splashContainer.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
            splashContainer.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
            splashContainer.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
            splashContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        }
        
        onceToken = 1
    }
    
    fileprivate func setTabs() {
        //    contactsController.title = "Contacts"
        activityController.title = "Activities"
        chatsController.title = "Chats"
        settingsController.title = "Settings"
        
        //    let contactsNavigationController = UINavigationController(rootViewController: contactsController)
        let activityNavigationController = UINavigationController(rootViewController: activityController)
        let chatsNavigationController = UINavigationController(rootViewController: chatsController)
        let settingsNavigationController = UINavigationController(rootViewController: settingsController)
        
        if #available(iOS 11.0, *) {
            //      contactsNavigationController.navigationBar.prefersLargeTitles = true
            activityNavigationController.navigationBar.prefersLargeTitles = true
            settingsNavigationController.navigationBar.prefersLargeTitles = true
            chatsNavigationController.navigationBar.prefersLargeTitles = true
        }
        
        //    let contactsImage =  UIImage(named: "user")
        let activityImage = UIImage(named: "activity")
        let chatsImage = UIImage(named: "chat")
        let settingsImage = UIImage(named: "settings")
        
        //    let contactsTabItem = UITabBarItem(title: contactsController.title, image: contactsImage, selectedImage: nil)
        let activityTabItem = UITabBarItem(title: activityController.title, image: activityImage, selectedImage: nil)
        let chatsTabItem = UITabBarItem(title: chatsController.title, image: chatsImage, selectedImage: nil)
        let settingsTabItem = UITabBarItem(title: settingsController.title, image: settingsImage, selectedImage: nil)
        
        //    contactsController.tabBarItem = contactsTabItem
        activityController.tabBarItem = activityTabItem
        chatsController.tabBarItem = chatsTabItem
        settingsController.tabBarItem = settingsTabItem
        
        //    let tabBarControllers = [contactsNavigationController, chatsNavigationController as UIViewController, settingsNavigationController]
        let tabBarControllers = [chatsNavigationController, activityNavigationController as UIViewController,  settingsNavigationController]
        viewControllers = tabBarControllers
        selectedIndex = Tabs.activity.rawValue
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
    
    fileprivate func grabContacts() {
        DispatchQueue.global(qos: .default).async { [unowned self] in
            self.contactsFetcher.fetchContacts()
        }
    }
    
    fileprivate func grabUsers() {
        DispatchQueue.global(qos: .default).async {
            self.falconUsersFetcher.fetchFalconUsers(asynchronously: true)
        }
    }
    
    fileprivate func addSampleActivityForNewUser() {
        if let isNewUser = appDelegate.additionalUserInfo?.isNewUser, isNewUser {
            createNewUserActivities()
        }
    }
    
    func createNewUserActivities() {
        guard let mainUrl = Bundle.main.url(forResource: "NewUserActivities", withExtension: "json") else { return }
        do {
            let jsonData = try Data(contentsOf: mainUrl)
            let decoder = JSONDecoder()
            let activities = try decoder.decode([Activity].self, from: jsonData)

            
            let dispatchGroup = DispatchGroup()
            for activity in activities {
                guard let currentUserID = Auth.auth().currentUser?.uid else {
                    continue
                }
                
                let activityID = Database.database().reference().child("user-activities").child(currentUserID).childByAutoId().key ?? ""
                
                activity.activityID = activityID
                activity.admin = currentUserID
                activity.participantsIDs = [currentUserID]
                                
                var dateComponents = DateComponents()
                dateComponents.year = Date.yearNumber(Date())()
                dateComponents.month = Date.monthNumber(Date())()
                dateComponents.day = Date.dayNumber(Date())()
                dateComponents.timeZone = TimeZone.current
                dateComponents.hour = 17
                dateComponents.minute = 20

                // Create date from components
                let userCalendar = Calendar.current
                let someDateTime = userCalendar.date(from: dateComponents)!

                
                let timezone = TimeZone.current
                let seconds = TimeInterval(timezone.secondsFromGMT(for: someDateTime))
                let startDateTime = Date().addingTimeInterval(seconds)
                let endDateTime = startDateTime.addingTimeInterval(512100)
                activity.startDateTime = NSNumber(value: Int((startDateTime).timeIntervalSince1970))
                activity.endDateTime = NSNumber(value: Int((endDateTime).timeIntervalSince1970))
                activity.allDay = true
                
                for schedule in activity.schedule! {
                    dispatchGroup.enter()
                    switch schedule.name {
                    case "Flight from EWR to DUB":
                        schedule.startDateTime = activity.startDateTime
                        schedule.endDateTime = NSNumber(value: Int((startDateTime.addingTimeInterval(41400)).timeIntervalSince1970))
                        schedule.allDay = false
                        schedule.participantsIDs = [currentUserID]
                    case "Flight from DUB to EDI":
                        schedule.startDateTime = NSNumber(value: Int((startDateTime.addingTimeInterval(79500)).timeIntervalSince1970))
                        schedule.endDateTime = NSNumber(value: Int((startDateTime.addingTimeInterval(84300)).timeIntervalSince1970))
                        schedule.allDay = false
                        schedule.participantsIDs = [currentUserID]
                    case "Edinburgh":
                        schedule.startDateTime = NSNumber(value: Int((startDateTime.addingTimeInterval(172800)).timeIntervalSince1970))
                        schedule.endDateTime = NSNumber(value: Int((startDateTime.addingTimeInterval(345600)).timeIntervalSince1970))
                        schedule.allDay = true
                        schedule.participantsIDs = [currentUserID]
                    case "Aizle Reservation":
                        schedule.startDateTime = NSNumber(value: Int((startDateTime.addingTimeInterval(182400)).timeIntervalSince1970))
                        schedule.endDateTime = NSNumber(value: Int((startDateTime.addingTimeInterval(189600)).timeIntervalSince1970))
                        schedule.allDay = false
                        schedule.participantsIDs = [currentUserID]
                    case "Kitchin Reservation":
                        schedule.startDateTime = NSNumber(value: Int((startDateTime.addingTimeInterval(268800)).timeIntervalSince1970))
                        schedule.endDateTime = NSNumber(value: Int((startDateTime.addingTimeInterval(276000)).timeIntervalSince1970))
                        schedule.allDay = false
                        schedule.participantsIDs = [currentUserID]
                    case "St. Andrews":
                        schedule.startDateTime = NSNumber(value: Int((startDateTime.addingTimeInterval(353400)).timeIntervalSince1970))
                        schedule.endDateTime = NSNumber(value: Int((startDateTime.addingTimeInterval(526200)).timeIntervalSince1970))
                        schedule.allDay = true
                        schedule.participantsIDs = [currentUserID]
                    case "Flight from EDI to DUB":
                        schedule.startDateTime = NSNumber(value: Int((startDateTime.addingTimeInterval(490200)).timeIntervalSince1970))
                        schedule.endDateTime = NSNumber(value: Int((startDateTime.addingTimeInterval(495000)).timeIntervalSince1970))
                        schedule.allDay = false
                        schedule.participantsIDs = [currentUserID]
                    case "Flight from DUB to EWR":
                        schedule.startDateTime = NSNumber(value: Int((startDateTime.addingTimeInterval(502800)).timeIntervalSince1970))
                        schedule.endDateTime = NSNumber(value: Int((startDateTime.addingTimeInterval(512100)).timeIntervalSince1970))
                        schedule.allDay = false
                        schedule.participantsIDs = [currentUserID]
                    default:
                        schedule.startDateTime = activity.startDateTime
                        schedule.endDateTime = activity.endDateTime
                        schedule.allDay = false
                        schedule.participantsIDs = [currentUserID]
                    }
                    dispatchGroup.leave()
                }
                
                                
                let activityDict = activity.toAnyObject()
                let activityReference = Database.database().reference().child("activities").child(activityID).child(messageMetaDataFirebaseFolder)
                dispatchGroup.enter()
                activityReference.updateChildValues(activityDict) { (error, reference) in
                    dispatchGroup.leave()
                }
                
                let userReference = Database.database().reference().child("user-activities").child(currentUserID).child(activityID).child(messageMetaDataFirebaseFolder)
                let values:[String : Any] = ["isGroupActivity": true]
                dispatchGroup.enter()
                userReference.updateChildValues(values, withCompletionBlock: { (error, reference) in
                    dispatchGroup.leave()
                })
            }
            
            dispatchGroup.notify(queue: .main) {
                self.activityController.handleReloadTable()
            }
        } catch {
            print(error)
        }
    }
}

extension GeneralTabBarController: ManageAppearanceChat {
    func manageAppearanceChat(_ chatsController: ChatsTableViewController, didFinishLoadingWith state: Bool) {
        guard !isAppLoaded else { return }
        isAppLoaded = true
        print("manageAppearanceChat")
        let isBiometricalAuthEnabled = userDefaults.currentBoolObjectState(for: userDefaults.biometricalAuth)
        _ = activityController.view
        _ = settingsController.view
        guard state else { return }
        if isBiometricalAuthEnabled {
            splashContainer.authenticationWithTouchID()
        } else {
            self.splashContainer.showSecuredData()
        }
        grabContacts()
        appDelegate.registerForPushNotifications(application: UIApplication.shared)

    }
}

extension GeneralTabBarController: ManageAppearanceActivity {
    func manageAppearanceActivity(_ activityController: ActivityViewController, didFinishLoadingWith state: Bool) {
        guard !isAppLoaded else { return }
        isAppLoaded = true
        print("manageAppearanceActivity")
        let isBiometricalAuthEnabled = userDefaults.currentBoolObjectState(for: userDefaults.biometricalAuth)
        _ = chatsController.view
        _ = settingsController.view
        guard state else { return }
        if isBiometricalAuthEnabled {
            splashContainer.authenticationWithTouchID()
        } else {
            self.splashContainer.showSecuredData()
        }
        grabContacts()
        appDelegate.registerForPushNotifications(application: UIApplication.shared)
        addSampleActivityForNewUser()
    }
}

extension GeneralTabBarController: ContactsUpdatesDelegate {
    func contacts(updateDatasource contacts: [CNContact]) {
        chatsController.contacts = contacts
        chatsController.filteredContacts = contacts
        DispatchQueue.global(qos: .default).async {
            self.falconUsersFetcher.fetchFalconUsers(asynchronously: true)
        }
    }
    
    func contacts(handleAccessStatus: Bool) {
    }
}

extension GeneralTabBarController: FalconUsersUpdatesDelegate {
    func falconUsers(shouldBeUpdatedTo users: [User]) {
        chatsController.users = users
        chatsController.filteredUsers = users
        activityController.users = users
        activityController.filteredUsers = users
        globalUsers = users
    }
}
