//
//  AppDelegate.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 8/2/17.
//  Copyright © 2017 Roman Mizin. All rights reserved.
//

import UIKit
import Firebase
import UserNotifications
import CodableFirebase
import GoogleSignIn
import FacebookCore

enum Identifiers {
    static let eventCategory = "EVENT_CATEGORY"
    static let taskCategory = "TASK_CATEGORY"
    static let workoutCategory = "WORKOUT_CATEGORY"
    static let mindfulnessCategory = "MINDFULNESS_CATEGORY"
    static let transactionCategory = "TRANSACTION_CATEGORY"
    static let accountCategory = "ACCOUNT_CATEGORY"
    static let listCategory = "LIST_CATEGORY"
    static let calendarCategory = "CALENDAR_CATEGORY"
    
//    static let viewEventsAction = "VIEW_EVENTS_IDENTIFIER"
//
//    static let viewChatsAction = "VIEW_CHAT_IDENTIFIER"
//    static let viewListsAction = "VIEW_LISTS_IDENTIFIER"
//    static let replyAction = "REPLY_ACTION"
//    static let chatCategory = "CHAT_CATEGORY"
//    static let checklistCategory = "CHECKLIST_CATEGORY"
//    static let grocerylistCategory = "GROCERYLIST_CATEGORY"
//    static let activitylistCategory = "ACTIVITYLIST_CATEGORY"
//    static let mealCategory = "MEAL_CATEGORY"
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    var notifications: [PLNotification] = []
    var participants: [String: [User]] = [:]
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        FirebaseApp.configure()
        Database.database().isPersistenceEnabled = true
        userDefaults.configureInitialLaunch()
        GIDSignIn.sharedInstance().clientID = "433321796976-14dht5ecttj96dnltoj7cf0arfr7e6bo.apps.googleusercontent.com"
        GIDSignIn.sharedInstance().scopes = googleScopes
        GIDSignIn.sharedInstance()?.restorePreviousSignIn()
        //manually create window or default controller, thus ridding of Storyboard
        let masterController = MasterActivityContainerController()
        let controller = UINavigationController(rootViewController: masterController)
        controller.navigationBar.prefersLargeTitles = true
        controller.navigationItem.largeTitleDisplayMode = .always
        
        // set-up window
        window = UIWindow(frame: UIScreen.main.bounds)
        //set window = tabBarController
        window?.rootViewController = controller
        //make window visible
        window?.makeKeyAndVisible()
        
        //register after user is no longer new user
        if Auth.auth().currentUser != nil {
            registerForPushNotifications(application: application)
        }
        
        ApplicationDelegate.shared.application(
                    application,
                    didFinishLaunchingWithOptions: launchOptions
                )
                
