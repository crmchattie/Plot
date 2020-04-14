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

enum Identifiers {
    static let viewChatsAction = "VIEW_CHAT_IDENTIFIER"
    static let viewActivitiesAction = "VIEW_ACTIVITIES_IDENTIFIER"
    static let replyAction = "REPLY_ACTION"
    static let chatCategory = "CHAT_CATEGORY"
    static let activityCategory = "ACTIVITY_CATEGORY"
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    var chatLogController: ChatLogController? = nil
    var messagesFetcher: MessagesFetcher? = nil
    var notifications: [PLNotification] = []
    var additionalUserInfo: AdditionalUserInfo?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        ThemeManager.applyTheme(theme: ThemeManager.currentTheme())
        FirebaseApp.configure()
        Database.database().isPersistenceEnabled = true
        userDefaults.configureInitialLaunch()
        //manually create window or default controller, thus ridding of Storyboard
        let tabBarController = GeneralTabBarController()
        // set-up window
        window = UIWindow(frame: UIScreen.main.bounds)
        //set window = tabBarController
        window?.rootViewController = tabBarController
        //make window visible
        window?.makeKeyAndVisible()
        //set backgroundColor to theme
        window?.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
        
        tabBarController.presentOnboardingController()
        
        registerForPushNotifications(application: application)
        
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
            
            // 1
            let viewActivityAction = UNNotificationAction(
                identifier: Identifiers.viewActivitiesAction, title: "View Activities",
                options: [.foreground])
            
            let viewChatAction = UNNotificationAction(
                identifier: Identifiers.viewChatsAction, title: "View Chats",
                options: [.foreground])
            
            //                let replyChatAction = UNTextInputNotificationAction(
            //                    identifier: Identifiers.viewAction, title: "Reply to Message",
            //                    options: [.foreground])
            
            // 2
            let activityCategory = UNNotificationCategory(
                identifier: Identifiers.activityCategory, actions: [viewActivityAction],
                intentIdentifiers: [], options: [])
            
            let chatCategory = UNNotificationCategory(
                identifier: Identifiers.chatCategory, actions: [viewChatAction],
                intentIdentifiers: [], options: [])
            
            
            // 3
            UNUserNotificationCenter.current().setNotificationCategories([chatCategory, activityCategory])
            
            //get application instance ID
            InstanceID.instanceID().instanceID { (result, error) in
                if let error = error {
                    print("Error fetching remote instance ID: \(error)")
                } else if let result = result {
                    print("Remote instance ID token: \(result.token)")
                }
            }
            
            self?.getNotificationSettings()
            self?.setFCMToken()
        }
        
