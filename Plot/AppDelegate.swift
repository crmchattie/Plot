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

enum Identifiers {
    static let viewChatsAction = "VIEW_CHAT_IDENTIFIER"
    static let viewActivitiesAction = "VIEW_ACTIVITIES_IDENTIFIER"
    static let viewListsAction = "VIEW_LISTS_IDENTIFIER"
    static let replyAction = "REPLY_ACTION"
    static let chatCategory = "CHAT_CATEGORY"
    static let activityCategory = "ACTIVITY_CATEGORY"
    static let checklistCategory = "CHECKLIST_CATEGORY"
    static let grocerylistCategory = "GROCERYLIST_CATEGORY"
    static let activitylistCategory = "ACTIVITYLIST_CATEGORY"
    static let mealCategory = "MEAL_CATEGORY"
    static let workoutCategory = "WORKOUT_CATEGORY"
    static let mindfulnessCategory = "MINDFULNESS_CATEGORY"
    static let transactionCategory = "TRANSACTION_CATEGORY"
    static let accountCategory = "ACCOUNT_CATEGORY"
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    var chatLogController: ChatLogController? = nil
    var messagesFetcher: MessagesFetcher? = nil
    var notifications: [PLNotification] = []
    var participants: [String: [User]] = [:]
    let invitationsFetcher = InvitationsFetcher()
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        FirebaseApp.configure()
        Database.database().isPersistenceEnabled = true
        userDefaults.configureInitialLaunch()
        GIDSignIn.sharedInstance().clientID = "433321796976-14dht5ecttj96dnltoj7cf0arfr7e6bo.apps.googleusercontent.com"
        GIDSignIn.sharedInstance().scopes = ["https://www.googleapis.com/auth/calendar"]
        GIDSignIn.sharedInstance()?.restorePreviousSignIn()
        //manually create window or default controller, thus ridding of Storyboard
        let tabBarController = GeneralTabBarController()
        // set-up window
        window = UIWindow(frame: UIScreen.main.bounds)
        //set window = tabBarController
        window?.rootViewController = tabBarController
        //make window visible
        window?.makeKeyAndVisible()
        //        //set backgroundColor to theme
        //        window?.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
        //
        tabBarController.presentOnboardingController()
        
        //register after user is no longer new user
        if Auth.auth().currentUser != nil {
            registerForPushNotifications(application: application)
        }

        RunLoop.current.run(until: NSDate(timeIntervalSinceNow:2) as Date)
        
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
            
            let activityCategory = UNNotificationCategory(
                identifier: Identifiers.activityCategory, actions: [],
                intentIdentifiers: [], options: [])
            
            let chatCategory = UNNotificationCategory(
                identifier: Identifiers.chatCategory, actions: [],
                intentIdentifiers: [], options: [])
            
            let checklistCategory = UNNotificationCategory(
                identifier: Identifiers.checklistCategory, actions: [],
                intentIdentifiers: [], options: [])
            
            let grocerylistCategory = UNNotificationCategory(
                identifier: Identifiers.grocerylistCategory, actions: [],
                intentIdentifiers: [], options: [])
            
            let activitylistCategory = UNNotificationCategory(
                identifier: Identifiers.activitylistCategory, actions: [],
                intentIdentifiers: [], options: [])
            