        return true
    }
    
    func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable: Any],
        fetchCompletionHandler completionHandler:
            @escaping (UIBackgroundFetchResult) -> Void
    ) {
        guard let aps = userInfo["aps"] as? [String: AnyObject] else {
            completionHandler(.failed)
            return
        }
        // 1
        if aps["content-available"] as? Int == 1 {
            
        } else  {
            completionHandler(.newData)
        }
        
    }
    
    func registerForPushNotifications(application: UIApplication) {
        UNUserNotificationCenter.current().delegate = self
        Messaging.messaging().delegate = self
        
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) {
            [weak self] granted, error in
            
            guard granted else { return }
            
            let eventCategory = UNNotificationCategory(
                identifier: Identifiers.eventCategory, actions: [],
                intentIdentifiers: [], options: [])
            
            let taskCategory = UNNotificationCategory(
                identifier: Identifiers.taskCategory, actions: [],
                intentIdentifiers: [], options: [])
            
            let workoutCategory = UNNotificationCategory(
                identifier: Identifiers.workoutCategory, actions: [],
                intentIdentifiers: [], options: [])
            
            let mindfulnessCategory = UNNotificationCategory(
                identifier: Identifiers.mindfulnessCategory, actions: [],
                intentIdentifiers: [], options: [])
            
            let transactionCategory = UNNotificationCategory(
                identifier: Identifiers.transactionCategory, actions: [],
                intentIdentifiers: [], options: [])
            
            let accountCategory = UNNotificationCategory(
                identifier: Identifiers.accountCategory, actions: [],
                intentIdentifiers: [], options: [])
            
            let listCategory = UNNotificationCategory(
                identifier: Identifiers.listCategory, actions: [],
                intentIdentifiers: [], options: [])
            
            let calendarCategory = UNNotificationCategory(
                identifier: Identifiers.calendarCategory, actions: [],
                intentIdentifiers: [], options: [])
            
//            let chatCategory = UNNotificationCategory(
//                identifier: Identifiers.chatCategory, actions: [],
//                intentIdentifiers: [], options: [])
//
//            let checklistCategory = UNNotificationCategory(
//                identifier: Identifiers.checklistCategory, actions: [],
//                intentIdentifiers: [], options: [])
//
//            let grocerylistCategory = UNNotificationCategory(
//                identifier: Identifiers.grocerylistCategory, actions: [],
//                intentIdentifiers: [], options: [])
//
//            let activitylistCategory = UNNotificationCategory(
//                identifier: Identifiers.activitylistCategory, actions: [],
//                intentIdentifiers: [], options: [])
//
//            let mealCategory = UNNotificationCategory(
//                identifier: Identifiers.mealCategory, actions: [],
//                intentIdentifiers: [], options: [])
            
            
            // 3
            UNUserNotificationCenter.current().setNotificationCategories([eventCategory, taskCategory, workoutCategory, mindfulnessCategory, transactionCategory, accountCategory, listCategory, calendarCategory])
            
            //get application instance ID
            Messaging.messaging().token { (token, error) in
                if let error = error {
                    print("Error fetching remote instance ID: \(error)")
                } else if let token = token {
                    print("Remote instance ID token: \(token)")
                }
            }
            
            self?.getNotificationSettings()
            self?.setFCMToken()
        }
    }
    
    func getNotificationSettings() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            print("Notification settings: \(settings)")
            guard settings.authorizationStatus == .authorized else { return }
            DispatchQueue.main.async {
                UIApplication.shared.registerForRemoteNotifications()
            }
            
        }
    }
    
    fileprivate func setFCMToken()  {
        if let uid = Auth.auth().currentUser?.uid, let fcmToken = Messaging.messaging().fcmToken {
            DispatchQueue.main.async {
                let fcmReference = Database.database().reference().child("users").child(uid).child("fcmToken")
                fcmReference.observeSingleEvent(of: .value, with: { (snapshot) in
                    if snapshot.exists() {
                        if let firebaseToken = snapshot.value as? String, fcmToken != firebaseToken {
                            fcmReference.setValue(fcmToken)
                        }
                    } else {
                        fcmReference.setValue(fcmToken)
                    }
                })
            }
        }
    }

    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        userActivity.webpageURL.flatMap(handlePasswordlessSignIn) ?? false
    }

    func handlePasswordlessSignIn(withURL url: URL) -> Bool {
        if Auth.auth().isSignIn(withEmailLink: url.absoluteString) {
            // Get email passed in the parameter for verification.
            let email = URLComponents(string: url.absoluteString)?.queryItems?
                .first(where: { $0.name == "link" })
                .flatMap({ URLComponents(string: $0.value ?? "")?.queryItems ?? [] })?
                .first(where: { $0.name == "continueUrl" })
                .flatMap({ URLComponents(string: $0.value ?? "")?.queryItems ?? [] })?
                .first(where: { $0.name == "email" })
                .map { $0.value }

            guard let verifiedEmail = email else { return false }

            NotificationCenter.default.post(name: .emailVerified, object: verifiedEmail)

            return true
        }
        return false
    }
    
    // listen for user notifications
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        
        saveUserNotification(notification: notification)
        
        completionHandler(.alert)
    }
    
    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
        let token = tokenParts.joined()
        print("Device Token: \(token)")
    }
    
    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register: \(error)")
    }
    
    var orientationLock = UIInterfaceOrientationMask.allButUpsideDown
    
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        guard Auth.auth().currentUser != nil else { return .portrait }
        return self.orientationLock
    }
    
    func application(_ app: UIApplication,
                     open url: URL,
                     options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        ApplicationDelegate.shared.application(
            app,
            open: url,
            sourceApplication: options[UIApplication.OpenURLOptionsKey.sourceApplication] as? String,
            annotation: options[UIApplication.OpenURLOptionsKey.annotation]
        )
        
        return GIDSignIn.sharedInstance().handle(url)
    }

    var documentsDirectory: String {
        return NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)[0]
    }
    
    var notificationsArchivePath: String {
        let filename = "/notifications.archive"
        let path = documentsDirectory + filename
        return path
    }
    
    func loadNotifications() {
        if let items: [PLNotification] = NSKeyedUnarchiver.unarchiveObject(withFile: notificationsArchivePath) as? [PLNotification] {
            if notifications.count == 0 {
                notifications = items
            } else {
                notifications.append(contentsOf: items)
            }
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension AppDelegate: UNUserNotificationCenterDelegate {
    
    func saveUserNotification(notification: UNNotification) {
        let userInfo = notification.request.content.userInfo
        let value = userInfo as! [String : Any]
        if let object = try? DictionaryDecoder().decode(PLNotification.self, from: value) {
            notifications.insert(object, at: 0)
            if notifications.count > 20 {
                notifications.removeLast()
            }
        }
        
        _ = NSKeyedArchiver.archiveRootObject(notifications, toFile: notificationsArchivePath)
        
        NotificationCenter.default.post(name: .userNotification, object: nil)
    }
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void) {
        
        // 1
        let userInfo = response.notification.request.content.userInfo
        
        saveUserNotification(notification: response.notification)
        
        // 2
        if let _ = userInfo["aps"] as? [String: AnyObject] {
            switch response.actionIdentifier {
//            case Identifiers.viewChatsAction:
//                (window?.rootViewController as? UITabBarController)?.selectedIndex = 1
//            case Identifiers.viewEventsAction:
//                (window?.rootViewController as? UITabBarController)?.selectedIndex = 1
//            case Identifiers.viewListsAction:
//                (window?.rootViewController as? UITabBarController)?.selectedIndex = 1
            default:
                if let activityID = userInfo["activityID"] as? String {
                    ActivitiesFetcher.getDataFromSnapshot(ID: activityID) { activities in
                        if let activity = activities.first {
                            if activity.isTask ?? false {
                                ParticipantsFetcher.getParticipants(forActivity: activity) { (participants) in
                                    if let masterController = self.window?.rootViewController as? MasterActivityContainerController {
                                        let destination = TaskViewController(networkController: masterController.networkController)
                                        destination.selectedFalconUsers = participants
                                        destination.task = activity
                                        destination.hidesBottomBarWhenPushed = true
                                        let cancelBarButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: destination, action: nil)
                                        destination.navigationItem.leftBarButtonItem = cancelBarButton
                                        let navigationViewController = UINavigationController(rootViewController: destination)
                                        masterController.present(navigationViewController, animated: true)
                                    }
                                }
                            } else {
                                ParticipantsFetcher.getParticipants(forActivity: activity) { (participants) in
                                    ParticipantsFetcher.getAcceptedParticipant(forActivity: activity, allParticipants: participants) { acceptedParticipant in
                                        if let masterController = self.window?.rootViewController as? MasterActivityContainerController {
                                            let destination = EventViewController(networkController: masterController.networkController)
                                            destination.acceptedParticipant = acceptedParticipant
                                            destination.selectedFalconUsers = participants
                                            destination.activity = activity
                                            destination.hidesBottomBarWhenPushed = true
                                            let cancelBarButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: destination, action: nil)
                                            destination.navigationItem.leftBarButtonItem = cancelBarButton
                                            let navigationViewController = UINavigationController(rootViewController: destination)
                                            masterController.present(navigationViewController, animated: true)
                                        }
                                    }
                                }
                            }
                        }
                    }
                } else if let transactionID = userInfo["transactionID"] as? String {
                    FinancialTransactionFetcher.getDataFromSnapshot(ID: transactionID) { transactions in
                        if let transaction = transactions.first {
                            ParticipantsFetcher.getParticipants(forTransaction: transaction) { (participants) in
                                if let masterController = self.window?.rootViewController as? MasterActivityContainerController {
                                    let destination = FinanceTransactionViewController(networkController: masterController.networkController)
                                    destination.selectedFalconUsers = participants
                                    destination.transaction = transaction
                                    destination.hidesBottomBarWhenPushed = true
                                    let cancelBarButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: destination, action: nil)
                                    destination.navigationItem.leftBarButtonItem = cancelBarButton
                                    let navigationViewController = UINavigationController(rootViewController: destination)
                                    masterController.present(navigationViewController, animated: true)
                                }
                            }
                        }
                    }
                } else if let accountID = userInfo["accountID"] as? String {
                    FinancialAccountFetcher.getDataFromSnapshot(ID: accountID) { accounts in
                        if let account = accounts.first {
                            ParticipantsFetcher.getParticipants(forAccount: account) { (participants) in
                                if let masterController = self.window?.rootViewController as? MasterActivityContainerController {
                                    let destination = FinanceAccountViewController(networkController: masterController.networkController)
                                    destination.selectedFalconUsers = participants
                                    destination.account = account
                                    destination.hidesBottomBarWhenPushed = true
                                    let cancelBarButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: destination, action: nil)
                                    destination.navigationItem.leftBarButtonItem = cancelBarButton
                                    let navigationViewController = UINavigationController(rootViewController: destination)
                                    masterController.present(navigationViewController, animated: true)
                                }
                            }
                        }
                    }
                } else if let holdingID = userInfo["holdingID"] as? String {
                    FinancialHoldingFetcher.getDataFromSnapshot(ID: holdingID) { holdings in
                        if let holding = holdings.first {
                            ParticipantsFetcher.getParticipants(forHolding: holding) { (participants) in
                                if let masterController = self.window?.rootViewController as? MasterActivityContainerController {
                                    let destination = FinanceHoldingViewController(networkController: masterController.networkController)
                                    destination.selectedFalconUsers = participants
                                    destination.holding = holding
                                    destination.hidesBottomBarWhenPushed = true
                                    let cancelBarButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: destination, action: nil)
                                    destination.navigationItem.leftBarButtonItem = cancelBarButton
                                    let navigationViewController = UINavigationController(rootViewController: destination)
                                    masterController.present(navigationViewController, animated: true)
                                }
                            }
                        }
                    }
                } else if let listID = userInfo["listID"] as? String {
                    ListFetcher.getDataFromSnapshot(ID: listID) { lists in
                        if let list = lists.first {
                            ParticipantsFetcher.getParticipants(forList: list) { (participants) in
                                if let masterController = self.window?.rootViewController as? MasterActivityContainerController {
                                    let destination = ListDetailViewController(networkController: masterController.networkController)
                                    destination.selectedFalconUsers = participants
                                    destination.list = list
                                    destination.hidesBottomBarWhenPushed = true
                                    let cancelBarButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: destination, action: nil)
                                    destination.navigationItem.leftBarButtonItem = cancelBarButton
                                    let navigationViewController = UINavigationController(rootViewController: destination)
                                    masterController.present(navigationViewController, animated: true)
                                }
                            }
                        }
                    }
                } else if let calendarID = userInfo["calendarID"] as? String {
                    CalendarFetcher.getDataFromSnapshot(ID: calendarID) { calendars in
                        if let calendar = calendars.first {
                            ParticipantsFetcher.getParticipants(forCalendar: calendar) { (participants) in
                                if let masterController = self.window?.rootViewController as? MasterActivityContainerController {
                                    let destination = CalendarDetailViewController(networkController: masterController.networkController)
                                    destination.selectedFalconUsers = participants
                                    destination.calendar = calendar
                                    destination.hidesBottomBarWhenPushed = true
                                    let cancelBarButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: destination, action: nil)
                                    destination.navigationItem.leftBarButtonItem = cancelBarButton
                                    let navigationViewController = UINavigationController(rootViewController: destination)
                                    masterController.present(navigationViewController, animated: true)
                                }
                            }
                        }
                    }
                }
            }
        }
        
        // 4
        completionHandler()
    }
}

extension AppDelegate : MessagingDelegate {
    // [START refresh_token]
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let fcmToken = fcmToken else { return }
        let dataDict:[String: String] = ["token": fcmToken]
        NotificationCenter.default.post(name: Notification.Name("FCMToken"), object: nil, userInfo: dataDict)
        self.setFCMToken()
        // TODO: If necessary send token to application server.
        // Note: This callback is fired at each app startup and whenever a new token is generated.
    }
    // [END refresh_token]
    
    // [START ios_10_data_message]
    // Receive data messages on iOS 10+ directly from FCM (bypassing APNs) when the app is in the foreground.
    // To enable direct data messages, you can set Messaging.messaging().shouldEstablishDirectChannel to true.
    // [END ios_10_data_message]
}

extension Notification.Name {
    static let userNotification = Notification.Name("userNotification")
}