//            application.registerForRemoteNotifications()
        
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
    
    func applicationWillResignActive(_ application: UIApplication) {
        
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
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
        if let aps = userInfo["aps"] as? [String: AnyObject] {
            print(aps)
            switch response.actionIdentifier {
            case Identifiers.viewChatsAction:
                (window?.rootViewController as? UITabBarController)?.selectedIndex = 0
            case Identifiers.viewActivitiesAction:
                (window?.rootViewController as? UITabBarController)?.selectedIndex = 1
            default:
                if let chatID = userInfo["chatID"] as? String {
                    
                    let groupChatDataReference = Database.database().reference().child("groupChats").child(chatID).child(messageMetaDataFirebaseFolder)
                    groupChatDataReference.observeSingleEvent(of: .value, with: { (snapshot) in
                        guard var dictionary = snapshot.value as? [String: AnyObject] else { return }
                        dictionary.updateValue(chatID as AnyObject, forKey: "id")
                        
                        if let membersIDs = dictionary["chatParticipantsIDs"] as? [String:AnyObject] {
                            dictionary.updateValue(Array(membersIDs.values) as AnyObject, forKey: "chatParticipantsIDs")
                        }
                        
                        let conversation = Conversation(dictionary: dictionary)
                        
                        if conversation.chatName == nil {
                            conversation.chatName = aps["alert"]!["title"] as? String
                        }
                        
                        self.chatLogController = ChatLogController(collectionViewLayout: AutoSizingCollectionViewFlowLayout())
                        self.messagesFetcher = MessagesFetcher()
                        self.messagesFetcher?.delegate = self
                        self.messagesFetcher?.loadMessagesData(for: conversation)
                    })
                } else {
                    let activityID = userInfo["activityID"] as? String
                    let groupChatDataReference = Database.database().reference().child("activities").child(activityID!).child(messageMetaDataFirebaseFolder)
                    groupChatDataReference.observeSingleEvent(of: .value, with: { (snapshot) in
                        guard var dictionary = snapshot.value as? [String: AnyObject] else { return }
                        dictionary.updateValue(activityID as AnyObject, forKey: "id")
                        
                        if let membersIDs = dictionary["chatParticipantsIDs"] as? [String:AnyObject] {
                            dictionary.updateValue(Array(membersIDs.values) as AnyObject, forKey: "chatParticipantsIDs")
                        }
                        
                        let activity = Activity(dictionary: dictionary)
                        
                        let dispatchGroup = DispatchGroup()
                                
                        if let recipeString = activity.recipeID, let recipeID = Int(recipeString) {
                            dispatchGroup.enter()
                            Service.shared.fetchRecipesInfo(id: recipeID) { (search, err) in
                                let detailedRecipe = search
                                dispatchGroup.leave()
                                dispatchGroup.notify(queue: .main) {
                                    let destination = MealDetailViewController()
                                    destination.recipe = detailedRecipe
                                    destination.detailedRecipe = detailedRecipe
                                    destination.activity = activity
                                    if let tabBarController = self.window?.rootViewController as? GeneralTabBarController {
                                        tabBarController.selectedIndex = 1
                                        tabBarController.presentedViewController?.dismiss(animated: true, completion: nil)
                                        if let homeNavigationController = tabBarController.viewControllers?[1] as? UINavigationController {
                                            homeNavigationController.pushViewController(destination, animated: true)
                                            
                                        }
                                        
                                    }
                                }
                            }
                        } else if let eventID = activity.eventID {
                            dispatchGroup.enter()
                            Service.shared.fetchEventsSegment(size: "50", id: eventID, keyword: "", attractionId: "", venueId: "", postalCode: "", radius: "", unit: "", startDateTime: "", endDateTime: "", city: "", stateCode: "", countryCode: "", classificationName: "", classificationId: "") { (search, err) in
                                if let events = search?.embedded?.events {
                                    let event = events[0]
                                    dispatchGroup.leave()
                                    dispatchGroup.notify(queue: .main) {
                                        let destination = EventDetailViewController()
                                        destination.event = event
                                        destination.activity = activity
                                        if let tabBarController = self.window?.rootViewController as? GeneralTabBarController {
                                            tabBarController.selectedIndex = 1
                                            tabBarController.presentedViewController?.dismiss(animated: true, completion: nil)
                                            if let homeNavigationController = tabBarController.viewControllers?[1] as? UINavigationController {
                                                homeNavigationController.pushViewController(destination, animated: true)
                                                
                                            }
                                            
                                        }
                                    }
                                }
                            }
                        } else if let workoutID = activity.workoutID {
                            var reference = Database.database().reference()
                            let destination = WorkoutDetailViewController()
                            dispatchGroup.enter()
                            reference = Database.database().reference().child("workouts").child("workouts")
                            reference.child(workoutID).observeSingleEvent(of: .value, with: { (snapshot) in
                                if snapshot.exists(), let workoutSnapshotValue = snapshot.value {
                                    if let workout = try? FirebaseDecoder().decode(Workout.self, from: workoutSnapshotValue) {
                                        dispatchGroup.leave()
                                        destination.workout = workout
                                        destination.intColor = 0
                                        destination.activity = activity
                                        if let tabBarController = self.window?.rootViewController as? GeneralTabBarController {
                                            tabBarController.selectedIndex = 1
                                            tabBarController.presentedViewController?.dismiss(animated: true, completion: nil)
                                            if let homeNavigationController = tabBarController.viewControllers?[1] as? UINavigationController {
                                                homeNavigationController.pushViewController(destination, animated: true)
                                                
                                            }
                                            
                                        }
                                    }
                                }
                              })
                            { (error) in
                                print(error.localizedDescription)
                            }
                        } else if let attractionID = activity.attractionID {
                            dispatchGroup.enter()
                            Service.shared.fetchAttractionsSegment(size: "50", id: attractionID, keyword: "", classificationName: "", classificationId: "") { (search, err) in
                                let attraction = search?.embedded?.attractions![0]
                                dispatchGroup.leave()
                                dispatchGroup.notify(queue: .main) {
                                    let destination = EventDetailViewController()
                                    destination.attraction = attraction
                                    destination.activity = activity
                                    if let tabBarController = self.window?.rootViewController as? GeneralTabBarController {
                                        tabBarController.selectedIndex = 1
                                        tabBarController.presentedViewController?.dismiss(animated: true, completion: nil)
                                        if let homeNavigationController = tabBarController.viewControllers?[1] as? UINavigationController {
                                            homeNavigationController.pushViewController(destination, animated: true)
                                            
                                        }
                                        
                                    }
                                }
                            }
                        } else {
                            let destination = CreateActivityViewController()
                            destination.hidesBottomBarWhenPushed = true
                            destination.activity = activity
                            if let tabBarController = self.window?.rootViewController as? GeneralTabBarController {
                                tabBarController.selectedIndex = 1
                                tabBarController.presentedViewController?.dismiss(animated: true, completion: nil)
                                if let homeNavigationController = tabBarController.viewControllers?[1] as? UINavigationController {
                                    homeNavigationController.pushViewController(destination, animated: true)
                                    
                                }
                                
                            }
                            
                        }
                        
                    })
                }
            }
        }
        
        // 4
        completionHandler()
    }
}