            let mealCategory = UNNotificationCategory(
                identifier: Identifiers.mealCategory, actions: [],
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
            
            
            // 3
            UNUserNotificationCenter.current().setNotificationCategories([chatCategory, activityCategory, checklistCategory, grocerylistCategory, activitylistCategory, mealCategory, workoutCategory, mindfulnessCategory, transactionCategory, accountCategory])
            
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
        if let aps = userInfo["aps"] as? [String: AnyObject] {
            switch response.actionIdentifier {
            case Identifiers.viewChatsAction:
                (window?.rootViewController as? UITabBarController)?.selectedIndex = 1
            case Identifiers.viewActivitiesAction:
                (window?.rootViewController as? UITabBarController)?.selectedIndex = 1
            case Identifiers.viewListsAction:
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
                } else if let activityID = userInfo["activityID"] as? String {
                    let groupChatDataReference = Database.database().reference().child("activities").child(activityID).child(messageMetaDataFirebaseFolder)
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
                                if let detailedRecipe = search {
                                    dispatchGroup.leave()
                                    dispatchGroup.notify(queue: .main) {
                                        let destination = RecipeDetailViewController()
                                        destination.hidesBottomBarWhenPushed = true
                                        destination.recipe = detailedRecipe
                                        destination.detailedRecipe = detailedRecipe
                                        destination.activity = activity
                                        self.getParticipants(forActivity: activity) { (participants) in
                                            InvitationsFetcher.getAcceptedParticipant(forActivity: activity, allParticipants: participants) { acceptedParticipant in
                                                destination.acceptedParticipant = acceptedParticipant
                                                destination.selectedFalconUsers = participants
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
                                        destination.hidesBottomBarWhenPushed = true
                                        destination.event = event
                                        destination.activity = activity
                                        self.getParticipants(forActivity: activity) { (participants) in
                                            InvitationsFetcher.getAcceptedParticipant(forActivity: activity, allParticipants: participants) { acceptedParticipant in
                                                destination.acceptedParticipant = acceptedParticipant
                                                destination.selectedFalconUsers = participants
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
                                }
                            }
                        } else if let workoutID = activity.workoutID {
                            var reference = Database.database().reference()
                            dispatchGroup.enter()
                            reference = Database.database().reference().child("workouts").child("workouts")
                            reference.child(workoutID).observeSingleEvent(of: .value, with: { (snapshot) in
                                if snapshot.exists(), let workoutSnapshotValue = snapshot.value {
                                    if let workout = try? FirebaseDecoder().decode(PreBuiltWorkout.self, from: workoutSnapshotValue) {
                                        dispatchGroup.leave()
                                        let destination = WorkoutDetailViewController()
                                        destination.hidesBottomBarWhenPushed = true
                                        destination.workout = workout
                                        destination.intColor = 0
                                        destination.activity = activity
                                        self.getParticipants(forActivity: activity) { (participants) in
                                            InvitationsFetcher.getAcceptedParticipant(forActivity: activity, allParticipants: participants) { acceptedParticipant in
                                                destination.acceptedParticipant = acceptedParticipant
                                                destination.selectedFalconUsers = participants
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
                                }
                            })
                            { (error) in
                                print(error.localizedDescription)
                            }
                        } else if let attractionID = activity.attractionID {
                            dispatchGroup.enter()
                            Service.shared.fetchAttractionsSegment(size: "50", id: attractionID, keyword: "", classificationName: "", classificationId: "") { (search, err) in
                                if let attraction = search?.embedded?.attractions![0] {
                                    dispatchGroup.leave()
                                    dispatchGroup.notify(queue: .main) {
                                        let destination = EventDetailViewController()
                                        destination.hidesBottomBarWhenPushed = true
                                        destination.attraction = attraction
                                        destination.activity = activity
                                        self.getParticipants(forActivity: activity) { (participants) in
                                            InvitationsFetcher.getAcceptedParticipant(forActivity: activity, allParticipants: participants) { acceptedParticipant in
                                                destination.acceptedParticipant = acceptedParticipant
                                                destination.selectedFalconUsers = participants
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
                                }
                            }
                        } else if let placeID = activity.placeID {
                            dispatchGroup.enter()
                            Service.shared.fetchFSDetails(id: placeID) { (search, err) in
                                if let place = search?.response?.venue {
                                    dispatchGroup.leave()
                                    dispatchGroup.notify(queue: .main) {
                                        let destination = PlaceDetailViewController()
                                        destination.hidesBottomBarWhenPushed = true
                                        destination.place = place
                                        destination.activity = activity
                                        self.getParticipants(forActivity: activity) { (participants) in
                                            InvitationsFetcher.getAcceptedParticipant(forActivity: activity, allParticipants: participants) { acceptedParticipant in
                                                destination.acceptedParticipant = acceptedParticipant
                                                destination.selectedFalconUsers = participants
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
                                }
                            }
                        } else {
                            let destination = CreateActivityViewController()
                            destination.hidesBottomBarWhenPushed = true
                            destination.activity = activity
                            self.getParticipants(forActivity: activity) { (participants) in
                                InvitationsFetcher.getAcceptedParticipant(forActivity: activity, allParticipants: participants) { acceptedParticipant in
                                    destination.acceptedParticipant = acceptedParticipant
                                    destination.selectedFalconUsers = participants
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
                        
                    })
                } else if let checklistID = userInfo["checklistID"] as? String {
                    let ref = Database.database().reference()
                    ref.child(checklistsEntity).child(checklistID).observeSingleEvent(of: .value, with: { checklistSnapshot in
                        if checklistSnapshot.exists(), let checklistSnapshotValue = checklistSnapshot.value {
                            if let checklist = try? FirebaseDecoder().decode(Checklist.self, from: checklistSnapshotValue) {
                                let destination = ChecklistViewController()
                                destination.checklist = checklist
                                destination.comingFromLists = true
                                destination.connectedToAct = false
                                self.getParticipants(grocerylist: nil, checklist: checklist, packinglist: nil, activitylist: nil) { (participants) in
                                    destination.selectedFalconUsers = participants
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
                    })
                } else if let grocerylistID = userInfo["grocerylistID"] as? String {
                    let ref = Database.database().reference()
                    ref.child(grocerylistsEntity).child(grocerylistID).observeSingleEvent(of: .value, with: { grocerylistSnapshot in
                        if grocerylistSnapshot.exists(), let grocerylistSnapshotValue = grocerylistSnapshot.value {
                            if let grocerylist = try? FirebaseDecoder().decode(Grocerylist.self, from: grocerylistSnapshotValue) {
                                let destination = GrocerylistViewController()
                                destination.grocerylist = grocerylist
                                destination.comingFromLists = true
                                destination.connectedToAct = false
                                self.getParticipants(grocerylist: grocerylist, checklist: nil, packinglist: nil, activitylist: nil) { (participants) in
                                    destination.selectedFalconUsers = participants
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
                    })
                } else if let activitylistID = userInfo["activitylistID"] as? String {
                    let ref = Database.database().reference()
                    ref.child(activitylistsEntity).child(activitylistID).observeSingleEvent(of: .value, with: { activitylistSnapshot in
                        if activitylistSnapshot.exists(), let activitylistSnapshotValue = activitylistSnapshot.value {
                            if let activitylist = try? FirebaseDecoder().decode(Activitylist.self, from: activitylistSnapshotValue) {
                                let destination = ActivitylistViewController()
                                destination.activitylist = activitylist
                                destination.comingFromLists = true
                                destination.connectedToAct = false
                                self.getParticipants(grocerylist: nil, checklist: nil, packinglist: nil, activitylist: activitylist) { (participants) in
                                    destination.selectedFalconUsers = participants
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
                    })
                } else if let transactionID = userInfo["transactionID"] as? String {
                    let ref = Database.database().reference()
                    ref.child(financialTransactionsEntity).child(transactionID).observeSingleEvent(of: .value, with: { snapshot in
                        if snapshot.exists(), let snapshotValue = snapshot.value {
                            if let transaction = try? FirebaseDecoder().decode(Transaction.self, from: snapshotValue) {
                                let destination = FinanceTransactionViewController()
                                destination.transaction = transaction
                                self.getParticipants(transaction: transaction, account: nil) { (participants) in
                                    destination.selectedFalconUsers = participants
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
                    })
                } else if let accountID = userInfo["accountID"] as? String {
                    let ref = Database.database().reference()
                    ref.child(financialAccountsEntity).child(accountID).observeSingleEvent(of: .value, with: { snapshot in
                        if snapshot.exists(), let snapshotValue = snapshot.value {
                            if let account = try? FirebaseDecoder().decode(MXAccount.self, from: snapshotValue) {
                                let destination = FinanceAccountViewController()
                                destination.account = account
                                self.getParticipants(transaction: nil, account: account) { (participants) in
                                    destination.selectedFalconUsers = participants
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
                    })
                }
            }
        }
        
        // 4
        completionHandler()
    }
    
    func getParticipants(grocerylist: Grocerylist?, checklist: Checklist?, packinglist: Packinglist?, activitylist: Activitylist?, completion: @escaping ([User])->()) {
        if let grocerylist = grocerylist, let ID = grocerylist.ID, let participantsIDs = grocerylist.participantsIDs, let currentUserID = Auth.auth().currentUser?.uid {
            let group = DispatchGroup()
            let olderParticipants = self.participants[ID]
            var participants: [User] = []
            for id in participantsIDs {
                if grocerylist.admin == currentUserID && id == currentUserID {
                    continue
                }
                
                if let first = olderParticipants?.filter({$0.id == id}).first {
                    participants.append(first)
                    continue
                }
                
                group.enter()
                let participantReference = Database.database().reference().child("users").child(id)
                participantReference.observeSingleEvent(of: .value, with: { (snapshot) in
                    if snapshot.exists(), var dictionary = snapshot.value as? [String: AnyObject] {
                        dictionary.updateValue(snapshot.key as AnyObject, forKey: "id")
                        let user = User(dictionary: dictionary)
                        participants.append(user)
                    }
                    
                    group.leave()
                })
            }
            
            group.notify(queue: .main) {
                self.participants[ID] = participants
                completion(participants)
            }
        } else if let checklist = checklist, let ID = checklist.ID, let participantsIDs = checklist.participantsIDs, let currentUserID = Auth.auth().currentUser?.uid {
            let group = DispatchGroup()
            let olderParticipants = self.participants[ID]
            var participants: [User] = []
            for id in participantsIDs {
                if checklist.admin == currentUserID && id == currentUserID {
                    continue
                }
                
                if let first = olderParticipants?.filter({$0.id == id}).first {
                    participants.append(first)
                    continue
                }
                
                group.enter()
                let participantReference = Database.database().reference().child("users").child(id)
                participantReference.observeSingleEvent(of: .value, with: { (snapshot) in
                    if snapshot.exists(), var dictionary = snapshot.value as? [String: AnyObject] {
                        dictionary.updateValue(snapshot.key as AnyObject, forKey: "id")
                        let user = User(dictionary: dictionary)
                        participants.append(user)
                    }
                    
                    group.leave()
                })
            }
            
            group.notify(queue: .main) {
                self.participants[ID] = participants
                completion(participants)
            }
        } else if let activitylist = activitylist, let ID = activitylist.ID, let participantsIDs = activitylist.participantsIDs, let currentUserID = Auth.auth().currentUser?.uid {
            let group = DispatchGroup()
            let olderParticipants = self.participants[ID]
            var participants: [User] = []
            for id in participantsIDs {
                if activitylist.admin == currentUserID && id == currentUserID {
                    continue
                }
                
                if let first = olderParticipants?.filter({$0.id == id}).first {
                    participants.append(first)
                    continue
                }
                
                group.enter()
                let participantReference = Database.database().reference().child("users").child(id)
                participantReference.observeSingleEvent(of: .value, with: { (snapshot) in
                    if snapshot.exists(), var dictionary = snapshot.value as? [String: AnyObject] {
                        dictionary.updateValue(snapshot.key as AnyObject, forKey: "id")
                        let user = User(dictionary: dictionary)
                        participants.append(user)
                    }
                    
                    group.leave()
                })
            }
            
            group.notify(queue: .main) {
                self.participants[ID] = participants
                completion(participants)
            }
        } else if let packinglist = packinglist, let ID = packinglist.ID, let participantsIDs = packinglist.participantsIDs, let currentUserID = Auth.auth().currentUser?.uid {
            let group = DispatchGroup()
            let olderParticipants = self.participants[ID]
            var participants: [User] = []
            for id in participantsIDs {
                if packinglist.admin == currentUserID && id == currentUserID {
                    continue
                }
                
                if let first = olderParticipants?.filter({$0.id == id}).first {
                    participants.append(first)
                    continue
                }
                
                group.enter()
                let participantReference = Database.database().reference().child("users").child(id)
                participantReference.observeSingleEvent(of: .value, with: { (snapshot) in
                    if snapshot.exists(), var dictionary = snapshot.value as? [String: AnyObject] {
                        dictionary.updateValue(snapshot.key as AnyObject, forKey: "id")
                        let user = User(dictionary: dictionary)
                        participants.append(user)
                    }
                    
                    group.leave()
                })
            }
            
            group.notify(queue: .main) {
                self.participants[ID] = participants
                completion(participants)
            }
        } else {
            return
        }
    }
    
    func getParticipants(forActivity activity: Activity, completion: @escaping ([User])->()) {
        guard let activityID = activity.activityID, let participantsIDs = activity.participantsIDs, let currentUserID = Auth.auth().currentUser?.uid else {
            return
        }
        
        
        let group = DispatchGroup()
        let olderParticipants = self.participants[activityID]
        var participants: [User] = []
        for id in participantsIDs {
            // Only if the current user is created this activity
            if activity.admin == currentUserID && id == currentUserID {
                continue
            }
            
            if let first = olderParticipants?.filter({$0.id == id}).first {
                participants.append(first)
                continue
            }
            
            group.enter()
            let participantReference = Database.database().reference().child("users").child(id)
            participantReference.observeSingleEvent(of: .value, with: { (snapshot) in
                if snapshot.exists(), var dictionary = snapshot.value as? [String: AnyObject] {
                    dictionary.updateValue(snapshot.key as AnyObject, forKey: "id")
                    let user = User(dictionary: dictionary)
                    participants.append(user)
                }
                
                group.leave()
            })
        }
        
        group.notify(queue: .main) {
            self.participants[activityID] = participants
            completion(participants)
        }
    }
    
    func getParticipants(transaction: Transaction?, account: MXAccount?, completion: @escaping ([User])->()) {
        if let transaction = transaction, let participantsIDs = transaction.participantsIDs, let currentUserID = Auth.auth().currentUser?.uid {
            let group = DispatchGroup()
            let ID = transaction.guid
            let olderParticipants = self.participants[ID]
            var participants: [User] = []
            for id in participantsIDs {
                if transaction.admin == currentUserID && id == currentUserID {
                    continue
                }
                
                if let first = olderParticipants?.filter({$0.id == id}).first {
                    participants.append(first)
                    continue
                }
                
                group.enter()
                let participantReference = Database.database().reference().child("users").child(id)
                participantReference.observeSingleEvent(of: .value, with: { (snapshot) in
                    if snapshot.exists(), var dictionary = snapshot.value as? [String: AnyObject] {
                        dictionary.updateValue(snapshot.key as AnyObject, forKey: "id")
                        let user = User(dictionary: dictionary)
                        participants.append(user)
                    }
                    
                    group.leave()
                })
            }
            
            group.notify(queue: .main) {
                self.participants[ID] = participants
                completion(participants)
            }
        } else if let account = account, let participantsIDs = account.participantsIDs, let currentUserID = Auth.auth().currentUser?.uid {
            let group = DispatchGroup()
            let ID = account.guid
            let olderParticipants = self.participants[ID]
            var participants: [User] = []
            
            for id in participantsIDs {
                if account.admin == currentUserID && id == currentUserID {
                    continue
                }
                
                if let first = olderParticipants?.filter({$0.id == id}).first {
                    participants.append(first)
                    continue
                }
                
                group.enter()
                let participantReference = Database.database().reference().child("users").child(id)
                participantReference.observeSingleEvent(of: .value, with: { (snapshot) in
                    if snapshot.exists(), var dictionary = snapshot.value as? [String: AnyObject] {
                        dictionary.updateValue(snapshot.key as AnyObject, forKey: "id")
                        let user = User(dictionary: dictionary)
                        participants.append(user)
                    }
                    
                    group.leave()
                })
            }
            
            group.notify(queue: .main) {
                self.participants[ID] = participants
                completion(participants)
            }
        } else {
            let participants: [User] = []
            completion(participants)
        }
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
            
            tabBarController.selectedIndex = 1
            
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
