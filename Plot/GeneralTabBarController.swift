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
        configureTabBar()
    }
    
    fileprivate func configureTabBar(){
        print("configureTabBar")
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
    
    fileprivate func addNewUserItems() {
        if let isNewUser = appDelegate.additionalUserInfo?.isNewUser, isNewUser {
            createNewUserActivities()
            sendWelcomeMessage()
        }
    }
    
    func createNewUserActivities() {
        repeat {} while Auth.auth().currentUser?.uid == nil
                
        let currentUserID = Auth.auth().currentUser?.uid
        
        let activityID = Database.database().reference().child("user-activities").child(currentUserID!).childByAutoId().key ?? ""
        let checklistID = Database.database().reference().child(userChecklistsEntity).child(currentUserID!).childByAutoId().key ?? ""
        
        let dispatchGroup = DispatchGroup()
        guard let mainActivitiesUrl = Bundle.main.url(forResource: "NewUserActivities", withExtension: "json") else { return }
        
        do {
            let jsonData = try Data(contentsOf: mainActivitiesUrl)
            let decoder = JSONDecoder()
            let activities = try decoder.decode([Activity].self, from: jsonData)
            
            for activity in activities {
                activity.activityID = activityID
                activity.checklistIDs = [checklistID]
                activity.admin = currentUserID
                activity.participantsIDs = [currentUserID!]
                
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
                        schedule.participantsIDs = [currentUserID!]
                    case "Flight from DUB to EDI":
                        schedule.startDateTime = NSNumber(value: Int((startDateTime.addingTimeInterval(79500)).timeIntervalSince1970))
                        schedule.endDateTime = NSNumber(value: Int((startDateTime.addingTimeInterval(84300)).timeIntervalSince1970))
                        schedule.allDay = false
                        schedule.participantsIDs = [currentUserID!]
                    case "Edinburgh":
                        schedule.startDateTime = NSNumber(value: Int((startDateTime.addingTimeInterval(172800)).timeIntervalSince1970))
                        schedule.endDateTime = NSNumber(value: Int((startDateTime.addingTimeInterval(345600)).timeIntervalSince1970))
                        schedule.allDay = true
                        schedule.participantsIDs = [currentUserID!]
                    case "Aizle Reservation":
                        schedule.startDateTime = NSNumber(value: Int((startDateTime.addingTimeInterval(182400)).timeIntervalSince1970))
                        schedule.endDateTime = NSNumber(value: Int((startDateTime.addingTimeInterval(189600)).timeIntervalSince1970))
                        schedule.allDay = false
                        schedule.participantsIDs = [currentUserID!]
                    case "Kitchin Reservation":
                        schedule.startDateTime = NSNumber(value: Int((startDateTime.addingTimeInterval(268800)).timeIntervalSince1970))
                        schedule.endDateTime = NSNumber(value: Int((startDateTime.addingTimeInterval(276000)).timeIntervalSince1970))
                        schedule.allDay = false
                        schedule.participantsIDs = [currentUserID!]
                    case "St. Andrews":
                        schedule.startDateTime = NSNumber(value: Int((startDateTime.addingTimeInterval(353400)).timeIntervalSince1970))
                        schedule.endDateTime = NSNumber(value: Int((startDateTime.addingTimeInterval(526200)).timeIntervalSince1970))
                        schedule.allDay = true
                        schedule.participantsIDs = [currentUserID!]
                    case "Flight from EDI to DUB":
                        schedule.startDateTime = NSNumber(value: Int((startDateTime.addingTimeInterval(490200)).timeIntervalSince1970))
                        schedule.endDateTime = NSNumber(value: Int((startDateTime.addingTimeInterval(495000)).timeIntervalSince1970))
                        schedule.allDay = false
                        schedule.participantsIDs = [currentUserID!]
                    case "Flight from DUB to EWR":
                        schedule.startDateTime = NSNumber(value: Int((startDateTime.addingTimeInterval(502800)).timeIntervalSince1970))
                        schedule.endDateTime = NSNumber(value: Int((startDateTime.addingTimeInterval(512100)).timeIntervalSince1970))
                        schedule.allDay = false
                        schedule.participantsIDs = [currentUserID!]
                    default:
                        schedule.startDateTime = activity.startDateTime
                        schedule.endDateTime = activity.endDateTime
                        schedule.allDay = false
                        schedule.participantsIDs = [currentUserID!]
                    }
                    dispatchGroup.leave()
                }
                
                
                let activityDict = activity.toAnyObject()
                let activityReference = Database.database().reference().child("activities").child(activityID).child(messageMetaDataFirebaseFolder)
                dispatchGroup.enter()
                activityReference.updateChildValues(activityDict) { (error, reference) in
                    dispatchGroup.leave()
                }
                
                let userReference = Database.database().reference().child("user-activities").child(currentUserID!).child(activityID).child(messageMetaDataFirebaseFolder)
                let values:[String : Any] = ["isGroupActivity": true]
                dispatchGroup.enter()
                userReference.updateChildValues(values, withCompletionBlock: { (error, reference) in
                    dispatchGroup.leave()
                })
            }
        } catch {
            print("new user error")
            print(error)
        }
        
        guard let mainChecklistsUrl = Bundle.main.url(forResource: "NewUserChecklists", withExtension: "json") else { return }
        
        do {
            let jsonData = try Data(contentsOf: mainChecklistsUrl)
            let decoder = JSONDecoder()
            let checklists = try decoder.decode([Checklist].self, from: jsonData)
            
            for checklist in checklists {
                checklist.ID = checklistID
                checklist.activityID = activityID
                checklist.admin = currentUserID
                checklist.participantsIDs = [currentUserID!]
                
                let checklistDict = checklist.toAnyObject()
                let checklistReference = Database.database().reference().child(checklistsEntity).child(checklistID)
                dispatchGroup.enter()
                checklistReference.updateChildValues(checklistDict) { (error, reference) in
                    dispatchGroup.leave()
                }
                
                let userReference = Database.database().reference().child(userChecklistsEntity).child(currentUserID!).child(checklistID)
                let values:[String : Any] = ["isGroupChecklist": true]
                dispatchGroup.enter()
                userReference.updateChildValues(values, withCompletionBlock: { (error, reference) in
                    dispatchGroup.leave()
                })
            }
        } catch {
            print("new user error")
            print(error)
        }
        
        dispatchGroup.notify(queue: .main) {
            self.homeController.activitiesVC.handleReloadTable()
            self.homeController.listsVC.fetchLists()
        }
    }
    
    func sendWelcomeMessage() {
        repeat {} while Auth.auth().currentUser?.uid == nil
        let dispatchGroup = DispatchGroup()
        let currentUserID = Auth.auth().currentUser?.uid
        let chatID = Database.database().reference().child("user-messages").child(currentUserID!).childByAutoId().key ?? ""
        let groupChatsReference = Database.database().reference().child("groupChats").child(chatID).child(messageMetaDataFirebaseFolder)
        let plotUser = "acdmpzhmDWaBdcEo17DRMt8gwCh1"
        let memberIDs = [currentUserID!: currentUserID!, plotUser: plotUser]
        let childValues: [String: AnyObject] = ["chatID": chatID as AnyObject, "chatName": "Plot" as AnyObject, "chatParticipantsIDs": memberIDs as AnyObject, "admin": currentUserID as AnyObject, "adminNeeded": false as AnyObject, "isGroupChat": true as AnyObject]
        
        dispatchGroup.enter()
        groupChatsReference.updateChildValues(childValues)
        dispatchGroup.leave()
        
        for (key, _) in memberIDs {
            dispatchGroup.enter()
            let userReference = Database.database().reference().child("user-messages").child(key).child(chatID).child(messageMetaDataFirebaseFolder)
            let values:[String : Any] = ["isGroupChat": true]
            userReference.updateChildValues(values)
            dispatchGroup.leave()
        }
        
        let text = "Welcome to Plot! If you have any questions, thoughts and/or concerns, just send us a message here! Enjoy Plotting"
//        "Hi, thanks for downloading Plot! I’m the founder of Plot and am reaching out to see if you are available for a quick call (< 20 min) to help improve the product? If so, a $20 Amazon gift card is coming your way. Thanks for reading and enjoying Plotting!"
        let messageReference = Database.database().reference().child("messages").childByAutoId()
        guard let messageUID = messageReference.key else { return }
        let messageStatus = messageStatusDelivered
        let timestamp = NSNumber(value: Int(Date().timeIntervalSince1970))
        let defaultData: [String: AnyObject] = ["messageUID": messageUID as AnyObject,
                                                "toId": chatID as AnyObject,
                                                "status": messageStatus as AnyObject,
                                                "seen": false as AnyObject,
                                                "fromId": plotUser as AnyObject,
                                                "timestamp": timestamp,
                                                "text": text as AnyObject]
        dispatchGroup.enter()
        messageReference.updateChildValues(defaultData)
        dispatchGroup.leave()
        
        for (key, _) in memberIDs {
            dispatchGroup.enter()
            let userReference = Database.database().reference().child("user-messages").child(key).child(chatID).child(userMessagesFirebaseFolder)
            userReference.updateChildValues([messageUID: 1])
            
            let ref = Database.database().reference().child("user-messages").child(key).child(chatID).child(messageMetaDataFirebaseFolder)
            ref.updateChildValues(["lastMessageID": messageUID])
            dispatchGroup.leave()
        }
        
        dispatchGroup.notify(queue: .main) {
            self.homeController.chatsVC.conversationsFetcher.fetchConversations()
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
            self.splashContainer.showSecuredData()
        }
        grabContacts()
        addNewUserItems()
    }
}

extension GeneralTabBarController: ContactsUpdatesDelegate {
    func contacts(updateDatasource contacts: [CNContact]) {
        homeController.contacts = contacts
        homeController.filteredContacts = contacts
        DispatchQueue.global(qos: .default).async {
            self.falconUsersFetcher.fetchFalconUsers(asynchronously: true)
        }
    }
    
    func contacts(handleAccessStatus: Bool) {
        
    }
}

extension GeneralTabBarController: FalconUsersUpdatesDelegate {
    func falconUsers(shouldBeUpdatedTo users: [User]) {
        homeController.users = users
        homeController.filteredUsers = users
        discoverController.users = users
        discoverController.filteredUsers = users
        settingsController.users = users
        settingsController.filteredUsers = users
        globalUsers = users
    }
}