extension AppDelegate : MessagingDelegate {
    // [START refresh_token]
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String) {
        print("Firebase registration token: \(fcmToken)")
        
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
    func messaging(_ messaging: Messaging, didReceive remoteMessage: MessagingRemoteMessage) {
        print("Received data message: \(remoteMessage.appData)")
    }
    // [END ios_10_data_message]
}

extension AppDelegate: MessagesDelegate {
    
    func messages(shouldChangeMessageStatusToReadAt reference: DatabaseReference) {
        chatLogController?.updateMessageStatus(messageRef: reference)
    }
    
    func messages(shouldBeUpdatedTo messages: [Message], conversation: Conversation) {
        
        chatLogController?.hidesBottomBarWhenPushed = true
        chatLogController?.messagesFetcher = messagesFetcher
        chatLogController?.messages = messages
        chatLogController?.conversation = conversation
        
        if let membersIDs = conversation.chatParticipantsIDs, let uid = Auth.auth().currentUser?.uid, membersIDs.contains(uid) {
            chatLogController?.observeTypingIndicator()
            chatLogController?.configureTitleViewWithOnlineStatus()
        }
        
        chatLogController?.messagesFetcher.collectionDelegate = chatLogController
        guard let destination = chatLogController else { return }
        
        if #available(iOS 11.0, *) {
        } else {
            self.chatLogController?.startCollectionViewAtBottom()
        }
        
        if let tabBarController = window?.rootViewController as? GeneralTabBarController {
            
            tabBarController.selectedIndex = 0
            
            tabBarController.presentedViewController?.dismiss(animated: true, completion: nil)
            
            if let homeNavigationController = tabBarController.viewControllers?[0] as? UINavigationController {
                
                homeNavigationController.pushViewController(destination, animated: true)
                chatLogController = nil
                messagesFetcher?.delegate = nil
                messagesFetcher = nil
                
            }
            
        }
        
    }
}

extension Notification.Name {
     static let userNotification = Notification.Name("userNotification")
}
